import 'package:flutter/material.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import '../data_model.dart';

class ProductListWidget extends StatelessWidget {
  final Repository<ProductModel> productRepository;
  final Query query;

  const ProductListWidget({
    super.key,
    required this.productRepository,
    this.query = const AllQuery(),
  });

  Future<void> _deleteProduct(BuildContext context, String productId) async {
    try {
      await productRepository.delete(productId);
      if (context.mounted) {
        _showSnackBar(context, 'Product deleted successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error deleting product: $e');
      }
    }
  }

  Future<void> _updateProductName(
    BuildContext context,
    String productId,
    String currentName,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Product Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        await productRepository.update(
          productId,
          (product) => product.copyWith(name: newName),
        );
        if (context.mounted) {
          _showSnackBar(context, 'Product name updated successfully!');
        }
      } catch (e) {
        if (context.mounted) {
          _showSnackBar(context, 'Error updating product: $e');
        }
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: productRepository.streamQuery(query: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 8),
                const Text(
                  'Make sure Firebase emulator is running:\nfirebase emulators:start --only firestore',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No products found'),
                Text(
                  'Try adjusting your search or add some products',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$${product.price.toStringAsFixed(2)}'),
                    if (product.description.isNotEmpty)
                      Text(
                        product.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    Text(
                      'Created: ${product.created.toLocal().toString().split('.')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _updateProductName(context, product.id, product.name),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(context, product.id),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
