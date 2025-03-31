import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sapient/services/app_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.changeLanguage),
              trailing: Icon(Icons.language),
              onTap: () {
                _showLanguagePickerDialog(context);
              },
            ),
            // Add other profile options here, such as name, email, etc.
          ],
        ),
      ),
    );
  }

  // Language Picker Dialog
  void _showLanguagePickerDialog(BuildContext context) {
    final appState = AppState.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, 'Français', const Locale('fr'), appState),
              _buildLanguageOption(context, 'English', const Locale('en'), appState),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without changing language
              },
              child: Text(AppLocalizations.of(context)!.cancelButton),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, Locale locale, AppState appState) {
    return ListTile(
      title: Text(label),
      onTap: () {
        appState.changeLanguage(locale); // Change the language through the appState
        Navigator.pop(context); // Close the dialog after changing language
      },
    );
  }
}