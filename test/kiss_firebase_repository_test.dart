import 'package:flutter_test/flutter_test.dart';

import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

class User {
  final String id;
  final String name;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}

void main() {
  test('add and get user', () async {
    final repository = RepositoryFirestore<User>(
      path: 'users',
      toFirestore: (user) => {
        'name': user.name,
        'createdAt': user.createdAt,
      },
      fromFirestore: (ref, data) => User(
        id: ref.id,
        name: data['name'],
        createdAt: data['createdAt'],
      ),
    );
    repository.addWithId(
        '1', User(id: '1', name: 'John', createdAt: DateTime.now()));
    final user = await repository.get('1');
    expect(user.name, 'John');
    expect(user.createdAt, DateTime.now());
  });
}
