import 'package:flutter/material.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditFlashcardPage extends StatefulWidget {
  final String initialFront;
  final String initialBack;
  final String flashcardId;
  final String subjectId;
  final String userId;
  final int level;
  final List<String>? parentPathIds;

  const EditFlashcardPage({
    super.key,
    required this.initialFront,
    required this.initialBack,
    required this.flashcardId,
    required this.subjectId,
    required this.userId,
    required this.level,
    required this.parentPathIds,
  });

  @override
  State<EditFlashcardPage> createState() => _EditFlashcardPageState();
}

class _EditFlashcardPageState extends State<EditFlashcardPage> {
  late TextEditingController _controller;
  bool isEditingFront = true;
  late String editedFront;
  late String editedBack;

  @override
  void initState() {
    super.initState();
    editedFront = widget.initialFront;
    editedBack = widget.initialBack;
    _controller = TextEditingController(text: editedFront);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchSide(bool front) {
    setState(() {
      if (isEditingFront) {
        editedFront = _controller.text;
      } else {
        editedBack = _controller.text;
      }
      isEditingFront = front;
      _controller.text = front ? editedFront : editedBack;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  Future<void> _saveChanges() async {
    if (isEditingFront) {
      editedFront = _controller.text;
    } else {
      editedBack = _controller.text;
    }

    await FirestoreService().updateFlashcardAtPath(
      userId: widget.userId,
      subjectId: widget.subjectId,
      flashcardId: widget.flashcardId,
      newFront: editedFront,
      newBack: editedBack,
      level: widget.level,
      parentPathIds: widget.parentPathIds,
    await FirestoreService().updateFlashcard(
      widget.userId,
      widget.subjectId,
      widget.flashcardId,
      editedFront,
      editedBack,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7FF),
      appBar: AppBar(
        title: const Text(
          'Éditer la flashcard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        title: Text(AppLocalizations.of(context)!.editFlashcard, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _controller,
              maxLines: null,
              autofocus: true,
              decoration: InputDecoration(
                hintText: isEditingFront ? 'Modifier la question...' : 'Modifier la réponse...',
                hintText: isEditingFront
                    ? AppLocalizations.of(context)!.modifyQuestion : AppLocalizations.of(context)!.modifyAnswer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: 'edit-front',
                  onPressed: () => _switchSide(true),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.help_outline, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'edit-back',
                  onPressed: () => _switchSide(false),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.priority_high, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'save',
                  onPressed: _saveChanges,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
