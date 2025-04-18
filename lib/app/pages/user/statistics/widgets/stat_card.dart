// 📄 stat_card.dart
// 🔹 Carte statistique avec deux valeurs : vue et non vue

import 'package:flutter/material.dart'; // 🧱 Composants UI de base
import 'package:sapient/app/pages/user/statistics/widgets/base_stat_card.dart'; // 🧱 Carte de base stylée
import 'package:flutter/foundation.dart'; // 🪛 Pour debugPrint

// 🛠️ Constante pour activer/désactiver les logs de StatCard
const bool kEnableStatCardLogs = true;

/// 🖨️ Fonction de log pour StatCard (si activée)
void logStatCard(String message) {
  if (kEnableStatCardLogs) debugPrint('[📊 StatCard] $message');
}

class StatCard extends StatelessWidget {
  final String title; // 🏷️ Titre de la carte
  final String leftValue; // 🔢 Valeur à gauche (ex: "10")
  final String leftLabel; // 📌 Libellé à gauche (ex: "Vues")
  final String rightValue; // 🔢 Valeur à droite (ex: "5")
  final String rightLabel; // 📌 Libellé à droite (ex: "Jamais vues")

  const StatCard({
    super.key, // 🔑 Clé pour l’identification du widget
    required this.title, // 🏷️ Titre
    required this.leftValue, // 🔢 Valeur gauche
    required this.leftLabel, // 📌 Label gauche
    required this.rightValue, // 🔢 Valeur droite
    required this.rightLabel, // 📌 Label droite
  });

  @override
  Widget build(BuildContext context) {
    logStatCard('🧱 Construction StatCard : $title'); // 🖨️ Log construction

    return BaseStatCard( // 🧱 Structure réutilisable commune
      title: title, // 🏷️ Titre affiché en haut
      child: Row( // ↔️ Ligne principale de contenu
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // ↔️ Répartition uniforme
        children: [
          Column( // 📊 Colonne gauche
            children: [
              Text(leftValue, style: _numberStyle), // 🔢 Valeur à gauche
              Text(leftLabel), // 📌 Label de la valeur gauche
            ],
          ),
          Column( // 📊 Colonne droite
            children: [
              Text(rightValue, style: _numberStyle), // 🔢 Valeur à droite
              Text(rightLabel), // 📌 Label de la valeur droite
            ],
          ),
        ],
      ),
    );
  }
}

// 🎨 Style numérique commun pour les statistiques
const TextStyle _numberStyle = TextStyle(
  fontSize: 24, // 🔠 Taille de police
  fontWeight: FontWeight.bold, // 🅱️ En gras
);