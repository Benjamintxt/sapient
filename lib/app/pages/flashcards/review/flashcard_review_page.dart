// 📄 flashcard_review_page.dart
// Page principale de révision des flashcards avec affichage, navigation et notation

import 'package:flutter/material.dart'; // 🎨 UI Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌐 Localisation
import 'package:sapient/services/firestore/flashcards_service.dart'; // 🧠 Service flashcards
import 'package:sapient/services/firestore/revisions_service.dart'; // 📊 Service statistiques
import 'review_flashcard_card.dart'; // 🧾 Widget carte à réviser
import 'review_navigation_buttons.dart'; // 🔁 Boutons navigation (précédent / suivant)
import 'review_answer_buttons.dart'; // ✅❌ Boutons réponse (correct / incorrect)

class FlashcardReviewPage extends StatefulWidget {
  final String subjectId; // 📁 ID du sujet
  final String userId; // 👤 Utilisateur
  final int level; // 🔢 Niveau hiérarchique
  final List<String> parentPathIds; // 🧭 Chemin des parents

  const FlashcardReviewPage({
    super.key, // 🗝️ Clé widget
    required this.subjectId,
    required this.userId,
    required this.level,
    required this.parentPathIds,
  });

  @override
  State<FlashcardReviewPage> createState() => _FlashcardReviewPageState();
}

class _FlashcardReviewPageState extends State<FlashcardReviewPage> {
  DateTime? _startTime; // ⏱️ Temps de début d’affichage d’une carte
  List<Map<String, dynamic>> flashcards = []; // 📦 Liste des cartes à réviser
  int currentIndex = 0; // 🔢 Index de la carte actuelle
  bool showQuestion = true; // 👁️ Affiche le recto (true) ou verso (false)

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  /// 🔄 Charge les flashcards depuis Firestore
  Future<void> _loadFlashcards() async {
    try {
      final snapshot = await FirestoreFlashcardsService().getFlashcardsRaw(
        userId: widget.userId,
        subjectId: widget.subjectId,
        level: widget.level,
        parentPathIds: widget.parentPathIds,
      );

      final docs = snapshot.docs;
      if (docs.isEmpty) return;

      setState(() {
        flashcards = docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print("❌ Erreur de chargement : $e");
    }
    _startTime = DateTime.now();
  }

  /// 🔁 Inverse la face affichée de la carte
  void _flipCard() => setState(() => showQuestion = !showQuestion);

  /// ⏭️ Carte suivante
  void _nextCard() {
    setState(() {
      currentIndex = (currentIndex + 1) % flashcards.length;
      showQuestion = true;
    });
    _startTime = DateTime.now();
  }

  /// ⏮️ Carte précédente
  void _previousCard() {
    setState(() {
      currentIndex = (currentIndex - 1 + flashcards.length) % flashcards.length;
      showQuestion = true;
    });
    _startTime = DateTime.now();
  }

  /// 📊 Enregistre la réponse (correcte ou non) dans les stats
  void _recordAnswer(bool isCorrect) async {
    final flashcard = flashcards[currentIndex];
    final flashcardId = flashcard['id'] ?? 'unknown';
    final now = DateTime.now();
    final durationSeconds = _startTime != null ? now.difference(_startTime!).inSeconds : 0;

    await FirestoreRevisionsService().recordAnswerForDayAndTheme(
      userId: widget.userId,
      flashcardId: flashcardId,
      isCorrect: isCorrect,
      durationSeconds: durationSeconds,
      subjectId: widget.subjectId,
      level: widget.level,
      parentPathIds: widget.parentPathIds,
    );

    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!; // 🌍 Texte localisé

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/FlashCard View.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withAlpha(25)),
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
              ReviewFlashcardCard(
                flashcard: flashcards[currentIndex],
                showQuestion: showQuestion,
                onTap: _flipCard,
              ),
              const SizedBox(height: 32),
              ReviewNavigationButtons(
                onPrevious: _previousCard,
                onNext: _nextCard,
              ),
              const SizedBox(height: 32),
              ReviewAnswerButtons(
                onAnswer: _recordAnswer, // ✅
              ),
            ],
          ),
        ],
      ),
    );
  }
}