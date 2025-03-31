import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  List<Map<String, dynamic>> flashcards = [];
  int currentIndex = 0;
  bool showQuestion = true;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    DocumentReference currentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('subjects')
        .doc(widget.parentPathIds![0]);

    for (int i = 1; i < widget.level; i++) {
      currentRef = currentRef
          .collection('subsubject$i')
          .doc(widget.parentPathIds![i]);
    }

    final docRef =
    currentRef.collection('subsubject${widget.level}').doc(widget.subjectId);

    final snapshot = await docRef
        .collection('flashcards')
        .orderBy('timestamp', descending: false)
        .get();

    setState(() {
      flashcards = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  void _flipCard() {
    setState(() => showQuestion = !showQuestion);
  }

  void _nextCard() {
    setState(() {
      currentIndex = (currentIndex + 1) % flashcards.length;
      showQuestion = true;
    });
  }

  void _previousCard() {
    setState(() {
      currentIndex = (currentIndex - 1 + flashcards.length) % flashcards.length;
      showQuestion = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.review, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: Center(child: Text(AppLocalizations.of(context)!.noFlashcards)),
      );
    }

    final card = flashcards[currentIndex];
    final String front = card['front'] ?? '';
    final String back = card['back'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.review, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _flipCard,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              height: 200,
              alignment: Alignment.center,
              child: Text(
                showQuestion ? front : back,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _previousCard,
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _nextCard,
              ),
            ],
          )
        ],
      ),
    );
  }
}
