// 📄 edit_flashcard_image_viewer.dart
// 📸 Widget pour afficher dynamiquement l'image recto ou verso dans la page d'édition

import 'package:flutter/material.dart';

// 🟢 Activer/désactiver les logs d'image
const bool kEnableEditImageLogs = false;

/// 🔊 Log conditionnel pour le debug image
void logEditImage(String message) {
  if (kEnableEditImageLogs) print("[EditImage] $message");
}

/// 📸 Widget qui affiche une image de flashcard (recto ou verso)
class EditFlashcardImageViewer extends StatelessWidget {
  final String? imageUrl; // 📷 URL de l'image à afficher (recto ou verso)
  final VoidCallback onTap; // 🔍 Callback si on tape sur l'image

  const EditFlashcardImageViewer({
    super.key,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    logEditImage("📸 Affichage image : ${imageUrl ?? 'Aucune'}");

    return GestureDetector(
      onTap: onTap, // 🔍 Gère le retournement ou l'action sur l'image
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35, // 📏 Agrandit l'image à 35% de la hauteur écran // ⬆️ Taille fixe
        decoration: BoxDecoration(
          color: Colors.white, // 🌟 Fond blanc
          borderRadius: BorderRadius.circular(16), // 📆 Bords arrondis
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25), // 🌫️ Ombre douce
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl!, // 🌐 Chargement dynamique
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        )
            : const Center(
          child: Text(
            "Image manquante",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}