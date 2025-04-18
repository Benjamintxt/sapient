// 📄 language_picker_dialog.dart
// 📌 Widget pour afficher un dialogue permettant de choisir la langue de l'application.

import 'package:flutter/material.dart'; // 🎨 UI Flutter
import 'package:sapient/services/app_state.dart'; // 📦 Service d’état de l'application

// 🟢 Active ou désactive les logs de debug pour le dialogue de sélection de langue
const bool kEnableLanguagePickerDialogLogs = true;

/// 🧾 Log conditionnel pour le dialogue de sélection de langue
void logLanguagePickerDialog(String message) {
  if (kEnableLanguagePickerDialogLogs) print('[LanguagePickerDialog] $message');
}

/// 📌 Widget pour afficher un dialogue permettant de choisir la langue
class LanguagePickerDialog extends StatelessWidget {
  const LanguagePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    logLanguagePickerDialog("🎨 Ouverture du dialogue de sélection de langue");

    final appState = AppState.of(context); // 📦 Récupère l'état de l'application pour changer la langue

    return AlertDialog(
      title: Text("Choisir la langue"), // 📛 Titre du dialogue
      content: Column(
        mainAxisSize: MainAxisSize.min, // 📏 Adapte la taille de la colonne
        children: [
          // 🇫🇷 Option pour choisir le français
          _buildLanguageOption(context, 'Français', const Locale('fr'), appState),

          // 🇬🇧 Option pour choisir l'anglais
          _buildLanguageOption(context, 'English', const Locale('en'), appState),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context), // ❌ Ferme le dialogue sans action
          child: Text("Annuler"), // ❌ Bouton d'annulation
        ),
      ],
    );
  }

  /// 📌 Widget pour chaque option de langue
  Widget _buildLanguageOption(BuildContext context, String label, Locale locale, AppState appState) {
    return ListTile(
      title: Text(label), // 🏷️ Nom de la langue
      onTap: () {
        appState.changeLanguage(locale); // 📦 Change la langue de l'application
        Navigator.pop(context); // ✅ Ferme le dialogue après sélection
      },
    );
  }
}
