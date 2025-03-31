import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:sapient/app/pages/flashcards.dart';
import 'package:sapient/app/pages/profile_page.dart';  // Make sure to import the profile page
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        title: Text(
          AppLocalizations.of(context)!.add_subject,
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
                        return Center(child: Text(AppLocalizations.of(context)!.no_subjects));
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

          // Temporary Profile button positioned in the bottom-right corner
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.purple,
              onPressed: () {
                // Navigate to the Profile Page when clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfilePage(),  // Make sure ProfilePage exists
                  ),
                );
              },
              child: const Icon(Icons.person, size: 32, color: Colors.white),
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
          title: Text(AppLocalizations.of(context)!.add_subject),
          content: TextField(
            controller: subjectController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.subject_name_hint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = subjectController.text.trim();
                if (name.isNotEmpty) {
                  await FirestoreService().createSubject(name);
                  Navigator.pop(context);
                }
              },
              child: Text(AppLocalizations.of(context)!.add),
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
        title: Text(AppLocalizations.of(context)!.delete_subject),
        content: Text(AppLocalizations.of(context)!.delete_subject_message(subjectName)),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text(AppLocalizations.of(context)!.delete),
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