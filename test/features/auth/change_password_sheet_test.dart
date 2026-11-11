import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/features/auth/widgets/change_password_sheet.dart';

void main() {
  testWidgets('ChangePasswordSheet validates length and password confirmation',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChangePasswordSheet(isRecovery: false),
        ),
      ),
    );

    // 1. Short password
    await tester.enterText(find.byType(TextField).at(0), '123');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pump();
    expect(find.text('La contraseña debe tener al menos 6 caracteres.'), findsOneWidget);

    // 2. Mismatched passwords
    await tester.enterText(find.byType(TextField).at(0), '123456');
    await tester.enterText(find.byType(TextField).at(1), '654321');
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });
}
