// =============================================================================
// waze_report_sheet.dart — MODAL GLASSMORPHIC DE REPORTES 1-TAP Y VOZ (COLOMBIA)
// =============================================================================
// Permite reportar retenes, fotomultas, huecos y resaltos de moto en 1 segundo
// o mediante dictado por voz manos libres.
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/voice_navigation_service.dart';
import '../../../../core/services/waze_community_alerts_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

class WazeReportSheet extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final bool isCar;

  const WazeReportSheet({
    super.key,
    required this.currentLat,
    required this.currentLng,
    this.isCar = false,
  });

  static void show(
    BuildContext context, {
    required double lat,
    required double lng,
    bool isCar = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WazeReportSheet(
        currentLat: lat,
        currentLng: lng,
        isCar: isCar,
      ),
    );
  }

  @override
  State<WazeReportSheet> createState() => _WazeReportSheetState();
}

class _WazeReportSheetState extends State<WazeReportSheet> {
  final _voiceCtrl = TextEditingController();

  @override
  void dispose() {
    _voiceCtrl.dispose();
    super.dispose();
  }

  void _sendReport(WazeIncidentType type, String title) {
    WazeCommunityAlertsService().reportIncident(
      type: type,
      title: title,
      description: widget.isCar
          ? 'Reportado por conductor de carro'
          : 'Reportado por motociclista en ruta',
      latitude: widget.currentLat,
      longitude: widget.currentLng,
    );

    VoiceNavigationService().speak('Reporte enviado: $title');
    Navigator.pop(context);
    AppSnackBar.show(
      context,
      'Reporte registrado en tiempo real: $title',
      backgroundColor: const Color(0xFF059669),
    );
  }

  void _submitVoiceText() {
    final text = _voiceCtrl.text.trim();
    if (text.isEmpty) return;
    final parsed = parseWazeVoiceCommand(text);
    _sendReport(parsed.type, parsed.title);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(22, 20, 22, inset + 24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.isCar
                    ? 'REPORTAR EN LA VÍA (CARRO)'
                    : 'ALERTAS MOTO & VÍA (1-TAP)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _voiceCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitVoiceText(),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Dicta por voz: "hay hueco", "retén", "fotomulta"...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(Icons.mic_rounded, color: Color(0xFF38BDF8)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF00FF87)),
                    onPressed: _submitVoiceText,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 18,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _ReportTile(
                    icon: Icons.local_police_rounded,
                    label: 'Policía',
                    color: const Color(0xFF0A84FF),
                    onTap: () => _sendReport(WazeIncidentType.police, '👮 Retén de Policía / Tránsito'),
                  ),
                  _ReportTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Fotomulta',
                    color: const Color(0xFFFF9500),
                    onTap: () => _sendReport(WazeIncidentType.radar, '🚨 Cámara / Radar de Fotomulta'),
                  ),
                  _ReportTile(
                    icon: Icons.warning_amber_rounded,
                    label: 'Hueco Moto',
                    color: const Color(0xFFF59E0B),
                    onTap: () => _sendReport(WazeIncidentType.pothole, '🕳️ Hueco Peligroso en Vía'),
                  ),
                  _ReportTile(
                    icon: Icons.speed_rounded,
                    label: 'Resalto',
                    color: const Color(0xFFA855F7),
                    onTap: () => _sendReport(WazeIncidentType.speedBump, '⚠️ Resalto / Policía Acostado'),
                  ),
                  _ReportTile(
                    icon: Icons.car_crash_rounded,
                    label: 'Accidente',
                    color: const Color(0xFFFF3B30),
                    onTap: () => _sendReport(WazeIncidentType.accident, '🚗 Accidente de Tránsito'),
                  ),
                  _ReportTile(
                    icon: Icons.construction_rounded,
                    label: 'Obra / Tráfico',
                    color: const Color(0xFFFFCC00),
                    onTap: () => _sendReport(WazeIncidentType.construction, '🚧 Obra en Vía / Tráfico'),
                  ),
                  _ReportTile(
                    icon: Icons.water_drop_rounded,
                    label: 'Inundación',
                    color: const Color(0xFF30D158),
                    onTap: () => _sendReport(WazeIncidentType.flooding, '🌧️ Vía Inundada / Mal Estado'),
                  ),
                  _ReportTile(
                    icon: Icons.toll_rounded,
                    label: 'Peaje',
                    color: const Color(0xFF38BDF8),
                    onTap: () => _sendReport(WazeIncidentType.tollQueue, '🛣️ Trancón en Peaje'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ReportTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
