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

// 🔁 Parcours de tous les niveaux de l’arborescence (sans inclure la feuille)
    for (int i = 0; i < parentPathIds.length; i++) {
      final levelKey = 'subsubject$i'; // 🏷️ Convention normée pour la collection (ex: subsubject0, subsubject1)

      // 🖨️ Log détaillé du niveau en cours de création
      logRevisions("🔗 [recordAnswer] Création niveau $i → ID=${parentPathIds[i]} | Nom=${subjectNames[i]} | levelKey=$levelKey");

      // 📦 Crée (ou récupère) le document correspondant à ce niveau intermédiaire
      currentRef = await _nav.ensureLevelDocument(
        parentRef: currentRef,          // 🔗 Document parent (niveau précédent)
        levelKey: levelKey,             // 🏷️ Nom normé de la collection (subsubjectX)
        docId: parentPathIds[i],        // 🆔 ID du document à créer ou récupérer
        subjectName: subjectNames[i],   // 📛 Nom lisible du sujet (affiché dans le champ 'name')
      );
    }

// 🏁 Dernier niveau : ajout de la feuille finale (ex: 'A1')
// 📁 La feuille est placée dans une collection nommée 'subsubject{level}'
    final lastLevelKey = 'subsubject$level'; // 🏷️ Collection contenant la feuille

// 🖨️ Log de confirmation
    logRevisions("🏁 [recordAnswer] Insertion du niveau terminal (feuille) → ID=$subjectId | Nom=$lastName | levelKey=$lastLevelKey");

