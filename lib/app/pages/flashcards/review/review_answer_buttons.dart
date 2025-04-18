// 📁 review_answer_buttons.dart
// Boutons de réponse à une flashcard pendant la révision (✅ Bonne réponse, ❌ Mauvaise réponse)

import 'package:flutter/material.dart'; // 🎨 UI Flutter

/// 🔘 Boutons pour répondre à une flashcard pendant la révision
///
/// Affiche deux boutons flottants : "mauvaise réponse" (❌) et "bonne réponse" (✅).
/// Lorsqu'un bouton est cliqué, appelle la fonction `onAnswer(bool)` passée en paramètre.
class ReviewAnswerButtons extends StatelessWidget {
  final void Function(bool isCorrect) onAnswer; // ✅ Fonction appelée avec true (✔️) ou false (❌)

  const ReviewAnswerButtons({
    required this.onAnswer, // 📥 Fonction callback pour enregistrer la réponse
    super.key, // 🗝️ Clé Flutter (optionnelle)
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // 🎯 Centrage horizontal
      children: [
        // ❌ Bouton "mauvaise réponse"
        FloatingActionButton(
          heroTag: 'fail_button', // 🏷️ Identifiant unique (évite les conflits d’animation)
          onPressed: () => onAnswer(false), // 📥 Envoie false si mauvaise réponse
          backgroundColor: Colors.deepPurple, // 🎨 Couleur du bouton
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // ⤴️ Coins arrondis
          child: const Icon(Icons.close, color: Colors.white), // ❌ Icône croix
        ),

        const SizedBox(width: 40), // ↔️ Espacement entre les deux boutons

        // ✅ Bouton "bonne réponse"
        FloatingActionButton(
          heroTag: 'success_button', // 🏷️ Identifiant unique
          onPressed: () => onAnswer(true), // 📥 Envoie true si bonne réponse
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.check, color: Colors.white), // ✔️ Icône check
        ),
      ],
    );
  }
}
