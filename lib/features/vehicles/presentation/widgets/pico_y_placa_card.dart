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
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Consultar Pico y Placa en otra ciudad',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          ...cities.map(
            (city) => ListTile(
              leading: const Icon(Icons.location_city_rounded),
              title: Text(city),
              onTap: () => Navigator.pop(ctx, city),
            ),
          ),
        ],
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

    Color accent = Colors.green;
    if (status != null) {
      if (status.isRestrictedToday) {
        accent = Colors.redAccent;
      } else if (status.isRestrictedTomorrow) {
        accent = Colors.orange;
      } else if (!status.hasRestrictionSystem || !status.appliesToVehicleType) {
        accent = widget.brandTheme.primaryColor;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _loading || status == null
          ? const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Detectando ciudad GPS y Pico y Placa...'),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.traffic_rounded, color: accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pico y Placa • ${status.cityName} (${status.detectedBy})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.headline,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cambiar ciudad / simular',
                      icon: const Icon(Icons.edit_location_alt_rounded, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _pickManualCity();
                      },
                    ),
                    IconButton(
                      tooltip: 'Actualizar GPS',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _refresh,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  status.detail,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (status.scheduleText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Horario: ${status.scheduleText}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
