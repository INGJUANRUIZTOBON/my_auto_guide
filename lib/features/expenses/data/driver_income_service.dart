import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverIncomeEntry {
  final String id;
  final String vehiculoId;
  final String plataforma;
  final double montoBruto;
  final double peajes;
  final double otrosGastos;
  final double kmsTurno;
  final String notas;
  final DateTime fecha;

  const DriverIncomeEntry({
    required this.id,
    required this.vehiculoId,
    required this.plataforma,
    required this.montoBruto,
    required this.peajes,
    required this.otrosGastos,
    required this.kmsTurno,
    required this.notas,
    required this.fecha,
  });

  double get netProfit => montoBruto - peajes - otrosGastos;

  double get copPerKm => kmsTurno > 0 ? netProfit / kmsTurno : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehiculo_id': vehiculoId,
        'plataforma': plataforma,
        'monto_bruto': montoBruto,
        'peajes': peajes,
        'otros_gastos': otrosGastos,
        'kms_turno': kmsTurno,
        'notas': notas,
        'fecha': fecha.toIso8601String(),
      };

  factory DriverIncomeEntry.fromMap(Map<String, dynamic> map) {
    return DriverIncomeEntry(
      id: map['id']?.toString() ?? '',
      vehiculoId: map['vehiculo_id']?.toString() ?? '',
      plataforma: map['plataforma']?.toString() ?? 'Particular / App',
      montoBruto: (map['monto_bruto'] as num?)?.toDouble() ?? 0.0,
      peajes: (map['peajes'] as num?)?.toDouble() ?? 0.0,
      otrosGastos: (map['otros_gastos'] as num?)?.toDouble() ?? 0.0,
      kmsTurno: (map['kms_turno'] as num?)?.toDouble() ?? 0.0,
      notas: map['notas']?.toString() ?? '',
      fecha: map['fecha'] != null
          ? (DateTime.tryParse(map['fecha'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class DriverProfitabilitySummary {
  final double totalBruto;
  final double totalGastosTurno;
  final double totalGastosVehiculoPeriodo;
  final double totalNeto;
  final double totalKms;
  final double promedioCopPorKm;
  final int totalTurnos;

  const DriverProfitabilitySummary({
    required this.totalBruto,
    required this.totalGastosTurno,
    required this.totalGastosVehiculoPeriodo,
    required this.totalNeto,
    required this.totalKms,
    required this.promedioCopPorKm,
    required this.totalTurnos,
  });
}

/// Servicio offline-first para Modo Conductor (Uber, DiDi, InDrive, Rappi, Mensajería, Fletes).
class DriverIncomeService {
  static final DriverIncomeService _instance = DriverIncomeService._internal();
  factory DriverIncomeService() => _instance;
  DriverIncomeService._internal();

  static const List<String> platformsColombia = [
    'Uber / Comfort',
    'DiDi / Express',
    'inDrive',
    'Yango / Cabify',
    'Rappi / Mensajería',
    'Picap Moto',
    'Fletes / Carga',
    'Servicio Particular',
  ];

  static String _cacheKey(String vehiculoId) => 'driver_incomes_$vehiculoId';

  static DriverProfitabilitySummary computeSummary(
    List<DriverIncomeEntry> entries, {
    double externalExpenses = 0.0,
  }) {
    double bruto = 0;
    double gastosTurno = 0;
    double kms = 0;
    for (final e in entries) {
      bruto += e.montoBruto;
      gastosTurno += e.peajes + e.otrosGastos;
      kms += e.kmsTurno;
    }
    final neto = bruto - gastosTurno - externalExpenses;
    final copKm = kms > 0 ? neto / kms : 0.0;
    return DriverProfitabilitySummary(
      totalBruto: bruto,
      totalGastosTurno: gastosTurno,
      totalGastosVehiculoPeriodo: externalExpenses,
      totalNeto: neto,
      totalKms: kms,
      promedioCopPorKm: copKm,
      totalTurnos: entries.length,
    );
  }

  Future<List<DriverIncomeEntry>> getEntries(String vehiculoId) async {
    final prefs = await SharedPreferences.getInstance();
    List<DriverIncomeEntry> cached = _decodeList(prefs.getString(_cacheKey(vehiculoId)));

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final rows = await client
            .from('driver_incomes')
            .select()
            .eq('vehiculo_id', vehiculoId)
            .eq('user_id', user.id)
            .order('fecha', ascending: false);

        final remote = (rows as List)
            .whereType<Map<String, dynamic>>()
            .map(DriverIncomeEntry.fromMap)
            .toList();
        await _saveCache(vehiculoId, remote);
        return remote;
      }
    } catch (e) {
      debugPrint('[DRIVER_INCOME] Offline / fallback a caché: $e');
    }
    return cached;
  }

  Future<DriverIncomeEntry> addEntry({
    required String vehiculoId,
    required String plataforma,
    required double montoBruto,
    required double peajes,
    required double otrosGastos,
    required double kmsTurno,
    String notas = '',
    DateTime? fecha,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = _decodeList(prefs.getString(_cacheKey(vehiculoId)));
    final now = fecha ?? DateTime.now();

    var created = DriverIncomeEntry(
      id: 'local_${now.millisecondsSinceEpoch}',
      vehiculoId: vehiculoId,
      plataforma: plataforma,
      montoBruto: montoBruto,
      peajes: peajes,
      otrosGastos: otrosGastos,
      kmsTurno: kmsTurno,
      notas: notas.trim(),
      fecha: now,
    );

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final inserted = await client
            .from('driver_incomes')
            .insert({
              'user_id': user.id,
              'vehiculo_id': vehiculoId,
              'plataforma': plataforma,
              'monto_bruto': montoBruto,
              'peajes': peajes,
              'otros_gastos': otrosGastos,
              'kms_turno': kmsTurno,
              'notas': notas.trim(),
              'fecha': now.toIso8601String(),
            })
            .select()
            .single();
        created = DriverIncomeEntry.fromMap(inserted);
      }
    } catch (e) {
      debugPrint('[DRIVER_INCOME] Guardado local (offline): $e');
    }

    final updated = [created, ...current];
    await _saveCache(vehiculoId, updated);
    return created;
  }

  Future<void> deleteEntry({
    required String vehiculoId,
    required String entryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = _decodeList(prefs.getString(_cacheKey(vehiculoId)));
    final filtered = current.where((e) => e.id != entryId).toList();
    await _saveCache(vehiculoId, filtered);

    if (entryId.startsWith('local_')) return;
    try {
      final client = Supabase.instance.client;
      await client.from('driver_incomes').delete().eq('id', entryId);
    } catch (e) {
      debugPrint('[DRIVER_INCOME] Error borrando remoto: $e');
    }
  }

  List<DriverIncomeEntry> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => DriverIncomeEntry.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveCache(String vehiculoId, List<DriverIncomeEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey(vehiculoId),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
