import 'package:flutter_test/flutter_test.dart';

import 'basic_crud_test.dart' as basic_crud;
import 'id_management_test.dart' as id_management;
import 'batch_operations_test.dart' as batch_operations;
import 'query_filtering_test.dart' as query_filtering;
import 'streaming_test.dart' as streaming;
import 'error_handling_test.dart' as error_handling;

void main() {
  group('All Integration Tests', () {
    basic_crud.main();
    id_management.main();
    batch_operations.main();
    query_filtering.main();
    streaming.main();
    error_handling.main();
  });
}


