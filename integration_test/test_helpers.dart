import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';

import '../../kiss_repository/shared_test_logic/data/product_model.dart';
import '../../kiss_repository/shared_test_logic/data/queries.dart';

/// Firebase-specific query builder for ProductModel
class TestFirestoreProductQueryBuilder implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery = firestore.FirebaseFirestore.instance.collection('products');

    if (query is QueryByName) {
      final prefix = query.namePrefix;
      return baseQuery
          .where('name', isGreaterThanOrEqualTo: prefix)
          .where('name', isLessThan: '$prefix\uf8ff')
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

    if (query is QueryByPriceGreaterThan) {
      return baseQuery.where('price', isGreaterThan: query.price).orderBy('price');
    }

    if (query is QueryByPriceLessThan) {
      return baseQuery.where('price', isLessThan: query.price).orderBy('price', descending: true);
    }

    // Default: return all objects ordered by creation date (newest first)
    return baseQuery.orderBy('created', descending: true);
  }
}

/// Shared test helpers for integration tests
class IntegrationTestHelpers {
  static late Repository<ProductModel> repository;
  static const String testCollection = 'products';

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

    repository = RepositoryFirestore<ProductModel>(
      path: testCollection,
      fromFirestore: (ref, data) => ProductModel(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        description: data['description'] as String? ?? '',
        created: data['created'] is DateTime
            ? data['created'] as DateTime
            : (data['created'] as firestore.Timestamp).toDate(),
      ),
      toFirestore: (productModel) => {
        'id': productModel.id,
        'name': productModel.name,
        'price': productModel.price,
        'description': productModel.description,
        'created': firestore.Timestamp.fromDate(productModel.created),
      },
      queryBuilder: TestFirestoreProductQueryBuilder(),
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
        _log('🧹 Cleared ${docs.docs.length} test records');
      }
    } catch (e) {
      _log('ℹ️ Collection clear: $e');
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
      _log('✅ Connected to Firebase Firestore emulator');
    } catch (e) {
      throw Exception(
        'Failed to connect to Firebase Firestore. Make sure the emulator is running at localhost:8080\n'
        'Run: firebase emulators:start --only firestore\n'
        'Error: $e',
      );
    }

    _log('🎯 Integration tests ready to run');
  }

  /// Teardown integration tests
  static Future<void> tearDownIntegrationTests() async {
    try {
      await clearTestCollection();
      _log('✅ Integration test cleanup completed');
    } catch (e) {
      _log('ℹ️ Cleanup error (may be harmless): $e');
    }
  }
}

void _log(String message) {
  // ignore: avoid_print
  print('🔍 $message');
}
