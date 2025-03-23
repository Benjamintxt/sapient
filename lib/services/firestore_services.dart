import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? getCurrentUserUid() {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      return user?.uid;
    } catch (e) {
      return null;
    }
  }

  // Create a subject
  Future<String> createSubject(String name, {String? parentId}) async {
    String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    DocumentReference newSubjectRef =
    _db.collection('users').doc(userId).collection('subjects').doc();
    String subjectId = newSubjectRef.id;

    String formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

    await newSubjectRef.set({
      'name': name,
      'parentId': parentId,
      'children': [],
      'createdAt': formattedDate,
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
  }

  // Get subjects for the logged-in user
  Stream<QuerySnapshot> getSubjects() {
    String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    return _db
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> deleteSubject(String subjectId) async {
    String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    DocumentReference subjectRef =
    _db.collection('users').doc(userId).collection('subjects').doc(subjectId);
    DocumentSnapshot subjectSnapshot = await subjectRef.get();

    if (!subjectSnapshot.exists) throw Exception("Subject not found.");

    Map<String, dynamic>? subjectData =
    subjectSnapshot.data() as Map<String, dynamic>?;

    if (subjectData != null) {
      List<dynamic> children = subjectData['children'] ?? [];

      for (String childId in children) {
        await deleteSubject(childId);
      }

      String? parentId = subjectData['parentId'];
      if (parentId != null) {
        DocumentReference parentRef =
        _db.collection('users').doc(userId).collection('subjects').doc(parentId);
        await parentRef.update({
          'children': FieldValue.arrayRemove([subjectId])
        });
      }

      await subjectRef.delete();
    }
  }

  // 🔄 Ajout cohérent avec userId passé en paramètre
  Future<void> addFlashcard(String userId, String subjectId, String front, String back) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(subjectId)
        .collection('flashcards')
        .doc()
        .set({
      'front': front,
      'back': back,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 🔄 Récupération des flashcards
  Stream<QuerySnapshot> getFlashcards(String userId, String subjectId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(subjectId)
        .collection('flashcards')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 🔄 Suppression cohérente avec userId
  Future<void> deleteFlashcard(String userId, String subjectId, String flashcardId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(subjectId)
        .collection('flashcards')
        .doc(flashcardId)
        .delete();
  }
}
