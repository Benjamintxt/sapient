// lib/services/firestore/revisions_service.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // 📆 Firestore pour accéder à la base de données
import 'package:intl/intl.dart'; // ⏰ Pour le formatage de la date

import 'core.dart'; // 🧰 Accès à FirestoreCore (singleton utilisateur)
import 'navigation_service.dart'; // 🗭 Service de navigation hiérarchique dans Firestore

import 'subjects_service.dart'; // 📚 Pour accéder aux noms des sujets

const bool kEnableRevisionsLogs = true; // ✅ Active les logs debug pour les révisions

/// 📢 Fonction de log conditionnelle pour le service de révision
void logRevisions(String message) {
  if (kEnableRevisionsLogs) print(message); // 🖨️ Affiche le message uniquement si les logs sont activés
}

/// 🌀 Service Firestore pour gérer les statistiques de révision :
/// enregistrement de réponses, création de structure, statistiques globales...
class FirestoreRevisionsService {
  final FirebaseFirestore _db = FirestoreCore().db; // 🔗 Instance principale de Firestore
  final FirestoreNavigationService _nav = FirestoreNavigationService(); // 🗺️ Service pour gérer les chemins dynamiques dans Firestore

  /// 🔹 Enregistre une réponse à une flashcard pour une date et un sujet donné
  Future<void> recordAnswerForDayAndTheme({
    required String userId, // 👤 Identifiant utilisateur
    required String flashcardId, // 🃏 Identifiant de la flashcard
    required bool isCorrect, // ✅ true si la réponse est correcte
    required int durationSeconds, // ⏱ Temps mis pour répondre
    required String subjectId, // 📁 ID du sujet (doit être une feuille)
    required int level, // 🔢 Niveau de profondeur
    required List<String> parentPathIds, // 🧭 Chemin hiérarchique des IDs parents
  }) async {
    // 📆 Récupère la date d’aujourd’hui au format "yyyy-MM-dd"
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    logRevisions("🗓 [recordAnswer] Date=$today | Flashcard=$flashcardId | Correct=$isCorrect");

    // 📍 Référence vers le document du jour dans /revision_stats
    DocumentReference currentRef = _db
        .collection('users')
        .doc(userId)
        .collection('revision_stats')
        .doc(today);

    // 🆕 Crée le document du jour s’il n’existe pas encore
    await currentRef.set({ 'createdAt': FieldValue.serverTimestamp() }, SetOptions(merge: true));

    // 📘 Récupère les noms lisibles pour chaque niveau de la hiérarchie
    final subjectNames = await FirestoreSubjectsService().getSubjectNamesFromPath(
      userId: userId,
      parentPathIds: parentPathIds,
    );

    // ✅ Copie la liste des IDs parents pour pouvoir la modifier sans impacter l’original
    final correctedParentPathIds = [...parentPathIds];

    // 🛑 Sécurité : si le dernier ID des parents est égal à celui du sujet, on le supprime (évite la duplication)
    if (correctedParentPathIds.isNotEmpty && correctedParentPathIds.last == subjectId) {
      correctedParentPathIds.removeLast();
      logRevisions("⚠️ [recordAnswer] Correction parentPathIds → suppression du dernier ID car il était dupliqué avec subjectId");
    }

    // 📄 Récupère la référence Firestore du document sujet final (feuille)
    final finalRef = await _nav.getSubSubjectDocRef(
      userId: userId,                       // 👤 ID utilisateur
      level: level,                         // 🔢 Niveau de profondeur dans la hiérarchie
      parentPathIds: correctedParentPathIds, // 🧭 Chemin corrigé sans duplicata
      subjectId: subjectId,                // 🆔 ID du sujet cible
    );
    logRevisions("📌 Référence finale du sujet = ${finalRef.path}");

    final snap = await finalRef.get(); // 🔍 Lecture du document Firestore

    // 📄 Récupère les données du document sujet terminal (ex: "A1")
    final data = snap.data() as Map<String, dynamic>?;

// 🛑 Sécurité : vérifie que le champ 'name' est bien présent
    if (data == null || data['name'] == null) {
      throw Exception("❌ Champ 'name' manquant dans le document sujet ${finalRef.path}");
    }

// ✅ Si tout va bien, on récupère le nom lisible (ex: "A1")
    final lastName = data['name'] as String;

// ➕ Ajoute ce nom à la liste des noms lisibles (pour construire la hiérarchie)
    subjectNames.add(lastName);

    // 🔁 Parcours de tous les niveaux de l’arborescence (y compris la feuille)
    for (int i = 0; i < parentPathIds.length; i++) {
      logRevisions("🔗 [recordAnswer] Création niveau $i → ID=${parentPathIds[i]} | Nom=${subjectNames[i]}");

      currentRef = await _nav.ensureLevelDocument(
        parentRef: currentRef,              // 🔗 Document parent (niveau précédent dans la hiérarchie)
        levelKey: subjectNames[i],          // 🏷️ Nom lisible (ex: 'Anglais', 'Grammaire')
        docId: parentPathIds[i],            // 🆔 ID du document à créer/mettre à jour
        subjectName: subjectNames[i],       // 📛 Nom affiché dans Firestore (pour debug ou UI)
      );
    }

// ✅ Ajout final du niveau terminal (la feuille, ex: 'A1')
    logRevisions("🏁 [recordAnswer] Insertion du niveau terminal (feuille) → ID=$subjectId | Nom=$lastName");

    final subjectRef = await _nav.ensureLevelDocument(
      parentRef: currentRef,      // 🔗 Dernier document intermédiaire (niveau juste au-dessus de la feuille)
      levelKey: lastName,         // 🏷️ Nom de la collection contenant la feuille (ex: 'A1')
      docId: subjectId,           // 🆔 ID du document feuille (la flashcard est rattachée à ce sujet)
      subjectName: lastName,      // 📛 Nom lisible pour la feuille
    );


    // 📍 Référence unique de la réponse à cette flashcard dans 'answers'
    final answerRef = subjectRef.collection('answers').doc(flashcardId);

    // 📝 Enregistrement de la réponse (merge avec existant)
    await answerRef.set({
      'flashcardId': flashcardId, // 🆔 ID unique
      'subjectId': subjectId, // 📁 Sujet de la flashcard
      'level': level, // 🔢 Niveau de profondeur
      'parentPathIds': parentPathIds, // 🧭 Arborescence complète
      'lastIsCorrect': isCorrect, // ✅ Bonne réponse ?
      'lastTimestamp': FieldValue.serverTimestamp(), // 🕒 Dernière date de réponse
      'correctCount': FieldValue.increment(isCorrect ? 1 : 0), // ➕ Incrémente bonnes
      'wrongCount': FieldValue.increment(isCorrect ? 0 : 1), // ➕ Incrémente erreurs
      'totalDuration': FieldValue.increment(durationSeconds), // ⏱ Temps cumulé
    }, SetOptions(merge: true));

    // 📊 Référence au résumé global des révisions du sujet
    final summaryRef = subjectRef.collection('meta').doc('revision_summary');

    // 🧮 Mise à jour du résumé global
    await summaryRef.set({
      'correctTotal': FieldValue.increment(isCorrect ? 1 : 0), // ✅ +1 si bonne
      'wrongTotal': FieldValue.increment(isCorrect ? 0 : 1), // ❌ +1 si erreur
      'revisionCount': FieldValue.increment(1), // 🔁 +1 révision
      'totalDuration': FieldValue.increment(durationSeconds), // ⏱ Temps cumulé
      'lastUpdated': FieldValue.serverTimestamp(), // 📅 Date mise à jour
      'flashcardsSeen': FieldValue.arrayUnion([flashcardId]), // 👀 Ajoute l’ID si absent
    }, SetOptions(merge: true));

    // ✅ Log final
    logRevisions("✅ Révision enregistrée pour $flashcardId dans $today/$lastName");
  }

