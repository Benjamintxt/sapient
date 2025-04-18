// 🥎 pie_stat_card.dart
// 🥧 Carte circulaire des révisions avec pourcentage de réussite

import 'package:flutter/material.dart'; // 💡 UI de base
import 'package:flutter/foundation.dart'; // 🔧 debugPrint
import 'base_stat_card.dart'; // 🛋 Carte de base stylisée

// 🔧 Activation des logs
const bool kEnablePieStatCardLogs = true;

/// 🔍 Logger central pour PieStatCard
void logPieStatCard(String message) {
  if (kEnablePieStatCardLogs) debugPrint('[🥧 PieStatCard] \$message');
}

class PieStatCard extends StatelessWidget {
  final String title; // 🏛þ Titre de la carte
  final String value; // 🔢 Valeur principale (ex: "12")
  final int percentage; // 🔄 Pourcentage de réussite (ex: 80)

  const PieStatCard({
    super.key, // 🔑 Identifiant du widget
    required this.title, // 🏛þ
    required this.value, // 🔢
    required this.percentage, // 🔄
  });

  @override
  Widget build(BuildContext context) {
    logPieStatCard('Construction : \$title - \$value - \$percentage%'); // 📈 Log

    return BaseStatCard( // 🛋 Carte réutilisable avec titre
      title: title, // 🏛þ
      child: Row( // ↔️ Ligne de contenu
        children: [
          Text(value, style: _numberStyle), // 🔢 Affiche la valeur numérique
          const SizedBox(width: 16), // ↔️ Espace entre les éléments
          Stack( // 🌀 Empile l'indicateur et le texte
            alignment: Alignment.center, // 🌌 Centre les éléments
            children: [
              SizedBox( // 🎨 Zone de l'indicateur
                width: 60, // 📏 Taille fixe
                height: 60, // 📏
                child: CircularProgressIndicator( // 🔄 Cercle de progression
                  value: percentage / 100, // 📊 Valeur de 0.0 à 1.0
                  color: Colors.green, // 🌿 Couleur verte
                  strokeWidth: 6, // 🛏 Largeur du trait
                ),
              ),
              Text("$percentage%"), // 🔄 Texte du pourcentage centré
            ],
          ),
        ],
      ),
    );
  }
}

// 🎨 Style commun aux valeurs numériques
const TextStyle _numberStyle = TextStyle(
  fontSize: 24, // 📏 Taille de police
  fontWeight: FontWeight.bold, // 💪 Gras
);