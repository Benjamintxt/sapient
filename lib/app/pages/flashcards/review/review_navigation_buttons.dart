// 📁 review_navigation_buttons.dart
// Boutons de navigation entre flashcards (précédent / suivant)

import 'package:flutter/material.dart'; // 🎨 UI Flutter

/// 🔘 Widget pour afficher les deux flèches de navigation (gauche et droite)
class ReviewNavigationButtons extends StatelessWidget {
  final VoidCallback onPrevious; // ⬅️ Action quand on clique sur "précédent"
  final VoidCallback onNext; // ➡️ Action quand on clique sur "suivant"

  const ReviewNavigationButtons({
    super.key, // 🔑 Clé Flutter pour l’optimisation
    required this.onPrevious, // 📥 Callback précédent obligatoire
    required this.onNext, // 📥 Callback suivant obligatoire
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // 📍 Centre les deux flèches horizontalement
      children: [
        // 🔙 Flèche gauche (précédent)
        IconButton(
          icon: const Icon(Icons.arrow_back_ios), // ⬅️ Icône flèche gauche
          onPressed: onPrevious, // ⬅️ Appelle la fonction "précédent"
        ),

        const SizedBox(width: 24), // 🧱 Espacement entre les deux flèches

        // 🔜 Flèche droite (suivant)
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios), // ➡️ Icône flèche droite
          onPressed: onNext, // ➡️ Appelle la fonction "suivant"
        ),
      ],
    );
  }
}
