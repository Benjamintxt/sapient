// lib/services/firestore/flashcards_service.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // 📦 Firestore pour la base de données
import 'package:firebase_storage/firebase_storage.dart'; // 🗄️ Pour la gestion des fichiers image

import 'dart:io'; // 📂 Pour accéder aux fichiers locaux (ex: image)
import 'package:uuid/uuid.dart'; // 🔑 Générateur d'identifiants uniques

import 'core.dart'; // 🧩 Accès au FirestoreCore (singleton)
import 'navigation_service.dart'; // 🧭 Navigation dans la hiérarchie Firestore

const bool kEnableFlashcardsLogs = true; // ✅ Activer/désactiver les logs de debug flashcards

/// 🖨️ Méthode de log dédiée aux flashcards (affiche seulement si activé)
void logFlashcards(String message) {
  if (kEnableFlashcardsLogs) print(message);
}

/// 💡 Service gérant les flashcards (ajout, lecture, suppression, images)
class FirestoreFlashcardsService {
  final FirebaseFirestore _db = FirestoreCore().db; // 🔗 Instance de Firestore pour la base de données
  final FirebaseStorage _storage = FirebaseStorage.instance; // 🗄️ Accès à Firebase Storage pour les images
  final FirestoreNavigationService _nav = FirestoreNavigationService(); // 🧭 Service pour retrouver les chemins Firestore hiérarchiques

  /// 🔹 Récupère toutes les flashcards d'un sujet donné (résultat unique, non Stream)
  Future<QuerySnapshot<Map<String, dynamic>>> getFlashcardsRaw({
    required String userId, /// - [userId] : ID de l'utilisateur connecté
    required String subjectId, /// - [subjectId] : ID du sujet cible
    required int level, /// - [level] : niveau hiérarchique
    required List<String> parentPathIds, /// - [parentPathIds] : chemin hiérarchique complet
  }) async {
    logFlashcards("📔 [getFlashcardsRaw] user=$userId, level=$level, subject=$subjectId");

    // 🔗 Récupère la référence au document du sujet cible
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId, // 👤 Utilisateur
      level: level, // 🔢 Niveau hiérarchique
      parentPathIds: parentPathIds, // 🧭 Chemin parent
      subjectId: subjectId, // 🆔 ID sujet
    );

