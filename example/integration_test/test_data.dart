// Test model
class TestUser {
  final String? id; // Nullable for auto-generation
  final String name;
  final int age;
  final DateTime createdAt;

  TestUser({this.id, required this.name, required this.age, required this.createdAt});

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
