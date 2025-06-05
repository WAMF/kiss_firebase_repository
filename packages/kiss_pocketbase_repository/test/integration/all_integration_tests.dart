import 'package:test/test.dart';

import 'basic_crud_integration_test.dart' as repository_tests;
import 'query_filtering_test.dart' as query_tests;
import 'batch_operations_test.dart' as batch_tests;
import 'id_validation_test.dart' as id_validation_tests;

void main() {
  group('All PocketBase Integration Tests', () {
    group('Repository CRUD Operations', repository_tests.main);
    group('Query Filtering', query_tests.main);
    group('Batch Operations', batch_tests.main);
    group('ID Validation', id_validation_tests.main);
  });
}
