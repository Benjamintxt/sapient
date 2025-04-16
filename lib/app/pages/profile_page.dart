import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sapient/services/app_state.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapient/app/pages/statistics_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirestoreService.getCurrentUserUid();
  late Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserEmail();
  }

  Future<void> _fetchUserData() async {
    if (_uid != null) {
      final snapshot = await _firestoreService.getUserData(_uid!);
      if (snapshot.exists) {
        setState(() {
          _userData = snapshot.data()!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateField(String field, String newValue) async {
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid!)
            .set({field: newValue}, SetOptions(merge: true));
        setState(() {
          _userData[field] = newValue;
        });
      } catch (e) {
        print("Error updating/creating document: $e");
      }
    }
  }

  Future<void> _fetchUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Screen profil.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Icon(Icons.person, size: 48, color: Colors.deepPurple),
                ),
                const SizedBox(height: 32),
                _buildEditableCard(
                  AppLocalizations.of(context)!.profile_name,
                  _userData['name'] ?? '',
                      () => _showEditDialog('name', _userData['name'] ?? ''),
                ),
                const SizedBox(height: 12),
                _buildStaticCard(
                  AppLocalizations.of(context)!.profile_email,
                  _userEmail ?? '',
                ),
                const SizedBox(height: 12),
                _buildEditableCard(
                  AppLocalizations.of(context)!.learning_objectives,
                  _userData['objectives'] ?? '',
                      () => _showEditDialog('objectives', _userData['objectives'] ?? ''),
                ),
                const SizedBox(height: 12),
                _buildIconCard(
                  AppLocalizations.of(context)!.change_language,
                  Icons.language,
                      () => _showLanguagePickerDialog(context),
                ),


              ],
            ),
          ),

          // 🌟 Nouveau bouton flottant progression
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width / 2 - 28, // centré
            child: FloatingActionButton(
              heroTag: "progress_button",
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
          ),

        ],
      ),



    );
  }

  Widget _buildEditableCard(String label, String value, VoidCallback onEdit) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.deepPurple),
              onPressed: onEdit,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStaticCard(String label, String value) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildIconCard(String label, IconData icon, VoidCallback onTap) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        trailing: Icon(icon, color: Colors.deepPurple),
        onTap: onTap,
      ),
    );
  }



  void _showEditDialog(String field, String currentValue) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
        context: context,
        builder: (BuildContext context) {
      return AlertDialog(
          title: Text('${AppLocalizations.of(context)!.edit} $field'),
          content: TextField(controller: controller),
          actions: [
          ElevatedButton(
          onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ],
      );
        },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, Locale locale, AppState appState) {
    return ListTile(
      title: Text(label),
      onTap: () {
        appState.changeLanguage(locale);
        Navigator.pop(context);
      },
    );
  }
  void _showLanguagePickerDialog(BuildContext context) {
    final appState = AppState.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, 'Français', const Locale('fr'), appState),
              _buildLanguageOption(context, 'English', const Locale('en'), appState),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancelButton),
            ),
          ],
        );
      },
    );
  }


}