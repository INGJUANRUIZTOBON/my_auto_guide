import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/services/driver_license_parser.dart';
import '../../core/services/notification_service.dart';
import 'app_snack_bar.dart';

/// Consulta ciudadana RUNTPRO por cédula para extraer categorías de licencia de conducción,
/// estado (Activa/Vencida) y fechas de vencimiento abriendo automáticamente "Ver Detalle".
class RuntDriverLicenseWebViewScreen extends StatefulWidget {
  final String cedula;
  final String vehiculoId;

  const RuntDriverLicenseWebViewScreen({
    super.key,
    required this.cedula,
    required this.vehiculoId,
  });

  @override
  State<RuntDriverLicenseWebViewScreen> createState() =>
      _RuntDriverLicenseWebViewScreenState();
}

class _RuntDriverLicenseWebViewScreenState
    extends State<RuntDriverLicenseWebViewScreen> {
  static const String _runtCitizenUrl =
      'https://portalpublico.runt.gov.co/#/consulta-ciudadano-documento/consulta/consulta-ciudadano-documento';

  late final WebViewController _controller;
  bool _loading = true;
  bool _extracting = false;
  RuntDriverProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadLocalCache();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint('[RUNT_LICENCIA] Error WebView: ${error.description}');
            if (mounted) setState(() => _loading = false);
          },
          onPageFinished: (_) async {
            if (mounted) setState(() => _loading = false);
            await _autofillDocument();
          },
        ),
      )
      ..loadRequest(Uri.parse(_runtCitizenUrl));
  }

  /// Solo autocompleta si es cédula numérica real (evita inyectar hashes SHA-256 de 64 caracteres).
  Future<void> _autofillDocument() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPlainDoc = prefs.getString('runt_plain_cedula_global') ?? '';
    final candidate = RegExp(r'^\d{4,15}$').hasMatch(widget.cedula.trim())
        ? widget.cedula.trim()
        : (RegExp(r'^\d{4,15}$').hasMatch(cachedPlainDoc) ? cachedPlainDoc : '');
    if (candidate.isEmpty) return;

    await _controller.runJavaScript('''
      (function fillDoc(attempt) {
        const selectors = [
          'input[formcontrolname*="documento" i]',
          'input[formcontrolname*="numero" i]',
          'input[placeholder*="documento" i]',
          '#txtNumDoc', '#noDocumento', '#numDoc', 'input[name="numDoc"]'
        ];
        let el = null;
        for (const s of selectors) {
          el = document.querySelector(s);
          if (el) break;
        }
        if (el) {
          if (!el.value) {
            el.value = '$candidate';
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
          }
        } else if (attempt < 10) {
          setTimeout(function() { fillDoc(attempt + 1); }, 500);
        }
      })(0);
    ''');
  }

  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('runt_driver_license_profile_${widget.vehiculoId}') ??
          prefs.getString('runt_driver_license_profile_global');
      if (raw != null && raw.isNotEmpty) {
        final parsed = RuntDriverProfile.tryDecodeWebViewResult(raw);
        if (mounted && parsed != null && parsed.licencias.isNotEmpty) {
          setState(() => _profile = parsed);
        }
      }
    } catch (_) {}
  }

  Future<void> _extraerLicencias() async {
    if (_extracting) return;
    setState(() {
      _extracting = true;
      _loading = true;
    });

    try {
      // Etapa 1: Expandir paneles "Licencia(s) de conducción" si están colapsados y llevarlos a vista
      await _controller.runJavaScript(r'''
        (function() {
          function norm(s) {
            return (s || '').toUpperCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/\s+/g, ' ').trim();
          }
          function triggerClick(el) {
            try {
              el.scrollIntoView({ behavior: 'instant', block: 'center' });
              el.click();
              el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
            } catch (_) {}
          }
          function expandDoc(doc) {
            if (!doc || !doc.body) return;
            const candidates = doc.querySelectorAll(
              'mat-expansion-panel-header, [data-toggle="collapse"], [data-bs-toggle="collapse"], .panel-heading, .panel-heading a, .accordion-button, .card-header, [role="button"][aria-expanded], button, h2, h3, h4, h5, span'
            );
            candidates.forEach(function(el) {
              const t = norm(el.innerText || el.textContent || '');
              if (!(t.includes('LICENCIA(S) DE CONDUC') || t.includes('LICENCIAS DE CONDUC'))) return;
              if (t.length > 90) return;

              const header = el.closest('mat-expansion-panel-header') || el;
              const panel = header.closest('mat-expansion-panel, .panel, .accordion-item, .card');
              const isExpanded =
                header.getAttribute('aria-expanded') === 'true' ||
                (panel && (panel.classList.contains('mat-expanded') || panel.classList.contains('show')));
              const alreadyHasTable =
                norm(doc.body.innerText || '').includes('OT EXPIDE LIC') ||
                norm(doc.body.innerText || '').includes('VER DETALLE');

              if (!isExpanded && !alreadyHasTable) {
                triggerClick(header);
              }
            });
          }
          expandDoc(document);
          document.querySelectorAll('iframe').forEach(function(fr) {
            try { if (fr.contentDocument) expandDoc(fr.contentDocument); } catch (_) {}
          });
        })();
      ''');

      await Future.delayed(const Duration(milliseconds: 650));

      // Etapa 2: Abrir "Ver Detalle" para desplegar "Categorías de la licencia"
      await _controller.runJavaScript(r'''
        (function() {
          function norm(s) {
            return (s || '').toUpperCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/\s+/g, ' ').trim();
          }
          function clickVerDetalle(doc) {
            if (!doc || !doc.body) return;
            const bodyUp = norm(doc.body.innerText || '');
            if (bodyUp.includes('CATEGORIAS DE LA LICENCIA')) return;

            const clickables = doc.querySelectorAll('a, button, span, u, div[role="button"], mat-icon, td a, mat-cell a');
            for (const el of clickables) {
              const t = norm(el.innerText || el.textContent || '');
              if (t === 'VER DETALLE' || t.includes('VER DETALLE')) {
                try {
                  el.scrollIntoView({ behavior: 'instant', block: 'center' });
                  el.click();
                  el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
                  break;
                } catch (_) {}
              }
            }
          }
          clickVerDetalle(document);
          document.querySelectorAll('iframe').forEach(function(fr) {
            try { if (fr.contentDocument) clickVerDetalle(fr.contentDocument); } catch (_) {}
          });
        })();
      ''');

      // Polling reactivo hasta 2.0s para esperar que Angular renderice mat-dialog-container
      for (int attempt = 0; attempt < 8; attempt++) {
        await Future.delayed(const Duration(milliseconds: 250));
        final readyRaw = await _controller.runJavaScriptReturningResult(r'''
          (function() {
            function norm(s) {
              return (s || '').toUpperCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
            }
            const t = norm(document.body ? document.body.innerText : '');
            if (t.includes('CATEGORIAS DE LA LICENCIA') ||
                (t.includes('FECHA VENCIMIENTO') && /\b(A1|A2|B1|B2|B3|C1|C2|C3)\b/.test(t))) {
              return 'READY';
            }
            return 'WAIT';
          })();
        ''');
        if (readyRaw.toString().contains('READY')) break;
      }

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
          function norm(s) { return (s || '').replace(/\s+/g, ' ').trim(); }
          function upper(s) {
            return norm(s).toUpperCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
          }
          const out = {
            nombre_conductor: '',
            numero_documento: '',
            estado_conductor: '',
            numero_inscripcion: '',
            licencias: [],
            raw_text: ''
          };

          let parentEstado = '';
          let parentNum = '';
          let parentOrg = '';

          function scrapeDoc(doc) {
            if (!doc || !doc.body) return;
            const textChunk = textOf(doc.body);
            if (textChunk) {
              out.raw_text += (out.raw_text ? '\n' : '') + textChunk;
            }

            // Capturar overlays/diálogos de Angular Material explícitamente si no están en flujo normal
            doc.querySelectorAll('mat-dialog-container, .cdk-overlay-container .mat-mdc-dialog-surface, .modal-content').forEach(function(dlg) {
              const dt = textOf(dlg);
              if (dt) out.raw_text += '\n' + dt;
            });

            const tables = [...doc.querySelectorAll('table, mat-table, [role="table"]')];
            // Primera pasada: capturar tabla principal "Licencia(s) de conducción"
            for (const t of tables) {
              const tUp = upper(textOf(t));
              if (!tUp.includes('OT EXPIDE') && !tUp.includes('NRO LICENCIA') && !tUp.includes('RETENCION')) continue;
              const headers = [...t.querySelectorAll('thead th, tr:first-child th, mat-header-cell, [role="columnheader"]')].map(h => upper(textOf(h)));
              const bodyRows = [...t.querySelectorAll('tbody tr, mat-row, [role="row"]')];
              for (const r of bodyRows) {
                const cols = [...r.querySelectorAll('td, mat-cell, [role="cell"]')].map(c => norm(textOf(c)));
                if (cols.length < 3) continue;
                headers.forEach((h, idx) => {
                  const val = cols[idx] || '';
                  if (!val) return;
                  if ((h.includes('NRO') || h.includes('NUMERO')) && h.includes('LICENCIA') && !parentNum) parentNum = val;
                  if (h === 'ESTADO' && !parentEstado) parentEstado = val;
                  if ((h.includes('OT EXPIDE') || h.includes('ORGANISMO')) && !parentOrg) parentOrg = val;
                });
              }
            }

            // Segunda pasada: capturar tabla "Categorías de la licencia" (con headers O posicional en móvil)
            const catPattern = /^(A1|A2|B1|B2|B3|C1|C2|C3)$/;
            const datePattern = /\b(\d{2}[\/\-]\d{2}[\/\-]\d{4}|\d{4}[\/\-]\d{2}[\/\-]\d{2})\b/;
            for (const t of tables) {
              const tUp = upper(textOf(t));
              const looksLikeCategoryTable =
                (tUp.includes('CATEGORIA') && (tUp.includes('VENCIMIENTO') || tUp.includes('EXPEDICION'))) ||
                (datePattern.test(tUp) && /\b(A1|A2|B1|B2|B3|C1|C2|C3)\b/.test(tUp));
              if (!looksLikeCategoryTable) continue;

              const headers = [...t.querySelectorAll('thead th, tr:first-child th, mat-header-cell, [role="columnheader"]')].map(h => upper(textOf(h)));
              const bodyRows = [...t.querySelectorAll('tbody tr, mat-row, [role="row"]')];
              for (const r of bodyRows) {
                const cellNodes = [...r.querySelectorAll('td, mat-cell, [role="cell"]')];
                const cols = cellNodes.map(c => norm(textOf(c)));
                if (cols.length < 2) continue;

                const rec = {
                  numero_licencia: parentNum,
                  categoria: '',
                  estado: parentEstado,
                  fecha_expedicion: '',
                  fecha_vencimiento: '',
                  organismo_transito: parentOrg
                };

                if (headers.length >= 2) {
                  headers.forEach((h, idx) => {
                    const val = cols[idx] || '';
                    if (!val) return;
                    if (h === 'CATEGORIA' || (h.includes('CATEGORIA') && !h.includes('ANTIGUA'))) rec.categoria = val;
                    else if (h.includes('EXPEDICION')) rec.fecha_expedicion = val;
                    else if (h.includes('VENCIMIENTO') || h.includes('VIGENCIA')) rec.fecha_vencimiento = val;
                    else if (h === 'ESTADO') rec.estado = val;
                  });
                }

                // Fallback si la tabla móvil oculta <thead> o usa columnas posicionales
                if (!rec.categoria && catPattern.test(upper(cols[0]))) {
                  rec.categoria = upper(cols[0]);
                  const dates = cols.slice(1).filter(c => datePattern.test(c));
                  if (dates.length >= 2) {
                    rec.fecha_expedicion = dates[0];
                    rec.fecha_vencimiento = dates[1];
                  } else if (dates.length == 1) {
                    rec.fecha_vencimiento = dates[0];
                  }
                }

                if (rec.categoria && (rec.fecha_vencimiento || rec.fecha_expedicion)) {
                  out.licencias.push(rec);
                }
              }
            }
          }

          scrapeDoc(document);
          document.querySelectorAll('iframe').forEach(function(fr) {
            try { if (fr.contentDocument) scrapeDoc(fr.contentDocument); } catch (_) {}
          });
          return JSON.stringify(out);
        })();
      ''';

      final raw = await _controller.runJavaScriptReturningResult(scraperJs);
      final parsed = RuntDriverProfile.tryDecodeWebViewResult(raw);

      if (parsed == null || parsed.licencias.isEmpty) {
        if (mounted) {
          final hasPersonaVisible = parsed != null &&
              (parsed.estadoConductor.isNotEmpty ||
                  parsed.nombreConductor.isNotEmpty ||
                  parsed.numeroInscripcion.isNotEmpty);
          final msg = hasPersonaVisible
              ? 'Conductor detectado (${parsed.nombreConductor.isNotEmpty ? parsed.nombreConductor : parsed.numeroDocumento}). Desplaza abajo, abre "Licencia(s) de conducción" → toca "Ver Detalle" y vuelve a presionar Extraer.'
              : 'Completa primero la consulta en RUNT (documento, apellido, CAPTCHA y Consultar) hasta ver tu licencia.';
          AppSnackBar.show(
            context,
            msg,
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      await _guardarLicencia(parsed);
      if (mounted) {
        setState(() => _profile = parsed);
        Navigator.pop(context, parsed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _extracting = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _guardarLicencia(RuntDriverProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(profile.toJson());
    await prefs.setString('runt_driver_license_profile_${widget.vehiculoId}', encoded);
    await prefs.setString('runt_driver_license_profile_global', encoded);
    if (RegExp(r'^\d{4,15}$').hasMatch(profile.numeroDocumento)) {
      await prefs.setString('runt_plain_cedula_global', profile.numeroDocumento);
    }

    final earliest = profile.earliestExpiration;
    String? licIso;
    if (earliest != null) {
      licIso = '${earliest.year}-${earliest.month.toString().padLeft(2, '0')}-${earliest.day.toString().padLeft(2, '0')}';
      await prefs.setString('extra_lic_${widget.vehiculoId}', licIso);
      await NotificationService().scheduleLegalNotification(
        id: 9101,
        type: 'Licencia de Conducción',
        dueDate: earliest,
      );
    }

    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid != null && licIso != null) {
        await client
            .from('vehiculos')
            .update({'licencia_vencimiento': licIso})
            .eq('id', widget.vehiculoId)
            .eq('user_id', uid);
      }
    } catch (e) {
      debugPrint('[RUNT_LICENCIA] Guardado local (remoto pendiente): $e');
    }

    if (mounted) {
      final vigentesCount = profile.vigentes.length;
      AppSnackBar.show(
        context,
        'Licencias RUNT guardadas ($vigentesCount vigentes de ${profile.licencias.length}).',
        backgroundColor: const Color(0xFF059669),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: const Color(0xFF06080C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06080C),
        title: const Text('Licencia de Conducción (RUNT)'),
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
          if (_loading) const LinearProgressIndicator(minHeight: 3, color: Color(0xFF00E5FF)),
          Positioned(
            bottom: 18,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profile != null && profile.licencias.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121722).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus licencias detectadas (${profile.vigentes.length} vigentes)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: profile.licencias.map((lic) {
                            final color = lic.isVigente
                                ? const Color(0xFF10B981)
                                : const Color(0xFFFF1744);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: color.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '${lic.categoria} • ${lic.isVigente ? "Vigente" : "Vencida"}'
                                '${lic.fechaVencimiento.isNotEmpty ? " • ${lic.fechaVencimiento}" : ""}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _extracting ? null : _extraerLicencias,
                    icon: _extracting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.badge_rounded),
                    label: Text(
                      _extracting
                          ? 'Extrayendo licencias...'
                          : 'Extraer y Guardar Mis Licencias RUNT',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
