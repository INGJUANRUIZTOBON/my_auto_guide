import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../logic/vehicle_health_logic.dart';

class CustomMaintenanceItem {
  final String id;
  final String vehiculoId;
  final String nombre;
  final int cicloDias;
  final int cicloKms;
  final DateTime ultimaFecha;
  final double ultimoKm;

  const CustomMaintenanceItem({
    required this.id,
    required this.vehiculoId,
    required this.nombre,
    required this.cicloDias,
    required this.cicloKms,
    required this.ultimaFecha,
    required this.ultimoKm,
  });

  double healthPercentage(double currentKms) {
    return VehicleHealthLogic.calculateHybridPercentage(
      lastDate: ultimaFecha,
      lastKms: ultimoKm,
      cycleDays: cicloDias,
      cycleKms: cicloKms,
      currentKms: currentKms,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehiculo_id': vehiculoId,
        'nombre': nombre,
        'ciclo_dias': cicloDias,
        'ciclo_kms': cicloKms,
        'ultima_fecha': ultimaFecha.toIso8601String(),
        'ultimo_km': ultimoKm,
      };

  factory CustomMaintenanceItem.fromMap(Map<String, dynamic> map) {
    return CustomMaintenanceItem(
      id: map['id']?.toString() ?? '',
      vehiculoId: map['vehiculo_id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Mantenimiento',
      cicloDias: (map['ciclo_dias'] as num?)?.toInt() ?? 180,
      cicloKms: (map['ciclo_kms'] as num?)?.toInt() ?? 10000,
      ultimaFecha: map['ultima_fecha'] != null
          ? (DateTime.tryParse(map['ultima_fecha'].toString()) ?? DateTime.now())
          : DateTime.now(),
      ultimoKm: (map['ultimo_km'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Gestión offline-first de mantenimientos adicionales / personalizados (Llantas, Frenos, Batería, etc.).
class CustomMaintenanceService {
  static final CustomMaintenanceService _instance = CustomMaintenanceService._internal();
  factory CustomMaintenanceService() => _instance;
  CustomMaintenanceService._internal();

  static String _cacheKey(String vehiculoId) => 'custom_maintenances_$vehiculoId';

  /// Sugerencias predeterminadas reales según sea Carro o Moto.
  static List<Map<String, dynamic>> presetsForVehicle({required bool isCar}) {
    if (isCar) {
      return const [
        {'nombre': 'Pastillas de Freno', 'dias': 365, 'kms': 20000},
        {'nombre': 'Rotación / Alineación Llantas', 'dias': 180, 'kms': 10000},
        {'nombre': 'Batería 12V', 'dias': 730, 'kms': 40000},
        {'nombre': 'Refrigerante Motor', 'dias': 365, 'kms': 20000},
        {'nombre': 'Correa de Repartición', 'dias': 1095, 'kms': 50000},
      ];
    }
    return const [
      {'nombre': 'Pastillas / Bandas Freno', 'dias': 180, 'kms': 8000},
      {'nombre': 'Llantas (Delantera/Trasera)', 'dias': 365, 'kms': 15000},
      {'nombre': 'Bujía y Calibración Válvulas', 'dias': 180, 'kms': 6000},
      {'nombre': 'Líquido de Frenos', 'dias': 365, 'kms': 12000},
    ];
  }

  Future<List<CustomMaintenanceItem>> getItems(String vehiculoId) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        final rows = await client
            .from('custom_maintenances')
            .select()
            .eq('vehiculo_id', vehiculoId)
            .order('created_at', ascending: true);
        final list = (rows as List)
            .map((e) => CustomMaintenanceItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        await prefs.setString(
          _cacheKey(vehiculoId),
          jsonEncode(list.map((e) => e.toJson()).toList()),
        );
        return list;
      }
    } catch (e) {
      debugPrint('[CUSTOM_MAINT] Usando caché local offline: $e');
    }

    final raw = prefs.getString(_cacheKey(vehiculoId));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => CustomMaintenanceItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addItem({
    required String vehiculoId,
    required String nombre,
    required int cicloDias,
    required int cicloKms,
    required double currentKms,
  }) async {
    final localId = 'cm_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    var item = CustomMaintenanceItem(
      id: localId,
      vehiculoId: vehiculoId,
      nombre: nombre.trim(),
      cicloDias: cicloDias,
      cicloKms: cicloKms,
      ultimaFecha: now,
      ultimoKm: currentKms,
    );

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        final inserted = await client
            .from('custom_maintenances')
            .insert({
              'user_id': userId,
              'vehiculo_id': vehiculoId,
              'nombre': item.nombre,
              'ciclo_dias': cicloDias,
              'ciclo_kms': cicloKms,
              'ultima_fecha': now.toIso8601String(),
              'ultimo_km': currentKms,
            })
            .select()
            .single();
        item = CustomMaintenanceItem.fromMap(inserted);
      }
    } catch (e) {
      debugPrint('[CUSTOM_MAINT] Guardado solo local: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await getLocalOnly(vehiculoId);
    current.add(item);
    await prefs.setString(
      _cacheKey(vehiculoId),
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> markDoneToday(CustomMaintenanceItem item, double currentKms) async {
    final now = DateTime.now();
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null && !item.id.startsWith('cm_')) {
        await client
            .from('custom_maintenances')
            .update({
              'ultima_fecha': now.toIso8601String(),
              'ultimo_km': currentKms,
            })
            .eq('id', item.id);
      }
    } catch (e) {
      debugPrint('[CUSTOM_MAINT] Reset local: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await getLocalOnly(item.vehiculoId);
    final updated = current
        .map((e) => e.id == item.id
            ? CustomMaintenanceItem(
                id: e.id,
                vehiculoId: e.vehiculoId,
                nombre: e.nombre,
                cicloDias: e.cicloDias,
                cicloKms: e.cicloKms,
                ultimaFecha: now,
                ultimoKm: currentKms,
              )
            : e)
        .toList();
    await prefs.setString(
      _cacheKey(item.vehiculoId),
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteItem(CustomMaintenanceItem item) async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null && !item.id.startsWith('cm_')) {
        await client.from('custom_maintenances').delete().eq('id', item.id);
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final current = await getLocalOnly(item.vehiculoId);
    current.removeWhere((e) => e.id == item.id);
    await prefs.setString(
      _cacheKey(item.vehiculoId),
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<CustomMaintenanceItem>> getLocalOnly(String vehiculoId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(vehiculoId));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => CustomMaintenanceItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
