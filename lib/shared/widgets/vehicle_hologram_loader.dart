import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de carga cinemático automotriz para MY AUTO GUIDE.
/// Implementa:
/// 1. Escaneo Láser Holográfico a 60-120 FPS sobre siluetas aerodinámicas nativas (Carro o Moto).
/// 2. Líneas de flujo simulando túnel de viento aerodinámico.
/// 3. Renderizado adaptativo: Escaneo completo en fotos medianas/grandes y Micro-Shimmer en miniaturas (<=80px).
/// 4. Acento de color dinámico por marca o cian obsidiana neón (#00E5FF).
/// 5. Manejo de timeout a los 5s (offline / modo túnel) con congelación de render y botón de reintento.
/// 6. Aceleración GPU con RepaintBoundary y cero rebuilds de widgets innecesarios.
class VehicleHologramLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final bool isCar;
  final Color? accentColor;
  final bool enableHaptic;
  final VoidCallback? onRetry;
  final Duration timeoutDuration;

  const VehicleHologramLoader({
    super.key,
    this.width,
    this.height,
    this.isCar = false,
    this.accentColor,
    this.enableHaptic = false,
    this.onRetry,
    this.timeoutDuration = const Duration(seconds: 5),
  });

  @override
  State<VehicleHologramLoader> createState() => _VehicleHologramLoaderState();
}

