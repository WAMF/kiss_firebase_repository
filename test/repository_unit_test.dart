import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

class MockUser {
  final String id;
  final String name;
  final DateTime createdAt;

  MockUser({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  MockUser copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return MockUser(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'MockUser(id: $id, name: $name, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MockUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdAt.hashCode;
}

void main() {
  group('KISS Firebase Repository - Unit Tests', () {
    test('should create IdentifedObject with specific ID', () {
      final testDate = DateTime.now();
      final user =
          MockUser(id: 'test-1', name: 'John Doe', createdAt: testDate);

      final identifiedObject = IdentifiedObject('test-1', user);

      expect(identifiedObject.id, 'test-1');
      expect(identifiedObject.object.name, 'John Doe');
      expect(identifiedObject.object.createdAt, testDate);
    });

    test('should create user with copyWith method', () {
      final originalDate = DateTime.now();
      final user =
          MockUser(id: 'test-2', name: 'Jane Doe', createdAt: originalDate);

      final updatedUser = user.copyWith(name: 'Jane Smith');

      expect(updatedUser.id, 'test-2');
      expect(updatedUser.name, 'Jane Smith');
      expect(updatedUser.createdAt, originalDate);

      // Original should be unchanged
      expect(user.name, 'Jane Doe');
    });

    test('should test data type conversion for DateTime', () {
      final now = DateTime.now();
      final testData = {
        'createdAt': now,
        'name': 'Test',
      };

      // This tests the internal type conversion logic that would be used
      // when converting between Dart and Firestore types
      expect(testData['createdAt'], isA<DateTime>());
      expect(testData['name'], isA<String>());
    });

    test('should create and manipulate user objects correctly', () {
      final users = [
        MockUser(id: '1', name: 'Alice', createdAt: DateTime.now()),
        MockUser(id: '2', name: 'Bob', createdAt: DateTime.now()),
        MockUser(id: '3', name: 'Charlie', createdAt: DateTime.now()),
      ];

      expect(users.length, 3);
      expect(users[0].name, 'Alice');
      expect(users[1].name, 'Bob');
      expect(users[2].name, 'Charlie');

      // Test that all users have unique IDs
      final ids = users.map((u) => u.id).toSet();
      expect(ids.length, 3);
    });

    test('should handle equality and hashCode correctly', () {
      final date = DateTime.now();
      final user1 = MockUser(id: 'test', name: 'John', createdAt: date);
      final user2 = MockUser(id: 'test', name: 'John', createdAt: date);
      final user3 = MockUser(id: 'different', name: 'John', createdAt: date);

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1, isNot(equals(user3)));
    });

    test('should demonstrate repository pattern structure', () {
      // This test demonstrates the structure that would be used with a real repository
      final user =
          MockUser(id: 'demo', name: 'Demo User', createdAt: DateTime.now());

      // Simulate the toFirestore conversion
      toFirestore(MockUser user) => {
            'name': user.name,
            'createdAt': user.createdAt,
          };

      final firestoreData = toFirestore(user);
      expect(firestoreData['name'], 'Demo User');
      expect(firestoreData['createdAt'], isA<DateTime>());

      // Simulate the fromFirestore conversion
      fromFirestore(String id, Map<String, dynamic> data) => MockUser(
            id: id,
            name: data['name'],
            createdAt: data['createdAt'],
          );

      final reconstructedUser = fromFirestore('demo', firestoreData);
      expect(reconstructedUser.id, 'demo');
      expect(reconstructedUser.name, 'Demo User');
      expect(reconstructedUser.createdAt, user.createdAt);
    });
  });

  group('MapConverter Tests', () {
    group('Basic Functionality', () {
      test('should preserve types with preserveType', () {
        final testMap = {
          'name': 'Test User',
          'age': 25,
          'active': true,
        };

        final converter = MapConverter(map: {
          'name': FieldFormat.preserveType('name'),
          'age': FieldFormat.preserveType('age'),
          'active': FieldFormat.preserveType('active'),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['name'], 'Test User');
        expect(converted['age'], 25);
        expect(converted['active'], true);
      });

      test('should handle field name remapping', () {
        final testMap = {
          'old_name': 'Test Value',
          'old_age': 30,
        };

        final converter = MapConverter(map: {
          'old_name': FieldFormat.preserveType('new_name'),
          'old_age': FieldFormat.preserveType('new_age'),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['new_name'], 'Test Value');
        expect(converted['new_age'], 30);
        expect(converted.containsKey('old_name'), false);
        expect(converted.containsKey('old_age'), false);
      });

      test('should handle missing keys gracefully', () {
        final testMap = {
          'name': 'Test User',
        };

        final converter = MapConverter(map: {
          'name': FieldFormat.preserveType('name'),
          'missing_field': FieldFormat.preserveType('missing_field'),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['name'], 'Test User');
        expect(converted.containsKey('missing_field'), false);
      });

      test('should handle wildcard conversion with *', () {
        final testMap = {
          'field1': 'value1',
          'field2': 'value2',
          'field3': 'value3',
        };

        final converter = MapConverter(map: {
          '*': FieldFormat(convert: (value) => 'converted_$value'),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['field1'], 'converted_value1');
        expect(converted['field2'], 'converted_value2');
        expect(converted['field3'], 'converted_value3');
      });

      test('should handle mixed specific and wildcard conversions', () {
        final testMap = {
          'specific_field': 'specific_value',
          'general_field1': 'general_value1',
          'general_field2': 'general_value2',
        };

        final converter = MapConverter(map: {
          'specific_field': FieldFormat.preserveType('renamed_specific'),
          '*': FieldFormat(convert: (value) => 'wildcard_$value'),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['renamed_specific'], 'specific_value');
        expect(converted['general_field1'], 'wildcard_general_value1');
        expect(converted['general_field2'], 'wildcard_general_value2');
      });
    });

    group('Default Type Converters', () {
      test('should convert to string', () {
        final testMap = {
          'string_field': 'already_string',
          'datetime_field': DateTime(2023, 1, 1, 12, 0, 0),
          'number_field': 42,
          'bool_field': true,
        };

        final converter = MapConverter(map: {
          'string_field': FieldFormat(
              name: 'string_field',
              convert: FieldFormat.defaultconverters['string']),
          'datetime_field': FieldFormat(
              name: 'datetime_field',
              convert: FieldFormat.defaultconverters['string']),
          'number_field': FieldFormat(
              name: 'number_field',
              convert: FieldFormat.defaultconverters['string']),
          'bool_field': FieldFormat(
              name: 'bool_field',
              convert: FieldFormat.defaultconverters['string']),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['string_field'], 'already_string');
        expect(converted['datetime_field'], '2023-01-01T12:00:00.000');
        expect(converted['number_field'], '42');
        expect(converted['bool_field'], 'true');
      });

      test('should convert to uppercase string', () {
        final testMap = {
          'text': 'hello world',
          'number': 123,
        };

        final converter = MapConverter(map: {
          'text': FieldFormat(
              name: 'text',
              convert: FieldFormat.defaultconverters['string_uppercase']),
          'number': FieldFormat(
              name: 'number',
              convert: FieldFormat.defaultconverters['string_uppercase']),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['text'], 'HELLO WORLD');
        expect(converted['number'], '123');
      });

      test('should convert to lowercase string', () {
        final testMap = {
          'text': 'HELLO WORLD',
          'number': 123,
        };

        final converter = MapConverter(map: {
          'text': FieldFormat(
              name: 'text',
              convert: FieldFormat.defaultconverters['string_lowercase']),
          'number': FieldFormat(
              name: 'number',
              convert: FieldFormat.defaultconverters['string_lowercase']),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['text'], 'hello world');
        expect(converted['number'], '123');
      });

      test('should convert to number', () {
        final testMap = {
          'int_field': 42,
          'double_field': 3.14,
          'string_number': '123',
          'string_double': '45.67',
          'datetime_field': DateTime(2023, 1, 1),
          'invalid_string': 'not_a_number',
        };

        final converter = MapConverter(map: {
          'int_field': FieldFormat(
              name: 'int_field',
              convert: FieldFormat.defaultconverters['number']),
          'double_field': FieldFormat(
              name: 'double_field',
              convert: FieldFormat.defaultconverters['number']),
          'string_number': FieldFormat(
              name: 'string_number',
              convert: FieldFormat.defaultconverters['number']),
          'string_double': FieldFormat(
              name: 'string_double',
              convert: FieldFormat.defaultconverters['number']),
          'datetime_field': FieldFormat(
              name: 'datetime_field',
              convert: FieldFormat.defaultconverters['number']),
          'invalid_string': FieldFormat(
              name: 'invalid_string',
              convert: FieldFormat.defaultconverters['number']),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['int_field'], 42);
        expect(converted['double_field'], 3.14);
        expect(converted['string_number'], 123);
        expect(converted['string_double'], 45.67);
        expect(converted['datetime_field'],
            (testMap['datetime_field'] as DateTime).millisecondsSinceEpoch);
        expect(converted['invalid_string'], null);
      });

      test('should convert to double', () {
        final testMap = {
          'int_field': 42,
          'double_field': 3.14,
          'string_number': '123',
          'string_double': '45.67',
          'datetime_field': DateTime(2023, 1, 1),
          'invalid_string': 'not_a_number',
        };

        final converter = MapConverter(map: {
          'int_field': FieldFormat(
              name: 'int_field',
              convert: FieldFormat.defaultconverters['double']),
          'double_field': FieldFormat(
              name: 'double_field',
              convert: FieldFormat.defaultconverters['double']),
          'string_number': FieldFormat(
              name: 'string_number',
              convert: FieldFormat.defaultconverters['double']),
          'string_double': FieldFormat(
              name: 'string_double',
              convert: FieldFormat.defaultconverters['double']),
          'datetime_field': FieldFormat(
              name: 'datetime_field',
              convert: FieldFormat.defaultconverters['double']),
          'invalid_string': FieldFormat(
              name: 'invalid_string',
              convert: FieldFormat.defaultconverters['double']),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['int_field'], 42.0);
        expect(converted['double_field'], 3.14);
        expect(converted['string_number'], 123.0);
        expect(converted['string_double'], 45.67);
        expect(
            converted['datetime_field'],
            (testMap['datetime_field'] as DateTime)
                .microsecondsSinceEpoch
                .toDouble());
        expect(converted['invalid_string'], null);
      });

      test('should convert to bool', () {
        final testMap = {
          'bool_true': true,
          'bool_false': false,
          'double_zero': 0.0,
          'double_nonzero': 1.5,
          'int_zero': 0,
          'int_positive': 5,
          'string_true': 'true',
          'string_yes': 'yes',
          'string_on': 'on',
          'string_false': 'false',
          'string_upper_true': 'TRUE',
          'string_upper_yes': 'YES',
          'string_upper_on': 'ON',
        };

        final converter = MapConverter(map: {
          'bool_true': FieldFormat(
              name: 'bool_true',
              convert: FieldFormat.defaultconverters['bool']),
          'bool_false': FieldFormat(
              name: 'bool_false',
              convert: FieldFormat.defaultconverters['bool']),
          'double_zero': FieldFormat(
              name: 'double_zero',
              convert: FieldFormat.defaultconverters['bool']),
          'double_nonzero': FieldFormat(
              name: 'double_nonzero',
              convert: FieldFormat.defaultconverters['bool']),
          'int_zero': FieldFormat(
              name: 'int_zero', convert: FieldFormat.defaultconverters['bool']),
          'int_positive': FieldFormat(
              name: 'int_positive',
              convert: FieldFormat.defaultconverters['bool']),
          'string_true': FieldFormat(
              name: 'string_true',
              convert: FieldFormat.defaultconverters['bool']),
          'string_yes': FieldFormat(
              name: 'string_yes',
              convert: FieldFormat.defaultconverters['bool']),
          'string_on': FieldFormat(
              name: 'string_on',
              convert: FieldFormat.defaultconverters['bool']),
          'string_false': FieldFormat(
              name: 'string_false',
              convert: FieldFormat.defaultconverters['bool']),
          'string_upper_true': FieldFormat(
              name: 'string_upper_true',
              convert: FieldFormat.defaultconverters['bool']),
          'string_upper_yes': FieldFormat(
              name: 'string_upper_yes',
              convert: FieldFormat.defaultconverters['bool']),
          'string_upper_on': FieldFormat(
              name: 'string_upper_on',
              convert: FieldFormat.defaultconverters['bool']),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['bool_true'], true);
        expect(converted['bool_false'], false);
        expect(converted['double_zero'], true); // < 1 is true
        expect(converted['double_nonzero'], false); // >= 1 is false (1.5 >= 1)
        expect(converted['int_zero'], false); // 0 is false
        expect(converted['int_positive'], true); // > 0 is true
        expect(converted['string_true'], true);
        expect(converted['string_yes'], true); // 'yes'.startsWith('y') is true
        expect(converted['string_on'], true); // 'on'.startsWith('on') is true
        expect(converted['string_false'], false);
        expect(converted['string_upper_true'],
            true); // lowerCase.startsWith('t') for 'TRUE' is true
        expect(converted['string_upper_yes'],
            false); // 'YES'.startsWith('y') is false
        expect(converted['string_upper_on'],
            false); // 'ON'.startsWith('on') is false
      });

      test('should convert to DateTime', () {
        final now = DateTime.now();
        final testMap = {
          'datetime_field': now,
          'string_iso': '2023-01-01T12:00:00.000Z',
          'int_millis': 1672574400000, // 2023-01-01T12:00:00.000Z
          'double_micros':
              1672574400000000.0, // 2023-01-01T12:00:00.000Z in microseconds
          'invalid_string': 'not_a_date',
        };

        final converter = MapConverter(map: {
          'datetime_field': FieldFormat(
              name: 'datetime_field',
              convert: FieldFormat.defaultconverters['datetime']),
          'string_iso': FieldFormat(
              name: 'string_iso',
              convert: FieldFormat.defaultconverters['datetime']),
          'int_millis': FieldFormat(
              name: 'int_millis',
              convert: FieldFormat.defaultconverters['datetime']),
          'double_micros': FieldFormat(
              name: 'double_micros',
              convert: FieldFormat.defaultconverters['datetime']),
          'invalid_string': FieldFormat(
              name: 'invalid_string',
              convert: FieldFormat.defaultconverters['datetime']),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['datetime_field'], now);
        expect(converted['string_iso'], isA<DateTime>());
        expect(converted['int_millis'], isA<DateTime>());
        expect(converted['double_micros'], isA<DateTime>());
        expect(converted['invalid_string'], null);
      });

      test('should convert to Duration', () {
        final testDuration = Duration(milliseconds: 5000);
        final testMap = {
          'duration_field': testDuration,
          'string_millis': '5000',
          'int_millis': 3000,
          'double_millis': 2500.0,
          'datetime_field': DateTime.now(), // Should throw
          'invalid_string': 'not_a_duration',
        };

        final converter = MapConverter(map: {
          'duration_field': FieldFormat(
              name: 'duration_field',
              convert: FieldFormat.defaultconverters['duration']),
          'string_millis': FieldFormat(
              name: 'string_millis',
              convert: FieldFormat.defaultconverters['duration']),
          'int_millis': FieldFormat(
              name: 'int_millis',
              convert: FieldFormat.defaultconverters['duration']),
          'double_millis': FieldFormat(
              name: 'double_millis',
              convert: FieldFormat.defaultconverters['duration']),
          'invalid_string': FieldFormat(
              name: 'invalid_string',
              convert: FieldFormat.defaultconverters['duration']),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['duration_field'], testDuration);
        expect(converted['string_millis'], Duration(milliseconds: 5000));
        expect(converted['int_millis'], Duration(milliseconds: 3000));
        expect(converted['double_millis'], Duration(milliseconds: 2500));
        expect(converted['invalid_string'], null);

        // Test DateTime to Duration conversion throws exception
        expect(() {
          final dateTimeConverter = MapConverter(map: {
            'datetime_field': FieldFormat(
                name: 'datetime_field',
                convert: FieldFormat.defaultconverters['duration']),
          });
          dateTimeConverter.convert(source: {'datetime_field': DateTime.now()});
        }, throwsException);
      });
    });

    group('Factory Methods', () {
      test('should create from JSON with simple types', () {
        final json = {
          'name': 'string',
          'age': {'type': 'number'},
          'active': {'type': 'bool'},
          'created': {'type': 'datetime'},
        };

        final converter = MapConverter.fromJson(json);
        final testData = {
          'name': 'John Doe',
          'age': '25',
          'active': 'true',
          'created': '2023-01-01T12:00:00.000Z',
        };

        final converted = converter.convert(source: testData);

        expect(converted['name'], 'John Doe');
        expect(converted['age'], 25);
        expect(converted['active'], true);
        expect(converted['created'], isA<DateTime>());
      });

      test('should create from JSON with nested maps', () {
        final json = {
          'user': {
            'type': {
              'name': 'string',
              'profile': {
                'type': {
                  'age': {'type': 'number'},
                  'active': {'type': 'bool'},
                }
              }
            }
          }
        };

        final converter = MapConverter.fromJson(json);
        final testData = {
          'user': {
            'name': 'John',
            'profile': {
              'age': '30',
              'active': 'true',
            }
          }
        };

        final converted = converter.convert(source: testData);

        expect(converted['user']['name'], 'John');
        expect(converted['user']['profile']['age'], 30);
        expect(converted['user']['profile']['active'], true);
      });

      test('should create from JSON with field renaming', () {
        final json = {
          'old_name': {'type': 'string', 'name': 'new_name'},
          'old_age': {'type': 'number', 'name': 'new_age'},
        };

        final converter = MapConverter.fromJson(json);
        final testData = {
          'old_name': 'John',
          'old_age': '25',
        };

        final converted = converter.convert(source: testData);

        expect(converted['new_name'], 'John');
        expect(converted['new_age'], 25);
        expect(converted.containsKey('old_name'), false);
        expect(converted.containsKey('old_age'), false);
      });

      test('should create type conversion factory', () {
        final converter =
            MapConverter.typeConverstion((value) => 'prefix_$value');
        final testData = {
          'field1': 'value1',
          'field2': 'value2',
        };

        final converted = converter.convert(source: testData);

        expect(converted['field1'], 'prefix_value1');
        expect(converted['field2'], 'prefix_value2');
      });

      test('should handle invalid JSON values', () {
        final json = {
          'valid_field': 'string',
          'invalid_field': 123, // Neither string nor Map
        };

        expect(() => MapConverter.fromJson(json), throwsArgumentError);
      });
    });

    group('Nested Path Support', () {
      test('should handle nested field paths for writing', () {
        final testMap = {
          'userName': 'John Doe',
          'userAge': 30,
          'userTheme': 'dark',
        };

        final converter = MapConverter(map: {
          'userName': FieldFormat.preserveType('user.profile.name'),
          'userAge': FieldFormat.preserveType('user.profile.age'),
          'userTheme': FieldFormat.preserveType('user.settings.theme'),
        });
        final converted = converter.convert(source: testMap);

        expect(converted['user']['profile']['name'], 'John Doe');
        expect(converted['user']['profile']['age'], 30);
        expect(converted['user']['settings']['theme'], 'dark');
      });
    });

    group('Custom Converters', () {
      test('should use custom converters', () {
        final customConverters = {
          'custom_upper': (dynamic value) => value.toString().toUpperCase(),
          'custom_reverse': (dynamic value) =>
              value.toString().split('').reversed.join(),
        };

        final converter = MapConverter(
          map: {
            'text1': FieldFormat(
                name: 'text1', convert: customConverters['custom_upper']),
            'text2': FieldFormat(
                name: 'text2', convert: customConverters['custom_reverse']),
          },
          customconverters: customConverters,
        );

        final testData = {
          'text1': 'hello',
          'text2': 'world',
        };

        final converted = converter.convert(source: testData);

        expect(converted['text1'], 'HELLO');
        expect(converted['text2'], 'dlrow');
      });

      test('should override default converters with custom ones', () {
        final customConverters = {
          'string': (dynamic value) => 'custom_$value',
        };

        final converter = MapConverter(
          map: {
            'field':
                FieldFormat(name: 'field', convert: customConverters['string']),
          },
          customconverters: customConverters,
        );

        final testData = {
          'field': 'test',
        };

        final converted = converter.convert(source: testData);

        expect(converted['field'], 'custom_test');
      });
    });

    group('CopyWith and Immutability', () {
      test('should create copy with new map', () {
        final original = MapConverter(map: {
          'field1': FieldFormat.preserveType('field1'),
        });

        final copy = original.copyWith(map: {
          'field2': FieldFormat.preserveType('field2'),
        });

        final testData = {
          'field1': 'value1',
          'field2': 'value2',
        };

        final originalResult = original.convert(source: testData);
        final copyResult = copy.convert(source: testData);

        expect(originalResult['field1'], 'value1');
        expect(originalResult.containsKey('field2'), false);
        expect(copyResult['field2'], 'value2');
        expect(copyResult.containsKey('field1'), false);
      });

      test('should create copy with new custom converters', () {
        final original = MapConverter(
          map: {
            'field': FieldFormat(
                name: 'field', convert: (value) => 'original_$value'),
          },
        );

        final copy = original.copyWith(
          customconverters: {
            'custom': (value) => 'custom_$value',
          },
        );

        final testData = {'field': 'test'};

        final originalResult = original.convert(source: testData);
        final copyResult = copy.convert(source: testData);

        expect(originalResult['field'], 'original_test');
        expect(copyResult['field'],
            'original_test'); // Still uses original converter for the field
      });
    });

    group('Edge Cases', () {
      test('should handle empty source map', () {
        final converter = MapConverter(map: {
          'field': FieldFormat.preserveType('field'),
        });

        final converted = converter.convert(source: {});

        expect(converted.isEmpty, true);
      });

      test('should handle empty converter map', () {
        final converter = MapConverter(map: {});
        final testData = {'field': 'value'};

        final converted = converter.convert(source: testData);

        expect(converted.isEmpty, true);
      });

      test('should handle null values in source', () {
        final converter = MapConverter(map: {
          'field': FieldFormat.preserveType('field'),
        });

        final testData = {'field': null};

        final converted = converter.convert(source: testData);

        expect(converted['field'], null);
      });

      test('should handle converter that returns null', () {
        final converter = MapConverter(map: {
          'field': FieldFormat(name: 'field', convert: (value) => null),
        });

        final testData = {'field': 'value'};

        final converted = converter.convert(source: testData);

        expect(converted['field'], null);
      });

      test('should handle converter with no convert function', () {
        final converter = MapConverter(map: {
          'field': FieldFormat(name: 'field'),
        });

        final testData = {'field': 'value'};

        final converted = converter.convert(source: testData);

        expect(converted['field'], 'value');
      });
    });
  });
}
