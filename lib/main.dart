import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sapient/firebase_options.dart';
import 'package:sapient/app/pages/auth_checker_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
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
      home: const AuthGate(), // Use AuthGate as the initial screen
    );
  }
}
