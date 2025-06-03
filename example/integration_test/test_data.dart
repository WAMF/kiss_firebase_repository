import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

// Test model
class TestUser {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;

  TestUser({required this.id, required this.name, required this.age, required this.createdAt});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'age': age, 'createdAt': createdAt.toIso8601String()};

  static TestUser fromMap(Map<String, dynamic> map) =>
      TestUser(id: map['id'], name: map['name'], age: map['age'], createdAt: DateTime.parse(map['createdAt']));

  TestUser copyWith({String? id, String? name, int? age}) =>
      TestUser(id: id ?? this.id, name: name ?? this.name, age: age ?? this.age, createdAt: createdAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser && runtimeType == other.runtimeType && id == other.id && name == other.name && age == other.age;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ age.hashCode;
}

// Query classes for testing
class QueryByAge extends Query {
  final int minAge;
  const QueryByAge(this.minAge);
}

class QueryByName extends Query {
  final String namePrefix;
  const QueryByName(this.namePrefix);
}

class QueryRecentUsers extends Query {
  final int daysAgo;
  const QueryRecentUsers(this.daysAgo);
}

// Query builder for TestUser
class TestUserQueryBuilder implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery = firestore.FirebaseFirestore.instance.collection('test_users');

    if (query is QueryByAge) {
      return baseQuery.where('age', isGreaterThanOrEqualTo: query.minAge).orderBy('age');
    }

    if (query is QueryByName) {
      return baseQuery
          .where('name', isGreaterThanOrEqualTo: query.namePrefix)
          .where('name', isLessThan: '${query.namePrefix}\uf8ff')
          .orderBy('name');
    }

    if (query is QueryRecentUsers) {
      final cutoffDate = DateTime.now().subtract(Duration(days: query.daysAgo));
      return baseQuery
          .where('createdAt', isGreaterThan: cutoffDate.toIso8601String())
          .orderBy('createdAt', descending: true);
    }

    // Default: return all users ordered by creation date
    return baseQuery.orderBy('createdAt', descending: true);
  }
}
