// statistics_controller.dart
// Contrôleur des statistiques utilisateur : logique de récupération depuis Firestore

import 'package:sapient/services/firestore/revisions_service.dart'; //  Service Firestore des révisions
import 'package:sapient/services/firestore/core.dart'; //  Pour récupérer l'UID
import 'package:flutter/foundation.dart'; //  Pour debugPrint

import 'package:sapient/services/firestore/subjects_service.dart'; //  Service des sujets

final _subjectsService = FirestoreSubjectsService(); //  Sujets Firestore
final _revisionsService = FirestoreRevisionsService(); //  Révisions Firestore


//  Constante pour activer ou désactiver les logs
const bool kEnableStatisticsControllerLogs = true;

///  Fonction de log conditionnelle (affichée uniquement si activée)
void logStatsController(String message) {
  if (kEnableStatisticsControllerLogs) debugPrint('[StatsController] $message');
}

class StatisticsController {
  /// Récupère l'UID de l'utilisateur actuel
  static String getUid() {
    final uid = FirestoreCore.getCurrentUserUid() ?? ''; // Retourne un UID valide ou vide
    logStatsController(' UID récupéré : $uid'); // Log récupération UID
    return uid;
  }

  /// Récupère les données de statistiques globales de la journée
  static Future<Map<String, dynamic>> getTodaySummary(String uid) async {
    logStatsController('Requête des stats pour UID = $uid'); // Log utilisateur

    // Récupère les statistiques du jour (inclut avgTimePerRevision et avgTimePerFlashcard)
    final stats = await FirestoreRevisionsService().getTodayGlobalSummary(uid);

    // Récupère aussi le nombre total de flashcards (toutes matières confondues)
    final total = await FirestoreRevisionsService().getTotalFlashcardsCount(uid);

    // Ajoute cette information dans la map des stats
    stats['flashcardsTotal'] = total;

    // Log des données finales envoyées à l’interface
    logStatsController('Stats complètes enrichies : $stats');

    // Retour des stats complètes
    return stats;
  }


  /// Récupère les taux de révision par sujet racine
  static Future<Map<String, double>> getRevisionRateByRootSubject(String userId) async {
    logStatsController('[getRevisionRateByRootSubject] Début récupération des taux par sujet racine');

    final result = <String, double>{};
    final rootSubjects = await _subjectsService.getRootSubjectsOnce();


    for (final doc in rootSubjects.docs) {
      final String subjectId = doc.id;
      final String subjectName = doc['name'] ?? 'Inconnu';

      final path = ['subsubject0', subjectId];

    // Recherche récursive dans la hiérarchie Firestore à partir du sujet racine
    // pour récupérer le premier résumé `meta/revision_summary` trouvé (le plus profond si besoin)
      final summary = await _revisionsService.findFirstSummaryRecursively(
        userId: userId,          // ID utilisateur actuel (ex: "tmjevj...")
        startingPath: path,      // Chemin de départ = ["subsubject0", "{subjectId}"]
      );

      if (summary != null && summary.containsKey('correctTotal') && summary.containsKey('wrongTotal')) {
        final correct = summary['correctTotal'];
        final wrong = summary['wrongTotal'];
        final total = correct + wrong;
        final rate = total > 0 ? correct / total : 0.0;

        result[subjectName] = rate;
        logStatsController('Taux pour "$subjectName" = ${(rate * 100).round()}%');
      } else {
        logStatsController('⚠Aucun résumé pour $subjectName');
      }
    }

    logStatsController('Résultat final = $result');
    return result;
  }


}