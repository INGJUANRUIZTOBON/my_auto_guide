import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_auto_guide/core/theme/app_apple_theme.dart';
import 'package:my_auto_guide/shared/widgets/app_snack_bar.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('AppSnackBar renders white text on dark background in dark mode',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppAppleTheme.lightTheme,
        darkTheme: AppAppleTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AppSnackBar.show(
                    context,
                    'Registro enviado. Revisa tu correo.',
                    action: SnackBarAction(
                      label: 'Reenviar',
                      onPressed: () {},
                    ),
                  );
                },
                child: const Text('Mostrar'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pump();

    final textWidget =
        tester.widget<Text>(find.text('Registro enviado. Revisa tu correo.'));
    expect(textWidget.style?.color, Colors.white);

    final actionWidget = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    expect(actionWidget.textColor, const Color(0xFF38BDF8));
  });

  testWidgets('Dark theme configures high-contrast SnackBarThemeData globally',
      (tester) async {
    final snackTheme = AppAppleTheme.darkTheme.snackBarTheme;
    expect(snackTheme.backgroundColor, AppAppleTheme.midnightSurfaceElevated);
    expect(snackTheme.contentTextStyle?.color, Colors.white);
    expect(snackTheme.actionTextColor, AppAppleTheme.electricCyan);
  });
}
