// edit_flashcard_page.dart
// Page de modification d'une flashcard (texte ou image)


import 'package:flutter/material.dart'; // 🎨 UI Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌍 Localisation multilingue

import 'package:sapient/services/firestore/flashcards_service.dart'; // 🔥 Service Firestore des flashcards
import 'package:sapient/app/pages/utils/camera_page.dart'; // 📷 Page de capture caméra personnalisée


import 'edit_flashcard_image_viewer.dart'; // 🖼️ Visualiseur d’image dynamique
import 'edit_flashcard_action_buttons.dart'; // Boutons actions édition (valider, changer côté, etc.)

// Constante pour activer/désactiver les logs dans cette page
const bool kEnableEditLogs = false;

/// 🖨Fonction de log centralisée pour l’édition
void logEdit(String message) {
  if (kEnableEditLogs) print('[EditPage] $message');
}

class EditFlashcardPage extends StatefulWidget {
  final String initialFront; // Texte initial recto
  final String initialBack; // Texte initial verso
  final String flashcardId; // ID de la flashcard
  final String subjectId; // ID du sujet associé
  final String userId; // Utilisateur connecté
  final int level; // Niveau hiérarchique
  final List<String>? parentPathIds; // Chemin Firestore complet
  final String? imageFrontUrl; // URL image recto (optionnel)
  final String? imageBackUrl; // URL image verso (optionnel)

  const EditFlashcardPage({
    super.key,
    required this.initialFront,
    required this.initialBack,
    required this.flashcardId,
    required this.subjectId,
    required this.userId,
    required this.level,
    required this.parentPathIds,
    this.imageFrontUrl,
    this.imageBackUrl,
  });

  @override
  State<EditFlashcardPage> createState() => _EditFlashcardPageState();
}

class _EditFlashcardPageState extends State<EditFlashcardPage> {
  late TextEditingController _controller; // Contrôle le texte édité
  bool isEditingFront = true; // Suivi du côté en édition (texte)
  late String editedFront; // Nouveau recto
  late String editedBack; // Nouveau verso
  String? editedImageFront; // Nouvelle image recto (URL Firebase)
  String? editedImageBack; // Nouvelle image verso
  bool showFront = true; // 👁Vue actuelle (recto ou verso)

  // Détermine si la carte est de type image ou texte
  bool get isImageFlashcard =>
      (editedImageFront != null && editedImageFront!.isNotEmpty) ||
          (editedImageBack != null && editedImageBack!.isNotEmpty);
  @override
  void initState() {
    super.initState();
    logEdit("Initialisation de la page d’édition");

    // Récupération initiale des textes
    editedFront = widget.initialFront;
    editedBack = widget.initialBack;

    // Récupération initiale des images
    editedImageFront = widget.imageFrontUrl;
    editedImageBack = widget.imageBackUrl;

    // Sécurité : remet à null si ce sont des chaînes vides
    if ((editedImageFront == null || editedImageFront!.isEmpty) &&
        (editedImageBack == null || editedImageBack!.isEmpty)) {
      editedImageFront = null;
      editedImageBack = null;
    }


    _controller = TextEditingController(text: editedFront);
  }

