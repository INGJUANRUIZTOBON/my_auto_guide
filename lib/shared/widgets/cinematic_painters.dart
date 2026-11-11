import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fondo de showroom oscuro con foco cenital volumétrico, piso húmedo en perspectiva y partículas.
class ShowroomBackdropPainter extends CustomPainter {
  final double ignition;
  final double idlePhase;

  const ShowroomBackdropPainter({
    required this.ignition,
    required this.idlePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.43);

    // 1. Foco cenital volumétrico tipo showroom automotriz
    final spotlight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.25),
        radius: 0.85,
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.10 * ignition),
          const Color(0xFF10223D).withValues(alpha: 0.22 * ignition),
          const Color(0xFF06080C),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), spotlight);

    // 2. Piso húmedo reflectivo en perspectiva debajo del vehículo
    final floorY = size.height * 0.56;
    final horizonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.22 * ignition),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, floorY - 1, size.width, 2))
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, floorY), Offset(size.width, floorY), horizonPaint);

    // Líneas de fuga sutiles en el suelo
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.055 * ignition)
      ..strokeWidth = 1.0;

    for (int i = -4; i <= 4; i++) {
      final topX = center.dx + i * 26.0;
      final botX = center.dx + i * 95.0;
      canvas.drawLine(Offset(topX, floorY), Offset(botX, size.height), gridPaint);
    }

    for (int row = 1; row <= 5; row++) {
      final t = row / 5.0;
      final y = floorY + (size.height - floorY) * (t * t);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Partículas ambientales flotantes (profundidad óptica)
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 22; i++) {
      final seed = (i * 0.37) % 1.0;
      final xFrac = ((i * 0.6180339887) % 1.0);
      final yProgress = (seed + idlePhase * (0.25 + (i % 3) * 0.12)) % 1.0;
      final px = size.width * xFrac;
      final py = size.height * (0.85 - yProgress * 0.72);
      final radius = (i % 3 == 0) ? 1.8 : 1.1;
      final fade = math.sin(yProgress * math.pi).clamp(0.0, 1.0);
      particlePaint.color = (i % 4 == 0
              ? const Color(0xFFFF1744)
              : const Color(0xFF00E5FF))
          .withValues(alpha: 0.32 * fade * ignition);
      canvas.drawCircle(Offset(px, py), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ShowroomBackdropPainter oldDelegate) =>
      oldDelegate.ignition != ignition || oldDelegate.idlePhase != idlePhase;
}

/// Tacómetro digital estilo Cockpit BMW M / Porsche / Superbike TFT con shift-lights segmentados y aguja.
class CockpitTachometerPainter extends CustomPainter {
  final double rpmProgress; // 0.0 .. 1.0
  final double ignition;

  const CockpitTachometerPainter({
    required this.rpmProgress,
    required this.ignition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const double startAngle = math.pi * 0.78;
    const double sweepTotal = math.pi * 1.44;
    final clampedRpm = rpmProgress.clamp(0.0, 1.0);

    // 1. Bisel interior oscuro con profundidad
    final bezelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06 * ignition)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bezelPaint,
    );

    // 2. Shift-lights segmentados (28 LEDs discretos, sin artefactos de gradientes circulares)
    const int segments = 28;
    final double segSweep = (sweepTotal / segments) * 0.68;
    final int activeCount = (clampedRpm * segments).round();

