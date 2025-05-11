// flashcard_list.dart
// Ce fichier contient un widget responsable d'afficher dynamiquement la liste des flashcards
// récupérées depuis Firestore, en utilisant un FutureBuilder puis un StreamBuilder.

import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore pour les données cloud
import 'package:flutter/material.dart'; // Composants Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Localisations pour les textes
import 'package:sapient/services/firestore/flashcards_service.dart'; // Service Firestore centralisé

import 'flashcard_tile.dart'; // 🔹 Widget réutilisable pour une flashcard individuelle

// Activer/désactiver les logs pour le widget de liste
const bool kEnableFlashcardListLogs = false;

/// Fonction de log conditionnelle
void logFlashcardList(String message) {
  if (kEnableFlashcardListLogs) print("[FlashcardList] $message");
}

/// Widget qui affiche la liste complète des flashcards pour un utilisateur/sujet donné
class FlashcardList extends StatelessWidget {
  final String userId; // ID de l'utilisateur
  final String subjectId; // ID du sujet actuel
  final int level; // Niveau hiérarchique (0 = racine)
  final List<String>? parentPathIds; // Liste ordonnée des IDs parents
  final ScrollController scrollController; // Contrôleur du scroll
  final void Function(String id, String front) onDelete; //  Callback suppression
  final void Function(DocumentSnapshot doc) onTap; // Callback affichage détaillé

  const FlashcardList({
    super.key,
    required this.userId, // Utilisateur connecté
    required this.subjectId, // Sujet dont on liste les flashcards
    required this.level, // Profondeur dans la hiérarchie
    required this.parentPathIds, // Chemin hiérarchique complet
    required this.scrollController, // Contrôle du scroll externe
    required this.onDelete, // Suppression au long-press
    required this.onTap, // Détail au clic
  });

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!; // Texte localisé
    final _flashcardsService = FirestoreFlashcardsService(); // Instance du service Firestore

    logFlashcardList("Demande du Stream de flashcards...");
    // Préparation du niveau et du chemin hiérarchique (parentPathIds)
    // On crée une copie du chemin reçu pour pouvoir le corriger si besoin
    final correctedParentPath = [...?parentPathIds];

    // Sécurité : si le dernier élément du chemin est identique à subjectId, c’est une duplication
    if (correctedParentPath.isNotEmpty && correctedParentPath.last == subjectId) {
      correctedParentPath.removeLast(); // On retire le doublon
      logFlashcardList("Duplication détectée → suppression du dernier élément de parentPathIds");
    }

    // Calcul final du niveau hiérarchique à envoyer (longueur du chemin corrigé)
    final correctedLevel = correctedParentPath.length;
    logFlashcardList("Calcul corrigé du niveau : level=$correctedLevel");


    return FutureBuilder<Stream<QuerySnapshot>>( // Attend un Stream en résultat d'un Future
      future: _flashcardsService.getFlashcardsStream( // Utilisation de la bonne méthode getFlashcardsStream
        userId: userId, // Utilisateur courant
        subjectId: subjectId, // Sujet terminal
        level: correctedLevel, // Profondeur dans l'arborescence
        parentPathIds: correctedParentPath, // Chemin d'accès Firestore
      ),

      builder: (context, futureSnapshot) {
        // Pendant le chargement du Future
        if (futureSnapshot.connectionState != ConnectionState.done) {
          logFlashcardList("En attente du Future (getFlashcardsStream)...");
          return const Center(child: CircularProgressIndicator()); // Loading
        }

        // Gestion des erreurs ou absence de données
        if (futureSnapshot.hasError || !futureSnapshot.hasData) {
          logFlashcardList("Erreur ou aucune donnée reçue dans FutureBuilder.");
          return Center(child: Text(local.no_flashcards_found)); // Aucun résultat
        }

        logFlashcardList("Stream prêt, lancement de StreamBuilder...");

        // Le Stream est disponible → écoute des mises à jour Firestore
        return StreamBuilder<QuerySnapshot>(
          stream: futureSnapshot.data!, // Stream reçu
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              logFlashcardList("En attente des données du Stream...");
              return const Center(child: CircularProgressIndicator()); // Attente du flux
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              logFlashcardList("Aucun document flashcard trouvé.");
              return Center(child: Text(local.no_flashcards_found)); // Aucun document
            }

            logFlashcardList("Affichage de ${snapshot.data!.docs.length} flashcard(s).");

            // Liste des flashcards disponibles
            return ListView.separated(
              controller: scrollController, // Contrôle du scroll extérieur
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Marge intérieure
              itemCount: snapshot.data!.docs.length, // Nombre d'éléments
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index]; // Document Firestore
                final data = doc.data() as Map<String, dynamic>; // Extraction des champs

                logFlashcardList("Flashcard ${doc.id} chargée avec front = \"${data['front']}\"");

                return FlashcardTile(
                  docId: doc.id, // ID unique de la flashcard
                  frontText: data['front'] ?? '', // Texte recto (par défaut vide)
                  imageFrontUrl: data['imageFrontUrl'], // Image recto
                  imageBackUrl: data['imageBackUrl'], // Image verso
                  onTap: () => onTap(doc), // Affichage détail
                  onLongPress: () => onDelete(doc.id, data['front'] ?? ''), // Suppression au long press
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12), // Espace entre les éléments
            );
          },
        );
      },
    );
  }
}