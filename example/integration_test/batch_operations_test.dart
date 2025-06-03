import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

import 'utils/test_data.dart';
import 'utils/test_helpers.dart';

void main() {
  IntegrationTestHelpers.setupIntegrationTest();

  group('Batch Operations', () {
    late Repository<TestUser> repository;

    setUpAll(() async {
      await IntegrationTestHelpers.initializeFirebase();
      repository = IntegrationTestHelpers.repository;
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();
    });

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
}
