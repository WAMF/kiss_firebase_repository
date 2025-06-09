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
    runFlutterCrudTests(() => IntegrationTestHelpers.repository);
  });

  group('Batch Operations Tests', () {
    runFlutterBatchTests(() => IntegrationTestHelpers.repository);
  });

  group('Query Filtering Tests', () {
    runFlutterQueryTests(() => IntegrationTestHelpers.repository);
  });

  group('Streaming Tests', () {
    runFlutterStreamingTests(() => IntegrationTestHelpers.repository);
  });

  group('ID Management Tests', () {
    runFlutterIdTests(() => IntegrationTestHelpers.repository);
  });
}
