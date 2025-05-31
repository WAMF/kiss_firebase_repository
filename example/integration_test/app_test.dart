import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kiss_firebase_repository_example/main.dart' as app;
import 'dart:async';

class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'User(id: $id, name: $name, email: $email, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ email.hashCode ^ createdAt.hashCode;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('KISS Firebase Repository - Integration Tests', () {
    late RepositoryFirestore<User> repository;

    setUpAll(() async {
      print('🔥 Initializing Firebase for integration testing...');

      try {
        // Add timeout to Firebase initialization
        await Future.any([
          Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: 'AIzaSyC_l_test_api_key_for_emulator',
              appId: '1:123456789:web:123456789abcdef',
              messagingSenderId: '123456789',
              projectId: 'kiss-test-project',
            ),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Firebase initialization timed out',
                const Duration(seconds: 10),
              );
            },
          ),
          Future.delayed(const Duration(seconds: 15), () {
            throw TimeoutException(
              'Overall setup timed out',
              const Duration(seconds: 15),
            );
          }),
        ]);

        print('✅ Firebase initialized successfully');
        print('🔗 Configuring Firestore emulator...');

        // Try multiple host configurations for iOS compatibility
        String emulatorHost = '0.0.0.0'; // Default fallback
        // Configure Firestore to use emulator
        FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);

        print('✅ Firebase configured for emulator integration testing');

        // Test connection to emulator with timeout
        print('🧪 Testing Firestore connection...');
        final testCollection = FirebaseFirestore.instance.collection(
          'test_connection',
        );
        await testCollection
            .doc('test')
            .set({'timestamp': DateTime.now()})
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw TimeoutException(
                  'Firestore connection test timed out',
                  const Duration(seconds: 5),
                );
              },
            );
        print('✅ Successfully connected to Firestore emulator');
      } catch (e) {
        print('⚠️ Firebase initialization error: $e');
        print('📋 Error details: ${e.toString()}');
        print('🔍 Error type: ${e.runtimeType}');

        // Firebase might already be initialized
        if (e.toString().contains('already')) {
          print('🔄 Firebase already initialized, proceeding...');
        } else {
          print('❌ Fatal Firebase initialization error');
          rethrow;
        }
      }
    });

    setUp(() async {
      print('🧪 Setting up integration test...');

      // Create a fresh repository for each test
      repository = RepositoryFirestore<User>(
        path: 'integration_test_users',
        toFirestore: (user) => {
          'name': user.name,
          'email': user.email,
          'createdAt': user.createdAt,
        },
        fromFirestore: (ref, data) => User(
          id: ref.id,
          name: data['name'],
          email: data['email'],
          createdAt: (data['createdAt'] as DateTime),
        ),
      );

      // Clear the collection before each test
      await _clearCollection('integration_test_users');
    });

    tearDown(() async {
      // Clean up after each test
      await _clearCollection('integration_test_users');
      await repository.dispose();
    });

    testWidgets('should initialize example app and Firebase', (
      WidgetTester tester,
    ) async {
      // Launch the example app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app launched
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify Firebase is working
      expect(Firebase.apps.isNotEmpty, true);
    });

    testWidgets('should add and retrieve user with specific ID', (
      WidgetTester tester,
    ) async {
      // Launch the example app
      app.main();
      await tester.pumpAndSettle();

      final testDate = DateTime.now();
      final user = User(
        id: 'integration-test-user-1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        createdAt: testDate,
      );

      final addedUser = await repository.add(
        IdentifedObject('integration-test-user-1', user),
      );

      expect(addedUser.id, 'integration-test-user-1');
      expect(addedUser.name, 'John Doe');
      expect(addedUser.email, 'john.doe@example.com');
      expect(
        addedUser.createdAt.millisecondsSinceEpoch,
        testDate.millisecondsSinceEpoch,
      );

      final retrievedUser = await repository.get('integration-test-user-1');
      expect(retrievedUser.id, 'integration-test-user-1');
      expect(retrievedUser.name, 'John Doe');
      expect(retrievedUser.email, 'john.doe@example.com');
      expect(
        retrievedUser.createdAt.millisecondsSinceEpoch,
        testDate.millisecondsSinceEpoch,
      );
    });

    testWidgets('should create user with auto-generated Firestore ID', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      final createdAt = DateTime.now();

      // Use repository helper to create FirestoreIdentifiedObject with real Firestore ID
      final autoItem = repository.createWithAutoId(
        User(
          id: '', // This will be ignored - Firestore generates its own ID
          name: 'Jane Smith',
          email: 'jane.smith@example.com',
          createdAt: createdAt,
        ),
        (user, id) => user.copyWith(id: id),
      );

      // The ID is generated using Firestore's document reference
      final generatedId = autoItem.id;
      expect(generatedId, isNotEmpty);
      expect(generatedId.length, 20); // Firestore IDs are 20 characters

      // Subsequent accesses return the same cached ID
      expect(autoItem.id, equals(generatedId));

      // The object now has the Firestore-generated ID populated
      expect(autoItem.object.id, equals(generatedId));
      expect(autoItem.object.name, 'Jane Smith');
      expect(autoItem.object.email, 'jane.smith@example.com');

      final createdUser = await repository.add(autoItem);

      // Verify the user was created with the Firestore-generated ID
      expect(createdUser.id, generatedId);
      expect(createdUser.name, 'Jane Smith');
      expect(createdUser.email, 'jane.smith@example.com');
      expect(
        createdUser.createdAt.millisecondsSinceEpoch,
        createdAt.millisecondsSinceEpoch,
      );

      // Verify we can retrieve the user by the generated ID
      final retrievedUser = await repository.get(generatedId);
      expect(retrievedUser.id, generatedId);
      expect(retrievedUser.name, 'Jane Smith');
      expect(retrievedUser.email, 'jane.smith@example.com');
    });

    testWidgets('should update existing user', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First, create a user
      final user = User(
        id: 'update-test-integration',
        name: 'Original Name',
        email: 'original.name@example.com',
        createdAt: DateTime.now(),
      );
      await repository.add(IdentifedObject('update-test-integration', user));

      // Then update the user
      final updatedUser = await repository.update('update-test-integration', (
        current,
      ) {
        return current.copyWith(name: 'Updated Name');
      });

      expect(updatedUser.id, 'update-test-integration');
      expect(updatedUser.name, 'Updated Name');
      expect(updatedUser.email, 'original.name@example.com');
      expect(updatedUser.createdAt, user.createdAt);
    });

    testWidgets('should delete user', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a user
      final user = User(
        id: 'delete-test-integration',
        name: 'To Be Deleted',
        email: 'to.be.deleted@example.com',
        createdAt: DateTime.now(),
      );
      await repository.add(IdentifedObject('delete-test-integration', user));

      // Verify user exists
      final retrievedUser = await repository.get('delete-test-integration');
      expect(retrievedUser.name, 'To Be Deleted');

      // Delete the user
      await repository.delete('delete-test-integration');

      // Verify user no longer exists
      expect(
        () => repository.get('delete-test-integration'),
        throwsA(isA<RepositoryException>()),
      );
    });

    testWidgets('should handle batch operations', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final users = [
        IdentifedObject(
          'batch-integration-1',
          User(
            id: 'batch-integration-1',
            name: 'User 1',
            email: 'user1@example.com',
            createdAt: DateTime.now(),
          ),
        ),
        IdentifedObject(
          'batch-integration-2',
          User(
            id: 'batch-integration-2',
            name: 'User 2',
            email: 'user2@example.com',
            createdAt: DateTime.now(),
          ),
        ),
        IdentifedObject(
          'batch-integration-3',
          User(
            id: 'batch-integration-3',
            name: 'User 3',
            email: 'user3@example.com',
            createdAt: DateTime.now(),
          ),
        ),
      ];

      // Add all users in batch
      await repository.addAll(users);

      // Verify all users were added
      final user1 = await repository.get('batch-integration-1');
      final user2 = await repository.get('batch-integration-2');
      final user3 = await repository.get('batch-integration-3');

      expect(user1.name, 'User 1');
      expect(user2.name, 'User 2');
      expect(user3.name, 'User 3');

      // Delete all users in batch
      await repository.deleteAll([
        'batch-integration-1',
        'batch-integration-2',
        'batch-integration-3',
      ]);

      // Verify all users were deleted
      expect(
        () => repository.get('batch-integration-1'),
        throwsA(isA<RepositoryException>()),
      );
      expect(
        () => repository.get('batch-integration-2'),
        throwsA(isA<RepositoryException>()),
      );
      expect(
        () => repository.get('batch-integration-3'),
        throwsA(isA<RepositoryException>()),
      );
    });

    testWidgets('should query all users', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Add some test users
      final users = [
        IdentifedObject(
          'query-integration-1',
          User(
            id: 'query-integration-1',
            name: 'Alice',
            email: 'alice@example.com',
            createdAt: DateTime.now(),
          ),
        ),
        IdentifedObject(
          'query-integration-2',
          User(
            id: 'query-integration-2',
            name: 'Bob',
            email: 'bob@example.com',
            createdAt: DateTime.now(),
          ),
        ),
        IdentifedObject(
          'query-integration-3',
          User(
            id: 'query-integration-3',
            name: 'Charlie',
            email: 'charlie@example.com',
            createdAt: DateTime.now(),
          ),
        ),
      ];

      await repository.addAll(users);

      // Query all users
      final allUsers = await repository.query();
      expect(allUsers.length, 3);

      final names = allUsers.map((u) => u.name).toSet();
      expect(names.contains('Alice'), true);
      expect(names.contains('Bob'), true);
      expect(names.contains('Charlie'), true);
    });

    testWidgets('should stream user changes', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final userId = 'stream-test-integration';
      final user = User(
        id: userId,
        name: 'Initial',
        email: 'initial@example.com',
        createdAt: DateTime.now(),
      );

      // Start listening to changes
      final streamFuture = repository.stream(userId).first;

      // Add the user
      await repository.add(IdentifedObject(userId, user));

      // Wait for the stream to emit the user
      final streamedUser = await streamFuture;
      expect(streamedUser.name, 'Initial');
    });
  });
}

/// Helper function to clear a Firestore collection in the emulator
Future<void> _clearCollection(String collectionPath) async {
  try {
    final collection = FirebaseFirestore.instance.collection(collectionPath);
    final snapshot = await collection.get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
      print(
        '🧹 Cleared ${snapshot.docs.length} documents from $collectionPath',
      );
    }
  } catch (e) {
    print('⚠️ Error clearing collection $collectionPath: $e');
  }
}
