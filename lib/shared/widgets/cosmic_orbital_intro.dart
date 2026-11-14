import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apertura Cósmica Orbital Inspirada en el video cinematográfico:
/// Horizonte planetario con amanecer ultravioleta -> Anillo orbital de plasma en rotación 360°
/// -> Destello anamórfico de lente (Lens Flare) -> Emergencia del escudo oficial MY AUTO GUIDE
/// -> Transición fluida hacia el tacómetro de telemetría.
class CosmicOrbitalIntro extends StatefulWidget {
  final VoidCallback onIntroComplete;
  final VoidCallback? onSkip;
  final Duration duration;

  const CosmicOrbitalIntro({
    super.key,
    required this.onIntroComplete,
    this.onSkip,
    this.duration = const Duration(milliseconds: 3200),
  });

  @override
  State<CosmicOrbitalIntro> createState() => _CosmicOrbitalIntroState();
}

class _CosmicOrbitalIntroState extends State<CosmicOrbitalIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hapticFired = false;
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addListener(() {
      final t = _controller.value;
      if (t >= 0.45 && !_hapticFired) {
        _hapticFired = true;
        if (!kIsWeb) {
          HapticFeedback.heavyImpact();
        }
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completedFired) {
        _completedFired = true;
        widget.onIntroComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skipIntro() {
    if (_completedFired) return;
    _completedFired = true;
    if (!kIsWeb) {
      HapticFeedback.selectionClick();
    }
    (widget.onSkip ?? widget.onIntroComplete)();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_completedFired) {
          _completedFired = true;
          widget.onIntroComplete();
        }
      });
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skipIntro,
      child: Scaffold(
        backgroundColor: const Color(0xFF06080C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Canvas Cósmico: Estrellas, Horizonte Planetario y Anillo Orbital
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: _CosmicScenePainter(progress: _controller.value),
                    size: Size.infinite,
                  ),
                );
              },
            ),

            // 2. Logo Oficial MY AUTO GUIDE con Shimmer y Revelación
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  // El logo empieza a revelarse desde t = 0.35 hasta 0.70
                  final double logoScale = t < 0.35
                      ? 0.70
                      : (0.70 + Curves.easeOutBack.transform(((t - 0.35) / 0.40).clamp(0.0, 1.0)) * 0.30);
                  final double logoOpacity = Curves.easeIn.transform(((t - 0.30) / 0.35).clamp(0.0, 1.0));
                  final double flareGlow = t < 0.45
                      ? 0.0
                      : (1.0 - ((t - 0.45) / 0.40).clamp(0.0, 1.0));

                  return Opacity(
                    opacity: logoOpacity,
                    child: Transform.scale(
                      scale: logoScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Contenedor del Logo con Aura Neón
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Resplandor de fondo
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35 + flareGlow * 0.45),
                                      blurRadius: 40 + flareGlow * 30,
                                      spreadRadius: 10 + flareGlow * 15,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
                                      blurRadius: 60,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              // Imagen del Escudo Oficial
                              Image.asset(
                                'assets/images/app_logo.png',
                                width: 130,
                                height: 130,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Tipografía Cinemática MY AUTO GUIDE
                          Text(
                            'MY AUTO GUIDE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0 + (1.0 - t) * 6.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtítulo con efecto de barrido
                          Opacity(
                            opacity: ((t - 0.50) / 0.35).clamp(0.0, 1.0),
                            child: const Text(
                              'ECOSISTEMA VEHICULAR INTELIGENTE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Botón Omitir Superior
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: InkWell(
                onTap: _skipIntro,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Omitir',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter que recrea el cosmos, el horizonte del planeta y el anillo orbital del video
class _CosmicScenePainter extends CustomPainter {
  final double progress;

  _CosmicScenePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 - 25);

    // 1. Resplandor del horizonte planetario inferior
    final horizonRect = Rect.fromCenter(
      center: Offset(w / 2, h + 40),
      width: w * 1.5,
      height: h * 0.45,
    );
    final horizonPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B5CF6).withValues(alpha: 0.35),
          const Color(0xFF00E5FF).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(horizonRect);

    canvas.drawOval(horizonRect, horizonPaint);

    // Destello de amanecer en la cresta del horizonte
    final sunGlowPaint = Paint()
      ..color = const Color(0xFFC084FC).withValues(alpha: 0.45 * (0.6 + 0.4 * math.sin(progress * math.pi)))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(w / 2, h - 8), 40, sunGlowPaint);

    // 2. Anillo Orbital Cinemático 3D (Efecto Saturno del video)
    final ringRadiusX = 145.0 + math.sin(progress * math.pi) * 8.0;
    final ringRadiusY = 62.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Inclinación del plano orbital a -22 grados
    canvas.rotate(-22 * math.pi / 180);

    // Dibuja la órbita de partículas y plasma
    final orbitRect = Rect.fromCenter(
      center: Offset.zero,
      width: ringRadiusX * 2,
      height: ringRadiusY * 2,
    );

    // Arco de trayectoria con gradiente violeta/cyan
    final orbitSweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: [
          const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          const Color(0xFF8B5CF6).withValues(alpha: 0.8),
          const Color(0xFF00E5FF),
          const Color(0xFF00E5FF).withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(orbitRect);

    canvas.drawOval(orbitRect, orbitSweepPaint);

    // Cabeza del cometa / plasma brillante que orbita
    final double angle = progress * math.pi * 2;
    final headX = ringRadiusX * math.cos(angle);
    final headY = ringRadiusY * math.sin(angle);

    final cometGlowPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(headX, headY), 5.5, cometGlowPaint);

    final cometCorePaint = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawCircle(Offset(headX, headY), 3.0, cometCorePaint);

    // Estela de partículas detrás de la cabeza del cometa
    for (int i = 1; i <= 6; i++) {
      final tailAngle = angle - (i * 0.09);
      final tx = ringRadiusX * math.cos(tailAngle);
      final ty = ringRadiusY * math.sin(tailAngle);
      final pPaint = Paint()
        ..color = const Color(0xFFC084FC).withValues(alpha: (1.0 - (i / 7.0)) * 0.7);
      canvas.drawCircle(Offset(tx, ty), 3.0 - (i * 0.35), pPaint);
    }

    // 3. Destello Anamórfico de Lente horizontal cuando el cometa pasa por el vértice
    if (progress >= 0.38 && progress <= 0.65) {
      final flareIntensity = 1.0 - (((progress - 0.50).abs()) / 0.15).clamp(0.0, 1.0);
      final flareLinePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: flareIntensity * 0.85)
        ..strokeWidth = 1.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawLine(
        Offset(-ringRadiusX * 1.3, headY),
        Offset(ringRadiusX * 1.3, headY),
        flareLinePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CosmicScenePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
