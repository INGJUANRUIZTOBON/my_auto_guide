import 'package:flutter/material.dart';
import '../../../../core/services/custom_maintenance_service.dart';
import '../../../../core/theme/brand_theme.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

class CustomMaintenancesCard extends StatefulWidget {
  final String vehiculoId;
  final double currentKms;
  final bool isCar;
  final BrandTheme brandTheme;

  const CustomMaintenancesCard({
    super.key,
    required this.vehiculoId,
    required this.currentKms,
    required this.isCar,
    required this.brandTheme,
  });

  @override
  State<CustomMaintenancesCard> createState() =>
      _CustomMaintenancesCardState();
}

class _CustomMaintenancesCardState extends State<CustomMaintenancesCard> {
  final _service = CustomMaintenanceService();
  List<CustomMaintenanceItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CustomMaintenancesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehiculoId != widget.vehiculoId) {
      _load();
    }
  }

  Future<void> _load() async {
    final rows = await _service.getItems(widget.vehiculoId);
    if (mounted) {
      setState(() {
        _items = rows;
        _loading = false;
      });
    }
  }

  Future<void> _openAddModal() async {
    final nameCtrl = TextEditingController();
    final diasCtrl = TextEditingController(text: '180');
    final kmsCtrl = TextEditingController(text: '10000');
    final presets = CustomMaintenanceService.presetsForVehicle(isCar: widget.isCar);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
                'Nuevo Mantenimiento Personalizado',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: presets.map((p) {
                  return ActionChip(
                    label: Text(p['nombre'].toString()),
                    onPressed: () {
                      nameCtrl.text = p['nombre'].toString();
                      diasCtrl.text = p['dias'].toString();
                      kmsCtrl.text = p['kms'].toString();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del mantenimiento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: diasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ciclo (días)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: kmsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ciclo (Km)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar mantenimiento'),
              ),
            ],
          ),
        ),
      ),
    );

    final nombre = nameCtrl.text.trim();
    final dias = int.tryParse(diasCtrl.text.trim()) ?? 180;
    final kms = int.tryParse(kmsCtrl.text.trim()) ?? 10000;
    nameCtrl.dispose();
    diasCtrl.dispose();
    kmsCtrl.dispose();

    if (ok != true || nombre.isEmpty) return;

    await _service.addItem(
      vehiculoId: widget.vehiculoId,
      nombre: nombre,
      cicloDias: dias.clamp(1, 3650),
      cicloKms: kms.clamp(100, 200000),
      currentKms: widget.currentKms,
    );
    await _load();
    if (mounted) {
      AppSnackBar.show(context, 'Agregado: $nombre');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Mantenimientos Personalizados',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: _openAddModal,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else if (_items.isEmpty)
            Text(
              widget.isCar
                  ? 'Agrega frenos, rotación de llantas, batería, refrigerante o correa de distribución.'
                  : 'Agrega pastillas de freno, llantas, bujía, líquido de frenos o batería.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            )
          else
            ..._items.map((item) {
              final pct = item.healthPercentage(widget.currentKms).clamp(0.0, 1.0);
              final color = pct > 0.5
                  ? Colors.green
                  : (pct > 0.25 ? Colors.orange : Colors.redAccent);
              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                        Text(
                          '${(pct * 100).round()}%',
                          style: TextStyle(fontWeight: FontWeight.w800, color: color),
                        ),
                        IconButton(
                          tooltip: 'Registrar realizado hoy',
                          icon: const Icon(Icons.check_circle_outline, size: 19),
                          onPressed: () async {
                            final messenger = context;
                            await _service.markDoneToday(
                              item,
                              widget.currentKms,
                            );
                            await _load();
                            if (!mounted || !messenger.mounted) return;
                            AppSnackBar.show(messenger, '${item.nombre} renovado al 100%.');
                          },
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline, size: 19),
                          onPressed: () async {
                            await _service.deleteItem(item);
                            await _load();
                          },
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cada ${item.cicloDias} días o ${item.cicloKms} Km • Último: ${item.ultimoKm.round()} Km',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
