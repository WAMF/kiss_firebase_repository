/// Test data models for PocketBase integration tests
class TestUser {
  final String id;
  final String name;
  final int age;
  final DateTime created;

  const TestUser({
    required this.id,
    required this.name,
    required this.age,
    required this.created,
  });

  /// Create a new TestUser without an ID (for adding to repository)
  TestUser.create({
    required this.name,
    required this.age,
    required this.created,
  }) : id = '';

  /// Create TestUser from PocketBase record data
  factory TestUser.fromMap(Map<String, dynamic> map) {
    return TestUser(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String,
      age: (map['age'] as num).toInt(),
      created: DateTime.parse(map['created'] as String),
    );
  }

  /// Convert TestUser to Map for PocketBase (excludes ID as it's auto-generated)
  Map<String, dynamic> toMap() {
    return {'name': name, 'age': age, 'created': created.toIso8601String()};
  }

  /// Create a copy with updated fields
  TestUser copyWith({String? id, String? name, int? age, DateTime? createdAt}) {
    return TestUser(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      created: createdAt ?? this.created,
    );
  }

  @override
  String toString() {
    return 'TestUser(id: $id, name: $name, age: $age, createdAt: $created)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestUser &&
        other.id == id &&
        other.name == name &&
        other.age == age &&
        other.created == created;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ age.hashCode ^ created.hashCode;
  }
}
