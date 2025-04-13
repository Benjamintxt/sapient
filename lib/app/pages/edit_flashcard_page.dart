import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'camera_page.dart';

class EditFlashcardPage extends StatefulWidget {
  final String initialFront;
  final String initialBack;
  final String flashcardId;
  final String subjectId;
  final String userId;
  final int level;
  final List<String>? parentPathIds;
  final String? imageFrontUrl;
  final String? imageBackUrl;

  const EditFlashcardPage({
    super.key,
    required this.initialFront,
    required this.initialBack,
    required this.flashcardId,
    required this.subjectId,
    required this.userId,
    required this.level,
    required this.parentPathIds,
    this.imageFrontUrl,
    this.imageBackUrl,
  });

  @override
  State<EditFlashcardPage> createState() => _EditFlashcardPageState();
}

class _EditFlashcardPageState extends State<EditFlashcardPage> {
  late TextEditingController _controller;
  bool isEditingFront = true;
  late String editedFront;
  late String editedBack;
  String? editedImageFront;
  String? editedImageBack;
  bool showFront = true;

  bool get isImageFlashcard => widget.imageFrontUrl != null || widget.imageBackUrl != null;

  @override
  void initState() {
    super.initState();
    editedFront = widget.initialFront;
    editedBack = widget.initialBack;
    editedImageFront = widget.imageFrontUrl;
    editedImageBack = widget.imageBackUrl;
    _controller = TextEditingController(text: editedFront);
  }

  void _switchSide(bool toFront) {
    setState(() {
      if (isImageFlashcard) {
        showFront = toFront;
      } else {
        if (isEditingFront) editedFront = _controller.text;
        else editedBack = _controller.text;
        isEditingFront = toFront;
        _controller.text = isEditingFront ? editedFront : editedBack;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });
  }

  Future<void> _captureImageForSide(bool forFront) async {
    final image = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraPage()),
    );
    if (image != null) {
      final url = await FirestoreService().uploadImageAndGetUrl(
        image,
        widget.userId,
        widget.subjectId,
        widget.parentPathIds,
      );
      setState(() {
        if (forFront) {
          editedImageFront = url;
          showFront = true;
        } else {
          editedImageBack = url;
          showFront = false;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus(); // ✅ Ferme le clavier
    if (!isImageFlashcard) {
      if (isEditingFront) editedFront = _controller.text;
      else editedBack = _controller.text;
    } else {
      editedFront = _controller.text;
    }

    try {
      await FirestoreService().updateFlashcardAtPath(
        userId: widget.userId,
        subjectId: widget.subjectId,
        flashcardId: widget.flashcardId,
        newFront: editedFront,
        newBack: editedBack,
        level: widget.level,
        parentPathIds: widget.parentPathIds,
      );

      final docRef = FirestoreService().buildFlashcardDocRef(
        userId: widget.userId,
        subjectId: widget.subjectId,
        level: widget.level,
        parentPathIds: widget.parentPathIds!,
      );

      await docRef.collection('flashcards').doc(widget.flashcardId).update({
        if (editedImageFront != null) 'imageFrontUrl': editedImageFront,
        if (editedImageBack != null) 'imageBackUrl': editedImageBack,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la sauvegarde : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = showFront ? editedImageFront : editedImageBack;
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7FF),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editFlashcard,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _controller,
                maxLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isImageFlashcard
                      ? "Nom de la flashcard"
                      : (isEditingFront
                      ? AppLocalizations.of(context)!.modifyQuestion
                      : AppLocalizations.of(context)!.modifyAnswer),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            if (isImageFlashcard)
              GestureDetector(
                onTap: () => setState(() => showFront = !showFront),
                child: Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: currentImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(currentImage, fit: BoxFit.cover, width: double.infinity),
                  )
                      : const Center(child: Text("Image à insérer")),
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
                    onPressed: isImageFlashcard ? () => _captureImageForSide(true) : () => _switchSide(true),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.help_outline, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: 'edit-back',
                    onPressed: isImageFlashcard ? () => _captureImageForSide(false) : () => _switchSide(false),
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
      ),
    );
  }
}
