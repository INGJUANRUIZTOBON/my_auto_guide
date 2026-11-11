import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/services/pico_y_placa_service.dart';

void main() {
  group('PicoYPlacaService Colombia rules', () {
    test('Bogotá applies parity to cars and exempts motorcycles', () {
      // 2026-05-11 is Monday, odd calendar day (11 -> 6,7,8,9,0 restricted)
      final dateOdd = DateTime(2026, 5, 11);
      final carRestricted = PicoYPlacaService.evaluateForDate(
        plate: 'ABC128',
        isCar: true,
        cityName: 'Bogotá',
        date: dateOdd,
      );
      expect(carRestricted.hasRestrictionSystem, isTrue);
      expect(carRestricted.appliesToVehicleType, isTrue);
      expect(carRestricted.isRestrictedToday, isTrue);

      final motoExempt = PicoYPlacaService.evaluateForDate(
        plate: 'XYZ89F',
        isCar: false,
        cityName: 'Bogotá',
        date: dateOdd,
      );
      expect(motoExempt.isRestrictedToday, isFalse);
      expect(motoExempt.appliesToVehicleType, isFalse);
    });

    test('Medellín checks first digit for motorcycles and last digit for cars', () {
      // 2026-05-11 is Monday -> restricted digits [5, 8]
      final monday = DateTime(2026, 5, 11);
      final motoRestricted = PicoYPlacaService.evaluateForDate(
        plate: 'KLM52G',
        isCar: false,
        cityName: 'Medellín',
        date: monday,
      );
      expect(motoRestricted.isRestrictedToday, isTrue);

      final carAllowed = PicoYPlacaService.evaluateForDate(
        plate: 'KLM523',
        isCar: true,
        cityName: 'Medellín',
        date: monday,
      );
      expect(carAllowed.isRestrictedToday, isFalse);
    });

    test('Holidays and unrestricted cities report no Pico y Placa', () {
      final holiday = DateTime(2026, 7, 20); // 20 de julio (lunes festivo)
      final onHoliday = PicoYPlacaService.evaluateForDate(
        plate: 'ABC120',
        isCar: true,
        cityName: 'Bogotá',
        date: holiday,
      );
      expect(onHoliday.isRestrictedToday, isFalse);

      final barranquilla = PicoYPlacaService.evaluateForDate(
        plate: 'ABC128',
        isCar: true,
        cityName: 'Barranquilla',
        date: DateTime(2026, 5, 11),
      );
      expect(barranquilla.hasRestrictionSystem, isFalse);
      expect(barranquilla.headline.toLowerCase(), contains('sin pico y placa'));

      final smallTown = PicoYPlacaService.evaluateForDate(
        plate: 'ABC128',
        isCar: true,
        cityName: 'Rionegro',
        date: DateTime(2026, 5, 11),
      );
      expect(smallTown.hasRestrictionSystem, isFalse);
      expect(smallTown.headline.toLowerCase(), contains('no aplica pico y placa'));
    });

    test('Coordinate bounding box matches Bogotá and Medellín offline', () {
      expect(PicoYPlacaService.matchCityByCoordinates(4.65, -74.08), 'Bogotá');
      expect(PicoYPlacaService.matchCityByCoordinates(6.24, -75.57), 'Medellín');
      expect(PicoYPlacaService.matchCityByCoordinates(5.15, -75.95), isNull);
    });
  });
}
