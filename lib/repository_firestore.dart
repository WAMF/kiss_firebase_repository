import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:kiss_firebase_repository/map_converter.dart';
import 'package:kiss_repository/kiss_repository.dart';

/// Special IdentifiedObject subclass that generates IDs on-demand
class FirestoreIdentifiedObject<T> extends IdentifiedObject<T> {
  FirestoreIdentifiedObject(T object, this._updateObjectWithId, this._repository) : super('', object);

  final T Function(T object, String id) _updateObjectWithId;
  final RepositoryFirestore<T> _repository;
  String? _cachedId;
  T? _cachedUpdatedObject;

  @override
  String get id {
    _cachedId ??= _generateFirestoreId();
    return _cachedId!;
  }

  @override
  T get object {
    if (_cachedUpdatedObject == null) {
      final generatedId = id; // This will generate and cache the ID if needed
      _cachedUpdatedObject = _updateObjectWithId(super.object, generatedId);
    }
    return _cachedUpdatedObject!;
  }

  /// Generates a real Firestore document ID using the repository's collection
  String _generateFirestoreId() {
    final doc = _repository.store.collection(_repository.path).doc();
    return doc.id;
  }

  /// Convenience factory method for creating objects with auto-generated IDs
  factory FirestoreIdentifiedObject.create(
          T object, T Function(T object, String id) updateObjectWithId, RepositoryFirestore<T> repository) =>
      FirestoreIdentifiedObject(object, updateObjectWithId, repository);
}

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
  static final typeConversionFromFirebase = MapConverter.typeConverstion(_firebaseToDartTypeConversion);
  static final typeConversionToFirebase = MapConverter.typeConverstion(_dartToFirebaseTypeConversion);
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
    final firebaseData = RepositoryFirestore.typeConversionFromFirebase.convert(source: snapshot.data() ?? {});
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

  /// Creates a real-time stream of changes for a specific document.
  ///
  /// **Initial Emission**: Immediately emits existing data (BehaviorSubject-like).
  /// **Deletion Behavior**: Firebase filters out deleted documents. Stream ends on deletion.
  @override
  Stream<T> stream(String id) {
    return store.doc(_normaliseToFullPath(id)).snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) {
        throw RepositoryException.notFound(id);
      }
      final data = snapshot.data()!;
      return fromFirestore(
        snapshot.reference,
        RepositoryFirestore.typeConversionFromFirebase.convert(
          source: data,
        ),
      );
    });
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
  Future<T> add(IdentifiedObject<T> item) async {
    await _ensureNotExists(item.id);

    final doc = store.doc(_normaliseToFullPath(item.id));
    final json = RepositoryFirestore.typeConversionToFirebase.convert(
      source: toFirestore(item.object),
    );
    await doc.set(json);
    final newSnapshot = await doc.get();

    final data = newSnapshot.data();
    if (data == null) {
      throw RepositoryException.notFound(item.id);
    }

    return fromFirestore(
      newSnapshot.reference,
      RepositoryFirestore.typeConversionFromFirebase.convert(
        source: data,
      ),
    );
  }

  @override
  Future<T> update(String id, T Function(T current) updater) async {
    final doc = store.doc(_normaliseToFullPath(id));
    final json = RepositoryFirestore.typeConversionToFirebase.convert(
      source: toFirestore(updater(await get(id))),
    );
    await doc.update(json);
    final snapshot = await doc.get();

    final data = snapshot.data();
    if (data == null) {
      throw RepositoryException.notFound(id);
    }

    return fromFirestore(
      snapshot.reference,
      RepositoryFirestore.typeConversionFromFirebase.convert(
        source: data,
      ),
    );
  }

  @override
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items) async {
    final batch = store.batch();

    for (final item in items) {
      await _ensureNotExists(item.id);
      final doc = store.doc(_normaliseToFullPath(item.id));
      final json = RepositoryFirestore.typeConversionToFirebase.convert(
        source: toFirestore(item.object),
      );
      batch.set(doc, json);
    }
    await batch.commit();
    return items.map((e) => e.object).toList(growable: false);
  }

  @override
  Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items) async {
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

  @override
  Future<void> dispose() async {
    // Nothing to do here
  }

  @override
  IdentifiedObject<T> autoIdentify(
    T object, {
    T Function(T object, String id)? updateObjectWithId,
  }) {
    return FirestoreIdentifiedObject(
      object,
      updateObjectWithId ?? (object, id) => object,
      this,
    );
  }

  @override
  Future<T> addAutoIdentified(T object, {T Function(T object, String id)? updateObjectWithId}) async {
    final autoIdentifiedObject = autoIdentify(object, updateObjectWithId: updateObjectWithId);
    return add(autoIdentifiedObject);
  }

  Future<void> _ensureNotExists(String id) async {
    final doc = store.doc(_normaliseToFullPath(id));
    final snapshot = await doc.get();
    if (snapshot.exists) {
      throw RepositoryException.alreadyExists(id);
    }
  }
}
