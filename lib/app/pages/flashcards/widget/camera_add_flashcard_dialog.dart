// 📷 camera_add_flashcard_dialog.dart
// Gère l’ajout d’une flashcard image via la caméra (recto puis verso en option)

import 'dart:io'; // 📁 Pour manipuler des fichiers (ex: File image)
import 'package:flutter/material.dart'; // 🎨 Widgets Flutter
import 'package:sapient/services/firestore/flashcards_service.dart'; // 📦 Service Firestore pour flashcards
import '../../utils/camera_page.dart'; // 📷 Page caméra
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌐 Localisation des textes

/// 🔧 Affiche un dialogue pour créer une flashcard image (recto ou verso d’abord)
Future<void> showCameraAddFlashcardDialog({
  required BuildContext context, // 🖼️ Contexte Flutter
  required String userId, // 👤 UID utilisateur
  required String subjectId, // 🧩 ID du sujet actuel
  required int level, // 🔢 Niveau hiérarchique (ex: 2)
  required List<String>? parentPathIds, // 🧭 Liste des IDs parents
}) async {
  final TextEditingController _nameController = TextEditingController(); // ✏️ Contrôle du nom de la carte
  final local = AppLocalizations.of(context)!; // 🌍 Localisation en cours

  // 🧾 Étape 1 — Affiche le dialogue pour choisir le côté d'abord
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // ⭕ Coins arrondis
      backgroundColor: Colors.white, // ⚪ Fond clair
      title: Text(
        local.chooseImageSide, // 🏷️ "Choisir un côté à photographier"
        style: const TextStyle(fontWeight: FontWeight.bold), // 🅱️ Texte en gras
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min, // 📐 Ne prend que la taille nécessaire
        children: [
          // 🖊️ Champ texte pour nom de la flashcard
          TextField(
            controller: _nameController, // 🧠 Contrôle de texte lié
            decoration: InputDecoration(
              hintText: local.flashcardNameHint, // 💬 Placeholder
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // ⭕ Bord arrondi
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 📏 Padding interne
            ),
          ),
          const SizedBox(height: 20), // ↕️ Espace
          // ➕ Boutons pour choisir recto/verso ou annuler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 📷 Capture du recto
              FloatingActionButton(
                heroTag: 'toFront',
                onPressed: () {
                  Navigator.pop(context); // 🔙 Ferme le dialogue
                  _startCapture(context, userId, subjectId, level, parentPathIds, _nameController.text, 'front');
                },
                backgroundColor: Colors.black,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
              // 📷 Capture du verso
              FloatingActionButton(
                heroTag: 'toBack',
                onPressed: () {
                  Navigator.pop(context);
                  _startCapture(context, userId, subjectId, level, parentPathIds, _nameController.text, 'back');
                },
                backgroundColor: Colors.black,
                child: const Icon(Icons.arrow_downward, color: Colors.white),
              ),
              // ❌ Annulation
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

/// 📸 Capture image(s), upload, puis création de la flashcard Firestore
Future<void> _startCapture(
    BuildContext context,
    String userId,
    String subjectId,
    int level,
    List<String>? parentPathIds,
    String flashcardName,
    String side, // 'front' ou 'back'
    ) async {
  // 📦 Service Firestore utilisé pour upload + création de la flashcard
  final firestore = FirestoreFlashcardsService();

  // 🧮 Crée une copie sûre des parentPathIds (vide si null)
  final List<String> correctedParentPathIds = [...?parentPathIds];
  int effectiveLevel = level; // 🔢 Niveau effectif, ajusté en cas de correction

  // 🧹 Vérifie si le dernier ID des parents est égal au sujet actuel
  // Cela arrive si l’ID du sujet a été ajouté deux fois par erreur (doublon)
  if (parentPathIds != null &&
      parentPathIds.isNotEmpty &&
      parentPathIds.last == subjectId &&
      level == parentPathIds.length) {
    correctedParentPathIds.removeLast(); // ❌ Supprime le doublon final
    effectiveLevel = correctedParentPathIds.length; // ✅ Corrige aussi le niveau
    debugPrint('! [addFlashcard] Correction du chemin : suppression du doublon final');
  }

  // 📷 Lance la capture de la première image (recto ou verso selon `side`)
  final File? firstImage = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CameraPage()),
  );

  // ❌ Si l’utilisateur annule la prise de photo → abandon
  if (firstImage == null) return;

  // 📤 Upload de l’image capturée vers Firebase Storage
  debugPrint('📄 [uploadImage] Début upload image 1...');
  final String firstUrl = await firestore.uploadImage(
    image: firstImage,
    userId: userId,
    subjectId: subjectId,
    parentPathIds: correctedParentPathIds,
  );
  debugPrint('✅ Image 1 uploadée → $firstUrl');

  // ❓ Dialogue : proposer à l’utilisateur de prendre aussi l’autre côté
  final local = AppLocalizations.of(context)!;
  final bool? wantSecondSide = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(local.addSecondSide),
      content: Text(side == 'front'
          ? "Tu veux aussi prendre le verso ?"
          : "Tu veux aussi prendre le recto ?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(local.no),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(local.yes),
        ),
      ],
    ),
  );

  // 📷 Capture du deuxième côté si l’utilisateur a accepté
  String? secondUrl;
  if (wantSecondSide == true) {
    debugPrint('📸 Capture de la deuxième image...');
    final File? secondImage = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraPage()),
    );

    // 📤 Upload de la deuxième image si elle existe
    if (secondImage != null) {
      debugPrint('📄 [uploadImage] Début upload image 2...');
      secondUrl = await firestore.uploadImage(
        image: secondImage,
        userId: userId,
        subjectId: subjectId,
        parentPathIds: correctedParentPathIds,
      );
      debugPrint('✅ Image 2 uploadée → $secondUrl');
    } else {
      debugPrint('⚠️ Deuxième capture annulée');
    }
  }

  // ➕ Création de la flashcard dans Firestore avec tous les éléments
  debugPrint('➕ [addFlashcard] DÉBUT : subject=$subjectId | level=$effectiveLevel | parentPathIds=$correctedParentPathIds');
  await firestore.addFlashcard(
    userId: userId,
    subjectId: subjectId,
    front: side == 'front' ? flashcardName : '',
    back: side == 'back' ? flashcardName : '',
    imageFrontUrl: side == 'front' ? firstUrl : secondUrl,
    imageBackUrl: side == 'back' ? firstUrl : secondUrl,
    level: effectiveLevel,
    parentPathIds: correctedParentPathIds,
  );

  // ✅ SnackBar de confirmation à l’utilisateur
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(local.flashcardAdded ?? "Flashcard ajoutée avec succès")),
  );
}


