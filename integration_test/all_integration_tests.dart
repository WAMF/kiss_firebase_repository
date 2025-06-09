import 'package:flutter_test/flutter_test.dart';

import 'kiss_tests.dart' as kiss_tests;

void main() {
  group('All Firebase Integration Tests', () {
    group('KISS Tests', kiss_tests.main);
  });
}
