# PocketBase Integration Tests

These tests run against a **real PocketBase server** to verify the repository implementation actually works.

## Prerequisites

### 1. Install PocketBase

Download PocketBase from [pocketbase.io](https://pocketbase.io/docs/):

```bash
# macOS
brew install pocketbase

# Or download manually
wget https://github.com/pocketbase/pocketbase/releases/download/v0.22.0/pocketbase_0.22.0_darwin_amd64.zip
unzip pocketbase_0.22.0_darwin_amd64.zip
```

### 2. Start PocketBase Server

```bash
# Start server on localhost:8090
pocketbase serve

# Or specify port
pocketbase serve --http=localhost:8090
```

### 3. Create Test Collection

1. Open PocketBase Admin: http://localhost:8090/_/
2. Create an admin account if first time
3. Create a new collection:
   - **Name**: `test_users`
   - **Type**: Base collection
   - **Fields**:
     - `id` (Text, required)
     - `name` (Text, required)
     - `age` (Number, required)
     - `createdAt` (Date, required)

## Running Tests

```bash
# Run all integration tests
dart test test/integration/

# Run specific test file
dart test test/integration/basic_crud_integration_test.dart

# Run with verbose output
dart test test/integration/ --reporter=expanded
```

## Test Coverage

✅ **CRUD Operations**: Add, Get, Update, Delete  
✅ **Error Handling**: Non-existent records, duplicates  
✅ **Data Persistence**: Verify operations actually persist  
✅ **Sequential Operations**: Multiple operations in sequence  
✅ **Real Network**: Actual HTTP calls to PocketBase  
✅ **Real Database**: Actual data storage and retrieval  

## Troubleshooting

### PocketBase Server Not Running
```
Exception: PocketBase server not running at http://localhost:8090
```
**Solution**: Start PocketBase server with `pocketbase serve`

### Collection Not Found
```
Collection test_users not found
```
**Solution**: Create the `test_users` collection in PocketBase admin interface

### Tests Failing
1. Check PocketBase server logs
2. Verify collection schema matches test expectations
3. Clear test data manually if needed

## Test Philosophy

These integration tests verify:
- **Real HTTP communication** with PocketBase
- **Actual data serialization/deserialization**
- **Real error responses** from the server
- **Network failure handling**
- **Database constraints and validation**

Unlike unit tests with mocks, these tests catch:
- API changes in PocketBase
- Serialization bugs
- Network issues
- Real database constraints
- Authentication problems 