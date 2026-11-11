import 'dart:convert';

class DriverLicenseRecord {
  final String numeroLicencia;
  final String categoria;
  final String estado;
  final String fechaExpedicion;
  final String fechaVencimiento;
  final String organismoTransito;
  final String servicio;

  const DriverLicenseRecord({
    this.numeroLicencia = '',
    required this.categoria,
    this.estado = '',
    this.fechaExpedicion = '',
    this.fechaVencimiento = '',
    this.organismoTransito = '',
    this.servicio = '',
  });

  DateTime? get expirationDate {
    final iso = convertToIsoDate(fechaVencimiento);
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  bool get isVigente {
    final st = estado.toUpperCase();
    if (st.contains('SUSPEND') ||
        st.contains('CANCEL') ||
        st.contains('VENCID') ||
        st.contains('INACTIV')) {
      return false;
    }
    final exp = expirationDate;
    if (exp != null) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      if (exp.isBefore(todayDate)) return false;
    }
    return st.isEmpty || st.contains('ACTIV') || st.contains('VIGENT');
  }

  String get inferredServicio {
    if (servicio.isNotEmpty) return servicio;
    final up = categoria.toUpperCase();
    if (up.startsWith('C')) return 'Público / Carga';
    if (up.startsWith('A')) return 'Motocicleta';
    if (up.startsWith('B')) return 'Particular';
    return 'Conducción';
  }

  Map<String, dynamic> toJson() => {
        'numero_licencia': numeroLicencia,
        'categoria': categoria,
        'estado': estado,
        'fecha_expedicion': fechaExpedicion,
        'fecha_vencimiento': fechaVencimiento,
        'organismo_transito': organismoTransito,
        'servicio': inferredServicio,
      };

  factory DriverLicenseRecord.fromMap(Map<String, dynamic> map) {
    String clean(String key) => (map[key]?.toString() ?? '').trim();
    return DriverLicenseRecord(
      numeroLicencia: clean('numero_licencia'),
      categoria: clean('categoria').toUpperCase(),
      estado: clean('estado'),
      fechaExpedicion: clean('fecha_expedicion'),
      fechaVencimiento: clean('fecha_vencimiento'),
      organismoTransito: clean('organismo_transito'),
      servicio: clean('servicio'),
    );
  }

  static String? convertToIsoDate(String rawDate) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return null;
    final dmy = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})').firstMatch(trimmed);
    if (dmy != null) {
      final day = dmy.group(1)!.padLeft(2, '0');
      final month = dmy.group(2)!.padLeft(2, '0');
      final year = dmy.group(3)!;
      return '$year-$month-$day';
    }
    final iso = RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})').firstMatch(trimmed);
    if (iso != null) {
      final year = iso.group(1)!;
      final month = iso.group(2)!.padLeft(2, '0');
      final day = iso.group(3)!.padLeft(2, '0');
      return '$year-$month-$day';
    }
    return null;
  }
}

/// Ficha oficial de licencias de conducción del ciudadano en RUNTPRO.
class RuntDriverProfile {
  final String nombreConductor;
  final String numeroDocumento;
  final String estadoConductor;
  final String numeroInscripcion;
  final List<DriverLicenseRecord> licencias;
  final DateTime? updatedAt;

  const RuntDriverProfile({
    this.nombreConductor = '',
    this.numeroDocumento = '',
    this.estadoConductor = '',
    this.numeroInscripcion = '',
    this.licencias = const [],
    this.updatedAt,
  });

  bool get hasAnyData =>
      licencias.isNotEmpty ||
      nombreConductor.isNotEmpty ||
      estadoConductor.isNotEmpty;

  List<DriverLicenseRecord> get vigentes =>
      licencias.where((l) => l.isVigente).toList();

  /// Retorna el vencimiento más próximo entre las licencias activas (o de todas si ninguna está vigente).
  DateTime? get earliestExpiration {
    final activeDates = vigentes
        .map((l) => l.expirationDate)
        .whereType<DateTime>()
        .toList()
      ..sort();
    if (activeDates.isNotEmpty) return activeDates.first;

    final allDates = licencias
        .map((l) => l.expirationDate)
        .whereType<DateTime>()
        .toList()
      ..sort();
    return allDates.isNotEmpty ? allDates.first : null;
  }

