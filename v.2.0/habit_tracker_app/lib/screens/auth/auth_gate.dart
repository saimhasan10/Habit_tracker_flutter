import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showLogin = true;

  void toggleScreen() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }

        if (showLogin) {
          return LoginScreen(onRegisterClicked: toggleScreen);
        } else {
          return SignupScreen(onLoginClicked: toggleScreen);
        }
      },
    );
  }
}
