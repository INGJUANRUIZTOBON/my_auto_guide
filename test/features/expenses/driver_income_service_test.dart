import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/features/expenses/data/driver_income_service.dart';

void main() {
  group('DriverIncomeService calculations', () {
    test('Computes net profit and COP/km deducting tolls, shift costs, and external expenses', () {
      final entries = [
        DriverIncomeEntry(
          id: '1',
          vehiculoId: 'v1',
          plataforma: 'Uber / Comfort',
          montoBruto: 180000,
          peajes: 15000,
          otrosGastos: 5000,
          kmsTurno: 80,
          notas: '',
          fecha: DateTime(2026, 5, 11),
        ),
        DriverIncomeEntry(
          id: '2',
          vehiculoId: 'v1',
          plataforma: 'DiDi / Express',
          montoBruto: 120000,
          peajes: 0,
          otrosGastos: 10000,
          kmsTurno: 70,
          notas: '',
          fecha: DateTime(2026, 5, 12),
        ),
      ];

      final summary = DriverIncomeService.computeSummary(
        entries,
        externalExpenses: 50000, // Gasolina / mantenimiento del periodo
      );

      expect(summary.totalBruto, 300000);
      expect(summary.totalGastosTurno, 30000);
      expect(summary.totalGastosVehiculoPeriodo, 50000);
      expect(summary.totalNeto, 220000);
      expect(summary.totalKms, 150);
      expect(summary.promedioCopPorKm, closeTo(220000 / 150, 0.01));
      expect(summary.totalTurnos, 2);
    });
  });
}
