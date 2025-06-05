import 'dart:async';

import 'package:pocketbase/pocketbase.dart';
import 'package:kiss_repository/kiss_repository.dart';

import 'utils/pocketbase_utils.dart';

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
    PocketBaseUtils.validateId(item.id);

    try {
      final data = toPocketBase(item.object);

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
      final currentRecord = await client.collection(collection).getOne(id);
      final current = fromPocketBase(currentRecord);

      final updated = updater(current);
      final data = toPocketBase(updated);

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
        // Silently succeed for non-existent records
        return;
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
    try {
      String? filter;
      String? sort;

      if (query is AllQuery) {
        sort = '-created';
      } else if (queryBuilder != null) {
        filter = queryBuilder!.build(query);
      } else {
        throw RepositoryException(
          message:
              'Query builder required for custom queries. '
              'Please provide a QueryBuilder<String> in the repository constructor.',
        );
      }

      final records = await client
          .collection(collection)
          .getFullList(filter: filter, sort: sort ?? '-created');

      return records.map((record) => fromPocketBase(record)).toList();
    } on ClientException catch (e) {
      throw RepositoryException(
        message: 'Failed to query records: ${e.response ?? e.toString()}',
      );
    } catch (e) {
      throw RepositoryException(message: 'Failed to query records: $e');
    }
  }

  @override
  Stream<T> stream(String id) {
    PocketBaseUtils.validateId(id);

    late StreamController<T> controller;
    bool isSubscribed = false;

    controller = StreamController<T>(
      onListen: () async {
        try {
          await client.collection(collection).subscribe(id, (event) {
            try {
              final record = event.record;
              if (record != null) {
                final domainObject = fromPocketBase(record);
                controller.add(domainObject);
              }
            } catch (e) {
              controller.addError(
                RepositoryException(
                  message: 'Failed to process stream event: $e',
                ),
              );
            }
          });
          isSubscribed = true;

          try {
            final initialData = await get(id);
            controller.add(initialData);
          } catch (e) {
            // If record doesn't exist initially, that's ok - we'll get it when created
            // Don't emit error, just wait for real-time events
          }
        } catch (e) {
          controller.addError(
            RepositoryException(
              message: 'Failed to establish stream subscription: $e',
            ),
          );
        }
      },
      onCancel: () async {
        if (isSubscribed) {
          try {
            await client.collection(collection).unsubscribe(id);
          } catch (e) {
            // Log error but don't throw - cleanup should be best effort
            print('Warning: Failed to unsubscribe from PocketBase stream: $e');
          }
        }
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<T>> streamQuery({Query query = const AllQuery()}) {
    late StreamController<List<T>> controller;
    bool isSubscribed = false;

    controller = StreamController<List<T>>(
      onListen: () async {
        try {
          await client.collection(collection).subscribe('*', (event) async {
            try {
              final results = await this.query(query: query);
              controller.add(results);
            } catch (e) {
              controller.addError(
                RepositoryException(
                  message: 'Failed to process stream query event: $e',
                ),
              );
            }
          });
          isSubscribed = true;

          try {
            final initialData = await this.query(query: query);
            controller.add(initialData);
          } catch (e) {
            controller.addError(
              RepositoryException(
                message: 'Failed to get initial stream query data: $e',
              ),
            );
          }
        } catch (e) {
          controller.addError(
            RepositoryException(
              message: 'Failed to establish stream query subscription: $e',
            ),
          );
        }
      },
      onCancel: () async {
        if (isSubscribed) {
          try {
            await client.collection(collection).unsubscribe('*');
          } catch (e) {
            print(
              'Warning: Failed to unsubscribe from PocketBase stream query: $e',
            );
          }
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items) async {
    final results = <T>[];
    final exceptions = <String, Exception>{};

    for (final item in items) {
      try {
        final result = await add(item);
        results.add(result);
      } catch (e) {
        exceptions[item.id] = e is Exception ? e : Exception(e);
      }
    }

    if (exceptions.isNotEmpty) {
      throw RepositoryException(
        message:
            'Batch add failed for ${exceptions.length} items: ${exceptions.keys.join(', ')}',
      );
    }

    return results;
  }

  @override
  Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items) async {
    final results = <T>[];
    final exceptions = <String, Exception>{};

    for (final item in items) {
      try {
        final result = await update(item.id, (_) => item.object);
        results.add(result);
      } catch (e) {
        exceptions[item.id] = e is Exception ? e : Exception(e);
      }
    }

    if (exceptions.isNotEmpty) {
      throw RepositoryException(
        message:
            'Batch update failed for ${exceptions.length} items: ${exceptions.keys.join(', ')}',
      );
    }

    return results;
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    final exceptions = <String, Exception>{};

    for (final id in ids) {
      try {
        await delete(id);
      } catch (e) {
        exceptions[id] = e is Exception ? e : Exception(e);
      }
    }

    if (exceptions.isNotEmpty) {
      throw RepositoryException(
        message:
            'Batch delete failed for ${exceptions.length} items: ${exceptions.keys.join(', ')}',
      );
    }
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
      throw RepositoryException(message: 'Failed to add record: ${e.response}');
    } catch (e) {
      throw RepositoryException(message: 'Failed to add record: $e');
    }
  }
}
