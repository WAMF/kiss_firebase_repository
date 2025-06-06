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

class QueryByMaxAge extends Query {
  final int maxAge;

  const QueryByMaxAge(this.maxAge);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByMaxAge &&
          runtimeType == other.runtimeType &&
          maxAge == other.maxAge;

  @override
  int get hashCode => maxAge.hashCode;

  @override
  String toString() => 'QueryByMaxAge(maxAge: $maxAge)';
}
