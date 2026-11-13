import 'package:flutter/material.dart';

/// Shell responsivo para MY AUTO GUIDE Web y Desktop.
/// En pantallas anchas (>= 900px), presenta una barra lateral (Sidebar)
/// con diseño Glassmorphism Cyberpunk (#0A0E1A) que se expande al 100% del viewport.
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
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  State<WebAdaptiveScaffold> createState() => _WebAdaptiveScaffoldState();
}

class _WebAdaptiveScaffoldState extends State<WebAdaptiveScaffold> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
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

        // Desktop / Pantallas Grandes (>= 900px): Sidebar Glassmorphism + 100% Body
        final sidebarWidth = _isSidebarCollapsed ? 80.0 : 260.0;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          body: Row(
            children: [
              // 1. Barra Lateral (Sidebar)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: sidebarWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                  border: const Border(
                    right: BorderSide(color: Colors.white10, width: 1),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 16,
                      offset: Offset(4, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Header con Logo y Botón Colapsar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0070F3)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_car_filled_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                          if (!_isSidebarCollapsed) ...[
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MY AUTO GUIDE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'Web Telemetry Console',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
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
                              color: Colors.white54,
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
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF00E5FF),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.vehiclePlate} • ${widget.vehicleBrand ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white70,
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

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10, height: 1),
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
                            onTap: () {
                              widget.onNavigationChanged?.call(0);
                            },
                          ),
                          _buildNavItem(
                            icon: Icons.directions_car_rounded,
                            label: 'Mi Garaje',
                            isSelected: widget.selectedIndex == 1,
                            onTap: widget.onOpenGaraje,
                          ),
                          _buildNavItem(
                            icon: Icons.satellite_alt_rounded,
                            label: 'Telemetría GPS',
                            isSelected: widget.selectedIndex == 2,
                            accentColor: const Color(0xFF00E5FF),
                            onTap: widget.onOpenTelemetry,
                          ),
                          _buildNavItem(
                            icon: Icons.auto_awesome,
                            label: 'IA Experto',
                            isSelected: widget.selectedIndex == 3,
                            accentColor: const Color(0xFFFFD60A),
                            onTap: widget.onOpenAiChat,
                          ),
                          _buildNavItem(
                            icon: Icons.picture_as_pdf_rounded,
                            label: 'Reporte PDF',
                            isSelected: false,
                            onTap: widget.onGenerateReport,
                          ),
                          _buildNavItem(
                            icon: Icons.lock_reset_rounded,
                            label: 'Seguridad',
                            isSelected: false,
                            onTap: widget.onChangePassword,
                          ),
                        ],
                      ),
                    ),

                    // Footer Usuario y Cerrar Sesión
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildNavItem(
                        icon: Icons.logout_rounded,
                        label: 'Cerrar Sesión',
                        isSelected: false,
                        accentColor: Colors.redAccent,
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
    required VoidCallback onTap,
  }) {
    final effectiveColor =
        accentColor ?? (isSelected ? const Color(0xFF00E5FF) : Colors.white70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3))
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
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
