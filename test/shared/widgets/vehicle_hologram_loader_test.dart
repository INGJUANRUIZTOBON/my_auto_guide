import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/shared/widgets/vehicle_hologram_loader.dart';

void main() {
  group('VehicleHologramLoader Widget', () {
    testWidgets('renders car hologram scan for large dimensions with CustomPaint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VehicleHologramLoader(
              width: 300,
              height: 180,
              isCar: true,
              accentColor: Color(0xFF00E5FF),
            ),
          ),
        ),
      );

      // Debe encontrar el RepaintBoundary para aceleración GPU y el CustomPaint
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(RepaintBoundary), findsWidgets);

      // Avanzamos 500ms de animación sin timeout
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders moto hologram scan for large dimensions when isCar is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VehicleHologramLoader(
              width: 250,
              height: 150,
              isCar: false,
              accentColor: Colors.amber,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders micro-shimmer mode when width/height <= 80px', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VehicleHologramLoader(
              width: 48,
              height: 48,
              isCar: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('displays timeout fallback with retry button after timeoutDuration', (tester) async {
      bool retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VehicleHologramLoader(
              width: 280,
              height: 160,
              isCar: true,
              timeoutDuration: const Duration(milliseconds: 500),
              onRetry: () {
                retryClicked = true;
              },
            ),
          ),
        ),
      );

      // Antes del timeout: renderiza escáner
      expect(find.text('Reintentar conexión'), findsNothing);

      // Esperamos a que expire el timeout
      await tester.pump(const Duration(milliseconds: 600));

      // Después del timeout: muestra botón de reintento
      expect(find.text('Reintentar conexión'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);

      // Tocamos el reintento
      await tester.tap(find.text('Reintentar conexión'));
      await tester.pump();

      expect(retryClicked, isTrue);
    });
  });
}
