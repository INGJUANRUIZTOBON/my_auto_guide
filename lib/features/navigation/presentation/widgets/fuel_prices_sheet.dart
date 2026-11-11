import 'package:flutter/material.dart';
import '../../../../core/services/fuel_prices_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// Hoja modal para consultar precios de gasolina en Colombia y reportar estaciones.
class FuelPricesSheet extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final String currentCity;

  const FuelPricesSheet({
    super.key,
    required this.currentLat,
    required this.currentLng,
    required this.currentCity,
  });

  static Future<void> show(
    BuildContext context, {
    required double lat,
    required double lng,
    required String city,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FuelPricesSheet(
        currentLat: lat,
        currentLng: lng,
        currentCity: city,
      ),
    );
  }

  @override
  State<FuelPricesSheet> createState() => _FuelPricesSheetState();
}

class _FuelPricesSheetState extends State<FuelPricesSheet> {
  final _stationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _fuelType = 'Corriente';
  List<FuelPriceReport> _prices = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _stationCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await FuelPricesService().fetchPrices();
    if (mounted) {
      setState(() {
        _prices = list;
        _loading = false;
      });
    }
  }

  Future<void> _submitPrice() async {
    final station = _stationCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0;
    if (station.isEmpty || price < 5000) {
      AppSnackBar.show(context, 'Ingresa estación y un precio válido por galón (COP).');
      return;
    }

    setState(() => _submitting = true);
    await FuelPricesService().reportPrice(
      ciudad: widget.currentCity,
      estacion: station,
      tipoCombustible: _fuelType,
      precioGalon: price,
      latitud: widget.currentLat,
      longitud: widget.currentLng,
    );
    _stationCtrl.clear();
    _priceCtrl.clear();
    await _load();
    if (mounted) {
      setState(() => _submitting = false);
      AppSnackBar.show(
        context,
        'Precio de $_fuelType reportado a la comunidad',
        backgroundColor: const Color(0xFF059669),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, inset + 20),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.local_gas_station_rounded, color: Color(0xFF38BDF8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Precios de Gasolina • ${widget.currentCity}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _stationCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ej: Terpel Autopista',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '16250',
                      prefixText: '\$ ',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final t in const ['Corriente', 'Extra', 'ACPM'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      selected: _fuelType == t,
                      onSelected: (_) => setState(() => _fuelType = t),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _submitting ? null : _submitPrice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reportar'),
                ),
              ],
            ),
            const Divider(height: 22),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _prices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = _prices[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.estacion,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${item.tipoCombustible} • ${item.ciudad}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.precioGalon.toStringAsFixed(0)} /gal',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00FF87),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
