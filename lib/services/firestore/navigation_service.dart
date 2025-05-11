// lib/services/firestore/navigation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart'; //  Firestore pour accéder à la base de données
import 'core.dart'; //  Accès au FirestoreCore (depuis le même dossier)

const bool kEnableLogs = false; //  Mettre à false pour désactiver tous les print() de ce fichier

void log(String message) {
  if (kEnableLogs) print(message);
}

///  Service de navigation hiérarchique dans Firestore (utile pour sujets/sous-sujets)
class FirestoreNavigationService {
  final FirebaseFirestore _db = FirestoreCore().db; //  Instance Firestore utilisée dans ce service

  ///  Retourne une référence vers un document situé dans une sous-collection hiérarchique (à n’importe quel niveau)
  ///
  /// Exemple de chemin généré :
  /// - Niveau 0 : /users/{uid}/subjects/{subjectId}
  /// - Niveau 1 : /users/{uid}/subjects/{id0}/subsubject1/{subjectId}
  /// - Niveau 2 : /users/{uid}/subjects/{id0}/subsubject1/{id1}/subsubject2/{subjectId}
  Future<DocumentReference> getSubSubjectDocRef({
    required String userId, //  ID de l’utilisateur connecté
    required int level, //  Niveau du sujet (0 = racine, 1 = sous-niveau 1, etc.)
    required List<String> parentPathIds, //  Liste des IDs des parents menant à ce niveau
    required String subjectId, // 🏷 ID du sujet final à cibler
  }) async {
    log("[getSubSubjectDocRef] → user=$userId | level=$level | parentPathIds=$parentPathIds | subjectId=$subjectId");

    // Vérifie que la longueur de parentPathIds est cohérente avec le niveau
    if (parentPathIds.length != level) {
      log("[ERREUR] Longueur parentPathIds (${parentPathIds.length}) ≠ level ($level)");
      throw Exception("Invalid parentPathIds for level $level");
    }

    //  Cas spécial : niveau 0 → on accède directement à /users/{uid}/subjects/{subjectId}
    if (level == 0) {
      final DocumentReference rootRef = _db
          .collection('users') //  Collection racine des utilisateurs
          .doc(userId) // Document utilisateur courant
          .collection('subjects') //  Collection des sujets racine
          .doc(subjectId); // 🏷 Document ciblé (niveau 0)
      log("Accès direct au sujet racine : ${rootRef.path}");
      return rootRef; //  Retour immédiat sans descente hiérarchique
    }

    // Cas général : niveau > 0 → on commence à reconstruire le chemin depuis la racine
    DocumentReference currentRef = _db
        .collection('users') // Collection des utilisateurs
        .doc(userId) // Document utilisateur
        .collection('subjects') // Sujets racine
        .doc(parentPathIds[0]); // Premier ID parent (niveau 0)
    log("Niveau 0 → ${currentRef.path}");

    // Pour chaque niveau intermédiaire (ex: subsubject1, subsubject2, etc.)
    for (int i = 1; i < level; i++) {
      final String subCollection = 'subsubject$i'; // Nom dynamique de la sous-collection
      final String docId = parentPathIds[i]; // ID du document à ce niveau

      currentRef = currentRef
          .collection(subCollection) // Accès à la sous-collection
          .doc(docId); // Accès au document correspondant
      log("Niveau $i → ${currentRef.path}");
    }

    // Cible finale : sous-collection subsubjectX du niveau courant
    final DocumentReference finalRef = currentRef
        .collection('subsubject$level') // Sous-collection finale selon le niveau
        .doc(subjectId); // ID du sujet final ciblé
    log("Document ciblé → ${finalRef.path}");

    return finalRef; // Retourne la référence finale vers le document ciblé
  }
// ← FERMETURE de getSubSubjectDocRef

  /// Crée ou met à jour un document dans une sous-collection donnée
  Future<DocumentReference> ensureLevelDocument({
    required DocumentReference parentRef, /// - [parentRef] → DocumentReference : référence du niveau parent
    required String levelKey, /// - [levelKey] → String : nom de la sous-collection (ex: subsubject3)
    required String docId, /// - [docId] → String : ID du document à créer ou modifier
    required String subjectName, /// - [subjectName] → String : Nom du sujet (champ `name`)
  }) async {
    log("[ensureLevelDocument] → levelKey=$levelKey | docId=$docId | name=$subjectName");

    final DocumentReference docRef = parentRef
        .collection(levelKey) // Accès à la sous-collection cible
        .doc(docId); // Document ciblé (créé ou mis à jour)
    log("Cible : ${docRef.path}");

// On essaie de récupérer le champ isCategory à partir du document original dans la base "subjects"
    DocumentSnapshot? subjectSnap;
    Map<String, dynamic>? subjectData;
    bool isCategory = true; // Par défaut on suppose que c’est une catégorie

    try {
      // On tente de lire depuis la collection globale 'subjects' (racine)
      subjectSnap = await FirebaseFirestore.instance.collection('subjects').doc(docId).get();
      subjectData = subjectSnap.data() as Map<String, dynamic>?;
      isCategory = subjectData?['isCategory'] ?? true;
      log("[ensureLevelDocument] isCategory récupéré : $isCategory pour $docId");
    } catch (e) {
      log("[ensureLevelDocument] Impossible de récupérer isCategory pour $docId : $e");
    }

// Données enregistrées dans Firestore
    await docRef.set({
      'createdAt': FieldValue.serverTimestamp(), //  Date technique (pour tri ou logs)
      'name': subjectName, //  Nom du sujet affiché
      'isCategory': isCategory, //  Champ ajouté ici
    }, SetOptions(merge: true));


    log("Document enregistré : ${docRef.path}");
    return docRef;
  }

