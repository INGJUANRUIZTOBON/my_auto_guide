import 'dart:io';
import 'package:flutter/material.dart';

/// Widget universal de imagen automotriz para MY AUTO GUIDE.
/// Soporta:
/// 1. URLs remotas (HTTP / HTTPS) de Supabase Storage / CDN con fade y fallback elegante.
/// 2. Archivos locales del dispositivo (cámara / galería / file://).
/// 3. Assets preempaquetados en la app (assets/...).
/// 4. Fallback con silueta o icono temático si la imagen no existe o falla la red.
class SmartVehicleImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final bool isCar;
  final Color? fallbackColor;
  final Widget? customFallback;

  const SmartVehicleImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.cacheWidth,
    this.isCar = false,
    this.fallbackColor,
    this.customFallback,
  });

  @override
  Widget build(BuildContext context) {
    final raw = (imagePath ?? '').trim();

    if (raw.isEmpty) {
      return _buildFallback();
    }

    // 1. Imagen de Red (Supabase Storage, CDN, URLs HTTP/HTTPS)
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final effectiveCacheWidth =
          cacheWidth ?? (width != null ? (width! * 2).toInt() : 800);
      return Image.network(
        raw,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: effectiveCacheWidth,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    // 2. Archivo local en almacenamiento del teléfono (Cámara / Galería)
    if (raw.startsWith('file://') ||
        raw.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(raw)) {
      final cleanPath = raw.startsWith('file://') ? raw.replaceFirst('file://', '') : raw;
      final file = File(cleanPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      }
    }

    // 3. Asset empaquetado en el bundle de Flutter
    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth ?? 800,
        errorBuilder: (context, error, stackTrace) =>
            _buildRemoteFallback(raw),
      );
    }

    // Si no coincide con ninguno, intenta asset como última opción o fallback OTA
    final fallbackAsset = 'assets/$raw';
    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          _buildRemoteFallback(fallbackAsset),
    );
  }

  /// Fallback Over-The-Air (OTA) resiliente:
  /// Si el asset local no existe en el APK instalado (ej. versión previa o actualización en caliente),
  /// lo descargamos directamente del CDN de Supabase Storage.
  Widget _buildRemoteFallback(String assetPath) {
    final cleanPath = assetPath.startsWith('/') ? assetPath.substring(1) : assetPath;
    final remoteUrl =
        'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/$cleanPath';
    return Image.network(
      remoteUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth ?? 800,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _buildLoadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              fallbackColor ?? const Color(0xFF00E5FF).withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    if (customFallback != null) return customFallback!;

    final color = fallbackColor ?? const Color(0xFF00E5FF).withOpacity(0.3);
    final icon = isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded;

    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Icon(icon, size: (width != null && width! < 60) ? 24 : 48, color: color),
      ),
    );
  }
}
