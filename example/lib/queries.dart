import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

class QueryByName extends Query {
  final String searchTerm;

  const QueryByName(this.searchTerm);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByName &&
          runtimeType == other.runtimeType &&
          searchTerm == other.searchTerm;

  @override
  int get hashCode => searchTerm.hashCode;

  @override
  String toString() => 'QueryByName(searchTerm: $searchTerm)';
}

class QueryByEmail extends Query {
  final String emailDomain;

  const QueryByEmail(this.emailDomain);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByEmail &&
          runtimeType == other.runtimeType &&
          emailDomain == other.emailDomain;

  @override
  int get hashCode => emailDomain.hashCode;

  @override
  String toString() => 'QueryByEmail(emailDomain: $emailDomain)';
}

class QueryRecentUsers extends Query {
  final int daysAgo;

  const QueryRecentUsers(this.daysAgo);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryRecentUsers &&
          runtimeType == other.runtimeType &&
          daysAgo == other.daysAgo;

  @override
  int get hashCode => daysAgo.hashCode;

  @override
  String toString() => 'QueryRecentUsers(daysAgo: $daysAgo)';
}
