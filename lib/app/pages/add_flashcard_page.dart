import 'package:flutter/material.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddFlashcardPage extends StatefulWidget {
  final String subjectId;
  final String userId;
  final int level;
  final List<String>? parentPathIds;

  const AddFlashcardPage({
    super.key,
    required this.subjectId,
    required this.userId,
    required this.level,
    required this.parentPathIds,
  });

  @override
  State<AddFlashcardPage> createState() => _AddFlashcardPageState();
}

class _AddFlashcardPageState extends State<AddFlashcardPage> {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.addFlashcard)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 80),
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.question,
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: answerController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.answer,
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final front = questionController.text.trim();
                final back = answerController.text.trim();
                if (front.isNotEmpty && back.isNotEmpty) {
                  await FirestoreService().addFlashcardAtPath(
                    userId: widget.userId,
                    subjectId: widget.subjectId,
                    front: front,
                    back: back,
                    level: widget.level,
                    parentPathIds: widget.parentPathIds,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Text(AppLocalizations.of(context)!.addFlashcard),
            ),
          ],
        ),
      ),
    );
  }
}
