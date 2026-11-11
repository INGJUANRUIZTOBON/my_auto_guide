import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cinematic_painters.dart';

/// Snapshot ligero en caché para mostrar marca/tipo/foto real del usuario desde el frame 0 al abrir la app.
class BootVehicleSnapshot {
  static const String _prefKey = 'last_boot_vehicle_snapshot';

  final String marca;
  final String modelo;
  final String placa;
  final bool isCar;
  final String? imagePath;

  const BootVehicleSnapshot({
    required this.marca,
    required this.modelo,
    required this.placa,
    required this.isCar,
    this.imagePath,
  });

  static Future<void> save({
    required String marca,
    required String modelo,
    required String placa,
    required bool isCar,
    String? imagePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        jsonEncode({
          'marca': marca,
          'modelo': modelo,
          'placa': placa,
          'isCar': isCar,
          'imagePath': imagePath,
        }),
      );
    } catch (_) {}
  }

  static Future<BootVehicleSnapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null || raw.isEmpty) return null;
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return BootVehicleSnapshot(
        marca: map['marca']?.toString() ?? '',
        modelo: map['modelo']?.toString() ?? '',
        placa: map['placa']?.toString() ?? '',
        isCar: map['isCar'] != false,
        imagePath: map['imagePath']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Secuencia cinemática de arranque automotriz:
/// Ignición de faros -> Barrido real de tacómetro (0 a redline y ralentí) -> Escaneo holográfico -> Checklist Colombia OK.
class CinematicVehicleLoader extends StatefulWidget {
  final String statusText;
  final bool isDataReady;
  final VoidCallback? onIntroComplete;
  final VoidCallback? onSkip;

  const CinematicVehicleLoader({
    super.key,
    this.statusText = 'SINCRONIZANDO MY AUTO GUIDE...',
    this.isDataReady = false,
    this.onIntroComplete,
    this.onSkip,
  });

  @override
  State<CinematicVehicleLoader> createState() => _CinematicVehicleLoaderState();
}

class _CinematicVehicleLoaderState extends State<CinematicVehicleLoader>
    with TickerProviderStateMixin {
  late final AnimationController _ignitionController;
  late final AnimationController _idleController;

  BootVehicleSnapshot? _snapshot;
  bool _hapticIgnitionFired = false;
  bool _hapticReadyFired = false;
  bool _introNotified = false;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();

    _ignitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(_handleTimelineEvents)
     ..addStatusListener((status) {
       if (status == AnimationStatus.completed && !_introNotified) {
         _introNotified = true;
         widget.onIntroComplete?.call();
       }
     });

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _ignitionController.forward();
  }

  Future<void> _loadSnapshot() async {
    final loaded = await BootVehicleSnapshot.load();
    if (mounted && loaded != null) {
      setState(() => _snapshot = loaded);
    }
  }

  void _handleTimelineEvents() {
    final t = _ignitionController.value;
    if (t >= 0.14 && !_hapticIgnitionFired) {
      _hapticIgnitionFired = true;
      HapticFeedback.mediumImpact();
    }
    if (t >= 0.88 && !_hapticReadyFired) {
      _hapticReadyFired = true;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _ignitionController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  double _computeRpmCurve(double t, double idleWave) {
    if (t < 0.16) {
      // Encendido inicial
      return Curves.easeOut.transform(t / 0.16) * 0.08;
    } else if (t < 0.44) {
      // Needle Sweep ascendente rápido hasta redline
      final p = (t - 0.16) / 0.28;
      return 0.08 + Curves.easeOutCubic.transform(p) * 0.90;
    } else if (t < 0.68) {
      // Caída natural del tacómetro hasta ralentí estable (~850 RPM = 13%)
      final p = (t - 0.44) / 0.24;
      return 0.98 - Curves.easeInOutCubic.transform(p) * 0.84;
    }
    // Ralentí vivo con micro-pulsación realista
    return 0.14 + math.sin(idleWave * math.pi * 2) * 0.018;
  }

  double _computeHeadlightFlare(double t, double idleWave) {
    if (t < 0.08) return 0.0;
    if (t < 0.24) return Curves.easeOut.transform((t - 0.08) / 0.16);
    if (t < 0.45) return 1.0 - Curves.easeOut.transform((t - 0.24) / 0.21) * 0.58;
    return 0.42 + math.sin(idleWave * math.pi * 2) * 0.05;
  }

  double _computeLaserScan(double t) {
    if (t < 0.42 || t > 0.84) return -1.0;
    return Curves.easeInOut.transform((t - 0.42) / 0.42);
  }

  void _handleTap() {
    if (!widget.isDataReady) return;
    HapticFeedback.selectionClick();
    if (!_introNotified) {
      _introNotified = true;
      (widget.onSkip ?? widget.onIntroComplete)?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF06080C),
        child: AnimatedBuilder(
          animation: Listenable.merge([_ignitionController, _idleController]),
          builder: (context, _) {
            final t = reduceMotion ? 1.0 : _ignitionController.value;
            final idle = reduceMotion ? 0.0 : _idleController.value;
            final ignition = Curves.easeOut.transform((t / 0.22).clamp(0.0, 1.0));
            final rpmVal = _computeRpmCurve(t, idle);
            final int rpmDisplay = (rpmVal * 8000).round();
            final int speedPeakDisplay = t < 0.68 ? (rpmVal * 220).round() : 0;
            final flare = _computeHeadlightFlare(t, idle);
            final scan = _computeLaserScan(t);
            final bool showMoto = _snapshot != null
                ? !_snapshot!.isCar
                : (idle > 0.5 && _snapshot == null);

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: ShowroomBackdropPainter(
                        ignition: ignition,
                        idlePhase: idle,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIdentityHeader(ignition),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 292,
                          height: 292,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              RepaintBoundary(
                                child: CustomPaint(
                                  size: const Size(292, 292),
                                  painter: CockpitTachometerPainter(
                                    rpmProgress: rpmVal,
                                    ignition: ignition,
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: ignition,
                                child: Transform.scale(
                                  scale: 0.94 + ignition * 0.06,
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: 232,
                                      height: 232,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildVehicleVisual(showMoto),
                                          CustomPaint(
                                            painter: HeadlightAndScanPainter(
                                              flareIntensity: flare,
                                              scanProgress: scan,
                                              isCar: !showMoto,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 18,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t < 0.68
                                          ? '$speedPeakDisplay KM/H'
                                          : '$rpmDisplay RPM',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color: Colors.white,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                        shadows: [
                                          Shadow(color: Color(0xFF00E5FF), blurRadius: 14),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      t < 0.68 ? 'IGNITION SWEEP' : 'RALENTÍ ESTABLE • READY',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.4,
                                        color: t >= 0.68
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF00E5FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        _buildSystemChecklist(t),
                        const SizedBox(height: 20),
                        _buildBottomPrompt(t, idle),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(double ignition) {
    final snap = _snapshot;
    final hasSnap = snap != null && (snap.marca.isNotEmpty || snap.placa.isNotEmpty);
    final label = hasSnap
        ? '${snap.marca.toUpperCase()} ${snap.modelo}'.trim()
        : 'MY AUTO GUIDE';
    final sub = hasSnap && snap.placa.isNotEmpty
        ? 'PLACA ${snap.placa.toUpperCase()} • TELEMETRÍA'
        : 'ECOSISTEMA VEHICULAR COLOMBIA';

    return Opacity(
      opacity: ignition,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snap?.imagePath != null && snap!.imagePath!.isNotEmpty) ...[
                  ClipOval(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: _buildTinyAvatar(snap.imagePath!, snap.isCar),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyAvatar(String path, bool isCar) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(isCar ? Icons.directions_car : Icons.two_wheeler, size: 14, color: Colors.white),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(isCar ? Icons.directions_car : Icons.two_wheeler, size: 14, color: Colors.white),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Icon(isCar ? Icons.directions_car : Icons.two_wheeler, size: 14, color: Colors.white),
    );
  }

  Widget _buildVehicleVisual(bool showMoto) {
    final asset = showMoto
        ? 'assets/images/splash_moto.jpg'
        : 'assets/images/splash_car.jpg';

    return ShaderMask(
      shaderCallback: (rect) => const RadialGradient(
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.72, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: Image.asset(
          asset,
          key: ValueKey(asset),
          fit: BoxFit.cover,
          cacheWidth: 900,
        ),
      ),
    );
  }

  Widget _buildSystemChecklist(double t) {
    final checks = [
      ('GPS & RUTA', t >= 0.34),
      ('PICO Y PLACA', t >= 0.54),
      ('RUNT & SOAT', t >= 0.72),
      ('MOTOR IA', t >= 0.88),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: checks.map((c) {
        final ok = c.$2;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ok
                ? const Color(0xFF10B981).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ok
                  ? const Color(0xFF10B981).withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 13,
                color: ok ? const Color(0xFF10B981) : Colors.white38,
              ),
              const SizedBox(width: 5),
              Text(
                c.$1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ok ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomPrompt(double t, double idle) {
    if (widget.isDataReady) {
      final pulse = 0.65 + math.sin(idle * math.pi * 2) * 0.35;
      return Opacity(
        opacity: pulse.clamp(0.4, 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.45)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, size: 15, color: Color(0xFF00E5FF)),
              SizedBox(width: 6),
              Text(
                'DATOS LISTOS • TOCA PARA ENTRAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Text(
      t >= 0.88 ? 'SINCRONIZANDO CON SUPABASE...' : widget.statusText,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}
