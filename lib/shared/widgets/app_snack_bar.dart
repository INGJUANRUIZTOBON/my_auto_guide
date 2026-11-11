// =============================================================================
// app_snack_bar.dart — MENSAJES EMERGENTES (SnackBar) CENTRALIZADOS
// =============================================================================
//
// Utilidad compartida para mostrar SnackBars con el mismo formato y alto
// contraste tanto en modo claro como en modo oscuro en toda la app.
//
// =============================================================================

import 'package:flutter/material.dart';

class AppSnackBar {
  const AppSnackBar._();

  /// Muestra un SnackBar con [message] en el [context] indicado.
  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
    Color? backgroundColor,
    bool floating = true,
  }) {
    final bgColor = backgroundColor ?? const Color(0xFF1E293B);
    final isDarkBg =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark;
    final fgColor = isDarkBg ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDarkBg
        ? const Color(0xFF38BDF8).withValues(alpha: 0.32)
        : Colors.black.withValues(alpha: 0.12);

    final effectiveAction = action == null
        ? null
        : SnackBarAction(
            label: action.label,
            onPressed: action.onPressed,
            textColor: action.textColor ??
                (isDarkBg ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
            disabledTextColor: action.disabledTextColor,
            backgroundColor: action.backgroundColor,
            disabledBackgroundColor: action.disabledBackgroundColor,
          );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: fgColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
          action: effectiveAction,
          duration: duration ?? const Duration(seconds: 4),
          backgroundColor: bgColor,
          elevation: 6,
          behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
          margin: floating ? const EdgeInsets.fromLTRB(16, 0, 16, 16) : null,
          shape: floating
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor, width: 1.0),
                )
              : null,
        ),
      );
  }
}
