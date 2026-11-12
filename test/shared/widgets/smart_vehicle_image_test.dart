import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/shared/widgets/smart_vehicle_image.dart';

void main() {
  group('SmartVehicleImage Widget', () {
    testWidgets('renders fallback icon when path is empty or null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartVehicleImage(
              imagePath: null,
              isCar: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);
    });

    testWidgets('renders car fallback icon when isCar is true and path is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartVehicleImage(
              imagePath: '',
              isCar: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);
    });

    testWidgets('renders custom fallback widget if provided and path is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartVehicleImage(
              imagePath: '',
              customFallback: Text('Sin imagen'),
            ),
          ),
        ),
      );

      expect(find.text('Sin imagen'), findsOneWidget);
    });
  });
}
