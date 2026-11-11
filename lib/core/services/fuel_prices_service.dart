import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FuelPriceReport {
  final String id;
  final String ciudad;
  final String estacion;
  final String tipoCombustible;
  final double precioGalon;
  final double latitud;
  final double longitud;
  final DateTime createdAt;

  const FuelPriceReport({
    required this.id,
    required this.ciudad,
    required this.estacion,
    required this.tipoCombustible,
    required this.precioGalon,
    required this.latitud,
    required this.longitud,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ciudad': ciudad,
        'estacion': estacion,
        'tipo_combustible': tipoCombustible,
        'precio_galon': precioGalon,
        'latitud': latitud,
        'longitud': longitud,
        'created_at': createdAt.toIso8601String(),
      };

  factory FuelPriceReport.fromMap(Map<String, dynamic> map) {
    return FuelPriceReport(
      id: map['id']?.toString() ?? '',
      ciudad: map['ciudad']?.toString() ?? 'Colombia',
      estacion: map['estacion']?.toString() ?? 'Estación',
      tipoCombustible: map['tipo_combustible']?.toString() ?? 'Corriente',
      precioGalon: (map['precio_galon'] as num?)?.toDouble() ?? 0.0,
      latitud: (map['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (map['longitud'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Servicio comunitario de precios de combustible en Colombia (offline-first + Supabase).
class FuelPricesService {
  static final FuelPricesService _instance = FuelPricesService._internal();
  factory FuelPricesService() => _instance;
  FuelPricesService._internal();

  static const String _cacheKey = 'colombia_fuel_prices_cache';

  static final List<FuelPriceReport> _referenceColombiaPrices = [
    FuelPriceReport(
      id: 'ref_1',
      ciudad: 'Bogotá',
      estacion: 'Terpel / Biomax Referencia',
      tipoCombustible: 'Corriente',
      precioGalon: 16250,
      latitud: 4.65,
      longitud: -74.08,
      createdAt: DateTime(2026, 11, 1),
    ),
    FuelPriceReport(
      id: 'ref_2',
      ciudad: 'Medellín',
      estacion: 'Primax / Texaco Referencia',
      tipoCombustible: 'Corriente',
      precioGalon: 16180,
      latitud: 6.24,
      longitud: -75.58,
      createdAt: DateTime(2026, 11, 1),
    ),
    FuelPriceReport(
      id: 'ref_3',
      ciudad: 'Cali',
      estacion: 'Esso / Mobil Referencia',
      tipoCombustible: 'Corriente',
      precioGalon: 16260,
      latitud: 3.45,
      longitud: -76.53,
      createdAt: DateTime(2026, 11, 1),
    ),
    FuelPriceReport(
      id: 'ref_4',
      ciudad: 'Colombia Nacional',
      estacion: 'Promedio Extra / ACPM',
      tipoCombustible: 'Extra',
      precioGalon: 21500,
      latitud: 4.60,
      longitud: -74.08,
      createdAt: DateTime(2026, 11, 1),
    ),
  ];

  Future<List<FuelPriceReport>> fetchPrices() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final rows = await Supabase.instance.client
          .from('fuel_station_prices')
          .select()
          .order('created_at', ascending: false)
          .limit(30);
      final list = (rows as List)
          .map((e) => FuelPriceReport.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      if (list.isNotEmpty) {
        await prefs.setString(
          _cacheKey,
          jsonEncode(list.map((e) => e.toJson()).toList()),
        );
        return list;
      }
    } catch (e) {
      debugPrint('[FUEL_PRICES] Usando caché/referencia local: $e');
    }

    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        final cached = decoded
            .map((e) => FuelPriceReport.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        if (cached.isNotEmpty) return cached;
      } catch (_) {}
    }

    return _referenceColombiaPrices;
  }

  Future<void> reportPrice({
    required String ciudad,
    required String estacion,
    required String tipoCombustible,
    required double precioGalon,
    required double latitud,
    required double longitud,
  }) async {
    var report = FuelPriceReport(
      id: 'fp_${DateTime.now().millisecondsSinceEpoch}',
      ciudad: ciudad.trim().isEmpty ? 'Colombia' : ciudad.trim(),
      estacion: estacion.trim(),
      tipoCombustible: tipoCombustible,
      precioGalon: precioGalon,
      latitud: latitud,
      longitud: longitud,
      createdAt: DateTime.now(),
    );

    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid != null) {
        final inserted = await client
            .from('fuel_station_prices')
            .insert({
              'user_id': uid,
              'ciudad': report.ciudad,
              'estacion': report.estacion,
              'tipo_combustible': report.tipoCombustible,
              'precio_galon': report.precioGalon,
              'latitud': latitud,
              'longitud': longitud,
            })
            .select()
            .single();
        report = FuelPriceReport.fromMap(inserted);
      }
    } catch (e) {
      debugPrint('[FUEL_PRICES] Guardado local: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchPrices();
    final updated = [report, ...existing.where((e) => !e.id.startsWith('ref_'))];
    await prefs.setString(
      _cacheKey,
      jsonEncode(updated.take(30).map((e) => e.toJson()).toList()),
    );
  }
}
