// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:kiss_repository_tests/kiss_repository_tests.dart';

import 'firebase_query_builder.dart';

class FirebaseRepositoryFactory implements RepositoryFactory<ProductModel> {
  static bool _initialized = false;
  Repository<ProductModel>? _repository;

  static const String _testCollection = 'products';

  @override
  Future<Repository<ProductModel>> createRepository() async {
    await _initialize();

    _repository = RepositoryFirestore<ProductModel>(
      path: _testCollection,
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
      queryBuilder: FirestoreProductQueryBuilder(),
    );
    return _repository!;
  }

  static Future<void> _initialize() async {
    if (_initialized) return;

    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'demo-project',
      ),
    );

    firestore.FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

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

    _initialized = true;
    print('✅ Firebase repository initialized');
  }

  @override
  Future<void> cleanup() async {
    if (_repository == null) {
      print('🧹 Cleanup: No repository to clean');
      return;
    }

    try {
      final collection = firestore.FirebaseFirestore.instance.collection(_testCollection);
      final docs = await collection.get();
      print('🧹 Cleanup: Found ${docs.docs.length} items to delete');

      if (docs.docs.isNotEmpty) {
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }
        print('🧹 Cleanup: Deleted ${docs.docs.length} items successfully');
      } else {
        print('🧹 Cleanup: Collection already empty');
      }
    } catch (e) {
      print('❌ Cleanup failed: $e');
    }
  }

  @override
  void dispose() {
    _repository?.dispose();
    _repository = null;
    _initialized = false;
  }
}
