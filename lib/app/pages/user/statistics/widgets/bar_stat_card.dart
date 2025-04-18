// 📄 bar_stat_card.dart
// 📊 Carte avec histogramme par sujet

import 'package:flutter/material.dart'; // 👥 UI de base
import 'package:sapient/app/pages/user/statistics/widgets/base_stat_card.dart'; // 👥 Carte de base commune
import 'package:flutter/foundation.dart'; // 🛠️ Pour debugPrint

// 🚧 Activation des logs de bar_stat_card
const bool kEnableBarStatCardLogs = true;

/// 🔎 Logger pour BarStatCard
void logBarStatCard(String message) {
  if (kEnableBarStatCardLogs) debugPrint('[📊 BarStatCard] $message');
}

class BarStatCard extends StatelessWidget {
  final String title; // 📛 Titre de la carte
  final int? percentage; // ❓ Pourcentage optionnel
  final List<int> bars; // 📊 Hauteur des barres (0-100)
  final List<String> labels; // 🎭 Libellés des barres

  const BarStatCard({
    super.key, // 🔑 Clé unique
    required this.title, // 📛 Titre
    this.percentage, // 🔄 Pourcentage en haut (optionnel)
    required this.bars, // 📊 Hauteurs
    required this.labels, // 🎭 Libellés
  });

  @override
  Widget build(BuildContext context) {
    logBarStatCard('📈 Construction de $title avec ${bars.length} barres.');

    return BaseStatCard( // 📊 Structure commune
      title: title, // 📛 Affiche le titre
      child: Column( // 🛋 Colonne verticale
        crossAxisAlignment: CrossAxisAlignment.start, // ← Aligné à gauche
        children: [
          if (percentage != null) // ❓ Si un pourcentage est fourni
            Text('$percentage%', style: _numberStyle), // 🔄 Texte du pourcentage
          const SizedBox(height: 8), // ↕⃣ Espace vertical
          Row( // ↔⃣ Ligne de barres
            mainAxisAlignment: MainAxisAlignment.spaceAround, // 😀 Espacement équilibré
            children: List.generate(bars.length, (i) => Column( // 🛋 Colonne pour chaque barre
              children: [
                Container( // 🛋 Barre verticale
                  width: 14, // 🌏 Largeur
                  height: bars[i].toDouble(), // 🔹 Hauteur
                  color: Colors.teal, // 🌯 Couleur
                ),
                const SizedBox(height: 4), // ↕⃣ Espacement
                Text(labels[i], style: const TextStyle(fontSize: 10)), // 🎭 Label sous la barre
              ],
            )),
          ),
        ],
      ),
    );
  }
}

// 🌐 Style de texte pour pourcentage
const TextStyle _numberStyle = TextStyle(
  fontSize: 24, // 🔹 Taille large
  fontWeight: FontWeight.bold, // 💪 Gras
);