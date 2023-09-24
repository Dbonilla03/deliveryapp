import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> adminEmails = ["bonilla@gmail.com"];
  // Registro con correo electrónico y contraseña
  Future<User?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = credential.user;
      if (isAdminEmail(email)) {
        await _updateUserRole(user!.uid, "Admin");
      } else {
        await _updateUserRole(user!.uid, "User");
      }
      return user;
    } catch (e) {
      print("Error: $e");
    }
    return null;
  }

  bool isAdminEmail(String email) {
    return adminEmails.contains(email);
  }

  Future<void> _updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection("userRoles").doc(uid).set({"role": role});
    } catch (e) {
      print("Error al actualizar el rol del usuario: $e");
    }
  }

// Inicio de sesión con correo electrónico y contraseña
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      print("Error: $e");
    }
    return null;
  }
}
