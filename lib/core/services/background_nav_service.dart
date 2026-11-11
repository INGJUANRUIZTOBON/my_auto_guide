import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // VULN-01
import '../logic/app_widget_logic.dart';
import '../../features/navigation/logic/telemetry_calculator.dart';

class BackgroundNavService {
  static const String channelId = 'my_auto_guide_nav';
  static const String notificationTitle = 'Recorrido en Progreso';

  static const String prefRoutePointsKey = 'nav_route_points';
  static const String prefTotalDistanceKey = 'nav_total_distance';
  static const String prefMaxSpeedKey = 'nav_max_speed_kmh';
  static const String prefStartTimeKey = 'nav_start_time_ms';

  /// Limpia la ruta persistida antes de iniciar un nuevo viaje.
  static Future<void> resetRouteStorage({LatLng? initialPoint}) async {
    final prefs = await SharedPreferences.getInstance();
    final initialList = initialPoint != null ? [initialPoint] : <LatLng>[];
    await prefs.setString(
      prefRoutePointsKey,
      TelemetryCalculator.encodeRoutePoints(initialList),
    );
    await prefs.setDouble(prefTotalDistanceKey, 0.0);
    await prefs.setDouble(prefMaxSpeedKey, 0.0);
    await prefs.setInt(prefStartTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Pequeño delay para asegurar que otros servicios (notificaciones) estén listos
    await Future.delayed(const Duration(milliseconds: 500));

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channelId,
        initialNotificationTitle: notificationTitle,
        initialNotificationContent: 'Preparando seguimiento GPS...',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    StreamSubscription<Position>? gpsSubscription;

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) async {
      await gpsSubscription?.cancel();
      gpsSubscription = null;
      AppWidgetLogic.updateWidget(distance: 0, isTracking: false);
      service.stopSelf();
    });

    double totalDistanceMeters = 0.0;
    double maxSpeedKmH = 0.0;
    LatLng? lastPos;
    List<LatLng> routePoints = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      // Recuperar ruta parcial si el servicio se reinició durante el viaje
      final existingPoints = TelemetryCalculator.decodeRoutePoints(
        prefs.getString(prefRoutePointsKey),
      );
      if (existingPoints.isNotEmpty) {
        routePoints = existingPoints;
        lastPos = existingPoints.last;
        totalDistanceMeters = (prefs.getDouble(prefTotalDistanceKey) ?? 0.0) * 1000.0;
        maxSpeedKmH = prefs.getDouble(prefMaxSpeedKey) ?? 0.0;
      }

      // =========================================================
      // 1. CONFIGURACIÓN GPS CONTINUA CON WAKELOCK EN SUSPENSIÓN
      // =========================================================
      late LocationSettings locationSettings;

      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 4,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 2),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: notificationTitle,
            notificationText: 'Grabando tu ruta GPS con pantalla suspendida',
            notificationChannelName: 'Seguimiento GPS en Ruta',
            enableWakeLock: true,
            enableWifiLock: true,
            setOngoing: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 4,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 4,
        );
      }

      // =========================================================
      // 2. INICIALIZAR SUPABASE DESDE ALMACENAMIENTO CIFRADO (VULN-01)
      // =========================================================
      RealtimeChannel? supabaseChannel;
      unawaited(() async {
        try {
          const secureStorage = FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
              synchronizable: false,
            ),
          );
          final url = await secureStorage.read(key: 'secure_supabase_url') ?? '';
          final key = await secureStorage.read(key: 'secure_supabase_anon_key') ?? '';
          final vehicleId = prefs.getString('active_nav_vehicle_id') ?? 'unknown';

          if (url.isNotEmpty && key.isNotEmpty) {
            await Supabase.initialize(url: url, anonKey: key);
            final client = Supabase.instance.client;
            supabaseChannel = client.channel('tracking:$vehicleId');
            supabaseChannel?.subscribe();
          }
        } catch (e) {
          debugPrint('Error inicializando Supabase en Background (GPS continuará): $e');
        }
      }());

      // =========================================================
      // 3. GESTIÓN DEL STREAM GPS CONTINUO (FILTRO + PERSISTENCIA)
      // =========================================================
      gpsSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) async {
        final currentPos = LatLng(position.latitude, position.longitude);

        // Filtrar rebotes de antena con mala precisión o saltos imposibles
        if (!TelemetryCalculator.isValidGpsSample(
          accuracyMeters: position.accuracy,
          previousPoint: lastPos,
          nextPoint: currentPos,
        )) {
          return;
        }

        if (lastPos != null) {
          final distKm =
              TelemetryCalculator.calculateIncrementalDistance(lastPos!, currentPos);
          totalDistanceMeters += distKm * 1000.0;
        }

        final previousLength = routePoints.length;
        routePoints = TelemetryCalculator.optimizeRoutePoints(routePoints, currentPos);
        lastPos = currentPos;

        final speedKmH = position.speed >= 0 ? position.speed * 3.6 : 0.0;
        if (speedKmH > maxSpeedKmH && speedKmH <= 320.0) {
          maxSpeedKmH = speedKmH;
        }

        final totalDistanceKm = totalDistanceMeters / 1000.0;

        // PRIORIDAD 1: Persistir inmediatamente toda la polilínea para sobrevivir suspensión
        if (routePoints.length != previousLength || previousLength <= 1) {
          await prefs.setString(
            prefRoutePointsKey,
            TelemetryCalculator.encodeRoutePoints(routePoints),
          );
        }
        await prefs.setDouble(prefTotalDistanceKey, totalDistanceKm);
        await prefs.setDouble(prefMaxSpeedKey, maxSpeedKmH);
        await prefs.setDouble('nav_last_lat', position.latitude);
        await prefs.setDouble('nav_last_lng', position.longitude);

        // PRIORIDAD 2: Notificar a la UI si está activa
        service.invoke('update', {
          'lat': position.latitude,
          'lng': position.longitude,
          'distance': totalDistanceKm,
          'speed': position.speed,
          'maxSpeedKmH': maxSpeedKmH,
          'pointsCount': routePoints.length,
        });

        // PRIORIDAD 3: Actualizar notificación persistente
        if (service is AndroidServiceInstance && await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: notificationTitle,
            content:
                'Recorrido: ${totalDistanceKm.toStringAsFixed(2)} km • ${speedKmH.toStringAsFixed(0)} km/h',
          );
        }

        // PRIORIDAD 4: Home Widget y Realtime
        try {
          AppWidgetLogic.updateWidget(
            distance: totalDistanceKm,
            isTracking: true,
          );
          supabaseChannel?.track({
            'lat': position.latitude,
            'lng': position.longitude,
            'dist': totalDistanceKm,
            'ts': DateTime.now().millisecondsSinceEpoch,
            'speed': position.speed,
          });
        } catch (e) {
          debugPrint('Fallo secundario en background: $e');
        }
      }, onError: (e) {
        debugPrint('Error en stream GPS: $e');
        service.invoke('error', {
          'message': 'Error GPS: $e. Verifica permisos y señal.',
        });
      });
    } catch (e) {
      debugPrint('Error fatal iniciando background GPS: $e');
      service.invoke('error', {'message': 'Crash total en background: $e'});
    }
  }
}
