import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:kiss_firebase_repository_example/queries.dart';

class FirestoreUserQueryBuilder
    implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  final String collectionPath;

  FirestoreUserQueryBuilder(this.collectionPath);

  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery = firestore.FirebaseFirestore.instance.collection(
      collectionPath,
    );

    if (query is QueryByName) {
      // Search for users by name (case-insensitive contains)
      // Note: Firestore has limited text search capabilities, so we use array-contains
      // or implement client-side filtering for more complex search
      if (query.searchTerm.isNotEmpty) {
        // For exact match or prefix search, we can use range queries
        final searchTermLower = query.searchTerm.toLowerCase();
        return baseQuery
            .where('name', isGreaterThanOrEqualTo: searchTermLower)
            .where('name', isLessThan: '${searchTermLower}z')
            .orderBy('name');
      }
    }

    if (query is QueryByEmail) {
      // Search for users by email domain
      if (query.emailDomain.isNotEmpty) {
        // Use array-contains for email domain search
        // Note: This requires storing email domains separately or using different approach
        return baseQuery
            .where('email', isGreaterThanOrEqualTo: '@${query.emailDomain}')
            .where('email', isLessThan: '@${query.emailDomain}z')
            .orderBy('email');
      }
    }

    if (query is QueryByMaxAge) {
      return baseQuery
          .where('age', isLessThanOrEqualTo: query.maxAge)
          .orderBy('age', descending: true);
    }

    // Default: return all users ordered by creation date (newest first)
    return baseQuery.orderBy('createdAt', descending: true);
  }
}
