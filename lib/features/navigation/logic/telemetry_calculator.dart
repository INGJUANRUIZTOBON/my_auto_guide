import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/logic/vehicle_performance_logic.dart';

/// Lógica pura para cálculos de telemetría GPS.
/// Desacoplada de Flutter UI para facilitar el testeo y la precisión.
class TelemetryCalculator {
  
  /// Calcula la distancia recorrida entre dos puntos con filtro de ruido.
  /// Retorna la distancia en kilómetros.
  static double calculateIncrementalDistance(LatLng oldPos, LatLng newPos) {
    final distMeters = Geolocator.distanceBetween(
      oldPos.latitude, 
      oldPos.longitude, 
      newPos.latitude, 
      newPos.longitude
    );

    // Filtro de ruido (jitter): Ignorar saltos menores a 3m (vehículo detenido)
    // o saltos mayores a 5000m en un solo tick (glitch extremo de GPS/red).
    if (distMeters < 3 || distMeters > 5000) return 0.0;
    
    return distMeters / 1000.0;
  }

  /// Calcula la velocidad promedio basada en muestras puntuales de velocidad acumuladas.
  static double calculateAverageSpeed(double accumulatedSpeed, int speedSamples) {
    if (speedSamples <= 0) return 0.0;
    return accumulatedSpeed / speedSamples;
  }

  /// Calcula la velocidad promedio cinemática basada en distancia total recorrida y tiempo transcurrido (en segundos).
  static double calculateKinematicAverageSpeed({
    required double distanceKm,
    required int durationSeconds,
    double fallbackSpeedKmH = 0.0,
  }) {
    if (durationSeconds > 5 && distanceKm > 0.01) {
      final hours = durationSeconds / 3600.0;
      final speed = distanceKm / hours;
      // Limitar a valores físicamente plausibles (0 a 350 km/h)
      return speed.clamp(0.0, 350.0);
    }
    return fallbackSpeedKmH;
  }

  /// Estima el consumo y costo basado en la telemetría actual.
  static Map<String, double> estimateImpact({
    required double distanceKm,
    required double avgSpeedKmH,
    required String vehicleModel,
    required bool isCar,
  }) {
    final gallons = VehiclePerformanceLogic.estimateFuelConsumption(
      distanceKm, 
      vehicleModel,
      isCar: isCar,
      avgSpeedKmH: avgSpeedKmH
    );
    final cost = VehiclePerformanceLogic.estimateFuelCost(gallons);
    
    return {
      'gallons': gallons,
      'cost': cost,
    };
  }

  /// Limita y filtra los puntos de la ruta para generar una línea suave (Polyline)
  /// e impedir zigzags o distorsiones por temblor de GPS cuando el vehículo se detiene.
  static List<LatLng> optimizeRoutePoints(List<LatLng> currentPoints, LatLng newPoint) {
    final updated = List<LatLng>.from(currentPoints);
    if (updated.isEmpty) {
      updated.add(newPoint);
      return updated;
    }

    final lastPoint = updated.last;
    final distMeters = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      newPoint.latitude,
      newPoint.longitude,
    );

    // Solo agregar el nuevo punto a la polilínea si el desplazamiento es >= 4.0 metros
    if (distMeters >= 4.0) {
      updated.add(newPoint);
      if (updated.length > 5000) {
        updated.removeAt(0);
      }
    }
    return updated;
  }

  /// Valida si una muestra GPS es apta para trazar ruta (descarta saltos por baja señal).
  static bool isValidGpsSample({
    required double accuracyMeters,
    LatLng? previousPoint,
    required LatLng nextPoint,
  }) {
    if (previousPoint != null && accuracyMeters > 65.0) {
      return false;
    }
    if (previousPoint != null) {
      final jumpMeters = Geolocator.distanceBetween(
        previousPoint.latitude,
        previousPoint.longitude,
        nextPoint.latitude,
        nextPoint.longitude,
      );
      if (jumpMeters > 300.0 && accuracyMeters > 20.0) {
        return false;
      }
    }
    return true;
  }

  /// Serializa una polilínea compacta `[ [lat, lng], ... ]` para persistencia rápida en segundo plano.
  static String encodeRoutePoints(List<LatLng> points) {
    final compact = points
        .map((p) => [
              double.parse(p.latitude.toStringAsFixed(6)),
              double.parse(p.longitude.toStringAsFixed(6)),
            ])
        .toList(growable: false);
    return jsonEncode(compact);
  }

  /// Decodifica puntos persistidos desde `SharedPreferences` en formato compacto o lista de mapas.
  static List<LatLng> decodeRoutePoints(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return [];
      final points = <LatLng>[];
      for (final item in decoded) {
        if (item is List && item.length >= 2) {
          final lat = (item[0] as num?)?.toDouble();
          final lng = (item[1] as num?)?.toDouble();
          if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
            points.add(LatLng(lat, lng));
          }
        } else if (item is Map) {
          final lat = (item['lat'] as num?)?.toDouble();
          final lng = (item['lng'] as num?)?.toDouble();
          if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
            points.add(LatLng(lat, lng));
          }
        }
      }
      return points;
    } catch (_) {
      return [];
    }
  }
}
