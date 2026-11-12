import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Modelo inmutable de Marca Automotriz en Colombia.
class CatalogBrand {
  final String id;
  final String nombre;
  final String tipo; // 'moto', 'carro', 'ambos'
  final String logoUrl;
  final String colorHex;
  final String paisOrigen;
  final int popularidad;

  const CatalogBrand({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.logoUrl,
    this.colorHex = '#00E5FF',
    this.paisOrigen = '',
    this.popularidad = 0,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFF00E5FF);
  }

  factory CatalogBrand.fromMap(Map<String, dynamic> map) {
    return CatalogBrand(
      id: (map['id'] ?? '').toString().toLowerCase().trim(),
      nombre: (map['nombre'] ?? '').toString().trim(),
      tipo: (map['tipo'] ?? 'moto').toString().toLowerCase().trim(),
      logoUrl: (map['logo_url'] ?? '').toString().trim(),
      colorHex: (map['color_hex'] ?? '#00E5FF').toString().trim(),
      paisOrigen: (map['pais_origen'] ?? '').toString().trim(),
      popularidad: (map['popularidad'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'logo_url': logoUrl,
        'color_hex': colorHex,
        'pais_origen': paisOrigen,
        'popularidad': popularidad,
      };
}

/// Modelo inmutable de Modelo Automotriz con Especificaciones Técnicas Colombia.
class CatalogModel {
  final String id;
  final String marcaId;
  final String tipo; // 'moto', 'carro'
  final String linea;
  final String modelo;
  final int anioInicio;
  final int? anioFin;
  final int cilindrajeCc;
  final String tipoCombustible;
  final double capacidadTanqueGal;
  final double potenciaHp;
  final String aceiteRecomendado;
  final String imagenUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic> specsAdicionales;

  const CatalogModel({
    required this.id,
    required this.marcaId,
    required this.tipo,
    required this.linea,
    required this.modelo,
    this.anioInicio = 2012,
    this.anioFin,
    this.cilindrajeCc = 0,
    this.tipoCombustible = 'Gasolina',
    this.capacidadTanqueGal = 3.0,
    this.potenciaHp = 0.0,
    this.aceiteRecomendado = '20W-50 Semisintético',
    required this.imagenUrl,
    this.thumbnailUrl,
    this.specsAdicionales = const {},
  });

  factory CatalogModel.fromMap(Map<String, dynamic> map) {
    return CatalogModel(
      id: (map['id'] ?? '').toString(),
      marcaId: (map['marca_id'] ?? '').toString().toLowerCase().trim(),
      tipo: (map['tipo'] ?? 'moto').toString().toLowerCase().trim(),
      linea: (map['linea'] ?? '').toString().trim(),
      modelo: (map['modelo'] ?? '').toString().trim(),
      anioInicio: (map['anio_inicio'] as num?)?.toInt() ?? 2012,
      anioFin: (map['anio_fin'] as num?)?.toInt(),
      cilindrajeCc: (map['cilindraje_cc'] as num?)?.toInt() ?? 0,
      tipoCombustible: (map['tipo_combustible'] ?? 'Gasolina').toString().trim(),
      capacidadTanqueGal: (map['capacidad_tanque_gal'] as num?)?.toDouble() ?? 3.0,
      potenciaHp: (map['potencia_hp'] as num?)?.toDouble() ?? 0.0,
      aceiteRecomendado: (map['aceite_recomendado'] ?? '20W-50 Semisintético').toString().trim(),
      imagenUrl: (map['imagen_url'] ?? '').toString().trim(),
      thumbnailUrl: map['thumbnail_url']?.toString().trim(),
      specsAdicionales: map['specs_adicionales'] is Map
          ? Map<String, dynamic>.from(map['specs_adicionales'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'marca_id': marcaId,
        'tipo': tipo,
        'linea': linea,
        'modelo': modelo,
        'anio_inicio': anioInicio,
        'anio_fin': anioFin,
        'cilindraje_cc': cilindrajeCc,
        'tipo_combustible': tipoCombustible,
        'capacidad_tanque_gal': capacidadTanqueGal,
        'potencia_hp': potenciaHp,
        'aceite_recomendado': aceiteRecomendado,
        'imagen_url': imagenUrl,
        'thumbnail_url': thumbnailUrl,
        'specs_adicionales': specsAdicionales,
      };
}

/// Servicio Singleton de Catálogo Cloud con Caché Offline-First para Colombia.
class CloudCatalogService {
  static final CloudCatalogService _instance = CloudCatalogService._internal();
  factory CloudCatalogService() => _instance;
  CloudCatalogService._internal();

  SupabaseClient? get _client {
    try {
      return SupabaseService().client;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene marcas ordenadas por popularidad en Colombia.
  Future<List<CatalogBrand>> getBrands({required bool isMoto}) async {
    final tipoBuscado = isMoto ? 'moto' : 'carro';
    final cacheKey = 'cloud_catalog_brands_$tipoBuscado';

    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('catalogo_marcas')
            .select('*')
            .or('tipo.eq.$tipoBuscado,tipo.eq.ambos')
            .eq('activo', true)
            .order('popularidad', ascending: false);

        final list = (res as List).map((m) => CatalogBrand.fromMap(m)).toList();
        if (list.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, jsonEncode(list.map((b) => b.toMap()).toList()));
          return list;
        }
      } catch (e) {
        debugPrint('[CATALOG_SERVICE] Aviso consultando marcas de Supabase: $e');
      }
    }

    // Fallback: Caché local
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRaw = prefs.getString(cacheKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final decoded = jsonDecode(cachedRaw) as List;
        return decoded.map((m) => CatalogBrand.fromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Fallback estático base si nunca ha conectado a internet
    return _getFallbackBrands(isMoto: isMoto);
  }

  /// Normaliza el identificador de marca para tolerar nombres comerciales
  static String normalizeMarcaId(String raw) {
    final clean = raw.toLowerCase().trim();
    if (clean.startsWith('akt')) return 'akt';
    if (clean.startsWith('hero')) return 'hero';
    if (clean.contains('royal')) return 'royal_enfield';
    if (clean.startsWith('victory') || clean.startsWith('victori')) return 'victory';
    if (clean.startsWith('bmw')) return 'bmw';
    return clean;
  }

  /// Obtiene modelos de una marca específica filtrados por tipo.
  Future<List<CatalogModel>> getModelsForBrand(String marcaId, {required bool isMoto}) async {
    final cleanMarca = normalizeMarcaId(marcaId);
    final tipo = isMoto ? 'moto' : 'carro';
    final cacheKey = 'cloud_catalog_models_${cleanMarca}_$tipo';

    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('catalogo_modelos')
            .select('*')
            .eq('marca_id', cleanMarca)
            .eq('tipo', tipo)
            .eq('activo', true)
            .order('popularidad', ascending: false);

        final list = (res as List).map((m) => CatalogModel.fromMap(m)).toList();
        if (list.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, jsonEncode(list.map((m) => m.toMap()).toList()));
          return list;
        }
      } catch (e) {
        debugPrint('[CATALOG_SERVICE] Aviso consultando modelos de Supabase: $e');
      }
    }

    // Fallback: Caché local
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRaw = prefs.getString(cacheKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final decoded = jsonDecode(cachedRaw) as List;
        return decoded.map((m) => CatalogModel.fromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Búsqueda predictiva de vehículos (por línea o modelo).
  Future<List<CatalogModel>> searchCatalog(String query, {bool? isMoto}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final client = _client;
    if (client == null) return [];

    try {
      var queryBuilder = client
          .from('catalogo_modelos')
          .select('*')
          .eq('activo', true)
          .or('modelo.ilike.%$q%,linea.ilike.%$q%');

      if (isMoto != null) {
        queryBuilder = queryBuilder.eq('tipo', isMoto ? 'moto' : 'carro');
      }

      final res = await queryBuilder.limit(20);
      return (res as List).map((m) => CatalogModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('[CATALOG_SERVICE] Error buscando modelos: $e');
      return [];
    }
  }

  List<CatalogBrand> _getFallbackBrands({required bool isMoto}) {
    if (isMoto) {
      return const [
        CatalogBrand(id: 'bajaj', nombre: 'Bajaj', tipo: 'moto', logoUrl: 'assets/logos/bajaj_logo.png', colorHex: '#0047BA', popularidad: 100),
        CatalogBrand(id: 'yamaha', nombre: 'Yamaha', tipo: 'moto', logoUrl: 'assets/logos/yamaha_logo.png', colorHex: '#D31145', popularidad: 95),
        CatalogBrand(id: 'akt', nombre: 'AKT Motos', tipo: 'moto', logoUrl: 'assets/logos/akt_logo.png', colorHex: '#E31E24', popularidad: 92),
        CatalogBrand(id: 'suzuki', nombre: 'Suzuki', tipo: 'ambos', logoUrl: 'assets/logos/suzuki_logo.png', colorHex: '#E30613', popularidad: 90),
        CatalogBrand(id: 'honda', nombre: 'Honda', tipo: 'ambos', logoUrl: 'assets/logos/honda_logo.png', colorHex: '#CC0000', popularidad: 88),
      ];
    } else {
      return const [
        CatalogBrand(id: 'renault', nombre: 'Renault', tipo: 'carro', logoUrl: 'assets/logos/renault_logo.png', colorHex: '#FFCC00', popularidad: 100),
        CatalogBrand(id: 'chevrolet', nombre: 'Chevrolet', tipo: 'carro', logoUrl: 'assets/logos/chevrolet_logo.png', colorHex: '#CD9834', popularidad: 98),
        CatalogBrand(id: 'toyota', nombre: 'Toyota', tipo: 'carro', logoUrl: 'assets/logos/toyota_logo.png', colorHex: '#EB0A1E', popularidad: 95),
        CatalogBrand(id: 'mazda', nombre: 'Mazda', tipo: 'carro', logoUrl: 'assets/logos/mazda_logo.png', colorHex: '#1B365D', popularidad: 92),
        CatalogBrand(id: 'kia', nombre: 'Kia', tipo: 'carro', logoUrl: 'assets/logos/kia_logo.png', colorHex: '#05141F', popularidad: 88),
      ];
    }
  }
}
