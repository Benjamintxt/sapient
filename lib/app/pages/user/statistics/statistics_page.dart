// 📄 statistics_page.dart
// 📊 Page principale des statistiques utilisateur avec vue pastel

import 'package:flutter/material.dart'; // 🧱 Composants de base Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌐 Localisation multilingue
import 'package:sapient/app/pages/user/statistics/widgets/stat_card.dart'; // 🔹 Carte stats gauche/droite
import 'package:sapient/app/pages/user/statistics/widgets/pie_stat_card.dart'; // 🥧 Statistiques circulaires
import 'package:sapient/app/pages/user/statistics/widgets/bar_stat_card.dart'; // 📊 Barres comparatives
import 'package:sapient/app/pages/user/statistics/widgets/mini_stat_card.dart'; // 📦 Mini-carte (temps, etc.)
import 'package:sapient/app/pages/user/statistics/widgets/revision_rate_card.dart'; // 📈 Révisions par matière
import 'package:sapient/app/pages/user/statistics/controller/statistics_controller.dart'; // 🧠 Récupération des données

// 🔧 Constante pour activer/désactiver les logs
const bool kEnableStatisticsLogs = true;

/// 📣 Log conditionnel pour la page statistiques
void logStats(String msg) {
  if (kEnableStatisticsLogs) debugPrint('[📊 StatisticsPage] $msg');
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key}); // 🆕 Constructeur constant

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!; // 🌍 Localisation
    final uid = StatisticsController.getUid(); // 👤 Récupération de l'utilisateur
    logStats('👤 UID récupéré : $uid');

    return Scaffold(
      extendBodyBehindAppBar: true, // 🌫️ Étend le fond derrière l'appBar
      backgroundColor: Colors.transparent, // 🔍 Fond transparent

      appBar: AppBar(
        backgroundColor: Colors.transparent, // 🎨 AppBar sans fond opaque
        elevation: 0, // 🚫 Pas d'ombre
        centerTitle: true, // 🎯 Titre centré
        title: Text(
          local.statistics, // 🏷️ Texte "Statistiques"
          style: const TextStyle(
            fontWeight: FontWeight.bold, // 🅱️ Gras
            fontFamily: 'Raleway', // ✏️ Police élégante
            fontSize: 24, // 🔠 Taille titre
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple), // 🔙 Flèche retour violette
          onPressed: () => Navigator.pop(context), // ⬅️ Ferme la page
        ),
      ),

      body: FutureBuilder<Map<String, dynamic>>( // 🔄 Attend les données Firestore
        future: StatisticsController.getTodaySummary(uid), // 📡 Statistiques du jour
        builder: (context, snapshot) {
          logStats('📦 snapshot.connectionState = ${snapshot.connectionState}');
          logStats('📦 snapshot.hasData = ${snapshot.hasData}');
          logStats('📦 snapshot.hasError = ${snapshot.hasError}');
          if (snapshot.hasError) logStats('❌ snapshot.error = ${snapshot.error}');

          if (snapshot.connectionState != ConnectionState.done) { // ⏳ Chargement
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) { // ❌ Erreur ou vide
            return Center(child: Text(local.error_loading_stats));
          }

          final data = snapshot.data!; // 📦 Données récupérées
          final seen = data['flashcardsSeen'] ?? 0; // 👁️ Nombre de cartes vues
          final total = data['flashcardsTotal'] ?? 0; // 📦 Nombre total de flashcards
          final notSeen = (total - seen).clamp(0, total); // 🔴 Jamais vues (protège contre négatif)
          final revisions = data['revisionCount'] ?? 0; // 🔁 Nombre de révisions
          final successRate = data['successRate'] ?? 0; // ✅ Pourcentage de succès


          logStats('👀 flashcardsSeen = $seen');
          logStats('🔁 revisionCount = $revisions');
          logStats('✅ successRate = $successRate%');

          return Stack(
            children: [
              // 🌸 Image de fond
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Screen statistique.png', // 🖼️ Fond pastel
                  fit: BoxFit.cover, // 📐 Couvre tout l'écran
                ),
              ),

              SafeArea( // 📱 Gère les marges de l'OS (notch, etc.)
                child: SingleChildScrollView( // 📜 Scroll des stats
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80), // 📏 Marges internes
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // ↔️ Occupe toute la largeur
                    children: [
                      // 📊 Ligne principale
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: local.flashcards_reviewed, // 🏷️ Titre
                              leftValue: seen.toString(), // 🔢 Valeur gauche
                              leftLabel: local.seen, // 🟢 Libellé gauche
                              rightValue: notSeen.toString(), // // ❓ Valeur non vue (placeholder) ✅ Maintenant dynamique
                              rightLabel: local.never_seen, // 🔴 Libellé droite
                            ),
                          ),
                          const SizedBox(width: 12), // ➖ Espace entre les deux
                          Expanded(
                            child: PieStatCard(
                              title: local.total_revisions, // 🏷️ Titre
                              value: revisions.toString(), // 🔢 Nombre de révisions
                              percentage: successRate, // 📈 Taux de succès
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12), // ↕️ Espace
                      BarStatCard(
                        title: local.success_by_subject, // 🏷️ Titre
                        bars: [30, 50, 70, 90], // 📊 Hauteurs des barres
                        labels: ['Math', 'Hist', 'Angl', 'Bio'], // 🏷️ Labels associés
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MiniStatCard(
                              title: local.avg_time, // ⏱️ Temps moyen
                              value: '20 min',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MiniStatCard(
                              title: local.time_per_quizz, // 🧮 Temps par quiz
                              value: '1 min 12 s',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      RevisionRateCard(
                        title: local.revision_rates, // 🔢 Taux de révision
                        subjects: {
                          'Math': 0.8, // 📈 80%
                          'Histoire': 0.6, // 📈 60%
                          'Anglais': 0.5, // 📈 50%
                          'SVT': 0.4, // 📈 40%
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}