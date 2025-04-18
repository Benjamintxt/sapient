// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart'; // 🔐 Firebase Auth pour la gestion des comptes

const bool kEnableAuthLogs = true; // ✅ Active les logs de debug pour l’authentification

/// 🖨️ Fonction de log pour les opérations d'authentification
void logAuth(String message) {
  if (kEnableAuthLogs) print(message); // 📢 Affiche uniquement si les logs sont activés
}

/// 🔐 Service centralisé pour la gestion de l'authentification (login, logout, utilisateur courant...)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // 🔗 Accès à l’instance Firebase Auth

  /// 🔹 Retourne l’utilisateur actuellement connecté (ou null si déconnecté)
  User? get currentUser {
    final user = _auth.currentUser; // 👤 Utilisateur actuel
    logAuth("👤 Utilisateur courant : ${user?.uid ?? 'Aucun'}");
    return user;
  }

  /// 🔹 Retourne l’UID de l’utilisateur connecté (ou null)
  String? getCurrentUserUid() {
    try {
      final uid = _auth.currentUser?.uid; // 🔎 UID récupéré
      logAuth("🔐 UID courant : $uid");
      return uid;
    } catch (e) {
      logAuth("❌ Erreur récupération UID : $e");
      return null;
    }
  }

  /// 🔹 Connexion anonyme à Firebase Auth (utile pour un accès temporaire sans compte)
  Future<User?> signInAnonymously() async {
    try {
      logAuth("🚀 Connexion anonyme...");
      final result = await _auth.signInAnonymously(); // 🔓 Connexion temporaire
      logAuth("✅ Connecté en anonyme : ${result.user?.uid}");
      return result.user;
    } catch (e) {
      logAuth("❌ Erreur connexion anonyme : $e");
      return null;
    }
  }

  /// 🔹 Connexion avec email et mot de passe
  Future<User?> signInWithEmail({
    required String email, // 📧 Email utilisateur
    required String password, // 🔑 Mot de passe
  }) async {
    try {
      logAuth("🚀 Connexion avec email : $email");
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      logAuth("✅ Connecté avec email : ${result.user?.uid}");
      return result.user;
    } catch (e) {
      logAuth("❌ Erreur connexion email : $e");
      return null;
    }
  }

  /// 🔹 Création de compte avec email et mot de passe
  Future<User?> registerWithEmail({
    required String email, // 📧 Email à enregistrer
    required String password, // 🔑 Mot de passe
  }) async {
    try {
      logAuth("📝 Création d’un compte pour : $email");
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      logAuth("✅ Compte créé : ${result.user?.uid}");
      return result.user;
    } catch (e) {
      logAuth("❌ Erreur création compte : $e");
      return null;
    }
  }

  /// 🔹 Déconnexion de l’utilisateur actuel
  Future<void> signOut() async {
    try {
      logAuth("🚪 Déconnexion de ${_auth.currentUser?.uid}");
      await _auth.signOut(); // 🔐 Déconnexion Firebase
      logAuth("✅ Déconnecté !");
    } catch (e) {
      logAuth("❌ Erreur déconnexion : $e");
    }
  }
}
