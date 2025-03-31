import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppState extends ChangeNotifier {
  Locale _locale = Locale('fr'); // Default locale

  Locale get locale => _locale;

  void changeLanguage(Locale locale) {
    _locale = locale;
    notifyListeners(); // Notify listeners to rebuild the app with the new locale
  }

  // Use this to get the AppState through Provider or other state management solutions
  static AppState of(BuildContext context) {
    return context.read<AppState>();
  }
}