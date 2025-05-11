// lib/app/pages/subject/delete_subject_dialog.dart

// Import des packages nécessaires
import 'package:flutter/material.dart'; // UI widgets Flutter
import 'package:sapient/services/firestore/subjects_service.dart'; // Service Firestore pour supprimer un sujet
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Gestion de la traduction des textes

//  Active ou désactive les logs pour cette boîte de dialogue
const bool kEnableDeleteSubjectLogs = false;

//  Fonction utilitaire pour afficher des logs conditionnels
void logDeleteSubject(String message) {
  if (kEnableDeleteSubjectLogs) debugPrint("[DeleteSubjectDialog] $message");
}

///  Affiche une boîte de confirmation de suppression de sujet ou sous-sujet
Future<void> showDeleteSubjectDialog({
  required BuildContext context,         //  Contexte actuel de l'application
  required String subjectId,             //  ID Firestore du sujet à supprimer
  required String subjectName,           // ️ Nom du sujet (affiché dans la pop-up)
  required int level,                    //  Niveau hiérarchique du sujet (0 = racine, etc.)
  required List<String> parentPathIds,   //  Chemin Firestore des parents jusqu'à ce niveau
}) async {
  //  Log initial de demande de suppression
  logDeleteSubject("️Demande suppression : $subjectName (ID=$subjectId)");

  //  Affiche la boîte de dialogue
  await showDialog(
    context: context, //  Contexte nécessaire à l'affichage de la boîte
    builder: (_) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.delete_subject), //  Titre de la boîte (traduit)
      content: Text(AppLocalizations.of(context)!.delete_subject_message(subjectName)), // Message personnalisé
      actions: [
        // Bouton d'annulation
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Ferme la boîte sans rien faire
          child: Text(AppLocalizations.of(context)!.cancel), // Texte "Annuler"
        ),

        // Bouton de confirmation de suppression
        ElevatedButton(
          onPressed: () async {
            // Log de début d'opération
            logDeleteSubject("Suppression en cours de $subjectName...");

            // Appel au service Firestore pour supprimer le sujet et ses sous-éléments
            await FirestoreSubjectsService().deleteSubject(
              subjectId: subjectId,           //  ID du sujet
              level: level,                   // Niveau dans l'arborescence
              parentPathIds: parentPathIds,   // Chemin des parents
            );

            // Log de succès
            logDeleteSubject("Sujet supprimé !");

            // Fermeture de la boîte de dialogue
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple, // Couleur du bouton (violet)
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), //  Bords arrondis
          ),
          child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.white),
          ), // Texte du bouton "Supprimer"
        ),
      ],
    ),
  );
}
