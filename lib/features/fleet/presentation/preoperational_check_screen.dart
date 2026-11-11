import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../data/fleet_service.dart';

class PreoperationalCheckScreen extends StatefulWidget {
  final String vehiculoId;
  final String placa;
  final String marcaModelo;
  final bool isCar;
  final String? flotaId;

  const PreoperationalCheckScreen({
    super.key,
    required this.vehiculoId,
    required this.placa,
    required this.marcaModelo,
    required this.isCar,
    this.flotaId,
  });

  @override
  State<PreoperationalCheckScreen> createState() =>
      _PreoperationalCheckScreenState();
}

class _PreoperationalCheckScreenState extends State<PreoperationalCheckScreen> {
  final _service = FleetService();
  final _obsController = TextEditingController();
  late Map<String, bool> _checks;
  bool _saving = false;
  List<PreoperationalInspection> _history = const [];

  @override
  void initState() {
    super.initState();
    final items = widget.isCar
        ? FleetService.pesvItemsCar
        : FleetService.pesvItemsMoto;
    _checks = {for (final item in items) item: true};
    _loadHistory();
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final rows = await _service.getRecentInspections(
      vehiculoId: widget.vehiculoId,
    );
    if (mounted) {
      setState(() => _history = rows);
    }
  }

  Future<void> _saveInspection() async {
    setState(() => _saving = true);
    try {
      final saved = await _service.savePreoperational(
        flotaId: widget.flotaId,
        vehiculoId: widget.vehiculoId,
        items: _checks,
        observaciones: _obsController.text,
      );
      if (!mounted) return;
      _obsController.clear();
      await _loadHistory();
      if (!mounted) return;
      AppSnackBar.show(
        context,
        saved.aprobada
            ? 'Preoperacional PESV APROBADA y guardada.'
            : 'Preoperacional guardada CON HALLAZGOS (No Apta).',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'No se pudo guardar la inspección: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allOk = _checks.values.every((v) => v);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preoperacional PESV'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (allOk ? Colors.green : Colors.orange).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.placa.toUpperCase()} • ${widget.marcaModelo}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lista diaria PESV Colombia (${widget.isCar ? "Automóvil" : "Motocicleta"})',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._checks.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                title: Text(entry.key, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  entry.value ? 'Estado conforme' : 'Hallazgo / Falla detectada',
                  style: TextStyle(
                    fontSize: 12,
                    color: entry.value ? Colors.green : Colors.redAccent,
                  ),
                ),
                value: entry.value,
                activeThumbColor: Colors.green,
                onChanged: (val) => setState(() => _checks[entry.key] = val),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextField(
            controller: _obsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Observaciones / Novedades (opcional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _saveInspection,
            icon: Icon(
              allOk ? Icons.verified_rounded : Icons.warning_amber_rounded,
            ),
            label: Text(
              _saving
                  ? 'Guardando...'
                  : (allOk
                      ? 'Registrar Preoperacional Aprobada'
                      : 'Registrar con Hallazgos'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: allOk ? const Color(0xFF10B981) : Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Historial Reciente PESV',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ..._history.take(8).map((item) {
              final fmt = DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt.toLocal());
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.aprobada ? Icons.check_circle : Icons.error_outline,
                  color: item.aprobada ? Colors.green : Colors.orange,
                ),
                title: Text(item.aprobada ? 'Aprobada ($fmt)' : 'Con hallazgos ($fmt)'),
                subtitle: item.observaciones.isNotEmpty
                    ? Text(item.observaciones)
                    : null,
              );
            }),
          ],
        ],
      ),
    );
  }
}
