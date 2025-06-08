import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';
import '../../../kiss_repository/integration_test/basic_crud_integration_test.dart';
import '../../../kiss_repository/integration_test/basic_batch_integration_test.dart';
import '../../../kiss_repository/integration_test/basic_query_integration_test.dart';
import '../../../kiss_repository/integration_test/basic_streaming_integration_test.dart';
import '../../../kiss_repository/integration_test/basic_error_integration_test.dart';

void main() {
  setUpAll(() async {
    await IntegrationTestHelpers.setupIntegrationTests();
  });

  tearDownAll(() async {
    await IntegrationTestHelpers.tearDownIntegrationTests();
  });

  setUp(() async {
    await IntegrationTestHelpers.clearTestCollection();
  });

  group('PocketBase Repository - Centralized CRUD Tests', () {
    runFlutterBasicCrudTests(() => IntegrationTestHelpers.repository);
  });

  group('Batch Operations Tests', () {
    runFlutterBasicBatchTests(() => IntegrationTestHelpers.repository);
  });

  group('Query Filtering Tests', () {
    runFlutterBasicQueryTests(() => IntegrationTestHelpers.repository);
  });

  group('Streaming Tests', () {
    runFlutterBasicStreamingTests(() => IntegrationTestHelpers.repository);
  });

  group('Error Handling Tests', () {
    runFlutterBasicErrorTests(() => IntegrationTestHelpers.repository);
  });
}
