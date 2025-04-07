import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sapient/services/app_state.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    print("Fetching user data for UID: $_uid");
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

  void _updateField(String field, String newValue) async { // Make it async
    print("Updating field: $field with new value: $newValue for UID : $_uid");
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_uid!).set({field: newValue}, SetOptions(merge: true));
        setState(() {
          _userData[field] = newValue; // Update the local data immediately
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildProfilePicture(),
            _buildEditableField(AppLocalizations.of(context)!.name, 'name', _userData['name'] ?? ''),
            ListTile(
              title: Text(AppLocalizations.of(context)!.email),
              subtitle: Text(_userEmail ?? AppLocalizations.of(context)!.emailNotAvailable),
            ),
            _buildEditableField(
                AppLocalizations.of(context)!.learningGoals, 'learningGoals', _userData['learningGoals'] ?? ''),
            // Add other editable fields here
            ListTile(
              title: Text(AppLocalizations.of(context)!.changeLanguage),
              trailing: const Icon(Icons.language),
              onTap: () {
                _showLanguagePickerDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return const CircleAvatar(
      radius: 50,
      child: Icon(Icons.person),
    );
  }

  Widget _buildEditableField(String label, String field, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit),
      onTap: () {
        _showEditDialog(field, value);
      },
    );
  }

  void _showEditDialog(String field, String currentValue) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                _updateField(field, controller.text);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
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
              onPressed: () {
                Navigator.pop(context);
              },
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
}