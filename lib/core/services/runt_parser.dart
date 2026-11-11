import 'dart:convert';

/// Modelo estructurado con la ficha técnica y legal completa extraída del RUNT oficial.
class RuntVehicleProfile {
  final String marca;
  final String linea;
  final String modeloAno;
  final String color;
  final String clase;
  final String servicio;
  final String estadoVehiculo;
  final String cilindraje;
  final String combustible;
  final String vin;
  final String numeroMotor;
  final String numeroChasis;
  final String gravamenes;
  final String organismoTransito;

  final String soatEstado;
  final String soatAseguradora;
  final String soatPoliza;
  final String soatExpedicion;
  final String soatVencimiento;

  final String tecnoEstado;
  final String tecnoCertificado;
  final String tecnoCda;
  final String tecnoExpedicion;
  final String tecnoVencimiento;

  final DateTime? updatedAt;

  const RuntVehicleProfile({
    this.marca = '',
    this.linea = '',
    this.modeloAno = '',
    this.color = '',
    this.clase = '',
    this.servicio = '',
    this.estadoVehiculo = '',
    this.cilindraje = '',
    this.combustible = '',
    this.vin = '',
    this.numeroMotor = '',
    this.numeroChasis = '',
    this.gravamenes = '',
    this.organismoTransito = '',
    this.soatEstado = '',
    this.soatAseguradora = '',
    this.soatPoliza = '',
    this.soatExpedicion = '',
    this.soatVencimiento = '',
    this.tecnoEstado = '',
    this.tecnoCertificado = '',
    this.tecnoCda = '',
    this.tecnoExpedicion = '',
    this.tecnoVencimiento = '',
    this.updatedAt,
  });

  bool get hasAnyData =>
      soatVencimiento.isNotEmpty ||
      tecnoVencimiento.isNotEmpty ||
      marca.isNotEmpty ||
      linea.isNotEmpty ||
      vin.isNotEmpty ||
      numeroMotor.isNotEmpty ||
      cilindraje.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'marca': marca,
        'linea': linea,
        'modelo_ano': modeloAno,
        'color': color,
        'clase': clase,
        'servicio': servicio,
        'estado_vehiculo': estadoVehiculo,
        'cilindraje': cilindraje,
        'combustible': combustible,
        'vin': vin,
        'numero_motor': numeroMotor,
        'numero_chasis': numeroChasis,
        'gravamenes': gravamenes,
        'organismo_transito': organismoTransito,
        'soat_estado': soatEstado,
        'soat_aseguradora': soatAseguradora,
        'soat_poliza': soatPoliza,
        'soat_expedicion': soatExpedicion,
        'soat_vencimiento': soatVencimiento,
        'tecno_estado': tecnoEstado,
        'tecno_certificado': tecnoCertificado,
        'tecno_cda': tecnoCda,
        'tecno_expedicion': tecnoExpedicion,
        'tecno_vencimiento': tecnoVencimiento,
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  factory RuntVehicleProfile.fromMap(Map<String, dynamic> map) {
    String clean(String key) => (map[key]?.toString() ?? '').trim();
    return RuntVehicleProfile(
      marca: clean('marca'),
      linea: clean('linea'),
      modeloAno: clean('modelo_ano'),
      color: clean('color'),
      clase: clean('clase'),
      servicio: clean('servicio'),
      estadoVehiculo: clean('estado_vehiculo'),
      cilindraje: clean('cilindraje'),
      combustible: clean('combustible'),
      vin: clean('vin'),
      numeroMotor: clean('numero_motor'),
      numeroChasis: clean('numero_chasis'),
      gravamenes: clean('gravamenes'),
      organismoTransito: clean('organismo_transito'),
      soatEstado: clean('soat_estado'),
      soatAseguradora: clean('soat_aseguradora'),
      soatPoliza: clean('soat_poliza'),
      soatExpedicion: clean('soat_expedicion'),
      soatVencimiento: clean('soat_vencimiento'),
      tecnoEstado: clean('tecno_estado'),
      tecnoCertificado: clean('tecno_certificado'),
      tecnoCda: clean('tecno_cda'),
      tecnoExpedicion: clean('tecno_expedicion'),
      tecnoVencimiento: clean('tecno_vencimiento'),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Decodifica el resultado crudo devuelto por WebView (`runJavaScriptReturningResult`),
  /// tolerando doble serialización JSON propia de Android WebView.
  static RuntVehicleProfile? tryDecodeWebViewResult(Object? rawResult) {
    if (rawResult == null) return null;
    try {
      dynamic decoded = rawResult is String ? jsonDecode(rawResult) : rawResult;
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is Map) {
        return RuntVehicleProfile.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  /// Convierte fechas DD/MM/AAAA o YYYY-MM-DD a ISO `YYYY-MM-DD` para Supabase.
  static String? convertToIsoDate(String rawDate) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return null;

    final dmyMatch = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})').firstMatch(trimmed);
    if (dmyMatch != null) {
      final day = dmyMatch.group(1)!.padLeft(2, '0');
      final month = dmyMatch.group(2)!.padLeft(2, '0');
      final year = dmyMatch.group(3)!;
      return '$year-$month-$day';
    }

    final isoMatch = RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})').firstMatch(trimmed);
    if (isoMatch != null) {
      final year = isoMatch.group(1)!;
      final month = isoMatch.group(2)!.padLeft(2, '0');
      final day = isoMatch.group(3)!.padLeft(2, '0');
      return '$year-$month-$day';
    }
    return null;
  }
}
