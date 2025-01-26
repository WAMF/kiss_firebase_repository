// ignore_for_file: avoid_dynamic_calls

typedef FormatConvert = dynamic Function(dynamic value);

class FieldFormat {
  FieldFormat({
    this.name,
    this.convert,
  });

  factory FieldFormat.preserveType(String named) {
    return FieldFormat(
      name: named,
      convert: (value) => value,
    );
  }

  factory FieldFormat.convertMap({
    required MapConverter destinationFormat,
    String? named,
  }) {
    return FieldFormat(
      name: named,
      convert: (value) {
        if (value is Map<String, dynamic>) {
          return destinationFormat.convert(source: value);
        }
        return value;
      },
    );
  }
  final String? name;
  final FormatConvert? convert;

  static String? _defaultStringConverter(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    final stringValue = value.toString();
    return stringValue.isEmpty ? null : stringValue;
  }

  static final defaultconverters = {
    'string': _defaultStringConverter,
    'string_uppercase': (dynamic value) =>
        _defaultStringConverter(value)?.toUpperCase(),
    'string_lowercase': (dynamic value) =>
        _defaultStringConverter(value)?.toLowerCase(),
    'number': (dynamic value) {
      if (value is num) {
        return value;
      }
      if (value is String) {
        return num.tryParse(value);
      }
      if (value is DateTime) {
        return value.millisecondsSinceEpoch;
      }
      return null;
    },
    'double': (dynamic value) {
      if (value is double) {
        return value;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      if (value is DateTime) {
        return value.microsecondsSinceEpoch.toDouble();
      }
      return null;
    },
    'bool': (dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is double) {
        return value < 1;
      }
      if (value is int) {
        return value > 0;
      }
      if (value is String) {
        final lowerCase = value.toLowerCase();
        return lowerCase.startsWith('t') ||
            value.startsWith('y') ||
            value.startsWith('on');
      }
      return null;
    },
    'datetime': (dynamic value) {
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is double) {
        return DateTime.fromMicrosecondsSinceEpoch(value.toInt());
      }
      return null;
    },
    'duration': (dynamic value) {
      if (value is Duration) {
        return value;
      }
      if (value is String) {
        final milliseconds = int.tryParse(value);
        if (milliseconds != null) {
          return Duration(milliseconds: milliseconds);
        }
      }
      if (value is num) {
        return Duration(milliseconds: value.toInt());
      }
      if (value is DateTime) {
        throw Exception('Cannot convert DateTime to Duration');
      }
      return null;
    },
  };
}

class MapConverter {
  MapConverter({
    required this.map,
    Map<String, Object? Function(dynamic)>? customconverters,
  }) {
    converters.addAll(FieldFormat.defaultconverters);
    if (customconverters != null) {
      converters.addAll(customconverters);
    }
  }

  factory MapConverter.fromJson(Map<String, Object?> json) {
    final map = <String, FieldFormat>{};
    for (final key in json.keys) {
      final value = json[key];
      if (value is String) {
        map[key] = FieldFormat.preserveType(key);
      } else if (value is Map<String, Object?>) {
        final type = value['type'];
        final named = value['name'] as String?;
        if (type is Map<String, dynamic>) {
          map[key] = FieldFormat.convertMap(
            named: named ?? key,
            destinationFormat: MapConverter.fromJson(type),
          );
          continue;
        }
        final converter = FieldFormat.defaultconverters[type];
        if (converter != null) {
          map[key] = FieldFormat(
            name: named ?? key,
            convert: converter,
          );
        } else {
          map[key] = FieldFormat.preserveType(
            named ?? key,
          );
        }
      } else {
        throw ArgumentError.value(
          value,
          'value',
          'Invalid value for key $key in ${json[key]}',
        );
      }
    }
    return MapConverter(map: map);
  }

  factory MapConverter.typeConverstion(FormatConvert conversion) {
    return MapConverter(map: {'*': FieldFormat(convert: conversion)});
  }
  final Map<String, FieldFormat> map;
  final Map<String, Object? Function(dynamic)> converters = {};

  Map<String, dynamic> convert({
    required Map<String, dynamic> source,
  }) {
    final destination = <String, dynamic>{};

    // go through key key in the map and convert based on the name (remap) and
    // the conversion (type)
    for (final key in map.keys) {
      final format = map[key];
      if (source.containsKey(key)) {
        final value = valueForKey(key, source);
        setValue(
          destination,
          format?.name ?? key,
          format?.convert != null ? format?.convert?.call(value) : value,
        );
      }
    }

    //* is a special case convert all keys not listed
    if (map.keys.contains('*')) {
      for (final key in source.keys) {
        if (!map.keys.contains(key)) {
          final format = map['*'];
          final value = valueForKey(key, source);
          setValue(
            destination,
            key,
            format?.convert != null ? format?.convert?.call(value) : value,
          );
        }
      }
    }
    return destination;
  }

  void setValue(Map<String, dynamic> destination, String key, dynamic value) {
    final path = key.split('.');
    if (path.length > 1) {
      var map = destination[path[0]];
      if (map == null) {
        map = <String, dynamic>{};
        destination[path[0]] = map;
      }
      for (var i = 1; i < path.length - 1; i++) {
        var nextMap = map[path[i]];
        if (nextMap == null) {
          nextMap = <String, dynamic>{};
          map[path[i]] = nextMap;
        }
        map = nextMap;
      }
      map[path.last] = value;
      return;
    }
    destination[key] = value;
  }

  dynamic valueForKey(String key, Map<String, dynamic> sourceData) {
    final path = key.split('.');
    if (path.length > 1) {
      var value = sourceData[path[0]];
      for (var i = 1; i < path.length; i++) {
        if (value is Map<String, dynamic>) {
          value = value[path[i]];
        } else {
          return null;
        }
      }
      return value;
    }
    return sourceData[key];
  }

  MapConverter copyWith({
    Map<String, FieldFormat>? map,
    Map<String, Object? Function(dynamic)>? customconverters,
  }) {
    return MapConverter(
      map: map ?? this.map,
      customconverters: customconverters ?? converters,
    );
  }
}
