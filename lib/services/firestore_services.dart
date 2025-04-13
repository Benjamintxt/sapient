import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? getCurrentUserUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    return _db.collection('users').doc(uid).get();
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    return _db.collection('users').doc(uid).update(data);
  }

  /// 🔸 Crée un sujet à un niveau donné dans la bonne sous-collection
  Future<void> createSubject({
    required String name,
    required int level,
    required bool isCategory,
    List<String>? parentPathIds,
  }) async {
    String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    String formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

    CollectionReference collectionRef;

    if (level == 0) {
      collectionRef = _db.collection('users').doc(userId).collection('subjects');
    } else {
      if (parentPathIds == null || parentPathIds.length != level) {
        throw Exception("Invalid parentPathIds for level $level");
      }

      DocumentReference currentRef =
      _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);

      for (int i = 1; i < level; i++) {
        currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
      }

      collectionRef = currentRef.collection('subsubject$level');
    }

    final newDoc = collectionRef.doc();
    await newDoc.set({
      'name': name,
      'isCategory': isCategory,
      'createdAt': formattedDate,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// 🔸 Récupère les sujets au bon niveau et parent
  Stream<QuerySnapshot> getSubjectsAtLevel(int level, List<String>? parentPathIds) {
    String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    CollectionReference ref;

    if (level == 0) {
      ref = _db.collection('users').doc(userId).collection('subjects');
    } else {
      if (parentPathIds == null || parentPathIds.length != level) {
        throw Exception("Invalid parentPathIds for level $level");
      }

      DocumentReference currentRef =
      _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);

      for (int i = 1; i < level; i++) {
        currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
      }

      ref = currentRef.collection('subsubject$level');
    }

    return ref.orderBy('createdAt', descending: false).snapshots();
  }

  /// 🔸 Supprime récursivement un sujet et ses enfants à tous les niveaux
  Future<void> deleteSubject({
    required String subjectId,
    required int level,
    required List<String>? parentPathIds,
  }) async {
    String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    DocumentReference docRef;

    if (level == 0) {
      docRef = _db.collection('users').doc(userId).collection('subjects').doc(subjectId);
    } else {
      if (parentPathIds == null || parentPathIds.length != level) {
        throw Exception("Invalid parentPathIds for level $level");
      }

      DocumentReference currentRef =
      _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);

      for (int i = 1; i < level; i++) {
        currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
      }

      docRef = currentRef.collection('subsubject$level').doc(subjectId);
    }

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return;

    final data = docSnapshot.data() as Map<String, dynamic>;
    final bool isCategory = data['isCategory'] ?? false;

    if (isCategory) {
      for (int nextLevel = level + 1; nextLevel <= 5; nextLevel++) {
        final nextSub = 'subsubject$nextLevel';
        final childrenRef = docRef.collection(nextSub);
        final childrenSnapshot = await childrenRef.get();

        for (var child in childrenSnapshot.docs) {
          await deleteSubject(
            subjectId: child.id,
            level: nextLevel,
            parentPathIds: [...?parentPathIds, subjectId],
          );
        }
      }
    } else {
      final flashcardsRef = docRef.collection('flashcards');
      final flashcards = await flashcardsRef.get();
      for (var card in flashcards.docs) {
        await card.reference.delete();
      }
    }

    await docRef.delete();
  }

  /// 🔸 Ajouter une flashcard avec texte et/ou image
  Future<void> addFlashcardAtPath({
    required String userId,
    required String subjectId,
    required String front,
    required String back,
    required int level,
    required List<String>? parentPathIds,
    String? imageFrontUrl, // ✅ facultatif
    String? imageBackUrl,  // ✅ facultatif (à venir)
  }) async {
    if (parentPathIds == null || parentPathIds.length != level) {
      throw Exception("Invalid parentPathIds for level $level");
    }

    DocumentReference currentRef =
    _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);

    for (int i = 1; i < level; i++) {
      currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
    }

    final docRef = currentRef.collection('subsubject$level').doc(subjectId);

    // On prépare un Map dynamique
    final data = {
      'front': front,
      'back': back,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Ajoute les images si elles sont présentes
    if (imageFrontUrl != null) data['imageFrontUrl'] = imageFrontUrl;
    if (imageBackUrl != null) data['imageBackUrl'] = imageBackUrl;

    await docRef.collection('flashcards').add(data);
  }

  /// 🔸 Lire les flashcards dans l’arborescence hiérarchique
  Stream<QuerySnapshot> getFlashcardsAtPath({
    required String userId,
    required String subjectId,
    required int level,
    required List<String>? parentPathIds,
  }) {
    if (parentPathIds == null || parentPathIds.length != level) {
      throw Exception("Invalid parentPathIds for level $level");
    }

    DocumentReference currentRef =
    _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);

    for (int i = 1; i < level; i++) {
      currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
    }

    final docRef = currentRef.collection('subsubject$level').doc(subjectId);

    return docRef.collection('flashcards').orderBy('timestamp', descending: true).snapshots();
  }


  /// 🔸 Editer une flashcard
  Future<void> updateFlashcardAtPath({
    required String userId,
    required String subjectId,
    required String flashcardId,
    required String newFront,
    required String newBack,
    required int level,
    required List<String>? parentPathIds,
  }) async {
    if (parentPathIds == null || parentPathIds.length != level) {
      throw Exception("Invalid parentPathIds for level $level");
    }

    DocumentReference currentRef =
    _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);

    for (int i = 1; i < level; i++) {
      currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
    }

    final docRef = currentRef.collection('subsubject$level').doc(subjectId);

    await docRef.collection('flashcards').doc(flashcardId).update({
      'front': newFront,
      'back': newBack,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// 🔸 Supprimer une flashcard dans l’arborescence hiérarchique
  Future<void> deleteFlashcardAtPath({
    required String userId,
    required String subjectId,
    required int level,
    required List<String>? parentPathIds,
    required String flashcardId,
  }) async {
    if (parentPathIds == null || parentPathIds.length != level) {
      throw Exception("Invalid parentPathIds for level $level");
    }

    DocumentReference currentRef =
    _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);

    for (int i = 1; i < level; i++) {
      currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
    }

    final docRef = currentRef.collection('subsubject$level').doc(subjectId);

    await docRef.collection('flashcards').doc(flashcardId).delete();
  }

// 🔄 Mise à jour d'une flashcard
  Future<void> updateFlashcard(String userId, String subjectId, String flashcardId, String newFront, String newBack) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(subjectId)
        .collection('flashcards')
        .doc(flashcardId)
        .update({
      'front': newFront,
      'back': newBack,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }


  /// 🔸 Upload une image et retourne son URL
  Future<String> uploadImageAndGetUrl(File image) async {
    final filename = const Uuid().v4(); // nom unique
    final ref = FirebaseStorage.instance.ref().child('flashcards/$filename.jpg');

    final uploadTask = await ref.putFile(image);
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }


}
