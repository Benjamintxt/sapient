// edit_flashcard_text_field.dart
// Widget champ de texte pour l'édition de flashcard

import 'package:flutter/material.dart';

// 🟢 Activer/désactiver les logs d’édition de flashcard
const bool kEnableEditFlashcardLogs = false;

/// Fonction de log conditionnelle
void logEditFlashcard(String message) {
  if (kEnableEditFlashcardLogs) print("[EditFlashcard] $message");
}


/// Champ de texte réutilisable pour l’édition du recto/verso
class EditFlashcardTextField extends StatelessWidget {
  final TextEditingController controller; // Contrôleur du champ

  const EditFlashcardTextField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    //  Log optionnel pour le debug (affiche la valeur courante du champ)
    logEditFlashcard(" Affichage du champ texte (valeur: ${controller.text})");

    return TextField(
      controller: controller, //  Connecte le champ au contrôleur (pour lire/modifier le texte)
      autofocus: true, //  Active automatiquement le curseur à l’ouverture de la page
      textAlign: TextAlign.center, // Centre le texte dans le champ
      style: const TextStyle(fontSize: 20), // Définit la taille de la police
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // Bords arrondis du champ
        ),
        filled: true, // Active le fond coloré
        fillColor: Colors.white, // Fond blanc pour une bonne lisibilité
      ),
    );
  }
}
