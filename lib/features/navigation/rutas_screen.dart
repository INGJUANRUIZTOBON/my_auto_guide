// =============================================================================
// rutas_screen.dart — NAVEGACIÓN GPS PROFESIONAL & INTELIGENTE (GOOGLE MAPS STYLE)
// =============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/background_nav_service.dart';
import '../../../core/services/colombia_tolls_service.dart';
import '../../../core/services/pico_y_placa_service.dart';
import '../../../core/services/auto_bluetooth_trip_service.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/voice_navigation_service.dart';
import '../../../core/services/secure_storage_service.dart'; // VULN-01: almacenamiento cifrado
import 'domain/models/navigation_telemetry.dart';
import 'logic/map_tile_config.dart';
import 'logic/telemetry_calculator.dart';
import 'presentation/controllers/navigation_controller.dart';
import 'presentation/widgets/navigation_widgets.dart';
import 'presentation/widgets/fuel_prices_sheet.dart';
import 'presentation/historial_rutas_screen.dart';
import '../../shared/widgets/app_snack_bar.dart';
import '../../../core/services/camera_radar_service.dart';
import '../../../core/services/waze_community_alerts_service.dart';
import 'presentation/widgets/waze_report_sheet.dart';

class RutasScreen extends StatefulWidget {
  final String vehiculoId;
  final int kmsActuales;
  final Map<String, dynamic>? initialRoute;

  const RutasScreen({
    super.key,
    required this.vehiculoId,
    required this.kmsActuales,
    this.initialRoute,
  });

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final SupabaseClient supabase = SupabaseService().client;
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late NavigationController _controller;
  bool _isLoadingRoute = false;
  bool _isStartingNav = false;
  bool _autoFollow = true;
  MapStyle? _mapStyle;
  String? _vehicleImagePath;
  PicoYPlacaStatus? _picoStatus;
  
  List<NominatimPlace> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  StreamSubscription<Position>? _idlePositionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = NavigationController(
      vehicleId: widget.vehiculoId,
      vehicleModel: 'Vehículo',
      isCar: false,
    );
    _controller.addListener(_onControllerStateUpdate);
    _obtenerUbicacionInicial();
    _iniciarSeguimientoIdle();
    _cargarInfoVehiculo();
    CameraRadarService().startRadar();
    WazeCommunityAlertsService().initRealtimeAlerts();

