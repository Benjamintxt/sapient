// 📄 base_stat_card.dart
// 🧱 Widget de base pour toutes les cartes statistiques avec style cohérent

import 'package:flutter/material.dart'; // 👥 Composants de base Flutter
import 'package:flutter/foundation.dart'; // 🧠 Pour debugPrint

// 🔧 Constante de contrôle des logs
const bool kEnableBaseStatCardLogs = true;

/// 🖊️ Fonction de log conditionnelle
void logBaseStatCard(String message) {
  if (kEnableBaseStatCardLogs) debugPrint('[🔹 BaseStatCard] $message');
}

/// 🧱 Widget de base pour contenir une carte stat
class BaseStatCard extends StatelessWidget {
  final String title; // 🎫 Titre de la carte
  final Widget child; // 🧱 Contenu principal

  const BaseStatCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    logBaseStatCard('🧱 Construction de la carte "$title"');

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // ➕ Plus d’espace entre les cartes
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // ↕️ Réduction du padding vertical

      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235), // 🌿 Légèrement plus opaque
        borderRadius: BorderRadius.circular(24), // ⭕ Coins plus doux
        boxShadow: [
          BoxShadow(
            color: Colors.black12, // 🌫️ Ombre plus douce
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔧 Réduit la hauteur à ce qui est nécessaire
        crossAxisAlignment: CrossAxisAlignment.center, // 🧲 Centre horizontalement le contenu
        children: [
          if (title.isNotEmpty) // 🔕 Affiche uniquement si titre présent
            Padding(
              padding: const EdgeInsets.only(bottom: 12), // 🧘‍♀️ Espace entre le titre et le contenu
              child: Text(
                title,
                textAlign: TextAlign.center, // 🧭 Centrage texte
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
          child, // 🧱 Contenu (MiniStatCard, etc.)
        ],
      ),

    );
  }
}
