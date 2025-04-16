import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔐 Utils - Authentification
  static String? getCurrentUserUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  /// 🔹 Récupère les données de l'utilisateur
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    return _db.collection('users').doc(uid).get();
  }

  /// 🔹 Met à jour les données de l'utilisateur
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    return _db.collection('users').doc(uid).update(data);
  }

  // 📁 Navigation hiérarchique

  /// 🔹 Génère le DocumentReference d’un sujet à n’importe quel niveau
  DocumentReference getSubSubjectDocRef({
    required String userId,
    required int level,
    required List<String> parentPathIds,
    required String subjectId,
  }) {
    if (parentPathIds.length != level) {
      throw Exception("Invalid parentPathIds for level $level");
    }

    DocumentReference currentRef = _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);

    for (int i = 1; i < level; i++) {
      currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
    }

    return currentRef.collection('subsubject$level').doc(subjectId);
  }

  // 📚 Sujets

  /// 🔹 Crée un sujet (matière ou catégorie)
  Future<void> createSubject({
    required String name,
    required int level,
    required bool isCategory,
    List<String>? parentPathIds,
  }) async {
    final String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    String formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

    CollectionReference collectionRef;

    if (level == 0) {
      collectionRef = _db.collection('users').doc(userId).collection('subjects');
    } else {
      if (parentPathIds == null || parentPathIds.length != level) {
        throw Exception("Invalid parentPathIds for level $level");
      }

      DocumentReference currentRef = _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);
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

  /// 🔹 Récupère les sujets à un niveau donné
  Stream<QuerySnapshot> getSubjectsAtLevel(int level, List<String>? parentPathIds) {
    final String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    CollectionReference ref;

    if (level == 0) {
      ref = _db.collection('users').doc(userId).collection('subjects');
    } else {
      if (parentPathIds == null || parentPathIds.length != level) {
        throw Exception("Invalid parentPathIds for level $level");
      }

      DocumentReference currentRef = _db.collection('users').doc(userId).collection('subjects').doc(parentPathIds[0]);
      for (int i = 1; i < level; i++) {
        currentRef = currentRef.collection('subsubject$i').doc(parentPathIds[i]);
      }

      ref = currentRef.collection('subsubject$level');
    }

    return ref.orderBy('createdAt', descending: false).snapshots();
  }

  /// 🔹 Supprime récursivement un sujet et ses enfants
  Future<void> deleteSubject({
    required String subjectId,
    required int level,
    required List<String>? parentPathIds,
  }) async {
    final String? userId = getCurrentUserUid();
    if (userId == null) throw Exception("User not authenticated.");

    final docRef = getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds!,
      subjectId: subjectId,
    );

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

  // 🧠 Flashcards

  /// 🔹 Récupère les flashcards (Future)
  Future<QuerySnapshot<Map<String, dynamic>>> getFlashcardsRaw({
    required String userId,
    required String subjectId,
    required int level,
    required List<String>? parentPathIds,
  }) async {
    final docRef = getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds!,
      subjectId: subjectId,
    );

    return await docRef.collection('flashcards').orderBy('timestamp').get();
  }

  /// 🔹 Récupère les flashcards (Stream)
  Stream<QuerySnapshot> getFlashcardsAtPath({
    required String userId,
    required String subjectId,
    required int level,
    required List<String>? parentPathIds,
  }) {
    final docRef = getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds!,
      subjectId: subjectId,
    );

    return docRef.collection('flashcards').orderBy('timestamp', descending: true).snapshots();
  }

  /// 🔹 Ajoute une flashcard
  Future<void> addFlashcardAtPath({
    required String userId,
    required String subjectId,
    required String front,
    required String back,
    required int level,
    required List<String>? parentPathIds,
    String? imageFrontUrl,
    String? imageBackUrl,
  }) async {
    final docRef = getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds!,
      subjectId: subjectId,
    );

    final data = {
      'front': front,
      'back': back,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (imageFrontUrl != null) data['imageFrontUrl'] = imageFrontUrl;
    if (imageBackUrl != null) data['imageBackUrl'] = imageBackUrl;

    await docRef.collection('flashcards').add(data);
  }

  /// 🔹 Met à jour une flashcard
  Future<void> updateFlashcardAtPath({
    required String userId,
    required String subjectId,
    required String flashcardId,
    required String newFront,
    required String newBack,
    required int level,
    required List<String>? parentPathIds,
  }) async {
    final docRef = getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds!,
      subjectId: subjectId,
    );

    await docRef.collection('flashcards').doc(flashcardId).update({
      'front': newFront,
      'back': newBack,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Supprime une flashcard et ses images
  Future<void> deleteFlashcardAtPath({
    required String userId,
    required String subjectId,
    required int level,
    required List<String>? parentPathIds,
    required String flashcardId,
  }) async {
    final docRef = getSubSubjectDocRef(
      userId: userId,
      level: level,
      parentPathIds: parentPathIds!,
      subjectId: subjectId,
    );

    final flashcardRef = docRef.collection('flashcards').doc(flashcardId);
    final snapshot = await flashcardRef.get();
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data != null) {
      final imageFrontUrl = data['imageFrontUrl'];
      final imageBackUrl = data['imageBackUrl'];

      Future<void> deleteImage(String? imageUrl) async {
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print("Erreur suppression image : $e");
          }
        }
      }

      await deleteImage(imageFrontUrl);
      await deleteImage(imageBackUrl);
    }

    await flashcardRef.delete();
  }

  /// 🔹 Upload une image et retourne son URL
  Future<String> uploadImageAndGetUrl(
      File image,
      String userId,
      String subjectId,
      List<String>? parentPathIds,
      ) async {
    final fileName = const Uuid().v4();
    final pathSegments = [
      'flashcards',
      userId,
      subjectId,
      ...(parentPathIds ?? []),
      '$fileName.jpg',
    ];

    final storageRef = FirebaseStorage.instance.ref().child(pathSegments.join('/'));
    await storageRef.putFile(image);
    return await storageRef.getDownloadURL();
  }

  Future<DocumentReference> _ensureLevelDocument({
    required DocumentReference parentRef,
    required String levelKey,
    required String docId,
  }) async {
    final docRef = parentRef.collection(levelKey).doc(docId);
    await docRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    return docRef;
  }


  // 🌀 Révision - Quizz
  /// 🔹 Met à jour un document unique par jour et par thème pour suivre toutes les réponses
  Future<void> recordAnswerForDayAndTheme({
    required String userId,
    required String flashcardId,
    required bool isCorrect,
    required int durationSeconds,
    required String subjectId,
    required int level,
    required List<String> parentPathIds,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Point de départ : document date
    DocumentReference currentRef = _db
        .collection('users')
        .doc(userId)
        .collection('revision_stats')
        .doc(today);

    await currentRef.set({
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Traverse la hiérarchie pour arriver au thème ciblé
    for (int i = 0; i < level; i++) {
      currentRef = await _ensureLevelDocument(
        parentRef: currentRef,
        levelKey: 'level_$i',
        docId: parentPathIds[i],
      );
    }



// Dernier niveau : sujet
    final subjectRef = currentRef.collection('level_$level').doc(subjectId);
    await subjectRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    await subjectRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));


// Référence vers answers/{flashcardId}
    final answerRef = subjectRef
        .collection('answers')
        .doc(flashcardId);

// Référence vers meta/revision_summary
    final summaryRef = subjectRef
        .collection('meta')
        .doc('revision_summary');

// 🔁 Enregistrement de la réponse
    await answerRef.set({
      'flashcardId': flashcardId,
      'subjectId': subjectId,
      'level': level,
      'parentPathIds': parentPathIds,
      'lastIsCorrect': isCorrect,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'correctCount': FieldValue.increment(isCorrect ? 1 : 0),
      'wrongCount': FieldValue.increment(isCorrect ? 0 : 1),
      'totalDuration': FieldValue.increment(durationSeconds),
    }, SetOptions(merge: true));

// 📦 Mise à jour du résumé journalier
    await summaryRef.set({
      'correctTotal': FieldValue.increment(isCorrect ? 1 : 0),
      'wrongTotal': FieldValue.increment(isCorrect ? 0 : 1),
      'revisionCount': FieldValue.increment(1),
      'totalDuration': FieldValue.increment(durationSeconds),
      'lastUpdated': FieldValue.serverTimestamp(),
      'flashcardsSeen': FieldValue.arrayUnion([flashcardId]),
    }, SetOptions(merge: true));

  }

  Future<Map<String, dynamic>> getTodayGlobalSummary(String userId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print('📆 Date du jour : $today');
    final statsRef = _db.collection('users').doc(userId).collection('revision_stats').doc(today);

    int totalCorrect = 0;
    int totalWrong = 0;
    int revisionCount = 0;
    int flashcardsSeen = 0;

    Future<void> exploreLevels(DocumentReference ref, int level) async {
      final levelKey = 'level_$level';
      final levelDocs = await ref.collection(levelKey).get();
      print('🔎 Lecture de ${levelDocs.docs.length} sujets à $levelKey');


      for (var doc in levelDocs.docs) {
        // 📥 Lire d'abord meta/revision_summary
        print('📂 Sujet ID = ${doc.id}');
        final metaRef = doc.reference.collection('meta').doc('revision_summary');
        final metaSnap = await metaRef.get();
        if (metaSnap.exists) {
          final data = metaSnap.data()!;
          print('📊 Found revision_summary for ${doc.id}: $data');
          totalCorrect += (data['correctTotal'] ?? 0) as int;
          totalWrong += (data['wrongTotal'] ?? 0) as int;
          revisionCount += (data['revisionCount'] ?? 0) as int;
          flashcardsSeen += (data['flashcardsSeen'] as List?)?.length ?? 0;
        }

        // 🔁 Ensuite : explorer récursivement
        print('✅ Document trouvé pour le jour : $today. Exploration...');
        await exploreLevels(doc.reference, level + 1);
        print('✅ Résumé final : correct=$totalCorrect, wrong=$totalWrong, seen=$flashcardsSeen');
      }
    }



    final exists = await statsRef.get();
    print('✅ Le document existe-t-il ? ${exists.exists}');
    if (!exists.exists) {
      return {
        'correctTotal': 0,
        'wrongTotal': 0,
        'revisionCount': 0,
        'successRate': 0,
        'flashcardsSeen': 0,
      };
    }

    final level0Docs = await statsRef.collection('level_0').get();
    print('📁 Nombre de documents dans level_0 : ${level0Docs.docs.length}');
    for (var doc in level0Docs.docs) {
      print('📄 ID du doc level_0 : ${doc.id}');
    }

    await exploreLevels(statsRef, 0);

    return {
      'correctTotal': totalCorrect,
      'wrongTotal': totalWrong,
      'revisionCount': revisionCount,
      'flashcardsSeen': flashcardsSeen,
      'successRate': revisionCount == 0
          ? 0
          : ((totalCorrect / (totalCorrect + totalWrong)) * 100).round(),
    };
  }


}
