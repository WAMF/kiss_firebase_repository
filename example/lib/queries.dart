import 'package:kiss_repository/kiss_repository.dart';

class QueryByName extends Query {
  final String namePrefix;
  const QueryByName(this.namePrefix);
}

class QueryByCreatedAfter extends Query {
  final DateTime date;
  const QueryByCreatedAfter(this.date);
}

class QueryByCreatedBefore extends Query {
  final DateTime date;
  const QueryByCreatedBefore(this.date);
}

class QueryByPriceGreaterThan extends Query {
  final double price;
  const QueryByPriceGreaterThan(this.price);
}

class QueryByPriceLessThan extends Query {
  final double price;
  const QueryByPriceLessThan(this.price);
}
