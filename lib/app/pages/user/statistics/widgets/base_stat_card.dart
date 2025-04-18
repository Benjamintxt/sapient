// 📄 base_stat_card.dart
// 🧱 Widget de base pour toutes les cartes statistiques avec style cohérent

import 'package:flutter/material.dart'; // 👥 Composants de base Flutter
import 'package:flutter/foundation.dart'; // 🧠 Pour debugPrint

// 🔧 Constante de contrôle des logs
const bool kEnableBaseStatCardLogs = true; // 📢 Active ou non les logs de debug

/// 🖊️ Fonction centrale de log de la carte de base
void logBaseStatCard(String message) {
  if (kEnableBaseStatCardLogs) debugPrint('[🔹 BaseStatCard] $message');
}

/// 🧱 Widget de base pour contenir n'importe quelle carte stat
class BaseStatCard extends StatelessWidget {
  final String title; // 🎫 Titre affiché en haut de la carte
  final Widget child; // 🔹 Contenu dynamique de la carte

  const BaseStatCard({
    super.key, // 🔐 Clé du widget
    required this.title, // 🎫 Titre requis
    required this.child, // 🔹 Contenu interne
  });

  @override
  Widget build(BuildContext context) {
    logBaseStatCard('🧱 Construction de la carte "$title"'); // 🖊️ Log de construction

    return Container( // 📦 Boîte principale de la carte
      margin: const EdgeInsets.only(bottom: 12), // 🛏️ Espace sous la carte
      padding: const EdgeInsets.all(16), // 🛠️ Marges intérieures
      decoration: BoxDecoration( // 👗 Style de fond de la carte
        color: Colors.white.withAlpha(229), // 🌟 Blanc semi-transparent
        borderRadius: BorderRadius.circular(20), // ⭕ Bords arrondis
        boxShadow: [ // 💨 Ombre douce sous la carte
          BoxShadow(
            blurRadius: 6, // 🔫 Intensité du flou
            color: Colors.black26, // 💥 Couleur de l’ombre
            offset: const Offset(0, 3), // 🔄 Décalage vertical
          ),
        ],
      ),
      child: Column( // 📃 Contenu vertical
        crossAxisAlignment: CrossAxisAlignment.start, // ← Aligné à gauche
        children: [
          Text( // 🎫 Titre
            title, // 🌐 Texte du titre
            style: const TextStyle( // 🎨 Style du titre
              fontWeight: FontWeight.bold, // 🔝 Gras
            ),
          ),
          const SizedBox(height: 12), // 🛏️ Espace vertical
          child, // 🔹 Widget contenu (ligne, graphique, texte...)
        ],
      ),
    );
  }
}