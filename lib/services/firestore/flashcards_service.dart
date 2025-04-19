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
    required String userId,            // 👤 ID de l'utilisateur connecté
    required String subjectId,        // 📚 ID du sujet (feuille terminale)
    required int level,               // 🔢 Niveau hiérarchique dans la structure
    required List<String> parentPathIds, // 🧭 Chemin des parents (depuis racine jusqu’au parent direct)
  }) async {
    logFlashcards("📔 [getFlashcardsRaw] Début → user=$userId | level=$level | subject=$subjectId");

    // ✅ Corrige les répétitions si subjectId est dupliqué à la fin de parentPathIds
    final correctedPath = [...parentPathIds]; // 🔁 Copie de la liste
    if (correctedPath.isNotEmpty && correctedPath.last == subjectId) {
      correctedPath.removeLast(); // ❌ Supprime l’ID final s’il est dupliqué
      logFlashcards("⚠️ [getFlashcardsRaw] Duplication détectée dans parentPathIds → suppression de l'ID final");
    }

    // 🔗 Récupère la référence au document du sujet cible (niveau donné dans la hiérarchie)
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId,                  // 👤 Utilisateur
      level: level,                    // 🔢 Niveau du sujet
      parentPathIds: correctedPath,   // 🧭 Chemin vers le parent du sujet
      subjectId: subjectId,           // 🆔 Sujet final (feuille contenant les flashcards)
    );
    logFlashcards("📌 Référence document sujet : ${docRef.path}");

    // 📂 Accède à la sous-collection "flashcards" et les trie par date croissante
    final result = await docRef.collection('flashcards')
        .orderBy('timestamp') // 🕒 Tri ascendant
        .get(); // 📦 Requête unique

    logFlashcards("📄 ${result.docs.length} flashcard(s) trouvée(s) dans ${docRef.path}");
    return result; // 🔁 Renvoie le snapshot Firestore contenant les flashcards
  }

  /// 🔹 Ajoute une nouvelle flashcard dans un sujet donné
  Future<void> addFlashcard({
    required String userId,           // 👤 ID utilisateur
    required String subjectId,        // 🆔 ID du sujet (feuille) dans lequel ajouter la carte
    required int level,               // 🔢 Niveau hiérarchique dans la structure
    required List<String> parentPathIds, // 🧭 Chemin complet vers le sujet (ex: [MathID, GeoID])
    required String front,            // 📄 Contenu du recto
    required String back,             // 📄 Contenu du verso
    String? imageFrontUrl,            // 🖼️ URL image recto (optionnelle)
    String? imageBackUrl,             // 🖼️ URL image verso (optionnelle)
  }) async {
    logFlashcards("➕ [addFlashcard] DÉBUT : subject=$subjectId | level=$level | parentPathIds=$parentPathIds");

    // ✅ Corrige les répétitions potentielles du sujetId dans parentPathIds
    final correctedPath = [...parentPathIds]; // 🧬 Clone de la liste pour ne pas modifier l’original
    if (correctedPath.isNotEmpty && correctedPath.last == subjectId) {
      logFlashcards("⚠️ [addFlashcard] Correction du chemin : suppression de l'ID dupliqué à la fin");
      correctedPath.removeLast(); // ❌ Supprime la redondance si présente
    }

    // 🔗 Récupère la référence du document cible (le sujet terminal)
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: correctedPath,
      subjectId: subjectId,
    );
    logFlashcards("📌 Référence obtenue : ${docRef.path}");

    // 📝 Prépare les données de la nouvelle flashcard
    final data = {
      'front': front,                                // 🖊 Texte recto
      'back': back,                                  // 🖊 Texte verso
      'timestamp': FieldValue.serverTimestamp(),     // ⏱ Date/heure automatique pour tri
    };

    // 🖼️ Ajout conditionnel des images si présentes
    if (imageFrontUrl != null) data['imageFrontUrl'] = imageFrontUrl;
    if (imageBackUrl != null) data['imageBackUrl'] = imageBackUrl;

    // 🚀 Envoi dans Firestore dans la sous-collection `flashcards`
    await docRef.collection('flashcards').add(data);
    logFlashcards("✅ Flashcard ajoutée dans ${docRef.path}/flashcards");
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
    required String userId,           // 👤 ID de l'utilisateur connecté
    required String subjectId,        // 🆔 ID du sujet contenant la flashcard
    required int level,               // 🔢 Niveau hiérarchique (ex: 3 pour subsubject3)
    required List<String> parentPathIds, // 🧭 Chemin complet vers le sujet
    required String flashcardId,      // 🃏 ID unique de la flashcard à supprimer
  }) async {
    logFlashcards("🚮 [deleteFlashcard] DÉBUT → subject=$subjectId | level=$level | flashcardId=$flashcardId");

    // ✅ Corrige les éventuelles répétitions de subjectId dans parentPathIds
    final correctedPath = [...parentPathIds]; // 🧬 Copie sécurisée
    if (correctedPath.isNotEmpty && correctedPath.last == subjectId) {
      correctedPath.removeLast(); // ❌ Supprime la duplication si elle existe
      logFlashcards("⚠️ [deleteFlashcard] Correction du chemin : suppression du dernier ID dupliqué");
    }

    // 🔗 Récupère la référence du document sujet contenant la flashcard
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: correctedPath,
      subjectId: subjectId,
    );
    logFlashcards("📌 Référence sujet = ${docRef.path}");

    // 🔗 Récupère la référence exacte de la flashcard à supprimer
    final ref = docRef.collection('flashcards').doc(flashcardId);
    final snap = await ref.get(); // 🔍 Lecture du document flashcard
    final data = snap.data(); // 📦 Récupère les données (peut contenir des URLs d'image)

    // 🧹 Supprime les images si elles sont présentes dans le document
    if (data != null) {
      Future<void> deleteImage(String? url) async {
        if (url != null && url.isNotEmpty) {
          try {
            final imageRef = _storage.refFromURL(url); // 🔗 Référence à l'image dans Firebase Storage
            await imageRef.delete(); // 🗑️ Supprime le fichier distant
            logFlashcards("🖼️ Image supprimée depuis le storage : $url");
          } catch (e) {
            logFlashcards("❌ Erreur lors de la suppression de l'image : $e");
          }
        }
      }

      await deleteImage(data['imageFrontUrl']); // 🖼️ Supprime image recto si présente
      await deleteImage(data['imageBackUrl']);  // 🖼️ Supprime image verso si présente
    } else {
      logFlashcards("⚠️ Aucune donnée trouvée pour la flashcard $flashcardId (peut déjà être supprimée)");
    }

    // 🗑️ Supprime le document flashcard dans Firestore
    await ref.delete();
    logFlashcards("✅ Flashcard supprimée avec succès : ${ref.path}");
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
  /// 🔁 Permet d’écouter automatiquement les changements (ajouts/suppressions) de flashcards en temps réel
  Future<Stream<QuerySnapshot>> getFlashcardsStream({
    required String userId,            // 👤 ID de l'utilisateur connecté
    required String subjectId,         // 📚 ID du sujet (feuille) dont on veut les flashcards
    required int level,                // 🧭 Niveau hiérarchique (0 = racine, 1 = sous-sujet, ...)
    required List<String>? parentPathIds, // 🧱 Chemin des parents dans la hiérarchie (ex: ['abc', 'def'])
  }) async {
    // 📝 Log d'entrée
    logFlashcards("📡 [getFlashcardsStream] → user=$userId | level=$level | subject=$subjectId");

    // ✅ Copie de parentPathIds pour éviter les effets de bord
    final correctedPath = [...?parentPathIds];

    // ⚠️ Correction automatique si le dernier ID de parentPathIds est égal à subjectId
    if (correctedPath.isNotEmpty && correctedPath.last == subjectId) {
      correctedPath.removeLast(); // ❌ Supprime la duplication
      logFlashcards("⚠️ [getFlashcardsStream] Duplication détectée dans parentPathIds → suppression du dernier élément");
    }

    // 🔍 Récupère dynamiquement la référence Firestore du sujet (feuille terminale)
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId,               // 👤 Utilisateur courant
      level: level,                 // 🔢 Niveau dans la hiérarchie
      parentPathIds: correctedPath, // ✅ Chemin corrigé
      subjectId: subjectId,         // 🆔 ID de la feuille terminale
    );

    // 📝 Log de la référence obtenue
    logFlashcards("📌 Référence sujet cible : ${docRef.path}");

    // 📁 Accès à la sous-collection "flashcards" sous ce document
    final flashcardsRef = docRef.collection('flashcards');
    logFlashcards("📂 Accès à la sous-collection : ${flashcardsRef.path}");

    // 🔁 Préparation du Stream des flashcards triées par date croissante
    final stream = flashcardsRef
        .orderBy('timestamp', descending: false) // 🕒 Tri par timestamp croissant
        .snapshots();                            // 📡 Flux en temps réel

    // 🟢 Log de confirmation
    logFlashcards("✅ [getFlashcardsStream] Flux prêt (écoute en temps réel des flashcards)");

    return stream; // 🔁 Retourne le flux au widget
  }




}