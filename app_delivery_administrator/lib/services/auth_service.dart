import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/admin_user_model.dart';

/// Authenticates admin users against Firebase Auth and reads their profile
/// from the `admins/{uid}` Firestore collection.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Reads the admin profile document. Returns null if the authenticated user
  /// does not have an entry in `admins/`.
  static Future<AdminUserModel?> currentAdminProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    final snap = await _db.collection('admins').doc(uid).get();
    if (!snap.exists) return null;
    return AdminUserModel.fromMap(uid, snap.data()!);
  }

  static Stream<AdminUserModel?> streamAdminProfile() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _db.collection('admins').doc(uid).snapshots().map((s) =>
        s.exists ? AdminUserModel.fromMap(uid, s.data()!) : null);
  }
}
