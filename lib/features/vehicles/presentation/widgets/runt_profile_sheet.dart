import 'package:flutter/material.dart';
import '../../../../core/services/runt_parser.dart';

/// Hoja modal estilo Obsidiana Cockpit para mostrar la Ficha Técnica y Legal RUNTPRO del vehículo.
class RuntProfileSheet {
  const RuntProfileSheet._();

  static Future<void> show(
    BuildContext context, {
    required String placa,
    required RuntVehicleProfile? profile,
    required VoidCallback onUpdateFromRunt,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        const obsidian = Color(0xFF06080C);
        const surface = Color(0xFF121722);
        const cyan = Color(0xFF00E5FF);
        const cobalt = Color(0xFF2979FF);
        const emerald = Color(0xFF10B981);

        final p = profile;
        final hasData = p != null && p.hasAnyData;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: obsidian,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: cyan.withValues(alpha: 0.28), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: cyan.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Encabezado oficial MY AUTO GUIDE / RUNTPRO
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cyan.withValues(alpha: 0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FICHA OFICIAL RUNTPRO',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                              color: cyan,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasData && (p.marca.isNotEmpty || p.linea.isNotEmpty)
                                ? '${p.marca} ${p.linea}'.trim()
                                : 'Vehículo $placa',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (placa.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          placa.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (!hasData)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'Aún no has extraído la ficha técnica oficial desde el RUNT. '
                      'Toca el botón inferior, resuelve el CAPTCHA en el portal oficial y presiona "Extraer y Guardar Toda la Ficha RUNT".',
                      style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.45),
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tarjetas gemelas SOAT & Tecnomecánica
                          Row(
                            children: [
                              Expanded(
                                child: _LegalStatusCard(
                                  title: 'SOAT',
                                  icon: Icons.health_and_safety_rounded,
                                  estado: p.soatEstado.isNotEmpty ? p.soatEstado : 'REGISTRADO',
                                  vencimiento: p.effectiveSoatVencimiento,
                                  expedicion: p.effectiveSoatInicio,
                                  extra: p.soatAseguradora,
                                  accent: cyan,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _LegalStatusCard(
                                  title: 'TECNOMECÁNICA',
                                  icon: Icons.verified_rounded,
                                  estado: p.tecnoEstado.isNotEmpty
                                      ? p.tecnoEstado
                                      : (p.effectiveTecnoVencimiento.isNotEmpty ? 'REGISTRADA' : 'SIN DATO'),
                                  vencimiento: p.effectiveTecnoVencimiento,
                                  expedicion: p.effectiveTecnoInicio,
                                  extra: p.tecnoCda,
                                  accent: emerald,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Identificación y Especificaciones Técnicas
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'IDENTIDAD Y ESPECIFICACIONES',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                        color: cyan,
                                      ),
                                    ),
                                    if (p.estadoVehiculo.isNotEmpty)
                                      _StatusPill(
                                        label: p.estadoVehiculo,
                                        isPositive: p.estadoVehiculo.toUpperCase().contains('ACTIV'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _SpecRow(label: 'Año / Color', value: '${p.modeloAno} • ${p.color}'.replaceAll(RegExp(r'^•\s*|\s*•$'), '')),
                                _SpecRow(label: 'Clase / Servicio', value: '${p.clase} • ${p.servicio}'.replaceAll(RegExp(r'^•\s*|\s*•$'), '')),
                                _SpecRow(
                                  label: 'Cilindraje',
                                  value: p.cilindraje.isNotEmpty ? '${p.cilindraje} cc' : '',
                                  mono: true,
                                ),
                                _SpecRow(label: 'Combustible', value: p.combustible),
                                _SpecRow(label: 'VIN', value: p.vin, mono: true),
                                _SpecRow(label: 'N° Motor', value: p.numeroMotor, mono: true),
                                _SpecRow(label: 'N° Chasis', value: p.numeroChasis, mono: true),
                                _SpecRow(label: 'Póliza SOAT', value: p.soatPoliza, mono: true),
                                _SpecRow(label: 'Gravámenes / Prendas', value: p.gravamenes),
                                _SpecRow(label: 'Organismo Tránsito', value: p.organismoTransito),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [cyan, cobalt]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cobalt.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onUpdateFromRunt();
                    },
                    icon: const Icon(Icons.sync_rounded, color: Colors.white),
                    label: const Text(
                      'Actualizar desde RUNT Oficial',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LegalStatusCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String estado;
  final String vencimiento;
  final String expedicion;
  final String extra;
  final Color accent;

  const _LegalStatusCard({
    required this.title,
    required this.icon,
    required this.estado,
    required this.vencimiento,
    this.expedicion = '',
    required this.extra,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final up = estado.toUpperCase();
    final isBad = up.contains('VENCID') || up.contains('CANCEL') || up.contains('SIN DATO');
    final pillColor = isBad ? const Color(0xFFFF1744) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF121722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: accent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              estado.isNotEmpty ? estado : 'N/D',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: pillColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vencimiento.isNotEmpty ? 'Vence: $vencimiento' : 'Sin vencimiento',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (expedicion.isNotEmpty && expedicion != vencimiento) ...[
            const SizedBox(height: 2),
            Text(
              'Expedido: $expedicion',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white54,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
          if (extra.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              extra,
              style: const TextStyle(fontSize: 10.5, color: Colors.white60),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isPositive;

  const _StatusPill({required this.label, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final c = isPositive ? const Color(0xFF10B981) : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _SpecRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: mono ? 'monospace' : null,
                fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
