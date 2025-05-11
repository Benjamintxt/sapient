// review_flashcard_card.dart
// Widget principal pour l'affichage d'une flashcard dans la page de révision

import 'package:flutter/material.dart'; // UI Flutter

// Constante pour activer ou désactiver les logs
const bool kEnableFlashcardLogs = false;

/// Fonction utilitaire pour afficher les logs si activés
void logFlashcard(String message) {
  if (kEnableFlashcardLogs) print(message); // Affiche uniquement si les logs sont activés
}

/// Affiche une carte avec image ou texte et un effet de retournement
class ReviewFlashcardCard extends StatelessWidget {
  final bool showQuestion; // true = recto (question), false = verso (réponse)
  final Map<String, dynamic> flashcard; // Données de la flashcard
  final VoidCallback onTap; // Fonction appelée lorsqu'on tape sur la carte

  const ReviewFlashcardCard({
    super.key, // Clé du widget (recommandée pour les StatelessWidget)
    required this.showQuestion,
    required this.flashcard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = showQuestion
        ? flashcard['imageFrontUrl'] // URL de l'image recto
        : flashcard['imageBackUrl']; // URL de l'image verso

    final text = showQuestion
        ? flashcard['front'] // Texte recto
        : flashcard['back']; // Texte verso

    // Log de debug pour savoir ce qui va être affiché
    logFlashcard(" [ReviewFlashcardCard] Affichage du ${showQuestion ? 'recto' : 'verso'} : "
        "${imageUrl != null && imageUrl.toString().isNotEmpty ? 'Image' : ' Texte'}");

    return GestureDetector(
      onTap: () {
        logFlashcard(" [ReviewFlashcardCard] Tap détecté → on retourne la carte");
        onTap(); // Appelle effectivement la fonction
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // Animation de transition
        padding: const EdgeInsets.all(24), // Padding intérieur
        margin: const EdgeInsets.symmetric(horizontal: 24), // Marges latérales
        constraints: const BoxConstraints(
          minHeight: 200, //  Hauteur minimale
          maxHeight: 300, // Hauteur maximale
          maxWidth: double.infinity, //  Largeur maximale
        ),
        alignment: Alignment.center, // Centrage du contenu
        decoration: BoxDecoration(
          color: Colors.white, // Couleur de fond blanche
          borderRadius: BorderRadius.circular(16), // Bords arrondis
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25), // Ombre douce
              blurRadius: 8, // 🔍 Flou
              offset: const Offset(0, 4), // Décalage vers le bas
            ),
          ],
        ),
        child: imageUrl != null && imageUrl.toString().isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12), // Coins arrondis image
          child: Image.network(
            imageUrl, // Chargement image réseau
            fit: BoxFit.cover, //Couvre tout l'espace disponible
            width: double.infinity, // Prend toute la largeur
            height: double.infinity, // Prend toute la hauteur
          ),
        )
            : Text(
          text ?? '', // Affiche le texte si pas d'image
          style: const TextStyle(fontSize: 20), //️ Taille de police
          textAlign: TextAlign.center, // Centrage du texte
        ),
      ),
    );
  }
}
