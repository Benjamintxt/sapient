// 📄 profile_editable_card.dart
// 📝 Carte de profil modifiable avec champ et icône "éditer"

import 'package:flutter/material.dart'; // 🎨 UI Flutter

// 🟢 Active ou désactive les logs liés à l’édition des cartes de profil
const bool kEnableProfileCardLogs = true;

/// 🧾 Log conditionnel pour le debug des cartes modifiables
void logProfileCard(String message) {
  if (kEnableProfileCardLogs) print('[EditableCard] $message');
}

/// 📝 Widget carte modifiable utilisée dans la page de profil
class ProfileEditableCard extends StatelessWidget {
  final String label; // 🏷️ Libellé du champ (ex: "Nom")
  final String value; // 📝 Valeur affichée (ex: "Maxime")
  final VoidCallback onEdit; // ✏️ Fonction appelée lors d’un clic sur l’icône "éditer"

  const ProfileEditableCard({
    super.key,
    required this.label, // 🎯 Libellé obligatoire
    required this.value, // 📝 Valeur affichée obligatoire
    required this.onEdit, // ✏️ Callback d’édition obligatoire
  });

  @override
  Widget build(BuildContext context) {
    // 🖨️ Log d’affichage de la carte
    logProfileCard('Affichage carte: "$label" = "$value"');

    return Card(
      color: Colors.white.withAlpha(229), // 🎨 Fond légèrement transparent
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🟦 Bords arrondis
      elevation: 4, // 🌑 Ombre portée
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // 📏 Marge intérieure
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // ↖️ Aligne à gauche
                children: [
                  Text(
                    label, // 🏷️ Titre du champ
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4), // 📏 Espacement entre titre et valeur
                  Text(
                    value, // 📝 Contenu de la valeur affichée
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.deepPurple), // ✏️ Icône éditer
              onPressed: () {
                logProfileCard('🖱️ Click sur "éditer" pour $label'); // 🖨️ Log clic
                onEdit(); // 🔁 Lance le callback fourni
              },
            ),
          ],
        ),
      ),
    );
  }
}