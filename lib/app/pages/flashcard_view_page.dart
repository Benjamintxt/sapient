import 'package:flutter/material.dart';
import 'edit_flashcard_page.dart';

class FlashcardViewPage extends StatefulWidget {
  final String front;
  final String back;
  final String flashcardId;
  final String subjectId;
  final String userId;

  const FlashcardViewPage({
    super.key,
    required this.front,
    required this.back,
    required this.flashcardId,
    required this.subjectId,
    required this.userId,
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
      backgroundColor: const Color(0xFFFCF7FF),
      appBar: AppBar(
        title: const Text(
          'Flashcard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
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
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 200,
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
              child: Text(
                showFront ? widget.front : widget.back,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
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
                    builder: (context) => EditFlashcardPage(
                      initialFront: widget.front,
                      initialBack: widget.back,
                      flashcardId: widget.flashcardId,
                      subjectId: widget.subjectId,
                      userId: widget.userId,
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
    );
  }
}
