// 📄 mini_stat_card.dart
// 📦 Carte compacte pour une statistique simple (ex: temps moyen)

import 'package:flutter/material.dart'; // 🧱 Composants de base
import 'package:sapient/app/pages/user/statistics/widgets/base_stat_card.dart'; // 🧱 Carte de base réutilisable
import 'package:flutter/foundation.dart'; // 🛠️ Pour debugPrint (logs)

// ✅ Constante pour activer/désactiver les logs de cette carte
const bool kEnableMiniStatCardLogs = true;

/// 🖨️ Fonction de log spécifique à MiniStatCard
void logMiniStatCard(String msg) {
  if (kEnableMiniStatCardLogs) debugPrint('[📦 MiniStatCard] $msg');
}

class MiniStatCard extends StatelessWidget {
  final String title; // 🏷️ Titre principal de la carte
  final String value; // 🔢 Valeur affichée dans la carte

  const MiniStatCard({
    super.key, // 🔑 Clé pour le widget
    required this.title, // 🏷️ Titre du widget,
    required this.value, // 🔢 Valeur du widget,
  });

  @override
  Widget build(BuildContext context) {
    logMiniStatCard('🧱 Construction de la carte "$title" avec valeur "$value"');

    return BaseStatCard( // 🧱 Utilise la structure générique
      title: title, // 🏷️ Passe le titre à afficher
      child: Text( // 🔤 Contenu principal
        value, // 📦 Valeur stat
        style: _numberStyle, // 🎨 Style du texte
        textAlign: TextAlign.center, // 🧭 Centré horizontalement
      ),
    );
  }
}

// 🎨 Style texte pour les chiffres/statistiques
const TextStyle _numberStyle = TextStyle(
  fontSize: 24, // 🔠 Taille de police
  fontWeight: FontWeight.bold, // 🅱️ Gras pour lisibilité
);
