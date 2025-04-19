// lib/app/pages/subject/add_subject_dialog.dart

import 'package:flutter/material.dart'; // 🎨 Widgets Flutter
import 'package:sapient/services/firestore/core.dart'; // 🔐 UID utilisateur
import 'package:sapient/services/firestore/subjects_service.dart'; // 📚 Service Firestore pour sujets
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌐 Localisation

const bool kEnableAddSubjectLogs = false; // 🟢 Active/désactive les logs
void logAddSubject(String message) {
  if (kEnableAddSubjectLogs) debugPrint("[AddSubjectDialog] $message");
}

/// 📦 Ouvre un dialogue modal pour ajouter un nouveau sujet ou une catégorie
Future<void> showAddSubjectDialog({
  required BuildContext context, // 🧭 Contexte actuel (nécessaire pour navigation/UI)
  required int level, // 🔢 Niveau dans la hiérarchie (0 = racine)
  required List<String>? parentPathIds, // 🧭 Liste des IDs des parents (si level > 0)
}) async {
  final TextEditingController controller = TextEditingController(); // ⌨️ Contrôleur du champ texte
  bool isCategory = false; // ✅ Coché = catégorie, décoché = feuille simple

  // 🧱 Affiche la boîte de dialogue
  await showDialog(
    context: context, // 📍 Contexte
    builder: (context) => StatefulBuilder( // 🔄 Permet de mettre à jour l'état interne (ex: checkbox)
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // 🟣 Coins arrondis
        backgroundColor: const Color(0xFFFFF8F0), // 🌸 Fond crème pastel
        child: Padding(
          padding: const EdgeInsets.all(24), // 🧱 Marge intérieure
          child: Column(
            mainAxisSize: MainAxisSize.min, // 📏 Adapte la taille verticale au contenu
            children: [
              // 🏷️ Titre du dialogue
              Text(
                AppLocalizations.of(context)!.add_subject, // 🌐 Texte localisé : "Ajouter un sujet"
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 20), // ↕️ Espace

              // 📝 Champ de saisie du nom du sujet
              TextField(
                controller: controller, // 📌 Contrôleur pour lire le texte saisi
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.subject_name_hint, // 🌐 Indice : "Nom du sujet"
                  filled: true, // 🎨 Fond blanc
                  fillColor: Colors.white,
                  hintStyle: const TextStyle(color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none, // ❌ Pas de bord visible
                  ),
                ),
              ),
              const SizedBox(height: 16), // ↕️ Espace

              // ✅ Checkbox : est-ce une catégorie ?
              CheckboxListTile(
                contentPadding: EdgeInsets.zero, // ❌ Pas de marge
                title: Text(
                  AppLocalizations.of(context)!.is_category,
                  style: const TextStyle(color: Color(0xFF4A148C)),
                ),
                value: isCategory, // ☑️ État de la case
                activeColor: Colors.deepPurple, // 🎨 Couleur lorsqu'activée
                onChanged: (value) => setState(() => isCategory = value ?? false), // 🔁 Met à jour l'état interne
              ),
              const SizedBox(height: 16), // ↕️ Espace

              // 🔘 Boutons en bas du dialogue
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // 🔚 Aligné à droite
                children: [
                  // ❌ Bouton Annuler
                  TextButton(
                    onPressed: () => Navigator.pop(context), // 🔙 Ferme la boîte
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                  const SizedBox(width: 8), // ↔️ Espace entre les boutons

                  // ✅ Bouton Ajouter
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple, // 🎨 Couleur de fond
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // 🟣 Coins arrondis
                      ),
                    ),
                    onPressed: () async {
                      final name = controller.text.trim(); // ✂️ Supprime les espaces
                      if (name.isEmpty) return; // ⚠️ Si champ vide, on annule

                      final userId = FirestoreCore.getCurrentUserUid(); // 🔐 Vérifie l'authentification
                      if (userId == null) return; // ❌ Ne rien faire si non connecté

                      logAddSubject("🆕 Création sujet : name=$name | level=$level | isCategory=$isCategory");

                      // 🔥 Création Firestore via service
                      await FirestoreSubjectsService().createSubject(
                        name: name, // 🏷️ Nom du sujet
                        level: level, // 🔢 Niveau hiérarchique
                        parentPathIds: parentPathIds, // 🧭 Chemin parent
                        isCategory: isCategory, // 📁 Type
                      );

                      logAddSubject("✅ Sujet ajouté : $name");
                      Navigator.pop(context); // 🔚 Ferme le dialogue après ajout
                    },
                    child: Text(
                      AppLocalizations.of(context)!.add,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}