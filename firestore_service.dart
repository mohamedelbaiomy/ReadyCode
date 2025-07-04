import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepo {
  FirestoreRepo._();

  static final FirestoreRepo _instance = FirestoreRepo._();

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Public access point
  static FirestoreRepo get instance => _instance;

  static Future<void> createCollectionWithDoc({
    required String collectionName,
    required String docName,
    required Map<String, dynamic> data,
  }) async =>
      await _firestore.collection(collectionName).doc(docName).set(data);

  static Future<DocumentReference<Map<String, dynamic>>> createCollection({
    required String collectionName,
    required Map<String, dynamic> data,
  }) async => await _firestore.collection(collectionName).add(data);

  static Future<void> createSubCollectionWithDoc({
    required String firstCollectionName,
    required String secondCollectionName,
    required String firstDocName,
    required String secondDocName,
    required Map<String, dynamic> data,
  }) async => await _firestore
      .collection(firstCollectionName)
      .doc(firstDocName)
      .collection(secondCollectionName)
      .doc(secondDocName)
      .set(data);

  static Future<void> deleteData({
    required String collectionName,
    required String documentId,
  }) async {
    await _firestore.collection(collectionName).doc(documentId).delete();
  }

  static Future<void> deleteSubCollection({
    required String firstCollectionName,
    required String secondCollectionName,
    required String docName,
  }) async {
    // Get all documents in the subCollection
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(firstCollectionName)
        .doc(docName)
        .collection(secondCollectionName)
        .get(const GetOptions(source: Source.server));

    // Delete each document in the subCollection
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> updateData({
    required String collectionName,
    required String docName,
    required Map<String, dynamic> data,
  }) async =>
      await _firestore.collection(collectionName).doc(docName).update(data);

  static Future<QuerySnapshot<Map<String, dynamic>>> getDataWithPagination({
    required String collectionName,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
  }) async =>
      lastDocument != null
          ? await _firestore
              .collection(collectionName)
              //.orderBy('uploadedAt', descending: true)
              .startAfterDocument(lastDocument)
              .limit(limit)
              .get()
          : await _firestore
              .collection(collectionName)
              //.orderBy('uploadedAt', descending: true)
              .limit(limit)
              .get();

  static Future<QuerySnapshot<Map<String, dynamic>>>
  getSubCollectionDocDataWithPagination({
    required String firstCollectionName,
    required String secondCollectionName,
    required String docName,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
  }) async =>
      lastDocument != null
          ? await _firestore
              .collection(firstCollectionName)
              .doc(docName)
              .collection(secondCollectionName)
              .startAfterDocument(lastDocument)
              .limit(limit)
              .get()
          : await _firestore
              .collection(firstCollectionName)
              .doc(docName)
              .collection(secondCollectionName)
              .limit(limit)
              .get();

  static Future<QuerySnapshot<Map<String, dynamic>>> getData({
    required String collectionName,
  }) async => await _firestore.collection(collectionName).get();

  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocData(
    String collectionName,
    String docName,
  ) async => await _firestore.collection(collectionName).doc(docName).get();

  static Future<QuerySnapshot<Map<String, dynamic>>> getSubCollectionDocData(
    String firstCollectionName,
    String secondCollectionName,
    String docName,
  ) async => await _firestore
      .collection(firstCollectionName)
      .doc(docName)
      .collection(secondCollectionName)
      .get(const GetOptions(source: Source.server));

  static Future<void> deleteSubCollectionWithDoc({
    required String firstCollectionName,
    required String secondCollectionName,
    required String docName,
    required String subDocId,
  }) async {
    await _firestore
        .collection(firstCollectionName)
        .doc(docName)
        .collection(secondCollectionName)
        .doc(subDocId)
        .delete();
  }

  static Future<void> updateSubCollectionDoc({
    required String firstCollectionName,
    required String secondCollectionName,
    required String firstDocName,
    required String secondDocName,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection(firstCollectionName)
        .doc(firstDocName)
        .collection(secondCollectionName)
        .doc(secondDocName)
        .update(data);
  }
}
