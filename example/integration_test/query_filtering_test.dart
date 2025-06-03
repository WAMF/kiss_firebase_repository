import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'utils/test_data.dart';
import 'utils/test_helpers.dart';

void main() {
  IntegrationTestHelpers.setupIntegrationTest();

  group('Query & Filtering', () {
    late Repository<TestUser> repository;

    setUpAll(() async {
      await IntegrationTestHelpers.initializeFirebase();
      repository = IntegrationTestHelpers.repository;
    });

    setUp(() async {
      final collection = firestore.FirebaseFirestore.instance.collection('test_users');
      final docs = await collection.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }

      final testUsers = [
        TestUser(id: 'alice', name: 'Alice Smith', age: 25, createdAt: DateTime.now().subtract(Duration(days: 5))),
        TestUser(id: 'bob', name: 'Bob Johnson', age: 30, createdAt: DateTime.now().subtract(Duration(days: 3))),
        TestUser(id: 'charlie', name: 'Charlie Brown', age: 35, createdAt: DateTime.now().subtract(Duration(days: 1))),
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
}
