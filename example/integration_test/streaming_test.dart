import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

import 'utils/test_data.dart';
import 'utils/test_helpers.dart';

void main() {
  IntegrationTestHelpers.setupIntegrationTest();

  group('Real-time Streaming', () {
    late Repository<TestUser> repository;

    setUpAll(() async {
      await IntegrationTestHelpers.initializeFirebase();
      repository = IntegrationTestHelpers.repository;
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();
    });

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
}
