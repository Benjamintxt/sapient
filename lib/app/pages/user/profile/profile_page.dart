import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'profile_editable_card.dart';
import 'profile_static_card.dart';
import 'profile_icon_card.dart';
import 'edit_dialog.dart';
import 'language_picker_dialog.dart';
import 'package:sapient/app/pages/user/statistics/statistics_page.dart';

const bool kEnableProfileLogs = false;

void logProfile(String message) {
  if (kEnableProfileLogs) print("[👤 ProfilePage] $message");
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userEmail;
  String _userName = '';
  String _userObjectives = '';
  bool _isLoading = true;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _fetchUserData();
  }

  Future<void> _fetchUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }

  Future<void> _fetchUserData() async {
    if (_uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? '';
          _userObjectives = data['learningGoals'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateField(String field, String newValue) async {
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .set({field: newValue}, SetOptions(merge: true));

        setState(() {
          if (field == 'name') {
            _userName = newValue;
          } else if (field == 'learningGoals') {
            _userObjectives = newValue;
          }
        });
      } catch (e) {
        print('Error updating $field: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/Screen profil.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withAlpha(38)),
          ),
          Positioned(
            top: 55,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                local.profile,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                  fontFamily: 'Raleway',
                  shadows: [
                    Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1, 2)),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: const Icon(Icons.person, size: 48, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 32),
                    ProfileEditableCard(
                      label: local.profile_name,
                      value: _userName,
                      onEdit: () {
                        showEditDialog(
                          context: context,
                          field: 'name',
                          currentValue: _userName,
                          onSave: (newValue) => _updateField('name', newValue),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ProfileStaticCard(
                      label: local.profile_email,
                      value: _userEmail ?? local.emailNotAvailable,
                    ),
                    const SizedBox(height: 12),
                    ProfileEditableCard(
                      label: local.learning_objectives,
                      value: _userObjectives,
                      onEdit: () {
                        showEditDialog(
                          context: context,
                          field: 'learningGoals',
                          currentValue: _userObjectives,
                          onSave: (newValue) => _updateField('learningGoals', newValue),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ProfileIconCard(
                      label: local.change_language,
                      icon: Icons.language,
                      onTap: () => _showLanguagePickerDialog(context),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: 'stats_btn',
                          backgroundColor: Colors.deepPurple,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StatisticsPage()),
                            );
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.bar_chart, color: Colors.white),
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
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Annuler"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Déconnexion"),
                                  ),
                                ],
                              ),
                            );

                            if (shouldLogout == true) {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pop(context); // Pop the ProfilePage
                              }
                            }
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.logout, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const LanguagePickerDialog(),
    );
  }
}

  void _showLanguagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const LanguagePickerDialog(),
    );
  }