  /// 🔹 Calcule les statistiques globales de la journée (correct, erreurs, pourcentage, flashcards vues...)
  Future<Map<String, dynamic>> getTodayGlobalSummary(String userId) async {
    // 📆 Récupère la date du jour au format "yyyy-MM-dd"
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    logRevisions("📊 [getTodayGlobalSummary] pour $today");

    // 📁 Référence vers le document du jour dans /revision_stats
    final statsRef = _db.collection('users').doc(userId).collection('revision_stats').doc(today);

    // 🧮 Initialisation des compteurs cumulés
    int totalCorrect = 0; // ✅ Nombre total de bonnes réponses
    int totalWrong = 0;   // ❌ Nombre total de mauvaises réponses
    int revisionCount = 0; // 🔁 Nombre total de révisions effectuées

    // 👀 Ensemble des flashcards uniques vues (pas de doublons)
    final Set<String> seenFlashcards = {};

    // 🔁 Fonction récursive qui explore toute l’arborescence des sous-sujets du jour
    Future<void> explore(DocumentReference ref) async {
      logRevisions("🔎 [explore] Exploration de ${ref.path}");

      // 📚 Récupère les sous-collections de ce document (ex: subsubject1, subsubject2...)
      final subCollections = await _nav.getSubCollectionsFromDoc(ref);
      logRevisions("📦 Sous-collections retournées : ${subCollections.keys}");

      // 🔁 Pour chaque sous-collection (ex: subsubject1 → [docA, docB...])
      for (final colName in subCollections.keys) {
        for (final doc in subCollections[colName]!.docs) {
          logRevisions("📁 Document trouvé : ${doc.reference.path}");

          // 📄 Accède au résumé de révision : /meta/revision_summary
          final summary = await doc.reference.collection('meta').doc('revision_summary').get();

          if (summary.exists) {
            final data = summary.data()!; // 📦 Récupère les données du résumé
            logRevisions("📋 Données résumé dans ${doc.reference.path}/meta/revision_summary = $data");

            // ✅ Incrémente les compteurs globaux
            totalCorrect += (data['correctTotal'] ?? 0) as int;
            totalWrong += (data['wrongTotal'] ?? 0) as int;
            revisionCount += (data['revisionCount'] ?? 0) as int;

            // 👁️ Récupère les flashcards vues et les ajoute à l'ensemble
            final seenList = (data['flashcardsSeen'] as List?)?.cast<String>() ?? [];
            seenFlashcards.addAll(seenList);
            logRevisions("➕ ${seenList.length} flashcard(s) vues ajoutée(s), total unique = ${seenFlashcards.length}");
          } else {
            logRevisions("⚠️ Aucun résumé trouvé pour ${doc.reference.path}/meta/revision_summary");
          }

          // 🔁 Appelle récursivement cette fonction pour explorer plus bas
          await explore(doc.reference);
        }
      }
    }

    // ✅ Si le document du jour existe, on commence l’exploration
    final exists = await statsRef.get();
    if (exists.exists) {
      await explore(statsRef);
    } else {
      logRevisions("⚠️ Aucun document de stats trouvé pour $today");
    }

    // 📈 Calcule le pourcentage de succès en arrondissant
    final successRate = revisionCount == 0
        ? 0
        : ((totalCorrect / (totalCorrect + totalWrong)) * 100).round();
    logRevisions("📊 Taux de succès = $successRate%");

    // 📦 Résumé final retourné
    final summary = {
      'correctTotal': totalCorrect, // ✅ Total de bonnes réponses
      'wrongTotal': totalWrong, // ❌ Total d’erreurs
      'revisionCount': revisionCount, // 🔁 Révisions effectuées
      'flashcardsSeen': seenFlashcards.length, // 👁️ Nombre unique de flashcards vues
      'successRate': successRate, // 📈 Taux de réussite
    };

    logRevisions("📦 Résumé final des stats = $summary");
    return summary;
  }


