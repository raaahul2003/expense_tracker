import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Sign Up with Email & Password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error during sign-up: $e");
      return null;
    }
  }

  // Login with Email & Password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error during login: $e");
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
