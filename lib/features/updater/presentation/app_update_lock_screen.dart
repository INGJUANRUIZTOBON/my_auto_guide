import 'package:flutter/material.dart';
import '../../../core/services/app_update_service.dart';

class AppUpdateLockScreen extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateLockScreen({
    super.key,
    required this.updateInfo,
  });

  @override
  State<AppUpdateLockScreen> createState() => _AppUpdateLockScreenState();
}

class _AppUpdateLockScreenState extends State<AppUpdateLockScreen> with SingleTickerProviderStateMixin {
  final _updateService = AppUpdateService();

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = '';
  String? _extractedApkPath;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _iniciarActualizacion() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.05;
      _statusText = 'Iniciando descarga...';
      _errorMessage = null;
    });

    final apkPath = await _updateService.downloadAndExtractApk(
      zipUrl: widget.updateInfo.zipUrl,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
            _statusText = status;
          });
        }
      },
    );

    if (!mounted) return;

    if (apkPath != null) {
      setState(() {
        _extractedApkPath = apkPath;
        _isDownloading = false;
        _downloadProgress = 1.0;
        _statusText = 'Abriendo instalador del sistema...';
      });

      await _updateService.installApk(apkPath);
    } else {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Ocurrió un error al descargar o descomprimir la actualización. Verifica tu conexión a internet e inténtalo de nuevo.';
        _statusText = 'Descarga fallida';
      });
    }
  }

  Future<void> _reinstalarApk() async {
    if (_extractedApkPath != null) {
      await _updateService.installApk(_extractedApkPath!);
    } else {
      await _iniciarActualizacion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMandatory = widget.updateInfo.isMandatory;
    const obsidian = Color(0xFF06080C);
    const surface = Color(0xFF121722);
    const cyan = Color(0xFF00E5FF);
    const cobalt = Color(0xFF2979FF);

    return PopScope(
      canPop: !isMandatory,
      child: Scaffold(
        backgroundColor: obsidian,
        body: Stack(
          children: [
            // Halos atmosféricos estilo Obsidiana Cockpit
            Positioned(
              top: -120,
              right: -90,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cyan.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cobalt.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo oficial MY AUTO GUIDE con badge OTA
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: cyan.withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cyan.withValues(alpha: 0.25),
                                    blurRadius: 28,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(27),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -6,
                              bottom: -6,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [cyan, cobalt],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: obsidian, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cyan.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      const Text(
                        'MY AUTO GUIDE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                          color: cyan,
                        ),
                      ),
                      const SizedBox(height: 6),

                      const Text(
                        'Actualización Disponible',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        'Tu vehículo, bajo control inteligente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: cyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cyan.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          'Versión ${widget.updateInfo.versionName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: cyan,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Tarjeta de Notas de la Versión (Cockpit Surface)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: cyan.withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, color: cyan, size: 19),
                                SizedBox(width: 8),
                                Text(
                                  'Novedades de la actualización',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.updateInfo.releaseNotes.replaceAll(r'\n', '\n'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE2E8F0),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Sección de Progreso
                      if (_isDownloading || _downloadProgress > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            minHeight: 10,
                            backgroundColor: const Color(0xFF1E293B),
                            valueColor: const AlwaysStoppedAnimation<Color>(cyan),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _statusText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0AEC0),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cyan,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1744).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFF1744).withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF8A80),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Botón Principal Obsidiana Cockpit (Gradiente Cian -> Cobalto)
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _isDownloading
                              ? null
                              : const LinearGradient(
                                  colors: [cyan, cobalt],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: _isDownloading ? surface : null,
                          boxShadow: _isDownloading
                              ? null
                              : [
                                  BoxShadow(
                                    color: cobalt.withValues(alpha: 0.40),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isDownloading
                              ? null
                              : (_extractedApkPath != null ? _reinstalarApk : _iniciarActualizacion),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isDownloading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: cyan,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Actualizando...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _extractedApkPath != null
                                          ? Icons.install_mobile_rounded
                                          : Icons.download_rounded,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _extractedApkPath != null
                                          ? 'Completar Instalación'
                                          : 'Descargar e Instalar Ahora',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      if (!isMandatory && !_isDownloading) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Recordar más tarde',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      Text(
                        isMandatory
                            ? '🔒 Actualización requerida para garantizar la seguridad y sincronización.'
                            : 'Mantén MY AUTO GUIDE al día para recibir todas las mejoras.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718096),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
