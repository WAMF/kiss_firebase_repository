import 'package:test/test.dart';

import 'basic_crud_integration_test.dart' as basic_crud;
import 'query_filtering_test.dart' as query_filtering;
import 'batch_operations_test.dart' as batch_operations;

void main() {
  group('All PocketBase Integration Tests', () {
    basic_crud.main();
    query_filtering.main();
    batch_operations.main();
  });
}
