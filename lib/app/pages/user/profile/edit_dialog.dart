//  edit_dialog.dart
//  Affiche un dialogue pour éditer un champ spécifique du profil utilisateur (par exemple, nom, objectifs, etc.).

import 'package:flutter/material.dart'; //  UI Flutter
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; //  Localisation

//  Active ou désactive les logs de debug pour le dialogue d'édition
const bool kEnableEditDialogLogs = false;

///  Log conditionnel pour le dialogue d'édition
void logEditDialog(String message) {
  if (kEnableEditDialogLogs) print('[EditDialog] $message');
}

///  Affiche un dialogue pour modifier un champ spécifique du profil (ex: nom, objectifs)
Future<void> showEditDialog({
  required BuildContext context, // ️ Contexte de l’application
  required String currentValue,  //  Valeur actuelle à afficher dans le champ
  required String field,         //  Nom du champ à modifier (ex: 'name', 'objectives')
  required void Function(String newValue) onSave, // Fonction appelée lors de la sauvegarde
}) async {
  logEditDialog(" Ouverture du dialogue d'édition pour le champ : $field");

  // Contrôleur de texte pour le champ
  TextEditingController controller = TextEditingController(text: currentValue);

  // Affichage du dialogue
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('${AppLocalizations.of(context)!.edit} $field'), // Titre du dialogue
        content: TextField(
          controller: controller, // 🖊️ Champ de texte
          decoration: InputDecoration(
            hintText: '${AppLocalizations.of(context)!.enter_new_value}', // Indice pour l'utilisateur
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), //  Bord arrondi
          ),
        ),
        actions: [
          //  Bouton pour annuler l'édition
          ElevatedButton(
            onPressed: () => Navigator.pop(context), //  Fermer sans enregistrer
            child: Text(AppLocalizations.of(context)!.cancelButton), // Texte du bouton
          ),
          //  Bouton pour sauvegarder les changements
          ElevatedButton(
            onPressed: () {
              final newValue = controller.text; // Récupère la nouvelle valeur
              onSave(newValue); // Sauvegarde
              Navigator.pop(context); //  Ferme le dialogue
            },
            child: Text(AppLocalizations.of(context)!.saveButton), // Texte du bouton
          ),
        ],
      );
    },
  );
}
