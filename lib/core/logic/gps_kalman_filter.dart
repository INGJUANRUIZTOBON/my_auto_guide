import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Resultado de proyección del punto GPS sobre la ruta OSRM activa (Road Snapping).
class RoadSnapResult {
  final LatLng position;
  final bool snapped;
  final double distanceToRouteMeters;
  final double? segmentBearingDegrees;

  const RoadSnapResult({
    required this.position,
    required this.snapped,
    required this.distanceToRouteMeters,
    this.segmentBearingDegrees,
  });
}

/// Filtro de Kalman 1D/2D ligero para suavizar coordenadas GPS en tiempo real (estilo Waze),
/// eliminando zigzag urbano cuando la señal satelital oscila sin introducir lag en curvas.
class GpsKalmanFilter {
  double? _lat;
  double? _lng;
  double _variance = -1.0;
  int _lastTimestampMs = 0;

  bool get isInitialized => _variance >= 0.0 && _lat != null && _lng != null;

  void reset() {
    _lat = null;
    _lng = null;
    _variance = -1.0;
    _lastTimestampMs = 0;
  }

  /// Procesa una muestra GPS cruda y retorna la coordenada suavizada.
  LatLng process({
    required double lat,
    required double lng,
    required double accuracyMeters,
    required int timestampMs,
    double speedMs = 0.0,
  }) {
    final effectiveAcc = accuracyMeters.clamp(3.0, 120.0);

    if (_variance < 0.0 || _lat == null || _lng == null) {
      _lat = lat;
      _lng = lng;
      _lastTimestampMs = timestampMs;
      _variance = effectiveAcc * effectiveAcc;
      return LatLng(lat, lng);
    }

    final dtMs = math.max(0, timestampMs - _lastTimestampMs);
    if (dtMs > 0) {
      // A mayor velocidad, mayor Q dinámico para seguir curvas reales sin retraso visual
      final qMetersPerSec = speedMs > 1.5 ? math.min(25.0, speedMs * 1.15) : 1.5;
      _variance += (dtMs / 1000.0) * qMetersPerSec * qMetersPerSec;
      _lastTimestampMs = timestampMs;
    }

    // Ganancia de Kalman: K in (0, 1]
    final measurementVariance = effectiveAcc * effectiveAcc;
    final k = _variance / (_variance + measurementVariance);

    _lat = _lat! + k * (lat - _lat!);
    _lng = _lng! + k * (lng - _lng!);
    _variance = (1.0 - k) * _variance;

    return LatLng(_lat!, _lng!);
  }
}

/// Utilidades cinemáticas estilo Waze para rumbo (bearing), interpolación 60fps,
/// zoom adaptativo por velocidad y Road Snapping sobre polilíneas.
class GpsMotionMath {
  static const double _earthRadiusMeters = 6371000.0;

  /// Calcula el azimut (bearing) en grados [0, 360) en sentido horario desde el Norte.
  static double calculateBearingDegrees(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLng = _degToRad(to.longitude - from.longitude);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final rad = math.atan2(y, x);
    return (_radToDeg(rad) + 360.0) % 360.0;
  }

  /// Interpola dos ángulos [0, 360) tomando siempre el giro más corto.
  static double lerpAngleDegrees(double fromDeg, double toDeg, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    double diff = ((toDeg - fromDeg + 540.0) % 360.0) - 180.0;
    return (fromDeg + diff * clampedT + 360.0) % 360.0;
  }

  /// Interpolación lineal de coordenadas para animación fluida a 60fps del marcador.
  static LatLng lerpLatLng(LatLng from, LatLng to, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * clampedT,
      from.longitude + (to.longitude - from.longitude) * clampedT,
    );
  }

  /// Proyecta la ubicación actual sobre el segmento más cercano de la ruta (Road Snapping)
  /// cuando está dentro de `maxSnapDistanceMeters` (~18m), eliminando desvíos laterales.
  static RoadSnapResult snapToRoutePolyline({
    required LatLng position,
    required List<LatLng> routePoints,
    double maxSnapDistanceMeters = 18.0,
  }) {
    if (routePoints.length < 2) {
      return RoadSnapResult(
        position: position,
        snapped: false,
        distanceToRouteMeters: double.infinity,
      );
    }

    final cosLat = math.cos(_degToRad(position.latitude)).clamp(0.1, 1.0);
    final metersPerDegLat = _earthRadiusMeters * math.pi / 180.0;
    final metersPerDegLng = metersPerDegLat * cosLat;

    double bestDistSq = double.infinity;
    LatLng bestPoint = position;
    int bestSegIndex = 0;

    final px = (position.longitude) * metersPerDegLng;
    final py = (position.latitude) * metersPerDegLat;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final a = routePoints[i];
      final b = routePoints[i + 1];

      final ax = a.longitude * metersPerDegLng;
      final ay = a.latitude * metersPerDegLat;
      final bx = b.longitude * metersPerDegLng;
      final by = b.latitude * metersPerDegLat;

      final abx = bx - ax;
      final aby = by - ay;
      final abLenSq = abx * abx + aby * aby;

      final double t = abLenSq <= 1e-6
          ? 0.0
          : (((px - ax) * abx + (py - ay) * aby) / abLenSq).clamp(0.0, 1.0);

      final projX = ax + t * abx;
      final projY = ay + t * aby;
      final dx = px - projX;
      final dy = py - projY;
      final distSq = dx * dx + dy * dy;

      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        bestSegIndex = i;
        bestPoint = LatLng(projY / metersPerDegLat, projX / metersPerDegLng);
      }
    }

    final bestDist = math.sqrt(bestDistSq);
    if (bestDist <= maxSnapDistanceMeters) {
      final segBearing = calculateBearingDegrees(
        routePoints[bestSegIndex],
        routePoints[bestSegIndex + 1],
      );
      return RoadSnapResult(
        position: bestPoint,
        snapped: true,
        distanceToRouteMeters: bestDist,
        segmentBearingDegrees: segBearing,
      );
    }

    return RoadSnapResult(
      position: position,
      snapped: false,
      distanceToRouteMeters: bestDist,
    );
  }

  /// Zoom automático estilo Waze según velocidad actual en km/h.
  static double recommendedZoomForSpeed(double speedKmH) {
    if (speedKmH >= 85.0) return 15.2;
    if (speedKmH >= 55.0) return 16.0;
    if (speedKmH >= 25.0) return 16.6;
    return 17.2;
  }

  static double _degToRad(double deg) => deg * math.pi / 180.0;
  static double _radToDeg(double rad) => rad * 180.0 / math.pi;
}
