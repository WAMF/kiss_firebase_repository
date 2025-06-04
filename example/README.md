# KISS Firebase Repository Example

This example demonstrates the `kiss_firebase_repository` package with a fully functional Flutter app that showcases:

- **Real-time user management** with Firebase Firestore
- **Auto-generated Firestore IDs** using the repository pattern
- **CRUD operations** (Create, Read, Update, Delete)
- **Real-time streaming** of data changes
- **Custom Query system** with QueryBuilder and search functionality
- **Modern Material 3 UI** with comprehensive error handling
- **Integration tests** with Firebase emulator

## New Features - Query System Demo 🔍

The example now includes a comprehensive demonstration of the **Query system** with:

### Custom Query Classes
- `QueryByName` - Search users by name with prefix matching
- `QueryByEmail` - Search users by email domain
- `QueryRecentUsers` - Filter users created within the last N days

### QueryBuilder Implementation
- `FirestoreUserQueryBuilder` - Converts Query objects to Firestore queries
- Demonstrates how to build complex Firestore queries programmatically
- Shows proper ordering and filtering techniques

### Tabbed UI Interface
- **All Users** tab - Shows all users with real-time updates
- **Search** tab - Interactive search with live results
- **Recent** tab - Shows users created in the last 7 days

### Search Functionality
- Real-time search as you type
- Debounced search input for performance
- Clear search functionality
- Dynamic result display with query information

## Quick Start

### 🔥 Start Firebase Emulator

```bash
cd example
./scripts/start_emulator.sh
```

Start the Firebase emulator and keep it running. Use this in one terminal, then run the app/tests in other terminals.

### 📱 Run the App

```bash
cd example
./scripts/run_app.sh
```

Runs the Flutter app (requires emulator to be running).

### 🧪 Run Integration Tests

```bash
cd example
./scripts/run_tests.sh
```

Runs the integration tests (requires emulator to be running).

## Features Demonstrated

- ✅ Add users with auto-generated Firestore IDs
- ✅ Real-time streaming of user list updates
- ✅ Update user information inline
- ✅ Delete users with confirmation
- ✅ **Custom Query system with QueryBuilder**
- ✅ **Search functionality with QueryByName**
- ✅ **Recent users filtering with QueryRecentUsers**
- ✅ **Tabbed interface for different query views**
- ✅ Error handling for Firebase operations
- ✅ Firebase emulator integration for development
- ✅ Comprehensive integration testing

## Query System Architecture

The example demonstrates the KISS Firebase Repository Query system:

```dart
// 1. Define custom Query classes
class QueryByName extends Query {
  final String searchTerm;
  const QueryByName(this.searchTerm);
}

// 2. Implement QueryBuilder
class FirestoreUserQueryBuilder implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  final String collectionPath;
  
  FirestoreUserQueryBuilder(this.collectionPath);

  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery = firestore.FirebaseFirestore.instance.collection(collectionPath);
    
    if (query is QueryByName) {
      final searchTermLower = query.searchTerm.toLowerCase();
      return baseQuery
          .where('name', isGreaterThanOrEqualTo: searchTermLower)
          .where('name', isLessThan: '${searchTermLower}z')
          .orderBy('name');
    }
    
    return baseQuery.orderBy('createdAt', descending: true);
  }
}

// 3. Configure repository with QueryBuilder
final repository = RepositoryFirestore<User>(
  path: 'users',
  queryBuilder: FirestoreUserQueryBuilder('users'),
  // ... other configuration
);

// 4. Use queries in your app
final searchResults = repository.streamQuery(
  query: QueryByName('john')
);
```

## Prerequisites

1. **Flutter SDK** (3.8.0+)
2. **Firebase CLI** for running the emulator
3. **Node.js** (for Firebase emulator)

## Setup Instructions (Manual)

If you prefer to run things manually instead of using the scripts:

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Firebase Configuration

The project includes a `firebase.json` configuration file at the repository root that configures the Firestore emulator to run on:
- Emulator: `localhost:8080` (host: `0.0.0.0`)
- UI: `localhost:4000`

### 3. Start Firebase Emulator (in one terminal)

From the root of the repository:

```bash
firebase emulators:start --only firestore
```

This starts the Firestore emulator using the configuration from `firebase.json`.

### 4. Run the Example App (in another terminal)

```bash
cd example
flutter pub get
flutter run
```

The app will automatically connect to the Firestore emulator and you can start adding users and testing the search functionality.