  Map<String, dynamic> toJson() => {
        'nombre_conductor': nombreConductor,
        'numero_documento': numeroDocumento,
        'estado_conductor': estadoConductor,
        'numero_inscripcion': numeroInscripcion,
        'licencias': licencias.map((l) => l.toJson()).toList(),
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  factory RuntDriverProfile.fromMap(Map<String, dynamic> map) {
    final rawList = map['licencias'];
    final parsed = <DriverLicenseRecord>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map) {
          final rec = DriverLicenseRecord.fromMap(Map<String, dynamic>.from(item));
          if (rec.categoria.isNotEmpty || rec.numeroLicencia.isNotEmpty) {
            parsed.add(rec);
          }
        }
      }
    }
    return RuntDriverProfile(
      nombreConductor: (map['nombre_conductor']?.toString() ?? '').trim(),
      numeroDocumento: (map['numero_documento']?.toString() ?? '').trim(),
      estadoConductor: (map['estado_conductor']?.toString() ?? '').trim(),
      numeroInscripcion: (map['numero_inscripcion']?.toString() ?? '').trim(),
      licencias: parsed,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  static RuntDriverProfile? tryDecodeWebViewResult(Object? rawResult) {
    if (rawResult == null) return null;
    try {
      dynamic decoded = rawResult is String ? jsonDecode(rawResult) : rawResult;
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final primary = RuntDriverProfile.fromMap(map);
        final rawText = map['raw_text']?.toString() ?? '';
        if (rawText.trim().isNotEmpty) {
          return primary.mergeWith(parseFromRawText(rawText));
        }
        return primary;
      }
    } catch (_) {}
    if (rawResult is String && rawResult.trim().isNotEmpty) {
      final parsed = parseFromRawText(rawResult);
      if (parsed.hasAnyData) return parsed;
    }
    return null;
  }

  RuntDriverProfile mergeWith(RuntDriverProfile fallback) {
    String pick(String a, String b) => a.trim().isNotEmpty ? a.trim() : b.trim();
    final mergedLicenses = <String, DriverLicenseRecord>{};

    void addAll(List<DriverLicenseRecord> list) {
      for (final item in list) {
        final key = '${item.categoria}_${item.numeroLicencia}'.trim();
        if (!mergedLicenses.containsKey(key)) {
          mergedLicenses[key] = item;
        } else {
          final prev = mergedLicenses[key]!;
          mergedLicenses[key] = DriverLicenseRecord(
            numeroLicencia: pick(prev.numeroLicencia, item.numeroLicencia),
            categoria: pick(prev.categoria, item.categoria),
            estado: pick(prev.estado, item.estado),
            fechaExpedicion: pick(prev.fechaExpedicion, item.fechaExpedicion),
            fechaVencimiento: pick(prev.fechaVencimiento, item.fechaVencimiento),
            organismoTransito: pick(prev.organismoTransito, item.organismoTransito),
            servicio: pick(prev.servicio, item.servicio),
          );
        }
      }
    }

    addAll(licencias);
    addAll(fallback.licencias);

    return RuntDriverProfile(
      nombreConductor: pick(nombreConductor, fallback.nombreConductor),
      numeroDocumento: pick(numeroDocumento, fallback.numeroDocumento),
      estadoConductor: pick(estadoConductor, fallback.estadoConductor),
      numeroInscripcion: pick(numeroInscripcion, fallback.numeroInscripcion),
      licencias: mergedLicenses.values.toList(),
      updatedAt: updatedAt ?? fallback.updatedAt,
    );
  }

  /// Extrae licencias de conducción y categorías (A1, A2, B1, B2, B3, C1, C2, C3) desde el texto RUNTPRO.
  static RuntDriverProfile parseFromRawText(String rawText) {
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

    String nombre = '', documento = '', estadoConductor = '', inscripcion = '';
    final List<DriverLicenseRecord> records = [];

    String curCat = '';
    String curNum = '';
    String curEstado = '';
    String curExp = '';
    String curVen = '';
    String curOrg = '';

    void flushCurrent() {
      if (curCat.isNotEmpty || curVen.isNotEmpty) {
        records.add(
          DriverLicenseRecord(
            numeroLicencia: curNum,
            categoria: curCat.isNotEmpty ? curCat : 'LIC',
            estado: curEstado,
            fechaExpedicion: curExp,
            fechaVencimiento: curVen,
            organismoTransito: curOrg,
          ),
        );
      }
      curCat = '';
      curNum = '';
      curEstado = '';
      curExp = '';
      curVen = '';
      curOrg = '';
    }

    final catRegex = RegExp(r'\b(A1|A2|B1|B2|B3|C1|C2|C3)\b');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final up = normalizeKey(line);

      // Campos de identidad del conductor
      final colonIdx = line.indexOf(':');
      String keyPart = '';
      String valPart = '';
      if (colonIdx > 0 && colonIdx < line.length - 1) {
        keyPart = normalizeKey(line.substring(0, colonIdx));
        valPart = line.substring(colonIdx + 1).trim();
      } else if (line.endsWith(':') && i + 1 < lines.length) {
        keyPart = normalizeKey(line.substring(0, line.length - 1));
        valPart = lines[i + 1].trim();
      }

      if (keyPart.isNotEmpty && valPart.isNotEmpty) {
        if ((keyPart.contains('NOMBRE') || keyPart.contains('APELLIDOS')) && nombre.isEmpty) {
          nombre = valPart;
          continue;
        }
        if ((keyPart.contains('NUMERO DE DOCUMENTO') || keyPart == 'DOCUMENTO') && documento.isEmpty) {
          documento = valPart;
          continue;
        }
        if (keyPart.contains('ESTADO DEL CONDUCTOR') && estadoConductor.isEmpty) {
          estadoConductor = valPart;
          continue;
        }
        if (keyPart.contains('INSCRIPCION') && inscripcion.isEmpty) {
          inscripcion = valPart;
          continue;
        }
        if (keyPart.contains('NUMERO DE LICENCIA') || keyPart == 'NRO. LICENCIA' || keyPart == 'LICENCIA') {
          if (curNum.isNotEmpty && curCat.isNotEmpty) flushCurrent();
          curNum = valPart;
          continue;
        }
        if (keyPart.contains('CATEGORIA')) {
          final m = catRegex.firstMatch(valPart.toUpperCase());
          if (curCat.isNotEmpty) flushCurrent();
          curCat = m != null ? m.group(1)! : valPart.toUpperCase();
          continue;
        }
        if (keyPart.contains('ESTADO')) {
          curEstado = valPart;
          continue;
        }
        if (keyPart.contains('EXPEDICION')) {
          curExp = valPart;
          continue;
        }
        if (keyPart.contains('VENCIMIENTO') || keyPart.contains('VIGENCIA')) {
          curVen = valPart;
          continue;
        }
        if (keyPart.contains('ORGANISMO') || keyPart.contains('SECRETARIA') || keyPart.contains('TRANSITO')) {
          curOrg = valPart;
          continue;
        }
      }

      // Filas tabulares en texto plano que contienen categoría + fechas en una sola línea
      final rowCatMatch = catRegex.firstMatch(up);
      final dates = RegExp(r'\b(\d{2}[\/\-]\d{2}[\/\-]\d{4}|\d{4}[\/\-]\d{2}[\/\-]\d{2})\b')
          .allMatches(line)
          .map((m) => m.group(0)!)
          .toList();
      if (rowCatMatch != null && dates.isNotEmpty) {
        String st = '';
        if (up.contains('ACTIVA') || up.contains('VIGENTE')) {
          st = 'ACTIVA';
        } else if (up.contains('VENCID')) {
          st = 'VENCIDA';
        } else if (up.contains('SUSPEND')) {
          st = 'SUSPENDIDA';
        } else if (up.contains('CANCEL')) {
          st = 'CANCELADA';
        }
        records.add(
          DriverLicenseRecord(
            categoria: rowCatMatch.group(1)!,
            estado: st,
            fechaExpedicion: dates.length >= 2 ? dates.first : '',
            fechaVencimiento: dates.last,
          ),
        );
      }
    }

    flushCurrent();

    return RuntDriverProfile(
      nombreConductor: nombre,
      numeroDocumento: documento,
      estadoConductor: estadoConductor,
      numeroInscripcion: inscripcion,
      licencias: records,
    );
  }
}
