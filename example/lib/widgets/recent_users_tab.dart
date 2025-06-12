import 'package:flutter/material.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import '../data_model.dart';
import '../queries.dart';
import 'user_list_widget.dart';

class RecentProductsTab extends StatelessWidget {
  final Repository<ProductModel> productRepository;
  final int daysBack;

  const RecentProductsTab({
    super.key,
    required this.productRepository,
    this.daysBack = 7,
  });

  @override
  Widget build(BuildContext context) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recent Products (Last $daysBack Days)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ProductListWidget(
              productRepository: productRepository,
              query: QueryByCreatedAfter(cutoffDate),
            ),
          ),
        ),
      ],
    );
  }
}
