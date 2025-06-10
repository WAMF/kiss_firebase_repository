// KISS Firebase Repository Example App
//
// This example app demonstrates the full capabilities of the kiss_firebase_repository
// package in a real Flutter application. It showcases:
//
// 1. RepositoryFirestore setup with type-safe conversions
// 2. Auto-generated Firestore IDs using createWithAutoId()
// 3. Real-time streaming with streamQuery()
// 4. Full CRUD operations (Create, Read, Update, Delete)
// 5. Error handling and user feedback
// 6. Firebase emulator integration for development
// 7. Custom Query system with QueryBuilder and search functionality
//
// The app is fully integrated with integration tests in ../integration_test/app_test.dart
// which verify that all repository operations work correctly with a real Firebase instance.
//
// To run the app with Firebase emulator:
//   cd example && ./scripts/run_with_emulator.sh
//
// To run integration tests:
//   cd example && ./scripts/run_integration_tests.sh
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'data_model.dart';
import 'firestore_query_builder.dart';
import 'widgets/add_user_form.dart';
import 'widgets/user_list_widget.dart';
import 'widgets/search_tab.dart';
import 'widgets/recent_users_tab.dart';
import 'widgets/repository_info_widget.dart';

void _log(String message) {
  // ignore: avoid_print
  print(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyC_l_test_api_key_for_emulator',
        appId: '1:123456789:web:123456789abcdef',
        messagingSenderId: '123456789',
        projectId: 'kiss-test-project',
      ),
    );
    try {
      firestore.FirebaseFirestore.instance.useFirestoreEmulator(
        '0.0.0.0',
        8080,
      );
      _log('🔥 Using Firestore emulator at 0.0.0.0:8080');
    } catch (e) {
      _log('⚠️ Could not connect to Firestore emulator: $e');
      _log('💡 Make sure to run: firebase emulators:start --only firestore');
    }

    _log('✅ Firebase initialized successfully');
  } catch (e) {
    _log('⚠️ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KISS Firebase Repository Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const ProductManagementPage(),
    );
  }
}

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> with TickerProviderStateMixin {
  late final RepositoryFirestore<ProductModel> _productRepository;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _initializeRepository() {
    const collectionPath = 'products';
    _productRepository = RepositoryFirestore<ProductModel>(
      path: collectionPath,
      toFirestore: (product) => {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'description': product.description,
        'created': firestore.Timestamp.fromDate(product.created),
      },
      fromFirestore: (ref, data) => ProductModel(
        id: ref.id,
        name: data['name'] ?? '',
        price: (data['price'] ?? 0.0).toDouble(),
        description: data['description'] ?? '',
        created: (data['created'] as firestore.Timestamp).toDate(),
      ),
      queryBuilder: FirestoreProductModelQueryBuilder(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KISS Firebase Repository Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Products'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.schedule), text: 'Recent'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Add Product Form
          AddProductForm(productRepository: _productRepository),

          // Tabbed Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ProductListWidget(productRepository: _productRepository),
                SearchTab(productRepository: _productRepository),
                RecentProductsTab(productRepository: _productRepository),
              ],
            ),
          ),

          // Repository Info
          const RepositoryInfoWidget(),
        ],
      ),
    );
  }
}
