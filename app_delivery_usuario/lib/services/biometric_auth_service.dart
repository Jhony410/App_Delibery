import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_service.dart';

class BiometricSignInResult {
  final bool success;
  final bool canceled;
  final String? error;

  const BiometricSignInResult._({
    this.success = false,
    this.canceled = false,
    this.error,
  });

  const BiometricSignInResult.success() : this._(success: true);
  const BiometricSignInResult.canceled() : this._(canceled: true);
  const BiometricSignInResult.failure(String message) : this._(error: message);
}

/// Local biometric access for the account associated with this device.
///
/// Google accounts only store the Firebase UID and unlock the session already
/// persisted by Firebase. Password accounts may additionally store email and
/// password in Android Keystore/iOS Keychain, but only after Firebase
/// reauthentication and a successful biometric challenge. Nothing is written
/// to Firestore and Google/OAuth tokens are never persisted here.
class BiometricAuthService {
  static final _localAuth = LocalAuthentication();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _kEnabledUid = 'biometric_enabled_uid';
  static const _kEmail = 'biometric_email';
  static const _kPassword = 'biometric_password';

  static Future<bool> isBiometricAvailable() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      if (!await _localAuth.canCheckBiometrics) return false;
      return (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate({String? reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason:
            reason ?? 'Verifica tu identidad para ingresar a DeliPuno',
        biometricOnly: true,
      );
    } on LocalAuthException catch (error) {
      switch (error.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
        case LocalAuthExceptionCode.userRequestedFallback:
          return false;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          throw const BiometricUnavailableException(
            'No tienes ninguna huella registrada en este dispositivo.',
          );
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          throw const BiometricUnavailableException(
            'El sensor de huella no está disponible en este momento.',
          );
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          throw const BiometricUnavailableException(
            'Demasiados intentos fallidos. Ingresa con tu cuenta.',
          );
        default:
          throw const BiometricUnavailableException(
            'No pudimos verificar tu huella.',
          );
      }
    }
  }

  static Future<bool> hasAccessForUser(String uid) async {
    try {
      return await _storage.read(key: _kEnabledUid) == uid;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasSavedLogin() async {
    try {
      final uid = await _storage.read(key: _kEnabledUid);
      final email = await _storage.read(key: _kEmail);
      final password = await _storage.read(key: _kPassword);
      return uid != null &&
          uid.isNotEmpty &&
          email != null &&
          email.isNotEmpty &&
          password != null &&
          password.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPasswordCredentialsForUser(String uid) async {
    if (!await hasAccessForUser(uid)) return false;
    return hasSavedLogin();
  }

  static Future<void> enableForUser(String uid) async {
    if (AuthService.currentUid != uid) {
      throw const BiometricUnavailableException(
        'La sesión cambió. Vuelve a intentarlo.',
      );
    }
    await _storage.write(key: _kEnabledUid, value: uid);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPassword);
  }

  static Future<void> savePasswordCredentials({
    required String uid,
    required String email,
    required String password,
  }) async {
    final user = AuthService.currentUser;
    if (user == null || user.uid != uid) {
      throw const BiometricUnavailableException(
        'La sesión cambió. Vuelve a intentarlo.',
      );
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
    await _storage.write(key: _kEnabledUid, value: uid);
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPassword, value: password);
  }

  static Future<BiometricSignInResult> signInWithBiometrics() async {
    try {
      if (!await authenticate()) {
        return const BiometricSignInResult.canceled();
      }
      final expectedUid = await _storage.read(key: _kEnabledUid);
      final email = await _storage.read(key: _kEmail);
      final password = await _storage.read(key: _kPassword);
      if (expectedUid == null || email == null || password == null) {
        return const BiometricSignInResult.failure(
          'No hay un acceso con huella configurado para iniciar sesión.',
        );
      }
      final profile = await AuthService.signInWithEmail(email, password);
      if (profile.uid != expectedUid) {
        await AuthService.signOut();
        return const BiometricSignInResult.failure(
          'La cuenta guardada no coincide. Ingresa manualmente.',
        );
      }
      return const BiometricSignInResult.success();
    } on BiometricUnavailableException catch (error) {
      return BiometricSignInResult.failure(error.message);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'user-not-found' ||
          error.code == 'user-disabled') {
        await clearAllAccess();
        return const BiometricSignInResult.failure(
          'La credencial guardada ya no es válida. Ingresa manualmente.',
        );
      }
      if (error.code == 'network-request-failed') {
        return const BiometricSignInResult.failure('Sin conexión a internet.');
      }
      return const BiometricSignInResult.failure(
        'No pudimos iniciar sesión con tu huella.',
      );
    } catch (_) {
      return const BiometricSignInResult.failure(
        'No pudimos iniciar sesión con tu huella.',
      );
    }
  }

  static Future<void> clearAccessIfDifferent(String uid) async {
    try {
      final storedUid = await _storage.read(key: _kEnabledUid);
      if (storedUid != null && storedUid != uid) await clearAllAccess();
    } catch (_) {
      await clearAllAccess();
    }
  }

  static Future<void> clearAccessForUser(String uid) async {
    try {
      if (await _storage.read(key: _kEnabledUid) == uid) {
        await clearAllAccess();
      }
    } catch (_) {
      // A revoked Keystore makes these values unreadable already.
    }
  }

  static Future<void> clearAllAccess() async {
    try {
      await _storage.delete(key: _kEnabledUid);
      await _storage.delete(key: _kEmail);
      await _storage.delete(key: _kPassword);
    } catch (_) {
      // A revoked Keystore makes these values unreadable already.
    }
  }
}

class BiometricUnavailableException implements Exception {
  final String message;
  const BiometricUnavailableException(this.message);

  @override
  String toString() => message;
}
