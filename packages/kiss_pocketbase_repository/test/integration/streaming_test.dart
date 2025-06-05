import 'package:test/test.dart';
import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';

import 'test_helpers.dart';
import 'test_data.dart';

void main() {
  group('Real-time Streaming', () {
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

    test('should stream single document changes', () async {
      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'Initial Name',
        age: 25,
        created: DateTime.now(),
      );

      final stream = repository.stream(userId);
      final streamFuture = stream.take(3).toList();

      await repository.add(IdentifiedObject(user.id, user));

      await repository.update(
        user.id,
        (current) => current.copyWith(name: 'Updated Name 1'),
      );
      await repository.update(
        user.id,
        (current) => current.copyWith(name: 'Updated Name 2', age: 30),
      );

      final emissions = await streamFuture.timeout(Duration(seconds: 15));

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

      await Future.delayed(Duration(milliseconds: 200));

      final user1 = TestUser(
        id: PocketBaseUtils.generateId(),
        name: 'User 1',
        age: 25,
        created: DateTime.now(),
      );
      await repository.add(IdentifiedObject(user1.id, user1));

      final user2 = TestUser(
        id: PocketBaseUtils.generateId(),
        name: 'User 2',
        age: 30,
        created: DateTime.now(),
      );
      await repository.add(IdentifiedObject(user2.id, user2));

      await repository.update(
        user1.id,
        (current) => current.copyWith(name: 'Updated User 1'),
      );

      final emissions = await streamFuture.timeout(Duration(seconds: 15));

      expect(emissions.length, 4);
      expect(emissions[0].length, 0);
      expect(emissions[1].length, 1);
      expect(emissions[1][0].name, 'User 1');
      expect(emissions[2].length, 2);
      expect(emissions[3].length, 2);
      expect(
        emissions[3].firstWhere((u) => u.id == user1.id).name,
        'Updated User 1',
      );
    });

    test('should handle multiple concurrent streams', () async {
      final user1Id = PocketBaseUtils.generateId();
      final user2Id = PocketBaseUtils.generateId();
      final user1 = TestUser(
        id: user1Id,
        name: 'User 1',
        age: 25,
        created: DateTime.now(),
      );
      final user2 = TestUser(
        id: user2Id,
        name: 'User 2',
        age: 30,
        created: DateTime.now(),
      );

      await repository.add(IdentifiedObject(user1.id, user1));
      await repository.add(IdentifiedObject(user2.id, user2));

      final stream1 = repository.stream(user1Id);
      final stream2 = repository.stream(user2Id);
      final queryStream = repository.streamQuery();

      final stream1Future = stream1.take(2).toList();
      final stream2Future = stream2.take(2).toList();
      final queryStreamFuture = queryStream.take(3).toList();

      await repository.update(
        user1.id,
        (current) => current.copyWith(name: 'Updated User 1'),
      );
      await repository.update(
        user2.id,
        (current) => current.copyWith(name: 'Updated User 2'),
      );

      final stream1Emissions = await stream1Future.timeout(
        Duration(seconds: 15),
      );
      final stream2Emissions = await stream2Future.timeout(
        Duration(seconds: 15),
      );
      final queryEmissions = await queryStreamFuture.timeout(
        Duration(seconds: 15),
      );

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
      final userId = PocketBaseUtils.generateId();
      final stream = repository.stream(userId);

      final user = TestUser(
        id: userId,
        name: 'Created Later',
        age: 25,
        created: DateTime.now(),
      );

      final streamFuture = stream.take(1).toList();

      await repository.add(IdentifiedObject(user.id, user));

      final emissions = await streamFuture.timeout(Duration(seconds: 15));

      expect(emissions.length, 1);
      expect(emissions[0].name, 'Created Later');
      expect(emissions[0].id, userId);
    });

    test('should stop emitting when document is deleted', () async {
      final userId = PocketBaseUtils.generateId();
      final user = TestUser(
        id: userId,
        name: 'To Be Deleted',
        age: 25,
        created: DateTime.now(),
      );

      await repository.add(IdentifiedObject(user.id, user));

      final stream = repository.stream(userId);
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

    test(
      'should emit initial data immediately on stream subscription',
      () async {
        final userId = PocketBaseUtils.generateId();
        final user = TestUser(
          id: userId,
          name: 'Immediate User',
          age: 25,
          created: DateTime.now(),
        );

        await repository.add(IdentifiedObject(user.id, user));

        final stream = repository.stream(userId);
        final firstEmission = await stream.first.timeout(Duration(seconds: 10));

        expect(firstEmission.name, 'Immediate User');
        expect(firstEmission.id, userId);
      },
    );

    test('should validate ID format in stream method', () async {
      expect(
        () => repository.stream('invalid_id'),
        throwsA(isA<RepositoryException>()),
      );

      expect(() => repository.stream(''), throwsA(isA<RepositoryException>()));

      expect(
        () => repository.stream('abc123def45678'), // 14 chars
        throwsA(isA<RepositoryException>()),
      );

      // Should not throw for valid ID
      final validId = PocketBaseUtils.generateId();
      expect(() => repository.stream(validId), returnsNormally);
    });
  });
}
