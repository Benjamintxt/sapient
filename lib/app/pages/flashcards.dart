import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'add_flashcard_page.dart';
import 'flashcard_review_page.dart';
import 'flashcard_view_page.dart';
import 'camera_page.dart';

class FlashcardPage extends StatefulWidget {
  final String subjectId;
  final String userId;
  final int level;
  final List<String>? parentPathIds;

  const FlashcardPage({
    super.key,
    required this.subjectId,
    required this.userId,
    required this.level,
    required this.parentPathIds,
  });

  @override
  _FlashcardPageState createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7FF),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.flashcards,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getFlashcardsAtPath(
                userId: widget.userId,
                subjectId: widget.subjectId,
                level: widget.level,
                parentPathIds: widget.parentPathIds,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.no_flashcards_found));
                }

                return Scrollbar(
                  controller: _scrollController,
                  thickness: 4,
                  radius: const Radius.circular(10),
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      return GestureDetector(
                        onLongPress: () {
                          _showDeleteDialog(context, doc.id, data['front']);
                        },
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FlashcardViewPage(
                                  front: data['front'],
                                  back: data['back'],
                                  flashcardId: doc.id,
                                  subjectId: widget.subjectId,
                                  userId: widget.userId,
                                  level: widget.level,
                                  parentPathIds: widget.parentPathIds,
                                  imageFrontUrl: data['imageFrontUrl'],  // 👈 ajouté
                                  imageBackUrl: data['imageBackUrl'],    // 👈 (pour plus tard)
                                ),
                              ),
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            data['front'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFlashcardPage(
                          subjectId: widget.subjectId,
                          userId: widget.userId,
                          level: widget.level,
                          parentPathIds: widget.parentPathIds,
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, size: 32, color: Colors.white),
                ),


                // 📷 Bouton caméra ajouté ici
                FloatingActionButton(
                  heroTag: 'camera',
                  onPressed: () async {
                    await showImageChoiceDialog(
                      context: context,
                      onConfirm: (String flashcardName, String side) async {
                        final firstImage = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraPage()),
                        );

                        if (firstImage != null) {
                          final firestore = FirestoreService();
                          final firstUrl = await firestore.uploadImageAndGetUrl(firstImage);

                          // 👉 Demande à l'utilisateur s’il veut ajouter aussi l’autre côté
                          final wantSecondSide = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.addSecondSide ?? "Ajouter aussi l'autre côté ?"),
                              content: Text(side == 'front'
                                  ? "Tu veux aussi prendre le verso ?"
                                  : "Tu veux aussi prendre le recto ?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(AppLocalizations.of(context)!.no ?? "Non"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(AppLocalizations.of(context)!.yes ?? "Oui"),
                                ),
                              ],
                            ),
                          );

                          String? secondUrl;
                          if (wantSecondSide == true) {
                            final secondImage = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CameraPage()),
                            );
                            if (secondImage != null) {
                              secondUrl = await firestore.uploadImageAndGetUrl(secondImage);
                            }
                          }

                          // 💾 Enregistrement final de la flashcard complète
                          await firestore.addFlashcardAtPath(
                            userId: widget.userId,
                            subjectId: widget.subjectId,
                            front: side == 'front' ? flashcardName : '',
                            back: side == 'back' ? flashcardName : '',
                            imageFrontUrl: side == 'front' ? firstUrl : secondUrl,
                            imageBackUrl: side == 'back' ? firstUrl : secondUrl,
                            level: widget.level,
                            parentPathIds: widget.parentPathIds,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.flashcardAdded)),
                          );
                        }
                      },




                    );
                  },
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt, size: 28, color: Colors.white),
                ),

                FloatingActionButton(
                  heroTag: 'review',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlashcardReviewPage(
                          subjectId: widget.subjectId,
                          userId: widget.userId,
                          level: widget.level,
                          parentPathIds: widget.parentPathIds,
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.lightbulb, size: 32, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String flashcardId, String frontText) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete_flashcard),
        content: Text(
            AppLocalizations.of(context)!.delete_flashcard_message(frontText)
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text(AppLocalizations.of(context)!.delete),
            onPressed: () async {
              await _firestoreService.deleteFlashcardAtPath(
                userId: widget.userId,
                subjectId: widget.subjectId,
                level: widget.level,
                parentPathIds: widget.parentPathIds,
                flashcardId: flashcardId,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> showImageChoiceDialog({
    required BuildContext context,
    required Function(String name, String side) onConfirm,
  }) async {
    final TextEditingController _nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)!.chooseImageSide,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.flashcardNameHint ?? 'Nom de la flashcard',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'toFront',
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm(_nameController.text, "front");
                  },
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'toBack',
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm(_nameController.text, "back");
                  },
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.arrow_downward, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'cancelChoice',
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.grey.shade700,
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
