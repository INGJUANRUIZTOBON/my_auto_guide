import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Excepción personalizada para mapear errores conocidos de Supabase a mensajes UI amigables
class AuthLogicException implements Exception {
  final String message;
  final bool isNotConfirmed;
  AuthLogicException(this.message, {this.isNotConfirmed = false});
  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// URI de retorno registrado en AndroidManifest.xml para volver a la app tras confirmar email u OAuth.
  static const String authCallbackUrl = 'io.supabase.myautoguide://login-callback';

  final SupabaseClient _supabase = SupabaseService().client;
  StreamSubscription<AuthState>? _recoverySub;
  bool _hasPendingPasswordRecovery = false;

  bool get hasPendingPasswordRecovery => _hasPendingPasswordRecovery;

  void clearPendingPasswordRecovery() {
    _hasPendingPasswordRecovery = false;
  }

  /// Escucha globalmente eventos de recuperación de contraseña (incluso en arranque en frío por deep link).
  void initRecoveryWatcher() {
    _recoverySub ??= _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _hasPendingPasswordRecovery = true;
      }
    });
  }

  /// Retorna el usuario actual si hay sesión; de otra forma, null
  User? get currentUser => _supabase.auth.currentUser;

  /// Retorna la id del primer vehículo que tenga el usuario; de otra forma, null
  Future<String?> getFirstVehicleId() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final List data = await _supabase
          .from('vehiculos')
          .select('id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);
          
      if (data.isNotEmpty) {
        return (data.first as Map)['id'] as String;
      }
      return null;
    } catch (e) {
      // Retorna null silenciosamente porque el objetivo de bootstrap es enrutar limpiamente.
      return null;
    }
  }

  /// Inicia sesión con correo y clave.
  Future<void> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('not confirmed')) {
         throw AuthLogicException('Tu correo no está confirmado. Revisa tu bandeja o reenvía el correo de verificación.', isNotConfirmed: true);
      }
      throw AuthLogicException(e.message);
    } catch (e) {
      throw AuthLogicException('Error inesperado: $e');
    }
  }

  /// Reenvía confirmación de email (OtpType.signup) con redirección de retorno a la app
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: kIsWeb ? null : authCallbackUrl,
      );
    } on AuthException catch (e) {
      throw AuthLogicException(e.message);
    } catch (e) {
      throw AuthLogicException('Error inesperado: $e');
    }
  }

  /// Envia enlace para restablecer contraseña
  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw AuthLogicException('Ingresa tu e-mail para recuperar la contraseña.');
    }
    try {
      await _supabase.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: kIsWeb ? null : authCallbackUrl,
      );
    } on AuthException catch (e) {
      throw AuthLogicException(e.message);
    } catch (e) {
      throw AuthLogicException('Error inesperado: $e');
    }
  }

  /// Actualiza directamente la contraseña del usuario en Supabase Auth.
  Future<void> updatePassword(String newPassword) async {
    final cleanPassword = newPassword.trim();
    if (cleanPassword.length < 6) {
      throw AuthLogicException('La nueva contraseña debe tener al menos 6 caracteres.');
    }
    if (_supabase.auth.currentSession == null && _supabase.auth.currentUser == null) {
      throw AuthLogicException(
        'No hay una sesión de recuperación activa. Abre el enlace enviado a tu correo o inicia sesión nuevamente.',
      );
    }
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: cleanPassword),
      );
      _hasPendingPasswordRecovery = false;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('same password') || msg.contains('different from the old')) {
        throw AuthLogicException('La nueva contraseña debe ser diferente a la actual.');
      }
      throw AuthLogicException(e.message);
    } catch (e) {
      throw AuthLogicException('No se pudo actualizar la contraseña: $e');
    }
  }

  /// Iniciar sesión con Google via OAuth (Soporte Android & iOS)
  Future<bool> signInWithGoogle() async {
    try {
      final res = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.myautoguide://login-callback',
      );
      return res;
    } on AuthException catch (e) {
      throw AuthLogicException('Error en autenticación con Google: ${e.message}');
    } catch (e) {
      throw AuthLogicException('No se pudo iniciar sesión con Google: $e');
    }
  }

  /// Iniciar sesión con Facebook via OAuth (Soporte Android & iOS)
  Future<bool> signInWithFacebook() async {
    try {
      final res = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'io.supabase.myautoguide://login-callback',
      );
      return res;
    } on AuthException catch (e) {
      throw AuthLogicException('Error en autenticación con Facebook: ${e.message}');
    } catch (e) {
      throw AuthLogicException('No se pudo iniciar sesión con Facebook: $e');
    }
  }

  /// Cerrar Sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