  /// 🔢 Compte toutes les flashcards de l'utilisateur, dans tous les sujets terminaux (feuilles)
  Future<int> getTotalFlashcardsCount(String userId) async {
    int total = 0; // 🧮 Initialisation du compteur global

    logRevisions("🧭 [getTotalFlashcardsCount] Début du comptage des flashcards pour l'utilisateur : $userId");

    // 📁 Référence au document utilisateur
    final userRef = _db.collection('users').doc(userId);

    // 📚 Récupère tous les sujets racines (niveau 0)
    final rootSubjects = await userRef.collection('subjects').get();
    logRevisions("📚 ${rootSubjects.docs.length} sujet(s) racine(s) trouvés pour l'utilisateur");

    /// 🔁 Fonction récursive pour parcourir l’arborescence et compter les flashcards dans les feuilles
    Future<void> countFlashcardsRecursive(DocumentReference docRef) async {
      // 📄 Lecture des données du sujet courant
      final data = (await docRef.get()).data() as Map<String, dynamic>?;

      // ❓ Vérifie si ce sujet est une catégorie ou une feuille
      final isCategory = data?['isCategory'] == true; // ✅ vérifie explicitement true

      final subjectName = data?['name'] ?? 'inconnu';

      if (!isCategory) {
        // ✅ Sujet terminal : on compte les flashcards dans la collection 'flashcards'
        final flashcardsSnap = await docRef.collection('flashcards').get();
        total += flashcardsSnap.size; // ➕ Ajout au compteur global
        logRevisions("🟢 Sujet feuille '$subjectName' → ${flashcardsSnap.size} flashcard(s)");
        return;
      }

      // 🔁 Si ce n’est pas une feuille, on explore les sous-collections possibles
      for (int level = 1; level <= 5; level++) {
        final subColName = 'subsubject$level'; // 🏷️ Nom de la sous-collection potentielle
        final subColSnap = await docRef.collection(subColName).get(); // 📥 Documents de cette sous-collection

        if (subColSnap.docs.isNotEmpty) {
          logRevisions("📂 Sujet '$subjectName' contient ${subColSnap.docs.length} sous-sujet(s) dans '$subColName'");
        }

        // 🔁 Appel récursif pour chaque sous-sujet trouvé
        for (final subDoc in subColSnap.docs) {
          await countFlashcardsRecursive(subDoc.reference);
        }
      }
    }

    // 🚀 Lance le parcours récursif pour chaque sujet racine
    for (final doc in rootSubjects.docs) {
      await countFlashcardsRecursive(doc.reference);
    }

    logRevisions("✅ [getTotalFlashcardsCount] Total final = $total flashcard(s)");
    return total; // 🎯 Résultat retourné
  }


}
