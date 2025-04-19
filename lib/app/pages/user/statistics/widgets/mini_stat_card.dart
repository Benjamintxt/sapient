// 📄 mini_stat_card.dart
// 📦 Carte compacte finale avec alignement parfait et occupation maximale

import 'package:flutter/material.dart'; // 🧱 UI Flutter de base
import 'package:flutter/foundation.dart'; // 🧠 Pour debugPrint (logs)
import 'base_stat_card.dart'; // 📦 Structure pastel réutilisable définie dans base_stat_card.dart

// 🔧 Constante pour activer/désactiver les logs de debug
const bool kEnableMiniStatCardLogs = true;

/// 🖨️ Fonction de log conditionnelle pour MiniStatCard
void logMiniStatCard(String msg) {
  // Si les logs sont activés, on affiche le message avec un préfixe lisible
  if (kEnableMiniStatCardLogs) debugPrint('[📦 MiniStatCard] $msg');
}

/// 🧱 Widget représentant une carte compacte avec :
/// - un titre (ex: Temps moyen)
/// - une icône (ex: horloge, sablier)
/// - une valeur centrale (ex: 20 min)
class MiniStatCard extends StatelessWidget {
  final String title; // 🏷️ Texte qui décrit la statistique (ex: "Temps moyen")
  final String value; // 🔢 Valeur à afficher (ex: "20 min")
  final IconData icon; // ⏳ Icône illustrant la statistique

  const MiniStatCard({
    super.key, // 🔑 Clé unique pour le widget (bonne pratique pour les widgets stateless)
    required this.title, // 🏷️ Titre à afficher
    required this.value, // 🔢 Valeur affichée
    required this.icon,  // ⏳ Icône à afficher
  });

  @override
  Widget build(BuildContext context) {
    logMiniStatCard('🧱 Construction "$title" = $value'); // 📋 Log de debug à la construction

    return BaseStatCard(
      title: '', // ❌ On laisse vide ici car on redessine manuellement le titre plus bas
      child: SizedBox(
        // 🔄 Suppression de la hauteur fixe pour laisser le contenu déterminer sa taille
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 📐 Centrage vertical du contenu
          crossAxisAlignment: CrossAxisAlignment.center, // 📐 Centrage horizontal du contenu
          children: [
            Text(
              title, // 🏷️ Affiche le titre comme "Temps moyen"
              textAlign: TextAlign.center, // 🧭 Centré horizontalement
              style: const TextStyle(
                fontWeight: FontWeight.w600, // 💪 Semi-gras pour mise en évidence
                fontSize: 16, // 🔠 Taille confortable pour un titre court
                height: 1.3, // 🧾 Hauteur de ligne pour aération
              ),
            ),
            const SizedBox(height: 6), // ↕️ Espace entre le titre et l'icône
            Icon(
              icon, // 🕒 Affiche l’icône choisie (Clock ou Hourglass)
              size: 36, // 📐 Taille visuellement équilibrée
              color: Colors.black87, // 🎨 Couleur sombre pour bonne lisibilité
            ),
            const SizedBox(height: 6), // ↕️ Espace entre l’icône et la valeur
            Text(
              value, // ⏱️ Affiche la valeur, ex: "20 min"
              textAlign: TextAlign.center, // 🧭 Centré pour harmonie visuelle
              style: const TextStyle(
                fontSize: 22, // 📊 Taille plus grande pour accentuer l’information
                fontWeight: FontWeight.bold, // 💪 Gras pour attirer l’attention
                color: Colors.black87, // 🎨 Couleur lisible
              ),
            ),
          ],
        ),
      ),
    );
  }
}
