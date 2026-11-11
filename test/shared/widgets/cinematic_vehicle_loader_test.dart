import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/shared/widgets/cinematic_vehicle_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CinematicVehicleLoader shows Colombia checklist and tap-to-skip when data is ready',
      (WidgetTester tester) async {
    bool skipped = false;
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CinematicVehicleLoader(
            isDataReady: true,
            onSkip: () => skipped = true,
            onIntroComplete: () => completed = true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('GPS & RUTA'), findsOneWidget);
    expect(find.text('PICO Y PLACA'), findsOneWidget);
    expect(find.text('RUNT & SOAT'), findsOneWidget);
    expect(find.text('MOTOR IA'), findsOneWidget);
    expect(find.text('DATOS LISTOS • TOCA PARA ENTRAR'), findsOneWidget);

    await tester.tap(find.byType(CinematicVehicleLoader));
    await tester.pump();

    expect(skipped, isTrue);
    expect(completed, isFalse);
  });

  testWidgets('CinematicVehicleLoader fires onIntroComplete after 2.4s ignition sequence',
      (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CinematicVehicleLoader(
            isDataReady: false,
            onIntroComplete: () => completed = true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    expect(completed, isFalse);

    await tester.pump(const Duration(milliseconds: 1300));
    expect(completed, isTrue);
  });
}
