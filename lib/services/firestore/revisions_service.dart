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
    required int durationSeconds, // ⏱ Temps mis pour répondre à la question
    required String subjectId, // 📁 ID du sujet (doit être une feuille, pas une catégorie)
    required int level, // 🔢 Niveau de profondeur du sujet
    required List<String> parentPathIds, // 🧭 Liste des IDs des parents du sujet dans la hiérarchie
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now()); // 📆 Date d'aujourd'hui au format "YYYY-MM-DD"
    logRevisions("🗓 [recordAnswer] Date=$today | Flashcard=$flashcardId | Correct=$isCorrect");

    // 📍 Référence au document de la date dans /revision_stats
    DocumentReference currentRef = _db
        .collection('users')
        .doc(userId)
        .collection('revision_stats')
        .doc(today);

    // 🆕 Crée le document du jour s'il n'existe pas encore
    await currentRef.set({ 'createdAt': FieldValue.serverTimestamp() }, SetOptions(merge: true));

    // 🧾 Récupère les noms lisibles pour chaque niveau de la hiérarchie
    final subjectNames = await FirestoreSubjectsService().getSubjectNamesFromPath(
      userId: userId,
      parentPathIds: parentPathIds,
    );

    // 📘 Récupère le nom du dernier sujet (celui en cours)
    final finalRef = await _nav.getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds,
      subjectId: subjectId,
    );
    final snap = await finalRef.get(); // 📄 Lecture du document Firestore
    final lastName = (snap.data() as Map<String, dynamic>?)?['name'] ?? 'unknown'; // 🏷️ Nom du dernier niveau
    subjectNames.add(lastName); // ➕ Ajoute à la liste

    // 🔁 Traverse les niveaux de la hiérarchie et crée chaque document intermédiaire si besoin
    for (int i = 0; i < level; i++) {
      currentRef = await _nav.ensureLevelDocument(
        parentRef: currentRef, // 🔗 Référence du niveau actuel
        levelKey: subjectNames[i], // 🔑 Nom lisible du niveau actuel (clé de collection)
        docId: parentPathIds[i], // 🆔 ID du document actuel
        subjectName: subjectNames[i], // 🏷️ Nom du document
      );
    }

    // ✅ Ajoute le dernier niveau (la feuille) dans la structure
    final subjectRef = await _nav.ensureLevelDocument(
      parentRef: currentRef, // 🔗 Dernier niveau parent
      levelKey: lastName, // 🔑 Nom de la feuille
      docId: subjectId, // 🆔 ID du sujet final
      subjectName: lastName, // 🏷️ Nom lisible de la feuille
    );

    // 📍 Référence vers le document de réponse (unique par flashcard)
    final answerRef = subjectRef.collection('answers').doc(flashcardId);

    // 📝 Enregistre ou met à jour les statistiques de cette flashcard
    await answerRef.set({
      'flashcardId': flashcardId, // 🆔 ID unique
      'subjectId': subjectId, // 📁 Sujet auquel appartient la flashcard
      'level': level, // 🔢 Niveau de profondeur
      'parentPathIds': parentPathIds, // 🧭 Arborescence complète
      'lastIsCorrect': isCorrect, // ✅ Dernière réponse correcte ?
      'lastTimestamp': FieldValue.serverTimestamp(), // ⏱ Timestamp de la dernière révision
      'correctCount': FieldValue.increment(isCorrect ? 1 : 0), // ➕ Incrémente si correct
      'wrongCount': FieldValue.increment(isCorrect ? 0 : 1), // ➕ Incrémente si incorrect
      'totalDuration': FieldValue.increment(durationSeconds), // ➕ Incrémente la durée totale
    }, SetOptions(merge: true));

    // 📊 Référence au résumé global pour ce sujet/date
    final summaryRef = subjectRef.collection('meta').doc('revision_summary');

    // 🧮 Met à jour les stats globales
    await summaryRef.set({
      'correctTotal': FieldValue.increment(isCorrect ? 1 : 0), // ✅ Total des bonnes réponses
      'wrongTotal': FieldValue.increment(isCorrect ? 0 : 1), // ❌ Total des mauvaises réponses
      'revisionCount': FieldValue.increment(1), // 🔄 Nombre total de révisions
      'totalDuration': FieldValue.increment(durationSeconds), // ⏱ Temps cumulé
      'lastUpdated': FieldValue.serverTimestamp(), // 📆 Dernière mise à jour
      'flashcardsSeen': FieldValue.arrayUnion([flashcardId]), // 👀 Liste unique des flashcards vues
    }, SetOptions(merge: true));

    logRevisions("✅ Révision enregistrée pour $flashcardId dans $today/$lastName");
  }

  /// 🔹 Calcule les statistiques globales de la journée (correct, erreurs, pourcentage...)
  Future<Map<String, dynamic>> getTodayGlobalSummary(String userId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now()); // 📆 Date du jour
    logRevisions("📊 [getTodayGlobalSummary] pour $today");

    final statsRef = _db.collection('users').doc(userId).collection('revision_stats').doc(today); // 📁 Référence document du jour

    // 🧮 Initialisation des compteurs
    int totalCorrect = 0; // ✅ Bonnes réponses
    int totalWrong = 0; // ❌ Mauvaises réponses
    int revisionCount = 0; // 🔁 Nombre total de révisions
    int flashcardsSeen = 0; // 👀 Nombre total de flashcards uniques vues

    // 🔁 Fonction récursive pour explorer toutes les sous-collections et résumés
    Future<void> explore(DocumentReference ref) async {
      final subCollections = await _nav.getSubCollectionsFromDoc(ref); // 📚 Liste des sous-collections

      for (final colName in subCollections.keys) { // 🔁 Parcours des collections
        for (final doc in subCollections[colName]!.docs) { // 🔁 Parcours des documents
          final summary = await doc.reference.collection('meta').doc('revision_summary').get(); // 📄 Accès au résumé

          if (summary.exists) {
            final data = summary.data()!; // 📦 Données du résumé

            totalCorrect += (data['correctTotal'] ?? 0) as int; // ➕ Ajoute au compteur
            totalWrong += (data['wrongTotal'] ?? 0) as int;
            revisionCount += (data['revisionCount'] ?? 0) as int;
            flashcardsSeen += (data['flashcardsSeen'] as List?)?.length ?? 0;
          }

          await explore(doc.reference); // 🔁 Appel récursif
        }
      }
    }

    // ✅ Si le document du jour existe, on lance l'exploration
    if ((await statsRef.get()).exists) {
      await explore(statsRef);
    } else {
      logRevisions("⚠️ Pas de stats pour $today");
    }

    // 📊 Calcul du taux de succès en pourcentage (arrondi)
    final successRate = revisionCount == 0 ? 0 : ((totalCorrect / (totalCorrect + totalWrong)) * 100).round();

    // 📦 Résumé retourné
    return {
      'correctTotal': totalCorrect, // ✅ Total bonnes réponses
      'wrongTotal': totalWrong, // ❌ Total erreurs
      'revisionCount': revisionCount, // 🔁 Révisions
      'flashcardsSeen': flashcardsSeen, // 👀 Cartes vues
      'successRate': successRate, // 📈 Pourcentage de succès
    };
  }
}
