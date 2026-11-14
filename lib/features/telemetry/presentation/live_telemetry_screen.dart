import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../navigation/logic/map_tile_config.dart';
import '../../../../shared/widgets/smart_vehicle_image.dart';

/// Modos de visualización para la cabina de telemetría GPS
enum TelemetryViewMode {
  map,
  cockpit,
  hud,
}

/// Pantalla de Telemetría GPS y Cockpit de Rendimiento en Vivo (Web y Móvil)
/// Permite monitorear la ubicación en tiempo real, velocímetro dinámico de plasma,
/// tacómetro analógico-digital con simulación de ralentí y modo HUD parabrisas invertido.
class LiveTelemetryScreen extends StatefulWidget {
  final String vehicleId;
  final String placa;
  final String marca;
  final String modelo;
  final String? imagePath;

  const LiveTelemetryScreen({
    super.key,
    required this.vehicleId,
    required this.placa,
    required this.marca,
    required this.modelo,
    this.imagePath,
  });

  @override
  State<LiveTelemetryScreen> createState() => _LiveTelemetryScreenState();
}

class _LiveTelemetryScreenState extends State<LiveTelemetryScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final supabase = Supabase.instance.client;

  RealtimeChannel? _trackingChannel;
  LatLng _currentLocation = const LatLng(6.2442, -75.5812); // Medellín por defecto
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _distanceTraveled = 0.0;
  double _heading = 0.0;
  DateTime? _lastPing;
  bool _isLive = false;
  bool _autoCenter = true;
  final List<LatLng> _liveTrail = [];

  TelemetryViewMode _viewMode = TelemetryViewMode.map;
  late final AnimationController _idlePulseController;
  final Stopwatch _tripStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _tripStopwatch.start();
    _idlePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _loadLastKnownPosition();
    _subscribeToLiveTracking();
  }

  @override
  void dispose() {
    _idlePulseController.dispose();
    _tripStopwatch.stop();
    _trackingChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadLastKnownPosition() async {
    try {
      final res = await supabase
          .from('routes')
          .select('via_puntos, distancia_km, created_at')
          .eq('vehicle_id', widget.vehicleId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null && mounted) {
        final puntos = res['via_puntos'];
        if (puntos is List && puntos.isNotEmpty) {
          final first = puntos.last;
          if (first is Map && first['lat'] != null && first['lng'] != null) {
            setState(() {
              _currentLocation = LatLng(
                (first['lat'] as num).toDouble(),
                (first['lng'] as num).toDouble(),
              );
            });
            _mapController.move(_currentLocation, 15);
          }
        }
      }
    } catch (_) {}
  }

  void _subscribeToLiveTracking() {
    final channelName = 'tracking:${widget.vehicleId}';
    _trackingChannel = supabase.channel(channelName);

    // Escuchar broadcast directo desde el teléfono en ruta
    _trackingChannel!.onBroadcast(
      event: 'location_update',
      callback: (payload) {
        if (!mounted) return;
        final lat = (payload['lat'] as num?)?.toDouble();
        final lng = (payload['lng'] as num?)?.toDouble();
        final spd = (payload['speed'] as num?)?.toDouble() ?? 0.0;
        final dst = (payload['dist'] as num?)?.toDouble() ?? 0.0;
        final hdg = (payload['heading'] as num?)?.toDouble() ?? 0.0;

        if (lat != null && lng != null) {
          final newPos = LatLng(lat, lng);
          setState(() {
            _currentLocation = newPos;
            _currentSpeed = spd;
            if (spd > _maxSpeed) _maxSpeed = spd;
            _distanceTraveled = dst;
            _heading = hdg;
            _lastPing = DateTime.now();
            _isLive = true;
            _liveTrail.add(newPos);
            if (_liveTrail.length > 500) {
              _liveTrail.removeAt(0);
            }
          });

          if (_autoCenter && _viewMode == TelemetryViewMode.map) {
            _mapController.move(newPos, _mapController.camera.zoom);
          }
        }
      },
    );

    // Escuchar estado de presencia para detectar si el celular está en ruta activa
    _trackingChannel!.onPresenceSync((_) {
      if (!mounted) return;
      final presenceState = _trackingChannel!.presenceState();
      final isOnline = presenceState.isNotEmpty;
      setState(() {
        _isLive = isOnline;
      });
    });

    _trackingChannel!.subscribe();
  }

  int _calculateVirtualRpm(double speed) {
    if (speed < 1.0) {
      // Ralentí oscilante con respiración realista
      final pulse = _idlePulseController.value;
      final bool isCar = widget.marca.toLowerCase().contains('carro') ||
          widget.modelo.toLowerCase().contains('carro');
      final int baseIdle = isCar ? 820 : 1180;
      return (baseIdle + (pulse * 90)).round();
    }
    // Proporcional a la velocidad y marcha
    return (1400 + (speed * 72)).clamp(1000, 11500).round();
  }

  String _calculateVirtualGear(double speed) {
    if (speed < 1.0) return 'N';
    if (speed < 24.0) return '1';
    if (speed < 44.0) return '2';
    if (speed < 64.0) return '3';
    if (speed < 85.0) return '4';
    if (speed < 110.0) return '5';
    return '6';
  }

  double _calculateEstimatedGForce(double speed) {
    if (speed < 1.0) return 0.0;
    // Estimación dinámica suave para visualización de telemetría deportiva
    final base = (speed / 120.0).clamp(0.0, 1.0);
    return double.parse((0.15 + base * 0.70).toStringAsFixed(2));
  }

  String _formatTripTimer(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final bool isHud = _viewMode == TelemetryViewMode.hud;

    return Scaffold(
      backgroundColor: isHud ? Colors.black : const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: isHud ? Colors.black : const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isLive
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isLive ? const Color(0xFF00E5FF) : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLive
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFFFFA000),
                      boxShadow: _isLive
                          ? const [
                              BoxShadow(
                                color: Color(0xFF00E5FF),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isLive ? 'EN VIVO' : 'ESTACIONADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: _isLive
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFFFFA000),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.placa.toUpperCase()} — ${widget.marca} ${widget.modelo}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Selector de modo de telemetría (Mapa / Cockpit / HUD)
          _buildViewModeToggle(TelemetryViewMode.map, Icons.map_rounded, 'Mapa'),
          _buildViewModeToggle(TelemetryViewMode.cockpit, Icons.speed_rounded, 'Pista'),
          _buildViewModeToggle(TelemetryViewMode.hud, Icons.screen_rotation_rounded, 'HUD'),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildCurrentViewBody(),
      ),
    );
  }

  Widget _buildViewModeToggle(TelemetryViewMode mode, IconData icon, String label) {
    final bool isSelected = _viewMode == mode;
    return InkWell(
      onTap: () {
        if (!kIsWeb) HapticFeedback.selectionClick();
        setState(() => _viewMode = mode);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFF00E5FF) : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentViewBody() {
    switch (_viewMode) {
      case TelemetryViewMode.map:
        return _buildMapView();
      case TelemetryViewMode.cockpit:
        return _buildCockpitView(isMirrored: false);
      case TelemetryViewMode.hud:
        return _buildCockpitView(isMirrored: true);
    }
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // 1. Mapa Leaflet / OpenStreetMap interactivo
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 15,
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _autoCenter) {
                setState(() => _autoCenter = false);
              }
            },
          ),
          children: [
            MapTileConfig.buildTileLayer(style: MapStyle.dark),
            if (_liveTrail.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _liveTrail,
                    strokeWidth: 4,
                    color: const Color(0xFF00E5FF),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation,
                  width: 64,
                  height: 64,
                  child: Transform.rotate(
                    angle: (_heading * (math.pi / 180.0)),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                            border: Border.all(
                              color: const Color(0xFF00E5FF),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF00E5FF),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.navigation_rounded,
                          size: 32,
                          color: Color(0xFF00E5FF),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. HUD Flotante con métricas en tiempo real
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              _buildMetricCard(
                label: 'VELOCIDAD',
                value: '${_currentSpeed.toStringAsFixed(0)} km/h',
                icon: Icons.speed_rounded,
                accentColor: const Color(0xFF00E5FF),
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                label: 'DISTANCIA',
                value: '${_distanceTraveled.toStringAsFixed(2)} km',
                icon: Icons.alt_route_rounded,
                accentColor: const Color(0xFF30D158),
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                label: 'ACTUALIZACIÓN',
                value: _lastPing != null
                    ? '${DateTime.now().difference(_lastPing!).inSeconds}s'
                    : 'N/A',
                icon: Icons.sync_rounded,
                accentColor: const Color(0xFFFFD60A),
              ),
            ],
          ),
        ),

        // 3. Mini Tacómetro Flotante en la esquina inferior izquierda
        Positioned(
          bottom: 100,
          right: 16,
          child: InkWell(
            onTap: () {
              if (!kIsWeb) HapticFeedback.mediumImpact();
              setState(() => _viewMode = TelemetryViewMode.cockpit);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed_rounded, color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_currentSpeed.toStringAsFixed(0)} KM/H',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${_calculateVirtualRpm(_currentSpeed)} RPM • MARCH ${_calculateVirtualGear(_currentSpeed)}',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.w700,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 4. Tarjeta informativa inferior
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: SmartVehicleImage(
                    imagePath: widget.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.marca} ${widget.modelo}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isLive
                            ? 'Transmitiendo telemetría en vivo vía WebSockets'
                            : 'Vehículo en pausa o estacionado',
                        style: TextStyle(
                          color: _isLive ? const Color(0xFF00E5FF) : Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Centrar en vehículo',
                  icon: Icon(
                    Icons.my_location_rounded,
                    color: _autoCenter ? const Color(0xFF00E5FF) : Colors.white60,
                  ),
                  onPressed: () {
                    setState(() => _autoCenter = !_autoCenter);
                    _mapController.move(_currentLocation, 16);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCockpitView({required bool isMirrored}) {
    final int currentRpm = _calculateVirtualRpm(_currentSpeed);
    final String currentGear = _calculateVirtualGear(_currentSpeed);
    final double gForce = _calculateEstimatedGForce(_currentSpeed);
    final String tripTime = _formatTripTimer(_tripStopwatch.elapsed);

    Widget cockpitContent = Container(
      color: isMirrored ? Colors.black : const Color(0xFF080C16),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isMirrored)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                  ),
                  child: const Text(
                    'MODO HUD PARABRISAS ACTIVO • COLOCA EL TELÉFONO EN EL TABLERO',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

              // 1. TACÓMETRO & VELOCÍMETRO ANALÓGICO-DIGITAL 240°
              Center(
                child: AnimatedBuilder(
                  animation: _idlePulseController,
                  builder: (context, _) {
                    return SizedBox(
                      width: 290,
                      height: 290,
                      child: CustomPaint(
                        painter: _TachometerGaugePainter(
                          speed: _currentSpeed,
                          rpm: currentRpm,
                          maxRpm: 12000,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 18),
                              // Marcha virtual
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: currentGear == 'N'
                                      ? const Color(0xFF30D158).withValues(alpha: 0.2)
                                      : const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: currentGear == 'N'
                                        ? const Color(0xFF30D158)
                                        : const Color(0xFF00E5FF),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  'MARCHA $currentGear',
                                  style: TextStyle(
                                    color: currentGear == 'N'
                                        ? const Color(0xFF30D158)
                                        : const Color(0xFF00E5FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Velocidad digital grande
                              Text(
                                _currentSpeed.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 68,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                'KM/H',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E5FF),
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$currentRpm RPM',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: currentRpm > 9000
                                      ? const Color(0xFFFF453A)
                                      : (currentRpm > 6500
                                          ? const Color(0xFFFFD60A)
                                          : const Color(0xFF30D158)),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 2. Barra dinámica de Aceleración y Fuerzas G
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMirrored
                      ? const Color(0xFF111111)
                      : const Color(0xFF0F172A).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FUERZA G / ACELERACIÓN:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${gForce.toStringAsFixed(2)} G',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (gForce / 1.5).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          gForce > 0.8
                              ? const Color(0xFFFF453A)
                              : (gForce > 0.4
                                  ? const Color(0xFFFFD60A)
                                  : const Color(0xFF00E5FF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Grid de Estadísticas de Telemetría de Pista
              Row(
                children: [
                  _buildTrackMetricCard(
                    title: 'VEL. MÁXIMA',
                    value: '${_maxSpeed.toStringAsFixed(0)} km/h',
                    icon: Icons.rocket_launch_rounded,
                    accent: const Color(0xFFFF9500),
                  ),
                  const SizedBox(width: 12),
                  _buildTrackMetricCard(
                    title: 'DISTANCIA',
                    value: '${_distanceTraveled.toStringAsFixed(2)} km',
                    icon: Icons.route_rounded,
                    accent: const Color(0xFF30D158),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTrackMetricCard(
                    title: 'CRONÓMETRO',
                    value: tripTime,
                    icon: Icons.timer_outlined,
                    accent: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 12),
                  _buildTrackMetricCard(
                    title: 'RUMBO',
                    value: '${_heading.toStringAsFixed(0)}°',
                    icon: Icons.explore_rounded,
                    accent: const Color(0xFFBF5AF2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // En Modo HUD, invertimos horizontalmente toda la pantalla para el reflejo sobre el cristal panorámico
    if (isMirrored) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
        child: cockpitContent,
      );
    }

    return cockpitContent;
  }

  Widget _buildTrackMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Outfit',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pintor del arco de tacómetro LED dinámico de 240 grados
class _TachometerGaugePainter extends CustomPainter {
  final double speed;
  final int rpm;
  final int maxRpm;

  _TachometerGaugePainter({
    required this.speed,
    required this.rpm,
    required this.maxRpm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 18;

    const startAngle = 140.0 * (math.pi / 180.0);
    const sweepTotal = 260.0 * (math.pi / 180.0);

    // 1. Pista de fondo
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // 2. Arco activo con gradiente de plasma
    final double sweepFraction = (rpm / maxRpm).clamp(0.0, 1.0);
    final double activeSweep = sweepTotal * sweepFraction;

    if (activeSweep > 0.02) {
      final activePaint = Paint()
        ..shader = const SweepGradient(
          startAngle: 140.0 * (math.pi / 180.0),
          endAngle: 400.0 * (math.pi / 180.0),
          colors: [
            Color(0xFF00E5FF),
            Color(0xFF30D158),
            Color(0xFFFFD60A),
            Color(0xFFFF453A),
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }

    // 3. Ticks radiales (marcas de RPM cada 1000)
    final tickPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.6;

    for (int i = 0; i <= 12; i++) {
      final double fraction = i / 12.0;
      final double angle = startAngle + (sweepTotal * fraction);
      final double innerR = radius - (i % 2 == 0 ? 18 : 12);
      final double outerR = radius - 6;

      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TachometerGaugePainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.rpm != rpm;
  }
}
