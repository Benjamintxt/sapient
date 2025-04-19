// 🧮 pie_stat_card.dart
// 📊 Carte avec barre horizontale pour "Nombre de révisions"

import 'package:flutter/material.dart'; // 🎨 Widgets UI de base
import 'package:flutter/foundation.dart'; // 🧰 debugPrint
import 'base_stat_card.dart'; // 🧱 Carte de base stylisée

// 🔧 Activation des logs
const bool kEnablePieStatCardLogs = true;

/// 🧾 Logger pour la carte PieStatCard (barre horizontale)
void logPieStatCard(String message) {
  if (kEnablePieStatCardLogs) debugPrint('[🥧 PieStatCard] $message');
}

class PieStatCard extends StatelessWidget {
  final String title; // 🏷️ Titre de la carte
  final String value; // 🔢 Valeur numérique (ex: "7")
  final int percentage; // 📈 Taux de réussite ou remplissage (ex: 57)

  const PieStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    logPieStatCard('🧱 Construction de la carte "$title"');
    logPieStatCard('🔢 Valeur = $value | % = $percentage%');

    return BaseStatCard( // 🧱 Utilise la base commune avec fond et ombre
      title: title, // 🏷️ Titre en haut
      child: Column( // 🧊 Colonne verticale
        mainAxisAlignment: MainAxisAlignment.center, // 📍 Centrage vertical
        crossAxisAlignment: CrossAxisAlignment.center, // 📍 Centrage horizontal
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 📐 Marge interne
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16), // 🟦 Coins arrondis pour la barre
              child: LinearProgressIndicator( // 📊 Barre horizontale
                value: percentage / 100, // 📏 Valeur entre 0.0 et 1.0
                minHeight: 20, // 📏 Hauteur personnalisée
                backgroundColor: Colors.grey.shade300, // 🎨 Fond gris clair
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal), // 🌿 Couleur de progression
              ),
            ),
          ),
          const SizedBox(height: 12), // ↕️ Espace
          Text(
            value, // 🔢 Affichage du chiffre
            style: const TextStyle(
              fontSize: 28, // 📏 Grosse taille
              fontWeight: FontWeight.bold, // 💪 En gras
              color: Colors.deepPurple, // 🎨 Violet foncé
            ),
          ),
          const SizedBox(height: 4), // ↕️ Petit espace
          const Text(
            "Révisions", // 📋 Légende
            style: TextStyle(
              fontSize: 16, // 📏 Taille normale
              color: Colors.black87, // 🎨 Texte presque noir
            ),
          ),
        ],
      ),
    );
  }
}