### 5. Test the Query System

1. Add some users with different names and emails
2. Switch to the "Search" tab
3. Type in the search box to see real-time filtering
4. Check the "Recent" tab to see users created in the last 7 days
5. Notice how each tab uses different Query classes

## Integration Tests

The example includes **comprehensive integration tests** organized into **6 focused test modules** with **39 total tests**:

### Test Organization

- **📄 basic_crud_test.dart** (5 tests) - CRUD operations & lifecycle testing
- **📄 id_management_test.dart** (5 tests) - Auto-ID generation & management
- **📄 batch_operations_test.dart** (5 tests) - Bulk operations & transactions  
- **📄 query_filtering_test.dart** (7 tests) - Query system & filtering functionality
- **📄 streaming_test.dart** (7 tests) - Real-time data streaming & subscriptions
- **📄 error_handling_test.dart** (10 tests) - Edge cases & error scenarios

### Shared Test Utilities

- **📁 utils/test_data.dart** - TestUser model & custom query classes
- **📁 utils/test_helpers.dart** - Common Firebase setup & test helpers

### Running Tests

Run all tests together:
```bash
cd example
./scripts/run_tests.sh
```

Or run individual test modules:
```bash
flutter test integration_test/basic_crud_test.dart
flutter test integration_test/streaming_test.dart
flutter test integration_test/error_handling_test.dart
```

Run all tests with the main test runner:
```bash
flutter test integration_test/all_integration_tests.dart
```

### What the Tests Verify

The comprehensive test suite verifies:

- ✅ **Repository CRUD operations** - Add, get, update, delete lifecycle
- ✅ **Auto-generated Firestore IDs** - ID generation and uniqueness
- ✅ **Batch operations** - Bulk add/update/delete with transaction handling
- ✅ **Query system functionality** - Custom queries, filtering, and edge cases
- ✅ **Real-time streaming** - Live data updates and subscription management
- ✅ **Error handling** - Type errors, concurrent modifications, edge cases
- ✅ **Firebase emulator integration** - Safe testing environment

## Architecture Benefits

The Query system provides:

- **Type Safety** - Compile-time verification of query parameters
- **Reusability** - Query classes can be reused across the app
- **Testability** - Easy to unit test query logic
- **Maintainability** - Clear separation of query logic
- **Flexibility** - Easy to add new query types
- **Performance** - Optimized Firestore queries with proper indexing

## Example Query Usage

```dart
// Search users by name
Stream<List<User>> searchUsers(String name) {
  return repository.streamQuery(query: QueryByName(name));
}

// Get recent users
Stream<List<User>> getRecentUsers() {
  return repository.streamQuery(query: QueryRecentUsers(7));
}

// Get all users (default)
Stream<List<User>> getAllUsers() {
  return repository.streamQuery(); // Uses AllQuery by default
}
```

This demonstrates how the KISS Firebase Repository's Query system makes complex data retrieval simple, type-safe, and maintainable.

## Repository Configuration

The example uses this repository configuration:

```dart
final userRepository = RepositoryFirestore<User>(
  path: 'users',
  toFirestore: (user) => {
    'id': user.id,
    'name': user.name,
    'email': user.email,
    'createdAt': user.createdAt,
  },
  fromFirestore: (ref, data) => User(
    id: ref.id,
    name: data['name'] ?? '',
    email: data['email'] ?? '',
    createdAt: data['createdAt'] as DateTime,
  ),
  queryBuilder: FirestoreUserQueryBuilder('users'),
);
```

## User Model

```dart
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  User copyWith({String? id, String? name, String? email, DateTime? createdAt}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

## Troubleshooting

### Firebase Emulator Not Running

If you see connection errors, make sure the Firebase emulator is running:

```bash
firebase emulators:start --only firestore
```

### Port Conflicts

If port 8080 is in use, you can modify the `firebase.json` configuration:

```json
{
  "emulators": {
    "firestore": {
      "port": 9090,
      "host": "0.0.0.0"
    }
  }
}
```

Then update the emulator configuration in the app accordingly.

### Dependencies Issues

Make sure all dependencies are installed:

```bash
flutter pub get
```

## Firebase Emulator UI

Access the Firebase emulator UI at `http://localhost:4000` to:
- View Firestore data in real-time
- Monitor database operations
- Clear test data between runs

This provides a complete development and testing environment without requiring a live Firebase project.
