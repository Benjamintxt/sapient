
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sapient/services/firestore_services.dart';

class FlashcardReviewPage extends StatefulWidget {
  final String subjectId;
  final String userId;
  final int level;
  final List<String>? parentPathIds;


  const FlashcardReviewPage({
    super.key,
    required this.subjectId,
    required this.userId,
    required this.level,
    required this.parentPathIds,

  });

  @override
  State<FlashcardReviewPage> createState() => _FlashcardReviewPageState();
}

class _FlashcardReviewPageState extends State<FlashcardReviewPage> {
  DateTime? _startTime;
  List<Map<String, dynamic>> flashcards = [];
  int currentIndex = 0;
  bool showQuestion = true;


  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    try {
      final snapshot = await FirestoreService().getFlashcardsRaw(
        userId: widget.userId,
        subjectId: widget.subjectId,
        level: widget.level,
        parentPathIds: widget.parentPathIds,
      );

      final docs = snapshot.docs;
      if (docs.isEmpty) return;

      setState(() {
        flashcards = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print("Erreur de chargement des flashcards : $e");
    }
    _startTime = DateTime.now();
  }

  void _flipCard() {
    setState(() => showQuestion = !showQuestion);
  }

  void _nextCard() {
    setState(() {
      currentIndex = (currentIndex + 1) % flashcards.length;
      showQuestion = true;
    });
    _startTime = DateTime.now();
  }

  void _previousCard() {
    setState(() {
      currentIndex = (currentIndex - 1 + flashcards.length) % flashcards.length;
      showQuestion = true;
    });
    _startTime = DateTime.now();
  }

  void _recordAnswer(bool isCorrect) async {
    final flashcard = flashcards[currentIndex];
    final flashcardId = flashcard['id'] ?? 'unknown';
    final now = DateTime.now();
    final durationSeconds = _startTime != null ? now.difference(_startTime!).inSeconds : 0;

    await FirestoreService().recordAnswerForDayAndTheme(
      userId: widget.userId,
      flashcardId: flashcardId,
      isCorrect: isCorrect,
      durationSeconds: durationSeconds,
      subjectId: widget.subjectId,
      level: widget.level,
      parentPathIds: widget.parentPathIds!,
    );


    _nextCard();
  }



  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/FlashCard View.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),
          Positioned(
            top: 55,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                local.review,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                  fontFamily: 'Raleway',
                  shadows: [Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1, 2))],
                ),
              ),
            ),
          ),
          flashcards.isEmpty
              ? Center(child: Text(local.no_flashcards_found))
              : Column(
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
                    final card = flashcards[currentIndex];
                    final imageUrl = showQuestion ? card['imageFrontUrl'] : card['imageBackUrl'];
                    final text = showQuestion ? card['front'] : card['back'];
                    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
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
                      return Text(
                        text ?? '',
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      );
                    }
                  }(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: _previousCard),
                  const SizedBox(width: 24),
                  IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: _nextCard),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'fail_button',
                    onPressed: () => _recordAnswer(false),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 40),
                  FloatingActionButton(
                    heroTag: 'success_button',
                    onPressed: () => _recordAnswer(true),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
