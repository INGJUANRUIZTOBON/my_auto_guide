import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/app_update_service.dart';

/// Modal interactivo para visualizar las novedades y cambios de una actualización
/// tanto en Web como en Android.
class ReleaseNotesDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final bool isAutomaticNotice;

  const ReleaseNotesDialog({
    super.key,
    required this.updateInfo,
    this.isAutomaticNotice = false,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    bool isAutomaticNotice = false,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isAutomaticNotice,
      builder: (ctx) => ReleaseNotesDialog(
        updateInfo: updateInfo,
        isAutomaticNotice: isAutomaticNotice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00E5FF);
    const bgDark = Color(0xFF0F172A);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cyan.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cyan.withValues(alpha: 0.15),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0070F3)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cyan.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'MY AUTO GUIDE',
                              style: TextStyle(
                                color: cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                'v${updateInfo.versionName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAutomaticNotice
                              ? '¡Nueva Actualización Disponible!'
                              : 'Novedades de la Versión',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              // Indicador de Plataformas Sincronizadas
              Row(
                children: [
                  _buildPlatformBadge(
                    icon: Icons.language_rounded,
                    label: 'Web (Vercel)',
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 8),
                  _buildPlatformBadge(
                    icon: Icons.android_rounded,
                    label: 'Android (APK)',
                    color: const Color(0xFF30D158),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contenido con las Notas del Release
              const Text(
                '¿QUÉ HAY DE NUEVO?',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      updateInfo.releaseNotes.trim().isNotEmpty
                          ? updateInfo.releaseNotes
                          : '• Mejoras de rendimiento y estabilidad.\n• Sincronización continua Web y Móvil.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón de Acción
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (kIsWeb) {
                      await AppUpdateService()
                          .markWebVersionAsSeen(updateInfo.versionCode);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    isAutomaticNotice ? '¡Entendido, Comenzar!' : 'Cerrar',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
