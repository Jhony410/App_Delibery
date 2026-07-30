import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user_model.dart';
import 'auth_service.dart';

/// Resultado de un intento de ingreso con huella.
///
/// La biometría no es un proveedor de Firebase: es un desbloqueo local de unas
/// credenciales guardadas. Por eso el resultado distingue tres casos, y no dos:
/// éxito, cancelación del usuario (no es un error, no se muestra nada) y error
/// real (se muestra el mensaje).
class BiometricSignInResult {
  final UserModel? user;
  final String? error;
  final bool canceled;

  const BiometricSignInResult._({this.user, this.error, this.canceled = false});

  const BiometricSignInResult.success(UserModel user) : this._(user: user);
  const BiometricSignInResult.canceled() : this._(canceled: true);
  const BiometricSignInResult.failure(String message) : this._(error: message);

  bool get isSuccess => user != null;
}

/// Acceso rápido con huella / Face ID.
///
/// No reemplaza al login por correo y contraseña: lo complementa. Tras un login
/// exitoso el usuario puede activar esta opción desde su perfil, y a partir de
/// ahí las credenciales quedan cifradas en el almacén seguro del sistema
/// operativo (Android Keystore / iOS Keychain) — nunca en Firestore, nunca en
/// texto plano.
///
/// Mismo patrón que [AuthService]: todo estático, sin instanciación.
class BiometricAuthService {
  static final _localAuth = LocalAuthentication();

  /// `AndroidOptions()` por defecto ya cifra con AES-GCM y envuelve la llave con
  /// RSA-OAEP en el Android Keystore. El antiguo flag `encryptedSharedPreferences`
  /// quedó deprecado en la v10 del paquete (la librería Jetpack Security que lo
  /// respaldaba fue descontinuada por Google) y hoy se ignora, así que no se pasa.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _kEmail = 'biometric_email';
  static const _kPassword = 'biometric_password';

  /// True solo si el dispositivo tiene hardware biométrico Y hay al menos una
  /// huella/rostro registrado. Sin lo segundo el prompt fallaría al invocarse.
  static Future<bool> isBiometricAvailable() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      if (!await _localAuth.canCheckBiometrics) return false;
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Lanza el prompt biométrico del sistema. `biometricOnly: true` impide que el
  /// PIN o el patrón del dispositivo sustituyan a la huella.
  ///
  /// Devuelve true si se verificó, false si el usuario canceló o no coincidió.
  /// Lanza [BiometricUnavailableException] si el problema es de configuración
  /// del dispositivo y vale la pena explicárselo al usuario.
  static Future<bool> authenticate({String? reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason:
            reason ?? 'Verifica tu identidad para ingresar a DeliPuno',
        biometricOnly: true,
      );
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
        case LocalAuthExceptionCode.userRequestedFallback:
          return false;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          throw const BiometricUnavailableException(
              'No tienes ninguna huella registrada en este dispositivo.');
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          throw const BiometricUnavailableException(
              'El sensor de huella no está disponible en este momento.');
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          throw const BiometricUnavailableException(
              'Demasiados intentos fallidos. Ingresa con tu contraseña.');
        default:
          throw const BiometricUnavailableException(
              'No pudimos verificar tu huella. Ingresa con tu contraseña.');
      }
    }
  }

  /// Guarda el par correo + contraseña cifrado, solo tras confirmar que la
  /// contraseña es correcta.
  ///
  /// Reautentica primero contra Firebase con `EmailAuthProvider` — el mismo
  /// mecanismo que usa el cambio de contraseña — para no llegar a persistir una
  /// contraseña equivocada que luego rompería el ingreso con huella.
  ///
  /// Lanza [FirebaseAuthException] si la contraseña no es válida.
  static Future<void> saveCredentials(String email, String password) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No hay una sesión activa.',
      );
    }
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(cred);
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPassword, value: password);
  }

  /// Si hay credenciales guardadas. Decide si el login muestra el botón de huella
  /// y si el toggle del perfil aparece activado.
  static Future<bool> hasSavedCredentials() async {
    try {
      final email = await _storage.read(key: _kEmail);
      final password = await _storage.read(key: _kPassword);
      return email != null && email.isNotEmpty && password != null;
    } catch (_) {
      return false;
    }
  }

  /// Verifica la huella y, si es válida, reautentica contra Firebase con las
  /// credenciales guardadas.
  ///
  /// Si Firebase responde `invalid-credential` (la contraseña cambió desde otro
  /// dispositivo) las credenciales guardadas quedan obsoletas: se borran solas y
  /// se pide entrar manualmente.
  static Future<BiometricSignInResult> signInWithBiometrics() async {
    try {
      final ok = await authenticate();
      if (!ok) return const BiometricSignInResult.canceled();
    } on BiometricUnavailableException catch (e) {
      return BiometricSignInResult.failure(e.message);
    } catch (_) {
      return const BiometricSignInResult.failure(
          'No pudimos verificar tu huella. Ingresa con tu contraseña.');
    }

    String? email;
    String? password;
    try {
      email = await _storage.read(key: _kEmail);
      password = await _storage.read(key: _kPassword);
    } catch (_) {
      return const BiometricSignInResult.failure(
          'No pudimos leer tus datos guardados. Ingresa con tu contraseña.');
    }
    if (email == null || password == null) {
      return const BiometricSignInResult.failure(
          'No hay un acceso con huella configurado. Ingresa con tu contraseña.');
    }

    try {
      final user = await AuthService.signIn(email, password);
      if (user == null) {
        await clearCredentials();
        return const BiometricSignInResult.failure(
            'No encontramos tu cuenta. Ingresa con tu contraseña.');
      }
      return BiometricSignInResult.success(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'user-disabled') {
        await clearCredentials();
        return const BiometricSignInResult.failure(
            'Tu contraseña cambió. Ingresa con tu contraseña para reactivar la huella.');
      }
      if (e.code == 'network-request-failed') {
        return const BiometricSignInResult.failure('Sin conexión a internet');
      }
      return const BiometricSignInResult.failure(
          'No pudimos iniciar sesión. Inténtalo de nuevo.');
    } catch (_) {
      return const BiometricSignInResult.failure(
          'No pudimos iniciar sesión. Inténtalo de nuevo.');
    }
  }

  /// Borra las credenciales del almacén seguro. Se llama al desactivar el toggle
  /// y también desde el cierre de sesión manual.
  static Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _kEmail);
      await _storage.delete(key: _kPassword);
    } catch (_) {
      // El almacén seguro puede fallar si el Keystore fue invalidado (por
      // ejemplo, al quitar el bloqueo de pantalla). En ese caso las credenciales
      // ya son ilegibles, así que no hay nada que rescatar ni que informar.
    }
  }
}

/// Problema de configuración o disponibilidad del sensor, con un mensaje ya
/// listo para mostrarle al usuario.
class BiometricUnavailableException implements Exception {
  final String message;
  const BiometricUnavailableException(this.message);

  @override
  String toString() => message;
}
