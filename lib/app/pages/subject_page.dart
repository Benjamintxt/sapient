import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:sapient/app/pages/flashcards.dart';

class SubjectPage extends StatefulWidget {
  const SubjectPage({super.key});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final ScrollController _scrollController = ScrollController();
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7FF),
      appBar: AppBar(
        title: const Text(
          "Sujets",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 90), // Espace pour le bouton en bas
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirestoreService().getSubjects(),
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

                            return GestureDetector(
                              onLongPress: () {
                                _showDeleteDialog(context, subjectId, subjectName);
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
                                  if (userId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FlashcardPage(subjectId: subjectId, userId: userId),
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

          // 🔹 Le trait gris au-dessus du bouton
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Divider(height: 1, color: Colors.grey),
          ),


          // Bouton flottant positionné en bas
          Positioned(
            bottom: 20,
            right: MediaQuery.of(context).size.width / 2 - 28, // Centré
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter un sujet"),
          content: TextField(
            controller: subjectController,
            decoration: const InputDecoration(
              hintText: "Nom du sujet",
            ),
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
                  await FirestoreService().createSubject(name);
                  Navigator.pop(context);
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String subjectId, String subjectName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le sujet ?"),
        content: Text("Souhaitez-vous vraiment supprimer \"$subjectName\" ?"),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Supprimer"),
            onPressed: () async {
              await FirestoreService().deleteSubject(subjectId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
