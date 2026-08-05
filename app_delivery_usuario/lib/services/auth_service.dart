import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/user_model.dart';
import 'biometric_auth_service.dart';

class AuthFlowException implements Exception {
  final String code;
  final String message;

  const AuthFlowException(this.code, this.message);

  @override
  String toString() => message;
}

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleInitialization;
  static bool _signingIn = false;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserModel> signInWithEmail(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw const AuthFlowException(
        'missing-user',
        'No pudimos cargar tu cuenta.',
      );
    }
    await BiometricAuthService.clearAccessIfDifferent(firebaseUser.uid);
    return _upsertUserProfile(firebaseUser);
  }

  static Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw const AuthFlowException(
        'missing-user',
        'No pudimos crear tu cuenta.',
      );
    }
    await firebaseUser.updateDisplayName(name);
    final profile = UserModel(
      uid: firebaseUser.uid,
      name: name,
      email: email,
      phone: phone,
      memberSince: DateTime.now(),
    );
    await _db.collection('users').doc(firebaseUser.uid).set(profile.toMap());
    await BiometricAuthService.clearAccessIfDifferent(firebaseUser.uid);
    return profile;
  }

  static Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return;
    }
    final current = _googleInitialization;
    if (current != null) return current;
    final attempt = _googleSignIn.initialize(
      clientId:
          defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
    );
    _googleInitialization = attempt;
    try {
      await attempt;
    } catch (_) {
      if (identical(_googleInitialization, attempt)) {
        _googleInitialization = null;
      }
      rethrow;
    }
  }

  /// Authenticates with Google and returns the real `users/{uid}` profile.
  /// A null result means that the account picker was canceled by the user.
  static Future<UserModel?> signInWithGoogle() async {
    if (_signingIn) {
      throw const AuthFlowException(
        'sign-in-in-progress',
        'El acceso con Google ya está en proceso.',
      );
    }
    _signingIn = true;
    try {
      return await _performGoogleSignIn();
    } finally {
      _signingIn = false;
    }
  }

  static Future<UserModel?> _performGoogleSignIn() async {
    try {
      final UserCredential credential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters(const {'prompt': 'select_account'});
        credential = await _auth.signInWithPopup(provider);
      } else {
        await initialize();
        if (!_googleSignIn.supportsAuthenticate()) {
          throw const AuthFlowException(
            'unsupported-platform',
            'Google no está disponible en este dispositivo.',
          );
        }
        final account = await _googleSignIn.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw const AuthFlowException(
            'missing-id-token',
            'Google no devolvió una credencial válida. Inténtalo nuevamente.',
          );
        }
        credential = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthFlowException(
          'missing-user',
          'No pudimos obtener tu cuenta de Google.',
        );
      }
      await BiometricAuthService.clearAccessIfDifferent(firebaseUser.uid);
      return await _upsertUserProfile(firebaseUser);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      await _rollbackIncompleteSignIn();
      throw AuthFlowException(error.code.name, googleErrorMessage(error.code));
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request') {
        return null;
      }
      await _rollbackIncompleteSignIn();
      throw AuthFlowException(error.code, firebaseErrorMessage(error.code));
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_canceled' || error.code == 'canceled') {
        return null;
      }
      await _rollbackIncompleteSignIn();
      throw const AuthFlowException(
        'platform-error',
        'No pudimos abrir el selector de Google. Inténtalo nuevamente.',
      );
    } on AuthFlowException {
      await _rollbackIncompleteSignIn();
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Google Sign-In failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _rollbackIncompleteSignIn();
      throw const AuthFlowException(
        'unknown',
        'No pudimos iniciar sesión con Google. Inténtalo nuevamente.',
      );
    }
  }

  static Future<UserModel> _upsertUserProfile(User firebaseUser) async {
    final ref = _db.collection('users').doc(firebaseUser.uid);
    final snapshot = await ref.get();
    final existing = snapshot.data();
    final email = firebaseUser.email?.trim() ?? '';
    final googleName = firebaseUser.displayName?.trim() ?? '';

    if (!snapshot.exists) {
      final profile = UserModel(
        uid: firebaseUser.uid,
        name: googleName.isNotEmpty ? googleName : _nameFromEmail(email),
        email: email,
        phone: '',
        memberSince:
            firebaseUser.metadata.creationTime?.toLocal() ?? DateTime.now(),
      );
      await ref.set(profile.toMap());
      return profile;
    }

    final updates = <String, dynamic>{};
    if (email.isNotEmpty && existing?['email'] != email) {
      updates['email'] = email;
    }
    final currentName = (existing?['name'] as String? ?? '').trim();
    if (currentName.isEmpty && googleName.isNotEmpty) {
      updates['name'] = googleName;
    }
    if (updates.isNotEmpty) await ref.set(updates, SetOptions(merge: true));

    final merged = <String, dynamic>{...?existing, ...updates};
    return UserModel.fromMap(firebaseUser.uid, merged);
  }

  static String _nameFromEmail(String email) {
    final prefix = email.split('@').first.trim();
    return prefix.isEmpty ? 'Usuario DeliPuno' : prefix;
  }

  static Future<void> _rollbackIncompleteSignIn() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        await initialize();
        await _googleSignIn.signOut();
      } catch (error) {
        debugPrint('Could not rollback Google sign-in: $error');
      }
    }
    try {
      await _auth.signOut();
    } catch (error) {
      debugPrint('Could not rollback Firebase sign-in: $error');
    }
  }

  static String googleErrorMessage(GoogleSignInExceptionCode code) =>
      switch (code) {
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Google Sign-In todavía no está configurado correctamente.',
        GoogleSignInExceptionCode.uiUnavailable =>
          'No pudimos abrir el selector de cuentas de Google.',
        GoogleSignInExceptionCode.interrupted =>
          'El acceso con Google fue interrumpido. Inténtalo nuevamente.',
        GoogleSignInExceptionCode.userMismatch =>
          'La cuenta seleccionada no coincide con la sesión actual.',
        GoogleSignInExceptionCode.canceled => '',
        GoogleSignInExceptionCode.unknownError =>
          'No pudimos iniciar sesión con Google. Inténtalo nuevamente.',
      };

  static String firebaseErrorMessage(String code) => switch (code) {
    'network-request-failed' => 'Sin conexión a internet.',
    'user-disabled' => 'Esta cuenta fue deshabilitada.',
    'operation-not-allowed' =>
      'El acceso con Google todavía no está habilitado.',
    'account-exists-with-different-credential' =>
      'Este correo ya usa otro método de acceso. Ingresa con ese método antes de vincular Google.',
    'invalid-credential' =>
      'Google devolvió una credencial inválida. Inténtalo nuevamente.',
    'too-many-requests' =>
      'Hubo demasiados intentos. Espera unos minutos y vuelve a intentarlo.',
    _ => 'No pudimos iniciar sesión con Google. Inténtalo nuevamente.',
  };

  static Future<void> signOut({bool preservePasswordBiometrics = false}) async {
    final uid = currentUid;
    final canPreserve =
        uid != null &&
        preservePasswordBiometrics &&
        await BiometricAuthService.hasPasswordCredentialsForUser(uid);
    if (!canPreserve && uid != null) {
      await BiometricAuthService.clearAccessForUser(uid);
    }

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        await initialize();
        await _googleSignIn.signOut();
      } catch (error) {
        debugPrint('Could not close the local Google session: $error');
      }
    }
    await _auth.signOut();
  }

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
