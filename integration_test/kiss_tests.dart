import 'package:kiss_repository_tests/kiss_repository_tests.dart';

import 'factories/firebase_repository_factory.dart';

void main() {
  runRepositoryTests(
    implementationName: 'Firebase',
    factoryProvider: FirebaseRepositoryFactory.new,
    cleanup: () {},
  );
}
