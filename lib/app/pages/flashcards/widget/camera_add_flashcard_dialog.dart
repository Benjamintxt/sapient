// 📷 camera_add_flashcard_dialog.dart
// Gère l’ajout d’une flashcard par capture d’image via la caméra : recto, puis éventuellement verso

import 'dart:io'; // 📁 Pour manipuler les fichiers images
import 'package:flutter/material.dart'; // 🎨 UI Flutter
import 'package:sapient/services/firestore/flashcards_service.dart'; // 📦 Service Firestore (upload + flashcard)
import '../../utils/camera_page.dart'; // 📷 Page caméra (retourne un File)
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌐 Localisation des textes

/// 📷 Affiche un dialogue qui permet de capturer des images et créer une flashcard avec images
Future<void> showCameraAddFlashcardDialog({
  required BuildContext context, // 🖼️ Contexte Flutter
  required String userId, // 👤 UID utilisateur
  required String subjectId, // 📚 ID du sujet actuel
  required int level, // 🔢 Niveau de profondeur
  required List<String>? parentPathIds, // 🧱 Chemin d’accès Firestore
}) async {
  final TextEditingController _nameController = TextEditingController(); // 🖊️ Nom de la flashcard
  final local = AppLocalizations.of(context)!; // 🌍 Texte localisé

  // 🧾 Étape 1 — Choix du nom + côté à prendre en photo d’abord
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Text(
        local.chooseImageSide,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: local.flashcardNameHint ?? 'Nom de la flashcard',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'toFront',
                onPressed: () {
                  Navigator.pop(context); // ✅ Ferme le dialogue
                  _startCapture(context, userId, subjectId, level, parentPathIds, _nameController.text, 'front');
                },
                backgroundColor: Colors.black,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
              FloatingActionButton(
                heroTag: 'toBack',
                onPressed: () {
                  Navigator.pop(context);
                  _startCapture(context, userId, subjectId, level, parentPathIds, _nameController.text, 'back');
                },
                backgroundColor: Colors.black,
                child: const Icon(Icons.arrow_downward, color: Colors.white),
              ),
              FloatingActionButton(
                heroTag: 'cancelChoice',
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.grey.shade700,
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// 📸 Étape 2 — Capture image(s), upload, et création de la flashcard
Future<void> _startCapture(
    BuildContext context,
    String userId,
    String subjectId,
    int level,
    List<String>? parentPathIds,
    String flashcardName,
    String side, // 'front' ou 'back'
    ) async {
  final firestore = FirestoreFlashcardsService(); // ✅ Nouveau service modulaire

  // 📷 Prise de la première image
  final File? firstImage = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CameraPage()),
  );

  if (firstImage == null) return; // ❌ Annulation utilisateur

  final String firstUrl = await firestore.uploadImage(
    image: firstImage,
    userId: userId,
    subjectId: subjectId,
    parentPathIds: parentPathIds!,
  );


  // ❓ Propose de prendre aussi le verso (ou recto)
  final local = AppLocalizations.of(context)!;
  final bool? wantSecondSide = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(local.addSecondSide ?? "Ajouter aussi l'autre côté ?"),
      content: Text(side == 'front' ? "Tu veux aussi prendre le verso ?" : "Tu veux aussi prendre le recto ?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(local.no ?? "Non"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(local.yes ?? "Oui"),
        ),
      ],
    ),
  );

  String? secondUrl;
  if (wantSecondSide == true) {
    final File? secondImage = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraPage()),
    );

    if (secondImage != null) {
      secondUrl = await firestore.uploadImage(
        image: secondImage,
        userId: userId,
        subjectId: subjectId,
        parentPathIds: parentPathIds!,
      );

    }
  }

  // 🧠 Création finale de la flashcard dans Firestore
  await firestore.addFlashcard(
    userId: userId,
    subjectId: subjectId,
    front: side == 'front' ? flashcardName : '',
    back: side == 'back' ? flashcardName : '',
    imageFrontUrl: side == 'front' ? firstUrl : secondUrl,
    imageBackUrl: side == 'back' ? firstUrl : secondUrl,
    level: level,
    parentPathIds: parentPathIds,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(local.flashcardAdded)), // ✅ Message de confirmation
  );
}