    if (widget.initialRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarRutaDesdeHistorial(widget.initialRoute!);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(() async {
        await _controller.syncFromBackgroundStorage();
        final pos = _controller.telemetry.currentPos;
        if (mounted && _autoFollow && pos != null) {
          _mapCtrl.move(pos, _mapCtrl.camera.zoom);
        }
      }());
    }
  }

  bool _isFinalizing = false;

  void _onControllerStateUpdate() {
    if (mounted) {
      // Si la navegación finalizó automáticamente por arribo al destino (< 40m)
      if (_controller.state == NavigationState.completed && !_isFinalizing) {
        _finalizarRuta();
      } else if (_autoFollow &&
          (_controller.state == NavigationState.navigating ||
              _controller.state == NavigationState.freeTracking) &&
          _controller.telemetry.currentPos != null) {
        _mapCtrl.move(_controller.telemetry.currentPos!, _mapCtrl.camera.zoom);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    CameraRadarService().stopRadar();
    _controller.removeListener(_onControllerStateUpdate);
    _idlePositionSubscription?.cancel();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─── LÓGICA DE CARGA ────────────────────────────────────
  
  Future<void> _cargarInfoVehiculo() async {
    try {
      final data = await supabase
          .from('vehiculos')
          .select('modelo, marca, placa, image_path')
          .eq('id', widget.vehiculoId)
          .single();
      final marca = (data['marca'] as String? ?? '').toUpperCase();
      final modelo = data['modelo'] ?? 'Vehículo';
      final placa = data['placa']?.toString() ?? '';
      final imagePath = (data['image_path'] as String? ?? '').toLowerCase();
      final isCar = imagePath.contains('carros/') ||
          marca.contains('TOYOTA') ||
          marca.contains('MAZDA') ||
          marca.contains('CHEVROLET');

      if (mounted) {
        setState(() {
          _vehicleImagePath = data['image_path'] as String?;
        });
      }

      _controller.updateVehicleInfo(model: modelo, isCar: isCar);

      // Verificar Pico y Placa por GPS y si hay Bluetooth vinculado conectado
      if (placa.isNotEmpty) {
        final pico = await PicoYPlacaService().detectAndEvaluate(
          plate: placa,
          isCar: isCar,
          schedulePushReminders: false,
        );
        if (mounted) setState(() => _picoStatus = pico);
      }

      final btConnected =
          await AutoBluetoothTripService().isTargetDeviceConnected(widget.vehiculoId);
      if (btConnected &&
          mounted &&
          _controller.state == NavigationState.idle) {
        AppSnackBar.show(
          context,
          'Bluetooth del vehículo detectado. ¿Iniciar grabación de ruta?',
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Iniciar',
            onPressed: () => _iniciarNav(isFree: true),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _configurarAutoBluetooth() async {
    final current = await AutoBluetoothTripService().getConfig(widget.vehiculoId);
    if (!mounted) return;
    final ctrl = TextEditingController(text: current.deviceName);
    bool enabled = current.enabled;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Auto-Inicio por Bluetooth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cuando tu teléfono se conecte al radio del carro o intercomunicador del casco, la app te sugerirá iniciar la ruta automáticamente.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activar detección'),
                value: enabled,
                onChanged: (v) => setDialogState(() => enabled = v),
              ),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Bluetooth (ej: CAR BT, SENA)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await AutoBluetoothTripService().saveConfig(
                  vehiculoId: widget.vehiculoId,
                  enabled: enabled,
                  deviceName: ctrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  AppSnackBar.show(
                    context,
                    enabled
                        ? 'Auto-inicio Bluetooth guardado (${ctrl.text.trim()})'
                        : 'Auto-inicio Bluetooth desactivado',
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _obtenerUbicacionInicial() async {
    // 1. Obtener la última posición conocida en caché del dispositivo (instantánea en 0ms)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final lastLatLng = LatLng(lastKnown.latitude, lastKnown.longitude);
        _controller.updateCurrentPosition(lastLatLng);
        _mapCtrl.move(lastLatLng, 15);
      }
    } catch (_) {}

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
        return;
      }
    }
    
    // 2. Obtener posición precisa satelital con timeout para no bloquear el renderizado
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _controller.updateCurrentPosition(latLng);
      _mapCtrl.move(latLng, 16);
    } catch (e) {
      debugPrint('Aviso: GPS satelital inicializando en segundo plano: $e');
    }
  }

  void _iniciarSeguimientoIdle() {
    _idlePositionSubscription?.cancel();
    late LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3);
    }

    _idlePositionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      _controller.updateCurrentPosition(latLng, speedMs: position.speed);
    });
  }

  // ─── ACCIONES DE BÚSQUEDA Y MAPA TÁCTIL ─────────────────
  
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _buscarDestino(query);
    });
  }

  Future<void> _buscarDestino(String query, {bool autoSelectFirst = false}) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await NavigationService().searchDestination(query);
      if (mounted) {
        setState(() => _searchResults = results);
        if (autoSelectFirst && results.isNotEmpty) {
          _seleccionarDestino(results.first);
        }
      }
    } catch (_) {
      // Ignorar errores silenciosos en autocompletado
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _seleccionarDestino(NominatimPlace place) {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    // Solo guardamos el destino en el controller — _trazarRuta hará el setRouteReady
    // completo con los puntos reales de OSRM
    _controller.setDestinationOnly(
      destination: LatLng(place.lat, place.lon),
      destinationName: place.displayName,
    );
    _searchCtrl.text = place.displayName;
    setState(() {
      _searchResults = [];
    });
    _trazarRuta();
  }

  /// Manejo táctil del mapa: Toque o Long Press para seleccionar punto de destino
  void _onMapTappedOrLongPressed(LatLng point) async {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchResults = [];
    });

    // Si está en navegación activa, un toque no cambia el destino directamente
    if (_controller.state == NavigationState.navigating || _controller.state == NavigationState.freeTracking) {
      return;
    }

    final curPos = _controller.telemetry.currentPos;
    if (curPos == null) {
      AppSnackBar.show(context, 'Esperando señal GPS...');
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      // 1. Geocodificación inversa para nombre amigable
      final placeName = await NavigationService().reverseGeocode(point);
      _searchCtrl.text = placeName;

      // 2. Calcular ruta vial con OSRM
      final route = await NavigationService().calculateRoute(curPos, point);

      _controller.setRouteReady(
        destination: point,
        destinationName: placeName,
        points: route.points,
        distanceKm: route.distanceKm,
        durationMin: route.durationMin,
        steps: route.steps,
      );

      _mapCtrl.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([curPos, point]),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 90),
        ),
      );
    } catch (e) {
      if (mounted) AppSnackBar.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _trazarRuta() async {
    final curPos = _controller.telemetry.currentPos;
    final dest = _controller.destination;
    if (curPos == null || dest == null) return;
    
    setState(() => _isLoadingRoute = true);
    try {
      final route = await NavigationService().calculateRoute(curPos, dest);
      _controller.setRouteReady(
        destination: dest,
        destinationName: _controller.destinationName,
        points: route.points,
        distanceKm: route.distanceKm,
        durationMin: route.durationMin,
        steps: route.steps,
      );
      _mapCtrl.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([curPos, dest]),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 90),
        ),
      );
    } catch (e) {
      if (mounted) AppSnackBar.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  /// Carga y visualiza en el mapa una ruta seleccionada del historial
  void _cargarRutaDesdeHistorial(Map<String, dynamic> route) async {
    final destName = route['destino_name'] ?? route['destino'] ?? 'Destino Histórico';
    final double dist = ((route['distancia_km'] ?? route['distancia'] ?? 0.0) as num).toDouble();
    final double? vMax = (route['velocidad_max'] as num?)?.toDouble();
    final double? vProm = (route['velocidad_prom'] as num?)?.toDouble();

    List<LatLng> points = [];
    final rawPoints = route['via_puntos'] ?? route['viaPuntos'];
    if (rawPoints != null) {
      try {
        dynamic decoded = rawPoints;
        if (rawPoints is String) decoded = jsonDecode(rawPoints);
        if (decoded is List) {
          for (var p in decoded) {
            if (p is Map) {
              final lat = (p['lat'] ?? p['latitude'] as num?)?.toDouble() ?? 0.0;
              final lng = (p['lng'] ?? p['longitude'] as num?)?.toDouble() ?? 0.0;
              if (lat != 0.0 && lng != 0.0) points.add(LatLng(lat, lng));
            } else if (p is List && p.length >= 2) {
              final lng = (p[0] as num).toDouble();
              final lat = (p[1] as num).toDouble();
              if (lat != 0.0 && lng != 0.0) points.add(LatLng(lat, lng));
            }
          }
        }
      } catch (e) {
        debugPrint('Error parseando puntos históricos: $e');
      }
    }

    if (points.isNotEmpty) {
      _controller.loadHistoricalRoute(
        destinationName: destName,
        points: points,
        distanceKm: dist,
        maxSpeedKmH: vMax,
        avgSpeedKmH: vProm,
      );
      _mapCtrl.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
        ),
      );
      if (mounted) {
        AppSnackBar.show(context, 'Ruta histórica trazada en el mapa.', backgroundColor: const Color(0xFF035880));
      }
    } else {
      final destLat = (route['destino_lat'] as num?)?.toDouble();
      final destLng = (route['destino_lng'] as num?)?.toDouble();
      if (destLat != null && destLng != null && destLat != 0.0 && destLng != 0.0) {
        _searchCtrl.text = destName;
        _onMapTappedOrLongPressed(LatLng(destLat, destLng));
      } else {
        _searchCtrl.text = destName;
        _buscarDestino(destName);
      }
    }
  }

  // ─── CONTROL DE NAVEGACIÓN ──────────────────────────────

  Future<bool> _ensureBackgroundLocationPermissions() async {
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Activa el GPS de tu teléfono para grabar la ruta con precisión.',
          action: SnackBarAction(
            label: 'Ajustes',
            onPressed: () => Geolocator.openLocationSettings(),
          ),
        );
      }
      return false;
    }

    var whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) {
      whenInUse = await Permission.locationWhenInUse.request();
      if (!whenInUse.isGranted) {
        if (mounted) {
          AppSnackBar.show(
            context,
            'Permiso de ubicación necesario para trazar tu recorrido.',
            action: SnackBarAction(
              label: 'Ajustes',
              onPressed: () => openAppSettings(),
            ),
          );
        }
        return false;
      }
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      var alwaysStatus = await Permission.locationAlways.status;
      if (!alwaysStatus.isGranted && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('GPS con pantalla suspendida'),
            content: const Text(
              'Para seguir grabando toda tu ruta curva a curva cuando apagues la pantalla:\n\n'
              '1) En Ubicación selecciona "Permitir todo el tiempo".\n'
              '2) Permite desactivar la restricción de batería para My Auto Guide.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuar sin esto'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Configurar ahora'),
              ),
            ],
          ),
        );

        if (proceed == true) {
          alwaysStatus = await Permission.locationAlways.request();
          if (!alwaysStatus.isGranted && alwaysStatus.isPermanentlyDenied) {
            await openAppSettings();
          }
        }
      }

      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    return true;
  }

  Future<void> _iniciarNav({bool isFree = false}) async {
    if (_isStartingNav) return;
    _isStartingNav = true;
    try {
      _searchFocusNode.unfocus();
      FocusScope.of(context).unfocus();

      final canStart = await _ensureBackgroundLocationPermissions();
      if (!canStart || !mounted) return;

      // Evitar listeners duplicados mientras corre el servicio en segundo plano
      await _idlePositionSubscription?.cancel();
      _idlePositionSubscription = null;

      await BackgroundNavService.resetRouteStorage(
        initialPoint: _controller.telemetry.currentPos,
      );

      final service = FlutterBackgroundService();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_nav_vehicle_id', widget.vehiculoId);
      await prefs.setBool('is_navigating', true);
      // VULN-01: Credenciales guardadas en almacenamiento cifrado (no SharedPreferences)
      await SecureStorageService().saveSupabaseCredentials(
        url: dotenv.get('SUPABASE_URL'),
        anonKey: dotenv.get('SUPABASE_ANON_KEY'),
      );

      if (!(await service.isRunning())) {
        await service.startService();
        await Future.delayed(const Duration(milliseconds: 600));
      }

      _autoFollow = true;
      _controller.startNavigation(isFree: isFree);

      final curPos = _controller.telemetry.currentPos;
      if (curPos != null) {
        _mapCtrl.move(curPos, 16.5);
      }
    } finally {
      _isStartingNav = false;
    }
  }

  Future<void> _finalizarRuta({bool skipSummaryModal = false}) async {
    if (_isFinalizing) return;
    _isFinalizing = true;

    // Recuperar cualquier tramo grabado en segundo plano antes de cerrar
    await _controller.syncFromBackgroundStorage();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_navigating', false);

      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
      }
    } catch (e) {
      debugPrint('Error deteniendo background service: $e');
    }
    
    final t = _controller.telemetry;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: No se encontró sesión de usuario activa para guardar el trayecto.');
      }
      _controller.stopNavigation();
      _isFinalizing = false;
      return;
    }

    final durationSec = t.startTime != null ? DateTime.now().difference(t.startTime!).inSeconds : 0;
    
    // Calcular velocidad promedio cinemática exacta
    final double calculatedAvgSpeed = TelemetryCalculator.calculateKinematicAverageSpeed(
      distanceKm: t.distanceKm,
      durationSeconds: durationSec,
      fallbackSpeedKmH: t.averageSpeedKmH,
    );

    final impact = TelemetryCalculator.estimateImpact(
      distanceKm: t.distanceKm, 
      avgSpeedKmH: calculatedAvgSpeed, 
      vehicleModel: _controller.vehicleModel, 
      isCar: _controller.isCar
    );

    final int kmsToAdd = (t.distanceKm >= 0.1)
        ? (t.distanceKm < 1.0 ? 1 : t.distanceKm.round())
        : 0;

    final String destName = (_controller.destinationName.trim().isNotEmpty)
        ? _controller.destinationName
        : 'Recorrido Libre';

    if (t.distanceKm >= 0.01) {
      // Guardar de forma asíncrona segura sin congelar el hilo principal
      unawaited(() async {
        try {
          await SyncService().saveRouteOfflineFirst(
            userId: userId,
            vehicleId: widget.vehiculoId,
            originName: 'Ubicación Actual',
            destinationName: destName,
            distanceKm: t.distanceKm,
            durationSeconds: durationSec,
            consumoGalones: impact['gallons']!,
            costoEstimado: impact['cost']!,
            velocidadMax: t.maxSpeedKmH,
            velocidadProm: calculatedAvgSpeed,
            viaPuntos: t.travelledPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
          );
          
          if (kmsToAdd > 0) {
            await SyncService().updateVehicleKmsOfflineFirst(widget.vehiculoId, kmsToAdd);
          }
        } catch (e) {
          debugPrint('Error al guardar trayecto localmente: $e');
        }
      }());
    } else {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Recorrido finalizado. No se registraron distancias significativas.',
          backgroundColor: Colors.orange,
        );
      }
    }

    _controller.stopNavigation();

    // Mostrar modal con el resumen visual del recorrido y limpiar polilínea al cerrar
    if (mounted && !skipSummaryModal && (t.distanceKm >= 0.01 || durationSec >= 10)) {
      try {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => TripSummarySheet(
            distanceKm: t.distanceKm,
            durationSeconds: durationSec,
            avgSpeedKmH: calculatedAvgSpeed,
            maxSpeedKmH: t.maxSpeedKmH,
            fuelGallons: impact['gallons'] ?? 0.0,
            estimatedCost: impact['cost'] ?? 0.0,
            destinationName: destName,
            onDismiss: () {
              if (Navigator.canPop(ctx)) {
                Navigator.pop(ctx);
              }
            },
          ),
        );
      } catch (e) {
        debugPrint('Aviso modal resumen: $e');
      }
    }

    _controller.clearRouteAndReset();
    _iniciarSeguimientoIdle();
    _isFinalizing = false;
  }

  void _recenterMap() {
    setState(() => _autoFollow = true);
    final curPos = _controller.telemetry.currentPos;
    if (curPos != null) {
      _mapCtrl.move(curPos, 16.5);
    }
  }

  // ─── BUILD UI ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _controller.telemetry;
    final state = _controller.state;

    return PopScope(
      canPop: state != NavigationState.navigating && state != NavigationState.freeTracking,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ruta en curso'),
            content: const Text('¿Deseas finalizar y guardar el recorrido actual antes de salir?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salir sin guardar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx, false);
                  await _finalizarRuta();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Guardar y Salir'),
              ),
            ],
          ),
        );
        if (ok == true && mounted) {
          _controller.stopNavigation();
          final service = FlutterBackgroundService();
          service.invoke('stopService');
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () {
            _searchFocusNode.unfocus();
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              _buildMap(t),
              if (state != NavigationState.navigating) _buildTopSearch(),
              
              // Banner Turn-by-Turn durante Navegación
              if (state == NavigationState.navigating && _controller.currentStep != null)
                _buildTurnByTurnBanner(_controller.currentStep!, t),

              // Alertas de Fotomulta y Radar
              StreamBuilder<RadarAlertState>(
                stream: CameraRadarService().alertStream,
                builder: (context, snapshot) {
                  final alert = snapshot.data ?? RadarAlertState.clear();
                  final isSpeeding = alert.isSpeeding;
                  final isNear = alert.isNearCamera;

                  return Stack(
                    children: [
                      Positioned(
                        top: 0, left: 0, right: 0,
                        height: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSpeeding
                                ? Colors.redAccent
                                : (isNear ? Colors.orangeAccent : const Color(0xFF00FF87)),
                            boxShadow: [
                              BoxShadow(
                                color: isSpeeding
                                    ? Colors.red.withOpacity(0.8)
                                    : (isNear ? Colors.orange.withOpacity(0.8) : const Color(0xFF00FF87).withOpacity(0.5)),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      ),
                      if (isNear && alert.nearestCamera != null)
                        Positioned(
                          top: 110, left: 20, right: 20,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSpeeding
                                      ? const Color(0xFFFF3B30).withOpacity(0.85)
                                      : const Color(0xFF1C1C1E).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSpeeding ? Colors.redAccent : Colors.orangeAccent.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      color: isSpeeding ? Colors.white : Colors.orangeAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '📷 FOTOMULTA a ${alert.distanceMeters.round()}m (${alert.nearestCamera!.city})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Límite: ${alert.nearestCamera!.speedLimitKmH.round()} km/h | Actual: ${alert.currentSpeedKmH.round()} km/h',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Botones Flotantes Laterales (Reportes Waze y Recentrar)
              Positioned(
                right: 16,
                bottom: (state == NavigationState.navigating || state == NavigationState.routeReady) ? 220 : 160,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(
                      builder: (ctx) {
                        final isDark = Theme.of(ctx).brightness == Brightness.dark;
                        final currentStyle =
                            _mapStyle ?? (isDark ? MapStyle.dark : MapStyle.street);
                        return FloatingActionButton.small(
                          heroTag: 'btn_map_style',
                          tooltip: 'Vista: ${currentStyle.label}',
                          backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                          onPressed: () {
                            final nextStyle = currentStyle.next;
                            setState(() => _mapStyle = nextStyle);
                            AppSnackBar.show(
                              context,
                              'Mapa: ${nextStyle.label}',
                              duration: const Duration(seconds: 2),
                            );
                          },
                          child: Icon(
                            currentStyle.icon,
                            color: const Color(0xFF38BDF8),
                            size: 20,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'btn_voice_nav',
                      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                      onPressed: () {
                        setState(() {
                          VoiceNavigationService().toggleMute();
                        });
                        AppSnackBar.show(
                          context,
                          VoiceNavigationService().isMuted ? 'Guía por voz desactivada' : 'Guía por voz activada',
                          backgroundColor: VoiceNavigationService().isMuted ? Colors.grey[800]! : const Color(0xFF00FF87),
                        );
                      },
                      child: Icon(
                        VoiceNavigationService().isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: VoiceNavigationService().isMuted ? Colors.white54 : const Color(0xFF00FF87),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'btn_fuel_prices',
                      tooltip: 'Precios Gasolina',
                      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                      onPressed: () {
                        final pos = t.currentPos ?? const LatLng(4.6097, -74.0817);
                        FuelPricesSheet.show(
                          context,
                          lat: pos.latitude,
                          lng: pos.longitude,
                          city: _picoStatus?.cityName ?? 'Colombia',
                        );
                      },
                      child: const Icon(Icons.local_gas_station_rounded, color: Color(0xFFFF9500), size: 20),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'btn_auto_bt',
                      tooltip: 'Auto-Inicio Bluetooth',
                      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                      onPressed: _configurarAutoBluetooth,
                      child: const Icon(Icons.bluetooth_audio_rounded, color: Color(0xFF38BDF8), size: 20),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'btn_recenter_map',
                      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
                      onPressed: _recenterMap,
                      child: Icon(
                        Icons.my_location_rounded,
                        color: _autoFollow ? const Color(0xFF00FF87) : Colors.white70,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'btn_waze_report',
                      backgroundColor: const Color(0xFF0A84FF),
                      onPressed: () {
                        final pos = t.currentPos;
                        if (pos != null) {
                          WazeReportSheet.show(
                            context,
                            lat: pos.latitude,
                            lng: pos.longitude,
                            isCar: _controller.isCar,
                          );
                        }
                      },
                      child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              _buildBottomPanel(t, state),
              if (_isLoadingRoute)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(NavigationTelemetry t) {
    final centerPos = t.currentPos ?? const LatLng(4.6097, -74.0817);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeStyle = _mapStyle ?? (isDark ? MapStyle.dark : MapStyle.street);

    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: centerPos,
        initialZoom: 15,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _autoFollow) {
            setState(() => _autoFollow = false);
          }
        },
        onTap: (tapPosition, point) => _onMapTappedOrLongPressed(point),
        onLongPress: (tapPosition, point) => _onMapTappedOrLongPressed(point),
      ),
      children: [
        MapTileConfig.buildTileLayer(style: activeStyle),
        if (_controller.routePoints.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(
              points: _controller.routePoints,
              strokeWidth: 8,
              color: Colors.blue.withOpacity(0.35),
            ),
            Polyline(
              points: _controller.routePoints,
              strokeWidth: 4.5,
              color: const Color(0xFF00C6FF),
            ),
          ]),
        if (t.travelledPoints.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(
              points: t.travelledPoints,
              strokeWidth: 9,
              color: Colors.green.withOpacity(0.35),
            ),
            Polyline(
              points: t.travelledPoints,
              strokeWidth: 5,
              color: const Color(0xFF00FF87),
            ),
          ]),
        MarkerLayer(markers: [
          if (_controller.destination != null)
            Marker(
              point: _controller.destination!,
              width: 48,
              height: 48,
              child: const Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 44,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          Marker(
            point: t.currentPos!,
            width: 45,
            height: 45,
            child: PulsingLocationMarker(imagePath: _vehicleImagePath),
          ),
        ]),
        StreamBuilder<List<WazeIncidentReport>>(
          stream: WazeCommunityAlertsService().incidentsStream,
          initialData: WazeCommunityAlertsService().currentIncidents,
          builder: (context, snapshot) {
            final alerts = snapshot.data ?? [];
            final markers = alerts.map((a) {
              IconData iconData = Icons.warning_rounded;
              Color iconColor = Colors.orange;

              switch (a.type) {
                case WazeIncidentType.police:
                  iconData = Icons.local_police_rounded;
                  iconColor = const Color(0xFF0A84FF);
                  break;
                case WazeIncidentType.radar:
                  iconData = Icons.camera_alt_rounded;
                  iconColor = const Color(0xFFFF9500);
                  break;
                case WazeIncidentType.accident:
                  iconData = Icons.car_crash_rounded;
                  iconColor = const Color(0xFFFF3B30);
                  break;
                case WazeIncidentType.construction:
                  iconData = Icons.construction_rounded;
                  iconColor = const Color(0xFFFFCC00);
                  break;
                case WazeIncidentType.flooding:
                  iconData = Icons.water_drop_rounded;
                  iconColor = const Color(0xFF30D158);
                  break;
                case WazeIncidentType.pothole:
                  iconData = Icons.warning_amber_rounded;
                  iconColor = const Color(0xFFF59E0B);
                  break;
                case WazeIncidentType.speedBump:
                  iconData = Icons.speed_rounded;
                  iconColor = const Color(0xFFA855F7);
                  break;
                case WazeIncidentType.tollQueue:
                  iconData = Icons.toll_rounded;
                  iconColor = const Color(0xFF38BDF8);
                  break;
              }

              return Marker(
                point: LatLng(a.latitude, a.longitude),
                width: 38,
                height: 38,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(a.title),
                        content: const Text('Reportado por la comunidad. ¿Sigue ahí el incidente?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              WazeCommunityAlertsService().voteIncident(id: a.id, isStillThere: false);
                              Navigator.pop(ctx);
                              AppSnackBar.show(context, 'Gracias por confirmar.');
                            },
                            child: const Text('No / Se retiró', style: TextStyle(color: Colors.red)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              WazeCommunityAlertsService().voteIncident(id: a.id, isStillThere: true);
                              Navigator.pop(ctx);
                              AppSnackBar.show(context, '¡Gracias por confirmar!', backgroundColor: Colors.green);
                            },
                            child: const Text('Sí, sigue ahí'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                ),
              );
            }).toList();

            return MarkerLayer(markers: markers);
          },
        ),
      ],
    );
  }

  IconData _getManeuverIcon(String type, String? modifier, String instruction) {
    final text = instruction.toLowerCase();
    final mod = (modifier ?? '').toLowerCase();
    final t = type.toLowerCase();

    // 1. Llegada a destino
    if (t == 'arrive' || text.contains('llegado') || text.contains('destino')) {
      return Icons.flag_circle_rounded;
    }

    // 2. Giros en U (Retorno)
    if (mod == 'uturn' || text.contains('giro en u') || text.contains('retorno') || text.contains('retorne')) {
      return Icons.u_turn_left_rounded;
    }

    // 3. Giros a la izquierda (Curva hacia la izquierda)
    if (mod.contains('left') || text.contains('izquierda') || text.contains('izq')) {
      if (mod == 'sharp left' || text.contains('pronunciado')) {
        return Icons.turn_sharp_left_rounded;
      }
      if (mod == 'slight left' || text.contains('levemente')) {
        return Icons.turn_slight_left_rounded;
      }
      return Icons.turn_left_rounded;
    }

    // 4. Giros a la derecha (Curva hacia la derecha)
    if (mod.contains('right') || text.contains('derecha') || text.contains('der')) {
      if (mod == 'sharp right' || text.contains('pronunciado')) {
        return Icons.turn_sharp_right_rounded;
      }
      if (mod == 'slight right' || text.contains('levemente')) {
        return Icons.turn_slight_right_rounded;
      }
      return Icons.turn_right_rounded;
    }

    // 5. Rotondas / Glorietas
    if (t == 'roundabout' || t == 'rotary' || text.contains('rotonda') || text.contains('glorieta')) {
      return Icons.roundabout_right_rounded;
    }

    // 6. Bifurcaciones
    if (t == 'fork' || text.contains('bifurcación')) {
      return mod == 'left' ? Icons.fork_left_rounded : Icons.fork_right_rounded;
    }

    // 7. Incorporaciones
    if (t == 'merge' || text.contains('incorpórate')) {
      return Icons.merge_rounded;
    }

    // 8. Seguir derecho / Recto
    return Icons.straight_rounded;
  }

  Widget _buildTurnByTurnBanner(NavigationStep step, NavigationTelemetry t) {
    final curPos = t.currentPos;
    final int distanceMeters = (curPos != null)
        ? const Distance().as(LengthUnit.Meter, curPos, step.location).round()
        : step.distanceMeters.round();

    final String distanceStr = (distanceMeters <= 25)
        ? '¡Gira ahora!'
        : (distanceMeters < 1000 ? 'En $distanceMeters m' : 'En ${(distanceMeters / 1000).toStringAsFixed(1)} km');

    final icon = _getManeuverIcon(step.maneuverType, step.modifier, step.instruction);

    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF035880), Color(0xFF0A2342)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF87),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF87).withOpacity(0.4),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Icon(icon, color: Colors.black, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        distanceStr,
                        style: const TextStyle(
                          color: Color(0xFF00FF87),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: 50, left: 16, right: 16,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.88) : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: (val) {
                    _searchFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    if (val.trim().isNotEmpty) {
                      _buscarDestino(val.trim(), autoSelectFirst: true);
                    }
                  },
                  onTapOutside: (_) => _searchFocusNode.unfocus(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: '¿A dónde vas? (Toca o mantén en el mapa)',
                    hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black54),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _controller.clearRouteAndReset();
                              setState(() => _searchResults = []);
                            },
                          ),
                        IconButton(
                          tooltip: 'Historial de Rutas',
                          icon: Icon(Icons.history_rounded, color: isDark ? Colors.white70 : Colors.black54), 
                          onPressed: () async {
                            _searchFocusNode.unfocus();
                            FocusScope.of(context).unfocus();
                            final selected = await Navigator.push<Map<String, dynamic>>(
                              context, 
                              MaterialPageRoute(builder: (_) => HistorialRutasScreen(vehiculoId: widget.vehiculoId)),
                            );
                            if (selected != null) {
                              _cargarRutaDesdeHistorial(selected);
                            }
                          },
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 250,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.92) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                    itemBuilder: (ctx, i) => ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: Color(0xFF00C6FF), size: 20),
                      title: Text(
                        _searchResults[i].displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => _seleccionarDestino(_searchResults[i]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(NavigationTelemetry t, NavigationState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14171F).withOpacity(0.92) : Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── 1. MODO NAVEGANDO O RECORRIDO LIBRE ─────────
                if (state == NavigationState.navigating || state == NavigationState.freeTracking) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoChip(
                        icon: Icons.speed_rounded,
                        label: '${t.maxSpeedKmH.toStringAsFixed(0)} km/h máx',
                        color: const Color(0xFF00C6FF),
                      ),
                      InfoChip(
                        icon: Icons.straighten_rounded,
                        label: '${t.distanceKm.toStringAsFixed(2)} km',
                        color: const Color(0xFF00FF87),
                      ),
                      InfoChip(
                        icon: Icons.av_timer_rounded,
                        label: '${t.averageSpeedKmH.toStringAsFixed(0)} km/h prom',
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _finalizarRuta,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('FINALIZAR VIAJE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.9),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ] 
                // ─── 2. MODO CÓMO LLEGAR (RUTA LISTA) ─────────────
                else if (state == NavigationState.routeReady) ...[
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.destinationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => _controller.clearRouteAndReset(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (_) {
                      final tolls = ColombiaTollsService.estimateRouteTolls(
                        _controller.routePoints,
                        isCar: _controller.isCar,
                      );
                      return Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          InfoChip(
                            icon: Icons.straighten_rounded,
                            label: '${_controller.routeDistanceKm.toStringAsFixed(1)} km',
                            color: const Color(0xFF00C6FF),
                          ),
                          InfoChip(
                            icon: Icons.timer_outlined,
                            label: '${_controller.routeDurationMin.round()} min',
                            color: Colors.orangeAccent,
                          ),
                          if (tolls.count > 0)
                            InfoChip(
                              icon: Icons.toll_rounded,
                              label: _controller.isCar
                                  ? '${tolls.count} peaje(s) ~\$${(tolls.totalCostCop / 1000).toStringAsFixed(1)}k'
                                  : '${tolls.count} peaje(s) Moto \$0',
                              color: const Color(0xFF00FF87),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _iniciarNav(),
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text('INICIAR NAVEGACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF035880),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
                // ─── 3. MODO VISUALIZACIÓN DE RUTA HISTÓRICA ───────
                else if (state == NavigationState.viewingHistory) ...[
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Color(0xFF00FF87), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.destinationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => _controller.clearRouteAndReset(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoChip(
                        icon: Icons.straighten_rounded,
                        label: '${_controller.routeDistanceKm.toStringAsFixed(1)} km',
                        color: const Color(0xFF00C6FF),
                      ),
                      InfoChip(
                        icon: Icons.speed_rounded,
                        label: '${_controller.telemetry.maxSpeedKmH.toStringAsFixed(0)} km/h',
                        color: const Color(0xFFFF3B30),
                      ),
                      InfoChip(
                        icon: Icons.av_timer_rounded,
                        label: '${_controller.telemetry.averageSpeedKmH.toStringAsFixed(0)} km/h',
                        color: const Color(0xFF00FF87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _controller.clearRouteAndReset(),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('CERRAR VISTA DE RUTA', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF035880),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ]
                // ─── 4. MODO LIVE IDLE DE ESPERA ───────────────────
                else ...[
                  FilledButton.icon(
                    onPressed: () => _iniciarNav(isFree: true),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('INICIAR RECORRIDO LIBRE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF035880),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PulsingLocationMarker extends StatefulWidget {
  final String? imagePath;
  const PulsingLocationMarker({super.key, this.imagePath});
  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44 * _animCtrl.value,
              height: 44 * _animCtrl.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C6FF).withOpacity(1.0 - _animCtrl.value),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF00C6FF), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: ClipOval(
                child: widget.imagePath != null && widget.imagePath!.isNotEmpty
                    ? Image.asset(
                        widget.imagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.motorcycle,
                          size: 18,
                          color: Color(0xFF00C6FF),
                        ),
                      )
                    : const Icon(
                        Icons.motorcycle,
                        size: 18,
                        color: Color(0xFF00C6FF),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
