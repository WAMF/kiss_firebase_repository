import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'queries.dart';

/// Firebase-specific query builder for ProductModel
class FirestoreProductModelQueryBuilder implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
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

    if (query is QueryByCreatedAfter) {
      return baseQuery.where('created', isGreaterThan: firestore.Timestamp.fromDate(query.date)).orderBy('created');
    }

    if (query is QueryByCreatedBefore) {
      return baseQuery
          .where('created', isLessThan: firestore.Timestamp.fromDate(query.date))
          .orderBy('created', descending: true);
    }

    if (query is QueryByPriceGreaterThan) {
      return baseQuery.where('price', isGreaterThan: query.price).orderBy('price');
    }

    if (query is QueryByPriceLessThan) {
      return baseQuery.where('price', isLessThan: query.price).orderBy('price', descending: true);
    }

    // Default: return all objects ordered by creation date (newest first)
    return baseQuery.orderBy('created', descending: true);
  }
}
