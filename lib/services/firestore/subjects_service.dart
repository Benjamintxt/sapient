// lib/services/firestore/subjects_service.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // 📦 Firestore pour la base de données
import 'package:intl/intl.dart'; // ⏰ Pour le formatage de date
import 'core.dart'; // 🥉 Singleton Firestore (depuis le même dossier)
import 'navigation_service.dart'; // 🧱 Navigation hiérarchique dans Firestore (depuis le même dossier)

const bool kEnableSubjectsLogs = true; // 🟢 Constante activant ou désactivant les logs de debug

/// 🖨️ Fonction utilitaire pour afficher les logs de sujet uniquement si activés
void logSubjects(String message) {
  if (kEnableSubjectsLogs) print(message); // ✅ Affiche les logs uniquement si activés
}

/// 📚 Service de gestion des sujets dans Firestore (ajout, récupération, suppression)
class FirestoreSubjectsService {
  final FirebaseFirestore _db = FirestoreCore().db; // 🔗 Instance de Firestore locale
  final FirestoreNavigationService _nav = FirestoreNavigationService(); // 🧭 Service de navigation dans la hiérarchie

  /// 🔹 Crée un nouveau sujet à un niveau donné (racine ou sous-niveau)
  Future<void> createSubject({
    required String name, // 🌿 Nom du sujet à créer (ex : "Maths")
    required int level, // 🔢 Niveau hiérarchique (0 = racine, 1 = sous-niveau, etc.)
    required bool isCategory, // 📁 true si le sujet contient des sous-sujets
    List<String>? parentPathIds, // 🧭 Liste des IDs des parents dans la hiérarchie (si level > 0)
  }) async {
    final String? userId = FirestoreCore.getCurrentUserUid(); // 🔐 Récupération de l'ID utilisateur actuellement connecté

    // ❗ Vérifie que l'utilisateur est connecté
    if (userId == null) {
      logSubjects("❌ [createSubject] Utilisateur non connecté"); // 🛑 Log si l'utilisateur est déconnecté
      throw Exception("User not authenticated."); // 🚫 Erreur levée si pas connecté
    }

    // 📝 Log de démarrage avec les paramètres fournis
    logSubjects("🚀 [createSubject] name=$name | level=$level | isCategory=$isCategory | parents=$parentPathIds");

    final formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.now()); // 📆 Date actuelle formatée pour affichage

    CollectionReference collectionRef; // 📁 Référence vers la collection où insérer le sujet

    // 🔍 Cas 1 : niveau racine (level == 0)
    if (level == 0) {
      collectionRef = _db.collection('users') // 📁 Accès à la collection "users"
        .doc(userId) // 📄 Document de l'utilisateur courant
        .collection('subjects'); // 📁 Collection des sujets racine
      logSubjects("📍 Insertion racine : ${collectionRef.path}"); // 🖨️ Affiche le chemin de la collection
    } else {
      // 🔍 Cas 2 : sous-sujet (niveau > 0)

      // ❗ Vérifie que la liste des IDs parents est fournie et de la bonne taille
      if (parentPathIds == null || parentPathIds.length != level) {
        logSubjects("❌ [createSubject] parentPathIds invalides pour level=$level"); // 🛑 Log erreur
        throw Exception("Invalid parentPathIds for level $level"); // 🚫 Lève une erreur explicite
      }

      // 🔗 Récupère la référence du document parent via le service de navigation
      final docRef = await _nav.getSubSubjectDocRef(
        userId: userId, // 👤 ID de l'utilisateur
        level: level - 1, // 🔢 Niveau du parent (un en dessous du sujet à créer)
        parentPathIds: parentPathIds.sublist(0, level - 1), // 🧭 Chemin jusqu'au parent
        subjectId: parentPathIds[level - 1], // 🆔 ID du sujet parent direct
      );

      // 📁 Accès à la sous-collection subsubjectX correspondante
      collectionRef = docRef.collection('subsubject$level');
      logSubjects("📂 Insertion niveau $level dans : ${collectionRef.path}");
    }

    final newDoc = collectionRef.doc(); // 🆕 Génération d'un ID auto pour le nouveau sujet

    // 📝 Création du document Firestore avec les champs requis
    await newDoc.set({
      'name': name, // 🏷️ Nom du sujet
      'isCategory': isCategory, // ✅ true si le sujet contient des sous-sujets
      'createdAt': formattedDate, // 📅 Date formatée (utile pour l'affichage)
      'timestamp': FieldValue.serverTimestamp(), // ⏱️ Timestamp technique Firestore (tri par date)
    });

