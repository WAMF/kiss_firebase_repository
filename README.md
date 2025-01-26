# KISS Firebase Repository

A Flutter package that provides a clean and simple repository interface for Firebase Firestore, following the KISS (Keep It Simple, Stupid) principle.

## Features

- Simple repository interface for CRUD operations
- Type-safe data conversions between Dart and Firestore
- Support for batch operations
- Flexible query building
- Automatic type conversion for common Firestore data types
- Stream support for real-time updates
- Built-in error handling

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  kiss_firebase_repository: ^1.0.0
```

## Usage

### Basic Setup

1. Create a model class for your data:

```dart
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
```

2. Initialize the repository:

```dart
final userRepository = RepositoryFirestore<User>(
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
```

### Basic Operations

```dart
// Add a new user
final newUser = await userRepository.add(
  User(
    id: '',
    name: 'John Doe',
    createdAt: DateTime.now(),
  ),
);

// Get a user by ID
final user = await userRepository.get('user_id');

// Update a user
final updatedUser = await userRepository.update(
  'user_id',
  (current) => User(
    id: current.id,
    name: 'Jane Doe',
    createdAt: current.createdAt,
  ),
);

// Delete a user
await userRepository.delete('user_id');
```

### Batch Operations

```dart
// Add multiple users
final users = [user1, user2, user3];
await userRepository.addAll(users);

// Update multiple users
final updates = [
  IdentifedObject('id1', updatedUser1),
  IdentifedObject('id2', updatedUser2),
];
await userRepository.updateAll(updates);

// Delete multiple users
await userRepository.deleteAll(['id1', 'id2', 'id3']);
```

### Real-time Updates

```dart
// Stream a single document
userRepository.stream('user_id').listen((user) {
  print('User updated: ${user.name}');
});

// Stream query results
userRepository.streamQuery().listen((users) {
  print('Total users: ${users.length}');
});
```

### Custom Queries

```dart
class UserQueryBuilder implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery = FirebaseFirestore.instance.collection('users');
    
    if (query is AgeQuery) {
      return baseQuery
          .where('age', isGreaterThan: query.minAge)
          .orderBy('age');
    }
    
    if (query is ActiveUsersQuery) {
      return baseQuery
          .where('status', isEqualTo: 'active')
          .orderBy('lastActive', descending: true);
    }
    
    if (query is UsersByRoleQuery) {
      return baseQuery
          .where('role', isEqualTo: query.role)
          .orderBy('name');
    }
    
    // Default to returning all users
    return baseQuery;
  }
}

// Example query classes
class AgeQuery extends Query {
  final int minAge;
  const AgeQuery(this.minAge);
}

class ActiveUsersQuery extends Query {
  const ActiveUsersQuery();
}

class UsersByRoleQuery extends Query {
  final String role;
  const UsersByRoleQuery(this.role);
}

final userRepository = RepositoryFirestore<User>(
  // ... other parameters
  queryBuilder: UserQueryBuilder(),
);

// Usage examples
final adultUsers = await userRepository.query(query: AgeQuery(18));
final activeUsers = await userRepository.query(query: const ActiveUsersQuery());
final adminUsers = await userRepository.query(query: UsersByRoleQuery('admin'));
```

### Type Conversion

The package automatically handles type conversion between Dart and Firestore for:
- DateTime <-> Timestamp
- Nested Maps
- Lists
- Basic data types

## Error Handling

The repository provides typed exceptions for common errors:

```dart
try {
  final user = await userRepository.get('non_existent_id');
} on RepositoryException catch (e) {
  if (e.code == RepositoryErrorCode.notFound) {
    print('User not found');
  }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.