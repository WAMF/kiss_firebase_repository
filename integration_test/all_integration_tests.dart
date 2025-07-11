import 'package:flutter_test/flutter_test.dart';

import 'firebase_specific_tests.dart' as firebase_specific_tests;
import 'kiss_tests.dart' as kiss_tests;

void main() {
  group('All Firebase Integration Tests', () {
    // KISS Repository Tests using Factory Pattern
    group('KISS Repository Tests', kiss_tests.main);

    // Firebase-specific implementation tests
    group('Firebase-Specific Tests', firebase_specific_tests.main);
  });
}
