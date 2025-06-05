import 'dart:math';

import 'package:kiss_repository/kiss_repository.dart';

/// Utilities for PocketBase ID handling and validation
class PocketBaseUtils {
  /// Generate a valid PocketBase ID (15 characters, lowercase alphanumeric)
  static String generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      15,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Validate if an ID meets PocketBase requirements
  static bool isValidId(String id) {
    if (id.isEmpty) return true; // Empty ID is valid for auto-generation
    if (id.length != 15) return false;

    // Must contain only lowercase alphanumeric characters
    final validChars = RegExp(r'^[a-z0-9]+$');
    return validChars.hasMatch(id);
  }

  /// Validate ID and throw appropriate exception if invalid
  static void validateId(String id) {
    if (id.isNotEmpty && !isValidId(id)) {
      throw RepositoryException(
        message:
            'Invalid PocketBase ID format. ID must be exactly 15 characters '
            'and contain only lowercase alphanumeric characters (a-z0-9). '
            'Got: "$id" (length: ${id.length})',
      );
    }
  }
}
