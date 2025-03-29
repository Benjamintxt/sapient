import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:sapient/app/pages/flashcards.dart';

class SubjectPage extends StatefulWidget {
  final List<String>? parentPathIds;
  final int level;
  final String? title;

  const SubjectPage({
    super.key,
    this.parentPathIds,
    this.level = 0,
    this.title,
  });

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final ScrollController _scrollController = ScrollController();

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
          widget.title ?? "Sujets",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: widget.level > 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirestoreService().getSubjectsAtLevel(
                      widget.level,
                      widget.parentPathIds,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text("Erreur : ${snapshot.error}"));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Aucun sujet pour le moment."));
                      }

                      var subjects = snapshot.data!.docs;

                      return Scrollbar(
                        controller: _scrollController,
                        thickness: 4,
                        radius: const Radius.circular(10),
                        thumbVisibility: true,
                        interactive: true,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            var subject = subjects[index];
                            String subjectId = subject.id;
                            String subjectName = subject['name'];
                            bool isCategory = subject['isCategory'] ?? false;

                            return GestureDetector(
                              onLongPress: () {
                                _showDeleteDialog(context, subjectId);
                              },
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                title: Text(
                                  subjectName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  final userId = FirestoreService.getCurrentUserUid();
                                  if (userId == null) return;

                                  final updatedPath = [...?widget.parentPathIds, subjectId];

                                  if (isCategory && widget.level < 5) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubjectPage(
                                          parentPathIds: updatedPath,
                                          level: widget.level + 1,
                                          title: subjectName,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FlashcardPage(
                                          subjectId: subjectId,
                                          userId: userId,
                                          level: widget.level,
                                          parentPathIds: widget.parentPathIds,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Divider(height: 1, color: Colors.grey),
          ),
          Positioned(
            bottom: 20,
            right: MediaQuery.of(context).size.width / 2 - 28,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onPressed: () => _showAddSubjectDialog(context),
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    TextEditingController subjectController = TextEditingController();
    bool isCategory = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Ajouter un sujet"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      hintText: "Nom du sujet",
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Catégorie (pas de flashcards)"),
                    value: isCategory,
                    onChanged: (value) {
                      setState(() => isCategory = value ?? false);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String name = subjectController.text.trim();
                    if (name.isNotEmpty) {
                      await FirestoreService().createSubject(
                        name: name,
                        level: widget.level,
                        parentPathIds: widget.parentPathIds,
                        isCategory: isCategory,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Ajouter"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String subjectId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le sujet ?"),
        content: const Text("Souhaitez-vous vraiment supprimer ce sujet et tout ce qu'il contient ?"),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Supprimer"),
            onPressed: () async {
              await FirestoreService().deleteSubject(
                subjectId: subjectId,
                level: widget.level,
                parentPathIds: widget.parentPathIds,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
