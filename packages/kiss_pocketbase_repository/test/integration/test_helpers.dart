import 'package:pocketbase/pocketbase.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';

import 'test_data.dart';

class IntegrationTestHelpers {
  static late PocketBase pocketbaseClient;
  static late RepositoryPocketBase<TestUser> repository;
  static const String testCollection = 'test_users';
  static const String pocketbaseUrl = 'http://localhost:8090';

  // Test user credentials (matching the setup script)
  static const String testUserEmail = 'testuser@example.com';
  static const String testUserPassword = 'testuser123';

  /// Initialize PocketBase connection and authenticate as test user
  static Future<void> initializePocketBase() async {
    pocketbaseClient = PocketBase(pocketbaseUrl);

    // Authenticate as test user using the test_users collection (auth type)
    try {
      await pocketbaseClient
          .collection(testCollection)
          .authWithPassword(testUserEmail, testUserPassword);
      print('🔐 Authenticated as test user: $testUserEmail');
    } catch (e) {
      throw Exception(
        'Failed to authenticate test user. Make sure user exists:\n'
        'Email: $testUserEmail\n'
        'Error: $e',
      );
    }

    repository = RepositoryPocketBase<TestUser>(
      client: pocketbaseClient,
      collection: testCollection,
      fromPocketBase: (record) => TestUser.fromMap(record.data),
      toPocketBase: (user) => user.toMap(),
    );
  }

  /// Clear all test data from the collection
  static Future<void> clearTestCollection() async {
    try {
      // Get all records in the test collection
      final records = await pocketbaseClient
          .collection(testCollection)
          .getFullList();

      // Delete each record
      for (final record in records) {
        await pocketbaseClient.collection(testCollection).delete(record.id);
      }

      if (records.isNotEmpty) {
        print('🧹 Cleared ${records.length} test records');
      }
    } catch (e) {
      // Collection might not exist or be empty, that's fine
      print('ℹ️ Collection clear: $e');
    }
  }

  /// Setup method to be called in test setUpAll
  static Future<void> setupIntegrationTests() async {
    // Connect to manually started PocketBase instance and authenticate
    await initializePocketBase();

    // Verify connection
    try {
      await pocketbaseClient.health.check();
      print('✅ Connected to PocketBase at $pocketbaseUrl');
    } catch (e) {
      throw Exception(
        'Failed to connect to PocketBase. Make sure it\'s running at $pocketbaseUrl\n'
        'Run: ./packages/kiss_pocketbase_repository/scripts/setup_test_collection_and_user.sh\n'
        'Error: $e',
      );
    }

    print('🎯 Integration tests ready to run');
  }

  /// Clean up after all tests
  static Future<void> tearDownIntegrationTests() async {
    try {
      await clearTestCollection();
      print('✅ Integration test cleanup completed');
    } catch (e) {
      print('ℹ️ Cleanup error (may be harmless): $e');
    }
  }
}
