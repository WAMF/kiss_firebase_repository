# Firebase Repository Implementation

A Flutter package that provides a clean repository interface for Firebase Firestore, following the KISS (Keep It Simple, Stupid) principle.

## Overview

This package implements the `kiss_repository` interface for Firebase Firestore, providing type-safe CRUD operations, real-time streaming, and flexible query building. It's designed specifically for Flutter applications that need Firestore integration with a clean, consistent API.

## ✨ Features & Limitations

### ✅ Standard Repository Features
- ✅ Complete CRUD operations (Create, Read, Update, Delete)
- ✅ Batch operations for multiple items
- ✅ Type-safe data conversions between Dart and backend
- ✅ Custom query building with `QueryBuilder`
- ✅ Built-in error handling with typed exceptions

### 🔥 Firebase-Specific Features
- ✅ Real-time streaming with Firestore listeners
- ✅ Offline support with automatic local caching and sync
- ✅ Auto-generated IDs (using Firestore's ID generation)
- ✅ Firebase emulator support for development
- ✅ Integration with Firebase ecosystem

### ⚠️ Limitations
- **Prefix-only search**: Only supports prefix matching ("Fire" finds "Firebase", but "base" won't)
- **Case-sensitive search**: "fire" won't find "Firebase" (case matters)
- **Non-atomic batch updates**: `updateAll` processes valid items and skips invalid ones (not truly atomic)
- **Complex queries**: Subject to Firestore's query limitations
- **Flutter only**: Requires Flutter SDK (not pure Dart)

## 🚀 Quick Start

### Prerequisites
- Flutter SDK ^3.8.0
- Firebase CLI (for local development with emulator)
- Android SDK with emulator (for integration tests)
- Firebase project setup

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  kiss_firebase_repository: ^0.9.0
```

### Basic Usage

```dart
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

// 1. Define your model
class User {
  final String id;
  final String name;
  final DateTime createdAt;

  User({required this.id, required this.name, required this.createdAt});
  
  User copyWith({String? id, String? name, DateTime? createdAt}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// 2. Create repository
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

// 3. Use it
final newUser = await userRepository.add(
  IdentifedObject('user123', User(
    id: 'user123',
    name: 'John Doe',
    createdAt: DateTime.now(),
  )),
);
```

## 🔧 Development Setup

### Firebase Emulator Setup

```bash
# Start Firebase emulator
./scripts/start_emulator.sh
```

The emulator runs on:
- Firestore: `localhost:8080`
- Emulator UI: `localhost:4000`

### Running Tests

```bash
# Integration tests (requires Firebase emulator AND Android emulator running)
./scripts/run_tests.sh
```

### Manual Development

```bash
# Start emulator (in one terminal)
./scripts/start_emulator.sh

# Run example app (in another terminal)
flutter run
```

## 📖 Usage

### Auto-Generated Firestore IDs

```dart
// Create item with auto-generated ID
final item = repository.createWithAutoId(
  User(id: '', name: 'John Doe', createdAt: DateTime.now()),
  (user, id) => user.copyWith(id: id),
);

final savedUser = await repository.add(item);
print(savedUser.id); // Real Firestore document ID (20 characters)
```

### Batch Operations

```dart
// Add multiple users
await userRepository.addAll([
  IdentifedObject('id1', user1),
  IdentifedObject('id2', user2),
]);

// Update multiple users
await userRepository.updateAll([
  IdentifedObject('id1', updatedUser1),
  IdentifedObject('id2', updatedUser2),
]);

// Delete multiple users
await userRepository.deleteAll(['id1', 'id2']);
```

### Real-time Streaming

```dart
// Stream single document
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
    
    return baseQuery.orderBy('createdAt', descending: true);
  }
}

// Use custom queries
final adults = await userRepository.query(query: AgeQuery(minAge: 18));
final activeUsers = userRepository.streamQuery(query: ActiveUsersQuery());
```

### Error Handling

```dart
try {
  final user = await userRepository.get('non-existing-id');
} on RepositoryException catch (e) {
  if (e.code == RepositoryErrorCode.notFound) {
    print('User not found');
  } else if (e.code == RepositoryErrorCode.alreadyExists) {
    print('User already exists');
  }
}
```

## 🔄 Comparison with Other Implementations

For a detailed comparison of all repository implementations, see the [main documentation](https://github.com/WAMF/kiss_repository#comparison-table).

## 📁 Example Application

See the [example](https://github.com/WAMF/kiss_repository/tree/main/example) directory for a complete Flutter app demonstrating:

- Real-time user management with Firestore
- Auto-generated IDs and CRUD operations
- Custom query system with search functionality
- Modern Material 3 UI with error handling
- Integration tests with Firebase emulator

```bash
cd example
./scripts/start_emulator.sh  # Terminal 1  
flutter run                  # Terminal 2
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
