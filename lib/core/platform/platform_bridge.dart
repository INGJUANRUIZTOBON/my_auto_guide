import 'package:flutter/foundation.dart';

/// Plataforma y capacidades unificadas para MY AUTO GUIDE.
/// Evita depender de 'dart:io' directamente en código compartido,
/// permitiendo soporte 100% nativo tanto en Web (CanvasKit) como en Android / iOS / Desktop.
class PlatformBridge {
  static const bool isWeb = kIsWeb;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isMobile => isAndroid || isIOS;

  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Capacidad de hardware: Escáner OCR de cámara
  static bool get supportsCameraOCR => !kIsWeb;

  /// Capacidad de hardware: Diagnóstico OBD-II Bluetooth
  static bool get supportsBluetoothOBD => isAndroid;

  /// Capacidad de hardware: Widgets de pantalla de inicio (Android)
  static bool get supportsHomeWidget => isAndroid;

  /// Capacidad de hardware: Servicio en segundo plano para GPS persistente
  static bool get supportsBackgroundLocationService => !kIsWeb;

  /// Capacidad de base de datos local SQLite (sqflite)
  static bool get supportsLocalSqlite => !kIsWeb;
}
