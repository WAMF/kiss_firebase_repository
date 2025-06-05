# PocketBase Repository Implementation Plan

## Package Structure: `packages/kiss_pocketbase_repository/`

### Core Files

#### `pubspec.yaml` ✅
```yaml
name: kiss_pocketbase_repository
description: "A PocketBase implementation of kiss_repository interface"
version: 0.1.0

environment:
  sdk: ^3.6.0
  flutter: ">=1.17.0"

dependencies:
  pocketbase: ^0.22.0
  kiss_repository: ^0.9.0
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

#### `lib/kiss_pocketbase_repository.dart` (Main Export) ✅
- Export `Repository` interface from kiss_repository
- Export `RepositoryPocketBase` implementation
- Export utility classes and types

#### `lib/src/repository_pocketbase.dart` (Core Implementation) ✅
- `RepositoryPocketBase<T>` class extending `Repository<T>`
- Constructor: `PocketBase client`, `String collection`, serialization functions, query builder
- ✅ Implement core CRUD methods: get, add, update, delete
- ✅ Implement query() method with AllQuery support
- ✅ Handle PocketBase RecordModel conversion
- ✅ Error mapping: `ClientException` → `RepositoryException`
- ✅ Auto-ID support with `autoIdentify()` and `addAutoIdentified()`
- 🚧 Batch operations (addAll, updateAll, deleteAll) - TODO
- 🚧 Streaming (stream, streamQuery) - TODO

#### `lib/src/pocketbase_identified_object.dart` (Auto-ID Support) ❌
- Not needed - auto-ID functionality integrated directly in main repository class
- PocketBase auto-generates IDs, use empty string as placeholder
- ✅ Implemented via `autoIdentify()` and `addAutoIdentified()` methods

#### `lib/src/pocketbase_query_builder.dart` (Query System) 🚧
- ✅ Basic QueryBuilder<String> interface support
- ✅ AllQuery implementation with default sorting
- 🚧 Custom query builders for complex filtering - TODO
- Support patterns like:
  - `QueryByAge(25)` → `"age >= 25"`
  - `QueryByName("John")` → `"name ~ 'John'"`
  - `QueryRecentUsers(7)` → `"created >= '2024-01-01'"`

#### `lib/src/pocketbase_stream_manager.dart` (Real-time Streams) ❌
- TODO: Manage PocketBase subscription lifecycle
- TODO: Convert subscription events to Dart Streams
- TODO: Handle single record and query result streaming
- TODO: Automatic cleanup and reconnection

#### `lib/src/type_converter.dart` (Data Conversion) ❌
- Currently handled inline in repository methods
- DateTime conversion built into PocketBase client
- Could extract for better organization

### Test Files ✅

#### `test/integration/basic_crud_integration_test.dart` ✅
- Integration tests for core repository CRUD functionality
- Real PocketBase instance testing
- Auto-ID generation testing
- Error handling verification

#### `test/integration/query_filtering_test.dart` ✅
- Integration tests for query functionality
- AllQuery testing with proper sorting
- Empty collection handling
- Multiple test scenarios

#### `test/integration/test_helpers.dart` ✅
- PocketBase setup and teardown utilities
- Authentication and collection management
- Test data cleanup helpers

#### `test/integration/test_data.dart` ✅
- TestUser model for integration testing
- Serialization/deserialization helpers
- Test data creation utilities

### Integration with Existing Tests

#### Modifications needed in `example/integration_test/`: 🚧
- TODO: Update `utils/test_helpers.dart` to support PocketBase
- TODO: Add PocketBase initialization option
- TODO: Create `TestUserPocketBaseQueryBuilder`
- TODO: All existing tests should pass without modification

## Implementation Progress

### ✅ **Completed (Steps 1-3)**
1. **Setup** - ✅ Package structure, pubspec.yaml, test infrastructure
2. **Core Repository** - ✅ Basic CRUD operations (get, add, update, delete)
3. **Query System** - ✅ AllQuery support with PocketBase filtering
4. **Auto-ID** - ✅ PocketBase ID generation via `addAutoIdentified()`
5. **Integration Tests** - ✅ CRUD and query tests working with real PocketBase

### 🚧 **In Progress/Next Steps**
6. **Batch Operations** - 🚧 Sequential processing (addAll, updateAll, deleteAll)
7. **Streaming** - ❌ Real-time subscriptions (stream, streamQuery)
8. **Custom Query Builders** - ❌ Complex filtering beyond AllQuery
9. **Documentation** - 🚧 README and migration guides (partially done)

## Key Design Decisions

### PocketBase vs Firebase Differences
- **No native batch operations** → ✅ Sequential processing with error handling (implementing now)
- **Different filter syntax** → ✅ Custom query builder interface (basic support done)
- **RecordModel API** → ✅ Convert to domain objects (implemented)
- **Subscription events** → 🚧 Map to Dart Streams (TODO)

### API Compatibility
- ✅ Same public interface as `RepositoryFirestore`
- ✅ Drop-in replacement capability for basic operations
- ✅ Identical error types and behaviors
- ✅ Compatible with existing test patterns

### Performance Considerations
- ✅ Connection reuse via single PocketBase instance
- 🚧 Subscription management and cleanup (TODO)
- ✅ Efficient query execution with proper sorting
- ✅ Proper error handling and conversion 