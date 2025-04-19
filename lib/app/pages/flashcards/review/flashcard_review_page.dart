// 📄 flashcard_review_page.dart
// Page principale de révision des flashcards avec affichage, navigation et notation

import 'package:flutter/material.dart'; // 🎨 UI Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌐 Localisation
import 'package:sapient/services/firestore/flashcards_service.dart'; // 🧠 Service flashcards
import 'package:sapient/services/firestore/revisions_service.dart'; // 📊 Service statistiques
import 'review_flashcard_card.dart'; // 🧾 Widget carte à réviser
import 'review_navigation_buttons.dart'; // 🔁 Boutons navigation (précédent / suivant)
import 'review_answer_buttons.dart'; // ✅❌ Boutons réponse (correct / incorrect)

// 🔧 Activation ou désactivation des logs
const bool kEnableFlashcardReviewLogs = false;

// 🖨️ Fonction utilitaire pour afficher les logs si activé
void logReview(String message) {
  if (kEnableFlashcardReviewLogs) print('[📄 FlashcardReviewPage] $message');
}

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
    logReview('🚀 initState() → Chargement des flashcards...');
    _loadFlashcards();
  }

  /// 🔄 Charge les flashcards depuis Firestore
  Future<void> _loadFlashcards() async {
    final _flashcardsService = FirestoreFlashcardsService(); // 🧠 Instance du service des flashcards

    final correctedPath = [...widget.parentPathIds]; // 🧱 Copie du chemin original
    if (correctedPath.isNotEmpty && correctedPath.last == widget.subjectId) {
      correctedPath.removeLast(); // ❌ Suppression de la duplication
      logReview("⚠️ Duplication détectée → suppression du dernier élément de parentPathIds");
    }

    final level = correctedPath.length; // 📏 Recalcul du niveau hiérarchique
    logReview("📏 Calcul corrigé du niveau : level=$level");

    try {
      final snapshot = await _flashcardsService.getFlashcardsRaw(
        userId: widget.userId,
        subjectId: widget.subjectId,
        level: level,
        parentPathIds: correctedPath,
      );

      final docs = snapshot.docs;
      logReview("📥 ${docs.length} flashcard(s) récupérée(s)");

      if (docs.isEmpty) {
        logReview("🚫 Aucune flashcard trouvée");
        return;
      }

      setState(() {
        flashcards = docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // 🆔 Ajout de l'ID à chaque carte
          return data;
        }).toList();
        logReview("✅ flashcards chargées et stockées dans l'état");
      });
    } catch (e) {
      logReview("❌ Erreur de chargement des flashcards : $e");
    }

    _startTime = DateTime.now(); // 🕒 Mémorise le moment où l'utilisateur commence
  }

  /// 🔁 Inverse la face affichée de la carte
  void _flipCard() {
    setState(() => showQuestion = !showQuestion);
    logReview("🔄 Carte retournée → showQuestion=$showQuestion");
  }

  /// ⏭️ Carte suivante
  void _nextCard() {
    if (flashcards.isEmpty) return; // 🛑 Sécurité si vide
    setState(() {
      currentIndex = (currentIndex + 1) % flashcards.length; // ➕ Index suivant
      showQuestion = true; // 👁️ Toujours afficher la question au début
    });
    _startTime = DateTime.now(); // ⏱️ Repart à zéro
    logReview("⏭️ Passage à la carte suivante (index=$currentIndex)");
  }

  /// ⏮️ Carte précédente
  void _previousCard() {
    if (flashcards.isEmpty) return; // 🛑 Sécurité si vide
    setState(() {
      currentIndex = (currentIndex - 1 + flashcards.length) % flashcards.length; // 🔁 Retour circulaire
      showQuestion = true;
    });
    _startTime = DateTime.now();
    logReview("⏮️ Retour à la carte précédente (index=$currentIndex)");
  }

  /// 📊 Enregistre une réponse de l’utilisateur (correcte ou incorrecte)
  void _recordAnswer(bool isCorrect) async {
    // 🧠 Récupère la flashcard actuellement affichée
    final flashcard = flashcards[currentIndex];

    // 🆔 Récupère l’ID de la flashcard (ou 'unknown' si non trouvé)
    final flashcardId = flashcard['id'] ?? 'unknown';

    // ⏱️ Récupère l’heure actuelle (fin de la consultation de la carte)
    final now = DateTime.now();

    // 🕒 Calcule la durée d’affichage de la carte en secondes (si _startTime est défini)
    final durationSeconds = _startTime != null
        ? now.difference(_startTime!).inSeconds
        : 0;

    // 🖨️ Log de l’action utilisateur
    logReview("📄 [FlashcardReviewPage] 📊 Enregistrement réponse → ID=$flashcardId | Correct=$isCorrect | Durée=$durationSeconds s");

    // 🔧 Correction du chemin Firestore : supprime subjectId si dupliqué dans parentPathIds
    final correctedPath = [...widget.parentPathIds]; // 🧱 Copie défensive du chemin original
    if (correctedPath.isNotEmpty && correctedPath.last == widget.subjectId) {
      correctedPath.removeLast();
      logReview("! [recordAnswer] Correction parentPathIds → suppression du dernier ID car il était dupliqué avec subjectId");
    }

    // 💾 Appelle le service Firestore pour enregistrer la réponse
    await FirestoreRevisionsService().recordAnswerForDayAndTheme(
      userId: widget.userId,              // 👤 ID utilisateur
      flashcardId: flashcardId,           // 🆔 ID flashcard
      isCorrect: isCorrect,               // ✅ Réponse correcte ?
      durationSeconds: durationSeconds,   // ⏱️ Temps de consultation
      subjectId: widget.subjectId,        // 📁 ID du sujet (feuille)
      level: correctedPath.length,        // 🔢 Niveau calculé dynamiquement
      parentPathIds: correctedPath,       // 🧭 Chemin hiérarchique corrigé
    );

    // ⏭️ Passe à la carte suivante
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
// 🌸 Image de fond de la page de révision (remplit toute la zone visible)
          Positioned.fill(
            // 🖼️ Affiche une image couvrant tout l'écran (fond pastel de flashcards)
            child: Image.asset(
              'assets/images/FlashCard View.png', // 📂 Chemin de l'image dans les assets
              fit: BoxFit.cover, // 🔳 L’image s’adapte pour couvrir toute la zone sans déformation
            ),
          ),

// 🌫️ Voile blanc semi-transparent par-dessus l’image pour améliorer la lisibilité du texte
          Positioned.fill(
            // 🧊 Conteneur blanc semi-transparent qui s’étend sur tout l’écran
            child: Container(
              color: Colors.white.withAlpha(25), // 🎨 Blanc avec une transparence faible (alpha = 25/255)
            ),
          ),

// 🔙 Bouton de retour positionné en haut à gauche de l'écran
          Positioned(
            top: 55, // ↕️ Distance du haut de l'écran (position verticale)
            left: 16, // ↔️ Distance du bord gauche de l'écran
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back, // ⬅️ Icône représentant une flèche de retour
                color: Color(0xFF4A148C), // 🎨 Couleur violette (match avec le thème pastel)
                size: 28, // 📏 Taille de l’icône en pixels
              ),
              onPressed: () {
                // 🖨️ Log déclenché si les logs sont activés
                logReview("🔙 Retour arrière (Navigator.pop)");

                // 🔁 Action : revenir à la page précédente
                Navigator.pop(context);
              },
            ),
          ),

// 🏷️ Titre centré en haut de la page : "Révision"
          Positioned(
            top: 50, // ↕️ Position verticale légèrement au-dessus du bouton
            left: 0, // ↔️ Collé au bord gauche
            right: 0, // ↔️ Collé au bord droit → largeur = toute la page
            child: Center(
              // 🎯 Centre le texte horizontalement
              child: Text(
                local.review, // 🌍 Texte localisé pour le mot "Révision"
                style: const TextStyle(
                  fontSize: 32, // 🔠 Grande taille pour un titre visible
                  fontWeight: FontWeight.bold, // 🅱️ Met le texte en gras
                  color: Color(0xFF4A148C), // 🎨 Couleur violette (cohérente avec le design)
                  fontFamily: 'Raleway', // ✏️ Police personnalisée pour un style élégant
                  shadows: [
                    Shadow(
                      blurRadius: 3, // 🌫️ Flou de l’ombre
                      color: Colors.black26, // 🎨 Ombre noire semi-transparente
                      offset: Offset(1, 2), // ↘️ Décalage de l’ombre vers la droite et le bas
                    ),
                  ],
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
