// 📄 statistics_controller.dart
// 🧠 Contrôleur des statistiques utilisateur : logique de récupération depuis Firestore

import 'package:sapient/services/firestore/revisions_service.dart'; // 🔁 Service Firestore des révisions
import 'package:sapient/services/firestore/core.dart'; // 🔐 Pour récupérer l'UID
import 'package:flutter/foundation.dart'; // 🪛 Pour debugPrint

// 🛠️ Constante pour activer ou désactiver les logs
const bool kEnableStatisticsControllerLogs = true;

/// 🗒️ Fonction de log conditionnelle (affichée uniquement si activée)
void logStatsController(String message) {
  if (kEnableStatisticsControllerLogs) debugPrint('[📊 StatsController] $message');
}

class StatisticsController {
  /// 🔑 Récupère l'UID de l'utilisateur actuel
  static String getUid() {
    final uid = FirestoreCore.getCurrentUserUid() ?? ''; // ✅ Retourne un UID valide ou vide
    logStatsController('🔐 UID récupéré : $uid'); // 🖨️ Log récupération UID
    return uid;
  }

  /// 📊 Récupère les données de statistiques globales de la journée
  static Future<Map<String, dynamic>> getTodaySummary(String uid) async {
    logStatsController('📡 Requête des stats pour UID = $uid');

    // 🔄 Récupère les stats du jour
    final stats = await FirestoreRevisionsService().getTodayGlobalSummary(uid);

    // 🔢 Récupère le nombre total de flashcards
    final total = await FirestoreRevisionsService().getTotalFlashcardsCount(uid);
    stats['flashcardsTotal'] = total;

    logStatsController('📦 Stats complètes : $stats');
    return stats;
  }

}