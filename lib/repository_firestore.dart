import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:kiss_firebase_repository/map_converter.dart';
import 'package:kiss_repository/kiss_repository.dart';

dynamic _firebaseToDartTypeConversion(dynamic value) {
  if (value is firestore.Timestamp) {
    return value.toDate();
  }
  if (value is Map<String, dynamic>) {
    final entries = value.entries.map((entry) {
      return MapEntry<String, dynamic>(
        entry.key,
        _firebaseToDartTypeConversion(entry.value),
      );
    });
    return Map<String, dynamic>.fromEntries(entries);
  }
  if (value is List) {
    return value.map(_firebaseToDartTypeConversion).toList();
  }
  return value;
}

dynamic _dartToFirebaseTypeConversion(dynamic value) {
  if (value is DateTime) {
    return firestore.Timestamp.fromDate(value);
  }
  if (value is Map<String, dynamic>) {
    final entries = value.entries.map((entry) {
      return MapEntry<String, dynamic>(
        entry.key,
        _dartToFirebaseTypeConversion(entry.value),
      );
    });
    return Map<String, dynamic>.fromEntries(entries);
  }
  if (value is List) {
    return value.map(_dartToFirebaseTypeConversion).toList();
  }
  return value;
}

class RepositoryFirestore<T> extends Repository<T> {
  RepositoryFirestore({
    required this.toFirestore,
    required this.fromFirestore,
    required this.path,
    firestore.FirebaseFirestore? store,
    this.queryBuilder,
    this.nativeQuery,
  }) {
    this.store = store ?? firestore.FirebaseFirestore.instance;
  }
  static final typeConversionFromFirebase =
      MapConverter.typeConverstion(_firebaseToDartTypeConversion);
  static final typeConversionToFirebase =
      MapConverter.typeConverstion(_dartToFirebaseTypeConversion);
  late final firestore.FirebaseFirestore store;
  @override
  final String path;
  final Map<String, dynamic> Function(T object) toFirestore;
  final T Function(
    firestore.DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) fromFirestore;
  final QueryBuilder<firestore.Query<Map<String, dynamic>>>? queryBuilder;
  firestore.Query<Map<String, dynamic>>? nativeQuery;

  String _normaliseToFullPath(String identifier) {
    if (!identifier.contains(path)) {
      return '$path/$identifier';
    }

    return identifier;
  }

  @override
  Future<T> get(String id) async {
    final firestoreRef = store.doc(_normaliseToFullPath(id));
    final snapshot = await firestoreRef.get();
    if (!snapshot.exists) {
      throw RepositoryException.notFound(id);
    }
    final firebaseData = RepositoryFirestore.typeConversionFromFirebase
        .convert(source: snapshot.data()!);
    return fromFirestore(
      snapshot.reference,
      firebaseData,
    );
  }

  @override
  Future<List<T>> query({Query query = const AllQuery()}) async {
    final firestoreQuery = nativeQuery ?? queryBuilder?.build(query);
    assert(firestoreQuery != null, 'query missing, native or builder required');
    final firestoreQueryResult = await firestoreQuery!.get();
    return firestoreQueryResult.docs
        .map(
          (snapshot) => fromFirestore(
            snapshot.reference,
            RepositoryFirestore.typeConversionFromFirebase.convert(
              source: snapshot.data(),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<T> stream(String id) {
    return store.doc(_normaliseToFullPath(id)).snapshots().map(
          (snapshot) => fromFirestore(
            snapshot.reference,
            RepositoryFirestore.typeConversionFromFirebase.convert(
              source: snapshot.data()!,
            ),
          ),
        );
  }

  @override
  Stream<List<T>> streamQuery({Query query = const AllQuery()}) {
    var firestoreQuery = nativeQuery;
    if (firestoreQuery == null) {
      if (query is AllQuery) {
        firestoreQuery = store.collection(path);
      } else {
        firestoreQuery ??= queryBuilder?.build(query);
      }
    }
    assert(firestoreQuery != null, 'query missing, native or builder required');
    return firestoreQuery!.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (snapshot) => fromFirestore(
              snapshot.reference,
              RepositoryFirestore.typeConversionFromFirebase.convert(
                source: snapshot.data(),
              ),
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> delete(String id) {
    final doc = store.doc(_normaliseToFullPath(id));
    try {
      return doc.delete();
    } on firestore.FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw RepositoryException.notFound(id);
      }
      rethrow;
    }
  }

  @override
  Future<T> add(T item) async {
    final json = RepositoryFirestore.typeConversionToFirebase.convert(
      source: toFirestore(item),
    );
    final newFirestoreObject = await store.collection(path).add(json);
    final snapshot = await newFirestoreObject.get();
    return fromFirestore(
      snapshot.reference,
      RepositoryFirestore.typeConversionFromFirebase.convert(
        source: snapshot.data()!,
      ),
    );
  }

  @override
  Future<T> addWithId(String id, T item) async {
    final doc = store.doc(_normaliseToFullPath(id));
    final snapshot = await doc.get();
    if (snapshot.exists) {
      throw RepositoryException.alreadyExists(id);
    }
    final json = RepositoryFirestore.typeConversionToFirebase.convert(
      source: toFirestore(item),
    );
    await doc.set(json);
    final newSnapshot = await doc.get();
    return fromFirestore(
      newSnapshot.reference,
      RepositoryFirestore.typeConversionFromFirebase.convert(
        source: snapshot.data()!,
      ),
    );
  }

  @override
  Future<T> update(String id, T Function(T current) updater) async {
    // todo: fix this
    final doc = store.doc(_normaliseToFullPath(id));
    final json = RepositoryFirestore.typeConversionToFirebase.convert(
      source: toFirestore(updater(await get(id))),
    );
    await doc.update(json);
    final snapshot = await doc.get();
    return fromFirestore(
      snapshot.reference,
      RepositoryFirestore.typeConversionFromFirebase.convert(
        source: snapshot.data()!,
      ),
    );
  }

  @override
  Future<Iterable<T>> addAll(Iterable<T> items) async {
    final batch = store.batch();
    for (final item in items) {
      final newFirestoreObject = store.collection(path).doc();
      final json = RepositoryFirestore.typeConversionToFirebase.convert(
        source: toFirestore(item),
      );
      batch.set(newFirestoreObject, json);
    }
    await batch.commit();
    return items;
  }

  @override
  Future<Iterable<T>> updateAll(Iterable<IdentifedObject<T>> items) async {
    final batch = store.batch();
    for (final item in items) {
      final existingFirestoreRef = store.doc(_normaliseToFullPath(item.id));
      final json = RepositoryFirestore.typeConversionToFirebase.convert(
        source: toFirestore(item.object),
      );
      batch.set(
        existingFirestoreRef,
        json,
        firestore.SetOptions(merge: true),
      );
    }
    await batch.commit();
    return items.map((e) => e.object).toList(growable: false);
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    final batch = store.batch();
    for (final id in ids) {
      batch.delete(store.doc(_normaliseToFullPath(id)));
    }
    await batch.commit();
  }
}
