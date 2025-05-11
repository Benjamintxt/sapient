// edit_flashcard_action_buttons.dart
// Boutons d'action pour l'édition d'une flashcard : voir recto/verso, prendre photo, valider

import 'package:flutter/material.dart'; // UI Flutter

// Active ou désactive les logs de debug pour les boutons d'action
const bool kEnableEditFlashcardButtonsLogs = false;

/// Fonction de log conditionnelle
void logEditFlashcardButtons(String message) {
  if (kEnableEditFlashcardButtonsLogs) print("[EditButtons] $message");

}

// Widget des boutons d'action (voir recto/verso, capturer image, valider)
class EditFlashcardActionButtons extends StatelessWidget {
  final bool isImageFlashcard; // true si flashcard avec image
  final void Function(bool toFront)? onSwitchSide; // Change le côté visible (texte)
  final void Function(bool forFront)? onCaptureImage; // Capture image recto/verso
  final VoidCallback onSave; // Enregistre

  const EditFlashcardActionButtons({
    super.key,
    required this.isImageFlashcard,
    this.onSwitchSide,
    this.onCaptureImage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Répartit les boutons uniformément dans la ligne
      children: [

        // 🖼Si la flashcard est une image → affiche les boutons pour prendre photo recto / verso
        if (isImageFlashcard) ...[
          // 📸 Bouton pour prendre une photo du recto
          _buildButton(
            icon: Icons.photo_camera_front,
            onTap: () {
              if (isImageFlashcard) {
                onCaptureImage!(false); // Lance caméra uniquement si image
              } else {
                onSwitchSide?.call(false); // Sinon, on passe au verso texte
              }
            },
          ),


          // Bouton pour prendre une photo du verso
          _buildButton(icon: Icons.photo_camera_back,
            onTap: () {
              if (isImageFlashcard) {
                onCaptureImage!(true);
              } else {
                onSwitchSide?.call(true);
              }
            },

          ),
        ],

        // ✍Si la flashcard est textuelle → affiche les boutons pour changer de côté
        if (!isImageFlashcard) ...[
          // ✏Bouton pour afficher ou éditer le recto (texte)
          _buildButton(
            icon: Icons.short_text, // Icône de texte
            onTap: () => onSwitchSide?.call(true),// Action : capturer le verso
          ),

          // Bouton pour afficher ou éditer le verso (texte)
          _buildButton(
            icon: Icons.text_fields, // Icône de texte aussi
            onTap: () => onSwitchSide?.call(false), // Action : basculer vers verso
          ),
        ],

        // Bouton pour enregistrer les modifications de la flashcard
        _buildButton(
          icon: Icons.check, // Icône de validation
          onTap: onSave, // Action d'enregistrement
        ),
      ],
    );
  }

  /// Bouton unique avec icône
  Widget _buildButton({required IconData icon, required VoidCallback onTap}) {
    logEditFlashcardButtons("Bouton créé avec icône: \${icon.codePoint}");
    return FloatingActionButton(
      heroTag: icon.codePoint.toString(), // Clé unique pour chaque FAB
      onPressed: onTap, // Action liée
      backgroundColor: Colors.deepPurple, // Couleur du bouton
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Coins arrondis
      child: Icon(icon, color: Colors.white), // Icône blanche
    );
  }
}