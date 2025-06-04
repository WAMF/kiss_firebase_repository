# PocketBase Repository Implementation Plan

## Package Structure: `packages/kiss_pocketbase_repository/`

### Core Files

#### `pubspec.yaml`
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

#### `lib/kiss_pocketbase_repository.dart` (Main Export)
- Export `Repository` interface from kiss_repository
- Export `RepositoryPocketBase` implementation
- Export utility classes and types

#### `lib/src/repository_pocketbase.dart` (Core Implementation)
- `RepositoryPocketBase<T>` class extending `Repository<T>`
- Constructor: `PocketBase client`, `String collection`, serialization functions, query builder
- Implement all abstract methods from Repository interface
- Handle PocketBase RecordModel conversion
- Error mapping: `ClientException` → `RepositoryException`

#### `lib/src/pocketbase_identified_object.dart` (Auto-ID Support)
- `PocketBaseIdentifiedObject<T>` extending `IdentifiedObject<T>`
- Auto-generate IDs using PocketBase collection create
- Lazy ID generation similar to Firestore implementation
- Update object with generated ID

#### `lib/src/pocketbase_query_builder.dart` (Query System)
- `QueryBuilder<String>` interface for PocketBase filters
- Convert `Query` objects to PocketBase filter strings
- Support common patterns:
  - `QueryByAge(25)` → `"age >= 25"`
  - `QueryByName("John")` → `"name ~ 'John'"`
  - `QueryRecentUsers(7)` → `"created >= '2024-01-01'"`

#### `lib/src/pocketbase_stream_manager.dart` (Real-time Streams)
- Manage PocketBase subscription lifecycle
- Convert subscription events to Dart Streams
- Handle single record and query result streaming
- Automatic cleanup and reconnection

#### `lib/src/type_converter.dart` (Data Conversion)
- DateTime ↔ ISO string conversion
- Handle nested objects and collections
- Map Dart types to PocketBase compatible formats
- Type-safe conversion utilities

### Test Files

#### `test/repository_pocketbase_test.dart`
- Unit tests for core repository functionality
- Mock PocketBase client for isolated testing
- Test serialization/deserialization

#### `test/query_builder_test.dart`
- Test query conversion logic
- Verify filter string generation
- Edge cases and invalid queries

### Integration with Existing Tests

#### Modifications needed in `example/integration_test/`:
- Update `utils/test_helpers.dart` to support PocketBase
- Add PocketBase initialization option
- Create `TestUserPocketBaseQueryBuilder`
- All existing tests should pass without modification

## Implementation Order

1. **Setup** - Create package structure and pubspec.yaml
2. **Core Repository** - Basic CRUD operations
3. **Query System** - AllQuery support first
4. **Streaming** - Real-time subscriptions
5. **Auto-ID** - PocketBase ID generation
6. **Batch Operations** - Sequential processing
7. **Integration Tests** - Verify compatibility
8. **Documentation** - README and examples

## Key Design Decisions

### PocketBase vs Firebase Differences
- **No native batch operations** → Sequential processing with error handling
- **Different filter syntax** → Custom query builder
- **RecordModel API** → Convert to domain objects
- **Subscription events** → Map to Dart Streams

### API Compatibility
- Same public interface as `RepositoryFirestore`
- Drop-in replacement capability
- Identical error types and behaviors
- Compatible with existing test suite

### Performance Considerations
- Connection pooling via single PocketBase instance
- Subscription management and cleanup
- Efficient query caching where applicable
- Minimize data transfer with field selection 