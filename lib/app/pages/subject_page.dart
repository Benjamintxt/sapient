
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:sapient/app/pages/flashcards.dart';
import 'package:sapient/app/pages/profile_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      extendBodyBehindAppBar: true,

      body: Stack(
        children: [
          // 🌸 Fond pastel
          Positioned.fill(
            child: Image.asset(
              'assets/images/Vue principale.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.05),
            ),
          ),

          // ✅ Ajoute ici le titre personnalisé :
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                widget.title ?? AppLocalizations.of(context)!.add_subject,
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

          // 💡 Liste des sujets
          Padding(
            padding: const EdgeInsets.only(bottom: 90, top: 80),
            child: Column(
              children: [
                const SizedBox(height: 32), // espace ajouté avant la liste
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
                        return Center(child: Text("Erreur : \${snapshot.error}"));
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
                            bool isCategory = subject['isCategory'] ?? false;

                            return GestureDetector(
                              onLongPress: () => _showDeleteDialog(context, subjectId, subjectName),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    title: Text(
                                      subjectName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A148C),
                                      ),
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF4A148C)),
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
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 🌸 Boutons en bas
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "add_subject_button",
                  backgroundColor: Colors.deepPurple,
                  onPressed: () => _showAddSubjectDialog(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.add, size: 30, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: "profile_button",
                  backgroundColor: Colors.deepPurple,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: "logout_button",
                  backgroundColor: Colors.deepPurple,
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Se déconnecter ?"),
                        content: const Text("Es-tu sûr(e) de vouloir te déconnecter ?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Déconnexion")),
                        ],
                      ),
                    );
                    if (shouldLogout == true) await FirebaseAuth.instance.signOut();
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFFFF8F0), // Couleur crème pastel
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🌸 Titre
                Text(
                  AppLocalizations.of(context)!.add_subject,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C), // Violet foncé
                    fontFamily: 'Raleway',
                  ),
                ),
                const SizedBox(height: 20),

                // 📝 Champ texte
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.subject_name_hint,
                    filled: true,
                    fillColor: Colors.white,
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 📦 Checkbox
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context)!.is_category,
                    style: const TextStyle(color: Color(0xFF4A148C)),
                  ),
                  value: isCategory,
                  activeColor: Colors.deepPurple,
                  onChanged: (value) => setState(() => isCategory = value ?? false),
                ),
                const SizedBox(height: 16),

                // 🎯 Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
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
                      child: Text(
                        AppLocalizations.of(context)!.add,
                        style: const TextStyle(color: Colors.white), // ← 👈 ICI
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showDeleteDialog(BuildContext context, String subjectId, String subjectName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete_subject),
        content: Text(AppLocalizations.of(context)!.delete_subject_message(subjectName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService().deleteSubject(
                subjectId: subjectId,
                level: widget.level,
                parentPathIds: widget.parentPathIds,
              );
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}
