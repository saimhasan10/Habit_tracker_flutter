import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential> signupWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    UserCredential userCredential = await firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);

    await userCredential.user?.updateDisplayName(name);
    await userCredential.user?.reload();

    return userCredential;
  }

  Future<UserCredential> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> updateUserName(String name) async {
    await firebaseAuth.currentUser?.updateDisplayName(name);
    await firebaseAuth.currentUser?.reload();
  }

  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}
