import 'package:flutter/material.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import '../data_model.dart';
import '../queries.dart';
import 'user_list_widget.dart';

class SearchTab extends StatefulWidget {
  final Repository<ProductModel> productRepository;

  const SearchTab({super.key, required this.productRepository});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Search Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by name',
                  hintText: 'Enter product name to search...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search Results
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _searchController.text.isEmpty ? 'All Products' : 'Search Results for "${_searchController.text}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _searchController.text.isEmpty
                      ? ProductListWidget(productRepository: widget.productRepository)
                      : ProductListWidget(
                          productRepository: widget.productRepository,
                          query: QueryByName(_searchController.text),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
