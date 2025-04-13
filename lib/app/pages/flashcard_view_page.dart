import 'package:flutter/material.dart';
import 'edit_flashcard_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FlashcardViewPage extends StatefulWidget {
  final String front;
  final String back;
  final String flashcardId;
  final String subjectId;
  final String userId;
  final int level;
  final List<String>? parentPathIds;

  final String? imageFrontUrl;
  final String? imageBackUrl;

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
  bool showFront = true;

  void _flipCard() {
    setState(() {
      showFront = !showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 🌸 Fond
          Positioned.fill(
            child: Image.asset(
              'assets/images/FlashCard View.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),

          // 🔙 Flèche retour
          Positioned(
            top: 55,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 📛 Titre "Flashcard"
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.flashcard,
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

          // 🧠 Contenu principal
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: () {
                    final imageUrl = showFront ? widget.imageFrontUrl : widget.imageBackUrl;
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
              Center(
                child: FloatingActionButton(
                  heroTag: 'edit',
                  onPressed: () {
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
