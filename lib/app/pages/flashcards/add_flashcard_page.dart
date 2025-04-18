// 📄 add_flashcard_page.dart
// ➕ Page d'ajout manuel de flashcard avec le thème floral/pastel de FlashcardPage

import 'package:flutter/material.dart'; // 🎨 Widgets UI Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌍 Localisation
import 'package:sapient/services/firestore/flashcards_service.dart'; // 🔥 Service Firestore pour les flashcards

const bool kEnableAddFlashcardLogs = true; // 🟢 Active ou désactive les logs pour cette page

/// 🔍 Fonction utilitaire pour afficher des logs si activés
void logAddFlashcard(String msg) {
  if (kEnableAddFlashcardLogs) debugPrint('[AddFlashcardPage] $msg');
}

/// 🧱 Widget principal représentant la page d'ajout de flashcard
class AddFlashcardPage extends StatefulWidget {
  final String subjectId; // 🆔 ID du sujet courant
  final String userId; // 👤 ID de l'utilisateur
  final int level; // 🔢 Niveau de profondeur du sujet
  final List<String> parentPathIds; // 🧭 Chemin vers les sujets parents

  const AddFlashcardPage({
    super.key, // 🔑 Clé unique Flutter
    required this.subjectId, // 📁 ID du sujet
    required this.userId, // 👤 Utilisateur
    required this.level, // 📊 Niveau dans la hiérarchie
    required this.parentPathIds, // 🧭 Chemin vers les parents
  });

  @override
  State<AddFlashcardPage> createState() => _AddFlashcardPageState(); // 🔄 Crée l'état associé
}

/// 💡 État dynamique de la page d'ajout
class _AddFlashcardPageState extends State<AddFlashcardPage> {
  final _formKey = GlobalKey<FormState>(); // 🧾 Clé unique du formulaire pour valider
  final _frontController = TextEditingController(); // ✍️ Contrôleur pour le recto
  final _backController = TextEditingController(); // ✍️ Contrôleur pour le verso
  final _service = FirestoreFlashcardsService(); // 🔥 Service Firestore pour ajouter la flashcard

  @override
  void dispose() {
    _frontController.dispose(); // 🧹 Libère le contrôleur recto
    _backController.dispose(); // 🧹 Libère le contrôleur verso
    super.dispose(); // 🔚 Termine proprement
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!; // 🌍 Récupère les traductions

    return Scaffold(
      extendBodyBehindAppBar: true, // 🪟 Étend le contenu derrière la AppBar
      backgroundColor: Colors.transparent, // 🎨 Fond transparent (image visible)
      body: Stack(
        children: [
          // 🌸 Image de fond
          Positioned.fill(
            child: Image.asset(
              'assets/images/FlashCard View.png', // 🖼️ Image pastel/floral
              fit: BoxFit.cover, // 🧱 Ajustement à l'écran
            ),
          ),

          // 🌫️ Couche blanche semi-transparente pour lisibilité
          Positioned.fill(
            child: Container(color: Colors.white.withAlpha(25)),
          ),

          // 🔙 Bouton retour (flèche)
          Positioned(
            top: 55, // ↕️ Distance du haut
            left: 16, // ↔️ Distance de la gauche
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28), // 🔙 Icône violette
              onPressed: () => Navigator.pop(context), // 🔚 Retour à la page précédente
            ),
          ),

          // 🏷️ Titre "Ajouter une flashcard"
          Positioned(
            top: 50, // ↕️ Position du titre
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                local.addFlashcard, // 🌍 Texte localisé "Ajouter une flashcard"
                style: const TextStyle(
                  fontSize: 28, // 🔠 Taille du texte
                  fontWeight: FontWeight.bold, // 💪 Texte en gras
                  color: Color(0xFF4A148C), // 🎨 Couleur violette
                  fontFamily: 'Raleway', // ✍️ Police personnalisée
                  shadows: [
                    Shadow(
                      blurRadius: 3, // 🌫️ Flou doux
                      color: Colors.black26, // 🌑 Ombre noire translucide
                      offset: Offset(1, 2), // ↘️ Décalage ombre
                    )
                  ],
                ),
              ),
            ),
          ),

          // 🧾 Formulaire de saisie centré
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80), // 🧱 Espacement
              child: Form(
                key: _formKey, // 🔐 Clé du formulaire pour validation
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ↕️ Adapte à la taille minimale
                  children: [
                    // ✍️ Champ de texte pour le recto
                    TextFormField(
                      controller: _frontController, // 🔗 Connecté au champ recto
                      decoration: InputDecoration(
                        labelText: local.front, // 🏷️ Libellé "Recto"
                        filled: true, // ✅ Fond coloré
                        fillColor: Colors.white.withAlpha(229), // 🎨 Fond blanc translucide
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), // 🎯 Bords arrondis
                        ),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? local.error_generic : null, // ❌ Vérifie champ vide
                    ),
                    const SizedBox(height: 16), // ↕️ Espace vertical

                    // ✍️ Champ de texte pour le verso
                    TextFormField(
                      controller: _backController, // 🔗 Connecté au champ verso
                      decoration: InputDecoration(
                        labelText: local.back, // 🏷️ Libellé "Verso"
                        filled: true, // ✅ Fond coloré
                        fillColor: Colors.white.withAlpha(229), // 🎨 Fond blanc translucide
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), // 🎯 Bords arrondis
                        ),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? local.error_generic : null, // ❌ Vérifie champ vide
                    ),
                    const SizedBox(height: 24), // ↕️ Espace avant bouton

                    // ✅ Bouton "Sauvegarder"
                    ElevatedButton(
                      onPressed: _submit, // 🧠 Lance la fonction d'ajout
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C), // 🎨 Couleur violette
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 🔲 Bords arrondis
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), // 🧱 Padding interne
                      ),
                      child: Text(
                        local.save, // 🌍 Texte "Sauvegarder"
                        style: const TextStyle(fontSize: 16, color: Colors.white), // 🔠 Style blanc
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Fonction appelée lors du clic sur "Sauvegarder"
  void _submit() async {
    if (!_formKey.currentState!.validate()) return; // ❌ Ne continue pas si invalide

    final front = _frontController.text.trim(); // 🔤 Texte recto sans espace
    final back = _backController.text.trim(); // 🔤 Texte verso sans espace

    await _service.addFlashcard(
      userId: widget.userId, // 👤 Utilisateur
      subjectId: widget.subjectId, // 📁 Sujet concerné
      level: widget.level, // 🔢 Niveau hiérarchique
      parentPathIds: widget.parentPathIds, // 🧭 Chemin complet
      front: front, // 📝 Texte recto
      back: back, // 📝 Texte verso
    );

    logAddFlashcard("✅ Flashcard ajoutée avec succès"); // 📋 Log de succès
    Navigator.pop(context); // 🔙 Retour à la page précédente
  }
}