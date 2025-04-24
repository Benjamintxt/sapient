import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sapient/app/pages/utils/error_handler.dart';

const bool kEnableAuthLogs = true;

void logAuth(String message) {
  if (kEnableAuthLogs) print(message);
}

/// Centralized authentication service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current Firebase user
  User? get currentUser {
    final user = _auth.currentUser;
    logAuth("Utilisateur courant : ${user?.uid ?? 'Aucun'}");
    return user;
  }

  /// Get current user's UID
  String? getCurrentUserUid() {
    try {
      final uid = _auth.currentUser?.uid;
      logAuth("UID courant : $uid");
      return uid;
    } catch (e) {
      logAuth("Erreur récupération UID : $e");
      return null;
    }
  }

  /// Sign in anonymously
  Future<User?> signInAnonymously(BuildContext context) async {
    User? user;
    await ErrorHandler.safeCall(context, () async {
      logAuth("Connexion anonyme...");
      final result = await _auth.signInAnonymously();
      user = result.user;
      logAuth("Connecté en anonyme : ${user?.uid}");
    }, errorMessage: "Échec de la connexion anonyme.");
    return user;
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    // Validate input
    if (email.isEmpty || password.isEmpty) {
      ErrorHandler.handleError(
        context,
        'Email or password cannot be empty.',
        userMessage: 'Please enter a valid email and password.',
        title: 'Input Error',
      );
      return null; // Return early if inputs are invalid
    }

    User? user;
    await ErrorHandler.safeCall(context, () async {
      logAuth("Connexion avec email : $email");
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = result.user;
      logAuth("Connecté avec email : ${user?.uid}");
    }, errorMessage: "Échec de la connexion. Vérifiez vos identifiants.");

    return user;
  }

  /// Register a new account
  Future<User?> registerWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    User? user;
    await ErrorHandler.safeCall(context, () async {
      logAuth("Création d’un compte pour : $email");
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = result.user;
      logAuth("Compte créé : ${user?.uid}");
    }, errorMessage: "Échec de la création du compte.");
    return user;
  }

  /// Sign out the current user
  Future<void> signOut(BuildContext context) async {
    await ErrorHandler.safeCall(context, () async {
      final uid = _auth.currentUser?.uid;
      logAuth("Déconnexion de $uid");
      await _auth.signOut();
      logAuth("Déconnecté !");
    }, errorMessage: "Erreur lors de la déconnexion.");
  }
}
