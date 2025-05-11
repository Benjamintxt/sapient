// lib/services/firestore/storage_service.dart

import 'dart:io'; // 📂 Pour gérer les fichiers locaux (ex: images prises par l'appareil photo)
import 'package:firebase_storage/firebase_storage.dart'; // ☁️ Pour accéder à Firebase Storage
import 'package:uuid/uuid.dart'; // 🔑 Pour générer des identifiants uniques

const bool kEnableStorageLogs = false; // ✅ Active/désactive les logs liés au stockage

/// 📢 Logger dédié à Firebase Storage (upload, suppression d'image)
void logStorage(String message) {
  if (kEnableStorageLogs) print(message); // 🖨️ Affiche uniquement si activé
}

/// 🗂️ Service pour gérer le stockage des images (upload Firebase Storage, suppression, URL...)
class FirestoreStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance; // 🔗 Instance principale de Firebase Storage

  /// 🔹 Upload une image dans Firebase Storage et retourne l’URL publique
  ///
  /// 📥 Paramètres :
  /// - [image] : fichier local sélectionné (ex: File depuis image_picker)
  /// - [userId] : ID de l'utilisateur (sert à organiser les images)
  /// - [subjectId] : ID du sujet lié à cette image
  /// - [parentPathIds] : chemin hiérarchique des IDs parents (utilisé pour la structure de dossier)
  ///
  /// 📤 Retour :
  /// - URL publique de l’image à stocker dans Firestore
  Future<String> uploadImage({
    required File image, // 📷 Image locale sélectionnée
    required String userId, // 👤 Utilisateur courant
    required String subjectId, // 📁 Sujet auquel l’image est rattachée
    required List<String> parentPathIds, // 🧭 Hiérarchie complète des sujets
  }) async {
    logStorage("📤 [uploadImage] Début upload image"); // 🚀 Log d'initialisation

    // 🆔 Génère un identifiant unique pour nommer le fichier (évite les collisions)
    final fileName = const Uuid().v4();
    logStorage("🆔 Nom unique généré : $fileName.jpg");

    // 🛤️ Construit le chemin de stockage dans Firebase Storage
    final pathSegments = [
      'flashcards', // 📁 Dossier racine des flashcards
      userId, // 👤 ID utilisateur
      subjectId, // 📁 ID du sujet actuel
      ...parentPathIds, // 🧱 Empilement des parents dans l’arborescence
      '$fileName.jpg', // 🖼️ Nom final de l’image
    ];

    final fullPath = pathSegments.join('/'); // 🔗 Chemin complet
    logStorage("📁 Chemin complet dans Storage : $fullPath");

    // 📍 Référence vers le fichier dans Firebase Storage
    final ref = _storage.ref().child(fullPath);

    // 🚀 Upload du fichier vers Firebase Storage
    await ref.putFile(image);
    logStorage("✅ Image uploadée avec succès !");

    // 🌍 Récupération de l’URL publique de l’image
    final url = await ref.getDownloadURL();
    logStorage("🔗 URL publique : $url");

    return url; // 📤 Retourne l’URL à stocker dans Firestore
  }

  /// 🔹 Supprime une image depuis Firebase Storage (si URL valide)
  ///
  /// 📥 Paramètre :
  /// - [imageUrl] : URL complète du fichier à supprimer
  Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      logStorage("⚠️ Aucune URL d’image fournie → rien à supprimer");
      return; // ❌ Rien à faire
    }

    try {
      logStorage("🗑️ Suppression image → $imageUrl");

      // 🔗 Récupère la référence Firebase Storage à partir de l’URL
      final ref = _storage.refFromURL(imageUrl);

      // ❌ Supprime le fichier dans Firebase Storage
      await ref.delete();

      logStorage("✅ Image supprimée : $imageUrl");
    } catch (e) {
      logStorage("❌ Erreur lors de la suppression de l'image : $e"); // ⚠️ Log d’erreur
    }
  }
}
