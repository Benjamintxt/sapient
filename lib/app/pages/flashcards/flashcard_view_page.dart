// 📄 flashcard_view_page.dart
// 👁️ Page de visualisation d’une flashcard (texte ou image), avec possibilité de la retourner et de l’éditer

import 'package:flutter/material.dart'; // 🎨 UI Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌐 Traductions
import 'package:sapient/app/pages/flashcards/edit/edit_flashcard_page.dart'; // ✏️ Page d’édition

// 🔧 Logs de debug activables
const bool kEnableFlashcardViewLogs = false;
void logFlashcardView(String msg) {
  if (kEnableFlashcardViewLogs) print('[FlashcardView] $msg');
}

class FlashcardViewPage extends StatefulWidget {
  final String front; // 🔹 Texte du recto
  final String back; // 🔹 Texte du verso
  final String flashcardId; // 🆔 ID de la carte
  final String subjectId; // 📁 ID du sujet
  final String userId; // 👤 ID utilisateur
  final int level; // 🔢 Niveau hiérarchique
  final List<String>? parentPathIds; // 🧭 Chemin hiérarchique
  final String? imageFrontUrl; // 📸 Image du recto
  final String? imageBackUrl; // 📸 Image du verso

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
  bool showFront = true; // 🔁 Recto ou verso

  void _flipCard() {
    logFlashcardView("🔁 Carte retournée");
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
          // 🌸 Fond d’écran
          Positioned.fill(
            child: Image.asset(
              'assets/images/FlashCard View.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withAlpha(25)),
          ),

          // 🔙 Flèche retour
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

          // 📛 Titre "Flashcard"
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

          // 🧠 Contenu principal : carte + bouton
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔁 Carte à retourner
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
                  child: () {
                    final imageUrl = showFront ? widget.imageFrontUrl : widget.imageBackUrl;
                    final side = showFront ? 'front' : 'back';
                    logFlashcardView("👁️ Affichage du côté $side");

                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      );
                    } else {
                      final text = showFront ? widget.front : widget.back;
                      return Text(
                        text,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      );
                    }
                  }(),
                ),
              ),
              const SizedBox(height: 40),
              // ✏️ Bouton édition
              Center(
                child: FloatingActionButton(
                  heroTag: 'edit',
                  onPressed: () {
                    logFlashcardView("✏️ Édition de la carte");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditFlashcardPage(
                          initialFront: widget.front,
                          initialBack: widget.back,
                          flashcardId: widget.flashcardId,
                          subjectId: widget.subjectId,
                          userId: widget.userId,
                          level: widget.level,
                          parentPathIds: widget.parentPathIds,
                          imageFrontUrl: widget.imageFrontUrl,
                          imageBackUrl: widget.imageBackUrl,
                        ),
                      ),
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