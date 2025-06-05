import 'dart:math';

import 'package:kiss_repository/kiss_repository.dart';

class PocketBaseUtils {
  static String generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      15,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static bool isValidId(String id) {
    if (id.length != 15) return false;

    final validChars = RegExp(r'^[a-z0-9]+$');
    return validChars.hasMatch(id);
  }

  static void validateId(String id) {
    if (!isValidId(id)) {
      throw RepositoryException(
        message:
            'Invalid PocketBase ID format. ID must be exactly 15 characters '
            'and contain only lowercase alphanumeric characters (a-z0-9). '
            'Got: "$id" (length: ${id.length})',
      );
    }
  }
}
