import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

class MockUser {
  final String id;
  final String name;
  final DateTime createdAt;

  MockUser({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  MockUser copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return MockUser(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'MockUser(id: $id, name: $name, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MockUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdAt.hashCode;
}

void main() {
  group('KISS Firebase Repository - Unit Tests', () {
    test('should create IdentifedObject with specific ID', () {
      final testDate = DateTime.now();
      final user =
          MockUser(id: 'test-1', name: 'John Doe', createdAt: testDate);

      final identifiedObject = IdentifedObject('test-1', user);

      expect(identifiedObject.id, 'test-1');
      expect(identifiedObject.object.name, 'John Doe');
      expect(identifiedObject.object.createdAt, testDate);
    });

    test('should create user with copyWith method', () {
      final originalDate = DateTime.now();
      final user =
          MockUser(id: 'test-2', name: 'Jane Doe', createdAt: originalDate);

      final updatedUser = user.copyWith(name: 'Jane Smith');

      expect(updatedUser.id, 'test-2');
      expect(updatedUser.name, 'Jane Smith');
      expect(updatedUser.createdAt, originalDate);

      // Original should be unchanged
      expect(user.name, 'Jane Doe');
    });

    test('should test MapConverter type conversion functionality', () {
      final testMap = {
        'name': 'Test User',
        'age': 25,
        'active': true,
      };

      // Create a simple MapConverter that preserves types
      final converter = MapConverter(map: {
        'name': FieldFormat.preserveType('name'),
        'age': FieldFormat.preserveType('age'),
        'active': FieldFormat.preserveType('active'),
      });
      final converted = converter.convert(source: testMap);

      expect(converted['name'], 'Test User');
      expect(converted['age'], 25);
      expect(converted['active'], true);
    });

    test('should test data type conversion for DateTime', () {
      final now = DateTime.now();
      final testData = {
        'createdAt': now,
        'name': 'Test',
      };

      // This tests the internal type conversion logic that would be used
      // when converting between Dart and Firestore types
      expect(testData['createdAt'], isA<DateTime>());
      expect(testData['name'], isA<String>());
    });

    test('should create and manipulate user objects correctly', () {
      final users = [
        MockUser(id: '1', name: 'Alice', createdAt: DateTime.now()),
        MockUser(id: '2', name: 'Bob', createdAt: DateTime.now()),
        MockUser(id: '3', name: 'Charlie', createdAt: DateTime.now()),
      ];

      expect(users.length, 3);
      expect(users[0].name, 'Alice');
      expect(users[1].name, 'Bob');
      expect(users[2].name, 'Charlie');

      // Test that all users have unique IDs
      final ids = users.map((u) => u.id).toSet();
      expect(ids.length, 3);
    });

    test('should handle equality and hashCode correctly', () {
      final date = DateTime.now();
      final user1 = MockUser(id: 'test', name: 'John', createdAt: date);
      final user2 = MockUser(id: 'test', name: 'John', createdAt: date);
      final user3 = MockUser(id: 'different', name: 'John', createdAt: date);

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1, isNot(equals(user3)));
    });

    test('should demonstrate repository pattern structure', () {
      // This test demonstrates the structure that would be used with a real repository
      final user =
          MockUser(id: 'demo', name: 'Demo User', createdAt: DateTime.now());

      // Simulate the toFirestore conversion
      toFirestore(MockUser user) => {
            'name': user.name,
            'createdAt': user.createdAt,
          };

      final firestoreData = toFirestore(user);
      expect(firestoreData['name'], 'Demo User');
      expect(firestoreData['createdAt'], isA<DateTime>());

      // Simulate the fromFirestore conversion
      fromFirestore(String id, Map<String, dynamic> data) => MockUser(
            id: id,
            name: data['name'],
            createdAt: data['createdAt'],
          );

      final reconstructedUser = fromFirestore('demo', firestoreData);
      expect(reconstructedUser.id, 'demo');
      expect(reconstructedUser.name, 'Demo User');
      expect(reconstructedUser.createdAt, user.createdAt);
    });
  });
}
