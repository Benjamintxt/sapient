// 📄 flashcard_tile.dart
// 🔹 Widget représentant une flashcard dans la liste avec affichage conditionnel (texte ou image)

import 'package:flutter/material.dart'; // 🎨 UI Flutter

// 🔧 Constante de debug (active ou non les logs console)
const bool kEnableFlashcardTileLogs = false;

/// 📢 Fonction de log conditionnelle pour FlashcardTile
void logFlashcardTile(String msg) {
  if (kEnableFlashcardTileLogs) print('[🧩 FlashcardTile] $msg');
}

/// 🔹 Widget individuel représentant une flashcard dans la liste principale
class FlashcardTile extends StatelessWidget {
  final String docId; // 🆔 ID Firestore de la flashcard
  final String frontText; // 📄 Texte du recto
  final String? imageFrontUrl; // 🖼️ URL image du recto (si présente)
  final String? imageBackUrl; // 🖼️ URL image du verso (non utilisé ici mais fourni pour la navigation)
  final VoidCallback onTap; // 👁️ Callback quand on appuie (ouvrir la carte)
  final VoidCallback onLongPress; // 🗑️ Callback quand on maintient (suppression)

  const FlashcardTile({
    super.key, // 🗝️ Clé Flutter (gestion widget identique)
    required this.docId, // 📌 ID unique Firestore
    required this.frontText, // 📄 Texte du recto obligatoire
    this.imageFrontUrl, // 🌄 Image du recto optionnelle
    this.imageBackUrl, // 🌄 Image du verso optionnelle (non affichée ici)
    required this.onTap, // 👆 Action sur clic
    required this.onLongPress, // ✋ Action sur long clic
  });

  @override
  Widget build(BuildContext context) {
    // 📋 Log de debug avec tous les champs utiles
    logFlashcardTile('docId=$docId | texte="${frontText.trim()}" | imageFrontUrl=$imageFrontUrl');

    return GestureDetector( // 👂 Gère les interactions utilisateur
      onTap: onTap, // 👆 Appui court
      onLongPress: onLongPress, // ✋ Appui long
      child: Padding( // 📐 Marge autour de la carte
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // ↔️↕️ Marges internes
        child: Container( // 📦 Boîte contenant la ListTile stylée
          decoration: BoxDecoration( // 🎨 Style de la carte
            color: Colors.white.withAlpha(229), // 🏳️ Couleur blanche semi-transparente
            borderRadius: BorderRadius.circular(24), // ⭕ Coins arrondis
            boxShadow: [ // 🌫️ Ombre douce
              BoxShadow(
                color: Colors.black.withAlpha(25), // ⚫ Ombre noire claire
                blurRadius: 6, // 🔍 Flou doux
                offset: const Offset(0, 4), // ⬇️ Décalage vers le bas
              ),
            ],
          ),
          child: ListTile( // 🧱 Contenu structuré (titre + icône)
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // 📐 Espace interne

            title: // 🏷️ Zone principale (texte ou image)
            frontText.trim().isNotEmpty // 🧪 Si le texte du recto est non vide
                ? Text( // 📝 Cas 1 : Affichage du texte
              frontText, // 📝 Affiche le texte brut
              style: const TextStyle( // 🎨 Style du texte
                fontSize: 18, // 🔠 Taille lisible
                fontWeight: FontWeight.bold, // 💪 En gras
                color: Color(0xFF4A148C), // 🟣 Violet Sapient
              ),
            )

                : (imageFrontUrl != null && imageFrontUrl!.isNotEmpty) // 🧪 Cas 2 : Image sans texte
                ? Row( // 📏 Ligne avec icône et label image
              children: [
                const Icon( // 🖼️ Icône image
                  Icons.image,
                  size: 20,
                  color: Colors.teal, // 🌿 Vert doux
                ),
                const SizedBox(width: 8), // ↔️ Espace entre icône et texte
                const Text(
                  '[Image]', // 🏷️ Libellé indiquant image
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                ),
              ],
            )

                : const Text( // 🚨 Cas 3 : Vide total (alerte)
              '[Flashcard vide]', // ⚠️ Indicateur carte vide
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red, // 🚨 Rouge d’alerte
              ),
            ),

            trailing: const Icon( // 👉 Chevron décoratif (à droite)
              Icons.chevron_right, // ➡️ Icône
              color: Color(0xFF4A148C), // 🟣 Violet cohérent
            ),
          ),
        ),
      ),
    );
  }
}