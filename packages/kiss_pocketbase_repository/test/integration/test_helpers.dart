import 'package:pocketbase/pocketbase.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';

import 'test_data.dart';

class IntegrationTestHelpers {
  static late PocketBase pocketbaseClient;
  static late RepositoryPocketBase<TestUser> repository;
  static const String testCollection = 'test_users';
  static const String pocketbaseUrl = 'http://localhost:8090';

  static Future<void> initializePocketBase() async {
    pocketbaseClient = PocketBase(pocketbaseUrl);

    repository = RepositoryPocketBase<TestUser>(
      client: pocketbaseClient,
      collection: testCollection,
      fromPocketBase: (record) => TestUser.fromMap(record.data),
      toPocketBase: (user) => user.toMap(),
    );
  }

  static Future<void> clearTestCollection() async {
    try {
      final records = await pocketbaseClient
          .collection(testCollection)
          .getFullList();

      for (final record in records) {
        await pocketbaseClient.collection(testCollection).delete(record.id);
      }

      if (records.isNotEmpty) {
        print('🧹 Cleared ${records.length} test records');
      }
    } catch (e) {
      print('ℹ️ Collection clear: $e');
    }
  }

  static Future<void> setupIntegrationTests() async {
    await initializePocketBase();

    try {
      await pocketbaseClient.health.check();
      print('✅ Connected to PocketBase at $pocketbaseUrl');
    } catch (e) {
      throw Exception(
        'Failed to connect to PocketBase. Make sure it\'s running at $pocketbaseUrl\n'
        'Run: dart run scripts/start_pocketbase_with_schema.dart\n'
        'Error: $e',
      );
    }

    print('🎯 Integration tests ready to run');
  }

  static Future<void> tearDownIntegrationTests() async {
    try {
      await clearTestCollection();
      print('✅ Integration test cleanup completed');
    } catch (e) {
      print('ℹ️ Cleanup error (may be harmless): $e');
    }
  }
}
