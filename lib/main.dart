import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sapient/firebase_options.dart';
import 'package:sapient/app/pages/auth_checker_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),  // Provide AppState using ChangeNotifierProvider
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sapient',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      supportedLocales: L10n.all,  // Define the supported locales (English, French)
      localizationsDelegates: [
        // Default Flutter localization delegates
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,

        // Your custom localization delegate
        AppLocalizations.delegate,
      ],
      locale: context.watch<AppState>().locale,  // Watch the locale from AppState to update the language
      home: const AuthGate(),  // Use AuthGate as the initial screen
    );
  }
}