import 'package:test/test.dart';
import 'package:kiss_repository/kiss_repository.dart';

import 'test_helpers.dart';
import 'test_data.dart';

void main() {
  group('PocketBase Query & Filtering Tests', () {
    setUpAll(() async {
      await IntegrationTestHelpers.setupIntegrationTests();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationTests();
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();

      // Create test data
      final repository = IntegrationTestHelpers.repository;
      final testUsers = [
        TestUser.create(
          name: 'Alice Smith',
          age: 25,
          created: DateTime.now().subtract(const Duration(days: 5)),
        ),
        TestUser.create(
          name: 'Bob Johnson',
          age: 30,
          created: DateTime.now().subtract(const Duration(days: 3)),
        ),
        TestUser.create(
          name: 'Charlie Brown',
          age: 35,
          created: DateTime.now().subtract(const Duration(days: 1)),
        ),
        TestUser.create(
          name: 'David Wilson',
          age: 20,
          created: DateTime.now().subtract(const Duration(days: 10)),
        ),
        TestUser.create(
          name: 'Alice Jones',
          age: 28,
          created: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      // Add test users with delay to ensure proper creation times
      for (final user in testUsers) {
        await repository.addAutoIdentified(user);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });

    test('should query all items with AllQuery (default)', () async {
      final repository = IntegrationTestHelpers.repository;
      final allUsers = await repository.query();

      expect(allUsers.length, equals(5));

      // Results should be sorted by created descending (most recent first)
      // Based on our setup order: Charlie Brown (newest) should be first
      final names = allUsers.map((u) => u.name).toList();
      expect(names, contains('Alice Smith'));
      expect(names, contains('Bob Johnson'));
      expect(names, contains('Charlie Brown'));
      expect(names, contains('David Wilson'));
      expect(names, contains('Alice Jones'));

      print('✅ Query returned all records: $names');
    });

    test('should return empty list when querying empty collection', () async {
      await IntegrationTestHelpers.clearTestCollection();

      final repository = IntegrationTestHelpers.repository;
      final emptyResults = await repository.query();

      expect(emptyResults, isEmpty);
      print('✅ Empty query returned empty list');
    });

    test('should query all items when using AllQuery explicitly', () async {
      final repository = IntegrationTestHelpers.repository;
      final allUsers = await repository.query(query: const AllQuery());

      expect(allUsers.length, equals(5));

      final names = allUsers.map((u) => u.name).toSet();
      expect(names, contains('Alice Smith'));
      expect(names, contains('Bob Johnson'));
      expect(names, contains('Charlie Brown'));
      expect(names, contains('David Wilson'));
      expect(names, contains('Alice Jones'));

      print('✅ Explicit AllQuery returned all records');
    });

    test('should handle query with no custom query builder', () async {
      final repository = IntegrationTestHelpers.repository;

      // Try to use a custom query without a query builder
      // This should work for AllQuery but fail for custom queries

      // AllQuery should work fine
      final allResults = await repository.query(query: const AllQuery());
      expect(allResults.length, equals(5));

      print('✅ AllQuery works without custom query builder');

      // TODO: Add tests for custom queries when we implement a PocketBase query builder
    });
  });
}