// 📝 Création (ou récupération) du document feuille
    final subjectRef = await _nav.ensureLevelDocument(
      parentRef: currentRef,      // 🔗 Dernier document intermédiaire (niveau juste au-dessus)
      levelKey: lastLevelKey,     // 🏷️ Collection finale (subsubjectX)
      docId: subjectId,           // 🆔 ID de la feuille
      subjectName: lastName,      // 📛 Nom lisible pour la feuille (ex: 'A1')
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
  /// 🔹 Calcule les statistiques globales de la journée (correct, erreurs, pourcentage, flashcards vues...)
  ///    et ajoute les nouvelles métriques : temps moyen par révision et par flashcard
  Future<Map<String, dynamic>> getTodayGlobalSummary(String userId) async {
    // 📆 Récupère la date du jour au format "yyyy-MM-dd"
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    logRevisions("📊 [getTodayGlobalSummary] pour $today");

    // 📁 Référence vers le document de stats du jour
    final statsRef = _db
        .collection('users') // 🔗 Chemin : collection utilisateur
        .doc(userId) // 👤 Document correspondant à l’utilisateur
        .collection('revision_stats') // 📁 Collection des stats quotidiennes
        .doc(today); // 📄 Document du jour en cours

    // 🧮 Initialisation des compteurs
    int totalCorrect = 0;     // ✅ Nombre de bonnes réponses cumulées
    int totalWrong = 0;       // ❌ Nombre de mauvaises réponses cumulées
    int revisionCount = 0;    // 🔁 Nombre total de révisions enregistrées
    int totalDuration = 0;    // ⏱ Temps total de réponse (en secondes)

    // 👀 Ensemble pour stocker les flashcards vues (sans doublons)
    final Set<String> seenFlashcards = {};

    // 🔁 Fonction récursive pour explorer l’arborescence de sujets de manière profonde
    Future<void> explore(DocumentReference ref) async {
      logRevisions("🔎 [explore] Exploration de ${ref.path}"); // 🪵 Log chemin exploré

      // 📚 Récupère dynamiquement les sous-collections subsubjectX
      final subCollections = await _nav.getSubCollectionsFromDoc(ref);
      logRevisions("📦 Sous-collections retournées : ${subCollections.keys}");

      // 🔁 Pour chaque sous-collection subsubjectX
      for (final colName in subCollections.keys) {
        // 🔁 Pour chaque document (sujet) dans la sous-collection
        for (final doc in subCollections[colName]!.docs) {
          logRevisions("📁 Document trouvé : ${doc.reference.path}");

          // 📄 Récupère le document /meta/revision_summary
          final summary = await doc.reference.collection('meta').doc('revision_summary').get();

          // ✅ Si le résumé existe
          if (summary.exists) {
            final data = summary.data()!; // 📦 Données du résumé
            logRevisions("📋 Données résumé dans ${doc.reference.path}/meta/revision_summary = $data");

            // ➕ Ajout des valeurs récupérées aux compteurs globaux
            totalCorrect += (data['correctTotal'] ?? 0) as int;         // ✅ Ajout des bonnes réponses
            totalWrong += (data['wrongTotal'] ?? 0) as int;             // ❌ Ajout des erreurs
            revisionCount += (data['revisionCount'] ?? 0) as int;       // 🔁 Ajout des révisions
            totalDuration += (data['totalDuration'] ?? 0) as int;       // ⏱ Ajout du temps total

            // 👁️ Ajout des flashcards vues (en évitant les doublons)
            final seenList = (data['flashcardsSeen'] as List?)?.cast<String>() ?? [];
            seenFlashcards.addAll(seenList); // 🧮 Ajout dans un Set pour unicité
            logRevisions("➕ ${seenList.length} flashcard(s) vues ajoutée(s), total unique = ${seenFlashcards.length}");
          } else {
            // ⚠️ Résumé manquant pour ce sous-sujet
            logRevisions("⚠️ Aucun résumé trouvé pour ${doc.reference.path}/meta/revision_summary");
          }

          // 🔁 Appel récursif sur les enfants de ce document
          await explore(doc.reference);
        }
      }
    }

    // 🚀 Déclenche l’exploration si le document existe
    final exists = await statsRef.get();
    if (exists.exists) {
      await explore(statsRef); // 🔁 Explore récursivement à partir du document de base
    } else {
      logRevisions("⚠️ Aucun document de stats trouvé pour $today"); // 📢 Alerte si aucune stat ce jour-là
    }

    // 📈 Calcul du taux de réussite en pourcentage arrondi
    final successRate = revisionCount == 0
        ? 0 // 🧯 Si aucune révision : succès = 0
        : ((totalCorrect / (totalCorrect + totalWrong)) * 100).round(); // 📊 (bonnes / total) * 100
    logRevisions("📊 Taux de succès = $successRate%");

    // ⏱ Temps moyen par révision (secondes)
    final avgTimePerRevision = revisionCount == 0
        ? 0 // 🧯 Si aucune révision → moyenne 0
        : (totalDuration / revisionCount).round(); // ⏱ Somme / nombre de révisions

    // ⏱ Temps moyen par flashcard vue (secondes)
    final avgTimePerFlashcard = seenFlashcards.isEmpty
        ? 0 // 🧯 Aucune flashcard vue
        : (totalDuration / seenFlashcards.length).round(); // ⏱ Somme / nombre flashcards uniques

    logRevisions("⏱ Temps total = $totalDuration sec | Moy/revision = $avgTimePerRevision sec | Moy/flashcard = $avgTimePerFlashcard sec");

    // 📦 Construction du résumé final à retourner
    final summary = {
      'correctTotal': totalCorrect,               // ✅ Total bonnes réponses
      'wrongTotal': totalWrong,                   // ❌ Total erreurs
      'revisionCount': revisionCount,             // 🔁 Révisions totales
      'flashcardsSeen': seenFlashcards.length,    // 👁️ Flashcards uniques vues
      'successRate': successRate,                 // 📊 Taux de réussite
      'avgTimePerRevision': avgTimePerRevision,   // ⏱ Moyenne / révision
      'avgTimePerFlashcard': avgTimePerFlashcard, // ⏱ Moyenne / flashcard
    };

    logRevisions("📦 Résumé final des stats = $summary"); // 🧾 Log final avant retour
    return summary; // 🎯 Résultat retourné à l’appelant
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


  /// 🔍 Récupère le résumé de révision à un chemin donné (ex: subsubject0 > ID > meta/revision_summary)
  Future<Map<String, dynamic>?> getSummaryAtPath({
    required String userId,
    required List<String> pathSegments, // ex: ['subsubject0', subjectId]
  }) async {
    logRevisions("🔎 [getSummaryAtPath] user=$userId | path=$pathSegments");

    try {
      // 📆 Date d’aujourd’hui
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 📍 Point de départ : /users/{uid}/revision_stats/{today}
      DocumentReference ref = _db
          .collection('users')
          .doc(userId)
          .collection('revision_stats')
          .doc(today);

      // 🔁 Parcours du chemin dynamique (ex: subsubject0 > doc > subsubject1 > doc...)
      for (int i = 0; i < pathSegments.length; i += 2) {
        final col = pathSegments[i];
        final docId = pathSegments[i + 1];
        ref = ref.collection(col).doc(docId);
      }

      // 📄 Référence finale vers /meta/revision_summary
      final summaryRef = ref.collection('meta').doc('revision_summary');
      final snap = await summaryRef.get();

      if (snap.exists) {
        logRevisions("📦 Résumé trouvé à ${summaryRef.path} : ${snap.data()}");
        return snap.data();
      } else {
        logRevisions("⚠️ Aucun résumé trouvé à ${summaryRef.path}");
        return null;
      }
    } catch (e) {
      logRevisions("❌ Erreur dans getSummaryAtPath : $e");
      return null;
    }
  }

  /// 🔍 Explore récursivement les sous-collections depuis un sujet racine
  /// pour trouver le **premier** document `meta/revision_summary` existant.
  Future<Map<String, dynamic>?> findFirstSummaryRecursively({
    required String userId, // 👤 UID utilisateur (ex: "tmjevj...")
    required List<String> startingPath, // 🧭 Liste ["subsubject0", "subjectId"] pour commencer
  }) async {
    logRevisions("🔎 [findFirstSummaryRecursively] Démarrage pour $userId | path=$startingPath");

    // 📅 Récupère le document de la date du jour
    DocumentReference ref = _db
        .collection('users')
        .doc(userId)
        .collection('revision_stats')
        .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()));
    logRevisions("📌 Point de départ = ${ref.path}");

    // 🔁 Descend dans le chemin de départ (subsubject0/{subjectId})
    for (int i = 0; i < startingPath.length; i += 2) {
      final collection = startingPath[i];
      final docId = startingPath[i + 1];
      ref = ref.collection(collection).doc(docId);
      logRevisions("↪️ Navigation vers $collection/$docId → ${ref.path}");
    }

    /// 🔁 Fonction récursive locale pour explorer les niveaux suivants
    Future<Map<String, dynamic>?> recursiveExplore(DocumentReference current) async {
      logRevisions("🔬 [recursiveExplore] Exploration de : ${current.path}");

      // 🧪 Essaye de lire le résumé : /meta/revision_summary
      final summary = await current.collection('meta').doc('revision_summary').get();
      if (summary.exists) {
        logRevisions("✅ Résumé trouvé dans : ${summary.reference.path}");
        return summary.data(); // 📦 Retourne les données
      } else {
        logRevisions("❌ Aucun résumé dans : ${summary.reference.path}");
      }

      // 🔁 Parcours récursif des sous-niveaux : subsubject0 → subsubject5
      for (int i = 0; i <= 5; i++) {
        final subColName = 'subsubject$i'; // 📁 Nom de la collection à explorer
        final subCol = current.collection(subColName); // 📦 Collection actuelle
        final snap = await subCol.get(); // 📄 Tous les documents de cette collection

        logRevisions("🔽 Exploration de $subColName → ${snap.docs.length} document(s)");

        for (final doc in snap.docs) {
          logRevisions("➡️ Descente dans : ${doc.reference.path}");
          final found = await recursiveExplore(doc.reference); // 🔁 Appel récursif

          if (found != null) {
            return found; // ✅ Résumé trouvé en profondeur
          }
        }
      }

      logRevisions("🔚 Fin d'exploration pour : ${current.path} (aucun résumé trouvé)");
      return null; // 🚫 Aucun résumé trouvé à ce niveau ou en-dessous
    }

    // 🚀 Lance l'exploration à partir du sujet racine
    final result = await recursiveExplore(ref);
    if (result == null) {
      logRevisions("❗ Aucun résumé trouvé depuis $startingPath");
    }
    return result;
  }


}
