import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/pico_y_placa_service.dart';
import '../../../../core/theme/brand_theme.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

class PicoYPlacaCard extends StatefulWidget {
  final String plate;
  final bool isCar;
  final BrandTheme brandTheme;

  const PicoYPlacaCard({
    super.key,
    required this.plate,
    required this.isCar,
    required this.brandTheme,
  });

  @override
  State<PicoYPlacaCard> createState() => _PicoYPlacaCardState();
}

class _PicoYPlacaCardState extends State<PicoYPlacaCard> {
  final _service = PicoYPlacaService();
  PicoYPlacaStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant PicoYPlacaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plate != widget.plate || oldWidget.isCar != widget.isCar) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final res = await _service.detectAndEvaluate(
      plate: widget.plate,
      isCar: widget.isCar,
      schedulePushReminders: true,
    );
    if (mounted) {
      setState(() {
        _status = res;
        _loading = false;
      });
    }
  }

  Future<void> _pickManualCity() async {
    const cities = [
      'Bogotá',
      'Medellín',
      'Cali',
      'Bucaramanga',
      'Barranquilla',
      'Pereira',
      'Manizales',
      'Armenia',
      'Cartagena',
      'Ibagué',
      'Otro municipio sin restricción',
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D111D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_city_rounded,
                        color: Color(0xFF00E5FF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Consultar Pico y Placa en otra ciudad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: cities.length,
                itemBuilder: (ctx, idx) {
                  final city = cities[idx];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pin_drop_rounded,
                          size: 16, color: Color(0xFF00E5FF)),
                    ),
                    title: Text(
                      city,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Colors.white38),
                    onTap: () => Navigator.pop(ctx, city),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final manualStatus = PicoYPlacaService.evaluateForDate(
      plate: widget.plate,
      isCar: widget.isCar,
      cityName: chosen,
      date: DateTime.now(),
      detectedBy: 'Manual',
    );
    setState(() => _status = manualStatus);
    AppSnackBar.show(context, 'Regla actualizada para $chosen.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _status;

    Color accent = const Color(0xFF00E5FF); // Cian Neón estándar
    Color badgeBg = const Color(0xFF00E5FF).withValues(alpha: 0.12);
    IconData statusIcon = Icons.check_circle_outline_rounded;

    if (status != null) {
      if (status.isRestrictedToday) {
        accent = const Color(0xFFFF3366); // Rojo Neón de alerta
        badgeBg = const Color(0xFFFF3366).withValues(alpha: 0.16);
        statusIcon = Icons.do_not_disturb_on_rounded;
      } else if (status.isRestrictedTomorrow) {
        accent = const Color(0xFFFFB300); // Ámbar Neón de advertencia
        badgeBg = const Color(0xFFFFB300).withValues(alpha: 0.16);
        statusIcon = Icons.warning_amber_rounded;
      } else if (!status.hasRestrictionSystem || !status.appliesToVehicleType) {
        accent = const Color(0xFF00E5FF); // Cian Neón / Libre
        badgeBg = const Color(0xFF00E5FF).withValues(alpha: 0.12);
        statusIcon = Icons.verified_rounded;
      } else {
        accent = const Color(0xFF00E676); // Verde Esmeralda Neón
        badgeBg = const Color(0xFF00E676).withValues(alpha: 0.12);
        statusIcon = Icons.check_circle_rounded;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: 0.38),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: _loading || status == null
          ? Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Detectando ciudad GPS y Pico y Placa...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(statusIcon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 11,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54),
                                const SizedBox(width: 4),
                                Text(
                                  'Pico y Placa • ${status.cityName} (${status.detectedBy})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.headline,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    _HeaderIconButton(
                      tooltip: 'Cambiar ciudad',
                      icon: Icons.edit_location_alt_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _pickManualCity();
                      },
                    ),
                    const SizedBox(width: 6),
                    _HeaderIconButton(
                      tooltip: 'Actualizar GPS',
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _refresh();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.detail,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      if (status.scheduleText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13,
                                color:
                                    isDark ? Colors.white54 : Colors.black54),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Horario: ${status.scheduleText}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
