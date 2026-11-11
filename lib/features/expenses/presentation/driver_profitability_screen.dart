import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../data/driver_income_service.dart';

class DriverProfitabilityScreen extends StatefulWidget {
  final String vehiculoId;
  final String marcaModelo;
  final String placa;

  const DriverProfitabilityScreen({
    super.key,
    required this.vehiculoId,
    required this.marcaModelo,
    required this.placa,
  });

  @override
  State<DriverProfitabilityScreen> createState() =>
      _DriverProfitabilityScreenState();
}

class _DriverProfitabilityScreenState extends State<DriverProfitabilityScreen> {
  final _service = DriverIncomeService();
  List<DriverIncomeEntry> _entries = const [];
  double _vehicleExpenses30d = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final entries = await _service.getEntries(widget.vehiculoId);
    double expensesSum = 0.0;
    try {
      final rows = await SupabaseService().getExpenses(widget.vehiculoId);
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      for (final row in rows) {
        final rawDate = row['fecha']?.toString();
        final d = rawDate != null ? DateTime.tryParse(rawDate) : null;
        if (d == null || d.isAfter(cutoff)) {
          expensesSum += ((row['monto'] ?? 0) as num).toDouble();
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _entries = entries;
        _vehicleExpenses30d = expensesSum;
        _loading = false;
      });
    }
  }

  Future<void> _openAddTurnModal() async {
    String selectedPlatform = DriverIncomeService.platformsColombia.first;
    final brutoCtrl = TextEditingController();
    final peajesCtrl = TextEditingController(text: '0');
    final otrosCtrl = TextEditingController(text: '0');
    final kmsCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Registrar Turno / Ingreso',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlatform,
                  decoration: const InputDecoration(
                    labelText: 'Plataforma / Servicio',
                    border: OutlineInputBorder(),
                  ),
                  items: DriverIncomeService.platformsColombia
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedPlatform = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: brutoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ingreso bruto del turno (COP)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: peajesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peajes (COP)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: otrosCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Otros gastos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: kmsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Kilómetros recorridos en el turno',
                    suffixText: 'km',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Guardar turno'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final bruto = double.tryParse(brutoCtrl.text.trim()) ?? 0;
    final peajes = double.tryParse(peajesCtrl.text.trim()) ?? 0;
    final otros = double.tryParse(otrosCtrl.text.trim()) ?? 0;
    final kms = double.tryParse(kmsCtrl.text.trim()) ?? 0;
    final notas = notasCtrl.text.trim();
    brutoCtrl.dispose();
    peajesCtrl.dispose();
    otrosCtrl.dispose();
    kmsCtrl.dispose();
    notasCtrl.dispose();

    if (ok != true || bruto <= 0) return;

    await _service.addEntry(
      vehiculoId: widget.vehiculoId,
      plataforma: selectedPlatform,
      montoBruto: bruto,
      peajes: peajes,
      otrosGastos: otros,
      kmsTurno: kms,
      notas: notas,
    );
    await _loadData();
    if (mounted) {
      AppSnackBar.show(context, 'Turno registrado en Modo Conductor.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = DriverIncomeService.computeSummary(
      _entries,
      externalExpenses: _vehicleExpenses30d,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final netPositive = summary.totalNeto >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Conductor • Rentabilidad'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTurnModal,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar Turno'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: netPositive
                          ? [const Color(0xFF065F46), const Color(0xFF10B981)]
                          : [const Color(0xFF7F1D1D), const Color(0xFFEF4444)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.placa.toUpperCase()} • ${widget.marcaModelo}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ganancia Neta Real (últimos 30 días de gastos)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${AppFormat.thousands(summary.totalNeto.round())} COP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _metricChip(
                            'Bruto: \$${AppFormat.thousands(summary.totalBruto.round())}',
                          ),
                          _metricChip(
                            'Gastos vehículo 30d: \$${AppFormat.thousands(summary.totalGastosVehiculoPeriodo.round())}',
                          ),
                          _metricChip(
                            'COP/km neto: \$${AppFormat.thousands(summary.promedioCopPorKm.round())}/km',
                          ),
                          _metricChip('${summary.totalKms.toStringAsFixed(1)} km'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Turnos Registrados (${_entries.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (_entries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Registra tus turnos de Uber, DiDi, inDrive, Rappi, Picap o fletes para calcular automáticamente cuánto ganas neto por kilómetro después de gasolina, peajes y gastos del vehículo.',
                    ),
                  )
                else
                  ..._entries.map((entry) {
                    final fmt = DateFormat('dd/MM/yyyy').format(entry.fecha.toLocal());
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          '${entry.plataforma} • \$${AppFormat.thousands(entry.netProfit.round())} neto',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '$fmt • Bruto \$${AppFormat.thousands(entry.montoBruto.round())} • '
                          '${entry.kmsTurno.toStringAsFixed(1)} km '
                          '(${entry.kmsTurno > 0 ? "\$${AppFormat.thousands(entry.copPerKm.round())}/km" : "-"})',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _service.deleteEntry(
                              vehiculoId: widget.vehiculoId,
                              entryId: entry.id,
                            );
                            await _loadData();
                          },
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Widget _metricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
