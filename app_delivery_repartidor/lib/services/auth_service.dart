import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/courier_model.dart';

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

  static Future<void> signOut() => _auth.signOut();

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
