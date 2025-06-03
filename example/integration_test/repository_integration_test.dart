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
    });

    setUp(() async {
      final collection = firestore.FirebaseFirestore.instance.collection('test_users');
      final docs = await collection.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    });

    group('Basic CRUD Operations', () {
      test('should add, get, update, delete single item', () async {
        final user = TestUser(id: 'user1', name: 'John Doe', age: 30, createdAt: DateTime.now());

        final identifiedUser = IdentifiedObject(user.id, user);
        await repository.add(identifiedUser);

        final retrieved = await repository.get(user.id);
        expect(retrieved.id, user.id);
        expect(retrieved.name, user.name);
        expect(retrieved.age, user.age);

        await repository.update(user.id, (current) => current.copyWith(name: 'John Updated', age: 31));

        final afterUpdate = await repository.get(user.id);
        expect(afterUpdate.name, 'John Updated');
        expect(afterUpdate.age, 31);

        await repository.delete(user.id);

        expect(() => repository.get(user.id), throwsA(isA<RepositoryException>()));
      });

      test('should handle adding item with existing ID', () async {
        final user = TestUser(id: 'duplicate', name: 'First', age: 25, createdAt: DateTime.now());

        final identifiedUser = IdentifiedObject(user.id, user);
        await repository.add(identifiedUser);

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
        await repository.delete('non-existent-id');
      });
    });

    group('ID Management & Auto-Generation', () {
      test('should auto-generate IDs with autoIdentify', () async {
        final user = TestUser(id: '', name: 'Auto User', age: 25, createdAt: DateTime.now());

        final autoIdentified = repository.autoIdentify(
          user,
          updateObjectWithId: (user, generatedId) => user.copyWith(id: generatedId),
        );

        expect(autoIdentified.id, isNotEmpty);
        expect(autoIdentified.id.length, 20);
        expect(autoIdentified.object.name, 'Auto User');
        expect(autoIdentified.object.age, 25);
        expect(autoIdentified.object.id, autoIdentified.id);
      });

      test('should add items with auto-generated IDs using addAutoIdentified', () async {
        final user = TestUser(id: '', name: 'Auto Added User', age: 30, createdAt: DateTime.now());

        final addedUser = await repository.addAutoIdentified(
          user,
          updateObjectWithId: (user, generatedId) => user.copyWith(id: generatedId),
        );

        expect(addedUser.id, isNotEmpty);
        expect(addedUser.id.length, 20);
        expect(addedUser.name, 'Auto Added User');
        expect(addedUser.age, 30);

        final retrieved = await repository.get(addedUser.id);
        expect(retrieved.id, addedUser.id);
        expect(retrieved.name, 'Auto Added User');
      });

      test('should handle multiple auto-generated IDs being unique', () async {
        final users = List.generate(
          5,
          (i) => TestUser(id: '', name: 'User $i', age: 20 + i, createdAt: DateTime.now()),
        );

        final addedUsers = <TestUser>[];
        for (final user in users) {
          final added = await repository.addAutoIdentified(
            user,
            updateObjectWithId: (user, generatedId) => user.copyWith(id: generatedId),
          );
          addedUsers.add(added);
        }

        final ids = addedUsers.map((u) => u.id).toSet();
        expect(ids.length, 5);

        for (final user in addedUsers) {
          expect(user.id, isNotEmpty);
          expect(user.id.length, 20);
        }

        for (final user in addedUsers) {
          final retrieved = await repository.get(user.id);
          expect(retrieved.id, user.id);
          expect(retrieved.name, user.name);
        }
      });

      test('should work with autoIdentify then manual add', () async {
        final user = TestUser(id: '', name: 'Manual Add User', age: 40, createdAt: DateTime.now());

        final autoIdentified = repository.autoIdentify(user, updateObjectWithId: (user, id) => user.copyWith(id: id));

        final addedUser = await repository.add(autoIdentified);

        expect(addedUser.id, isNotEmpty);
        expect(addedUser.id.length, 20);
        expect(addedUser.name, 'Manual Add User');

        final retrieved = await repository.get(addedUser.id);
        expect(retrieved.id, addedUser.id);
        expect(retrieved.name, 'Manual Add User');
      });

      test('should handle autoIdentify without updateObjectWithId (default behavior)', () async {
        final user = TestUser(id: 'original-id', name: 'Default User', age: 45, createdAt: DateTime.now());

        final autoIdentified = repository.autoIdentify(user);

        expect(autoIdentified.id, isNotEmpty);
        expect(autoIdentified.id.length, 20);
        expect(autoIdentified.id, isNot('original-id'));

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

        final addedUsers = await repository.addAll(identifiedUsers);

        final addedUsersList = addedUsers.toList();

        expect(addedUsersList.length, 3);
        for (int i = 0; i < users.length; i++) {
          expect(addedUsersList[i].id, users[i].id);
          expect(addedUsersList[i].name, users[i].name);
          expect(addedUsersList[i].age, users[i].age);

          final retrieved = await repository.get(users[i].id);
          expect(retrieved.id, users[i].id);
          expect(retrieved.name, users[i].name);
        }
      });

      test('should update multiple items with updateAll', () async {
        final users = [
          TestUser(id: 'update1', name: 'Update User 1', age: 20, createdAt: DateTime.now()),
          TestUser(id: 'update2', name: 'Update User 2', age: 25, createdAt: DateTime.now()),
          TestUser(id: 'update3', name: 'Update User 3', age: 30, createdAt: DateTime.now()),
        ];

        final identifiedUsers = users.map((user) => IdentifiedObject(user.id, user)).toList();
        await repository.addAll(identifiedUsers);

        final updatedUserObjects = users.map((user) => user.copyWith(age: user.age + 10)).toList();
        final identifiedUpdates = updatedUserObjects.map((user) => IdentifiedObject(user.id, user)).toList();

        final updatedUsers = await repository.updateAll(identifiedUpdates);

        final updatedUsersList = updatedUsers.toList();

        expect(updatedUsersList.length, 3);
        for (int i = 0; i < users.length; i++) {
          expect(updatedUsersList[i].id, users[i].id);
          expect(updatedUsersList[i].name, users[i].name);
          expect(updatedUsersList[i].age, users[i].age + 10);

          final retrieved = await repository.get(users[i].id);
          expect(retrieved.age, users[i].age + 10);
        }
      });

      test('should delete multiple items with deleteAll', () async {
        final users = [
          TestUser(id: 'delete1', name: 'Delete User 1', age: 40, createdAt: DateTime.now()),
          TestUser(id: 'delete2', name: 'Delete User 2', age: 45, createdAt: DateTime.now()),
          TestUser(id: 'delete3', name: 'Delete User 3', age: 50, createdAt: DateTime.now()),
        ];

        final identifiedUsers = users.map((user) => IdentifiedObject(user.id, user)).toList();
        await repository.addAll(identifiedUsers);

        for (final user in users) {
          final retrieved = await repository.get(user.id);
          expect(retrieved.id, user.id);
        }

        final deleteIds = users.map((user) => user.id).toList();
        await repository.deleteAll(deleteIds);

        for (final user in users) {
          expect(() => repository.get(user.id), throwsA(isA<RepositoryException>()));
        }
      });

      test('should handle batch operations with some failures', () async {
        final existingUser = TestUser(id: 'existing', name: 'Existing User', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(existingUser.id, existingUser));

        final batchUsers = [
          TestUser(id: 'new1', name: 'New User 1', age: 30, createdAt: DateTime.now()),
          TestUser(id: 'existing', name: 'Duplicate User', age: 35, createdAt: DateTime.now()),
          TestUser(id: 'new2', name: 'New User 2', age: 40, createdAt: DateTime.now()),
        ];

        final identifiedBatch = batchUsers.map((user) => IdentifiedObject(user.id, user)).toList();

        expect(() => repository.addAll(identifiedBatch), throwsA(isA<RepositoryException>()));

        expect(() => repository.get('new1'), throwsA(isA<RepositoryException>()));
        expect(() => repository.get('new2'), throwsA(isA<RepositoryException>()));

        final retrieved = await repository.get('existing');
        expect(retrieved.name, 'Existing User');
        expect(retrieved.age, 25);
      });

      test('should handle empty batch operations', () async {
        final emptyAddResult = await repository.addAll(<IdentifiedObject<TestUser>>[]);
        expect(emptyAddResult, isEmpty);

        final emptyUpdateResult = await repository.updateAll(<IdentifiedObject<TestUser>>[]);
        expect(emptyUpdateResult, isEmpty);

        await repository.deleteAll(<String>[]);
      });
    });

    group('Query & Filtering', () {
      setUp(() async {
        final collection = firestore.FirebaseFirestore.instance.collection('test_users');
        final docs = await collection.get();
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }

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

        expect(allUsers[0].name, 'Charlie Brown');
        expect(allUsers[1].name, 'Alice Jones');
        expect(allUsers[2].name, 'Bob Johnson');
        expect(allUsers[3].name, 'Alice Smith');
        expect(allUsers[4].name, 'David Wilson');
      });

      test('should return empty list when querying empty collection', () async {
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

        expect(adults[0].name, 'Bob Johnson');
        expect(adults[0].age, 30);
        expect(adults[1].name, 'Charlie Brown');
        expect(adults[1].age, 35);
      });

      test('should query by name prefix', () async {
        final aliceUsers = await repository.query(query: QueryByName('Alice'));

        expect(aliceUsers.length, 2);

        final names = aliceUsers.map((u) => u.name).toList();
        expect(names, contains('Alice Smith'));
        expect(names, contains('Alice Jones'));

        expect(aliceUsers[0].name, 'Alice Jones');
        expect(aliceUsers[1].name, 'Alice Smith');
      });

      test('should query recent users by days', () async {
        final recentUsers = await repository.query(query: QueryRecentUsers(4));

        expect(recentUsers.length, 3);

        expect(recentUsers[0].name, 'Charlie Brown');
        expect(recentUsers[1].name, 'Alice Jones');
        expect(recentUsers[2].name, 'Bob Johnson');

        final names = recentUsers.map((u) => u.name).toList();
        expect(names, isNot(contains('Alice Smith')));
        expect(names, isNot(contains('David Wilson')));
      });

      test('should handle query with no results', () async {
        final noResults = await repository.query(query: QueryByAge(100));
        expect(noResults, isEmpty);
      });

      test('should query all items when using AllQuery explicitly', () async {
        final allUsers = await repository.query(query: AllQuery());
        expect(allUsers.length, 5);

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

        final stream = repository.stream('stream-user');
        final streamFuture = stream.take(3).toList();

        await repository.add(IdentifiedObject(user.id, user));

        await repository.update(user.id, (current) => current.copyWith(name: 'Updated Name 1'));
        await repository.update(user.id, (current) => current.copyWith(name: 'Updated Name 2', age: 30));

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
        final stream = repository.streamQuery();
        final streamFuture = stream.take(4).toList();

        await Future.delayed(Duration(milliseconds: 100));

        final user1 = TestUser(id: 'stream1', name: 'User 1', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user1.id, user1));

        final user2 = TestUser(id: 'stream2', name: 'User 2', age: 30, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user2.id, user2));

        await repository.update(user1.id, (current) => current.copyWith(name: 'Updated User 1'));

        final emissions = await streamFuture.timeout(Duration(seconds: 10));

        expect(emissions.length, 4);
        expect(emissions[0].length, 0);
        expect(emissions[1].length, 1);
        expect(emissions[1][0].name, 'User 1');
        expect(emissions[2].length, 2);
        expect(emissions[3].length, 2);
        expect(emissions[3].firstWhere((u) => u.id == 'stream1').name, 'Updated User 1');
      });

      test('should handle multiple concurrent streams', () async {
        final user1 = TestUser(id: 'concurrent1', name: 'User 1', age: 25, createdAt: DateTime.now());
        final user2 = TestUser(id: 'concurrent2', name: 'User 2', age: 30, createdAt: DateTime.now());

        await repository.add(IdentifiedObject(user1.id, user1));
        await repository.add(IdentifiedObject(user2.id, user2));

        final stream1 = repository.stream('concurrent1');
        final stream2 = repository.stream('concurrent2');
        final queryStream = repository.streamQuery();

        final stream1Future = stream1.take(2).toList();
        final stream2Future = stream2.take(2).toList();
        final queryStreamFuture = queryStream.take(3).toList();

        await repository.update(user1.id, (current) => current.copyWith(name: 'Updated User 1'));
        await repository.update(user2.id, (current) => current.copyWith(name: 'Updated User 2'));

        final stream1Emissions = await stream1Future.timeout(Duration(seconds: 10));
        final stream2Emissions = await stream2Future.timeout(Duration(seconds: 10));
        final queryEmissions = await queryStreamFuture.timeout(Duration(seconds: 10));

        expect(stream1Emissions.length, 2);
        expect(stream1Emissions[0].name, 'User 1');
        expect(stream1Emissions[1].name, 'Updated User 1');

        expect(stream2Emissions.length, 2);
        expect(stream2Emissions[0].name, 'User 2');
        expect(stream2Emissions[1].name, 'Updated User 2');

        expect(queryEmissions.length, 3);
        expect(queryEmissions[0].length, 2);
        expect(queryEmissions[2].length, 2);
      });

      test('should handle streaming non-existent document', () async {
        final stream = repository.stream('non-existent');

        final user = TestUser(id: 'non-existent', name: 'Created Later', age: 25, createdAt: DateTime.now());

        final streamFuture = stream.take(1).toList();

        await repository.add(IdentifiedObject(user.id, user));

        final emissions = await streamFuture.timeout(Duration(seconds: 10));

        expect(emissions.length, 1);
        expect(emissions[0].name, 'Created Later');
        expect(emissions[0].id, 'non-existent');
      });

      test('should stream with custom queries', () async {
        final users = [
          TestUser(id: 'young1', name: 'Young User 1', age: 20, createdAt: DateTime.now()),
          TestUser(id: 'adult1', name: 'Adult User 1', age: 30, createdAt: DateTime.now()),
          TestUser(id: 'adult2', name: 'Adult User 2', age: 35, createdAt: DateTime.now()),
        ];

        for (final user in users) {
          await repository.add(IdentifiedObject(user.id, user));
        }

        final adultStream = repository.streamQuery(query: QueryByAge(30));
        final streamFuture = adultStream.take(2).toList();

        final newAdult = TestUser(id: 'adult3', name: 'Adult User 3', age: 40, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(newAdult.id, newAdult));

        final emissions = await streamFuture.timeout(Duration(seconds: 10));

        expect(emissions.length, 2);
        expect(emissions[0].length, 2);
        expect(emissions[1].length, 3);

        for (final emission in emissions) {
          for (final user in emission) {
            expect(user.age, greaterThanOrEqualTo(30));
          }
        }
      });

      test('should stop emitting when document is deleted', () async {
        final user = TestUser(id: 'delete-stream', name: 'To Be Deleted', age: 25, createdAt: DateTime.now());

        await repository.add(IdentifiedObject(user.id, user));

        final stream = repository.stream('delete-stream');
        final emissions = <TestUser>[];

        final subscription = stream.listen((user) {
          emissions.add(user);
        });

        await Future.delayed(Duration(milliseconds: 500));

        await repository.delete(user.id);

        await Future.delayed(Duration(milliseconds: 500));

        await subscription.cancel();

        expect(emissions.length, 1);
        expect(emissions[0].name, 'To Be Deleted');
      });

      test('should emit initial data immediately on stream subscription', () async {
        final user = TestUser(id: 'immediate', name: 'Immediate User', age: 25, createdAt: DateTime.now());

        await repository.add(IdentifiedObject(user.id, user));

        final stream = repository.stream('immediate');
        final firstEmission = await stream.first.timeout(Duration(seconds: 5));

        expect(firstEmission.name, 'Immediate User');
        expect(firstEmission.id, 'immediate');
      });
    });

    group('Error Handling & Edge Cases', () {
      test('should throw TypeError when reading data with incorrect field types', () async {
        final user = TestUser(id: 'malformed-test', name: 'Valid User', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user.id, user));

        final doc = firestore.FirebaseFirestore.instance.doc('test_users/malformed-test');
        await doc.update({'age': 'not_a_number'});

        expect(() => repository.get('malformed-test'), throwsA(isA<TypeError>()));
      });

      test('should handle concurrent modifications', () async {
        final user = TestUser(id: 'concurrent-mod', name: 'Original', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user.id, user));

        final futures = [
          repository.update(user.id, (current) => current.copyWith(name: 'Update 1')),
          repository.update(user.id, (current) => current.copyWith(name: 'Update 2')),
          repository.update(user.id, (current) => current.copyWith(name: 'Update 3')),
        ];

        final results = await Future.wait(futures);
        expect(results.length, 3);

        final finalUser = await repository.get(user.id);
        expect(['Update 1', 'Update 2', 'Update 3'], contains(finalUser.name));
      });

      test('should handle repository disposal', () async {
        final user = TestUser(id: 'disposal-test', name: 'Test User', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user.id, user));

        repository.dispose();

        final retrieved = await repository.get('disposal-test');
        expect(retrieved.name, 'Test User');
      });

      test('should handle very large batch operations', () async {
        final users = List.generate(
          50,
          (i) => TestUser(
            id: 'batch-large-$i',
            name: 'User $i',
            age: 20 + (i % 30),
            createdAt: DateTime.now().subtract(Duration(days: i)),
          ),
        );

        final identifiedUsers = users.map((user) => IdentifiedObject(user.id, user)).toList();

        final addedUsers = await repository.addAll(identifiedUsers);
        expect(addedUsers.length, 50);

        final retrieved1 = await repository.get('batch-large-0');
        final retrieved25 = await repository.get('batch-large-25');
        final retrieved49 = await repository.get('batch-large-49');

        expect(retrieved1.name, 'User 0');
        expect(retrieved25.name, 'User 25');
        expect(retrieved49.name, 'User 49');

        final ids = users.map((user) => user.id).toList();
        await repository.deleteAll(ids);
      });

      test('should handle invalid query gracefully', () async {
        final invalidQueryRepo = RepositoryFirestore<TestUser>(
          path: 'test_users',
          fromFirestore: (ref, data) => TestUser.fromMap(data),
          toFirestore: (user) => user.toMap(),
          queryBuilder: TestUserQueryBuilder(),
        );

        final emptyResult = await invalidQueryRepo.query(query: QueryByAge(-1));
        expect(emptyResult, isEmpty);

        final extremeAgeResult = await invalidQueryRepo.query(query: QueryByAge(1000));
        expect(extremeAgeResult, isEmpty);
      });

      test('should handle stream errors gracefully', () async {
        final user = TestUser(id: 'stream-error', name: 'Stream User', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user.id, user));

        final stream = repository.stream('stream-error');
        final emissions = <TestUser>[];
        final errors = <dynamic>[];

        final subscription = stream.listen((user) => emissions.add(user), onError: (error) => errors.add(error));

        await Future.delayed(Duration(milliseconds: 500));

        await repository.delete(user.id);

        await Future.delayed(Duration(milliseconds: 500));

        await subscription.cancel();

        expect(emissions.length, 1);
        expect(errors.length, 0);
      });

      test('should handle empty string IDs appropriately', () async {
        final userWithEmptyId = TestUser(id: '', name: 'Empty ID User', age: 25, createdAt: DateTime.now());

        expect(() => repository.add(IdentifiedObject('', userWithEmptyId)), throwsA(isA<ArgumentError>()));
      });

      test('should handle special characters in IDs', () async {
        final specialIds = ['user-with-dashes', 'user_with_underscores', 'user.with.dots', 'user123numbers'];

        for (final id in specialIds) {
          final user = TestUser(id: id, name: 'Special User', age: 25, createdAt: DateTime.now());
          await repository.add(IdentifiedObject(id, user));

          final retrieved = await repository.get(id);
          expect(retrieved.id, id);
          expect(retrieved.name, 'Special User');
        }

        await repository.deleteAll(specialIds);
      });

      test('should handle operations on deleted documents', () async {
        final user = TestUser(id: 'delete-ops', name: 'To Be Deleted', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user.id, user));

        await repository.delete(user.id);

        expect(() => repository.get(user.id), throwsA(isA<RepositoryException>()));
        expect(
          () => repository.update(user.id, (u) => u.copyWith(name: 'Updated')),
          throwsA(isA<RepositoryException>()),
        );

        await repository.delete(user.id);
      });

      test('should handle rapid consecutive operations', () async {
        final user = TestUser(id: 'rapid-ops', name: 'Rapid User', age: 25, createdAt: DateTime.now());
        await repository.add(IdentifiedObject(user.id, user));

        for (int i = 0; i < 10; i++) {
          await repository.update(user.id, (current) => current.copyWith(name: 'Update $i'));
        }

        final finalUser = await repository.get(user.id);
        expect(finalUser.name, 'Update 9');
      });
    });
  });
}
