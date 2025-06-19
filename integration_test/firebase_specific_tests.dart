import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository_tests/kiss_repository_tests.dart';

import 'factories/firebase_repository_factory.dart';

void main() {
  late FirebaseRepositoryFactory factory;
  late Repository<ProductModel> repository;

  setUpAll(() async {
    await FirebaseRepositoryFactory.initialize();
    factory = FirebaseRepositoryFactory();
    repository = factory.createRepository();
  });

  setUp(() async {
    await factory.cleanup();
  });

  group('Firebase-Specific Behavior', () {
    testWidgets('addAutoIdentified without updateObjectWithId does not change the object', (WidgetTester tester) async {
      final productModel = ProductModel.create(name: 'ProductX', price: 9.99);

      final addedObject = await repository.addAutoIdentified(productModel);

      expect(addedObject.id, isEmpty);
      expect(addedObject.name, equals('ProductX'));
      expect(addedObject.price, equals(9.99));

      // Note: The object is saved to Firestore with a server-generated ID,
      // but the returned object maintains the original (empty) ID because
      // no updateObjectWithId function was provided
    });
  });
}
