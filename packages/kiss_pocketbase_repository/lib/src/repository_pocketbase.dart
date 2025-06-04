import 'dart:async';

import 'package:pocketbase/pocketbase.dart';
import 'package:kiss_repository/kiss_repository.dart';

class RepositoryPocketBase<T> extends Repository<T> {
  RepositoryPocketBase({
    required this.client,
    required this.collection,
    required this.fromPocketBase,
    required this.toPocketBase,
    this.queryBuilder,
  });

  final PocketBase client;
  final String collection;
  final T Function(RecordModel record) fromPocketBase;
  final Map<String, dynamic> Function(T object) toPocketBase;
  final QueryBuilder<String>? queryBuilder;

  @override
  String get path => collection;

  @override
  Future<T> get(String id) async {
    try {
      final record = await client.collection(collection).getOne(id);
      return fromPocketBase(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw RepositoryException.notFound(id);
      }
      throw RepositoryException(message: 'Failed to get record: ${e.response}');
    } catch (e) {
      throw RepositoryException(message: 'Failed to get record: $e');
    }
  }

  @override
  Future<T> add(IdentifiedObject<T> item) async {
    try {
      final data = toPocketBase(item.object);

      // If ID is provided and not empty, include it
      if (item.id.isNotEmpty) {
        data['id'] = item.id;
      }

      final record = await client.collection(collection).create(body: data);
      return fromPocketBase(record);
    } on ClientException catch (e) {
      if (e.statusCode == 400 && e.response?['data'] != null) {
        final errors = e.response!['data'] as Map;
        if (errors.containsKey('id')) {
          throw RepositoryException.alreadyExists(item.id);
        }
      }
      throw RepositoryException(
        message: 'Failed to add record: ${e.response ?? e.toString()}',
      );
    } catch (e) {
      throw RepositoryException(message: 'Failed to add record: $e');
    }
  }

  @override
  Future<T> update(String id, T Function(T current) updater) async {
    try {
      // First get the current record
      final currentRecord = await client.collection(collection).getOne(id);
      final current = fromPocketBase(currentRecord);

      // Apply the update function
      final updated = updater(current);
      final data = toPocketBase(updated);

      // Update the record
      final updatedRecord = await client
          .collection(collection)
          .update(id, body: data);
      return fromPocketBase(updatedRecord);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw RepositoryException.notFound(id);
      }
      throw RepositoryException(
        message: 'Failed to update record: ${e.response}',
      );
    } catch (e) {
      throw RepositoryException(message: 'Failed to update record: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await client.collection(collection).delete(id);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw RepositoryException.notFound(id);
      }
      throw RepositoryException(
        message: 'Failed to delete record: ${e.response}',
      );
    } catch (e) {
      throw RepositoryException(message: 'Failed to delete record: $e');
    }
  }

  @override
  Future<List<T>> query({Query query = const AllQuery()}) async {
    // TODO: Implement query functionality
    throw UnimplementedError('Query functionality not yet implemented');
  }

  @override
  Stream<T> stream(String id) {
    // TODO: Implement real-time streaming
    throw UnimplementedError('Streaming functionality not yet implemented');
  }

  @override
  Stream<List<T>> streamQuery({Query query = const AllQuery()}) {
    // TODO: Implement query streaming
    throw UnimplementedError('Query streaming not yet implemented');
  }

  @override
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items) async {
    // TODO: Implement batch add (sequential for now)
    throw UnimplementedError('Batch add not yet implemented');
  }

  @override
  Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items) async {
    // TODO: Implement batch update (sequential for now)
    throw UnimplementedError('Batch update not yet implemented');
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    // TODO: Implement batch delete (sequential for now)
    throw UnimplementedError('Batch delete not yet implemented');
  }

  @override
  Future<void> dispose() async {
    // Nothing to dispose for PocketBase
  }

  @override
  IdentifiedObject<T> autoIdentify(
    T object, {
    T Function(T object, String id)? updateObjectWithId,
  }) {
    // PocketBase auto-generates IDs, so we use empty string as placeholder
    return IdentifiedObject('', object);
  }

  @override
  Future<T> addAutoIdentified(
    T object, {
    T Function(T object, String id)? updateObjectWithId,
  }) async {
    try {
      final data = toPocketBase(object);

      final record = await client.collection(collection).create(body: data);

      // If updateObjectWithId is provided, use it to update the object with the generated ID
      if (updateObjectWithId != null) {
        return updateObjectWithId(object, record.id);
      }

      // Otherwise, convert the record back to T (which should include the ID)
      return fromPocketBase(record);
    } on ClientException catch (e) {
      if (e.statusCode == 400 && e.response?['data'] != null) {
        final errors = e.response!['data'] as Map;
        if (errors.containsKey('id')) {
          throw RepositoryException.alreadyExists('auto-generated');
        }
      }
      throw RepositoryException(
        message: 'Failed to add record: ${e.response}',
      );
    } catch (e) {
      throw RepositoryException(message: 'Failed to add record: $e');
    }
  }
}