    for (int i = 0; i < segments; i++) {
      final frac = i / (segments - 1);
      final angle = startAngle + (sweepTotal * (i / segments));
      final bool isLit = i < activeCount;

      final Color segColor;
      if (frac < 0.45) {
        segColor = const Color(0xFF00E5FF);
      } else if (frac < 0.72) {
        segColor = const Color(0xFF2979FF);
      } else if (frac < 0.86) {
        segColor = const Color(0xFFFF9100);
      } else {
        segColor = const Color(0xFFFF1744);
      }

      final segPaint = Paint()
        ..color = isLit
            ? segColor.withValues(alpha: 0.95 * ignition)
            : Colors.white.withValues(alpha: 0.09 * ignition)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLit ? 6.5 : 4.5
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        segSweep,
        false,
        segPaint,
      );
    }

    // 3. Ticks internos finos de precisión
    final tickPaint = Paint()..strokeWidth = 1.4;
    const int ticks = 16;
    for (int i = 0; i <= ticks; i++) {
      final frac = i / ticks;
      final angle = startAngle + sweepTotal * frac;
      final isMajor = i % 4 == 0;
      final rIn = radius - (isMajor ? 18 : 12);
      final rOut = radius - 7;
      tickPaint.color = Colors.white.withValues(
        alpha: (isMajor ? 0.55 : 0.22) * ignition,
      );
      canvas.drawLine(
        Offset(center.dx + rIn * math.cos(angle), center.dy + rIn * math.sin(angle)),
        Offset(center.dx + rOut * math.cos(angle), center.dy + rOut * math.sin(angle)),
        tickPaint,
      );
    }

    // 4. Aguja física con estela luminosa en el perímetro
    if (ignition > 0.1) {
      final needleAngle = startAngle + sweepTotal * clampedRpm;
      final tip = Offset(
        center.dx + (radius - 2) * math.cos(needleAngle),
        center.dy + (radius - 2) * math.sin(needleAngle),
      );
      final inner = Offset(
        center.dx + (radius - 26) * math.cos(needleAngle),
        center.dy + (radius - 26) * math.sin(needleAngle),
      );

      final glowColor = clampedRpm > 0.82
          ? const Color(0xFFFF1744)
          : const Color(0xFF00E5FF);

      final haloPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.45 * ignition)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawLine(inner, tip, haloPaint);

      final needlePaint = Paint()
        ..color = Colors.white.withValues(alpha: ignition)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(inner, tip, needlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CockpitTachometerPainter oldDelegate) =>
      oldDelegate.rpmProgress != rpmProgress || oldDelegate.ignition != ignition;
}

/// Destello óptico de encendido de faros LED + barrido volumétrico láser sobre el vehículo real.
class HeadlightAndScanPainter extends CustomPainter {
  final double flareIntensity;
  final double scanProgress;
  final bool isCar;

  const HeadlightAndScanPainter({
    required this.flareIntensity,
    required this.scanProgress,
    required this.isCar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (flareIntensity > 0.02) {
      final leftEye = isCar
          ? Offset(size.width * 0.14, size.height * 0.56)
          : Offset(size.width * 0.27, size.height * 0.44);
      final rightEye = isCar
          ? Offset(size.width * 0.36, size.height * 0.57)
          : Offset(size.width * 0.35, size.height * 0.45);

      _drawHeadlightFlare(canvas, leftEye, flareIntensity);
      _drawHeadlightFlare(canvas, rightEye, flareIntensity);
    }

    if (scanProgress > 0.0 && scanProgress < 1.0) {
      final x = size.width * scanProgress;
      final curtainRect = Rect.fromLTWH(x - 28, 0, 28, size.height);
      final curtainPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            const Color(0xFF00E5FF).withValues(alpha: 0.20),
          ],
        ).createShader(curtainRect);
      canvas.drawRect(curtainRect, curtainPaint);

      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF00E5FF).withValues(alpha: 0.95),
            const Color(0xFFFF1744).withValues(alpha: 0.85),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(x - 1, 0, 2, size.height))
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(x, size.height * 0.12),
        Offset(x, size.height * 0.88),
        beamPaint,
      );
    }
  }

  void _drawHeadlightFlare(Canvas canvas, Offset center, double intensity) {
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.85 * intensity),
          const Color(0xFF00E5FF).withValues(alpha: 0.55 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 36 * intensity));
    canvas.drawCircle(center, 36 * intensity, haloPaint);

    // Anamorphic horizontal light streak
    final streakWidth = 64.0 * intensity;
    final streakRect = Rect.fromCenter(
      center: center,
      width: streakWidth,
      height: 3.5,
    );
    final streakPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.9 * intensity),
          Colors.white.withValues(alpha: 0.95 * intensity),
          const Color(0xFF00E5FF).withValues(alpha: 0.9 * intensity),
          Colors.transparent,
        ],
      ).createShader(streakRect);
    canvas.drawRect(streakRect, streakPaint);
  }

  @override
  bool shouldRepaint(covariant HeadlightAndScanPainter oldDelegate) =>
      oldDelegate.flareIntensity != flareIntensity ||
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.isCar != isCar;
}
