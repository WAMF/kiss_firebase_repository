import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository_tests/kiss_repository_tests.dart';

/// Firebase-specific query builder for ProductModel
class FirestoreProductQueryBuilder implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery = firestore.FirebaseFirestore.instance.collection('products');

    if (query is QueryByName) {
      final prefix = query.namePrefix;
      return baseQuery
          .where('name', isGreaterThanOrEqualTo: prefix)
          .where('name', isLessThan: '$prefix\uf8ff')
          .orderBy('name');
    }

    if (query is QueryByPriceRange) {
      firestore.Query<Map<String, dynamic>> result = baseQuery;
      if (query.minPrice != null) {
        result = result.where('price', isGreaterThanOrEqualTo: query.minPrice);
      }
      if (query.maxPrice != null) {
        result = result.where('price', isLessThanOrEqualTo: query.maxPrice);
      }
      return result.orderBy('price');
    }

    // Default: return all objects ordered by creation date (newest first)
    return baseQuery.orderBy('created', descending: true);
  }
}
