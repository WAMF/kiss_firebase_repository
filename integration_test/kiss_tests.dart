import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_repository_tests/test.dart';

import 'factories/firebase_repository_factory.dart';

void main() {
  setUpAll(() async {
    await FirebaseRepositoryFactory.initialize();
  });

  final factory = FirebaseRepositoryFactory();
  final tester = RepositoryTester('Firebase', factory, () {});

  // ignore: cascade_invocations
  tester.run();
}
