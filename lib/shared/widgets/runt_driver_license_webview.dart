import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/driver_license_parser.dart';
import '../../core/services/notification_service.dart';
import 'app_snack_bar.dart';

import 'package:webview_flutter/webview_flutter.dart';

/// Consulta ciudadana RUNTPRO por cédula para extraer categorías de licencia de conducción,
/// estado (Activa/Vencida) y fechas de vencimiento.
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

  Future<void> _autofillDocument() async {
    if (widget.cedula.trim().isEmpty) return;
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
            el.value = '${widget.cedula}';
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
        if (mounted && parsed != null && parsed.hasAnyData) {
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
      await _controller.runJavaScript('''
        (function() {
          function expandInDoc(doc) {
            const triggers = doc.querySelectorAll(
              '[data-toggle="collapse"], [data-bs-toggle="collapse"], .panel-heading a, .accordion-button, mat-expansion-panel-header, [role="button"][aria-expanded]'
            );
            triggers.forEach(function(el) {
              const txt = (el.innerText || el.textContent || '').toUpperCase();
              if (
                txt.includes('LICENCIA') ||
                txt.includes('CONDUC') ||
                txt.includes('DATOS') ||
                txt.includes('HISTOR') ||
                txt.includes('CERTIFICADO') ||
                txt.includes('PASE')
              ) {
                const expanded = el.getAttribute('aria-expanded');
                if (expanded !== 'true') {
                  try { el.click(); } catch (_) {}
                }
              }
            });
          }
          expandInDoc(document);
          document.querySelectorAll('iframe').forEach(function(fr) {
            try { if (fr.contentDocument) expandInDoc(fr.contentDocument); } catch (_) {}
          });
        })();
      ''');

      await Future.delayed(const Duration(milliseconds: 900));

      const scraperJs = r'''
        (function() {
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

          function scrapeDoc(doc) {
            if (!doc || !doc.body) return;
            const textChunk = doc.body.innerText || doc.body.textContent || '';
            if (textChunk) {
              out.raw_text += (out.raw_text ? '\n' : '') + textChunk;
            }

            const tables = [...doc.querySelectorAll('table, mat-table, [role="table"]')];
            for (const t of tables) {
              const tUp = upper(t.innerText);
              if (!tUp.includes('CATEGORIA') && !tUp.includes('LICENCIA') && !tUp.includes('VENCIMIENTO')) continue;
              const headers = [...t.querySelectorAll('thead th, tr:first-child th, mat-header-cell, [role="columnheader"]')].map(h => upper(h.innerText));
              const bodyRows = [...t.querySelectorAll('tbody tr, mat-row, [role="row"]')];
              for (const r of bodyRows) {
                const cols = [...r.querySelectorAll('td, mat-cell, [role="cell"]')].map(c => norm(c.innerText));
                if (cols.length < 2) continue;
                const rec = {
                  numero_licencia: '',
                  categoria: '',
                  estado: '',
                  fecha_expedicion: '',
                  fecha_vencimiento: '',
                  organismo_transito: ''
                };
                headers.forEach((h, idx) => {
                  const val = cols[idx] || '';
                  if (!val) return;
                  if (h.includes('LICENCIA') || h.includes('NUMERO')) rec.numero_licencia = val;
                  else if (h.includes('CATEGORIA')) rec.categoria = val;
                  else if (h.includes('ESTADO')) rec.estado = val;
                  else if (h.includes('EXPEDICION')) rec.fecha_expedicion = val;
                  else if (h.includes('VENCIMIENTO') || h.includes('VIGENCIA')) rec.fecha_vencimiento = val;
                  else if (h.includes('ORGANISMO') || h.includes('TRANSITO')) rec.organismo_transito = val;
                });
                if (rec.categoria || rec.fecha_vencimiento || rec.numero_licencia) {
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

      if (parsed == null || !parsed.hasAnyData) {
        if (mounted) {
          AppSnackBar.show(
            context,
            'Completa primero tu documento, apellido, CAPTCHA y Consultar en RUNT.',
            backgroundColor: Colors.orange,
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
      appBar: AppBar(
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
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          Positioned(
            bottom: 18,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profile != null && profile.licencias.isNotEmpty)
                  Card(
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: profile.licencias.map((lic) {
                          final color = lic.isVigente
                              ? const Color(0xFF10B981)
                              : Colors.redAccent;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '${lic.categoria} • ${lic.isVigente ? "Vigente" : "No vigente"}'
                              '${lic.fechaVencimiento.isNotEmpty ? " (${lic.fechaVencimiento})" : ""}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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