  /// Retourne un `Map` avec les sous-collections nommées `subsubjectX` non vides.
  /// Utile pour explorer récursivement les niveaux hiérarchiques de Firestore
  Future<Map<String, QuerySnapshot>> getSubCollectionsFromDoc(
      DocumentReference ref, // Référence du document Firestore dont on veut explorer les sous-collections
      ) async {
    log("[getSubCollectionsFromDoc] → doc=${ref.path}"); //️ Log du chemin du document de départ

    final Map<String, QuerySnapshot> result = {}; // Initialisation de la map résultat

    //  On parcourt les sous-collections normées : subsubject0 à subsubject5
    for (int i = 0; i <= 5; i++) {
      final colName = 'subsubject$i'; //  Nom de la sous-collection normée (ex: subsubject0)

      final collectionRef = ref.collection(colName); //  Référence vers cette sous-collection

      final snapshot = await collectionRef.get(); //  Récupère les documents présents dans la sous-collection

      if (snapshot.docs.isEmpty) {
        log("Collection $colName est vide."); //  Rien à explorer à ce niveau
      } else {
        result[colName] = snapshot; //  On ajoute cette sous-collection au résultat
        log("Collection $colName → ${snapshot.docs.length} document(s)"); //  Log du nombre de documents trouvés
      }
    }

    log(" Sous-collections retournées : ${result.keys.toList()}"); //  Log final avec la liste des clés trouvées
    return result; //  On retourne la map contenant toutes les sous-collections non vides
  }


  ///  Récupère la collection `subsubjectX` correspondant à un niveau donné
  ///
  /// Cette méthode retourne la `CollectionReference` vers la sous-collection d'un sujet
  /// Exemple : /users/{uid}/subjects/{id0}/subsubject1/{id1}/subsubject2
  ///  Récupère la collection `subsubjectX` correspondant à un niveau donné
  ///
  /// Cette méthode retourne la `CollectionReference` vers la sous-collection d'un sujet
  /// Exemple : /users/{uid}/subjects/{id0}/subsubject1/{id1}/subsubject2
  Future<CollectionReference> getSubSubjectCollection({
    required String userId, /// - [userId] → String : ID de l'utilisateur connecté
    required int level, /// - [level] → int : niveau hiérarchique (≥ 1)
    required List<String> parentPathIds, /// - [parentPathIds] → List<String> : liste des IDs depuis la racine jusqu'au niveau actuel (inclus)
  }) async {
    log("[getSubSubjectCollection] → user=$userId | level=$level | parentPathIds=$parentPathIds");

    // ️ Vérification de sécurité : le niveau doit être ≥ 1
    if (level < 1) {
      log("[ERREUR] Le niveau doit être ≥ 1 pour accéder à une sous-collection (reçu : $level)");
      throw Exception("Invalid level: must be >= 1");
    }

    //  Si level == 1 → il n'y a pas de parents au-dessus → on passe une liste vide []
    //  Sinon → on extrait les parents jusqu’au niveau - 1 (ex: [A,B,C] → [A,B])
    final List<String> parentIds = level > 1 ? parentPathIds.sublist(0, level - 1) : [];

    //  On récupère l’ID du parent direct (le dernier de la liste des IDs)
    final String parentId = parentPathIds[level - 1];
    log("Extraction du parent : parentId=$parentId | parentsPath=$parentIds");

    //  On utilise la méthode existante pour retrouver le document parent
    final DocumentReference docRef = await getSubSubjectDocRef(
      userId: userId, //  Utilisateur
      level: level - 1, //  Niveau parent
      parentPathIds: parentIds, //  Chemin jusqu’au parent
      subjectId: parentId, //  ID du parent direct
    );
    log("Référence du document parent obtenue : ${docRef.path}");

    // On retourne la sous-collection 'subsubjectX' rattachée à ce document parent
    final CollectionReference subCollection = docRef.collection('subsubject$level'); // Sous-collection cible
    log("Collection retournée : ${subCollection.path}");

    return subCollection; // Retour
  }

}