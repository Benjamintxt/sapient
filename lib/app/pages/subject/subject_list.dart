// 📄 subject_list.dart
// 📌 Widget qui affiche une liste de sujets (catégories ou feuilles) à partir de Firestore
// Ce widget utilise FutureBuilder + StreamBuilder pour écouter les changements dans la base de données hiérarchique Firestore.

import 'package:flutter/material.dart'; // 🎨 UI Flutter
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Firestore pour la gestion des données
import 'package:sapient/app/pages/subject/subject_tile.dart'; // 🔹 Widget qui affiche chaque sujet
import 'package:sapient/services/firestore/subjects_service.dart'; // 📚 Service Firestore pour récupérer les sujets

// 🟢 Active ou désactive les logs pour la liste des sujets
const bool kEnableSubjectListLogs = false;

// 🧾 Log conditionnel pour la liste des sujets
void logSubjectList(String message) {
  if (kEnableSubjectListLogs) {
    print('[SubjectList] $message'); // Affiche le message si les logs sont activés
  }
}

/// 🧾 Widget qui affiche une liste de sujets (catégories ou feuilles) à partir de Firestore
/// Utilise un FutureBuilder pour attendre l’accès à la bonne collection, puis un StreamBuilder pour écouter les sujets en temps réel.
class SubjectList extends StatelessWidget {
  final int level; // 🔢 Niveau dans la hiérarchie (0 = racine)
  final List<String> parentPathIds; // 🧭 Liste des ID des parents pour définir le chemin

  // Constructeur pour initialiser les paramètres : niveau et chemin des parents
  const SubjectList({
    super.key, // 🔑 Clé pour le widget
    required this.level, // 🔢 Le niveau dans l'arborescence des sujets
    required this.parentPathIds, // 🧭 Le chemin complet des parents
  });

  // Fonction build pour créer l'interface utilisateur du widget
  @override
  Widget build(BuildContext context) {
    // 🔍 Log pour savoir qu'on appelle la méthode build de SubjectList
    logSubjectList('🧭 Construction de la liste des sujets pour le niveau $level avec chemin ${parentPathIds.toString()}');

    // ⏳ FutureBuilder → on attend d’abord que le service Firestore retourne un Stream valide
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: FirestoreSubjectsService().getSubjectsAtLevel(level, parentPathIds), // 🔮 Récupère un Future<Stream> selon le niveau
      builder: (context, futureSnapshot) {
        // ⏱️ Si la future tâche n'est pas encore terminée (chargement)
        if (futureSnapshot.connectionState != ConnectionState.done) {
          logSubjectList('🔄 En attente de récupération du flux Firestore...');
          return const Center(child: CircularProgressIndicator());
        }

        // ❌ Si le Future échoue
        if (futureSnapshot.hasError) {
          logSubjectList('❌ Erreur Future : ${futureSnapshot.error}');
          return Center(child: Text('Erreur : ${futureSnapshot.error}'));
        }

        // ✅ Future résolu → on peut écouter le Stream Firestore
        final stream = futureSnapshot.data!;

        // 📡 StreamBuilder → écoute les documents dans la collection récupérée
        return StreamBuilder<QuerySnapshot>(
          stream: stream, // 🔁 Flux Firestore de la bonne collection
          builder: (context, snapshot) {
            // 🕐 Si le stream est en attente de données (chargement)
            if (snapshot.connectionState == ConnectionState.waiting) {
              logSubjectList('🔄 Chargement des sujets (stream)...');
              return const Center(child: CircularProgressIndicator()); // Afficher un loader pendant le chargement
            }

            // ⚠️ Si une erreur est survenue lors de la récupération des données
            if (snapshot.hasError) {
              logSubjectList('⚠️ Erreur lors du chargement des sujets : ${snapshot.error}');
              return Center(child: Text('Erreur : ${snapshot.error}')); // Afficher l'erreur
            }

            // ❌ Si aucune donnée n'a été récupérée (liste vide)
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              logSubjectList('📭 Aucun sujet trouvé.');
              return const Center(child: Text("Aucun sujet")); // Afficher un message si aucun sujet n'est trouvé
            }

            // ✅ Si des sujets ont été récupérés, on les affiche
            final subjects = snapshot.data!.docs; // Récupérer la liste des sujets
            logSubjectList('✅ ${subjects.length} sujet(s) trouvé(s)');

            // Retourner la liste des sujets dans un ListView
            return ListView.separated(
              padding: const EdgeInsets.all(16), // 🎨 Ajouter un padding autour de la liste
              itemCount: subjects.length, // Nombre d'éléments dans la liste
              separatorBuilder: (_, __) => const SizedBox(height: 8), // 🎨 Espacement entre chaque sujet
              itemBuilder: (context, index) {
                // 🧾 Extraire chaque sujet depuis la liste des documents Firestore
                final doc = subjects[index];
                final subjectName = doc['name']; // 🏷️ Récupérer le nom du sujet
                final isCategory = doc['isCategory'] ?? false; // 🧭 Vérifier si le sujet est une catégorie (par défaut false)

                // 🧭 Afficher le sujet dans un SubjectTile
                return SubjectTile(
                  subjectId: doc.id, // 🆔 ID du sujet
                  subjectName: subjectName, // 📛 Nom du sujet
                  isCategory: isCategory, // 🧭 Type de sujet (catégorie ou feuille)
                  level: level, // 🔢 Niveau du sujet
                  parentPathIds: parentPathIds, // 🧭 Chemin des sujets parents
                );
              },
            );
          },
        );
      },
    );
  }
}
