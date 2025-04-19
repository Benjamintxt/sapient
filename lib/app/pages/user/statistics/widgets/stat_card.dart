// 📄 stat_card.dart
// 🔹 Carte statistique circulaire pour les flashcards vues

import 'package:flutter/material.dart'; // 🧱 UI Flutter de base
import 'package:sapient/app/pages/user/statistics/widgets/base_stat_card.dart'; // 📦 Carte de base stylisée
import 'package:flutter/foundation.dart'; // 🪛 Pour debugPrint

// 🔧 Constante pour activer/désactiver les logs
const bool kEnableStatCardLogs = true;

/// 🖨️ Logger dédié pour StatCard
void logStatCard(String message) {
  if (kEnableStatCardLogs) debugPrint('[📊 StatCard] $message');
}

class StatCard extends StatelessWidget {
  final String title; // 🏷️ Titre de la carte
  final int seen; // 👁️ Nombre de flashcards vues
  final int total; // 📦 Nombre total de flashcards

  const StatCard({
    super.key,
    required this.title,
    required this.seen,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : ((seen / total) * 100).round(); // 🔢 Pourcentage vu
    logStatCard('🧱 Construction StatCard : $title → $seen vues / $total → $percentage%');

    return BaseStatCard(
      title: title, // 🏷️ Titre de la carte (ex: "Flashcards révisées")
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // ↕️ Centre tout verticalement
        crossAxisAlignment: CrossAxisAlignment.center, // ↔️ Centre tout horizontalement
        children: [
          // 🧱 Bloc de hauteur fixe pour bien centrer le contenu
          SizedBox(
            height: 100,
            child: Center( // 📍 Centre dans la hauteur du bloc
              child: Stack(
                alignment: Alignment.center, // 🌀 Centre valeur et indicateur
                children: [
                  SizedBox(
                    width: 70, height: 70, // 📏 Taille du cercle
                    child: CircularProgressIndicator(
                      value: total == 0 ? 0.0 : seen / total, // 🎯 Progrès réel
                      color: Colors.teal, // 🌿 Couleur principale
                      strokeWidth: 6, // 🖌️ Épaisseur trait
                      backgroundColor: Colors.grey.shade300, // 🎨 Couleur fond
                    ),
                  ),
                  Text(
                    "$seen", // 🔢 Valeur affichée au centre
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4), // ↕️ Espace entre le cercle et le label
          const Text('Vues', style: TextStyle(fontSize: 14)), // 🏷️ Libellé bas
        ],
      ),
    );
  }
}
