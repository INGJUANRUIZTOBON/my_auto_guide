import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_auto_guide/core/services/colombia_tolls_service.dart';

void main() {
  group('ColombiaTollsService', () {
    test('Detects tolls along Bogotá - Medellín points for car and exempts moto', () {
      final route = [
        const LatLng(4.7495, -74.1618), // Peaje Siberia
        const LatLng(5.0615, -74.4776), // Peaje Caiquero
        const LatLng(6.2442, -75.5812),
      ];

      final carEstimate = ColombiaTollsService.estimateRouteTolls(route, isCar: true);
      expect(carEstimate.count, greaterThanOrEqualTo(2));
      expect(carEstimate.totalCostCop, greaterThan(0));

      final motoEstimate = ColombiaTollsService.estimateRouteTolls(route, isCar: false);
      expect(motoEstimate.count, equals(carEstimate.count));
      expect(motoEstimate.totalCostCop, equals(0));
    });

    test('Returns empty estimate for fewer than 2 points', () {
      final empty = ColombiaTollsService.estimateRouteTolls(const [], isCar: true);
      expect(empty.count, 0);
      expect(empty.totalCostCop, 0);
    });
  });
}
