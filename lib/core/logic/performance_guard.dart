import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

/// Clase encargada de detectar el nivel de hardware del dispositivo
/// y decidir si se deben activar efectos visuales pesados (Glassmorphism, Blurs).
class PerformanceGuard {
  static final PerformanceGuard _instance = PerformanceGuard._internal();
  factory PerformanceGuard() => _instance;
  PerformanceGuard._internal();

  bool _isLowEnd = false;
  
  /// Indica si el dispositivo es de gama de entrada (entrada/baja)
  bool get isLowEnd => _isLowEnd;

  /// Inicializa la detección de hardware. Debe llamarse en el main().
  Future<void> initialize() async {
    if (kIsWeb) {
      _isLowEnd = false;
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        
        final model = androidInfo.model.toUpperCase();
        final brand = androidInfo.brand.toUpperCase();
        final hardware = androidInfo.hardware.toLowerCase();
        final product = androidInfo.product.toLowerCase();
        
        debugPrint('PerformanceGuard: Detectando Hardware - Brand: $brand, Model: $model, Hardware: $hardware, Product: $product');

        // 1. Detección específica por modelo (Samsung Galaxy A/M series, Xiaomi Redmi A/C, Moto E/G, Realme C)
        if (brand.contains('SAMSUNG') && 
           (model.contains('A05') || model.contains('A04') || model.contains('A03') || 
            model.contains('A02') || model.contains('A01') || model.contains('A10') || 
            model.contains('A11') || model.contains('A12') || model.contains('A13') || model.contains('A14') ||
            model.contains('M12') || model.contains('M13') || model.contains('A21') ||
            product.contains('a05') || product.contains('a04') || product.contains('a14'))) {
          _isLowEnd = true;
          debugPrint('PerformanceGuard: MODO BAJO CONSUMO ACTIVADO (Samsung A/M Series)');
          return;
        }

        // Xiaomi Redmi Gama Entrada (Redmi 9A/C, 10A/C, 12C, A1/A2/A3, Poco C series)
        if (brand.contains('XIAOMI') || brand.contains('REDMI') || brand.contains('POCO')) {
          if (model.contains('9A') || model.contains('9C') || model.contains('10A') ||
              model.contains('10C') || model.contains('12C') || model.contains('A1') ||
              model.contains('A2') || model.contains('A3') || model.contains('C40') ||
              model.contains('C50') || model.contains('C51') || model.contains('C55')) {
            _isLowEnd = true;
            debugPrint('PerformanceGuard: MODO BAJO CONSUMO ACTIVADO (Xiaomi Redmi/Poco Entry)');
            return;
          }
        }

        // Motorola Gama Entrada (Moto E series, Moto G13, G14, G22, G23, G Pure)
        if (brand.contains('MOTOROLA') || brand.contains('MOTO')) {
          if (model.contains(' E') || model.contains('E6') || model.contains('E7') ||
              model.contains('E13') || model.contains('E20') || model.contains('E22') ||
              model.contains('E32') || model.contains('G13') || model.contains('G14') ||
              model.contains('G22') || model.contains('G23') || model.contains('PURE')) {
            _isLowEnd = true;
            debugPrint('PerformanceGuard: MODO BAJO CONSUMO ACTIVADO (Motorola E/G Entry)');
            return;
          }
        }

        // 2. Detección por Hardware (Chipsets conocidos de < 2.0 GHz / <= 4GB RAM)
        // MediaTek Helio A22/P22/P35/G25/G35/G36/G37 (mt6761..mt6769)
        // Unisoc SC9863A, T606, T610, T612, T616
        // Exynos 7870, 7884, 850
        // Snapdragon 4xx / 662 / 665 / 680
        if (hardware.contains('mt676') || hardware.contains('mt673') || hardware.contains('mt675') ||
            hardware.contains('unisoc') || hardware.contains('sc98') || hardware.contains('t606') ||
            hardware.contains('t612') || hardware.contains('t616') || hardware.contains('ums') ||
            hardware.contains('exynos850') || hardware.contains('exynos7') ||
            hardware.contains('spreadtrum') || hardware.contains('sdm4') || hardware.contains('sm4') ||
            hardware.contains('qcom_4')) {
          _isLowEnd = true;
          debugPrint('PerformanceGuard: MODO BAJO CONSUMO ACTIVADO (Chipset Limitado: $hardware)');
          return;
        }
        
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final machine = iosInfo.utsname.machine.toLowerCase();
        // Dispositivos antiguos o con menos de 3GB RAM se consideran bajos para efectos pesados
        if (machine.contains('iphone7,') || machine.contains('iphone8,') || 
            machine.contains('iphone9,') || machine.contains('iphone10,1') || 
            machine.contains('iphone10,4') || machine.contains('ipad4,') || machine.contains('ipad5,')) {
          _isLowEnd = true;
        }
      }
    } catch (e) {
      debugPrint('PerformanceGuard: Error detectando nivel de hardware: $e');
      _isLowEnd = false; 
    }
  }

  /// Widget auxiliar que aplica desenfoque solo si el hardware lo soporta.
  /// Si es gama baja, muestra un fondo sólido con opacidad para ahorrar GPU.
  static Widget adaptiveBlur({
    required Widget child, 
    double sigma = 5, 
    Color? fallbackColor,
    BorderRadius? borderRadius,
  }) {
    final isLow = PerformanceGuard().isLowEnd;
    
    if (isLow) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          // Forzar color sólido sin transparencia compleja si es posible
          color: fallbackColor ?? const Color(0xFF121212), 
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}
