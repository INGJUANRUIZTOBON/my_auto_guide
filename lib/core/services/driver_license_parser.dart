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

  /// Determina vigencia real en Colombia:
  /// - Si el estado indica explícitamente SUSPENDIDA / CANCELADA / VENCIDA / INACTIVA => false.
  /// - Si hay fecha de vencimiento válida, se compara directamente contra hoy (`exp >= today` => vigente).
  /// - Si no hay fecha de vencimiento, solo es vigente si el estado indica ACTIVA / VIGENTE.
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
      return !exp.isBefore(todayDate);
    }
    return st.contains('ACTIV') || st.contains('VIGENT');
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
          // Exigir fecha de vencimiento o número/categoría real (descarta falsos positivos de formularios vacíos)
          if (rec.categoria.isNotEmpty &&
              (rec.fechaVencimiento.isNotEmpty ||
                  rec.fechaExpedicion.isNotEmpty ||
                  rec.numeroLicencia.isNotEmpty)) {
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
    final fallbackOrg = licencias.map((e) => e.organismoTransito).firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final fallbackNum = licencias.map((e) => e.numeroLicencia).firstWhere((e) => e.isNotEmpty, orElse: () => '');

    void addAll(List<DriverLicenseRecord> list) {
      for (final item in list) {
        final cat = item.categoria.toUpperCase();
        if (cat.isEmpty) continue;
        // Unificar por categoría real para combinar fila DOM + detalle modal sin duplicar
        final existing = mergedLicenses[cat];
        if (existing == null) {
          mergedLicenses[cat] = DriverLicenseRecord(
            numeroLicencia: item.numeroLicencia.isNotEmpty ? item.numeroLicencia : fallbackNum,
            categoria: cat,
            estado: item.estado,
            fechaExpedicion: item.fechaExpedicion,
            fechaVencimiento: item.fechaVencimiento,
            organismoTransito: item.organismoTransito.isNotEmpty ? item.organismoTransito : fallbackOrg,
            servicio: item.servicio,
          );
        } else {
          mergedLicenses[cat] = DriverLicenseRecord(
            numeroLicencia: pick(existing.numeroLicencia, item.numeroLicencia),
            categoria: cat,
            estado: pick(existing.estado, item.estado),
            fechaExpedicion: pick(existing.fechaExpedicion, item.fechaExpedicion),
            fechaVencimiento: pick(existing.fechaVencimiento, item.fechaVencimiento),
            organismoTransito: pick(existing.organismoTransito, item.organismoTransito),
            servicio: pick(existing.servicio, item.servicio),
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

  /// Extrae licencias de conducción y categorías (A1..C3) desde texto RUNTPRO
  /// (soporta pares "Clave: Valor", filas tabulares en línea y celdas apiladas en pantalla móvil).
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

    String extractLicenseState(String raw) {
      final up = normalizeKey(raw);
      if (up.contains('SUSPEND')) return 'SUSPENDIDA';
      if (up.contains('CANCEL')) return 'CANCELADA';
      if (up.contains('VENCID')) return 'VENCIDA';
      if (up.contains('INACTIV')) return 'INACTIVA';
      if (up.contains('ACTIVA') || up.contains('VIGENTE')) return 'ACTIVA';
      return '';
    }

    String nombre = '', documento = '', estadoConductor = '', inscripcion = '';
    String globalParentEstado = '';
    String globalLicenseNum = '';
    final List<DriverLicenseRecord> records = [];

    String curCat = '';
    String curNum = '';
    String curEstado = '';
    String curExp = '';
    String curVen = '';
    String curOrg = '';

    void flushCurrent() {
      if (curCat.isNotEmpty && (curVen.isNotEmpty || curExp.isNotEmpty || curNum.isNotEmpty)) {
        records.add(
          DriverLicenseRecord(
            numeroLicencia: curNum.isNotEmpty ? curNum : globalLicenseNum,
            categoria: curCat,
            estado: curEstado.isNotEmpty ? curEstado : globalParentEstado,
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
    final strictCatLineRegex = RegExp(r'^(A1|A2|B1|B2|B3|C1|C2|C3)$');
    final dateRegex = RegExp(r'\b(\d{2}[\/\-]\d{2}[\/\-]\d{4}|\d{4}[\/\-]\d{2}[\/\-]\d{2})\b');

    // Pre-escaneo de estado/número global en tabla principal "Licencia(s) de conducción"
    for (final l in lines) {
      final up = normalizeKey(l);
      if ((up.contains('ACTIVA') || up.contains('SUSPEND') || up.contains('CANCEL')) &&
          dateRegex.hasMatch(l)) {
        final st = extractLicenseState(up);
        if (st.isNotEmpty && globalParentEstado.isEmpty) globalParentEstado = st;
        final nMatch = RegExp(r'\b(\d{6,15})\b').firstMatch(l);
        if (nMatch != null && globalLicenseNum.isEmpty) {
          globalLicenseNum = nMatch.group(1)!;
        }
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final up = normalizeKey(line);

      final headerNroMatch = RegExp(r'CATEGORIAS DE LA LICENCIA NRO:\s*(\d+)').firstMatch(up);
      if (headerNroMatch != null) {
        globalLicenseNum = headerNroMatch.group(1)!;
        continue;
      }

      final colonIdx = line.indexOf(':');
      String keyPart = '';
      String valPart = '';
      bool consumedNextLine = false;
      if (colonIdx > 0 && colonIdx < line.length - 1) {
        keyPart = normalizeKey(line.substring(0, colonIdx));
        valPart = line.substring(colonIdx + 1).trim();
      } else if (line.endsWith(':') && i + 1 < lines.length) {
        keyPart = normalizeKey(line.substring(0, line.length - 1));
        valPart = lines[i + 1].trim();
        consumedNextLine = true;
      } else if (i + 1 < lines.length &&
          (up == 'NOMBRE COMPLETO' ||
              up == 'DOCUMENTO' ||
              up == 'NUMERO DE DOCUMENTO' ||
              up == 'ESTADO DEL CONDUCTOR' ||
              up == 'NUMERO DE INSCRIPCION' ||
              up == 'CATEGORIA' ||
              up == 'ESTADO' ||
              up == 'FECHA EXPEDICION' ||
              up == 'FECHA DE EXPEDICION' ||
              up == 'FECHA VENCIMIENTO' ||
              up == 'FECHA DE VENCIMIENTO')) {
        keyPart = up;
        valPart = lines[i + 1].trim();
        consumedNextLine = true;
      }

      if (keyPart.isNotEmpty && valPart.isNotEmpty) {
        void advanceIfStacked() {
          if (consumedNextLine) i++;
        }

        if ((keyPart.contains('NOMBRE') || keyPart.contains('APELLIDOS')) && nombre.isEmpty) {
          nombre = valPart;
          advanceIfStacked();
          continue;
        }
        if ((keyPart.contains('NUMERO DE DOCUMENTO') || keyPart == 'DOCUMENTO') && documento.isEmpty) {
          documento = valPart;
          advanceIfStacked();
          continue;
        }
        if (keyPart.contains('ESTADO DEL CONDUCTOR') && estadoConductor.isEmpty) {
          estadoConductor = valPart;
          advanceIfStacked();
          continue;
        }
        if (keyPart.contains('INSCRIPCION') && inscripcion.isEmpty) {
          inscripcion = valPart;
          advanceIfStacked();
          continue;
        }
        if (keyPart.contains('NUMERO DE LICENCIA') || keyPart == 'NRO. LICENCIA' || keyPart == 'LICENCIA') {
          if (curNum.isNotEmpty && curCat.isNotEmpty) flushCurrent();
          curNum = valPart;
          if (globalLicenseNum.isEmpty) globalLicenseNum = valPart;
          advanceIfStacked();
          continue;
        }
        if (keyPart == 'CATEGORIA') {
          final m = catRegex.firstMatch(valPart.toUpperCase());
          if (m != null) {
            if (curCat.isNotEmpty) flushCurrent();
            curCat = m.group(1)!;
          }
          advanceIfStacked();
          continue;
        }
        if (keyPart == 'ESTADO' || keyPart.contains('ESTADO LICENCIA')) {
          final st = extractLicenseState(valPart);
          if (st.isNotEmpty) curEstado = st;
          advanceIfStacked();
          continue;
        }
        if (keyPart.contains('EXPEDICION')) {
          curExp = valPart;
          advanceIfStacked();
          continue;
        }
        if (keyPart.contains('VENCIMIENTO') || keyPart.contains('VIGENCIA')) {
          curVen = valPart;
          advanceIfStacked();
          continue;
        }
        if (keyPart.contains('ORGANISMO') || keyPart.contains('SECRETARIA')) {
          curOrg = valPart;
          advanceIfStacked();
          continue;
        }
      }

      // Caso tabular en 1 línea: "A2  01/12/2021  01/12/2031"
      final rowCatMatch = catRegex.firstMatch(up);
      final dates = dateRegex.allMatches(line).map((m) => m.group(0)!).toList();
      if (rowCatMatch != null && dates.isNotEmpty) {
        final rowState = extractLicenseState(up);
        records.add(
          DriverLicenseRecord(
            numeroLicencia: globalLicenseNum,
            categoria: rowCatMatch.group(1)!,
            estado: rowState.isNotEmpty ? rowState : globalParentEstado,
            fechaExpedicion: dates.length >= 2 ? dates.first : '',
            fechaVencimiento: dates.last,
          ),
        );
        continue;
      }

      // Caso móvil apilado: línea sola "A2" seguida de fecha expedición y fecha vencimiento
      // (permite encabezados de celda intercalados como "Fecha expedición" / "Fecha vencimiento")
      if (strictCatLineRegex.hasMatch(up)) {
        final nextDates = <String>[];
        for (int j = i + 1; j < lines.length && j <= i + 6; j++) {
          final lNext = lines[j];
          if (strictCatLineRegex.hasMatch(normalizeKey(lNext))) break;
          for (final dm in dateRegex.allMatches(lNext)) {
            nextDates.add(dm.group(0)!);
          }
          if (nextDates.length >= 2) break;
        }
        if (nextDates.length >= 2) {
          records.add(
            DriverLicenseRecord(
              numeroLicencia: globalLicenseNum,
              categoria: up,
              estado: globalParentEstado,
              fechaExpedicion: nextDates.first,
              fechaVencimiento: nextDates.last,
            ),
          );
        } else if (nextDates.length == 1) {
          // Solo asumir fecha única como vencimiento si no está inmediatamente después de etiqueta EXPEDICION
          final prevUp = i + 1 < lines.length ? normalizeKey(lines[i + 1]) : '';
          if (!prevUp.contains('EXPEDICION')) {
            records.add(
              DriverLicenseRecord(
                numeroLicencia: globalLicenseNum,
                categoria: up,
                estado: globalParentEstado,
                fechaExpedicion: '',
                fechaVencimiento: nextDates.first,
              ),
            );
          }
        }
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
