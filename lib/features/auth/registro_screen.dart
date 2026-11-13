// =============================================================================
// registro_screen.dart — PANTALLA DE REGISTRO DE USUARIO
// =============================================================================
//
// Permite crear una cuenta nueva en Supabase Auth con email y contraseña
// o autenticación social OAuth (Google / Facebook).
// Características:
//   - Identidad visual oficial: Logo de My Auto Guide con badge Obsidian Glass.
//   - Formulario con campos: nombre, email, contraseña, confirmar contraseña.
//   - Aceptación obligatoria de Términos y Condiciones y Política de Privacidad (Ley 1581 Habeas Data).
//   - Envío de email de confirmación y monitoreo automático.
//   - Registro y login social integrado con Google y Facebook.
//
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logic/performance_guard.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_snack_bar.dart';
import '../../shared/widgets/glass_text_field.dart';
import '../vehicles/presentation/Agregar_vehiculo.dart';
import '../vehicles/presentation/inicio_app.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final AuthService _auth = AuthService();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool _acceptedTerms = false;

  // Estados para confirmación
  bool waitingForConfirm = false;
  int secondsLeft = 60;
  bool canSwitchEmail = false;
  Timer? _timer;
  StreamSubscription<AuthState>? _authSub;
  bool _navigatedAfterConfirm = false;

  @override
  void initState() {
    super.initState();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn &&
          data.session != null &&
          mounted &&
          !_navigatedAfterConfirm) {
        _completeEmailVerification();
      }
    });
  }

  Future<void> _completeEmailVerification() async {
    if (_navigatedAfterConfirm || !mounted) return;
    _navigatedAfterConfirm = true;
    _timer?.cancel();
    setState(() {
      waitingForConfirm = false;
      canSwitchEmail = false;
    });
    AppSnackBar.show(
      context,
      '¡Correo verificado! Bienvenido a My Auto Guide.',
    );
    final vehiculoId = await AuthService().getFirstVehicleId();
    if (!mounted) return;
    final Widget destination = vehiculoId != null
        ? InicioApp(vehiculoId: vehiculoId)
        : const AgregarVehiculoScreen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> signUp() async {
    final nombre = nombreController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (!_acceptedTerms) {
      AppSnackBar.show(
        context,
        'Debes aceptar los Términos y Condiciones y la Política de Privacidad para continuar.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Validaciones de entrada
    if (nombre.length < 2) {
      AppSnackBar.show(context, 'Por favor, ingresa un nombre válido.');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      AppSnackBar.show(context, 'Formato de correo electrónico no válido.');
      return;
    }

    if (password.length < 6) {
      AppSnackBar.show(
          context, 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    if (password != confirmPassword) {
      AppSnackBar.show(context, 'Las contraseñas no coinciden.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final redirectUrl = kIsWeb ? null : AuthService.authCallbackUrl;
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': nombre},
        emailRedirectTo: redirectUrl,
      );
      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Registro enviado. Revisa tu correo y confirma la cuenta para continuar.',
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Reenviar',
          onPressed: () async {
            try {
              await supabase.auth.resend(
                type: OtpType.signup,
                email: emailController.text.trim(),
                emailRedirectTo:
                    kIsWeb ? null : AuthService.authCallbackUrl,
              );
              if (!mounted) return;
              AppSnackBar.show(
                context,
                'Correo reenviado. Revisa tu bandeja de entrada o spam.',
              );
            } on AuthException catch (e) {
              if (!mounted) return;
              AppSnackBar.show(context, 'Error al reenviar: ${e.message}');
            }
          },
        ),
      );

      setState(() {
        waitingForConfirm = true;
        secondsLeft = 60;
        canSwitchEmail = false;
      });

      _startAutoCheck();
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('ya registrado')) {
        AppSnackBar.show(
          context,
          'Este correo ya tiene cuenta. Enviamos un nuevo enlace de confirmación.',
          duration: const Duration(seconds: 6),
        );
        try {
          await supabase.auth.resend(
            type: OtpType.signup,
            email: email,
            emailRedirectTo: kIsWeb ? null : AuthService.authCallbackUrl,
          );
        } catch (_) {}
        setState(() {
          waitingForConfirm = true;
          secondsLeft = 60;
          canSwitchEmail = false;
        });
        _startAutoCheck();
      } else {
        AppSnackBar.show(context, 'Error: ${e.message}');
      }
    } catch (e) {
      AppSnackBar.show(context, 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startAutoCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        secondsLeft = (secondsLeft - 5).clamp(0, 60);
      });

      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isNotEmpty && password.isNotEmpty) {
        try {
          final res = await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          if (res.user != null && mounted) {
            t.cancel();
            AppSnackBar.show(
                context, 'Correo verificado. Inicia sesión para continuar.');
            Navigator.pop(context);
            return;
          }
        } on AuthException {
          // Seguir esperando silenciosamente
        }
      }

      if (secondsLeft <= 0) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          canSwitchEmail = true;
          waitingForConfirm = true;
        });
        AppSnackBar.show(
          context,
          'No se confirmó el correo en 60 s. Puedes usar otro correo o reenviar.',
        );
      }
    });
  }

  void _switchToAnotherEmail() {
    _timer?.cancel();
    supabase.auth.signOut();
    setState(() {
      waitingForConfirm = false;
      canSwitchEmail = false;
      secondsLeft = 60;
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
    });
  }

  Future<void> _loginSocial(String provider) async {
    setState(() => isLoading = true);
    try {
      if (provider == 'google') {
        await _auth.signInWithGoogle();
      } else {
        await _auth.signInWithFacebook();
      }
      if (!mounted) return;
      final vehiculoId = await _auth.getFirstVehicleId();
      if (!mounted) return;
      final destination = vehiculoId != null
          ? InicioApp(vehiculoId: vehiculoId)
          : const AgregarVehiculoScreen();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, '$e');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showTermsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D111D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Color(0xFF00E5FF), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Términos, Condiciones y Privacidad',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Colors.white12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  '1. Objeto y Alcance\n'
                  'My Auto Guide es una plataforma inteligente para la gestión de vehículos, mantenimientos preventivos, monitoreo de odómetro, telemetría y consulta oficial ciudadana de RUNT y SIMIT en Colombia.\n\n'
                  '2. Tratamiento de Datos Personales (Ley 1581 de 2012)\n'
                  'Al crear tu cuenta autorizas el tratamiento de tus datos para la sincronización multi-dispositivo, notificaciones de vencimiento de SOAT/Tecnomecánica y cálculo de rutas seguras. Tus credenciales de RUNT y documentos vehiculares se transmiten mediante canales cifrados SSL/TLS y nunca son compartidos con terceros sin tu consentimiento expreso.\n\n'
                  '3. Ubicación y Telemetría GPS\n'
                  'La función de rastreo satelital opera bajo demanda exclusiva para registrar rutas y alertas de Pico y Placa. No compartimos tu ubicación en vivo con anunciantes ni redes externas.\n\n'
                  '4. Seguridad y Cuentas\n'
                  'Eres responsable de salvaguardar tus contraseñas y accesos. My Auto Guide implementa Row Level Security (RLS) en Supabase para garantizar que solo tú puedas ver y modificar tus vehículos y gastos.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _acceptedTerms = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Entendido y Aceptar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _timer?.cancel();
    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF06080C) : const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg_pattern.png',
              fit: BoxFit.cover,
              cacheWidth: PerformanceGuard().isLowEnd ? 400 : null,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge oficial con logo de My Auto Guide
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                            blurRadius: 26,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Registrarme',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crea tu cuenta en My Auto Guide',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),

                    if (waitingForConfirm)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.1)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirma tu correo para continuar',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isDark ? Colors.white : Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tiempo restante: $secondsLeft s',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await supabase.auth.resend(
                                        type: OtpType.signup,
                                        email: emailController.text.trim(),
                                        emailRedirectTo: kIsWeb
                                            ? null
                                            : AuthService.authCallbackUrl,
                                      );
                                      if (!mounted) return;
                                      AppSnackBar.show(
                                        context,
                                        'Correo reenviado. Revisa tu bandeja.',
                                      );
                                    } on AuthException catch (e) {
                                      if (!mounted) return;
                                      AppSnackBar.show(
                                        context,
                                        'Error al reenviar: ${e.message}',
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E5FF),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Reenviar correo'),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: canSwitchEmail
                                      ? _switchToAnotherEmail
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Otro correo'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    GlassTextField(
                      controller: nombreController,
                      label: 'Nombre completo',
                      icon: Icons.person_outline_rounded,
                      enabled: !waitingForConfirm,
                    ),
                    const SizedBox(height: 12),
                    GlassTextField(
                      controller: emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      enabled: !waitingForConfirm || canSwitchEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    GlassTextField(
                      controller: passwordController,
                      label: 'Contraseña',
                      icon: Icons.lock_outline_rounded,
                      enabled: !waitingForConfirm || canSwitchEmail,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    GlassTextField(
                      controller: confirmPasswordController,
                      label: 'Confirmar Contraseña',
                      icon: Icons.lock_reset_rounded,
                      enabled: !waitingForConfirm || canSwitchEmail,
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),

                    // Checkbox de Términos y Condiciones
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: const Color(0xFF00E5FF),
                          checkColor: Colors.black,
                          side: BorderSide(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          onChanged: (val) {
                            setState(() => _acceptedTerms = val ?? false);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showTermsDialog,
                            child: RichText(
                              text: TextSpan(
                                text: 'Acepto los ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Términos y Condiciones',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(text: ' y la '),
                                  TextSpan(
                                    text: 'Política de Privacidad',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botón Principal de Registro
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF035880), Color(0xFF023E5A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          if (!PerformanceGuard().isLowEnd)
                            BoxShadow(
                              color: const Color(0xFF035880).withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: (isLoading || waitingForConfirm) ? null : signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Registrarme'),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Separador Redes Sociales
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'O regístrate con',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botones Sociales (Google y Facebook)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialAuthCircle(
                          icon: Icons.g_mobiledata_rounded,
                          color: Colors.redAccent,
                          tooltip: 'Continuar con Google',
                          onTap: () => _loginSocial('google'),
                        ),
                        const SizedBox(width: 20),
                        _SocialAuthCircle(
                          icon: Icons.facebook_rounded,
                          color: const Color(0xFF1877F2),
                          tooltip: 'Continuar con Facebook',
                          onTap: () => _loginSocial('facebook'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Enlace a Iniciar Sesión
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: '¿Ya tienes una cuenta? ',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          children: [
                            TextSpan(
                              text: 'Iniciar Sesión',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF035880),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialAuthCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _SocialAuthCircle({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.04),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 30, color: color),
        ),
      ),
    );
  }
}
