import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// Modal para gestionar documentos adicionales en Colombia:
/// Licencia de Conducción, Impuesto Vehicular y Extintor / Kit de Carretera.
class LegalExtrasSheet extends StatefulWidget {
  final String vehiculoId;
  final Map<String, dynamic> vehicleData;

  const LegalExtrasSheet({
    super.key,
    required this.vehiculoId,
    required this.vehicleData,
  });

  static Future<bool> show(
    BuildContext context, {
    required String vehiculoId,
    required Map<String, dynamic> vehicleData,
  }) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalExtrasSheet(
        vehiculoId: vehiculoId,
        vehicleData: vehicleData,
      ),
    );
    return res == true;
  }

  @override
  State<LegalExtrasSheet> createState() => _LegalExtrasSheetState();
}

class _LegalExtrasSheetState extends State<LegalExtrasSheet> {
  DateTime? _licenciaVence;
  DateTime? _impuestoVence;
  DateTime? _extintorVence;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    final prefs = await SharedPreferences.getInstance();
    final remoteLic = widget.vehicleData['licencia_vencimiento']?.toString();
    final remoteImp = widget.vehicleData['impuesto_vencimiento']?.toString();
    final remoteExt = widget.vehicleData['extintor_vencimiento']?.toString();

    final licStr = remoteLic ?? prefs.getString('extra_lic_${widget.vehiculoId}');
    final impStr = remoteImp ?? prefs.getString('extra_imp_${widget.vehiculoId}');
    final extStr = remoteExt ?? prefs.getString('extra_ext_${widget.vehiculoId}');

    if (mounted) {
      setState(() {
        _licenciaVence = licStr != null ? DateTime.tryParse(licStr) : null;
        _impuestoVence = impStr != null ? DateTime.tryParse(impStr) : null;
        _extintorVence = extStr != null ? DateTime.tryParse(extStr) : null;
      });
    }
  }

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> onSelected,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 180)),
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365 * 12)),
    );
    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final licIso = _licenciaVence?.toIso8601String().split('T').first;
      final impIso = _impuestoVence?.toIso8601String().split('T').first;
      final extIso = _extintorVence?.toIso8601String().split('T').first;

      if (licIso != null) {
        await prefs.setString('extra_lic_${widget.vehiculoId}', licIso);
        await NotificationService().scheduleLegalNotification(
          id: 9101,
          type: 'Licencia de Conducción',
          dueDate: _licenciaVence!,
        );
      }
      if (impIso != null) {
        await prefs.setString('extra_imp_${widget.vehiculoId}', impIso);
        await NotificationService().scheduleLegalNotification(
          id: 9102,
          type: 'Impuesto Vehicular',
          dueDate: _impuestoVence!,
        );
      }
      if (extIso != null) {
        await prefs.setString('extra_ext_${widget.vehiculoId}', extIso);
        await NotificationService().scheduleLegalNotification(
          id: 9103,
          type: 'Extintor / Kit de Carretera',
          dueDate: _extintorVence!,
        );
      }

      try {
        final client = Supabase.instance.client;
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          await client
              .from('vehiculos')
              .update({
                if (licIso != null) 'licencia_vencimiento': licIso,
                if (impIso != null) 'impuesto_vencimiento': impIso,
                if (extIso != null) 'extintor_vencimiento': extIso,
              })
              .eq('id', widget.vehiculoId)
              .eq('user_id', uid);
        }
      } catch (e) {
        debugPrint('[LEGAL_EXTRAS] Guardado local (columnas remotas pendientes): $e');
      }

      if (!mounted) return;
      AppSnackBar.show(
        context,
        'Vencimientos legales guardados y alertas programadas',
        backgroundColor: const Color(0xFF059669),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(DateTime? d) => d == null
      ? 'Sin fecha'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Documentos Colombia Extra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Evita multas por licencia vencida, impuesto o extintor sin carga.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            _DocRowTile(
              icon: Icons.credit_card_rounded,
              title: 'Licencia de Conducción (Pase)',
              value: _fmt(_licenciaVence),
              onTap: () => _pickDate(_licenciaVence, (d) => _licenciaVence = d),
            ),
            const SizedBox(height: 10),
            _DocRowTile(
              icon: Icons.receipt_long_rounded,
              title: 'Impuesto Vehicular Anual',
              value: _fmt(_impuestoVence),
              onTap: () => _pickDate(_impuestoVence, (d) => _impuestoVence = d),
            ),
            const SizedBox(height: 10),
            _DocRowTile(
              icon: Icons.fire_extinguisher_rounded,
              title: 'Extintor y Kit de Carretera',
              value: _fmt(_extintorVence),
              onTap: () => _pickDate(_extintorVence, (d) => _extintorVence = d),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveAll,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.notifications_active_rounded),
              label: const Text('Guardar y Programar Alertas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocRowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DocRowTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vencimiento: $value',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF38BDF8)),
          ],
        ),
      ),
    );
  }
}
