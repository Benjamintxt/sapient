// 🔹 flashcard_tile.dart
// Ce widget représente une seule flashcard dans la liste avec un joli design pastel et des interactions

import 'package:flutter/material.dart'; // 🎨 UI Flutter

/// 🔹 Widget individuel représentant une flashcard dans la liste principale
class FlashcardTile extends StatelessWidget {
  final String docId; // 🆔 ID de la flashcard (Firestore)
  final String frontText; // 📄 Texte du recto
  final String? imageFrontUrl; // 🖼️ Image éventuelle du recto
  final String? imageBackUrl; // 🖼️ Image éventuelle du verso
  final VoidCallback onTap; // 👁️ Callback affichage détail au clic
  final VoidCallback onLongPress; // 🗑️ Callback suppression (long appui)

  const FlashcardTile({
    super.key,
    required this.docId,
    required this.frontText,
    this.imageFrontUrl,
    this.imageBackUrl,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // 👆 Taper → ouvrir la vue détaillée
      onLongPress: onLongPress, // ✋ Long appui → suppression
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(229), // 🎨 Couleur pastel
            borderRadius: BorderRadius.circular(24), // 🟣 Coins arrondis doux
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25), // 🌫️ Légère ombre
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            title: Text(
              frontText, // 🧠 Texte visible sur la carte
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C), // 🌸 Couleur violette douce
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF4A148C)), // 👉 Chevron décoratif
          ),
        ),
      ),
    );
  }
}
