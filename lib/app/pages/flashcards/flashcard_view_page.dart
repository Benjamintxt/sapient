// flashcard_view_page.dart
// Page de visualisation d’une flashcard (texte ou image), avec possibilité de la retourner et de l’éditer

import 'package:flutter/material.dart'; //  UI Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; //  Traductions
import 'package:sapient/app/pages/flashcards/edit/edit_flashcard_page.dart'; // ️Page d’édition

//  Logs de debug activables
const bool kEnableFlashcardViewLogs = false;
void logFlashcardView(String msg) {
  if (kEnableFlashcardViewLogs) print('[FlashcardView] $msg');
}

class FlashcardViewPage extends StatefulWidget {
  final String front; //  Texte du recto
  final String back; //  Texte du verso
  final String flashcardId; //  ID de la carte
  final String subjectId; //  ID du sujet
  final String userId; //  ID utilisateur
  final int level; // Niveau hiérarchique
  final List<String>? parentPathIds; //  Chemin hiérarchique
  final String? imageFrontUrl; // Image du recto
  final String? imageBackUrl; // Image du verso

  const FlashcardViewPage({
    super.key,
    required this.front,
    required this.back,
    required this.flashcardId,
    required this.subjectId,
    required this.userId,
    required this.level,
    required this.parentPathIds,
    this.imageFrontUrl,
    this.imageBackUrl,
  });

  @override
  State<FlashcardViewPage> createState() => _FlashcardViewPageState();
}

class _FlashcardViewPageState extends State<FlashcardViewPage> {
  bool showFront = true; //  Recto ou verso

  void _flipCard() {
    logFlashcardView(" Carte retournée");
    setState(() {
      showFront = !showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fond d’écran
          Positioned.fill(
            child: Image.asset(
              'assets/images/FlashCard View.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withAlpha(25)),
          ),

          // Flèche retour
          Positioned(
            top: 55,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28),
              onPressed: () {
                logFlashcardView("🔙 Retour");
                Navigator.pop(context);
              },
            ),
          ),

          // Titre "Flashcard"
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                local.flashcard,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                  fontFamily: 'Raleway',
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black26,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenu principal : carte + bouton
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Carte à retourner
              GestureDetector(
                onTap: _flipCard,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 300,
                    maxWidth: double.infinity,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (_) {
                      // Détermine la face affichée : recto ou verso
                      final isFront = showFront;
                      final side = isFront ? 'recto' : 'verso';
                      logFlashcardView("Affichage de la face $side");

                      // Texte et image associés à la face visible
                      final text = isFront ? widget.front.trim() : widget.back.trim();
                      final imageUrl = isFront ? widget.imageFrontUrl : widget.imageBackUrl;

                      // Cas 1 : il y a une image à afficher
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        logFlashcardView("Image détectée pour le $side : $imageUrl");
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12), // Coins arrondis doux
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover, // Remplit la zone disponible joliment
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        );
                      }

                      //  Cas 2 : texte disponible à afficher
                      if (text.isNotEmpty) {
                        logFlashcardView(" [FlashcardViewPage] Texte détecté pour le $side : \"$text\"");
                        return Text(
                          text,
                          style: const TextStyle(
                            fontSize: 20, // Taille confortable
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center, // Centré
                        );
                      }

                      // Cas 3 : ni texte ni image
                      logFlashcardView("[FlashcardViewPage] Rien à afficher pour le $side");
                      return const Text(
                        '[Flashcard vide]',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Bouton édition
              Center(
                child: FloatingActionButton(
                  heroTag: 'edit',
                  onPressed: () {
                    logFlashcardView("️ [FlashcardViewPage] Édition de la carte");

                    final bool hasParent = widget.parentPathIds != null && widget.parentPathIds!.isNotEmpty;
                    final String effectiveSubjectId = hasParent ? widget.parentPathIds!.last : widget.subjectId;
                    final List<String> effectiveParentPathIds =
                    hasParent ? widget.parentPathIds!.sublist(0, widget.parentPathIds!.length - 1) : [];

                    logFlashcardView(
                      " [FlashcardViewPage] Chemin vers l'édition : users/${widget.userId}/subjects/$effectiveSubjectId/"
                          "subsubject${widget.level}/flashcards/${widget.flashcardId}",
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditFlashcardPage(
                          initialFront: widget.front,
                          initialBack: widget.back,
                          flashcardId: widget.flashcardId,
                          subjectId: effectiveSubjectId,
                          userId: widget.userId,
                          level: widget.level,
                          parentPathIds: effectiveParentPathIds, //
                          imageFrontUrl: widget.imageFrontUrl,
                          imageBackUrl: widget.imageBackUrl,
                        ),
                      ),
                    );

                    logFlashcardView(
                      "[FlashcardViewPage] Navigation vers EditFlashcardPage avec : subjectId=$effectiveSubjectId, "
                          "parentPathIds=$effectiveParentPathIds, level=${widget.level}, flashcardId=${widget.flashcardId}",
                    );
                  },

                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit, size: 32, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}