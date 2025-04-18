// 📄 revision_rate_card.dart
// 📈 Widget affichant les taux de révision par sujet sous forme de barres de progression

import 'package:flutter/material.dart'; // 💼 Composants UI
import 'package:sapient/app/pages/user/statistics/widgets/base_stat_card.dart'; // 📊 Carte stylée réutilisable
import 'package:flutter/foundation.dart'; // 🔧 Pour debugPrint/logs

// 🔧 Constante pour activer/désactiver les logs
const bool kEnableRevisionRateCardLogs = true;

/// 💪 Log de debug conditionnel pour RevisionRateCard
void logRevisionRateCard(String msg) {
  if (kEnableRevisionRateCardLogs) debugPrint('[📈 RevisionRateCard] $msg');
}

class RevisionRateCard extends StatelessWidget {
  final String title; // 🏆 Titre du bloc (ex: Taux de révision)
  final Map<String, double> subjects; // 🔢 Dictionnaire "nom matière → taux de révision (0.0 → 1.0)"

  const RevisionRateCard({
    super.key, // 🔑 Clé Flutter
    required this.title, // 🏆 Titre
    required this.subjects, // 📅 Map des données
  });

  @override
  Widget build(BuildContext context) {
    logRevisionRateCard('Construction du widget avec ${subjects.length} sujets');

    return BaseStatCard( // 📊 Carte de base
      title: title, // 🏆 Titre du bloc
      child: Column( // 📆 Empile chaque ligne de progression
        children: subjects.entries.map((entry) {
          final subject = entry.key; // 🔍 Nom du sujet
          final value = entry.value; // 📈 Taux de révision (0.0 - 1.0)

          logRevisionRateCard('Sujet "$subject" : ${value * 100}%');

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4), // ⬇️ Espace entre les lignes
            child: Row(
              children: [
                SizedBox(
                  width: 60, // 📏 Largeur du nom du sujet
                  child: Text(subject), // 🖋️ Affiche le nom du sujet
                ),
                Expanded(
                  child: LinearProgressIndicator( // 🔢 Barre de progression horizontale
                    value: value, // 🔹 Pourcentage sous forme de 0.0 → 1.0
                    minHeight: 8, // 📊 Épaisseur
                    backgroundColor: Colors.grey.shade300, // 💚 Arrière-plan gris clair
                    color: Colors.teal, // 🖊 Couleur de progression
                  ),
                ),
              ],
            ),
          );
        }).toList(), // 📋 Convertit l'Iterable en List de widgets
      ),
    );
  }
}