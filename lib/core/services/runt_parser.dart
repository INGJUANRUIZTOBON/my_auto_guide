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
  final String soatInicioVigencia;
  final String soatVencimiento;

  final String tecnoEstado;
  final String tecnoCertificado;
  final String tecnoCda;
  final String tecnoExpedicion;
  final String tecnoInicioVigencia;
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
    this.soatInicioVigencia = '',
    this.soatVencimiento = '',
    this.tecnoEstado = '',
    this.tecnoCertificado = '',
    this.tecnoCda = '',
    this.tecnoExpedicion = '',
    this.tecnoInicioVigencia = '',
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
      cilindraje.isNotEmpty ||
      clase.isNotEmpty ||
      estadoVehiculo.isNotEmpty ||
      organismoTransito.isNotEmpty;

  /// Suma exactamente 1 año a una fecha formateada (DD/MM/AAAA o YYYY-MM-DD).
  /// Respeta años bisiestos (29 de febrero -> 28 de febrero del año siguiente).
  static String addOneYear(String rawDate) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return '';

    // Formato DD/MM/AAAA o D/M/AAAA
    final dmyMatch = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$').firstMatch(trimmed);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!) ?? 1;
      final month = int.tryParse(dmyMatch.group(2)!) ?? 1;
      final year = (int.tryParse(dmyMatch.group(3)!) ?? 2000) + 1;
      final safeDay = (month == 2 && day == 29) ? 28 : day;
      return '${safeDay.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
    }

    // Formato YYYY-MM-DD
    final isoMatch = RegExp(r'^(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})$').firstMatch(trimmed);
    if (isoMatch != null) {
      final year = (int.tryParse(isoMatch.group(1)!) ?? 2000) + 1;
      final month = int.tryParse(isoMatch.group(2)!) ?? 1;
      final day = int.tryParse(isoMatch.group(3)!) ?? 1;
      final safeDay = (month == 2 && day == 29) ? 28 : day;
      return '$year-${month.toString().padLeft(2, '0')}-${safeDay.toString().padLeft(2, '0')}';
    }

    try {
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        final safeDay = (dt.month == 2 && dt.day == 29) ? 28 : dt.day;
        final next = DateTime(dt.year + 1, dt.month, safeDay);
        return '${next.day.toString().padLeft(2, '0')}/${next.month.toString().padLeft(2, '0')}/${next.year}';
      }
    } catch (_) {}

    return trimmed;
  }

  /// Fecha de vencimiento efectiva del SOAT.
  /// En Colombia el SOAT vence estrictamente 1 año después de su expedición o inicio de vigencia.
  /// En el portal ciudadano del RUNT la columna exhibida suele ser la fecha de expedición/inicio;
  /// si la fecha extraída corresponde al inicio o si no se especificó fecha futura,
  /// se proyecta 1 año después para evitar falsos vencimientos.
  String get effectiveSoatVencimiento {
    final start = soatInicioVigencia.isNotEmpty ? soatInicioVigencia : soatExpedicion;

    if (soatVencimiento.isEmpty) {
      return start.isNotEmpty ? addOneYear(start) : '';
    }

    if (soatVencimiento == soatInicioVigencia || soatVencimiento == soatExpedicion) {
      return addOneYear(soatVencimiento);
    }

    final vIso = convertToIsoDate(soatVencimiento);
    final sIso = start.isNotEmpty ? convertToIsoDate(start) : null;
    if (vIso != null && sIso != null) {
      final vDate = DateTime.tryParse(vIso);
      final sDate = DateTime.tryParse(sIso);
      if (vDate != null && sDate != null && !vDate.isAfter(sDate)) {
        return addOneYear(soatVencimiento);
      }
      if (vDate != null && sDate != null && vDate.isAfter(sDate)) {
        return soatVencimiento;
      }
    }

    if (vIso != null) {
      final vDate = DateTime.tryParse(vIso);
      final now = DateTime.now();
      final isVigente = soatEstado.toUpperCase().contains('VIGENT') ||
          soatEstado.toUpperCase().contains('ACTIV') ||
          soatEstado.isEmpty;
      if (vDate != null && vDate.isBefore(now) && isVigente) {
        return addOneYear(soatVencimiento);
      }
    }

    return soatVencimiento;
  }

  /// Fecha de vencimiento efectiva de la Tecnomecánica (RTM).
  /// En Colombia la RTM vence exactamente 1 año después de su expedición/revisión.
  String get effectiveTecnoVencimiento {
    final start = tecnoInicioVigencia.isNotEmpty ? tecnoInicioVigencia : tecnoExpedicion;

    if (tecnoVencimiento.isEmpty) {
      return start.isNotEmpty ? addOneYear(start) : '';
    }

    if (tecnoVencimiento == tecnoInicioVigencia || tecnoVencimiento == tecnoExpedicion) {
      return addOneYear(tecnoVencimiento);
    }

    final vIso = convertToIsoDate(tecnoVencimiento);
    final sIso = start.isNotEmpty ? convertToIsoDate(start) : null;
    if (vIso != null && sIso != null) {
      final vDate = DateTime.tryParse(vIso);
      final sDate = DateTime.tryParse(sIso);
      if (vDate != null && sDate != null && !vDate.isAfter(sDate)) {
        return addOneYear(tecnoVencimiento);
      }
      if (vDate != null && sDate != null && vDate.isAfter(sDate)) {
        return tecnoVencimiento;
      }
    }

    if (vIso != null) {
      final vDate = DateTime.tryParse(vIso);
      final now = DateTime.now();
      final isVigente = tecnoEstado.toUpperCase().contains('VIGENT') ||
          tecnoEstado.toUpperCase().contains('ACTIV') ||
          tecnoEstado.isEmpty;
      if (vDate != null && vDate.isBefore(now) && isVigente) {
        return addOneYear(tecnoVencimiento);
      }
    }

    return tecnoVencimiento;
  }

  /// Fecha de inicio o expedición garantizada para SOAT
  String get effectiveSoatInicio {
    if (soatInicioVigencia.isNotEmpty) return soatInicioVigencia;
    if (soatExpedicion.isNotEmpty) return soatExpedicion;
    if (soatVencimiento.isNotEmpty) return soatVencimiento;
    return '';
  }

  /// Fecha de inicio o expedición garantizada para Tecnomecánica
  String get effectiveTecnoInicio {
    if (tecnoInicioVigencia.isNotEmpty) return tecnoInicioVigencia;
    if (tecnoExpedicion.isNotEmpty) return tecnoExpedicion;
    if (tecnoVencimiento.isNotEmpty) return tecnoVencimiento;
    return '';
  }

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
        'soat_expedicion': effectiveSoatInicio,
        'soat_inicio_vigencia': effectiveSoatInicio,
        'soat_vencimiento': effectiveSoatVencimiento,
        'tecno_estado': tecnoEstado,
        'tecno_certificado': tecnoCertificado,
        'tecno_cda': tecnoCda,
        'tecno_expedicion': effectiveTecnoInicio,
        'tecno_inicio_vigencia': effectiveTecnoInicio,
        'tecno_vencimiento': effectiveTecnoVencimiento,
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  factory RuntVehicleProfile.fromMap(Map<String, dynamic> map) {
    String clean(String key) => sanitizeField((map[key]?.toString() ?? ''));
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
      soatInicioVigencia: clean('soat_inicio_vigencia'),
      soatVencimiento: clean('soat_vencimiento'),
      tecnoEstado: clean('tecno_estado'),
      tecnoCertificado: clean('tecno_certificado'),
      tecnoCda: clean('tecno_cda'),
      tecnoExpedicion: clean('tecno_expedicion'),
      tecnoInicioVigencia: clean('tecno_inicio_vigencia'),
      tecnoVencimiento: clean('tecno_vencimiento'),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Decodifica el resultado crudo devuelto por WebView (`runJavaScriptReturningResult`),
  /// tolerando doble serialización JSON propia de Android WebView y aplicando fallback de texto plano si viene `raw_text`.
  static RuntVehicleProfile? tryDecodeWebViewResult(Object? rawResult) {
    if (rawResult == null) return null;
    try {
      dynamic decoded = rawResult is String ? jsonDecode(rawResult) : rawResult;
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final primary = RuntVehicleProfile.fromMap(map);
        final rawText = map['raw_text']?.toString() ?? '';
        if (rawText.trim().isNotEmpty) {
          return primary.mergeWith(parseFromRawText(rawText));
        }
        return primary;
      }
    } catch (_) {}
    if (rawResult is String && rawResult.trim().isNotEmpty) {
      final fromText = parseFromRawText(rawResult);
      if (fromText.hasAnyData) return fromText;
    }
    return null;
  }

  /// Combina los campos faltantes con un perfil secundario extraído por otra estrategia.
  RuntVehicleProfile mergeWith(RuntVehicleProfile fallback) {
    String pick(String a, String b) => a.trim().isNotEmpty ? a.trim() : b.trim();
    return RuntVehicleProfile(
      marca: pick(marca, fallback.marca),
      linea: pick(linea, fallback.linea),
      modeloAno: pick(modeloAno, fallback.modeloAno),
      color: pick(color, fallback.color),
      clase: pick(clase, fallback.clase),
      servicio: pick(servicio, fallback.servicio),
      estadoVehiculo: pick(estadoVehiculo, fallback.estadoVehiculo),
      cilindraje: pick(cilindraje, fallback.cilindraje),
      combustible: pick(combustible, fallback.combustible),
      vin: pick(vin, fallback.vin),
      numeroMotor: pick(numeroMotor, fallback.numeroMotor),
      numeroChasis: pick(numeroChasis, fallback.numeroChasis),
      gravamenes: pick(gravamenes, fallback.gravamenes),
      organismoTransito: pick(organismoTransito, fallback.organismoTransito),
      soatEstado: pick(soatEstado, fallback.soatEstado),
      soatAseguradora: pick(soatAseguradora, fallback.soatAseguradora),
      soatPoliza: pick(soatPoliza, fallback.soatPoliza),
      soatExpedicion: pick(soatExpedicion, fallback.soatExpedicion),
      soatInicioVigencia: pick(soatInicioVigencia, fallback.soatInicioVigencia),
      soatVencimiento: pick(soatVencimiento, fallback.soatVencimiento),
      tecnoEstado: pick(tecnoEstado, fallback.tecnoEstado),
      tecnoCertificado: pick(tecnoCertificado, fallback.tecnoCertificado),
      tecnoCda: pick(tecnoCda, fallback.tecnoCda),
      tecnoExpedicion: pick(tecnoExpedicion, fallback.tecnoExpedicion),
      tecnoInicioVigencia: pick(tecnoInicioVigencia, fallback.tecnoInicioVigencia),
      tecnoVencimiento: pick(tecnoVencimiento, fallback.tecnoVencimiento),
      updatedAt: updatedAt ?? fallback.updatedAt,
    );
  }

  /// Parser robusto de texto visible RUNTPRO (pares inline "Etiqueta: Valor" y pares apilados en líneas contiguas).
  static RuntVehicleProfile parseFromRawText(String rawText) {
    final lines = rawText
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String normalizeKey(String input) {
      return input
          .toUpperCase()
          .replaceAll('Á', 'A')
          .replaceAll('É', 'E')
          .replaceAll('Í', 'I')
          .replaceAll('Ó', 'O')
          .replaceAll('Ú', 'U')
          .replaceAll('Ñ', 'N')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    String marca = '',
        linea = '',
        modeloAno = '',
        color = '',
        clase = '',
        servicio = '',
        estadoVehiculo = '',
        cilindraje = '',
        combustible = '',
        vin = '',
        numeroMotor = '',
        numeroChasis = '',
        gravamenes = '',
        organismoTransito = '',
        soatEstado = '',
        soatAseguradora = '',
        soatPoliza = '',
        soatExpedicion = '',
        soatInicioVigencia = '',
        soatVencimiento = '',
        tecnoEstado = '',
        tecnoCertificado = '',
        tecnoCda = '',
        tecnoExpedicion = '',
        tecnoInicioVigencia = '',
        tecnoVencimiento = '';

    String section = 'GENERAL';

    void assign(String rawLabel, String rawVal) {
      final k = normalizeKey(rawLabel).replaceAll(':', '').trim();
      final v = rawVal.trim();
      if (k.isEmpty || v.isEmpty || v.endsWith(':') || v.length > 140) return;

      if (section == 'SOAT') {
        if ((k.contains('ESTADO') || k == 'VIGENCIA') && soatEstado.isEmpty) {
          soatEstado = v;
        } else if ((k.contains('ENTIDAD') || k.contains('ASEGURADORA')) && soatAseguradora.isEmpty) {
          soatAseguradora = v;
        } else if ((k.contains('POLIZA') || k.contains('NO. POLIZA')) && soatPoliza.isEmpty) {
          soatPoliza = v;
        } else if ((k.contains('INICIO DE VIGENCIA') || k.contains('INICIO VIGENCIA') || k.contains('DESDE')) &&
            soatInicioVigencia.isEmpty) {
          soatInicioVigencia = v;
        } else if (k.contains('EXPEDICION') && soatExpedicion.isEmpty) {
          soatExpedicion = v;
        } else if ((k.contains('FIN DE VIGENCIA') || k.contains('FIN VIGENCIA') || k.contains('VENCIMIENTO') || k.contains('HASTA')) &&
            soatVencimiento.isEmpty) {
          soatVencimiento = v;
        }
        return;
      }

      if (section == 'RTM') {
        if (k.contains('ESTADO') && tecnoEstado.isEmpty) {
          tecnoEstado = v;
        } else if ((k.contains('CERTIFICADO') || k.contains('NRO. CERTIFICADO')) && tecnoCertificado.isEmpty) {
          tecnoCertificado = v;
        } else if ((k.contains('CDA') || k.contains('ORGANISMO') || k.contains('CENTRO DE DIAGNOSTICO')) && tecnoCda.isEmpty) {
          tecnoCda = v;
        } else if ((k.contains('INICIO') || k.contains('DESDE')) && tecnoInicioVigencia.isEmpty) {
          tecnoInicioVigencia = v;
        } else if (k.contains('EXPEDICION') && tecnoExpedicion.isEmpty) {
          tecnoExpedicion = v;
        } else if ((k.contains('FIN DE VIGENCIA') || k.contains('FIN VIGENCIA') || k.contains('VIGENTE HASTA') || k.contains('VENCIMIENTO') || k.contains('HASTA') || k.contains('VIGENCIA')) &&
            tecnoVencimiento.isEmpty) {
          tecnoVencimiento = v;
        }
        return;
      }

      if (k == 'MARCA' && marca.isEmpty) {
        marca = v;
      } else if (k == 'LINEA' && linea.isEmpty) {
        linea = v;
      } else if ((k == 'MODELO' || k == 'ANO MODELO') && modeloAno.isEmpty) {
        modeloAno = v;
      } else if (k == 'COLOR' && color.isEmpty) {
        color = v;
      } else if ((k == 'CLASE' || k.startsWith('CLASE') || k.contains('CLASE') || k.contains('TIPO DE VEHICULO')) && clase.isEmpty) {
        clase = v;
      } else if ((k == 'SERVICIO' || k.startsWith('SERVICIO') || k.contains('SERVICIO') || k.contains('MODALIDAD')) && servicio.isEmpty) {
        servicio = v;
      } else if (k.contains('ESTADO DEL VEHICULO') && estadoVehiculo.isEmpty) {
        estadoVehiculo = v;
      } else if (k.contains('CILINDRA') && cilindraje.isEmpty) {
        cilindraje = v;
      } else if (k.contains('COMBUSTIBLE') && combustible.isEmpty) {
        combustible = v;
      } else if ((k == 'VIN' || k.contains('NUMERO VIN')) && vin.isEmpty) {
        vin = v;
      } else if (k.contains('NUMERO DE MOTOR') && numeroMotor.isEmpty) {
        numeroMotor = v;
      } else if ((k.contains('NUMERO DE CHASIS') || k == 'CHASIS') && numeroChasis.isEmpty) {
        numeroChasis = v;
      } else if ((k.contains('GRAVAMENES') || k.contains('PRENDAS') || k.contains('LIMITACIONES')) && gravamenes.isEmpty) {
        gravamenes = v;
      } else if (k.contains('ORGANISMO DE TRANSITO') && organismoTransito.isEmpty) {
        organismoTransito = v;
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final up = normalizeKey(line);

      if (up.contains('POLIZA SOAT') || up.contains('SOAT') || up.contains('SEGURO OBLIGATORIO')) {
        section = 'SOAT';
      } else if (up.contains('TECNICO MECANICA') ||
          up.contains('TECNICOMECANICA') ||
          up.contains('TECNICO-MECANICA') ||
          up.contains('RTM') ||
          up.contains('REVISION TECNICA')) {
        section = 'RTM';
      } else if (up.contains('INFORMACION GENERAL') ||
          up.contains('DATOS TECNICOS') ||
          up.contains('DATOS GENERALES') ||
          up.contains('LIMITACIONES')) {
        section = 'GENERAL';
      }

      // Caso A: Par en la misma línea ("Marca: BAJAJ", "Clase: AUTOMÓVIL")
      final colonIdx = line.indexOf(':');
      if (colonIdx > 0 && colonIdx < line.length - 1) {
        final labelPart = line.substring(0, colonIdx);
        final valPart = line.substring(colonIdx + 1);
        assign(labelPart, valPart);
        continue;
      }

      // Caso B: Etiqueta termina en ":" y el valor viene en la línea siguiente
      if (line.endsWith(':') && i + 1 < lines.length) {
        assign(line, lines[i + 1]);
        continue;
      }

      // Caso C: Filas tabulares o bloques de texto con fechas (DD/MM/AAAA o AAAA-MM-DD)
      final dateMatches = RegExp(r'\b(\d{1,2}[/\-]\d{1,2}[/\-]\d{4}|\d{4}[/\-]\d{1,2}[/\-]\d{1,2})\b')
          .allMatches(line)
          .map((m) => m.group(0)!)
          .toList();

      if (dateMatches.isNotEmpty) {
        if (section == 'SOAT') {
          if (soatVencimiento.isEmpty || up.contains('VIGENTE') || up.contains('ACTIVA')) {
            if (dateMatches.length >= 2) {
              if (soatInicioVigencia.isEmpty) soatInicioVigencia = dateMatches[0];
              soatVencimiento = dateMatches[dateMatches.length - 1];
            } else if (soatVencimiento.isEmpty) {
              soatVencimiento = dateMatches[0];
            }
          }
          if (up.contains('VIGENTE') && soatEstado.isEmpty) soatEstado = 'VIGENTE';
        } else if (section == 'RTM') {
          if (tecnoVencimiento.isEmpty || up.contains('VIGENTE') || up.contains('ACTIVA')) {
            if (dateMatches.length >= 2) {
              if (tecnoInicioVigencia.isEmpty) tecnoInicioVigencia = dateMatches[0];
              tecnoVencimiento = dateMatches[dateMatches.length - 1];
            } else if (tecnoVencimiento.isEmpty) {
              tecnoVencimiento = dateMatches[0];
            }
          }
          if (up.contains('VIGENTE') && tecnoEstado.isEmpty) tecnoEstado = 'VIGENTE';
        }
      }
    }

    // Barrido global de seguridad por expresiones regulares si algún campo crítico quedó vacío
    if (clase.isEmpty) {
      final m = RegExp(r'\b(?:CLASE|CLASE\s+DE\s+VEHICULO|CLASE\s+DEL\s+VEHICULO|TIPO\s+DE\s+VEHICULO)\s*[:\-]?\s*([A-Za-zÁÉÍÓÚáéíóúñÑ\s]{3,30})\b', caseSensitive: false).firstMatch(rawText);
      if (m != null) clase = m.group(1)!.trim();
    }

    if (servicio.isEmpty) {
      final m = RegExp(r'\b(?:TIPO\s+DE\s+SERVICIO|SERVICIO|MODALIDAD\s+DE\s+SERVICIO)\s*[:\-]?\s*([A-Za-zÁÉÍÓÚáéíóúñÑ\s]{3,30})\b', caseSensitive: false).firstMatch(rawText);
      if (m != null) servicio = m.group(1)!.trim();
    }

    if (soatVencimiento.isEmpty) {
      // Buscar en todo el texto cualquier fecha cercana a la palabra SOAT
      final m = RegExp(r'SOAT[^\n\r]{0,120}?(\d{1,2}[/\-]\d{1,2}[/\-]\d{4}|\d{4}[/\-]\d{1,2}[/\-]\d{1,2})', caseSensitive: false).firstMatch(rawText);
      if (m != null) soatVencimiento = m.group(1)!.trim();
    }

    if (tecnoVencimiento.isEmpty) {
      // Buscar en todo el texto cualquier fecha cercana a RTM o TECNICOMECANICA
      final m = RegExp(r'(?:RTM|TECNICO|MECANICA|REVISION)[^\n\r]{0,120}?(\d{1,2}[/\-]\d{1,2}[/\-]\d{4}|\d{4}[/\-]\d{1,2}[/\-]\d{1,2})', caseSensitive: false).firstMatch(rawText);
      if (m != null) tecnoVencimiento = m.group(1)!.trim();
    }

    return RuntVehicleProfile(
      marca: marca,
      linea: linea,
      modeloAno: modeloAno,
      color: color,
      clase: clase,
      servicio: servicio,
      estadoVehiculo: estadoVehiculo,
      cilindraje: cilindraje,
      combustible: combustible,
      vin: vin,
      numeroMotor: numeroMotor,
      numeroChasis: numeroChasis,
      gravamenes: gravamenes,
      organismoTransito: organismoTransito,
      soatEstado: soatEstado,
      soatAseguradora: soatAseguradora,
      soatPoliza: soatPoliza,
      soatExpedicion: soatExpedicion,
      soatInicioVigencia: soatInicioVigencia,
      soatVencimiento: soatVencimiento,
      tecnoEstado: tecnoEstado,
      tecnoCertificado: tecnoCertificado,
      tecnoCda: tecnoCda,
      tecnoExpedicion: tecnoExpedicion,
      tecnoInicioVigencia: tecnoInicioVigencia,
      tecnoVencimiento: tecnoVencimiento,
    );
  }

  /// Resuelve la fecha ISO (`YYYY-MM-DD`) de **inicio de vigencia** para mantener consistencia
  /// con los cálculos de vida útil anual en Mantenimientos (`last_soat` / `last_tecno`).
  /// Si la fecha provista es futura (vencimiento legítimo), resta 1 año para obtener el inicio.
  /// Si la fecha provista ya es del pasado (fecha de expedición/inicio del ciclo actual),
  /// la toma directamente para no empujar erróneamente el documento al año anterior ni marcarlo vencido.
  static String? resolveStartIsoDate({
    required String inicio,
    required String expedicion,
    required String vencimiento,
  }) {
    final directInicio = convertToIsoDate(inicio);
    if (directInicio != null) return directInicio;

    final directExp = convertToIsoDate(expedicion);
    if (directExp != null) return directExp;

    final expIso = convertToIsoDate(vencimiento);
    if (expIso == null) return null;
    final expDate = DateTime.tryParse(expIso);
    if (expDate == null) return null;

    final now = DateTime.now();
    if (expDate.isAfter(now)) {
      final startDate = DateTime(expDate.year - 1, expDate.month, expDate.day);
      return '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }

    // Si expDate <= now, la fecha encontrada fue la fecha de expedición / inicio
    return expIso;
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

  /// Limpia nombres de íconos Material (`check_circle`, `car_crash`, etc.) que RUNTPRO incrusta en `innerText`.
  static String sanitizeField(String raw) {
    var cleaned = raw
        .replaceAll(
          RegExp(
            r'\b(check_circle_outline|check_circle|car_crash|error_outline|cancel|warning|verified|info|directions_car|two_wheeler)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.startsWith('•')) {
      cleaned = cleaned.substring(1).trim();
    }
    return cleaned;
  }
}
