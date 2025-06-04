# Integration Tests for KISS Firebase Repository

This directory contains comprehensive Flutter integration tests for the KISS Firebase Repository package, organized into **6 focused test modules** with **39 total tests**.

## Test Organization

The integration tests are organized into focused modules for better maintainability and navigation:

### 📄 Test Modules (39 tests total)

- **basic_crud_test.dart** (5 tests) - Core CRUD operations & lifecycle testing
- **id_management_test.dart** (5 tests) - Auto-ID generation & management
- **batch_operations_test.dart** (5 tests) - Bulk operations & transaction handling
- **query_filtering_test.dart** (7 tests) - Query system & filtering functionality  
- **streaming_test.dart** (7 tests) - Real-time data streaming & subscriptions
- **error_handling_test.dart** (10 tests) - Edge cases & error scenarios

### 📁 Shared Utilities

- **utils/test_data.dart** - TestUser model & custom query classes (QueryByAge, QueryByName, etc.)
- **utils/test_helpers.dart** - Common Firebase setup & test helpers (DRY setup code)

### 📄 Test Runner

- **all_integration_tests.dart** - Main runner that executes all test modules together

## Prerequisites

1. **Flutter SDK** - Make sure Flutter is installed and in your PATH
2. **Xcode and iOS Simulator** - Required for running tests on iOS simulator
3. **Firebase CLI** - Install with `npm install -g firebase-tools`
4. **Firebase Emulator** - The tests use the Firestore emulator

## Running Integration Tests

### Option 1: Run All Tests

From the **example directory**:

```bash
./scripts/run_tests.sh
```

Or manually:
```bash
flutter test integration_test/all_integration_tests.dart
```

### Option 2: Run Individual Test Modules

Run specific test categories:

```bash
# CRUD operations
flutter test integration_test/basic_crud_test.dart

# Auto-ID generation
flutter test integration_test/id_management_test.dart

# Batch operations
flutter test integration_test/batch_operations_test.dart

# Query system
flutter test integration_test/query_filtering_test.dart

# Real-time streaming
flutter test integration_test/streaming_test.dart

# Error handling & edge cases
flutter test integration_test/error_handling_test.dart
```

### Option 3: Parallel Test Execution

Run multiple test modules simultaneously:

```bash
flutter test integration_test/basic_crud_test.dart integration_test/batch_operations_test.dart
```

### Option 4: Manual Setup

1. Start the iOS simulator:
```bash
flutter emulators --launch apple_ios_simulator
```

2. Start the Firebase emulator (from package root):
```bash
firebase emulators:start --only firestore
```

3. Navigate to example directory and install dependencies:
```bash
cd example
flutter pub get
```

4. Run specific tests:
```bash
flutter test integration_test/basic_crud_test.dart -d apple_ios_simulator
```

## What the Tests Cover

### 🧪 Basic CRUD Operations (5 tests)
- Add, get, update, delete single item lifecycle
- Handling duplicate IDs and non-existent items
- Idempotent delete behavior

### 🔑 ID Management & Auto-Generation (5 tests)
- Firebase auto-ID generation with `autoIdentify()`
- `addAutoIdentified()` method functionality
- Custom `updateObjectWithId` functions
- Unique ID generation verification
- Default behavior without update callbacks

### 📦 Batch Operations (5 tests)  
- Multiple item add/update/delete operations
- Transaction handling and atomicity
- Partial failure scenarios
- Empty batch operations
- Large batch processing (50+ items)

### 🔍 Query & Filtering (7 tests)
- AllQuery default behavior
- Custom query classes (QueryByAge, QueryByName, QueryRecentUsers)
- Query result filtering and ordering
- Empty result handling
- Edge case queries

### 🌊 Real-time Streaming (7 tests)
- Single document streaming with `stream()`
- Query result streaming with `streamQuery()`
- Custom query streaming
- Concurrent stream handling
- Stream lifecycle management (deletion, subscription cleanup)

### ⚠️ Error Handling & Edge Cases (10 tests)
- Type errors with malformed Firestore data
- Concurrent modification handling
- Repository disposal behavior
- Very large batch operations
- Invalid query handling
- Stream error scenarios
- Special character IDs
- Operations on deleted documents
- Rapid consecutive operations

## Test Structure & Architecture

```
integration_test/
├── utils/
│   ├── test_data.dart           # Shared models & queries
│   └── test_helpers.dart        # Common setup & utilities
├── basic_crud_test.dart         # CRUD operations (5 tests)
├── id_management_test.dart      # Auto-ID generation (5 tests)
├── batch_operations_test.dart   # Bulk operations (5 tests)
├── query_filtering_test.dart    # Query system (7 tests)
├── streaming_test.dart          # Real-time streaming (7 tests)
├── error_handling_test.dart     # Edge cases (10 tests)
└── all_integration_tests.dart   # Main test runner
```

### Benefits of This Organization

- ✅ **Better Navigation** - Find tests by category easily
- ✅ **Focused Testing** - Each file covers one specific area
- ✅ **Parallel Execution** - Run multiple test files simultaneously
- ✅ **Easier Maintenance** - Changes affect only relevant test files
- ✅ **DRY Code** - Shared utilities reduce duplication
- ✅ **Clear Separation** - 60-180 lines per file vs 700+ monolithic file

## Package Structure

```
kiss_firebase_repository/          # Package root
├── lib/                          # Package source code
├── test/                         # Unit tests  
├── example/                      # Example Flutter app
│   ├── lib/main.dart            # Example app
│   ├── integration_test/        # Integration tests (39 tests)
│   │   ├── utils/               # Shared test utilities
│   │   ├── basic_crud_test.dart # CRUD operations
│   │   ├── streaming_test.dart  # Real-time streaming
│   │   └── ...                  # Other focused test modules
│   └── pubspec.yaml             # Example app dependencies
└── test_integration_with_emulator.sh  # Test runner script
```

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
- Make sure iOS simulator is running
- Check with `flutter devices` to see available devices
- Try starting simulator manually: `flutter emulators --launch apple_ios_simulator`

**Tests fail with import errors**
- Verify all test files correctly import from `utils/test_data.dart` and `utils/test_helpers.dart`
- Make sure you're running tests from the example directory

**Individual test modules fail**
- Each test module is independent - verify the specific module's imports and setup
- Check that `IntegrationTestHelpers.setupIntegrationTest()` is called in each test file

**Error: "Xcode command line tools are not installed"**
- Install with: `xcode-select --install`

**Tests fail with connection errors**
- Ensure no firewall is blocking localhost:8080
- Try restarting the Firebase emulator
- Verify iOS simulator is fully booted before running tests
