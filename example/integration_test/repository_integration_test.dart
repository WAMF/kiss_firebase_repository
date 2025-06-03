import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Repository Integration Tests', () {
    late Repository<TestUser> repository;

    setUpAll(() async {
      // Initialize Firebase with mock options for testing
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'mock-api-key',
          appId: 'mock-app-id',
          messagingSenderId: 'mock-sender-id',
          projectId: 'demo-project',
        ),
      );

      // Connect to Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

      // Create repository
      repository = RepositoryFirestore<TestUser>(
        path: 'test_users',
        fromFirestore: (ref, data) => TestUser.fromMap(data),
        toFirestore: (user) => user.toMap(),
      );
    });

    setUp(() async {
      // Clear collection before each test
      final collection = FirebaseFirestore.instance.collection('test_users');
      final docs = await collection.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    });

    group('Basic CRUD Operations', () {
      test('should add, get, update, delete single item', () async {
        final user = TestUser(id: 'user1', name: 'John Doe', age: 30, createdAt: DateTime.now());

        // CREATE - using IdentifiedObject
        final identifiedUser = IdentifiedObject(user.id, user);
        await repository.add(identifiedUser);

        // READ
        final retrieved = await repository.get(user.id);
        expect(retrieved.id, user.id);
        expect(retrieved.name, user.name);
        expect(retrieved.age, user.age);

        // UPDATE - using updater function
        await repository.update(user.id, (current) => current.copyWith(name: 'John Updated', age: 31));

        final afterUpdate = await repository.get(user.id);
        expect(afterUpdate.name, 'John Updated');
        expect(afterUpdate.age, 31);

        // DELETE
        await repository.delete(user.id);

        // Should throw RepositoryException.notFound when getting deleted item
        expect(() => repository.get(user.id), throwsA(isA<RepositoryException>()));
      });

      test('should handle adding item with existing ID', () async {
        final user = TestUser(id: 'duplicate', name: 'First', age: 25, createdAt: DateTime.now());

        // Add first time - should succeed
        final identifiedUser = IdentifiedObject(user.id, user);
        await repository.add(identifiedUser);

        // Add same ID again - should throw RepositoryException
        final duplicate = TestUser(id: 'duplicate', name: 'Second', age: 30, createdAt: DateTime.now());
        final identifiedDuplicate = IdentifiedObject(duplicate.id, duplicate);

        expect(() => repository.add(identifiedDuplicate), throwsA(isA<RepositoryException>()));
      });

      test('should handle getting non-existent item', () async {
        expect(() => repository.get('non-existent-id'), throwsA(isA<RepositoryException>()));
      });

      test('should handle updating non-existent item', () async {
        expect(
          () => repository.update('non-existent', (user) => user.copyWith(name: 'Ghost')),
          throwsA(isA<RepositoryException>()),
        );
      });

      test('should handle deleting non-existent item', () async {
        // Delete is idempotent - should not throw
        await repository.delete('non-existent-id');
        // Test passes if no exception thrown
      });
    });
  });
}