class _VehicleHologramLoaderState extends State<VehicleHologramLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  Timer? _timeoutTimer;
  bool _isTimedOut = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _armTimeoutTimer();
  }

  void _armTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(widget.timeoutDuration, () {
      if (mounted) {
        setState(() {
          _isTimedOut = true;
        });
        // Detener la animación para ahorrar batería en condiciones de red muerta
        _scanController.stop();
      }
    });
  }

  void _handleRetry() {
    setState(() {
      _isTimedOut = false;
    });
    _scanController.repeat();
    _armTimeoutTimer();
    widget.onRetry?.call();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = widget.width ?? 280.0;
    final effectiveHeight = widget.height ?? 160.0;
    final isCompact = effectiveWidth <= 80 || effectiveHeight <= 80;
    final themeColor = widget.accentColor ?? const Color(0xFF00E5FF);

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: Center(
        child: _isTimedOut
            ? _buildTimeoutFallback(effectiveWidth, effectiveHeight, themeColor)
            : RepaintBoundary(
                child: isCompact
                    ? _buildMicroShimmer(effectiveWidth, effectiveHeight, themeColor)
                    : _buildHologramScan(effectiveWidth, effectiveHeight, themeColor),
              ),
      ),
    );
  }

  Widget _buildMicroShimmer(double w, double h, Color accent) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(w, h),
          painter: _MicroShimmerPainter(
            progress: _scanController.value,
            accentColor: accent,
          ),
        );
      },
    );
  }

  Widget _buildHologramScan(double w, double h, Color accent) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(w, h),
          painter: _VehicleLaserScanPainter(
            progress: _scanController.value,
            accentColor: accent,
            isCar: widget.isCar,
          ),
        );
      },
    );
  }

  Widget _buildTimeoutFallback(double w, double h, Color accent) {
    final isCompact = w <= 80 || h <= 80;
    return GestureDetector(
      onTap: _handleRetry,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
            size: isCompact ? 22 : 36,
            color: accent.withValues(alpha: 0.35),
          ),
          if (!isCompact) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 13, color: accent),
                  const SizedBox(width: 4),
                  Text(
                    'Reintentar conexión',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Painter de Escaneo Láser Holográfico a 60-120 FPS
class _VehicleLaserScanPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final bool isCar;

  _VehicleLaserScanPainter({
    required this.progress,
    required this.accentColor,
    required this.isCar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final silhouette = isCar ? _getCarSilhouette(size) : _getMotoSilhouette(size);

    // 1. Fondo suave de la silueta en vidrio oscuro
    final baseFillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    canvas.drawPath(silhouette, baseFillPaint);

    // 2. Trazo base de la silueta con baja intensidad
    final baseStrokePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(silhouette, baseStrokePaint);

    // 3. Líneas de Túnel de Viento Aerodinámico
    _drawWindTunnelLines(canvas, size);

    // 4. Haz Láser Vertical de Escaneo con Recorte dentro de la silueta
    canvas.save();
    canvas.clipPath(silhouette);

    final laserX = w * progress;
    final laserWidth = w * 0.28;

    final laserGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        accentColor.withValues(alpha: 0.10),
        accentColor.withValues(alpha: 0.55),
        Colors.white.withValues(alpha: 0.85),
        accentColor.withValues(alpha: 0.55),
        accentColor.withValues(alpha: 0.10),
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.45, 0.50, 0.55, 0.75, 1.0],
    );

    final laserRect = Rect.fromLTWH(laserX - (laserWidth / 2), 0, laserWidth, h);
    final laserPaint = Paint()
      ..shader = laserGradient.createShader(laserRect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(laserRect, laserPaint);

    // Línea central hiperbrillante del haz láser
    final centerLaserLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(laserX, 0), Offset(laserX, h), centerLaserLine);

    canvas.restore();

    // 5. Destello / Pulso sutil de faros frontales
    final headlightPos = isCar ? Offset(w * 0.07, h * 0.58) : Offset(w * 0.25, h * 0.36);
    final headlightPulse = (math.sin(progress * 2 * math.pi) + 1.0) / 2.0;

    final headlightGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.60 * headlightPulse),
          accentColor.withValues(alpha: 0.35 * headlightPulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: headlightPos, radius: 18.0));

    canvas.drawCircle(headlightPos, 18.0, headlightGlow);
  }

  void _drawWindTunnelLines(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 3 líneas aerodinámicas a distintas alturas relativas
    final heights = [h * 0.34, h * 0.50, h * 0.66];
    final speeds = [1.1, 1.35, 0.95];

    for (int i = 0; i < heights.length; i++) {
      final lineY = heights[i];
      final lineProgress = (progress * speeds[i]) % 1.0;
      final lineStartX = (w * lineProgress) - (w * 0.35);
      final lineLength = w * 0.32;

      final windGradient = LinearGradient(
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: 0.25),
          accentColor.withValues(alpha: 0.75),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.8, 1.0],
      );

      final rect = Rect.fromLTWH(lineStartX, lineY, lineLength, 2);
      final linePaint = Paint()
        ..shader = windGradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(lineStartX, lineY),
        Offset(lineStartX + lineLength, lineY),
        linePaint,
      );
    }
  }

  Path _getCarSilhouette(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();

    p.moveTo(w * 0.05, h * 0.72);
    p.lineTo(w * 0.07, h * 0.60);
    p.quadraticBezierTo(w * 0.12, h * 0.48, w * 0.22, h * 0.46);
    p.lineTo(w * 0.36, h * 0.44);
    p.quadraticBezierTo(w * 0.44, h * 0.30, w * 0.52, h * 0.28);
    p.lineTo(w * 0.68, h * 0.28);
    p.quadraticBezierTo(w * 0.78, h * 0.32, w * 0.88, h * 0.46);
    p.lineTo(w * 0.94, h * 0.48);
    p.lineTo(w * 0.93, h * 0.65);
    p.lineTo(w * 0.90, h * 0.72);

    // Hueco rueda trasera
    p.quadraticBezierTo(w * 0.86, h * 0.56, w * 0.74, h * 0.56);
    p.quadraticBezierTo(w * 0.62, h * 0.56, w * 0.60, h * 0.72);

    // Faldón lateral
    p.lineTo(w * 0.38, h * 0.72);

    // Hueco rueda delantera
    p.quadraticBezierTo(w * 0.34, h * 0.56, w * 0.22, h * 0.56);
    p.quadraticBezierTo(w * 0.12, h * 0.56, w * 0.10, h * 0.72);

    p.close();
    return p;
  }

  Path _getMotoSilhouette(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();

    p.moveTo(w * 0.24, h * 0.38);
    p.quadraticBezierTo(w * 0.27, h * 0.28, w * 0.33, h * 0.28);
    p.lineTo(w * 0.38, h * 0.32);
    p.quadraticBezierTo(w * 0.44, h * 0.24, w * 0.53, h * 0.33);
    p.quadraticBezierTo(w * 0.60, h * 0.48, w * 0.68, h * 0.44);
    p.lineTo(w * 0.81, h * 0.36);
    p.lineTo(w * 0.84, h * 0.41);
    p.lineTo(w * 0.77, h * 0.53);
    p.lineTo(w * 0.73, h * 0.65);

    // Rueda trasera
    p.quadraticBezierTo(w * 0.87, h * 0.55, w * 0.87, h * 0.74);
    p.quadraticBezierTo(w * 0.87, h * 0.84, w * 0.72, h * 0.84);
    p.quadraticBezierTo(w * 0.60, h * 0.84, w * 0.60, h * 0.70);

    // Quilla y bloque motor
    p.lineTo(w * 0.45, h * 0.76);
    p.lineTo(w * 0.36, h * 0.68);

    // Rueda delantera
    p.quadraticBezierTo(w * 0.36, h * 0.84, w * 0.24, h * 0.84);
    p.quadraticBezierTo(w * 0.12, h * 0.84, w * 0.12, h * 0.70);
    p.quadraticBezierTo(w * 0.12, h * 0.54, w * 0.22, h * 0.54);

    p.lineTo(w * 0.24, h * 0.38);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _VehicleLaserScanPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isCar != isCar;
  }
}

/// Painter de Micro-Shimmer ultra-ligero para logos y miniaturas (<=80px)
class _MicroShimmerPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _MicroShimmerPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.shortestSide * 0.18),
    );

    // Fondo tenue
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Shimmer oblicuo
    canvas.save();
    canvas.clipRRect(rrect);

    final sweepX = size.width * (progress * 2.0 - 0.5);
    final sweepWidth = size.width * 0.6;

    final shimmerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        accentColor.withValues(alpha: 0.15),
        Colors.white.withValues(alpha: 0.35),
        accentColor.withValues(alpha: 0.15),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
    );

    final sweepRect = Rect.fromLTWH(sweepX - (sweepWidth / 2), 0, sweepWidth, size.height);
    final shimmerPaint = Paint()
      ..shader = shimmerGradient.createShader(sweepRect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(sweepRect, shimmerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MicroShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
  }
}
