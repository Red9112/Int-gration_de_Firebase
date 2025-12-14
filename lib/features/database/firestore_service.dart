import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/crashlytics_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a document to a collection
  Future<DocumentReference> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      await CrashlyticsService.log('Document added to $collection');
      return docRef;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Get a document by ID
  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Update a document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .update(data);
      await CrashlyticsService.log('Document updated in $collection');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
      await CrashlyticsService.log('Document deleted from $collection');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Set a document (creates or overwrites)
  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));
      await CrashlyticsService.log('Document set in $collection');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Get a collection
  Future<QuerySnapshot> getCollection({
    required String collection,
    Query Function(Query)? queryBuilder,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      return await query.get();
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Stream a collection
  Stream<QuerySnapshot> streamCollection({
    required String collection,
    Query Function(Query)? queryBuilder,
    int? limit,
  }) {
    try {
      Query query = _firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      return query.snapshots();
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Stream a document
  Stream<DocumentSnapshot> streamDocument({
    required String collection,
    required String documentId,
  }) {
    try {
      return _firestore
          .collection(collection)
          .doc(documentId)
          .snapshots();
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Batch write
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();
      for (final operation in operations) {
        final ref = _firestore
            .collection(operation['collection'] as String)
            .doc(operation['documentId'] as String?);
        
        switch (operation['type'] as String) {
          case 'set':
            batch.set(ref, operation['data'] as Map<String, dynamic>);
            break;
          case 'update':
            batch.update(ref, operation['data'] as Map<String, dynamic>);
            break;
          case 'delete':
            batch.delete(ref);
            break;
        }
      }
      await batch.commit();
      await CrashlyticsService.log('Batch write completed');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }
}

