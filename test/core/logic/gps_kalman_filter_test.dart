import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_auto_guide/core/logic/gps_kalman_filter.dart';

void main() {
  group('GpsKalmanFilter', () {
    test('smooths stationary GPS drift while preserving convergence', () {
      final filter = GpsKalmanFilter();
      final p0 = filter.process(
        lat: 6.244200,
        lng: -75.581200,
        accuracyMeters: 10.0,
        timestampMs: 1000,
      );
      expect(p0.latitude, closeTo(6.244200, 1e-6));

      // Spike noisy reading with poor 45m accuracy shouldn't jump raw coordinate fully
      final p1 = filter.process(
        lat: 6.244600,
        lng: -75.581600,
        accuracyMeters: 45.0,
        timestampMs: 2000,
        speedMs: 0.0,
      );
      expect(p1.latitude, lessThan(6.244350));
      expect(p1.latitude, greaterThan(6.244200));
    });

    test('resets cleanly between trips', () {
      final filter = GpsKalmanFilter();
      filter.process(
        lat: 6.244200,
        lng: -75.581200,
        accuracyMeters: 10.0,
        timestampMs: 1000,
      );
      expect(filter.isInitialized, isTrue);
      filter.reset();
      expect(filter.isInitialized, isFalse);
    });
  });

  group('GpsMotionMath', () {
    test('calculates cardinal bearings accurately', () {
      const origin = LatLng(6.2442, -75.5812);
      const north = LatLng(6.2542, -75.5812);
      const east = LatLng(6.2442, -75.5712);

      expect(GpsMotionMath.calculateBearingDegrees(origin, north), closeTo(0.0, 0.5));
      expect(GpsMotionMath.calculateBearingDegrees(origin, east), closeTo(90.0, 0.5));
    });

    test('interpolates angles through shortest wrap-around path (350 -> 10)', () {
      final mid = GpsMotionMath.lerpAngleDegrees(350.0, 10.0, 0.5);
      expect(mid, closeTo(0.0, 0.01));

      final midReverse = GpsMotionMath.lerpAngleDegrees(10.0, 350.0, 0.5);
      expect(midReverse, closeTo(0.0, 0.01));
    });

    test('snaps lateral GPS offset onto OSRM route segment within threshold', () {
      const route = [
        LatLng(6.24400, -75.58100),
        LatLng(6.24500, -75.58100),
      ];
      // ~10m east of the vertical route segment
      const noisyPos = LatLng(6.24450, -75.58091);

      final snapped = GpsMotionMath.snapToRoutePolyline(
        position: noisyPos,
        routePoints: route,
        maxSnapDistanceMeters: 18.0,
      );
      expect(snapped.snapped, isTrue);
      expect(snapped.position.longitude, closeTo(-75.58100, 0.00001));
      expect(snapped.segmentBearingDegrees, closeTo(0.0, 1.0));
    });

    test('does not snap when vehicle is genuinely off-route (> threshold)', () {
      const route = [
        LatLng(6.24400, -75.58100),
        LatLng(6.24500, -75.58100),
      ];
      // ~110m east -> detour
      const offRoute = LatLng(6.24450, -75.58000);

      final result = GpsMotionMath.snapToRoutePolyline(
        position: offRoute,
        routePoints: route,
        maxSnapDistanceMeters: 18.0,
      );
      expect(result.snapped, isFalse);
      expect(result.position, offRoute);
    });
  });
}
