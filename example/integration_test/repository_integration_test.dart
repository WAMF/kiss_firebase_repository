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

    group('ID Management & Auto-Generation', () {
      test('should auto-generate IDs with autoIdentify', () async {
        final user = TestUser(
          id: '', // Empty ID - will be auto-generated
          name: 'Auto User',
          age: 25,
          createdAt: DateTime.now(),
        );

        // Create auto-identified object with custom updateObjectWithId
        final autoIdentified = repository.autoIdentify(
          user,
          updateObjectWithId: (user, generatedId) => user.copyWith(id: generatedId),
        );

        // ID should be generated (Firestore IDs are 20 characters)
        expect(autoIdentified.id, isNotEmpty);
        expect(autoIdentified.id.length, 20);
        expect(autoIdentified.object.name, 'Auto User');
        expect(autoIdentified.object.age, 25);
        // The object should now have the generated ID
        expect(autoIdentified.object.id, autoIdentified.id);
      });

      test('should add items with auto-generated IDs using addAutoIdentified', () async {
        final user = TestUser(
          id: '', // Empty ID - will be auto-generated
          name: 'Auto Added User',
          age: 30,
          createdAt: DateTime.now(),
        );

        // Add with auto-generated ID
        final addedUser = await repository.addAutoIdentified(
          user,
          updateObjectWithId: (user, generatedId) => user.copyWith(id: generatedId),
        );

        // Should have auto-generated ID
        expect(addedUser.id, isNotEmpty);
        expect(addedUser.id.length, 20);
        expect(addedUser.name, 'Auto Added User');
        expect(addedUser.age, 30);

        // Should be retrievable by the generated ID
        final retrieved = await repository.get(addedUser.id);
        expect(retrieved.id, addedUser.id);
        expect(retrieved.name, 'Auto Added User');
      });

      test('should handle multiple auto-generated IDs being unique', () async {
        final users = List.generate(
          5,
          (i) => TestUser(id: '', name: 'User $i', age: 20 + i, createdAt: DateTime.now()),
        );

        // Add all users with auto-generated IDs
        final addedUsers = <TestUser>[];
        for (final user in users) {
          final added = await repository.addAutoIdentified(
            user,
            updateObjectWithId: (user, generatedId) => user.copyWith(id: generatedId),
          );
          addedUsers.add(added);
        }

        // All IDs should be unique and valid
        final ids = addedUsers.map((u) => u.id).toSet();
        expect(ids.length, 5); // All unique

        for (final user in addedUsers) {
          expect(user.id, isNotEmpty);
          expect(user.id.length, 20);
        }

        // All should be retrievable
        for (final user in addedUsers) {
          final retrieved = await repository.get(user.id);
          expect(retrieved.id, user.id);
          expect(retrieved.name, user.name);
        }
      });

      test('should work with autoIdentify then manual add', () async {
        final user = TestUser(id: '', name: 'Manual Add User', age: 40, createdAt: DateTime.now());

        // First auto-identify to get the ID
        final autoIdentified = repository.autoIdentify(user, updateObjectWithId: (user, id) => user.copyWith(id: id));

        // Then manually add using the auto-identified object
        final addedUser = await repository.add(autoIdentified);

        // Should work correctly
        expect(addedUser.id, isNotEmpty);
        expect(addedUser.id.length, 20);
        expect(addedUser.name, 'Manual Add User');

        // Should be retrievable
        final retrieved = await repository.get(addedUser.id);
        expect(retrieved.id, addedUser.id);
        expect(retrieved.name, 'Manual Add User');
      });

      test('should handle autoIdentify without updateObjectWithId (default behavior)', () async {
        final user = TestUser(id: 'original-id', name: 'Default User', age: 45, createdAt: DateTime.now());

        // Auto-identify without custom updateObjectWithId
        final autoIdentified = repository.autoIdentify(user);

        // Should generate a new ID
        expect(autoIdentified.id, isNotEmpty);
        expect(autoIdentified.id.length, 20);
        expect(autoIdentified.id, isNot('original-id'));

        // Object should remain unchanged (default behavior)
        expect(autoIdentified.object.id, 'original-id');
        expect(autoIdentified.object.name, 'Default User');
      });
    });

    group('Batch Operations', () {
      test('should add multiple items with addAll', () async {
        final users = [
          TestUser(id: 'batch1', name: 'Batch User 1', age: 25, createdAt: DateTime.now()),
          TestUser(id: 'batch2', name: 'Batch User 2', age: 30, createdAt: DateTime.now()),
          TestUser(id: 'batch3', name: 'Batch User 3', age: 35, createdAt: DateTime.now()),
        ];

        final identifiedUsers = users.map((user) => IdentifiedObject(user.id, user)).toList();

        // Add all users in batch
        final addedUsers = await repository.addAll(identifiedUsers);

        // Convert to list for indexing
        final addedUsersList = addedUsers.toList();

        // Verify all were added
        expect(addedUsersList.length, 3);
        for (int i = 0; i < users.length; i++) {
          expect(addedUsersList[i].id, users[i].id);
          expect(addedUsersList[i].name, users[i].name);
          expect(addedUsersList[i].age, users[i].age);

          // Verify they exist in storage
          final retrieved = await repository.get(users[i].id);
          expect(retrieved.id, users[i].id);
          expect(retrieved.name, users[i].name);
        }
      });

      test('should update multiple items with updateAll', () async {
        // First add some users
        final users = [
          TestUser(id: 'update1', name: 'Update User 1', age: 20, createdAt: DateTime.now()),
          TestUser(id: 'update2', name: 'Update User 2', age: 25, createdAt: DateTime.now()),
          TestUser(id: 'update3', name: 'Update User 3', age: 30, createdAt: DateTime.now()),
        ];

        final identifiedUsers = users.map((user) => IdentifiedObject(user.id, user)).toList();
        await repository.addAll(identifiedUsers);

        // Update all users - increase age by 10
        final updatedUserObjects = users.map((user) => user.copyWith(age: user.age + 10)).toList();
        final identifiedUpdates = updatedUserObjects.map((user) => IdentifiedObject(user.id, user)).toList();

        final updatedUsers = await repository.updateAll(identifiedUpdates);

        // Convert to list for indexing
        final updatedUsersList = updatedUsers.toList();

        // Verify updates
        expect(updatedUsersList.length, 3);
        for (int i = 0; i < users.length; i++) {
          expect(updatedUsersList[i].id, users[i].id);
          expect(updatedUsersList[i].name, users[i].name);
          expect(updatedUsersList[i].age, users[i].age + 10);

          // Verify in storage
          final retrieved = await repository.get(users[i].id);
          expect(retrieved.age, users[i].age + 10);
        }
      });

      test('should delete multiple items with deleteAll', () async {
        // First add some users
        final users = [
          TestUser(id: 'delete1', name: 'Delete User 1', age: 40, createdAt: DateTime.now()),
          TestUser(id: 'delete2', name: 'Delete User 2', age: 45, createdAt: DateTime.now()),
          TestUser(id: 'delete3', name: 'Delete User 3', age: 50, createdAt: DateTime.now()),
        ];

        final identifiedUsers = users.map((user) => IdentifiedObject(user.id, user)).toList();
        await repository.addAll(identifiedUsers);

        // Verify they exist
        for (final user in users) {
          final retrieved = await repository.get(user.id);
          expect(retrieved.id, user.id);
        }

        // Delete all
        final deleteIds = users.map((user) => user.id).toList();
        await repository.deleteAll(deleteIds);

        // Verify all are deleted
        for (final user in users) {
          expect(() => repository.get(user.id), throwsA(isA<RepositoryException>()));
        }
      });

      test('should handle batch operations with some failures', () async {
        // Add one user first
        final existingUser = TestUser(id: 'existing', name: 'Existing User', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(existingUser.id, existingUser));

        // Try to add batch including duplicate ID
        final batchUsers = [
          TestUser(id: 'new1', name: 'New User 1', age: 30, createdAt: DateTime.now()),
          TestUser(id: 'existing', name: 'Duplicate User', age: 35, createdAt: DateTime.now()), // This should fail
          TestUser(id: 'new2', name: 'New User 2', age: 40, createdAt: DateTime.now()),
        ];

        final identifiedBatch = batchUsers.map((user) => IdentifiedObject(user.id, user)).toList();

        // Should throw RepositoryException for duplicate
        expect(() => repository.addAll(identifiedBatch), throwsA(isA<RepositoryException>()));

        // Verify partial operations didn't complete
        expect(() => repository.get('new1'), throwsA(isA<RepositoryException>()));
        expect(() => repository.get('new2'), throwsA(isA<RepositoryException>()));

        // Original should still exist unchanged
        final retrieved = await repository.get('existing');
        expect(retrieved.name, 'Existing User');
        expect(retrieved.age, 25);
      });

      test('should handle empty batch operations', () async {
        // Empty addAll
        final emptyAddResult = await repository.addAll(<IdentifiedObject<TestUser>>[]);
        expect(emptyAddResult, isEmpty);

        // Empty updateAll
        final emptyUpdateResult = await repository.updateAll(<IdentifiedObject<TestUser>>[]);
        expect(emptyUpdateResult, isEmpty);

        // Empty deleteAll - should complete without error
        await repository.deleteAll(<String>[]);
        // Test passes if no exception thrown
      });
    });
  });
}
