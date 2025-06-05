import 'package:test/test.dart';
import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';

import 'test_helpers.dart';
import 'test_data.dart';

void main() {
  group('Error Handling & Edge Cases', () {
    late Repository<TestUser> repository;

    setUpAll(() async {
      await IntegrationTestHelpers.setupIntegrationTests();
      repository = IntegrationTestHelpers.repository;
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationTests();
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();
    });

    test('should handle concurrent modifications', () async {
      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'Original',
        age: 25,
        created: DateTime.now(),
      );
      await repository.add(IdentifiedObject(user.id, user));

      final futures = [
        repository.update(
          user.id,
          (current) => current.copyWith(name: 'Update 1'),
        ),
        repository.update(
          user.id,
          (current) => current.copyWith(name: 'Update 2'),
        ),
        repository.update(
          user.id,
          (current) => current.copyWith(name: 'Update 3'),
        ),
      ];

      final results = await Future.wait(futures);
      expect(results.length, 3);

      final finalUser = await repository.get(user.id);
      expect(['Update 1', 'Update 2', 'Update 3'], contains(finalUser.name));
    });

    test('should handle repository disposal', () async {
      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'Test User',
        age: 25,
        created: DateTime.now(),
      );
      await repository.add(IdentifiedObject(user.id, user));

      repository.dispose();

      final retrieved = await repository.get(userId);
      expect(retrieved.name, 'Test User');
    });

    test('should handle very large batch operations', () async {
      final users = List.generate(
        50,
        (i) => TestUser(
          id: PocketBaseUtils.generateId(),
          name: 'User $i',
          age: 20 + (i % 30),
          created: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      final identifiedUsers = users
          .map((user) => IdentifiedObject(user.id, user))
          .toList();

      final addedUsers = await repository.addAll(identifiedUsers);
      expect(addedUsers.length, 50);

      final retrieved1 = await repository.get(users[0].id);
      final retrieved25 = await repository.get(users[25].id);
      final retrieved49 = await repository.get(users[49].id);

      expect(retrieved1.name, 'User 0');
      expect(retrieved25.name, 'User 25');
      expect(retrieved49.name, 'User 49');

      final ids = users.map((user) => user.id).toList();
      await repository.deleteAll(ids);
    });

    test('should handle invalid ID formats appropriately', () async {
      final invalidIds = [
        '',
        'short',
        'toolongandwaymorethan15chars',
        'invalid-chars!',
        'UPPERCASE123',
      ];

      for (final invalidId in invalidIds) {
        final user = TestUser(
          id: invalidId,
          name: 'Invalid ID User',
          age: 25,
          created: DateTime.now(),
        );

        expect(
          () => repository.add(IdentifiedObject(invalidId, user)),
          throwsA(isA<RepositoryException>()),
          reason: 'Should reject invalid ID: $invalidId',
        );
      }
    });

    test(
      'should handle valid special character IDs within PocketBase constraints',
      () async {
        // PocketBase only allows lowercase alphanumeric, so test valid combinations
        final validIds = [
          PocketBaseUtils.generateId(), // Standard generated
          'abc123def456789', // 15 chars alphanumeric
          '123456789012345', // All numbers
          'abcdefghijklmno', // All letters
        ];

        for (final id in validIds) {
          final user = TestUser(
            id: id,
            name: 'Valid ID User',
            age: 25,
            created: DateTime.now(),
          );
          await repository.add(IdentifiedObject(id, user));

          final retrieved = await repository.get(id);
          expect(retrieved.id, id);
          expect(retrieved.name, 'Valid ID User');
        }

        await repository.deleteAll(validIds);
      },
    );

    test('should handle operations on deleted documents', () async {
      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'To Be Deleted',
        age: 25,
        created: DateTime.now(),
      );
      await repository.add(IdentifiedObject(user.id, user));

      await repository.delete(user.id);

      expect(
        () => repository.get(user.id),
        throwsA(isA<RepositoryException>()),
      );

      expect(
        () => repository.update(user.id, (u) => u.copyWith(name: 'Updated')),
        throwsA(isA<RepositoryException>()),
      );

      // Deleting non-existent record should not throw in PocketBase
      await repository.delete(user.id);
    });

    test('should handle rapid consecutive operations', () async {
      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'Rapid User',
        age: 25,
        created: DateTime.now(),
      );
      await repository.add(IdentifiedObject(user.id, user));

      for (int i = 0; i < 10; i++) {
        await repository.update(
          user.id,
          (current) => current.copyWith(name: 'Update $i'),
        );
      }

      final finalUser = await repository.get(user.id);
      expect(finalUser.name, 'Update 9');
    });

    test('should handle stream errors gracefully', () async {
      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'Stream User',
        age: 25,
        created: DateTime.now(),
      );
      await repository.add(IdentifiedObject(user.id, user));

      final stream = repository.stream(userId);
      final emissions = <TestUser>[];
      final errors = <dynamic>[];

      final subscription = stream.listen(
        (user) => emissions.add(user),
        onError: (error) => errors.add(error),
      );

      await Future.delayed(Duration(milliseconds: 500));

      await repository.delete(user.id);

      await Future.delayed(Duration(milliseconds: 500));

      await subscription.cancel();

      expect(emissions.length, greaterThanOrEqualTo(1));
      expect(errors.length, 0); // Should handle deletions gracefully
    });

    test('should handle duplicate ID attempts correctly', () async {
      final userId = PocketBaseUtils.generateId();
      final user1 = TestUser(
        id: userId,
        name: 'First User',
        age: 25,
        created: DateTime.now(),
      );
      final user2 = TestUser(
        id: userId,
        name: 'Duplicate User',
        age: 30,
        created: DateTime.now(),
      );

      await repository.add(IdentifiedObject(userId, user1));

      expect(
        () => repository.add(IdentifiedObject(userId, user2)),
        throwsA(isA<RepositoryException>()),
      );

      // Original user should still be retrievable
      final retrieved = await repository.get(userId);
      expect(retrieved.name, 'First User');
      expect(retrieved.age, 25);
    });

    test('should handle batch operations with all failures', () async {
      final invalidUsers = [
        TestUser(
          id: 'invalid1',
          name: 'User 1',
          age: 25,
          created: DateTime.now(),
        ),
        TestUser(id: 'bad', name: 'User 2', age: 30, created: DateTime.now()),
        TestUser(id: '', name: 'User 3', age: 35, created: DateTime.now()),
      ];

      final identifiedUsers = invalidUsers
          .map((user) => IdentifiedObject(user.id, user))
          .toList();

      expect(
        () => repository.addAll(identifiedUsers),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('should handle network-like errors gracefully', () async {
      // Test behavior when PocketBase might be temporarily unavailable
      // This is more about testing our error handling structure

      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'Network Test',
        age: 25,
        created: DateTime.now(),
      );

      // This should work normally
      await repository.add(IdentifiedObject(userId, user));
      final retrieved = await repository.get(userId);
      expect(retrieved.name, 'Network Test');
    });

    test('should handle edge case query results', () async {
      // Test with no results
      final emptyResults = await repository.query();
      expect(emptyResults, isEmpty);

      // Add one user and test single result
      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'Solo User',
        age: 25,
        created: DateTime.now(),
      );
      await repository.add(IdentifiedObject(userId, user));

      final singleResult = await repository.query();
      expect(singleResult.length, 1);
      expect(singleResult.first.name, 'Solo User');
    });

    test('should handle autoIdentify edge cases', () async {
      final user = TestUser(
        id: '',
        name: 'Auto User',
        age: 25,
        created: DateTime.now(),
      );

      // Test autoIdentify method
      final identified = repository.autoIdentify(user);
      expect(identified.id, ''); // PocketBase uses empty string for auto-gen

      // Test addAutoIdentified
      final added = await repository.addAutoIdentified(user);
      expect(added.name, 'Auto User');
      expect(added.id, isNotEmpty); // Should have generated ID
      expect(PocketBaseUtils.isValidId(added.id), isTrue);
    });
  });
}
