import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

import 'utils/test_data.dart';
import 'utils/test_helpers.dart';

void main() {
  IntegrationTestHelpers.setupIntegrationTest();

  group('ID Management & Auto-Generation', () {
    late Repository<TestUser> repository;

    setUpAll(() async {
      await IntegrationTestHelpers.initializeFirebase();
      repository = IntegrationTestHelpers.repository;
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();
    });

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
      final users = List.generate(5, (i) => TestUser(id: '', name: 'User $i', age: 20 + i, createdAt: DateTime.now()));

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
}
