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

      final docRef = FirestoreService().getSubSubjectDocRef(
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
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 🌸 Fond
          Positioned.fill(
            child: Image.asset(
              'assets/images/FlashCard View.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),

          // 📛 Titre
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.editFlashcard,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                  fontFamily: 'Raleway',
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black26,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✏️ Contenu scrollable avec padding clavier
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 140,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isImageFlashcard)
                    GestureDetector(
                      onTap: () => setState(() => showFront = !showFront),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: currentImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            currentImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : const Center(child: Text("Image manquante")),
                      ),
                    ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.help_outline, () {
                        isImageFlashcard
                            ? _captureImageForSide(true)
                            : _switchSide(true);
                      }),
                      _buildActionButton(Icons.priority_high, () {
                        isImageFlashcard
                            ? _captureImageForSide(false)
                            : _switchSide(false);
                      }),
                      _buildActionButton(Icons.check, _saveChanges),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      heroTag: icon.codePoint.toString(),
      onPressed: onPressed,
      backgroundColor: Colors.deepPurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: Colors.white),
    );
  }


}
