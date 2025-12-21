import 'package:firebase_database/firebase_database.dart';
import '../../services/crashlytics_service.dart';

/// Service wrapper for Firebase Realtime Database
/// Provides CRUD operations and real-time listeners
class RealtimeDatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Set a value at a specific path (overwrites existing data)
  Future<void> setValue({
    required String path,
    required dynamic value,
  }) async {
    try {
      await _database.child(path).set(value);
      await CrashlyticsService.log('Value set at path: $path');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Update multiple values atomically
  Future<void> update({
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _database.update(updates);
      await CrashlyticsService.log('Database updated with ${updates.length} paths');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Get a value once (single read)
  Future<DataSnapshot> getValue({
    required String path,
  }) async {
    try {
      final snapshot = await _database.child(path).get();
      return snapshot;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Remove a value at a specific path
  Future<void> remove({
    required String path,
  }) async {
    try {
      await _database.child(path).remove();
      await CrashlyticsService.log('Value removed at path: $path');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Push a value to a list (generates unique key automatically)
  Future<DatabaseReference> push({
    required String path,
    required dynamic value,
  }) async {
    try {
      final ref = _database.child(path).push();
      await ref.set(value);
      await CrashlyticsService.log('Value pushed to path: $path');
      return ref;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Set a value with priority
  Future<void> setWithPriority({
    required String path,
    required dynamic value,
    required dynamic priority,
  }) async {
    try {
      await _database.child(path).setWithPriority(value, priority);
      await CrashlyticsService.log('Value set with priority at path: $path');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Set priority for an existing node
  Future<void> setPriority({
    required String path,
    required dynamic priority,
  }) async {
    try {
      await _database.child(path).setPriority(priority);
      await CrashlyticsService.log('Priority set at path: $path');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Run a transaction (atomic operation)
  Future<TransactionResult> runTransaction({
    required String path,
    required TransactionHandler handler,
  }) async {
    try {
      final result = await _database.child(path).runTransaction(handler);
      await CrashlyticsService.log('Transaction completed at path: $path');
      return result;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Keep a path synced even when offline
  Future<void> keepSynced({
    required String path,
    bool synced = true,
  }) async {
    try {
      await _database.child(path).keepSynced(synced);
      await CrashlyticsService.log('Keep synced ${synced ? "enabled" : "disabled"} at path: $path');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Go offline (disconnect from server)
  Future<void> goOffline() async {
    try {
      await FirebaseDatabase.instance.goOffline();
      await CrashlyticsService.log('Database went offline');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Go online (reconnect to server)
  Future<void> goOnline() async {
    try {
      await FirebaseDatabase.instance.goOnline();
      await CrashlyticsService.log('Database went online');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  // ==================== Real-time Listeners ====================

  /// Listen to value changes at a path
  /// Returns a stream that emits DatabaseEvent whenever the value changes
  Stream<DatabaseEvent> onValue({
    required String path,
  }) {
    try {
      return _database.child(path).onValue;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Listen to child added events
  Stream<DatabaseEvent> onChildAdded({
    required String path,
  }) {
    try {
      return _database.child(path).onChildAdded;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Listen to child changed events
  Stream<DatabaseEvent> onChildChanged({
    required String path,
  }) {
    try {
      return _database.child(path).onChildChanged;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Listen to child removed events
  Stream<DatabaseEvent> onChildRemoved({
    required String path,
  }) {
    try {
      return _database.child(path).onChildRemoved;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Listen to child moved events
  Stream<DatabaseEvent> onChildMoved({
    required String path,
  }) {
    try {
      return _database.child(path).onChildMoved;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  // ==================== Query Methods ====================

  /// Order by child value
  Query orderByChild(String childKey) {
    return _database.orderByChild(childKey);
  }

  /// Order by key
  Query orderByKey() {
    return _database.orderByKey();
  }

  /// Order by value
  Query orderByValue() {
    return _database.orderByValue();
  }

  /// Order by priority
  Query orderByPriority() {
    return _database.orderByPriority();
  }

  /// Limit to first N results
  Query limitToFirst(int limit) {
    return _database.limitToFirst(limit);
  }

  /// Limit to last N results
  Query limitToLast(int limit) {
    return _database.limitToLast(limit);
  }

  /// Start at a specific value
  Query startAt(dynamic value, {String? key}) {
    return _database.startAt(value, key: key);
  }

  /// End at a specific value
  Query endAt(dynamic value, {String? key}) {
    return _database.endAt(value, key: key);
  }

  /// Equal to a specific value
  Query equalTo(dynamic value, {String? key}) {
    return _database.equalTo(value, key: key);
  }

  // ==================== User Data Helpers ====================

  /// Set user data in Realtime Database
  /// Creates/updates data at path: users/{userId}
  Future<void> setUserData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await setValue(
        path: 'users/$userId',
        value: data,
      );
      await CrashlyticsService.log('User data set for user: $userId');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Get user data from Realtime Database
  Future<DataSnapshot> getUserData({
    required String userId,
  }) async {
    try {
      return await getValue(path: 'users/$userId');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Update user data in Realtime Database
  Future<void> updateUserData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await update(updates: {
        'users/$userId': data,
      });
      await CrashlyticsService.log('User data updated for user: $userId');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Delete user data from Realtime Database
  Future<void> deleteUserData({
    required String userId,
  }) async {
    try {
      await remove(path: 'users/$userId');
      await CrashlyticsService.log('User data deleted for user: $userId');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Listen to user data changes in real-time
  Stream<DatabaseEvent> listenToUserData({
    required String userId,
  }) {
    try {
      return onValue(path: 'users/$userId');
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Listen to child added events for user data
  Stream<DatabaseEvent> listenToUserDataChildAdded({
    required String userId,
  }) {
    try {
      return onChildAdded(path: 'users/$userId');
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }
}

