// =============================================================================
// runt_webview.dart — CONSULTA Y EXTRACCIÓN COMPLETA RUNT COLOMBIA
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/runt_parser.dart';
import '../../../shared/widgets/app_snack_bar.dart';

class RuntWebViewScreen extends StatefulWidget {
  final String placa;
  final String cedula;
  final String vehiculoId;

  const RuntWebViewScreen({
    super.key,
    required this.placa,
    required this.cedula,
    required this.vehiculoId,
  });

  @override
  State<RuntWebViewScreen> createState() => _RuntWebViewScreenState();
}

class _RuntWebViewScreenState extends State<RuntWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _extracting = false;

  RuntVehicleProfile? _extractedProfile;
  String? _cachedSoat;
  String? _cachedTecno;
  String? _cachedDate;
  bool _hasOfflineCache = false;

  @override
  void initState() {
    super.initState();
    _loadLocalRuntCache();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint('RUNT WebView error: ${error.description}');
            if (mounted && _hasOfflineCache) {
              setState(() => _loading = false);
            }
          },
          onPageFinished: (url) async {
            if (mounted) setState(() => _loading = false);

            // Autocompletar placa y cédula real (nunca inyectar hashes SHA-256) sin tocar el CAPTCHA oficial
            final safeCedula = RegExp(r'^\d{4,15}$').hasMatch(widget.cedula.trim())
                ? widget.cedula.trim()
                : '';
            await _controller.runJavaScript('''
              function fillInputs(attempt) {
                const placaSelectors = [
                  '#txtPlaca', '#placa', 'input[name="placa"]',
                  'input[formcontrolname*="placa" i]',
                  'input[placeholder*="Placa" i]', 'input[ng-model*="placa"]'
                ];
                const docSelectors = [
                  '#txtNumDoc', '#noDocumento', '#numDoc', 'input[name="numDoc"]',
                  'input[formcontrolname*="documento" i]', 'input[formcontrolname*="doc" i]',
                  'input[placeholder*="Documento" i]', 'input[ng-model*="numDoc"]'
                ];

                let placaEl = null;
                for (const sel of placaSelectors) {
                  placaEl = document.querySelector(sel);
                  if (placaEl) break;
                }

                let docEl = null;
                for (const sel of docSelectors) {
                  docEl = document.querySelector(sel);
                  if (docEl) break;
                }

                if (placaEl && !placaEl.value && '${widget.placa}') {
                  placaEl.value = '${widget.placa}';
                  placaEl.dispatchEvent(new Event('input', { bubbles: true }));
                  placaEl.dispatchEvent(new Event('change', { bubbles: true }));
                }
                if (docEl && !docEl.value && '$safeCedula') {
                  docEl.value = '$safeCedula';
                  docEl.dispatchEvent(new Event('input', { bubbles: true }));
                  docEl.dispatchEvent(new Event('change', { bubbles: true }));
                }
                if ((!placaEl || !docEl) && attempt < 10) {
                  setTimeout(function() { fillInputs(attempt + 1); }, 500);
                }
              }
              fillInputs(0);
            ''');
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://www.runt.gov.co/consultaCiudadana/#/consultaVehiculo',
        ),
      );
  }

  /// Expande paneles de RUNT ya consultados y extrae SOAT, RTM y ficha técnica completa.
  Future<void> consultarFichaCompleta() async {
    if (_extracting) return;
    setState(() {
      _extracting = true;
      _loading = true;
    });

    try {
      // 1. Expandir acordeones/paneles colapsados (Bootstrap y Angular Material RUNTPRO) sin colapsar los ya abiertos
      await _controller.runJavaScript('''
        (function() {
          function expandInDoc(doc) {
            const triggers = doc.querySelectorAll(
              '[data-toggle="collapse"], [data-bs-toggle="collapse"], .panel-heading, .panel-heading a, .accordion-button, .accordion-toggle, mat-expansion-panel-header, [role="button"][aria-expanded], button.mat-expansion-panel-header, .mat-expansion-panel-header-title, a[href*="collapse"]'
            );
            triggers.forEach(function(el) {
              const txt = (el.innerText || el.textContent || '').toUpperCase();
              if (
                txt.includes('SOAT') ||
                txt.includes('PÓLIZA') ||
                txt.includes('POLIZA') ||
                txt.includes('SEGURO') ||
                txt.includes('REVISI') ||
                txt.includes('TÉCNIC') ||
                txt.includes('TECNIC') ||
                txt.includes('RTM') ||
                txt.includes('DATOS') ||
                txt.includes('INFORMACI') ||
                txt.includes('GENERAL')
              ) {
                const header = el.closest('mat-expansion-panel-header') || el;
                const panel = el.closest('mat-expansion-panel, .panel, .accordion-item');
                const isExpanded = header.getAttribute('aria-expanded') === 'true' ||
                                   header.classList.contains('mat-expanded') ||
                                   (panel && (panel.classList.contains('mat-expanded') || panel.querySelector('.collapse.in, .collapse.show, .show')));
                if (!isExpanded) {
                  try {
                    header.scrollIntoView({ behavior: 'instant', block: 'center' });
                    header.click();
                    header.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
                  } catch (_) {}
                }
              }
            });

            // Expandir sub-botones "Ver detalle" si existen
            doc.querySelectorAll('button, a, span').forEach(function(btn) {
              const bTxt = (btn.innerText || btn.textContent || '').toUpperCase().trim();
              if (bTxt === 'VER DETALLE' || bTxt === 'DETALLE' || bTxt === '+' || bTxt === 'VER MAS') {
                try {
                  btn.click();
                  btn.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
                } catch (_) {}
              }
            });
          }
          expandInDoc(document);
          document.querySelectorAll('iframe').forEach(function(fr) {
            try { if (fr.contentDocument) expandInDoc(fr.contentDocument); } catch (_) {}
          });
        })();
      ''');

      // Dar tiempo suficiente (1.8s) a los servicios AJAX asíncronos de RUNT para retornar las pólizas y CDA
      await Future.delayed(const Duration(milliseconds: 1800));

      // 2. Extraer campos DOM, tablas HTML/Angular Material y raw_text para fallback multipaso
      const scraperJs = r'''
        (function() {
          function textOf(el) {
            if (!el) return '';
            const clone = el.cloneNode(true);
            clone.querySelectorAll('mat-icon, .material-icons, .material-icons-outlined, svg').forEach(function(ic) {
              ic.remove();
            });
            return (clone.innerText || clone.textContent || '');
          }
          function norm(s) {
            return (s || '')
              .replace(/\b(check_circle_outline|check_circle|car_crash|error_outline|cancel|warning|verified|info)\b/gi, '')
              .replace(/\s+/g, ' ')
              .trim();
          }
          function upper(s) {
            return norm(s).toUpperCase()
              .normalize('NFD').replace(/[\u0300-\u036f]/g, '');
          }

          const out = {
            marca: '', linea: '', modelo_ano: '', color: '', clase: '',
            servicio: '', estado_vehiculo: '', cilindraje: '', combustible: '',
            vin: '', numero_motor: '', numero_chasis: '', gravamenes: '',
            organismo_transito: '',
            soat_estado: '', soat_aseguradora: '', soat_poliza: '',
            soat_expedicion: '', soat_inicio_vigencia: '', soat_vencimiento: '',
            tecno_estado: '', tecno_certificado: '', tecno_cda: '',
            tecno_expedicion: '', tecno_inicio_vigencia: '', tecno_vencimiento: '',
            raw_text: ''
          };

          function assignPair(rawLabel, rawVal) {
            const k = upper(rawLabel).replace(/:$/, '').trim();
            const v = norm(rawVal);
            if (!k || !v || v.endsWith(':') || v.length > 140) return;

            if (!out.marca && (k === 'MARCA' || k.startsWith('MARCA:') || k.includes('MARCA'))) out.marca = v;
            else if (!out.linea && (k === 'LINEA' || k.includes('LINEA'))) out.linea = v;
            else if (!out.modelo_ano && (k === 'MODELO' || k === 'ANO MODELO' || k.includes('MODELO'))) out.modelo_ano = v;
            else if (!out.color && k.includes('COLOR')) out.color = v;
            else if (!out.clase && (k === 'CLASE' || k.startsWith('CLASE') || k.includes('CLASE') || k.includes('TIPO DE VEHICULO'))) out.clase = v;
            else if (!out.servicio && (k === 'SERVICIO' || k.startsWith('SERVICIO') || k.includes('SERVICIO') || k.includes('MODALIDAD'))) out.servicio = v;
            else if (!out.estado_vehiculo && (k.includes('ESTADO') && (k.includes('VEHICULO') || k.includes('AUTOMOTOR')))) out.estado_vehiculo = v;
            else if (!out.cilindraje && k.includes('CILINDRA')) out.cilindraje = v;
            else if (!out.combustible && k.includes('COMBUSTIBLE')) out.combustible = v;
            else if (!out.vin && (k === 'VIN' || k.includes('VIN'))) out.vin = v;
            else if (!out.numero_motor && (k.includes('MOTOR') || k.includes('NUMERO DE MOTOR'))) out.numero_motor = v;
            else if (!out.numero_chasis && (k.includes('CHASIS') || k.includes('SERIE') || k.includes('NUMERO DE CHASIS'))) out.numero_chasis = v;
            else if (!out.gravamenes && (k.includes('GRAVAMEN') || k.includes('PRENDA') || k.includes('LIMITACION'))) out.gravamenes = v;
            else if (!out.organismo_transito && (k.includes('ORGANISMO') || k.includes('SECRETARIA') || k.includes('TRANSITO'))) out.organismo_transito = v;
          }

          function scrapeDoc(doc) {
            if (!doc || !doc.body) return;
            const textChunk = textOf(doc.body);
            if (textChunk) {
              out.raw_text += (out.raw_text ? '\n' : '') + textChunk;
            }

            // 2A. Pares inline tipo "Marca: BAJAJ" o stacked en contenedores
            doc.querySelectorAll('p, span, div, li').forEach(function(el) {
              if (el.children.length > 2) return;
              const txt = norm(textOf(el));
              const idx = txt.indexOf(':');
              if (idx > 1 && idx < txt.length - 1 && idx < 45) {
                assignPair(txt.slice(0, idx), txt.slice(idx + 1));
              }
            });

            // 2B. Pares label/valor en bloques Bootstrap/Angular
            doc.querySelectorAll('label, .control-label, th, strong').forEach(function(lbl) {
              const nextEl = lbl.nextElementSibling;
              if (nextEl && !nextEl.querySelector('table')) {
                const input = nextEl.querySelector('input, select') || nextEl;
                const val = input.value !== undefined && input.value !== '' ? input.value : textOf(nextEl);
                assignPair(textOf(lbl), val);
              }
            });

            // 2C. Tablas HTML y Angular Material (<mat-table> / [role="table"])
            const tableSelectors = 'table, mat-table, [role="table"]';
            const tables = [...doc.querySelectorAll(tableSelectors)];
            for (const t of tables) {
              const tableText = upper(textOf(t));
              const rows = [...t.querySelectorAll('tr, mat-row, [role="row"]')];

              for (const r of rows) {
                const cells = [...r.querySelectorAll('th, td, mat-cell, [role="cell"]')];
                if (cells.length === 2) {
                  assignPair(textOf(cells[0]), textOf(cells[1]));
                }
              }

              let headerEls = [...t.querySelectorAll('thead th, thead td, mat-header-cell, [role="columnheader"]')];
              if (headerEls.length === 0 && rows.length > 0) {
                headerEls = [...rows[0].querySelectorAll('th, td')];
              }
              const headers = headerEls.map(h => upper(textOf(h)));
              const bodyRows = [...t.querySelectorAll('tbody tr, mat-row')];

              // Identificar la fila VIGENTE o más reciente
              let targetSoatRow = null;
              let targetTecnoRow = null;
              const candidateRows = bodyRows.length > 0 ? bodyRows : (rows.length > 1 ? rows.slice(1) : rows);

              for (const r of candidateRows) {
                const rTxt = upper(textOf(r));
                if ((rTxt.includes('VIGENTE') || rTxt.includes('ACTIVA')) && !targetSoatRow) {
                  targetSoatRow = r;
                }
                if ((rTxt.includes('VIGENTE') || rTxt.includes('ACTIVA')) && !targetTecnoRow) {
                  targetTecnoRow = r;
                }
              }
              if (!targetSoatRow && candidateRows.length > 0) targetSoatRow = candidateRows[0];
              if (!targetTecnoRow && candidateRows.length > 0) targetTecnoRow = candidateRows[0];

              if ((tableText.includes('SOAT') || tableText.includes('POLIZA')) && targetSoatRow) {
                const cols = [...targetSoatRow.querySelectorAll('td, mat-cell, [role="cell"]')].map(c => norm(textOf(c)));
                headers.forEach((h, idx) => {
                  const val = cols[idx] || '';
                  if (!val) return;
                  if (h.includes('POLIZA') && !out.soat_poliza) out.soat_poliza = val;
                  if ((h.includes('ASEGURADORA') || h.includes('ENTIDAD')) && !out.soat_aseguradora) out.soat_aseguradora = val;
                  if (h.includes('ESTADO') && !out.soat_estado) out.soat_estado = val;
                  if ((h.includes('INICIO') || h.includes('DESDE')) && !out.soat_inicio_vigencia) out.soat_inicio_vigencia = val;
                  else if (h.includes('EXPEDICION') && !out.soat_expedicion) out.soat_expedicion = val;
                  else if ((h.includes('FIN VIGENCIA') || h.includes('FIN DE VIGENCIA') || h.includes('VENCIMIENTO') || h.includes('HASTA')) && !out.soat_vencimiento) out.soat_vencimiento = val;
                });
                if (!out.soat_vencimiento) {
                  for (const r of candidateRows) {
                    const rTxt = upper(textOf(r));
                    const dates = rTxt.match(/\b(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}|\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2})\b/g);
                    if (dates && dates.length > 0 && (rTxt.includes('FIN') || rTxt.includes('VENCIMIENTO') || rTxt.includes('HASTA') || rTxt.includes('VIGENTE'))) {
                      if (!out.soat_inicio_vigencia && dates.length >= 2) out.soat_inicio_vigencia = dates[0];
                      out.soat_vencimiento = dates[dates.length - 1];
                      break;
                    }
                  }
                }
              }

              if ((tableText.includes('RTM') || tableText.includes('TECNICO') || tableText.includes('REVISION') || tableText.includes('TECNICOMECANICA')) && targetTecnoRow) {
                const cols = [...targetTecnoRow.querySelectorAll('td, mat-cell, [role="cell"]')].map(c => norm(textOf(c)));
                headers.forEach((h, idx) => {
                  const val = cols[idx] || '';
                  if (!val) return;
                  if ((h.includes('CERTIFICADO') || h.includes('NUMERO')) && !out.tecno_certificado) out.tecno_certificado = val;
                  if ((h.includes('CDA') || h.includes('CENTRO')) && !out.tecno_cda) out.tecno_cda = val;
                  if (h.includes('ESTADO') && !out.tecno_estado) out.tecno_estado = val;
                  if ((h.includes('INICIO') || h.includes('DESDE')) && !out.tecno_inicio_vigencia) out.tecno_inicio_vigencia = val;
                  else if (h.includes('EXPEDICION') && !out.tecno_expedicion) out.tecno_expedicion = val;
                  else if ((h.includes('FIN DE VIGENCIA') || h.includes('FIN VIGENCIA') || h.includes('VIGENTE') || h.includes('VIGENCIA') || h.includes('VENCIMIENTO') || h.includes('HASTA')) && !out.tecno_vencimiento) out.tecno_vencimiento = val;
                });
                if (!out.tecno_vencimiento) {
                  for (const r of candidateRows) {
                    const rTxt = upper(textOf(r));
                    const dates = rTxt.match(/\b(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}|\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2})\b/g);
                    if (dates && dates.length > 0 && (rTxt.includes('VENCIMIENTO') || rTxt.includes('HASTA') || rTxt.includes('VIGENTE'))) {
                      if (!out.tecno_inicio_vigencia && dates.length >= 2) out.tecno_inicio_vigencia = dates[0];
                      out.tecno_vencimiento = dates[dates.length - 1];
                      break;
                    }
                  }
                }
              }
            }

            // 2D. Búsqueda en tarjetas/bloques expansibles si RUNT no usó <table>
            doc.querySelectorAll('.mat-expansion-panel, .panel, .card, mat-card, .accordion-item, div[id*="soat" i], div[id*="rtm" i], div[id*="tecno" i]').forEach(function(card) {
              const cText = upper(textOf(card));
              const isSoat = cText.includes('SOAT') || cText.includes('POLIZA');
              const isTecno = cText.includes('TECNICO') || cText.includes('TECNICOMECANICA') || cText.includes('RTM') || cText.includes('REVISION');

              if (isSoat && !out.soat_vencimiento) {
                const dates = cText.match(/\b(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}|\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2})\b/g);
                if (dates && dates.length > 0) {
                  if (dates.length >= 2 && !out.soat_inicio_vigencia) out.soat_inicio_vigencia = dates[0];
                  out.soat_vencimiento = dates[dates.length - 1];
                  if (cText.includes('VIGENTE') && !out.soat_estado) out.soat_estado = 'VIGENTE';
                }
              }

              if (isTecno && !out.tecno_vencimiento) {
                const dates = cText.match(/\b(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}|\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2})\b/g);
                if (dates && dates.length > 0) {
                  if (dates.length >= 2 && !out.tecno_inicio_vigencia) out.tecno_inicio_vigencia = dates[0];
                  out.tecno_vencimiento = dates[dates.length - 1];
                  if (cText.includes('VIGENTE') && !out.tecno_estado) out.tecno_estado = 'VIGENTE';
                }
              }
            });
          }

          scrapeDoc(document);
          document.querySelectorAll('iframe').forEach(function(fr) {
            try { if (fr.contentDocument) scrapeDoc(fr.contentDocument); } catch (_) {}
          });

          return JSON.stringify(out);
        })();
      ''';

      final rawResult = await _controller.runJavaScriptReturningResult(scraperJs);
      final profile = RuntVehicleProfile.tryDecodeWebViewResult(rawResult);

      if (mounted) {
        setState(() {
          _extractedProfile = profile;
          _loading = false;
        });
      }

      await _guardarFicha(profile);
    } finally {
      if (mounted) {
        setState(() {
          _extracting = false;
          _loading = false;
        });
      }
    }
  }

  /// Guarda fechas y ficha completa RUNT en Supabase y caché local Offline.
  Future<void> _guardarFicha(RuntVehicleProfile? profile) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) AppSnackBar.show(context, 'Error: Usuario no autenticado');
      return;
    }

    if (profile == null || !profile.hasAnyData) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Completa primero la consulta en el RUNT (CAPTCHA y botón Consultar) y vuelve a intentar.',
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    // Guardamos en last_soat / last_tecno la fecha de INICIO DE VIGENCIA / expedición
    // (o fin de vigencia - 1 año si RUNT no mostró fecha de inicio) para cálculos precisos.
    final soatIso = RuntVehicleProfile.resolveStartIsoDate(
      inicio: profile.soatInicioVigencia,
      expedicion: profile.soatExpedicion,
      vencimiento: profile.soatVencimiento,
    );
    final tecnoIso = RuntVehicleProfile.resolveStartIsoDate(
      inicio: profile.tecnoInicioVigencia,
      expedicion: profile.tecnoExpedicion,
      vencimiento: profile.tecnoVencimiento,
    );

    final baseUpdate = <String, dynamic>{};
    if (soatIso != null) baseUpdate['last_soat'] = soatIso;
    if (tecnoIso != null) baseUpdate['last_tecno'] = tecnoIso;
    if (widget.placa.isNotEmpty) baseUpdate['placa'] = widget.placa;
    if (widget.cedula.isNotEmpty) baseUpdate['cedula'] = widget.cedula;

    final fullUpdate = <String, dynamic>{
      ...baseUpdate,
      'runt_data': profile.toJson(),
      'runt_last_check': DateTime.now().toIso8601String(),
    };

    bool savedRemoteRunt = false;
    try {
      try {
        await supabase
            .from('vehiculos')
            .update(fullUpdate)
            .eq('id', widget.vehiculoId)
            .eq('user_id', userId);
        savedRemoteRunt = true;
      } on PostgrestException catch (e) {
        // Fallback automático si el usuario aún no agregó la columna JSONB runt_data
        debugPrint('Aviso RUNT fallback a columnas base: ${e.message}');
        if (baseUpdate.isNotEmpty) {
          await supabase
              .from('vehiculos')
              .update(baseUpdate)
              .eq('id', widget.vehiculoId)
              .eq('user_id', userId);
        }
      }

      // Caché Offline completa en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'runt_full_data_${widget.vehiculoId}',
        jsonEncode(profile.toJson()),
      );
      if (profile.effectiveSoatVencimiento.isNotEmpty) {
        await prefs.setString(
          'runt_cached_soat_${widget.vehiculoId}',
          profile.effectiveSoatVencimiento,
        );
      }
      if (profile.effectiveTecnoVencimiento.isNotEmpty) {
        await prefs.setString(
          'runt_cached_tecno_${widget.vehiculoId}',
          profile.effectiveTecnoVencimiento,
        );
      }
      await prefs.setString(
        'runt_cached_date_${widget.vehiculoId}',
        DateTime.now().toIso8601String(),
      );

      if (mounted) {
        if (savedRemoteRunt) {
          AppSnackBar.show(
            context,
            'Ficha RUNT guardada y sincronizada en la nube',
            backgroundColor: const Color(0xFF059669),
          );
        } else {
          AppSnackBar.show(
            context,
            'Fechas guardadas. Ejecuta la migración SQL en Supabase para sincronizar la ficha completa en todos tus celulares.',
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error actualizando ficha RUNT en Supabase: $e');
      if (mounted) AppSnackBar.show(context, 'Error guardando ficha RUNT: $e');
    }
  }

  Future<void> _loadLocalRuntCache() async {
    try {
      // 1. Intentar cargar desde Supabase si hay conexión y sesión activa
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null && widget.vehiculoId.isNotEmpty) {
        final res = await supabase
            .from('vehiculos')
            .select('runt_data, runt_last_check')
            .eq('id', widget.vehiculoId)
            .eq('user_id', userId)
            .maybeSingle();
        final remoteData = res?['runt_data'];
        if (remoteData != null) {
          final p = remoteData is Map
              ? RuntVehicleProfile.fromMap(Map<String, dynamic>.from(remoteData))
              : RuntVehicleProfile.tryDecodeWebViewResult(remoteData.toString());
          if (mounted && p != null && p.hasAnyData) {
            setState(() {
              _extractedProfile = p;
              _cachedSoat = p.effectiveSoatVencimiento.isNotEmpty ? p.effectiveSoatVencimiento : null;
              _cachedTecno = p.effectiveTecnoVencimiento.isNotEmpty ? p.effectiveTecnoVencimiento : null;
              _cachedDate = res?['runt_last_check']?.toString();
              _hasOfflineCache = true;
            });
            return;
          }
        }
      }

      // 2. Fallback a SharedPreferences local si está offline
      final prefs = await SharedPreferences.getInstance();
      final soat = prefs.getString('runt_cached_soat_${widget.vehiculoId}');
      final tecno = prefs.getString('runt_cached_tecno_${widget.vehiculoId}');
      final date = prefs.getString('runt_cached_date_${widget.vehiculoId}');
      final fullRaw = prefs.getString('runt_full_data_${widget.vehiculoId}');
      if (soat != null || tecno != null || fullRaw != null) {
        if (mounted) {
          setState(() {
            _cachedSoat = soat;
            _cachedTecno = tecno;
            _cachedDate = date;
            if (fullRaw != null) {
              _extractedProfile = RuntVehicleProfile.tryDecodeWebViewResult(fullRaw);
            }
            _hasOfflineCache = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error leyendo caché RUNT local: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _extractedProfile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta RUNT Oficial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading && !_hasOfflineCache)
            const Center(child: CircularProgressIndicator()),
          if (_hasOfflineCache)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Card(
                color: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.offline_bolt_rounded,
                          color: Color(0xFF38BDF8), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Último RUNT${_cachedDate != null ? " (${_cachedDate!.split("T").first})" : ""}: '
                          'SOAT ${_cachedSoat ?? "N/D"} • Tecno ${_cachedTecno ?? "N/D"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _extracting ? null : consultarFichaCompleta,
                  icon: _extracting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_done_rounded),
                  label: Text(
                    _extracting
                        ? 'Extrayendo ficha completa...'
                        : 'Extraer y Guardar Toda la Ficha RUNT',
                  ),
                ),
                if (p != null && p.hasAnyData) ...[
                  const SizedBox(height: 10),
                  Card(
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.marca.isNotEmpty || p.linea.isNotEmpty)
                            Text(
                              '${p.marca} ${p.linea} ${p.modeloAno}'.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (p.soatVencimiento.isNotEmpty)
                            Text(
                              'SOAT vence: ${p.soatVencimiento}${p.soatAseguradora.isNotEmpty ? " (${p.soatAseguradora})" : ""}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          if (p.tecnoVencimiento.isNotEmpty)
                            Text(
                              'Tecnomecánica vence: ${p.tecnoVencimiento}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
