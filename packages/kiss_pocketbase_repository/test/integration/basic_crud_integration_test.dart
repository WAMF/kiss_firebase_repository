import 'package:test/test.dart';
import 'package:kiss_repository/kiss_repository.dart';

import 'test_helpers.dart';
import 'test_data.dart';

void main() {
  group('PocketBase Repository Integration Tests', () {
    setUpAll(() async {
      await IntegrationTestHelpers.setupIntegrationTests();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationTests();
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();
    });

    test('should perform complete CRUD lifecycle', () async {
      final repository = IntegrationTestHelpers.repository;

      // Create test user
      final testUser = TestUser.create(
        name: 'John Doe',
        age: 30,
        created: DateTime.now(),
      );

      // CREATE: Add user using auto-identified method
      final createdUser = await repository.addAutoIdentified(
        testUser,
        updateObjectWithId: (object, id) => object.copyWith(id: id),
      );
      expect(createdUser.id, isNotEmpty);
      expect(createdUser.name, equals('John Doe'));
      expect(createdUser.age, equals(30));
      print('✅ Created user: ${createdUser.id}');

      // READ: Get user by ID
      final retrievedUser = await repository.get(createdUser.id);
      expect(retrievedUser.id, equals(createdUser.id));
      expect(retrievedUser.name, equals('John Doe'));
      print('✅ Retrieved user: ${retrievedUser.id}');

      // UPDATE: Modify user
      final savedUser = await repository.update(
        createdUser.id,
        (current) => current.copyWith(name: 'Jane Doe', age: 25),
      );
      expect(savedUser.name, equals('Jane Doe'));
      expect(savedUser.age, equals(25));
      expect(savedUser.id, equals(createdUser.id)); // ID should remain same
      print('✅ Updated user: ${savedUser.id}');

      // DELETE: Remove user
      await repository.delete(savedUser.id);
      print('✅ Deleted user: ${savedUser.id}');

      // Verify deletion
      expect(
        () => repository.get(savedUser.id),
        throwsA(isA<RepositoryException>()),
      );
      print('✅ Verified deletion');
    });

    test('should handle non-existent records gracefully', () async {
      final repository = IntegrationTestHelpers.repository;

      expect(
        () => repository.get('non_existent_id'),
        throwsA(isA<RepositoryException>()),
      );

      expect(
        () => repository.update(
          'non_existent_id',
          (current) => current.copyWith(name: 'Updated'),
        ),
        throwsA(isA<RepositoryException>()),
      );

      expect(
        () => repository.delete('non_existent_id'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('should handle multiple sequential operations', () async {
      final repository = IntegrationTestHelpers.repository;

      final users = [
        TestUser.create(name: 'User 1', age: 20, created: DateTime.now()),
        TestUser.create(name: 'User 2', age: 25, created: DateTime.now()),
        TestUser.create(name: 'User 3', age: 30, created: DateTime.now()),
      ];

      final createdUsers = <TestUser>[];
      for (final user in users) {
        final created = await repository.addAutoIdentified(user);
        createdUsers.add(created);
        expect(created.id, isNotEmpty);
      }

      print('✅ Created ${createdUsers.length} users');

      for (final user in createdUsers) {
        final retrieved = await repository.get(user.id);
        expect(retrieved.id, equals(user.id));
      }

      print('✅ Retrieved all users successfully');

      for (final user in createdUsers) {
        await repository.delete(user.id);
      }

      print('✅ Cleaned up all test users');
    });
  });
}
