import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_apple_theme.dart';
import '../providers/scanner_provider.dart';

/// Gráfica ligera en tiempo real para RPM / Velocidad del escáner OBD2.
class ObdLiveSparklineCard extends StatelessWidget {
  final List<double> rpmValues;
  final List<double> speedValues;

  const ObdLiveSparklineCard({
    super.key,
    required this.rpmValues,
    required this.speedValues,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded,
                  color: AppAppleTheme.electricCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'Gráfica en Vivo (RPM & Velocidad)',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${rpmValues.length} muestras',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            width: double.infinity,
            child: rpmValues.length < 2
                ? Center(
                    child: Text(
                      'Recopilando señal de sensores en vivo...',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                    ),
                  )
                : CustomPaint(
                    painter: _SparklinePainter(
                      rpmValues: rpmValues,
                      speedValues: speedValues,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> rpmValues;
  final List<double> speedValues;

  _SparklinePainter({required this.rpmValues, required this.speedValues});

  @override
  void paint(Canvas canvas, Size size) {
    _drawLine(canvas, size, rpmValues, 7000, AppAppleTheme.electricCyan);
    if (speedValues.length >= 2) {
      _drawLine(canvas, size, speedValues, 180, const Color(0xFF00FF87));
    }
  }

  void _drawLine(
      Canvas canvas, Size size, List<double> values, double maxVal, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normY = (values[i] / maxVal).clamp(0.0, 1.0);
      final y = size.height - (normY * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}

/// Modo HUD nocturno (espejo horizontal para proyectar en el parabrisas del carro).
class ObdHudScreen extends StatefulWidget {
  final ScannerProvider provider;

  const ObdHudScreen({super.key, required this.provider});

  @override
  State<ObdHudScreen> createState() => _ObdHudScreenState();
}

class _ObdHudScreenState extends State<ObdHudScreen> {
  bool _mirrored = true;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Consumer<ScannerProvider>(
            builder: (context, p, _) {
              final speed = p.liveMetrics['Speed']?['value'] ?? '--';
              final rpm = p.liveMetrics['RPM']?['value'] ?? '--';
              final temp = p.liveMetrics['CoolantTemp']?['value'] ?? '--';
              final volt = p.batteryVoltage?.toStringAsFixed(1) ?? '--';

              final content = Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$speed',
                      style: GoogleFonts.outfit(
                        fontSize: 108,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00FF87),
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'KM/H',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HudStat(label: 'RPM', value: '$rpm'),
                        _HudStat(label: 'TEMP', value: '$temp °C'),
                        _HudStat(label: 'BATERÍA', value: '$volt V'),
                      ],
                    ),
                  ],
                ),
              );

              return Stack(
                children: [
                  _mirrored
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                          child: content,
                        )
                      : content,
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _mirrored = !_mirrored),
                          icon: const Icon(Icons.flip_rounded, color: Color(0xFF38BDF8)),
                          label: Text(
                            _mirrored ? 'Espejo Parabrisas ON' : 'Vista Normal',
                            style: const TextStyle(color: Color(0xFF38BDF8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HudStat extends StatelessWidget {
  final String label;
  final String value;

  const _HudStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            letterSpacing: 1.5,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}