  /// Change le côté affiché ou édité
  void _switchSide(bool toFront) {
    logEdit("Changement de côté vers ${toFront ? 'recto' : 'verso'}");
    setState(() {
      if (isImageFlashcard) {
        logEdit("Passage image - affichage uniquement");
        showFront = toFront; // 📷 Affichage uniquement
      } else {
        logEdit("Passage texte - changement de côté avec champ texte");
        // Sauvegarde temporaire du texte avant de changer
        if (isEditingFront) editedFront = _controller.text;
        else editedBack = _controller.text;

        isEditingFront = toFront; // Mise à jour de l'état
        _controller.text = isEditingFront ? editedFront : editedBack; // Met à jour le champ
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length), // Curseur à la fin
        );
      }
    });
  }

  /// Lance la caméra et enregistre l’image dans Firebase Storage
  Future<void> _captureImageForSide(bool forFront) async {
    logEdit(" Capture d'image pour le côté : ${forFront ? 'recto' : 'verso'}");
    final image = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraPage()),
    );
    if (image != null) {
      final url = await FirestoreFlashcardsService().uploadImage(
        image: image,
        userId: widget.userId,
        subjectId: widget.subjectId,
        parentPathIds: widget.parentPathIds!,
      );
      setState(() {
        if (forFront) {
          editedImageFront = url;
          showFront = true;
        } else {
          editedImageBack = url;
          showFront = false;
        }
      });
      logEdit(" Image mise à jour → isImageFlashcard = $isImageFlashcard");
    }
  }

  /// Sauvegarde les modifications dans Firestore
  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus(); // Ferme le clavier
    logEdit("💾 Tentative de sauvegarde des modifications");
    if (!isImageFlashcard) {
      if (isEditingFront) editedFront = _controller.text;
      else editedBack = _controller.text;
    } else {
      editedFront = _controller.text; // Texte seulement si image présente
    }

    try {
      await FirestoreFlashcardsService().updateFlashcard(
        userId: widget.userId,
        subjectId: widget.subjectId,
        flashcardId: widget.flashcardId,
        front: editedFront,
        back: editedBack,
        level: widget.level,
        parentPathIds: widget.parentPathIds!,
        imageFrontUrl: editedImageFront,
        imageBackUrl: editedImageBack,
      );

      logEdit(" Sauvegarde réussie");
      Navigator.pop(context);
    } catch (e) {
      logEdit(" Erreur de sauvegarde : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la sauvegarde : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Permet à la vue de se redimensionner quand le clavier apparaît
      extendBodyBehindAppBar: true, // 🌫Étend le fond derrière la barre supérieure (effet visuel doux)
      backgroundColor: Colors.transparent, // Fond transparent pour laisser passer l’image en-dessous

      body: Stack( // Superpose plusieurs éléments graphiques
        children: [
          // Image de fond principale (vue pastel avec bonsaï)
          Positioned.fill(
            child: Image.asset(
              'assets/images/FlashCard View.png', // Chemin de l’image de fond
              fit: BoxFit.cover, // Ajuste l’image pour couvrir tout l’espace
            ),
          ),

          // 🌫Voile blanc semi-transparent au-dessus de l’image pour lisibilité
          Positioned.fill(
            child: Container(
              color: Colors.white.withAlpha(26),  // Opacité légère
            ),
          ),

          // 🔙 Bouton retour (en haut à gauche)
          Positioned(
            top: 55,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28), // Couleur violette
              onPressed: () {
                logEdit(" Retour en arrière depuis la page d’édition");
                Navigator.pop(context); // Ferme la page
              },
            ),
          ),


          // Titre centré "Modifier la flashcard"
          Positioned(
            top: 50, // Position verticale à 50 pixels du haut
            left: 0, // Prend toute la largeur
            right: 0,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.editFlashcard, // Texte localisé "Modifier la flashcard"
                style: const TextStyle(
                  fontSize: 32, // 🔠 Taille du texte
                  fontWeight: FontWeight.bold, // Texte en gras
                  color: Color(0xFF4A148C), // Couleur violette profonde (cohérente avec le thème)
                  fontFamily: 'Raleway', // Police personnalisée
                  shadows: [
                    Shadow(
                      blurRadius: 3, // Effet de flou léger
                      color: Colors.black26, // Ombre noire avec opacité
                      offset: Offset(1, 2), // Décalage léger vers le bas et à droite
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenu principal (champ de texte ou image + boutons)
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 250, // Espace depuis le haut pour ne pas masquer le titre
                left: 24, // Marge à gauche
                right: 24, // Marge à droite
                bottom: MediaQuery.of(context).viewInsets.bottom + 40, // Ajuste le bas selon le clavier
              ),
              child: Column(
                children: [
                  // Affichage du champ texte si la flashcard est textuelle uniquement
                  if (!isImageFlashcard)
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 200, // Hauteur minimale
                        maxHeight: 400, // Hauteur maximale pour limiter l’expansion
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller, // Contrôle le texte
                          maxLines: null, // Permet plusieurs lignes
                          expands: true, // Remplit toute la hauteur disponible
                          textAlign: TextAlign.center, //  Centre horizontalement
                          textAlignVertical: TextAlignVertical.center, //  Centre verticalement
                          style: const TextStyle(fontSize: 22), // Taille du texte
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Espace intérieur
                            filled: true,
                            fillColor: Colors.white, // Fond blanc
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),




                  // Affichage de l’image si c’est une flashcard avec image (recto/verso)
                  if (isImageFlashcard)
                    EditFlashcardImageViewer(
                      imageUrl: showFront ? editedImageFront : editedImageBack, //  Affiche recto ou verso selon l’état
                      onTap: () => setState(() => showFront = !showFront), // Inverse la face affichée au clic
                    ),

                  const SizedBox(height: 40), // Espace vertical entre le contenu et les boutons

                  // Ligne des boutons : voir recto/verso, capturer image, valider
                  EditFlashcardActionButtons(
                    isImageFlashcard: isImageFlashcard, // S’adapte selon le type de flashcard
                    onSwitchSide: _switchSide, // Fonction de changement de face
                    onCaptureImage: _captureImageForSide, // Fonction pour lancer la caméra
                    onSave: _saveChanges, // Fonction de sauvegarde finale
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}