    // 📂 Accède à la collection des flashcards et les trie par date
    return await docRef.collection('flashcards').orderBy('timestamp').get();
  }

  /// 🔹 Ajoute une nouvelle flashcard dans un sujet donné
  Future<void> addFlashcard({
    required String userId, /// - ID utilisateur
    required String subjectId, /// - ID du sujet parent
    required int level, /// - Niveau dans la hiérarchie
    required List<String> parentPathIds, /// - Chemin complet dans la hiérarchie
    required String front, /// - Contenu du recto
    required String back, /// - Contenu du verso
    String? imageFrontUrl, /// - URL image recto (optionnelle)
    String? imageBackUrl, /// - URL image verso (optionnelle)
  }) async {
    logFlashcards("➕ [addFlashcard] subject=$subjectId, front=$front, back=$back");

    // 🔗 Référence au document du sujet
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds,
      subjectId: subjectId,
    );

    // 📝 Données à insérer
    final data = {
      'front': front, // ✏️ Texte recto
      'back': back, // ✏️ Texte verso
      'timestamp': FieldValue.serverTimestamp(), // ⏱️ Pour trier les flashcards
    };

    // 📸 Ajoute les images si présentes
    if (imageFrontUrl != null) data['imageFrontUrl'] = imageFrontUrl;
    if (imageBackUrl != null) data['imageBackUrl'] = imageBackUrl;

    // 🚀 Ajoute la flashcard à Firestore
    await docRef.collection('flashcards').add(data);
    logFlashcards("✅ Flashcard ajoutée dans ${docRef.path}");
  }

  /// 🔹 Met à jour une flashcard existante
  Future<void> updateFlashcard({
    required String userId, /// - ID utilisateur
    required String subjectId, /// - ID du sujet contenant la flashcard
    required int level, /// - Niveau hiérarchique du sujet
    required List<String> parentPathIds, /// - Chemin vers le sujet
    required String flashcardId, /// - ID de la flashcard à modifier
    required String front, /// - Nouveau texte recto
    required String back, /// - Nouveau texte verso
    String? imageFrontUrl, /// - Nouvelle URL image recto
    String? imageBackUrl, /// - Nouvelle URL image verso
  }) async {
    logFlashcards("✏️ [updateFlashcard] id=$flashcardId, front=$front, back=$back");

    // 🔗 Référence au sujet parent
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds,
      subjectId: subjectId,
    );

    // 📝 Données mises à jour
    final update = {
      'front': front,
      'back': back,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 📸 Ajout des images si fournies
    if (imageFrontUrl != null) update['imageFrontUrl'] = imageFrontUrl;
    if (imageBackUrl != null) update['imageBackUrl'] = imageBackUrl;

    // 💾 Mise à jour du document Firestore
    await docRef.collection('flashcards').doc(flashcardId).update(update);
    logFlashcards("✅ Mise à jour : ${docRef.path}/flashcards/$flashcardId");
  }

  /// 🔹 Supprime une flashcard et ses images si elles existent
  Future<void> deleteFlashcard({
    required String userId, /// - ID utilisateur
    required String subjectId, /// - ID sujet parent
    required int level, /// - Niveau dans la hiérarchie
    required List<String> parentPathIds, /// - Chemin complet jusqu'au sujet
    required String flashcardId, /// - ID de la flashcard à supprimer
  }) async {
    logFlashcards("🚮 [deleteFlashcard] id=$flashcardId");

    // 🔗 Référence au sujet
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds,
      subjectId: subjectId,
    );

    // 🔗 Référence à la flashcard spécifique
    final ref = docRef.collection('flashcards').doc(flashcardId);
    final snap = await ref.get(); // 📄 Lecture du document
    final data = snap.data(); // 📦 Contenu du document

    // 🔍 Si la flashcard existe et contient des images, on les supprime
    if (data != null) {
      Future<void> deleteImage(String? url) async {
        // ❗ Supprime uniquement si l'URL est valide
        if (url != null && url.isNotEmpty) {
          try {
            final ref = _storage.refFromURL(url); // 🔗 Référence au fichier dans Storage
            await ref.delete(); // 🗑️ Suppression
            logFlashcards("🖼️ Image supprimée : $url");
          } catch (e) {
            logFlashcards("❌ Erreur suppression image : $e");
          }
        }
      }
      await deleteImage(data['imageFrontUrl']); // 📸 Supprimer image recto
      await deleteImage(data['imageBackUrl']); // 📸 Supprimer image verso
    }

    // 🗑️ Supprime la flashcard de Firestore
    await ref.delete();
    logFlashcards("✅ Flashcard supprimée : ${ref.path}");
  }

  /// 🔹 Upload une image dans Firebase Storage et retourne son URL publique
  Future<String> uploadImage({
    required File image, /// - Fichier image à uploader (local)
    required String userId, /// - Utilisateur courant
    required String subjectId, /// - Sujet associé
    required List<String> parentPathIds, /// - Chemin vers le sujet (pour structure de dossier)
  }) async {
    logFlashcards("📄 [uploadImage] Début");

    final fileName = const Uuid().v4(); // 🔑 Génère un nom unique pour le fichier

    // 📁 Structure du chemin : flashcards/userId/subjectId/.../UUID.jpg
    final path = [
      'flashcards',
      userId,
      subjectId,
      ...parentPathIds,
      '$fileName.jpg',
    ].join('/');

    final ref = _storage.ref().child(path); // 🔗 Référence dans le storage

    await ref.putFile(image); // 🚀 Envoi du fichier
    final url = await ref.getDownloadURL(); // 🌐 Récupération de l'URL publique

    logFlashcards("✅ Image uploadée → $url");
    return url; // 📤 Retourne l'URL à stocker dans Firestore
  }

  /// 🔁 Récupère un Stream en temps réel des flashcards pour un sujet donné
  /// Permet d’écouter automatiquement les changements (ajouts/suppressions)
  Future<Stream<QuerySnapshot>> getFlashcardsStream({
    required String userId,           // 👤 ID de l'utilisateur connecté
    required String subjectId,        // 📚 ID du sujet (feuille) dont on veut les flashcards
    required int level,               // 🧭 Niveau hiérarchique (0 = racine, 1 = sous-sujet, ...)
    required List<String>? parentPathIds, // 🧱 Chemin des parents dans la hiérarchie (ex: ['abc', 'def'])
  }) async { // 🚀 Fonction asynchrone car elle récupère un DocumentReference avant de retourner un Stream

    // 🔍 Récupère dynamiquement la référence Firestore du sujet (feuille terminale)
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId,                 // 👤 Utilisateur courant (racine de la hiérarchie)
      level: level,                   // 🔢 Niveau dans la hiérarchie
      parentPathIds: parentPathIds!,  // 📂 Liste des parents, forcée non-nulle ici (assumée correcte)
      subjectId: subjectId,           // 🎯 ID du sujet terminal (feuille contenant les flashcards)
    ); // 📌 À ce stade, on a une référence du type : /users/{uid}/subjects/.../subsubjectX/{subjectId}

    // 📚 On cible la sous-collection "flashcards" sous ce document
    final flashcardsRef = docRef.collection('flashcards');

    // 🔄 Retourne un Stream des flashcards triées par date (timestamp croissant)
    return flashcardsRef.orderBy(
      'timestamp',                    // 🕒 Clé de tri : champ 'timestamp' (mis à jour à chaque ajout ou modif)
      descending: false,              // ⬆️ Ordre croissant (les plus anciennes en premier)
    ).snapshots();                    // 📡 Convertit la requête en un flux Stream en temps réel
  }


}