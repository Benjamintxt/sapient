//  bottom_action_buttons.dart
// Ce widget affiche les 3 boutons flottants en bas de l'écran :  Ajouter,  Caméra, Révision

import 'package:flutter/material.dart'; // 🎨 UI Flutter

/// Widget contenant les 3 FloatingActionButtons du bas
class BottomActionButtons extends StatelessWidget {
  final VoidCallback onAdd; //  Callback pour ajouter une flashcard
  final VoidCallback onCamera; // Callback pour ajouter via la caméra
  final VoidCallback onReview; // Callback pour lancer la révision

  const BottomActionButtons({
    super.key,
    required this.onAdd,
    required this.onCamera,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, //  Répartition équitable
      children: [
        _buildButton(Icons.add, 'add', onAdd), // Ajouter
        _buildButton(Icons.camera_alt, 'camera', onCamera), // Caméra
        _buildButton(Icons.lightbulb, 'review', onReview), // Révision
      ],
    );
  }

  /// Crée un FloatingActionButton personnalisé
  Widget _buildButton(IconData icon, String heroTag, VoidCallback onPressed) {
    return FloatingActionButton(
      heroTag: heroTag, // Tag unique pour éviter les conflits
      onPressed: onPressed, //  Action associée
      backgroundColor: Colors.deepPurple, // Couleur du bouton
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Coins doux
      child: Icon(icon, color: Colors.white, size: 28), // Icône blanche
    );
  }
}
