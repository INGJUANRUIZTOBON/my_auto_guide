import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/driver_license_parser.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/runt_driver_license_webview.dart';

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
  RuntDriverProfile? _driverProfile;
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
    final extStr = extStrOrNull(remoteExt ?? prefs.getString('extra_ext_${widget.vehiculoId}'));

    // 1. Cargar perfil de licencias RUNT desde Supabase si viene en vehicleData
    RuntDriverProfile? driverProfile;
    final remoteDriver = widget.vehicleData['driver_license_data'];
    if (remoteDriver is Map) {
      driverProfile = RuntDriverProfile.fromMap(Map<String, dynamic>.from(remoteDriver));
    } else if (remoteDriver is String && remoteDriver.trim().isNotEmpty) {
      driverProfile = RuntDriverProfile.tryDecodeWebViewResult(remoteDriver);
    }

    // 2. Fallback a SharedPreferences local si no venía en el map remoto
    if (driverProfile == null) {
      final rawDriver = prefs.getString('runt_driver_license_profile_${widget.vehiculoId}') ??
          prefs.getString('runt_driver_license_profile_global');
      if (rawDriver != null && rawDriver.isNotEmpty) {
        driverProfile = RuntDriverProfile.tryDecodeWebViewResult(rawDriver);
      }
    }

    if (mounted) {
      setState(() {
        _licenciaVence = licStr != null ? DateTime.tryParse(licStr) : null;
        _impuestoVence = impStr != null ? DateTime.tryParse(impStr) : null;
        _extintorVence = extStr != null ? DateTime.tryParse(extStr) : null;
        if (driverProfile != null && driverProfile.licencias.isNotEmpty) {
          _driverProfile = driverProfile;
        }
      });
    }
  }

  String? extStrOrNull(String? val) => (val == null || val.isEmpty) ? null : val;

  Future<void> _consultarLicenciaEnRunt() async {
    String cedula = (widget.vehicleData['cedula'] ?? '').toString().trim();
    if (!RegExp(r'^\d{4,15}$').hasMatch(cedula) && _driverProfile != null && _driverProfile!.numeroDocumento.isNotEmpty) {
      cedula = _driverProfile!.numeroDocumento;
    }

    final res = await Navigator.push<RuntDriverProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => RuntDriverLicenseWebViewScreen(
          cedula: cedula,
          vehiculoId: widget.vehiculoId,
        ),
      ),
    );
    if (res != null && mounted) {
      setState(() {
        _driverProfile = res;
        _licenciaVence = res.earliestExpiration ?? _licenciaVence;
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
                if (_driverProfile != null) 'driver_license_data': _driverProfile!.toJson(),
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
        child: SingleChildScrollView(
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _consultarLicenciaEnRunt,
              icon: const Icon(Icons.verified_user_rounded, size: 18),
              label: Text(
                _driverProfile != null && _driverProfile!.licencias.isNotEmpty
                    ? 'Actualizar Mis Licencias en RUNT'
                    : 'Verificar Categorías y Vigencia en RUNT',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
            if (_driverProfile != null && _driverProfile!.licencias.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Licencias RUNT (${_driverProfile!.vigentes.length} vigentes de ${_driverProfile!.licencias.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _driverProfile!.licencias.map((lic) {
                        final ok = lic.isVigente;
                        final c = ok ? const Color(0xFF10B981) : Colors.redAccent;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.withValues(alpha: 0.45)),
                          ),
                          child: Text(
                            'Cat. ${lic.categoria} (${lic.inferredServicio}) • ${ok ? "Vigente" : (lic.estado.isNotEmpty ? lic.estado : "Vencida")}'
                            '${lic.fechaVencimiento.isNotEmpty ? " • Vence ${lic.fechaVencimiento}" : ""}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
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
