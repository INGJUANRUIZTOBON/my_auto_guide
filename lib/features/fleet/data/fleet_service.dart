import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FleetModel {
  final String id;
  final String ownerId;
  final String nombre;
  final String codigoInvitacion;
  final DateTime createdAt;

  const FleetModel({
    required this.id,
    required this.ownerId,
    required this.nombre,
    required this.codigoInvitacion,
    required this.createdAt,
  });

  factory FleetModel.fromMap(Map<String, dynamic> map) {
    return FleetModel(
      id: map['id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Mi Flota',
      codigoInvitacion: map['codigo_invitacion']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class FleetMemberModel {
  final String id;
  final String flotaId;
  final String userId;
  final String? vehiculoId;
  final String rol;
  final String aliasConductor;
  final String placaSnapshot;
  final String marcaModeloSnapshot;
  final String? soatVencimiento;
  final String? tecnoVencimiento;

  const FleetMemberModel({
    required this.id,
    required this.flotaId,
    required this.userId,
    this.vehiculoId,
    required this.rol,
    required this.aliasConductor,
    required this.placaSnapshot,
    required this.marcaModeloSnapshot,
    this.soatVencimiento,
    this.tecnoVencimiento,
  });

  factory FleetMemberModel.fromMap(Map<String, dynamic> map) {
    return FleetMemberModel(
      id: map['id']?.toString() ?? '',
      flotaId: map['flota_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      vehiculoId: map['vehiculo_id']?.toString(),
      rol: map['rol']?.toString() ?? 'conductor',
      aliasConductor: map['alias_conductor']?.toString() ?? 'Conductor',
      placaSnapshot: map['placa_snapshot']?.toString() ?? '',
      marcaModeloSnapshot: map['marca_modelo_snapshot']?.toString() ?? '',
      soatVencimiento: map['soat_vencimiento']?.toString(),
      tecnoVencimiento: map['tecno_vencimiento']?.toString(),
    );
  }
}

class PreoperationalInspection {
  final String id;
  final String? flotaId;
  final String vehiculoId;
  final bool aprobada;
  final Map<String, bool> items;
  final String observaciones;
  final DateTime createdAt;

  const PreoperationalInspection({
    required this.id,
    this.flotaId,
    required this.vehiculoId,
    required this.aprobada,
    required this.items,
    required this.observaciones,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'flota_id': flotaId,
        'vehiculo_id': vehiculoId,
        'aprobada': aprobada,
        'items_json': items,
        'observaciones': observaciones,
        'created_at': createdAt.toIso8601String(),
      };

  factory PreoperationalInspection.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items_json'];
    final parsedItems = <String, bool>{};
    if (rawItems is Map) {
      for (final e in rawItems.entries) {
        parsedItems[e.key.toString()] = e.value == true;
      }
    }
    return PreoperationalInspection(
      id: map['id']?.toString() ?? '',
      flotaId: map['flota_id']?.toString(),
      vehiculoId: map['vehiculo_id']?.toString() ?? '',
      aprobada: map['aprobada'] != false,
      items: parsedItems,
      observaciones: map['observaciones']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Servicio para Flotas Pymes Colombia y Preoperacional diaria PESV (Res. 40595 de 2022).
class FleetService {
  static final FleetService _instance = FleetService._internal();
  factory FleetService() => _instance;
  FleetService._internal();

  static const List<String> pesvItemsCar = [
    'Frenos (servicio y parqueo)',
    'Llantas (labrado y presión)',
    'Luces, direccionales y stop',
    'Niveles (aceite, refrigerante, frenos)',
    'Espejos, limpiabrisas y pito',
    'Kit de carretera y extintor vigente',
    'Cinturones de seguridad y documentos',
  ];

  static const List<String> pesvItemsMoto = [
    'Freno delantero y trasero',
    'Llantas (labrado y presión)',
    'Cadena / Kit de arrastre y tensión',
    'Faro, stop, direccionales y pito',
    'Espejos y fugas visibles de aceite',
    'Casco certificado y chaleco reflectivo',
    'SOAT, Tecnomecánica y Licencia vigentes',
  ];

  static String _inspectionsCacheKey(String vehiculoId) => 'pesv_inspections_$vehiculoId';

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<List<FleetModel>> getMyFleets() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return const [];

      final owned = await client
          .from('flotas')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      final memberRows = await client
          .from('flota_miembros')
          .select('flota_id')
          .eq('user_id', user.id);

      final ids = <String>{};
      final result = <FleetModel>[];
      for (final row in (owned as List).whereType<Map<String, dynamic>>()) {
        final f = FleetModel.fromMap(row);
        if (ids.add(f.id)) result.add(f);
      }

      final joinedIds = (memberRows as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => m['flota_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty && !ids.contains(id))
          .toList();

      if (joinedIds.isNotEmpty) {
        final joined = await client.from('flotas').select().inFilter('id', joinedIds);
        for (final row in (joined as List).whereType<Map<String, dynamic>>()) {
          final f = FleetModel.fromMap(row);
          if (ids.add(f.id)) result.add(f);
        }
      }
      return result;
    } catch (e) {
      debugPrint('[FLEET] Error cargando flotas: $e');
      return const [];
    }
  }

  Future<FleetModel> createFleet(String nombre) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para crear una flota.');
    }
    final code = _generateInviteCode();
    final inserted = await client
        .from('flotas')
        .insert({
          'owner_id': user.id,
          'nombre': nombre.trim(),
          'codigo_invitacion': code,
        })
        .select()
        .single();
    return FleetModel.fromMap(inserted);
  }

  Future<FleetModel> joinFleetByCode({
    required String code,
    required String vehiculoId,
    required String aliasConductor,
    required String placa,
    required String marcaModelo,
    String? soatVencimiento,
    String? tecnoVencimiento,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para unirte a una flota.');
    }
    final normalizedCode = code.trim().toUpperCase();
    final fleetRow = await client
        .from('flotas')
        .select()
        .eq('codigo_invitacion', normalizedCode)
        .maybeSingle();

    if (fleetRow == null) {
      throw Exception('Código de flota "$normalizedCode" no encontrado.');
    }
    final fleet = FleetModel.fromMap(fleetRow);

    final existing = await client
        .from('flota_miembros')
        .select('id')
        .eq('flota_id', fleet.id)
        .eq('user_id', user.id)
        .eq('vehiculo_id', vehiculoId)
        .maybeSingle();

    if (existing == null) {
      await client.from('flota_miembros').insert({
        'flota_id': fleet.id,
        'user_id': user.id,
        'vehiculo_id': vehiculoId,
        'rol': fleet.ownerId == user.id ? 'admin' : 'conductor',
        'alias_conductor': aliasConductor.trim().isEmpty ? 'Conductor' : aliasConductor.trim(),
        'placa_snapshot': placa.toUpperCase(),
        'marca_modelo_snapshot': marcaModelo,
        'soat_vencimiento': soatVencimiento,
        'tecno_vencimiento': tecnoVencimiento,
      });
    }
    return fleet;
  }

  Future<List<FleetMemberModel>> getMembers(String flotaId) async {
    try {
      final rows = await Supabase.instance.client
          .from('flota_miembros')
          .select()
          .eq('flota_id', flotaId)
          .order('created_at', ascending: false);
      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(FleetMemberModel.fromMap)
          .toList();
    } catch (e) {
      debugPrint('[FLEET] Error cargando miembros: $e');
      return const [];
    }
  }

  Future<List<PreoperationalInspection>> getRecentInspections({
    required String vehiculoId,
    String? flotaId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final local = _decodeInspections(prefs.getString(_inspectionsCacheKey(vehiculoId)));

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) return local;

      final query = client.from('inspecciones_preoperacionales').select();
      final rows = flotaId != null && flotaId.isNotEmpty
          ? await query.eq('flota_id', flotaId).order('created_at', ascending: false).limit(30)
          : await query.eq('vehiculo_id', vehiculoId).order('created_at', ascending: false).limit(20);

      final remote = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(PreoperationalInspection.fromMap)
          .toList();
      if (flotaId == null) {
        await prefs.setString(
          _inspectionsCacheKey(vehiculoId),
          jsonEncode(remote.map((e) => e.toJson()).toList()),
        );
      }
      return remote;
    } catch (e) {
      debugPrint('[PESV] Fallback local inspecciones: $e');
      return local;
    }
  }

  Future<PreoperationalInspection> savePreoperational({
    String? flotaId,
    required String vehiculoId,
    required Map<String, bool> items,
    required String observaciones,
  }) async {
    final aprobada = items.values.every((v) => v == true);
    final now = DateTime.now();
    var created = PreoperationalInspection(
      id: 'local_${now.millisecondsSinceEpoch}',
      flotaId: flotaId,
      vehiculoId: vehiculoId,
      aprobada: aprobada,
      items: Map<String, bool>.from(items),
      observaciones: observaciones.trim(),
      createdAt: now,
    );

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final inserted = await client
            .from('inspecciones_preoperacionales')
            .insert({
              if (flotaId != null && flotaId.isNotEmpty) 'flota_id': flotaId,
              'vehiculo_id': vehiculoId,
              'user_id': user.id,
              'aprobada': aprobada,
              'items_json': items,
              'observaciones': observaciones.trim(),
            })
            .select()
            .single();
        created = PreoperationalInspection.fromMap(inserted);
      }
    } catch (e) {
      debugPrint('[PESV] Guardado local (offline): $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final current = _decodeInspections(prefs.getString(_inspectionsCacheKey(vehiculoId)));
    final updated = [created, ...current].take(20).toList();
    await prefs.setString(
      _inspectionsCacheKey(vehiculoId),
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    return created;
  }

  List<PreoperationalInspection> _decodeInspections(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => PreoperationalInspection.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
