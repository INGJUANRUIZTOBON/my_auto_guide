import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apertura Cinemática Oficial MY AUTO GUIDE.
/// Reproduce la animación de apertura de alta definición (horizonte cósmico,
/// anillo orbital de plasma en 360°, escudo oficial y tipografía brillante).
/// Soporta omisión instantánea al tocar la pantalla o el botón "Omitir".
class CosmicOrbitalIntro extends StatefulWidget {
  final VoidCallback onIntroComplete;
  final VoidCallback? onSkip;
  final Duration duration;

  const CosmicOrbitalIntro({
    super.key,
    required this.onIntroComplete,
    this.onSkip,
    this.duration = const Duration(milliseconds: 6800),
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
      if (t >= 0.40 && !_hapticFired) {
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
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Animación Cinemática Oficial WebP (24fps / 7.0s de alta fidelidad)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                  maxHeight: 920,
                ),
                child: Image.asset(
                  'assets/images/intro_animation.webp',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              ),
            ),

            // 2. Barra de progreso tenue y sutil en el borde inferior
            Positioned(
              bottom: 24,
              left: 32,
              right: 32,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Center(
                    child: Container(
                      width: 140,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _controller.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
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
              child: SafeArea(
                child: InkWell(
                  onTap: _skipIntro,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Omitir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white),
                      ],
                    ),
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
