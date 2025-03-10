import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? getCurrentUserUid() {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;

      // Récupérer l'utilisateur actuellement connecté
      User? user = auth.currentUser;

      if (user != null) {
        // Récupérer l'UID de l'utilisateur
        return user.uid;
      } else {
        // Aucun utilisateur n'est actuellement connecté
        return null;
      }
    } catch (e) {
      // Handle the error as needed
      return null;
    }
  }

  // Create a subject under the authenticated user
  Future<String> createSubject(String name, {String? parentId}) async {
    try {
      String? userId = getCurrentUserUid();
      if (userId == null) {
        throw Exception("User not authenticated.");
      }

      DocumentReference newSubjectRef =
      _db.collection('users').doc(userId).collection('subjects').doc();
      String subjectId = newSubjectRef.id;

      // Get current date and format it
      String formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

      await newSubjectRef.set({
        'name': name,
        'parentId': parentId,
        'children': [],
        'createdAt': formattedDate, // Store formatted date
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (parentId != null) {
        DocumentReference parentRef =
        _db.collection('users').doc(userId).collection('subjects').doc(parentId);
        await parentRef.update({
          'children': FieldValue.arrayUnion([subjectId])
        });
      }

      return subjectId;
    } catch (e) {
      throw Exception("Error creating subject: $e");
    }
  }

  // Get subjects for the logged-in user
  Stream<QuerySnapshot> getSubjects() {
  String? userId = getCurrentUserUid();
  if (userId == null) throw Exception("User not authenticated.");

  return _db.collection('users').doc(userId).collection('subjects').orderBy('createdAt', descending: false).snapshots();
  }



  Future<void> deleteSubject(String subjectId) async {
    try {
      String? userId = getCurrentUserUid();
      if (userId == null) {
        throw Exception("User not authenticated.");
      }

      DocumentReference subjectRef =
      _db.collection('users').doc(userId).collection('subjects').doc(subjectId);
      DocumentSnapshot subjectSnapshot = await subjectRef.get();

      if (!subjectSnapshot.exists) {
        throw Exception("Subject not found.");
      }

      Map<String, dynamic>? subjectData = subjectSnapshot.data() as Map<String, dynamic>?;

      if (subjectData != null) {
        List<dynamic> children = subjectData['children'] ?? [];

        // Recursively delete all children
        for (String childId in children) {
          await deleteSubject(childId);
        }

        // Remove from parent's children list
        String? parentId = subjectData['parentId'];
        if (parentId != null) {
          DocumentReference parentRef =
          _db.collection('users').doc(userId).collection('subjects').doc(parentId);
          await parentRef.update({
            'children': FieldValue.arrayRemove([subjectId])
          });
        }

        // Delete the subject itself
        await subjectRef.delete();
      }
    } catch (e) {
      throw Exception("Error deleting subject: $e");
    }
  }
}