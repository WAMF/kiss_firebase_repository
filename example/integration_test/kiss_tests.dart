import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';
import '../../../kiss_repository/integration_test/kiss_flutter_tests.dart';

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

  group('Firebase Repository - Centralized CRUD Tests', () {
    runBasicCrudTests(() => IntegrationTestHelpers.repository);
  });

  group('Batch Operations Tests', () {
    runBasicBatchTests(() => IntegrationTestHelpers.repository);
  });

  group('Query Filtering Tests', () {
    runBasicQueryTests(() => IntegrationTestHelpers.repository);
  });

  group('Streaming Tests', () {
    runBasicStreamingTests(() => IntegrationTestHelpers.repository);
  });

  group('Error Handling Tests', () {
    runBasicErrorTests(() => IntegrationTestHelpers.repository);
  });

  group('ID Management Tests', () {
    runBasicIdTests(() => IntegrationTestHelpers.repository);
  });
}
