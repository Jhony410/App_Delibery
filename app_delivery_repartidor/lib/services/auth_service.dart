import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/courier_model.dart';
import 'biometric_auth_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<CourierModel?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _db.collection('couriers').doc(uid).get();
    if (!doc.exists) return null;
    return CourierModel.fromMap(uid, doc.data()!);
  }

  static Future<CourierModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String dni = '',
    String vehiclePlate = '',
    String vehicleModel = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final courier = CourierModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      dni: dni,
      vehiclePlate: vehiclePlate,
      vehicleModel: vehicleModel,
      memberSince: DateTime.now(),
      status: 'pending_review',
    );
    await _db.collection('couriers').doc(uid).set(courier.toMap());
    return courier;
  }

  /// Cerrar sesión NO borra las credenciales del acceso con huella: si lo
  /// hiciera, al volver al login el botón de huella nunca aparecería, que es
  /// justo cuando hace falta. El acceso guardado se borra al desactivar el
  /// toggle en Seguridad o cuando Firebase rechaza la contraseña por haber
  /// cambiado (ver [BiometricAuthService.signInWithBiometrics]).
  static Future<void> signOut() => _auth.signOut();

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Change the signed-in courier's password. Firebase requires a recent login,
  /// so we reauthenticate with the current password first. Throws
  /// [FirebaseAuthException] on wrong password / weak password / etc.
  static Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No hay una sesión activa.',
      );
    }
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }
}
