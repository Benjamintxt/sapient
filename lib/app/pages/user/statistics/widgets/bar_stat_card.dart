// 📄 bar_stat_card.dart
// 📊 Carte avec histogramme horizontal par sujet avec alignement clair

import 'package:flutter/material.dart'; // 👥 UI de base
import 'package:sapient/app/pages/user/statistics/widgets/base_stat_card.dart'; // 📦 Carte de base commune
import 'package:flutter/foundation.dart'; // 🛠️ Pour debugPrint

// 🚧 Activation des logs de bar_stat_card
const bool kEnableBarStatCardLogs = true; // 📢 Active ou désactive les logs

/// 🔎 Logger pour BarStatCard
void logBarStatCard(String message) {
  if (kEnableBarStatCardLogs) debugPrint('[📊 BarStatCard] $message');
}

/// 📊 Carte avec barres horizontales et texte aligné à gauche
class BarStatCard extends StatelessWidget {
  final String title; // 📛 Titre de la carte
  final int? percentage; // ❓ Pourcentage optionnel en haut
  final List<int> bars; // 📊 Valeurs des barres (0-100)
  final List<String> labels; // 🏷️ Noms des sujets associés

  const BarStatCard({
    super.key,
    required this.title,
    this.percentage,
    required this.bars,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    logBarStatCard('📈 Construction de $title avec ${bars.length} barres.');

    return BaseStatCard(
      title: title, // 📛 Affiche le titre principal
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 🧭 Aligne à gauche
        children: [
          if (percentage != null) // ❓ Affiche le % global si fourni
            Text('$percentage%', style: _numberStyle),
          const SizedBox(height: 8),

          // 📦 Liste verticale des matières + barres horizontales
          Column(
            children: List.generate(bars.length, (i) {
              final value = bars[i].clamp(0, 100); // ✅ Clampe la valeur à 100 max
              final label = labels[i]; // 🏷️ Nom du sujet

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6), // ↕️ Espacement entre les lignes
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // 📏 Aligné verticalement au centre
                  children: [
                    SizedBox(
                      width: 80, // 📏 Largeur fixe pour tous les labels (alignement gauche cohérent)
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14, // 🔠 Plus lisible
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // ➖ Espace entre texte et barre
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 18, // 🔹 Hauteur visuelle de la barre
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200, // 🎨 Fond neutre pour contexte
                              borderRadius: BorderRadius.circular(8), // ⭕ Bords doux
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: value / 100, // 📏 Proportion de remplissage
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.teal, // 🌿 Couleur principale
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$value%', // 🔢 Affichage numérique
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// 🌐 Style de texte pour pourcentage global
const TextStyle _numberStyle = TextStyle(
  fontSize: 24, // 🔹 Taille large
  fontWeight: FontWeight.bold, // 💪 Gras
);