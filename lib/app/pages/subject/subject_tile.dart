// lib/app/pages/subject/subject_tile.dart

import 'package:flutter/material.dart'; // 🎨 Widgets visuels de Flutter
import 'package:sapient/app/pages/flashcards/flashcard_page.dart'; // 📘 Page des flashcards
import 'package:sapient/app/pages/subject/subject_page.dart'; // 🗂️ Page de sous-sujets
import 'package:sapient/app/pages/subject/delete_subject_dialog.dart'; // 🧹 Boîte de dialogue de suppression
import 'package:sapient/services/firestore/core.dart'; // 🔐 Récupération de l'utilisateur actuel


// 🪧 Affiche un sujet dans la liste avec actions contextuelles (clic, suppression)
class SubjectTile extends StatelessWidget {
  final String subjectId; // 🆔 ID du sujet
  final String subjectName; // 🏷️ Nom du sujet affiché
  final bool isCategory; // 📁 True si le sujet contient d'autres sous-sujets
  final int level; // 🔢 Niveau hiérarchique (0 = racine)
  final List<String> parentPathIds; // 🧭 Chemin des parents du sujet

  const SubjectTile({
    super.key, // 🔑 Clé widget
    required this.subjectId, // 📌 Paramètre requis : ID sujet
    required this.subjectName, // 📌 Nom du sujet
    required this.isCategory, // 📌 Catégorie ou feuille
    required this.level, // 📌 Niveau dans la hiérarchie
    required this.parentPathIds, // 📌 Liste des IDs parents
  });

  static const bool kEnableSubjectTileLogs = true; // 🟢 Active/désactive les logs de debug
  void logTile(String message) {
    if (kEnableSubjectTileLogs) debugPrint("[SubjectTile] $message");
  }

  @override
  Widget build(BuildContext context) {
    // final userId = FirestoreCore.getCurrentUserUid(); // 🔐 Récupère l'UID utilisateur connecté

    return GestureDetector(
      // 👆 Appui long = affichage du popup de suppression
      onLongPress: () => showDeleteSubjectDialog(
        context: context, // 📍 Contexte Flutter actuel
        subjectId: subjectId, // 🆔 ID du sujet ciblé
        subjectName: subjectName, // 🏷️ Nom affiché
        level: level, // 🔢 Niveau actuel
        parentPathIds: parentPathIds, // 🧭 Chemin complet
      ),

      // 📦 Marge intérieure autour du bloc visuel
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // ↔️↕️ Espace autour du container

        // 🎨 Boîte contenant le sujet stylisé
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(229), // 🎨 Couleur de fond blanc semi-transparent
            borderRadius: BorderRadius.circular(24), // 🟣 Coins arrondis
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25), // 🖤 Ombre douce
                blurRadius: 6, // 💫 Flou
                offset: const Offset(0, 4), // 🧭 Position de l’ombre (vers le bas)
              ),
            ],
          ),

          // 🧾 Composant principal contenant le texte et l'icône
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // ↔️↕️ Marge interne

            title: Text(
              subjectName, // 🏷️ Nom affiché du sujet
              style: const TextStyle(
                fontSize: 18, // 🔠 Taille du texte
                fontWeight: FontWeight.bold, // 💪 Texte en gras
                color: Color(0xFF4A148C), // 🎨 Couleur violette (thème)
              ),
            ),

            trailing: const Icon(Icons.chevron_right, color: Color(0xFF4A148C)), // ➡️ Icône de flèche

              onTap: () {
                // 📥 Lorsqu'on clique sur un sujet dans la liste (tile)
                logTile("📥 Clic sur sujet : $subjectName | isCategory=$isCategory | level=$level");

                // 🧭 Met à jour dynamiquement le chemin en ajoutant ce sujet cliqué
                // Exemple : [id1, id2] + id3 => [id1, id2, id3]
                final updatedPath = [...parentPathIds, subjectId];

                // 🔀 Cas 1 : Si le sujet est une catégorie et qu'on n'a pas atteint la profondeur maximale (5 niveaux)
                if (isCategory && level < 5) {
                  logTile("📂 Ouvre sous-sujets de $subjectName (niveau ${level + 1})");

                  // 🚀 Navigation vers une nouvelle page SubjectPage pour explorer les sous-sujets
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectPage(
                        parentPathIds: updatedPath, // 🧭 Nouveau chemin complet vers ce sous-sujet
                        level: level + 1, // 🔢 On augmente le niveau pour aller plus en profondeur
                        title: subjectName, // 🏷️ Affiche le nom du sujet en haut de la nouvelle page
                      ),
                    ),
                  );
                } else {
                  // 📘 Cas 2 : Si ce n'est pas une catégorie, on ouvre la page de flashcards
                  logTile("📘 Ouvre les flashcards de $subjectName");

                  Navigator.push( // 🧭 Navigation vers une nouvelle page (push dans la pile)
                    context, // 🧭 Contexte actuel de l'application (obligatoire pour naviguer)
                    MaterialPageRoute( // 🛣️ Crée une route de transition vers une nouvelle page avec un effet de glissement
                      builder: (_) => FlashcardPage( // 🧠 Destination : page des flashcards
                        subjectId: subjectId, // 📁 ID du sujet (dernier élément cliqué)
                        userId: FirestoreCore.getCurrentUserUid() ?? '', // 👤 UID de l’utilisateur actuel (récupéré via FirestoreCore)
                        level: level + 1, // 🔼 INCRÉMENTATION : on descend d’un niveau hiérarchique (ex: subsubject2)
                        parentPathIds: updatedPath, // 🧭 Nouveau chemin : liste complète des IDs parents (mis à jour avec le sujet actuel)
                      ),
                    ),
                  );

                }
              }

          ),
        ),
      ),
    );
  }
}