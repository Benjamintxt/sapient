// lib/app/pages/subject/subject_page.dart

import 'package:flutter/material.dart'; // 🎨 Widgets Flutter
import 'package:sapient/services/firestore/core.dart'; // 🔐 Récupération UID
import 'package:sapient/app/pages/subject/subject_list.dart'; // 📄 Liste des sujets affichée
import 'package:sapient/app/pages/subject/add_subject_dialog.dart'; // ➕ Popup d'ajout de sujet
import 'package:sapient/app/pages/user/profile/profile_page.dart'; // 👤 Page de profil
// import 'package:sapient/app/pages/statistics_page.dart'; // 📊 Page des statistiques
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌍 Localisation
import 'package:firebase_auth/firebase_auth.dart'; // 🔐 Authentification Firebase

import 'package:sapient/app/pages/gamification/gamification_page.dart'; // 🌟 Page gamification


// 📚 Page principale d’un niveau de sujets/sous-sujets
class SubjectPage extends StatelessWidget {
  final int level; // 🔢 Niveau dans la hiérarchie (0 = racine)
  final List<String>? parentPathIds; // 🧭 Chemin complet jusqu’à ce niveau
  final String? title; // 🏷️ Titre à afficher (nom du sujet parent)

  const SubjectPage({
    super.key, // 🔑 Clé widget
    this.level = 0, // ⚙️ Niveau par défaut = racine
    this.parentPathIds, // 🧭 Liste des parents (peut être null pour racine)
    this.title, // 🏷️ Titre facultatif (affiché en haut)
  });

  static const bool kEnableSubjectPageLogs = false; // 🔊 Active/désactive les logs
  void logPage(String message) {
    if (kEnableSubjectPageLogs) debugPrint("[SubjectPage] $message");
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirestoreCore.getCurrentUserUid(); // 🔐 Vérifie l’utilisateur connecté

    if (userId == null) {
      // ❌ Si pas connecté, on affiche un message simple
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true, // 📱 Permet un fond étendu derrière la barre supérieure
      body: Stack(
        children: [
          _buildBackground(), // 🖼️ Arrière-plan pastel

          if (level > 0) _buildBackButton(context), // 🔙 Flèche retour si pas racine
          _buildTitle(context), // 🏷️ Titre centré

          // 📋 Liste des sujets affichée entre 80 et 90 pixels
          Positioned.fill(
            top: 80,
            bottom: 90,
            child: SubjectList(
              level: level, // 🔢 Niveau courant
              parentPathIds: parentPathIds ?? [], // 🧭 Chemin courant ou vide
            ),
          ),

          _buildBottomButtons(context), // ⚙️ Boutons flottants en bas
        ],
      ),
    );
  }

  // 🖼️ Arrière-plan floral pastel + couche blanche semi-transparente
  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/Vue principale.png', // 🖼️ Image de fond
            fit: BoxFit.cover, // 📐 Couvre l’écran
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withAlpha(38), // 🌫️ Légère superposition blanche
          ),
        ),
      ],
    );
  }

  // 🔙 Flèche de retour en haut à gauche
  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 55, // ↕️ Position verticale
      left: 16, // ↔️ Position horizontale
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28), // 🔙 Icône violette
        onPressed: () => Navigator.pop(context), // 🔚 Retour à la page précédente
      ),
    );
  }

  // 🏷️ Titre centré en haut de l'écran
  Widget _buildTitle(BuildContext context) {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          title ?? AppLocalizations.of(context)!.add_subject, // 🌍 Nom fourni ou "Ajouter un sujet"
          style: const TextStyle(
            fontSize: 32, // 🔠 Taille grande
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C), // 🎨 Violette
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
    );
  }

  // ⚙️ Boutons d'action : ajouter, profil, stats
  Widget _buildBottomButtons(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 🔁 Espace équitable
        children: [
          // ➕ Ajouter un sujet
          FloatingActionButton(
            heroTag: "add_subject_button",
            backgroundColor: Colors.deepPurple,
            onPressed: () => showAddSubjectDialog(
              context: context,
              level: level,
              parentPathIds: parentPathIds ?? [],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),

          // 👤 Accès au profil
          FloatingActionButton(
            heroTag: "profile_button",
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.person, color: Colors.white),
          ),

          // 🌟 Accès à la page de gamification (bonsaï)
          FloatingActionButton(
            heroTag: "gamification_button",
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GamificationPage()),
              );
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.emoji_events, color: Colors.white),
          ),
        ],
      ),
    );
  }
} 