// lib/services/firestore/core.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔧 Coeur des accès Firestore : réutilisable par tous les services
class FirestoreCore {
  /// Instance principale de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔐 Récupère l'UID de l'utilisateur connecté (ou null si non connecté)
  static String? getCurrentUserUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      print("❌ [FirestoreCore] Erreur récupération UID : $e");
      return null;
    }
  }

  /// 🔁 Accès rapide à l'instance Firestore
  FirebaseFirestore get db => _db;
}
