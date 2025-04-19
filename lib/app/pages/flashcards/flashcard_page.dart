// 📄 flashcard_page.dart
// 🧠 Page principale des flashcards : affiche la liste, les boutons d'action, et gère les interactions

import 'package:flutter/material.dart'; // 🎨 UI Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌐 Traductions localisées



import 'add_flashcard_page.dart'; // ➕ Page d'ajout manuel
import 'review/flashcard_review_page.dart'; // 💡 Mode révision
import 'flashcard_view_page.dart'; // 👁️ Vue individuelle

// 🌟 Widgets modulaires
import 'package:sapient/app/pages/flashcards/widget/flashcard_list.dart'; // 📋 Liste des flashcards
import 'package:sapient/app/pages/flashcards/widget/bottom_action_buttons.dart'; // ⬇️ Boutons (ajout, caméra, révision)
import 'package:sapient/app/pages/flashcards/widget/camera_add_flashcard_dialog.dart'; // 📷 Dialogue pour capture caméra

// 🧠 Services Firestore
import 'package:sapient/services/firestore/flashcards_service.dart'; // 🃏 Service dédié à la gestion des flashcards (CRUD, Firestore)

const bool kEnableFlashcardPageLogs = false; // 🟢 Active les logs de debug
void logFlashcardPage(String msg) {
  if (kEnableFlashcardPageLogs) debugPrint("[FlashcardPage] $msg");
}

// 📚 Page d'affichage des flashcards pour un sujet donné
class FlashcardPage extends StatefulWidget {
  final String subjectId; // 📁 ID du sujet actuel
  final String userId; // 👤 ID utilisateur
  final int level; // 🔢 Niveau de hiérarchie
  final List<String> parentPathIds; // 🧭 Chemin des parents

  const FlashcardPage({
    super.key, // 🔑 Clé widget Flutter
    required this.subjectId, // 📁 ID du sujet
    required this.userId, // 👤 ID utilisateur
    required this.level, // 🔢 Niveau hiérarchique
    required this.parentPathIds, // 🧭 Liste des parents
  });

  @override
  State<FlashcardPage> createState() => _FlashcardPageState(); // 🧠 Crée l'état associé
}

class _FlashcardPageState extends State<FlashcardPage> {
  final ScrollController _scrollController = ScrollController(); // 📜 Gère le défilement
  final FirestoreFlashcardsService _flashcardsService = FirestoreFlashcardsService(); // 🃏 Service flashcards

  @override
  void dispose() {
    _scrollController.dispose(); // 🧹 Libère le scrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!; // 🌍 Accès à la localisation

    return Scaffold(
      extendBodyBehindAppBar: true, // 🪟 Fond sous la AppBar
      backgroundColor: Colors.transparent, // ✨ Transparence du fond

      body: Stack(
        children: [
          // 🌸 Image de fond
          Positioned.fill(
            child: Image.asset(
              'assets/images/FlashCard View.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🌫️ Voile blanc pour lisibilité
          Positioned.fill(
            child: Container(color: Colors.white.withAlpha(38)),
          ),

          // 🔙 Bouton retour
          Positioned(
            top: 55,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28),
              onPressed: () {
                logFlashcardPage("🔙 Retour en arrière");
                Navigator.pop(context);
              },
            ),
          ),

          // 🏷️ Titre "Flashcards"
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                local.flashcards,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                  fontFamily: 'Raleway',
                  shadows: [
                    Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1, 2)),
                  ],
                ),
              ),
            ),
          ),

          // 📋 Liste + boutons en bas
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 50), // ↕️ Réserve l’espace du haut

              // 🧾 Liste des flashcards existantes
              Expanded(
                child: FlashcardList(
                  userId: widget.userId,
                  subjectId: widget.subjectId,
                  level: widget.level,
                  parentPathIds: widget.parentPathIds,
                  scrollController: _scrollController,
                  onDelete: _showDeleteDialog,
                  onTap: (doc) {
                    final data = doc.data() as Map<String, dynamic>; // 📄 Données JSON
                    logFlashcardPage("👆 Flashcard cliquée : ${doc.id}");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlashcardViewPage(
                          front: data['front'],
                          back: data['back'],
                          flashcardId: doc.id,
                          subjectId: widget.subjectId,
                          userId: widget.userId,
                          level: widget.level,
                          parentPathIds: widget.parentPathIds,
                          imageFrontUrl: data['imageFrontUrl'],
                          imageBackUrl: data['imageBackUrl'],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 🔘 Boutons Ajouter / Caméra / Révision
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: BottomActionButtons(
                  onAdd: _openAddFlashcardPage,
                  onCamera: _openCameraDialog,
                  onReview: _openReviewPage,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ➕ Ajout manuel d'une flashcard
  void _openAddFlashcardPage() {
    logFlashcardPage("📄 Accès page ajout flashcard");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFlashcardPage(
          subjectId: widget.subjectId,
          userId: widget.userId,
          level: widget.level,
          parentPathIds: widget.parentPathIds,
        ),
      ),
    );
  }

  // 🔁 Accès à la révision
  void _openReviewPage() {
    logFlashcardPage("🔁 Accès page de révision");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardReviewPage(
          subjectId: widget.subjectId,
          userId: widget.userId,
          level: widget.level,
          parentPathIds: widget.parentPathIds,
        ),
      ),
    );
  }

  // 🗑️ Supprimer une flashcard après confirmation
  void _showDeleteDialog(String flashcardId, String frontText) {
    logFlashcardPage("🗑️ Demande suppression : $flashcardId");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete_flashcard),
        content: Text(AppLocalizations.of(context)!.delete_flashcard_message(frontText)),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text(AppLocalizations.of(context)!.delete),
            onPressed: () async {
              await _flashcardsService.deleteFlashcard(
                userId: widget.userId,
                subjectId: widget.subjectId,
                level: widget.level,
                parentPathIds: widget.parentPathIds,
                flashcardId: flashcardId,
              );
              logFlashcardPage("✅ Supprimée : $flashcardId");
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // 📷 Ajout via caméra
  void _openCameraDialog() {
    logFlashcardPage("📷 Ajout via caméra");
    showCameraAddFlashcardDialog(
      context: context,
      userId: widget.userId,
      subjectId: widget.subjectId,
      level: widget.level,
      parentPathIds: widget.parentPathIds,
    );
  }
}
