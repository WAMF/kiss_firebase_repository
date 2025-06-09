import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';

import '../../../kiss_repository/shared_test_logic/data/test_object.dart';
import '../../../kiss_repository/shared_test_logic/data/queries.dart';

/// Firebase-specific query builder for TestObject
class FirestoreTestObjectQueryBuilder implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery = firestore.FirebaseFirestore.instance.collection('test_objects');

    if (query is QueryByName) {
      final prefix = query.namePrefix;
      return baseQuery
          .where('name', isGreaterThanOrEqualTo: prefix)
          .where('name', isLessThan: '${prefix}\uf8ff')
          .orderBy('name');
    }

    if (query is QueryByCreatedAfter) {
      return baseQuery.where('created', isGreaterThan: firestore.Timestamp.fromDate(query.date)).orderBy('created');
    }

    if (query is QueryByCreatedBefore) {
      return baseQuery
          .where('created', isLessThan: firestore.Timestamp.fromDate(query.date))
          .orderBy('created', descending: true);
    }

    if (query is QueryByExpiresAfter) {
      return baseQuery.where('expires', isGreaterThan: firestore.Timestamp.fromDate(query.date)).orderBy('expires');
    }

    if (query is QueryByExpiresBefore) {
      return baseQuery
          .where('expires', isLessThan: firestore.Timestamp.fromDate(query.date))
          .orderBy('expires', descending: true);
    }

    // Default: return all objects ordered by creation date (newest first)
    return baseQuery.orderBy('created', descending: true);
  }
}

/// Shared test helpers for integration tests
class IntegrationTestHelpers {
  static late Repository<TestObject> repository;
  static const String testCollection = 'test_objects';

  /// Initialize Firebase and repository for integration tests
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'demo-project',
      ),
    );

    firestore.FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

    repository = RepositoryFirestore<TestObject>(
      path: testCollection,
      fromFirestore: (ref, data) => TestObject(
        id: ref.id,
        name: data['name'] as String,
        created: data['created'] is DateTime
            ? data['created'] as DateTime
            : (data['created'] as firestore.Timestamp).toDate(),
        expires: data['expires'] is DateTime
            ? data['expires'] as DateTime
            : (data['expires'] as firestore.Timestamp).toDate(),
      ),
      toFirestore: (testObject) => {
        'name': testObject.name,
        'created': firestore.Timestamp.fromDate(testObject.created),
        'expires': firestore.Timestamp.fromDate(testObject.expires),
      },
      queryBuilder: FirestoreTestObjectQueryBuilder(),
    );
  }

  /// Clear the test collection before each test
  static Future<void> clearTestCollection() async {
    try {
      final collection = firestore.FirebaseFirestore.instance.collection(testCollection);
      final docs = await collection.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
      if (docs.docs.isNotEmpty) {
        print('🧹 Cleared ${docs.docs.length} test records');
      }
    } catch (e) {
      print('ℹ️ Collection clear: $e');
    }
  }

  /// Setup integration test binding and Firebase
  static void setupIntegrationTest() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Setup integration tests
  static Future<void> setupIntegrationTests() async {
    setupIntegrationTest();
    await initializeFirebase();

    try {
      // Test Firebase connection
      await firestore.FirebaseFirestore.instance.enableNetwork();
      print('✅ Connected to Firebase Firestore emulator');
    } catch (e) {
      throw Exception(
        'Failed to connect to Firebase Firestore. Make sure the emulator is running at localhost:8080\n'
        'Run: firebase emulators:start --only firestore\n'
        'Error: $e',
      );
    }

    print('🎯 Integration tests ready to run');
  }

  /// Teardown integration tests
  static Future<void> tearDownIntegrationTests() async {
    try {
      await clearTestCollection();
      print('✅ Integration test cleanup completed');
    } catch (e) {
      print('ℹ️ Cleanup error (may be harmless): $e');
    }
  }
}
