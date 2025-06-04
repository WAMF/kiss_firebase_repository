import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';

import 'test_data.dart';

/// Shared test helpers for integration tests
class IntegrationTestHelpers {
  static late Repository<TestUser> repository;

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

    repository = RepositoryFirestore<TestUser>(
      path: 'test_users',
      fromFirestore: (ref, data) => TestUser.fromMap(data),
      toFirestore: (user) => user.toMap(),
      queryBuilder: TestUserQueryBuilder(),
    );
  }

  /// Clear the test collection before each test
  static Future<void> clearTestCollection() async {
    final collection = firestore.FirebaseFirestore.instance.collection('test_users');
    final docs = await collection.get();
    for (final doc in docs.docs) {
      await doc.reference.delete();
    }
  }

  /// Setup integration test binding and Firebase
  static void setupIntegrationTest() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }
}
