# Integration Tests for KISS Firebase Repository

This directory contains comprehensive Flutter integration tests for the KISS Firebase Repository package, using **centralized test modules** shared from the main `kiss_repository` package.

## Test Organization

The integration tests use **shared test modules** from `kiss_repository/integration_test/` to ensure consistency across repository implementations:

### 📄 Shared Test Modules (39 tests total)

- **basic_crud_integration_test.dart** (5 tests) - Core CRUD operations & lifecycle testing
- **id_management_test.dart** (5 tests) - Auto-ID generation & management
- **basic_batch_integration_test.dart** (5 tests) - Bulk operations & transaction handling  
- **basic_query_integration_test.dart** (7 tests) - Query system & filtering functionality
- **basic_streaming_integration_test.dart** (7 tests) - Real-time data streaming & subscriptions
- **basic_error_integration_test.dart** (10 tests) - Edge cases & error scenarios

### 📁 Firebase-Specific Files

- **test_helpers.dart** - Firebase/Firestore setup & configuration
- **kiss_tests.dart** - Main test runner that imports and executes shared tests

### 🎯 Centralized Test Architecture

All test logic is centralized in `kiss_repository/integration_test/` and imported by Firebase repository, ensuring:
- ✅ **Consistency** - Same test scenarios across repository implementations  
- ✅ **Maintainability** - Single source of truth for test logic
- ✅ **Scalability** - New repository implementations can reuse tests

## Prerequisites

1. **Flutter SDK** - Make sure Flutter is installed and in your PATH
2. **Android Emulator or iOS Simulator** - Required for running integration tests
3. **Firebase CLI** - Install with `npm install -g firebase-tools`
4. **Firebase Emulator** - The tests use the Firestore emulator

## Running Integration Tests

### Option 1: Using Scripts (Recommended)

The `scripts/` directory provides convenient automation:

```bash
# Start Firebase emulator in background
./scripts/start_emulator.sh

# Run all integration tests (starts emulator if not running)
./scripts/run_tests.sh

# Run the example app
./scripts/run_app.sh
```

See `scripts/README.md` for more details on available scripts.

### Option 2: Manual Setup

### Prerequisites: Start Firebase Emulator

**The Firebase emulator must be running before executing tests.**

From the package root directory:
```bash
firebase emulators:start --only firestore
```

### Run the Tests

From the **example directory**:

```bash
flutter test integration_test/kiss_tests.dart
```

### Full Setup from Scratch

1. **Start Firebase Emulator** (from package root):
```bash
firebase emulators:start --only firestore
```

2. **Navigate to example directory**:
```bash
cd example
```

3. **Install dependencies** (if needed):
```bash
flutter pub get
```

4. **Run tests**:
```bash
flutter test integration_test/kiss_tests.dart
```

## What the Tests Cover

### 🧪 Basic CRUD Operations (3 tests)
- Complete CRUD lifecycle (create, read, update, delete)
- Handling non-existent records gracefully
- Multiple sequential operations

### 📦 Batch Operations (5 tests)
- Multiple item add/update/delete operations
- Mixed batch operations
- Empty batch operations gracefully handled
- Transaction handling and atomicity

### 🔍 Query & Filtering (7 tests)
- AllQuery default behavior
- Custom query classes (QueryByName, QueryByCreatedAfter, QueryByCreatedBefore)
- Query result filtering and ordering
- Empty result handling
- Edge case queries

### 🌊 Real-time Streaming (6 tests)
- Single document streaming with `stream()`
- Query result streaming with `streamQuery()`
- Multiple concurrent streams
- Stream lifecycle management
- Initially non-existent document streaming

### ⚠️ Error Handling & Edge Cases (10 tests)
- Concurrent modification handling
- Repository disposal behavior
- Large batch operations
- Operations on deleted documents
- Rapid consecutive operations
- AutoIdentify edge cases
- Get/update operations on non-existent items

## Test Structure & Architecture

```
kiss_repository/integration_test/     # Shared test modules (flutter_test)
├── data/
│   ├── test_object.dart             # Shared test model
│   └── queries.dart                 # Shared query classes
├── basic_crud_integration_test.dart
├── basic_batch_integration_test.dart
├── basic_query_integration_test.dart
├── basic_streaming_integration_test.dart
└── basic_error_integration_test.dart

kiss_firebase_repository/example/integration_test/  # Firebase-specific
├── test_helpers.dart                # Firebase setup & configuration
└── kiss_tests.dart                  # Main runner (imports shared tests)
```

### Benefits of This Architecture

- ✅ **Centralized Logic** - Test scenarios defined once in `kiss_repository`
- ✅ **Cross-Implementation Consistency** - All repositories test the same scenarios
- ✅ **Easy Maintenance** - Update tests in one place, apply everywhere
- ✅ **Implementation-Specific Setup** - Each repository handles its own configuration
- ✅ **90% Success Rate** - 28/31 tests passing on Firebase implementation

## Current Test Results

**Firebase Repository: 28/31 tests passing (90% success rate)**

✅ **Passing Areas:**
- CRUD operations
- Batch operations
- Most query operations  
- Real-time streaming
- Error handling

⚠️ **Known Issues (3 failing tests):**
- Exception handling differences between Firebase and expected types
- Query filtering edge cases
- Batch failure scenarios with different error patterns

## Test Environment

- **Firebase Emulator** - Tests run against Firestore emulator on localhost:8080
- **Isolated Data** - Each test uses dedicated collection that gets cleaned up
- **Shared Setup** - Common Firebase initialization via test helpers
- **Safe Testing** - No impact on production Firebase projects

## Troubleshooting

**Error: "PlatformException(channel-error, Unable to establish connection on channel.)"**
- Make sure the Firebase emulator is running on localhost:8080
- Verify Firebase CLI is installed and working

**Error: "No supported devices connected"**
- Make sure Android emulator or iOS simulator is running
- Check with `flutter devices` to see available devices
- Try: `flutter emulators --launch <emulator_name>`

**Error: "Not found: 'package:test/test.dart'"**
- This indicates you're trying to run pure Dart tests with Flutter
- Make sure you're running from the Firebase example directory with `flutter test`

**Tests fail with DateTime/Timestamp errors**
- This should be fixed in the current version
- Verify `test_helpers.dart` handles both DateTime and Timestamp types

**Error: "Gradle task assembleDebug failed"**
- Ensure Android SDK is properly installed
- Try `flutter clean` and `flutter pub get`
- Verify Android emulator is running
