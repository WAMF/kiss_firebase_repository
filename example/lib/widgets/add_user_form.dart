import 'package:flutter/material.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import '../data_model.dart';

class AddProductForm extends StatefulWidget {
  final Repository<ProductModel> productRepository;
  final VoidCallback? onProductAdded;

  const AddProductForm({
    super.key,
    required this.productRepository,
    this.onProductAdded,
  });

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (_nameController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      _showSnackBar('Please fill in both name and price');
      return;
    }

    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      _showSnackBar('Please enter a valid price');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final product = ProductModel.create(
        name: _nameController.text.trim(),
        price: price,
        description: _descriptionController.text.trim(),
      );

      // Create product with auto-generated Firestore ID
      await widget.productRepository.addAutoIdentified(
        product,
        updateObjectWithId: (product, id) => product.copyWith(id: id),
      );

      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _showSnackBar('Product added successfully!');
      widget.onProductAdded?.call();
    } catch (e) {
      _showSnackBar('Error adding product: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add New Product',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _addProduct,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(_isLoading ? 'Adding...' : 'Add Product'),
          ),
        ],
      ),
    );
  }
}
