import 'package:flutter/material.dart';
import 'package:sapient/app/pages/home_page.dart';
import 'package:sapient/app/pages/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; //  Pour FirebaseAuth et User

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        //  Si l'utilisateur N'EST PAS connecté, on affiche LoginPage
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        //  Sinon, on affiche la HomePage
        return const HomePage();
      },
    );
  }
}
