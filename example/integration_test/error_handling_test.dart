import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'utils/test_data.dart';
import 'utils/test_helpers.dart';

void main() {
  IntegrationTestHelpers.setupIntegrationTest();

  group('Error Handling & Edge Cases', () {
    late Repository<TestUser> repository;

    setUpAll(() async {
      await IntegrationTestHelpers.initializeFirebase();
      repository = IntegrationTestHelpers.repository;
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();
    });

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
      expect(() => repository.update(user.id, (u) => u.copyWith(name: 'Updated')), throwsA(isA<RepositoryException>()));

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
}
