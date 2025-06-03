import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

import 'utils/test_data.dart';
import 'utils/test_helpers.dart';

void main() {
  IntegrationTestHelpers.setupIntegrationTest();

  group('Basic CRUD Operations', () {
    late Repository<TestUser> repository;

    setUpAll(() async {
      await IntegrationTestHelpers.initializeFirebase();
      repository = IntegrationTestHelpers.repository;
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();
    });

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
}
