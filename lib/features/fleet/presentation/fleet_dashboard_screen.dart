import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../data/fleet_service.dart';
import 'preoperational_check_screen.dart';

class FleetDashboardScreen extends StatefulWidget {
  final String vehiculoId;
  final String placa;
  final String marcaModelo;
  final bool isCar;
  final String? soatVencimiento;
  final String? tecnoVencimiento;

  const FleetDashboardScreen({
    super.key,
    required this.vehiculoId,
    required this.placa,
    required this.marcaModelo,
    required this.isCar,
    this.soatVencimiento,
    this.tecnoVencimiento,
  });

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  final _service = FleetService();
  bool _loading = true;
  List<FleetModel> _fleets = const [];
  FleetModel? _selectedFleet;
  List<FleetMemberModel> _members = const [];
  List<PreoperationalInspection> _inspections = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final fleets = await _service.getMyFleets();
    FleetModel? selected = _selectedFleet;
    if (selected == null && fleets.isNotEmpty) {
      selected = fleets.first;
    } else if (selected != null) {
      selected = fleets.cast<FleetModel?>().firstWhere(
            (f) => f?.id == selected!.id,
            orElse: () => fleets.isNotEmpty ? fleets.first : null,
          );
    }

    List<FleetMemberModel> members = const [];
    List<PreoperationalInspection> inspections = const [];
    if (selected != null) {
      members = await _service.getMembers(selected.id);
      inspections = await _service.getRecentInspections(
        vehiculoId: widget.vehiculoId,
        flotaId: selected.id,
      );
    }
    if (mounted) {
      setState(() {
        _fleets = fleets;
        _selectedFleet = selected;
        _members = members;
        _inspections = inspections;
        _loading = false;
      });
    }
  }

  Future<void> _showCreateFleetDialog() async {
    final nameCtrl = TextEditingController();
    final createdName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Flota Pyme'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de la empresa / flota',
            hintText: 'Ej: Mensajería Express Bogotá',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (createdName == null || createdName.isEmpty) return;

    try {
      final fleet = await _service.createFleet(createdName);
      if (!mounted) return;
      setState(() => _selectedFleet = fleet);
      await _loadData();
      if (mounted) {
        AppSnackBar.show(context, 'Flota creada. Código: ${fleet.codigoInvitacion}');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, '$e');
    }
  }

  Future<void> _showJoinFleetDialog() async {
    final codeCtrl = TextEditingController();
    final aliasCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unirme a una Flota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código de invitación (6 caracteres)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: aliasCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del conductor',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vincular vehículo'),
          ),
        ],
      ),
    );
    final code = codeCtrl.text.trim();
    final alias = aliasCtrl.text.trim();
    codeCtrl.dispose();
    aliasCtrl.dispose();
    if (confirmed != true || code.isEmpty) return;

    try {
      final fleet = await _service.joinFleetByCode(
        code: code,
        vehiculoId: widget.vehiculoId,
        aliasConductor: alias,
        placa: widget.placa,
        marcaModelo: widget.marcaModelo,
        soatVencimiento: widget.soatVencimiento,
        tecnoVencimiento: widget.tecnoVencimiento,
      );
      if (!mounted) return;
      setState(() => _selectedFleet = fleet);
      await _loadData();
      if (mounted) {
        AppSnackBar.show(context, 'Vehículo vinculado a "${fleet.nombre}".');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Flota & Preoperacional PESV'),
        actions: [
          IconButton(
            tooltip: 'Preoperacional PESV',
            icon: const Icon(Icons.fact_check_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreoperationalCheckScreen(
                    vehiculoId: widget.vehiculoId,
                    placa: widget.placa,
                    marcaModelo: widget.marcaModelo,
                    isCar: widget.isCar,
                    flotaId: _selectedFleet?.id,
                  ),
                ),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showCreateFleetDialog,
                        icon: const Icon(Icons.add_business_rounded),
                        label: const Text('Crear Flota'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showJoinFleetDialog,
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('Unirme con Código'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreoperationalCheckScreen(
                          vehiculoId: widget.vehiculoId,
                          placa: widget.placa,
                          marcaModelo: widget.marcaModelo,
                          isCar: widget.isCar,
                          flotaId: _selectedFleet?.id,
                        ),
                      ),
                    );
                    _loadData();
                  },
                  icon: const Icon(Icons.checklist_rtl_rounded),
                  label: const Text('Llenar Preoperacional Diaria PESV (Res. 40595)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 18),
                if (_fleets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Aún no perteneces a una flota Pyme. Crea una flota para compartir código de invitación con tus conductores y auditar SOAT, Tecno y Preoperacionales PESV sin comprar hardware GPS.',
                      style: TextStyle(fontSize: 13.5, height: 1.45),
                    ),
                  )
                else ...[
                  DropdownButtonFormField<FleetModel>(
                    initialValue: _selectedFleet,
                    decoration: const InputDecoration(
                      labelText: 'Flota activa',
                      border: OutlineInputBorder(),
                    ),
                    items: _fleets
                        .map((f) => DropdownMenuItem(value: f, child: Text(f.nombre)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedFleet = val);
                      _loadData();
                    },
                  ),
                  if (_selectedFleet != null) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      tileColor: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(
                        'Código de invitación: ${_selectedFleet!.codigoInvitacion}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text('Compártelo con tus conductores'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _selectedFleet!.codigoInvitacion),
                          );
                          AppSnackBar.show(context, 'Código copiado.');
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vehículos Vinculados (${_members.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (_members.isEmpty)
                      const Text(
                        'Sin vehículos vinculados todavía. Usa "Unirme con Código" para agregar el vehículo actual.',
                      )
                    else
                      ..._members.map((m) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                              title: Text('${m.placaSnapshot} • ${m.marcaModeloSnapshot}'),
                              subtitle: Text(
                                '${m.aliasConductor} (${m.rol})\nSOAT: ${m.soatVencimiento ?? "Sin fecha"} • Tecno: ${m.tecnoVencimiento ?? "Sin fecha"}',
                              ),
                              isThreeLine: true,
                            ),
                          )),
                    const SizedBox(height: 16),
                    Text(
                      'Inspecciones PESV Recientes (${_inspections.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ..._inspections.take(10).map((ins) => ListTile(
                          leading: Icon(
                            ins.aprobada ? Icons.verified_rounded : Icons.warning_rounded,
                            color: ins.aprobada ? Colors.green : Colors.orange,
                          ),
                          title: Text(ins.aprobada ? 'Aprobada' : 'Con hallazgos'),
                          subtitle: Text(
                            ins.observaciones.isEmpty
                                ? ins.createdAt.toLocal().toString().substring(0, 16)
                                : ins.observaciones,
                          ),
                        )),
                  ],
                ],
              ],
            ),
    );
  }
}
