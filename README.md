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
- Auto-generated Firestore IDs with `FirestoreIdentifiedObject`

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  kiss_firebase_repository: ^0.7.0
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

  User copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
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
// Add a new user with specific ID
final newUser = await userRepository.add(
  IdentifedObject('user123', User(
    id: 'user123',
    name: 'John Doe',
    createdAt: DateTime.now(),
  )),
);

// Add a user with auto-generated Firestore ID
final autoIdItem = userRepository.createWithAutoId(
  User(
    id: '', // Will be replaced with generated ID
    name: 'Jane Doe',
    createdAt: DateTime.now(),
  ),
  (user, id) => user.copyWith(id: id),
);
final userWithAutoId = await userRepository.add(autoIdItem);

// Get a user by ID
final user = await userRepository.get('user_id');

// Update a user
final updatedUser = await userRepository.update(
  'user_id',
  (current) => current.copyWith(name: 'Jane Doe'),
);

// Delete a user
await userRepository.delete('user_id');
```

### Auto-Generated Firestore IDs

The package provides `FirestoreIdentifiedObject` for working with auto-generated Firestore IDs:

```dart
// Create an item with auto-generated ID
final item = repository.createWithAutoId(
  User(
    id: '', // Will be ignored
    name: 'John Doe',
    createdAt: DateTime.now(),
  ),
  (user, id) => user.copyWith(id: id), // Update function
);

// The ID is generated using Firestore's document reference
print(item.id); // Real Firestore document ID (20 characters)
print(item.object.id); // User object now has the generated ID

// Save to Firestore
final savedUser = await repository.add(item);
```

### Batch Operations

```dart
// Add multiple users
final users = [
  IdentifedObject('id1', user1),
  IdentifedObject('id2', user2),
  IdentifedObject('id3', user3),
];
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

## Testing

This package includes comprehensive tests that demonstrate all the core functionality. There are two types of tests available:

### 1. Unit Tests (✅ Recommended for CI/CD)

Unit tests verify the repository pattern and data models without requiring Firebase connections:

```bash
flutter test test/repository_unit_test.dart
```

These tests cover:
- ✅ Object creation and manipulation
- ✅ Data type conversions
- ✅ Repository pattern structure
- ✅ Equality and hash code implementations

### 2. Integration Tests with Emulator (🔧 For full functionality testing)

Integration tests run against the Firebase Emulator to test the complete functionality:

#### Prerequisites

Before running integration tests, make sure you have:

1. **Firebase CLI installed**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Java installed** (required for Firestore emulator):
   ```bash
   # On macOS with Homebrew
   brew install openjdk
   
   # On Ubuntu/Debian
   sudo apt install default-jdk
   ```

3. **A connected device or emulator** (for integration tests):
   ```bash
   # Check available devices
   flutter devices
   
   # Start an Android emulator or connect a device
   # Or run on Chrome for web testing
   ```

#### Running Integration Tests

**Option 1: Unit Tests Only (No Firebase required)**
```bash
flutter test test/repository_unit_test.dart
```

**Option 2: Integration Tests with Emulator**

1. **Start the Firebase emulator** (in a separate terminal):
   ```bash
   firebase emulators:start --only firestore
   ```

2. **Run integration tests** (requires connected device):
   ```bash
   cd example
   flutter test integration_test/app_test.dart
   ```

3. **Or use the example app scripts**:
   ```bash
   cd example
   ./scripts/start_emulator.sh  # In one terminal
   ./scripts/run_tests.sh       # In another terminal
   ```

### Test Coverage

**Unit Tests:**
- ✅ **Object patterns**: IdentifedObject creation and manipulation
- ✅ **Data models**: User creation, copying, equality
- ✅ **Type conversion**: MapConverter functionality
- ✅ **Repository structure**: toFirestore/fromFirestore patterns

**Integration Tests (with emulator):**
- ✅ **Basic CRUD operations**: Create, Read, Update, Delete
- ✅ **Auto-generated IDs**: Using Firestore's document ID generation
- ✅ **FirestoreIdentifiedObject**: Auto-ID creation and caching
- ✅ **Batch operations**: Adding, updating, and deleting multiple items
- ✅ **Queries**: Retrieving multiple documents
- ✅ **Streams**: Real-time data updates
- ✅ **Error handling**: Not found exceptions
- ✅ **Type conversion**: DateTime <-> Firestore Timestamp

## Example App

The `example/` directory contains a fully functional Flutter app demonstrating all package features:

- Real-time user management with Firestore
- Auto-generated IDs with `createWithAutoId()`
- CRUD operations with modern Material 3 UI
- Firebase emulator integration
- Comprehensive integration tests

To run the example:

```bash
cd example
./scripts/start_emulator.sh  # Start Firebase emulator
./scripts/run_app.sh         # Run the app
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
