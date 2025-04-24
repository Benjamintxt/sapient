import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  // Displays a generic or custom error dialog.
  static void handleError(
      BuildContext context,
      dynamic error, {
        String? userMessage,
        String title = "Erreur",
      }) {
    debugPrint("Error: $error");

    String message;

    // Handle Firebase-specific error codes
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          message = "L'email n'est pas valide.";
          break;
        case 'user-disabled':
          message = "Ce compte a été désactivé.";
          break;
        case 'user-not-found':
          message = "Aucun utilisateur trouvé pour cet email.";
          break;
        case 'wrong-password':
          message = "Mot de passe incorrect.";
          break;
        case 'email-already-in-use':
          message = "L'adresse email est déjà utilisée par un autre compte.";
          break;
        case 'weak-password':
          message = "Le mot de passe est trop faible.";
          break;
        default:
          message = error.message ?? "Une erreur est survenue.";
          break;
      }
    } else {
      message = userMessage ?? "Une erreur est survenue. Veuillez réessayer.";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Executes an async action safely, handling any thrown error with a dialog.
  static Future<void> safeCall(
      BuildContext context,
      Future<void> Function() action, {
        String? errorMessage,
      }) async {
    try {
      await action();
    } catch (e) {
      handleError(context, e, userMessage: errorMessage);
    }
  }
}