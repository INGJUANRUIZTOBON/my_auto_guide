// =============================================================================
// login_screen.dart — PANTALLA DE INICIO DE SESIÓN
// =============================================================================
//
// Maneja la autenticación del usuario mediante email y contraseña usando
// Supabase Auth. Incluye:
//   - Login con email/contraseña.
//   - Verificación automática de sesión previa (auto-login).
//   - Recuperación de contraseña por correo.
//   - Reenvío de correo de confirmación si la cuenta no está verificada.
//   - Navegación post-login: si el usuario tiene vehículos registrados va a
//     [InicioApp]; si no, va a [AgregarVehiculoScreen].
//   - Botones decorativos de login social (Google, Facebook, Apple).
//   - Enlace para navegar a la pantalla de registro [RegistroScreen].
//
// Flujo de navegación:
//   CarRentalLoginScreen → InicioApp (si hay vehículos)
//                        → AgregarVehiculoScreen (si no hay vehículos)
//                        → RegistroScreen (si el usuario quiere registrarse)
//
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registro_screen.dart';
import '../vehicles/presentation/Agregar_vehiculo.dart';
import '../vehicles/presentation/inicio_app.dart';
import '../../core/services/auth_service.dart';
import '../../core/logic/performance_guard.dart';
import '../../shared/widgets/app_snack_bar.dart';
import '../../shared/widgets/glass_text_field.dart';
import 'widgets/change_password_sheet.dart';

import '../../core/services/biometric_service.dart';
import '../../core/services/app_update_service.dart';
import '../updater/presentation/app_update_lock_screen.dart';

class CarRentalLoginScreen extends StatefulWidget {
  const CarRentalLoginScreen({super.key});

  @override
  State<CarRentalLoginScreen> createState() => _CarRentalLoginScreenState();
}