    logSubjects("✅ Sujet créé : ${newDoc.path}"); // 🖨️ Log de succès
  }

  /// 🔹 Récupère un `Stream` (flux temps réel) des sujets à un niveau donné
  /// 🔹 Récupère un `Stream` (flux temps réel) des sujets à un niveau donné.
  /// Cette méthode se connecte à Firestore et renvoie un flux de données en temps réel pour les sujets.
  /// Elle vérifie également si l'utilisateur est authentifié et gère la hiérarchie des sous-sujets.
  ///
  /// Paramètres:
  /// - `level`: Le niveau hiérarchique du sujet à récupérer. Par exemple, `0` pour les sujets racines,
  ///   `1` pour les sous-sujets, etc.
  /// - `parentPathIds`: La liste des IDs des sujets parents à travers les différents niveaux. Si le niveau est
  ///   supérieur à 0, cette liste est nécessaire pour retrouver le bon chemin dans Firestore.
  ///
  /// Retourne un `Stream<QuerySnapshot>` contenant les sujets à ce niveau.
  /// 🔹 Récupère un `Stream<QuerySnapshot>` des sujets (catégories ou feuilles) pour un niveau donné dans la hiérarchie
  ///
  /// Cette méthode gère à la fois :
  /// - les sujets racines (`level == 0`) : récupérés depuis `/users/{uid}/subjects`
  /// - les sous-sujets (`level >= 1`) : récupérés via le chemin `/subsubjectX`, déterminé dynamiquement
  ///
  /// Elle utilise une structure hiérarchique pour Firestore :
  /// Exemples :
  /// - Racine (niveau 0)        → `/users/{uid}/subjects`
  /// - Sous-niveau 1 (niveau 1) → `/users/{uid}/subjects/{id}/subsubject1`
  /// - Sous-niveau 2 (niveau 2) → `/users/{uid}/subjects/{id}/subsubject1/{id}/subsubject2`
  /// etc.
  Future<Stream<QuerySnapshot>> getSubjectsAtLevel(int level, List<String>? parentPathIds) async {
    // 🔐 Étape 1 : On récupère l'utilisateur connecté
    final String? userId = FirestoreCore.getCurrentUserUid(); // 🔑 UID de l'utilisateur Firebase

    // ❌ Si aucun utilisateur connecté, on ne peut rien faire
    if (userId == null) {
      logSubjects("❌ [getSubjectsAtLevel] Utilisateur non connecté");
      throw Exception("User not authenticated."); // 🧱 Interruption explicite
    }

    // 🔍 Étape 2 : Log des infos reçues
    logSubjects("🔍 [getSubjectsAtLevel] user=$userId | level=$level | parentPathIds=$parentPathIds");

    // 🏁 Cas 1 : niveau 0 = racine → on accède directement à /subjects
    if (level == 0) {
      final ref = _db
          .collection('users') // 📁 Collection globale des utilisateurs
          .doc(userId)         // 📄 Document utilisateur actuel
          .collection('subjects'); // 📁 Collection des sujets racine

      logSubjects("📁 Racine : ${ref.path}"); // 🖨️ Log du chemin
      return ref
          .orderBy('createdAt', descending: false) // ⏱️ Trie par date de création (ancienne → récente)
          .snapshots(); // 📡 Flux Firestore en temps réel
    }

    // 🚧 Cas 2 : niveau > 0 → on doit avoir exactement autant d'IDs de parents que de niveaux
    if (parentPathIds == null || parentPathIds.length != level) {
      logSubjects("❌ [getSubjectsAtLevel] parentPathIds invalides : $parentPathIds pour level=$level");
      throw Exception("Invalid parentPathIds for level $level"); // 🛑 Erreur si incohérent
    }

    try {
      // 🧭 Étape 3 : on utilise le service de navigation pour récupérer la bonne collection
      final collection = await _nav.getSubSubjectCollection(
        userId: userId,            // 👤 Utilisateur actuel
        level: level,              // 🔢 Niveau à atteindre
        parentPathIds: parentPathIds, // 🧱 Liste des IDs menant au niveau actuel
      );

      // 🛰️ Étape 4 : On affiche le chemin résolu pour debug
      logSubjects("📡 Flux de sujets de : ${collection.path}");

      // ✅ Étape 5 : On retourne le flux des documents Firestore de cette collection
      return collection
          .orderBy('createdAt', descending: false) // 🗂️ Trie les sujets par ordre chronologique
          .snapshots(); // 🔁 Retourne un Stream temps réel
    } catch (e) {
      // ❌ En cas d’erreur dans getSubSubjectCollection (ex : mauvais chemin)
      logSubjects("❌ Exception dans getSubSubjectCollection : $e");
      rethrow; // 🚨 Propagation vers le StreamBuilder (affichera l’erreur)
    }
  }




  /// 🔹 Supprime un sujet et tous ses sous-sujets ou flashcards associées récursivement
  Future<void> deleteSubject({
    required String subjectId, // 🆔 ID du sujet à supprimer
    required int level, // 🔢 Niveau dans la hiérarchie
    required List<String> parentPathIds, // 🧭 Liste des parents
  }) async {
    final String? userId = FirestoreCore.getCurrentUserUid(); // 🔐 Récupère l'utilisateur connecté

    // ❗ Vérifie l'authentification
    if (userId == null) {
      logSubjects("❌ [deleteSubject] Utilisateur non connecté");
      throw Exception("User not authenticated.");
    }

    logSubjects("🗑️ [deleteSubject] subjectId=$subjectId | level=$level | parentPathIds=$parentPathIds");

    // 🔗 Référence vers le document du sujet à supprimer
    final docRef = await _nav.getSubSubjectDocRef(
      userId: userId, // 👤 ID utilisateur
      level: level, // 🔢 Niveau actuel
      parentPathIds: parentPathIds, // 🧭 Chemin des parents
      subjectId: subjectId, // 🆔 ID du sujet cible
    );

    final snapshot = await docRef.get(); // 📄 Récupération du document

    // ❗ Vérifie si le sujet existe réellement
    if (!snapshot.exists) {
      logSubjects("⚠️ Sujet inexistant : ${docRef.path}");
      return; // 🚪 Sort de la fonction si le sujet n'existe pas
    }

    final data = snapshot.data() as Map<String, dynamic>; // 📦 Données du sujet
    final isCategory = data['isCategory'] ?? false; // ✅ Détermine s'il s'agit d'une catégorie
    logSubjects("📄 Sujet trouvé : ${data['name']} (isCategory=$isCategory)");

    // 🔁 Si c’est une catégorie, supprimer récursivement les enfants
    if (isCategory) {
      for (int nextLevel = level + 1; nextLevel <= 5; nextLevel++) {
        final children = await docRef.collection('subsubject$nextLevel').get(); // 📁 Sous-sujets
        logSubjects("🔍 ${children.docs.length} enfants trouvés dans subsubject$nextLevel");
        for (var child in children.docs) {
          await deleteSubject(
            subjectId: child.id, // 🆔 ID de l'enfant
            level: nextLevel, // 🔢 Niveau de l'enfant
            parentPathIds: [...parentPathIds, subjectId], // ➕ Mise à jour du chemin
          );
        }
      }
    } else {
      // 🧼 Sinon, suppression des flashcards liées
      final flashcards = await docRef.collection('flashcards').get();
      logSubjects("📘 ${flashcards.docs.length} flashcard(s) à supprimer");
      for (var card in flashcards.docs) {
        await card.reference.delete(); // 🗑️ Suppression des flashcards
      }
    }

    await docRef.delete(); // 🗑️ Suppression du sujet lui-même
    logSubjects("✅ Sujet supprimé : ${docRef.path}");
  }

  /// 🔹 Récupère les noms lisibles des sujets dans l'arborescence à partir des IDs parents
  Future<List<String>> getSubjectNamesFromPath({
    required String userId,
    required List<String> parentPathIds,
  }) async {
    logSubjects("🔎 [getSubjectNamesFromPath] user=$userId | path=$parentPathIds");

    // Cas spécial : pas de parents → on retourne directement une liste vide (ou un nom générique)
    if (parentPathIds.isEmpty) {
      logSubjects("⚠️ [getSubjectNamesFromPath] parentPathIds vide, retourne []");
      return [];
    }

    final List<String> names = [];

    // 📘 Accès au niveau 0
    DocumentReference currentRef = _db
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(parentPathIds[0]);

    final rootSnap = await currentRef.get();
    final rootName = (rootSnap.data() as Map<String, dynamic>?)?['name'] ?? 'unknown';
    names.add(rootName);
    logSubjects("✅ Nom niveau 0 : $rootName");

    // 🔁 Niveaux suivants
    for (int i = 1; i < parentPathIds.length; i++) {
      final subCollection = 'subsubject$i';
      final docId = parentPathIds[i];
      currentRef = currentRef.collection(subCollection).doc(docId);

      try {
        final docSnap = await currentRef.get();
        final name = (docSnap.data() as Map<String, dynamic>?)?['name'] ?? 'unknown';
        names.add(name);
        logSubjects("✅ Nom niveau $i : $name");
      } catch (e) {
        logSubjects("❌ Erreur niveau $i : $e");
        names.add('unknown');
      }
    }

    logSubjects("📋 Noms finaux = $names");
    return names;
  }


  /// 🔹 Récupère les sujets racine (niveau 0) en une seule fois (QuerySnapshot)
  Future<QuerySnapshot> getRootSubjectsOnce() async {
    final String? userId = FirestoreCore.getCurrentUserUid();

    if (userId == null) {
      logSubjects("❌ [getRootSubjectsOnce] Utilisateur non connecté");
      throw Exception("User not authenticated.");
    }

    final ref = _db.collection('users').doc(userId).collection('subjects');
    logSubjects("📥 Lecture des sujets racine : ${ref.path}");

    return await ref.orderBy('createdAt', descending: false).get();
  }


}