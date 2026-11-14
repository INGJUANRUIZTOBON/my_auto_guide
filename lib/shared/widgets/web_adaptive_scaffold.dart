import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/app_update_service.dart';
import '../../features/updater/presentation/release_notes_dialog.dart';

/// Shell responsivo para MY AUTO GUIDE Web y Desktop.
/// En pantallas anchas (>= 900px), presenta una barra lateral (Sidebar)
/// con diseño Glassmorphism adaptativo y soporte completo de Modo Claro / Modo Oscuro.
/// En dispositivos móviles (< 900px), mantiene la interfaz nativa táctil.
class WebAdaptiveScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final String? vehiclePlate;
  final String? vehicleBrand;
  final String? vehicleModel;
  final int selectedIndex;
  final ValueChanged<int>? onNavigationChanged;
  final VoidCallback onOpenGaraje;
  final VoidCallback onOpenTelemetry;
  final VoidCallback onOpenAiChat;
  final VoidCallback onGenerateReport;
  final VoidCallback onShowReleaseNotes;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const WebAdaptiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.vehiclePlate,
    this.vehicleBrand,
    this.vehicleModel,
    this.selectedIndex = 0,
    this.onNavigationChanged,
    required this.onOpenGaraje,
    required this.onOpenTelemetry,
    required this.onOpenAiChat,
    required this.onGenerateReport,
    required this.onShowReleaseNotes,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  State<WebAdaptiveScaffold> createState() => _WebAdaptiveScaffoldState();
}

class _WebAdaptiveScaffoldState extends State<WebAdaptiveScaffold> {
  bool _isSidebarCollapsed = false;
  Timer? _webUpdateTimer;
  AppUpdateInfo? _pendingUpdate;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkUpdate();
      _webUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) => _checkUpdate());
    }
  }

  Future<void> _checkUpdate() async {
    try {
      final update = await AppUpdateService().checkForUpdate();
      if (mounted && update != null && update.versionCode != _pendingUpdate?.versionCode) {
        setState(() {
          _pendingUpdate = update;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _webUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (!isDesktop) {
          // Móvil: Scaffold estándar nativo
          return Scaffold(
            appBar: widget.appBar,
            body: widget.body,
            floatingActionButton: widget.floatingActionButton,
          );
        }

        // Desktop / Pantallas Grandes (>= 900px)
        final sidebarWidth = _isSidebarCollapsed ? 80.0 : 260.0;
        final scaffoldBg = isDark ? const Color(0xFF080C14) : const Color(0xFFF1F5F9);
        final sidebarBg = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white;
        final sidebarBorder = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
        final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
        final subtitleColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: Row(
            children: [
              // 1. Barra Lateral (Sidebar)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: sidebarWidth,
                decoration: BoxDecoration(
                  color: sidebarBg,
                  border: Border(
                    right: BorderSide(color: sidebarBorder, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Header con Logo Oficial y Botón Colapsar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: subtitleColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 38,
                              height: 38,
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (!_isSidebarCollapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MY AUTO GUIDE',
                                    style: TextStyle(
                                      color: primaryText,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'Web Telemetry Console',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          IconButton(
                            icon: Icon(
                              _isSidebarCollapsed
                                  ? Icons.chevron_right_rounded
                                  : Icons.chevron_left_rounded,
                              color: isDark ? Colors.white54 : Colors.black45,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isSidebarCollapsed = !_isSidebarCollapsed;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    if (!_isSidebarCollapsed && widget.vehiclePlate != null) ...[
                      const SizedBox(height: 16),
                      // Pill del Vehículo Activo
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: subtitleColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.vehiclePlate} • ${widget.vehicleBrand ?? ''}',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Banner Dinámico de Actualización Web Pendiente
                    if (_pendingUpdate != null && !_isSidebarCollapsed)
                      Container(
                        margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
                        child: InkWell(
                          onTap: () {
                            ReleaseNotesDialog.show(
                              context,
                              updateInfo: _pendingUpdate!,
                              isAutomaticNotice: true,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.rocket_launch_rounded, color: Color(0xFF00E5FF), size: 15),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'v${_pendingUpdate!.versionName} Lista',
                                    style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF), size: 13),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    Divider(color: sidebarBorder, height: 1),
                    const SizedBox(height: 12),

                    // Opciones de Navegación
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          _buildNavItem(
                            icon: Icons.dashboard_rounded,
                            label: 'Dashboard',
                            isSelected: widget.selectedIndex == 0,
                            isDark: isDark,
                            onTap: () {
                              widget.onNavigationChanged?.call(0);
                            },
                          ),
                          _buildNavItem(
                            icon: Icons.garage_rounded,
                            label: 'Mi Garaje',
                            isSelected: widget.selectedIndex == 1,
                            accentColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB),
                            isDark: isDark,
                            onTap: widget.onOpenGaraje,
                          ),
                          _buildNavItem(
                            icon: Icons.satellite_alt_rounded,
                            label: 'Telemetría GPS',
                            isSelected: widget.selectedIndex == 2,
                            accentColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB),
                            isDark: isDark,
                            onTap: widget.onOpenTelemetry,
                          ),
                          _buildNavItem(
                            icon: Icons.auto_awesome,
                            label: 'IA Experto',
                            isSelected: widget.selectedIndex == 3,
                            accentColor: const Color(0xFFFFD60A),
                            isDark: isDark,
                            onTap: widget.onOpenAiChat,
                          ),
                          _buildNavItem(
                            icon: Icons.picture_as_pdf_rounded,
                            label: 'Reporte PDF',
                            isSelected: false,
                            isDark: isDark,
                            onTap: widget.onGenerateReport,
                          ),
                          _buildNavItem(
                            icon: Icons.auto_awesome_motion_rounded,
                            label: 'Novedades',
                            isSelected: false,
                            accentColor: const Color(0xFF30D158),
                            isDark: isDark,
                            onTap: widget.onShowReleaseNotes,
                          ),
                          _buildNavItem(
                            icon: Icons.lock_reset_rounded,
                            label: 'Seguridad',
                            isSelected: false,
                            isDark: isDark,
                            onTap: widget.onChangePassword,
                          ),
                        ],
                      ),
                    ),

                    // Selector Explícito de Tema (Punto 5 Opción A)
                    Divider(color: sidebarBorder, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return _buildNavItem(
                            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            label: isDark ? 'Modo Claro' : 'Modo Oscuro',
                            isSelected: false,
                            accentColor: isDark ? const Color(0xFFFFD60A) : const Color(0xFF6366F1),
                            isDark: isDark,
                            onTap: () {
                              themeProvider.toggleTheme(context);
                            },
                          );
                        },
                      ),
                    ),

                    // Footer Usuario y Cerrar Sesión
                    Divider(color: sidebarBorder, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildNavItem(
                        icon: Icons.logout_rounded,
                        label: 'Cerrar Sesión',
                        isSelected: false,
                        accentColor: Colors.redAccent,
                        isDark: isDark,
                        onTap: widget.onLogout,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Área Principal de Contenido (100% de la Pantalla)
              Expanded(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: widget.appBar,
                  body: widget.body,
                  floatingActionButton: widget.floatingActionButton,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    Color? accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final defaultColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final activeColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB);
    final effectiveColor = accentColor ?? (isSelected ? activeColor : defaultColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.12) : const Color(0xFF2563EB).withValues(alpha: 0.10))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFF2563EB).withValues(alpha: 0.30),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            if (!_isSidebarCollapsed) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