class _CarRentalLoginScreenState extends State<CarRentalLoginScreen> {
  final _auth = AuthService();
  final _biometric = BiometricService();
  final _updateService = AppUpdateService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = true; // Por defecto true para mayor comodidad
  bool canUseBiometrics = false;
  bool _navigatedByAuth = false;
  bool _inPasswordRecovery = false;
  bool _checkingAutoLogin = true;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _inPasswordRecovery = true;
        _openRecoveryPasswordSheet();
        return;
      }
      if (data.event == AuthChangeEvent.signedIn &&
          data.session != null &&
          !_inPasswordRecovery &&
          !_auth.hasPendingPasswordRecovery &&
          !_navigatedByAuth &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        _navigatedByAuth = true;
        _goToDestination();
      }
    });
    _initSession();
  }

  Future<void> _openRecoveryPasswordSheet() async {
    if (!mounted) return;
    _inPasswordRecovery = true;
    final updated = await ChangePasswordSheet.show(context, isRecovery: true);
    _inPasswordRecovery = false;
    _auth.clearPendingPasswordRecovery();
    if (updated && mounted && _auth.currentUser != null) {
      await _goToDestination();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    _checkingAutoLogin = _auth.currentUser != null;
    try {
      final update = await _updateService.checkForUpdate();
      if (update != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AppUpdateLockScreen(updateInfo: update)),
        );
        return;
      }
      await _checkBiometrics();
      await _bootstrapSession();
    } finally {
      if (mounted && !_navigatedByAuth) {
        setState(() => _checkingAutoLogin = false);
      }
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometric.isBiometricAvailable();
    if (mounted) setState(() => canUseBiometrics = available);
  }

  // Carga preferencias y autologuea si la sesión de Supabase está activa y "Recordarme" habilitado
  Future<void> _bootstrapSession() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldRemember = prefs.getBool('remember_me') ?? true;
    final savedEmail = prefs.getString('saved_email') ?? '';
    
    if (mounted) {
      setState(() {
        rememberMe = shouldRemember;
        if (savedEmail.isNotEmpty) {
          emailController.text = savedEmail;
        } else if (_auth.currentUser != null && _auth.currentUser!.email != null) {
          emailController.text = _auth.currentUser!.email!;
        }
      });
    }

    // Si viene desde un enlace de recuperación de Supabase, abrir modal de cambio de clave
    if (_auth.hasPendingPasswordRecovery || _inPasswordRecovery) {
      await _openRecoveryPasswordSheet();
      return;
    }

    // Si "Recordarme" está activo y hay una sesión válida en Supabase, ir directo al inicio
    if (shouldRemember && _auth.currentUser != null) {
      await _goToDestination();
    }
  }

  Future<void> _loginAlternative() async {
    if (!canUseBiometrics) return;
    final authenticated = await _biometric.authenticate();
    if (authenticated) {
      if (_auth.currentUser != null) {
        await _goToDestination();
      } else {
        AppSnackBar.show(
          context,
          'Por favor, inicia sesión con correo y contraseña primero para habilitar el acceso biométrico.',
        );
      }
    }
  }

  // Decide a dónde navegar: InicioApp con id o AgregarVehiculo si no hay registros
  Future<void> _goToDestination() async {
    if (_auth.currentUser == null) return;
    _navigatedByAuth = true;

    final String? vehiculoId = await _auth.getFirstVehicleId();
    if (!mounted) return;
    
    if (vehiculoId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InicioApp(vehiculoId: vehiculoId)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AgregarVehiculoScreen()),
      );
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => isLoading = true);
    try {
      await _auth.signInWithGoogle();
      await _goToDestination();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, '$e');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loginFacebook() async {
    setState(() => isLoading = true);
    try {
      await _auth.signInWithFacebook();
      await _goToDestination();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, '$e');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      await _auth.signIn(
         emailController.text, 
         passwordController.text
      );

      // Guardar preferencia de recordar e email
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);
      if (rememberMe) {
        await prefs.setString('saved_email', emailController.text.trim());
      } else {
        await prefs.remove('saved_email');
      }

      if (!mounted) return;
      await _goToDestination();
    } on AuthLogicException catch (e) {
      if (!mounted) return;
      if (e.isNotConfirmed) {
        AppSnackBar.show(
          context,
          e.message,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Reenviar',
            onPressed: () async {
              try {
                await _auth.resendConfirmationEmail(emailController.text);
                if (!mounted) return;
                AppSnackBar.show(context, 'Correo de confirmación reenviado.');
              } on AuthLogicException catch (e2) {
                if (!mounted) return;
                AppSnackBar.show(
                    context, 'No se pudo reenviar: ${e2.message}');
              }
            },
          ),
        );
      } else {
        AppSnackBar.show(context, 'Error: ${e.message}');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendPasswordReset() async {
    String targetEmail = emailController.text.trim();
    if (targetEmail.isEmpty) {
      final ctrl = TextEditingController();
      final entered = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Ingresa tu correo registrado',
              hintText: 'usuario@correo.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Enviar enlace'),
            ),
          ],
        ),
      );
      ctrl.dispose();
      if (entered == null || entered.isEmpty) return;
      targetEmail = entered;
      emailController.text = entered;
    }

    try {
      await _auth.sendPasswordReset(targetEmail);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        'Te enviamos un correo desde Supabase para cambiar tu contraseña. Abre el enlace en tu teléfono.',
        duration: const Duration(seconds: 6),
      );
    } on AuthLogicException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAutoLogin) {
      return const Scaffold(
        backgroundColor: Color(0xFF06080C),
        body: Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFF00E5FF),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg_pattern.png',
              fit: BoxFit.cover,
              cacheWidth: PerformanceGuard().isLowEnd
                  ? 400
                  : null, // Reducir carga de textura
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
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
                  const SizedBox(height: 18),
                  const Text(
                    'MY AUTO GUIDE',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                      letterSpacing: 2.2,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu vehículo, bajo control inteligente',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Campos de entrada con Glassmorphism suave
                  GlassTextField(
                    controller: emailController,
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Theme(
                        data: ThemeData(
                            unselectedWidgetColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.3)),
                        child: Checkbox(
                          value: rememberMe,
                          checkColor: Colors.white,
                          activeColor: const Color(0xFF035880),
                          onChanged: (value) =>
                              setState(() => rememberMe = value ?? false),
                        ),
                      ),
                      Text(
                        'Recuerdame',
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.7)),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: sendPasswordReset,
                        child: Text(
                          'Recuperar contraseña',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : const Color(0xFF035880),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                      // Botón Iniciar Sesión y Biometría
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: PerformanceGuard().isLowEnd
                                    ? null
                                    : const LinearGradient(
                                        colors: [Color(0xFF035880), Color(0xFF023E5A)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                color: PerformanceGuard().isLowEnd
                                    ? const Color(0xFF035880)
                                    : null,
                                boxShadow: [
                                  if (!PerformanceGuard().isLowEnd)
                                    BoxShadow(
                                      color: const Color(0xFF035880).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Iniciar Sesión'),
                              ),
                            ),
                          ),
                          if (canUseBiometrics) ...[
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _loginAlternative,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF035880).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF035880).withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.fingerprint, size: 32, color: Color(0xFF035880)),
                              ),
                            ),
                          ],
                        ],
                      ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ingresa con',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.5)),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        icon: 'assets/google.png',
                        fallbackIcon: Icons.g_mobiledata_rounded,
                        iconColor: Colors.redAccent,
                        onTap: _loginGoogle,
                      ),
                      const SizedBox(width: 24),
                      _SocialButton(
                        icon: 'assets/facebook.png',
                        fallbackIcon: Icons.facebook_rounded,
                        iconColor: const Color(0xFF1877F2),
                        onTap: _loginFacebook,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegistroScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: '¿Aún no tienes cuenta? ',
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.6)),
                        children: [
                          TextSpan(
                            text: 'Registrarme',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF035880),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final IconData? fallbackIcon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    this.fallbackIcon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.12)),
          boxShadow: PerformanceGuard().isLowEnd
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: fallbackIcon != null
            ? Icon(fallbackIcon, size: 28, color: iconColor ?? Colors.white)
            : Image.asset(icon, height: 28),
      ),
    );
  }
}
