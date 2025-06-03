import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
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
      firestore.FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

      // Create repository with query builder for all tests
      repository = RepositoryFirestore<TestUser>(
        path: 'test_users',
        fromFirestore: (ref, data) => TestUser.fromMap(data),
        toFirestore: (user) => user.toMap(),
        queryBuilder: TestUserQueryBuilder(),
      );
    });

    setUp(() async {
      // Clear collection before each test
      final collection = firestore.FirebaseFirestore.instance.collection('test_users');
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

    group('Query & Filtering', () {
      setUp(() async {
        // Clear collection and add test data for query tests
        final collection = firestore.FirebaseFirestore.instance.collection('test_users');
        final docs = await collection.get();
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }

        // Add diverse test data for querying
        final testUsers = [
          TestUser(id: 'alice', name: 'Alice Smith', age: 25, createdAt: DateTime.now().subtract(Duration(days: 5))),
          TestUser(id: 'bob', name: 'Bob Johnson', age: 30, createdAt: DateTime.now().subtract(Duration(days: 3))),
          TestUser(
            id: 'charlie',
            name: 'Charlie Brown',
            age: 35,
            createdAt: DateTime.now().subtract(Duration(days: 1)),
          ),
          TestUser(id: 'david', name: 'David Wilson', age: 20, createdAt: DateTime.now().subtract(Duration(days: 10))),
          TestUser(id: 'alice2', name: 'Alice Jones', age: 28, createdAt: DateTime.now().subtract(Duration(days: 2))),
        ];

        final identifiedUsers = testUsers.map((user) => IdentifiedObject(user.id, user)).toList();
        await repository.addAll(identifiedUsers);
      });

      test('should query all items with AllQuery (default)', () async {
        final allUsers = await repository.query();

        expect(allUsers.length, 5);

        // Should be ordered by createdAt descending (most recent first)
        expect(allUsers[0].name, 'Charlie Brown'); // 1 day ago
        expect(allUsers[1].name, 'Alice Jones'); // 2 days ago
        expect(allUsers[2].name, 'Bob Johnson'); // 3 days ago
        expect(allUsers[3].name, 'Alice Smith'); // 5 days ago
        expect(allUsers[4].name, 'David Wilson'); // 10 days ago
      });

      test('should return empty list when querying empty collection', () async {
        // Clear all data first
        final collection = firestore.FirebaseFirestore.instance.collection('test_users');
        final docs = await collection.get();
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }

        final emptyResults = await repository.query();
        expect(emptyResults, isEmpty);
      });

      test('should query by minimum age', () async {
        final adults = await repository.query(query: QueryByAge(30));

        expect(adults.length, 2);

        // Should be ordered by age ascending
        expect(adults[0].name, 'Bob Johnson'); // age 30
        expect(adults[0].age, 30);
        expect(adults[1].name, 'Charlie Brown'); // age 35
        expect(adults[1].age, 35);
      });

      test('should query by name prefix', () async {
        final aliceUsers = await repository.query(query: QueryByName('Alice'));

        expect(aliceUsers.length, 2);

        // Should be ordered by name
        final names = aliceUsers.map((u) => u.name).toList();
        expect(names, contains('Alice Smith'));
        expect(names, contains('Alice Jones'));

        // Should be in alphabetical order
        expect(aliceUsers[0].name, 'Alice Jones');
        expect(aliceUsers[1].name, 'Alice Smith');
      });

      test('should query recent users by days', () async {
        final recentUsers = await repository.query(query: QueryRecentUsers(4));

        expect(recentUsers.length, 3); // Alice Jones, Bob Johnson, Charlie Brown

        // Should be ordered by createdAt descending (most recent first)
        expect(recentUsers[0].name, 'Charlie Brown'); // 1 day ago
        expect(recentUsers[1].name, 'Alice Jones'); // 2 days ago
        expect(recentUsers[2].name, 'Bob Johnson'); // 3 days ago

        // Should not include users older than 4 days
        final names = recentUsers.map((u) => u.name).toList();
        expect(names, isNot(contains('Alice Smith'))); // 5 days ago
        expect(names, isNot(contains('David Wilson'))); // 10 days ago
      });

      test('should handle query with no results', () async {
        final noResults = await repository.query(query: QueryByAge(100));
        expect(noResults, isEmpty);
      });

      test('should query all items when using AllQuery explicitly', () async {
        final allUsers = await repository.query(query: AllQuery());
        expect(allUsers.length, 5);

        // Verify all expected users are present
        final names = allUsers.map((u) => u.name).toSet();
        expect(names, contains('Alice Smith'));
        expect(names, contains('Bob Johnson'));
        expect(names, contains('Charlie Brown'));
        expect(names, contains('David Wilson'));
        expect(names, contains('Alice Jones'));
      });
    });

    group('Real-time Streaming', () {
      test('should stream single document changes', () async {
        final user = TestUser(id: 'stream-user', name: 'Initial Name', age: 25, createdAt: DateTime.now());

        // Start streaming before the document exists
        final stream = repository.stream('stream-user');
        final streamFuture = stream.take(3).toList(); // Take first 3 emissions

        // Add the document
        await repository.add(IdentifiedObject(user.id, user));

        // Update the document twice
        await repository.update(user.id, (current) => current.copyWith(name: 'Updated Name 1'));
        await repository.update(user.id, (current) => current.copyWith(name: 'Updated Name 2', age: 30));

        // Wait for all stream emissions
        final emissions = await streamFuture.timeout(Duration(seconds: 10));

        expect(emissions.length, 3);
        expect(emissions[0].name, 'Initial Name');
        expect(emissions[0].age, 25);
        expect(emissions[1].name, 'Updated Name 1');
        expect(emissions[1].age, 25);
        expect(emissions[2].name, 'Updated Name 2');
        expect(emissions[2].age, 30);
      });

      test('should stream query results changes', () async {
        // Start streaming query results
        final stream = repository.streamQuery();
        final streamFuture = stream.take(4).toList(); // Take first 4 emissions

        // Initially empty
        await Future.delayed(Duration(milliseconds: 100));

        // Add users one by one
        final user1 = TestUser(id: 'stream1', name: 'User 1', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user1.id, user1));

        final user2 = TestUser(id: 'stream2', name: 'User 2', age: 30, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user2.id, user2));

        // Update one user
        await repository.update(user1.id, (current) => current.copyWith(name: 'Updated User 1'));

        // Wait for all emissions
        final emissions = await streamFuture.timeout(Duration(seconds: 10));

        expect(emissions.length, 4);
        expect(emissions[0].length, 0); // Initial empty state
        expect(emissions[1].length, 1); // After adding user1
        expect(emissions[1][0].name, 'User 1');
        expect(emissions[2].length, 2); // After adding user2
        expect(emissions[3].length, 2); // After updating user1
        expect(emissions[3].firstWhere((u) => u.id == 'stream1').name, 'Updated User 1');
      });

      test('should handle multiple concurrent streams', () async {
        final user1 = TestUser(id: 'concurrent1', name: 'User 1', age: 25, createdAt: DateTime.now());
        final user2 = TestUser(id: 'concurrent2', name: 'User 2', age: 30, createdAt: DateTime.now());

        // Add initial data
        await repository.add(IdentifiedObject(user1.id, user1));
        await repository.add(IdentifiedObject(user2.id, user2));

        // Start multiple streams
        final stream1 = repository.stream('concurrent1');
        final stream2 = repository.stream('concurrent2');
        final queryStream = repository.streamQuery();

        final stream1Future = stream1.take(2).toList();
        final stream2Future = stream2.take(2).toList();
        final queryStreamFuture = queryStream.take(3).toList();

        // Update both users
        await repository.update(user1.id, (current) => current.copyWith(name: 'Updated User 1'));
        await repository.update(user2.id, (current) => current.copyWith(name: 'Updated User 2'));

        // Wait for all streams
        final stream1Emissions = await stream1Future.timeout(Duration(seconds: 10));
        final stream2Emissions = await stream2Future.timeout(Duration(seconds: 10));
        final queryEmissions = await queryStreamFuture.timeout(Duration(seconds: 10));

        // Verify individual streams
        expect(stream1Emissions.length, 2);
        expect(stream1Emissions[0].name, 'User 1');
        expect(stream1Emissions[1].name, 'Updated User 1');

        expect(stream2Emissions.length, 2);
        expect(stream2Emissions[0].name, 'User 2');
        expect(stream2Emissions[1].name, 'Updated User 2');

        // Verify query stream saw all changes
        expect(queryEmissions.length, 3);
        expect(queryEmissions[0].length, 2); // Initial state
        expect(queryEmissions[2].length, 2); // After both updates
      });

      test('should handle streaming non-existent document', () async {
        // Stream a document that doesn't exist
        final stream = repository.stream('non-existent');

        // Create the document after starting the stream
        final user = TestUser(id: 'non-existent', name: 'Created Later', age: 25, createdAt: DateTime.now());

        final streamFuture = stream.take(1).toList();

        // Add the document
        await repository.add(IdentifiedObject(user.id, user));

        // Should receive the document once it's created
        final emissions = await streamFuture.timeout(Duration(seconds: 10));

        expect(emissions.length, 1);
        expect(emissions[0].name, 'Created Later');
        expect(emissions[0].id, 'non-existent');
      });

      test('should stream with custom queries', () async {
        // Add test data
        final users = [
          TestUser(id: 'young1', name: 'Young User 1', age: 20, createdAt: DateTime.now()),
          TestUser(id: 'adult1', name: 'Adult User 1', age: 30, createdAt: DateTime.now()),
          TestUser(id: 'adult2', name: 'Adult User 2', age: 35, createdAt: DateTime.now()),
        ];

        for (final user in users) {
          await repository.add(IdentifiedObject(user.id, user));
        }

        // Stream adults only (age >= 30)
        final adultStream = repository.streamQuery(query: QueryByAge(30));
        final streamFuture = adultStream.take(2).toList();

        // Add another adult
        final newAdult = TestUser(id: 'adult3', name: 'Adult User 3', age: 40, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(newAdult.id, newAdult));

        final emissions = await streamFuture.timeout(Duration(seconds: 10));

        expect(emissions.length, 2);
        expect(emissions[0].length, 2); // Initial: adult1, adult2
        expect(emissions[1].length, 3); // After adding: adult1, adult2, adult3

        // Verify only adults are included
        for (final emission in emissions) {
          for (final user in emission) {
            expect(user.age, greaterThanOrEqualTo(30));
          }
        }
      });

      test('should stop emitting when document is deleted', () async {
        final user = TestUser(id: 'delete-stream', name: 'To Be Deleted', age: 25, createdAt: DateTime.now());

        // Add the document
        await repository.add(IdentifiedObject(user.id, user));

        // Start streaming
        final stream = repository.stream('delete-stream');
        final emissions = <TestUser>[];

        final subscription = stream.listen((user) {
          emissions.add(user);
        });

        // Wait for initial emission
        await Future.delayed(Duration(milliseconds: 500));

        // Delete the document
        await repository.delete(user.id);

        // Wait a bit more to see if any more emissions occur
        await Future.delayed(Duration(milliseconds: 500));

        // Clean up subscription
        await subscription.cancel();

        // Should only have received the initial document, no emissions after deletion
        expect(emissions.length, 1);
        expect(emissions[0].name, 'To Be Deleted');
      });

      test('should emit initial data immediately on stream subscription', () async {
        final user = TestUser(id: 'immediate', name: 'Immediate User', age: 25, createdAt: DateTime.now());

        // Add document first
        await repository.add(IdentifiedObject(user.id, user));

        // Start streaming - should get immediate emission
        final stream = repository.stream('immediate');
        final firstEmission = await stream.first.timeout(Duration(seconds: 5));

        expect(firstEmission.name, 'Immediate User');
        expect(firstEmission.id, 'immediate');
      });
    });
  });
}
