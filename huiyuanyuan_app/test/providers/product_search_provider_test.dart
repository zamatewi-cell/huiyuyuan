import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuanyuan/config/api_config.dart';
import 'package:huiyuanyuan/data/product_runtime_catalog.dart';
import 'package:huiyuanyuan/models/product_model.dart';
import 'package:huiyuanyuan/providers/product_catalog_provider.dart';
import 'package:huiyuanyuan/providers/product_search_provider.dart';
import 'package:huiyuanyuan/repositories/product_catalog_repository.dart';
import 'package:huiyuanyuan/services/api_service.dart';
import 'package:huiyuanyuan/services/product_service.dart';
import 'package:huiyuanyuan/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool originalUseMockApi;

  setUp(() async {
    originalUseMockApi = ApiConfig.useMockApi;
    ApiConfig.useMockApi = true;
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await StorageService().clearAll();
  });

  tearDown(() {
    ApiConfig.useMockApi = originalUseMockApi;
  });

  group('Product search provider', () {
    test('search should use shared catalog and expose derived categories',
        () async {
      final container = _createContainer(
        seedProducts: [
          _buildSeedProduct(
            id: 'A',
            name: 'search-alpha-bracelet',
            category: 'bracelet',
            price: 100,
          ),
          _buildSeedProduct(
            id: 'B',
            name: 'search-alpha-necklace',
            category: 'necklace',
            price: 300,
          ),
          _buildSeedProduct(
            id: 'C',
            name: 'search-beta-bracelet',
            category: 'bracelet',
            price: 200,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(productSearchProvider.notifier).search('alpha');

      final searchState = container.read(productSearchProvider);
      expect(searchState.showResults, isTrue);
      expect(
        searchState.results.map((product) => product.id).toList(),
        ['A', 'B'],
      );
      expect(
        container.read(productSearchResultCategoriesProvider),
        ['鍏ㄩ儴', 'bracelet', 'necklace'],
      );

      container.read(productSearchProvider.notifier).setFilterCategory(
            'bracelet',
          );
      expect(
        container
            .read(productSearchFilteredResultsProvider)
            .map((product) => product.id)
            .toList(),
        ['A'],
      );
    });

    test('hot products provider should rank shared catalog products', () async {
      final container = _createContainer(
        seedProducts: [
          _buildSeedProduct(id: 'A', name: 'plain-sales', salesCount: 50),
          _buildSeedProduct(
            id: 'B',
            name: 'hot-product',
            isHot: true,
            salesCount: 10,
          ),
          _buildSeedProduct(
            id: 'C',
            name: 'new-product',
            isNew: true,
            salesCount: 20,
          ),
          _buildSeedProduct(id: 'D', name: 'low-priority', salesCount: 5),
        ],
      );
      addTearDown(container.dispose);

      await container.read(productCatalogProvider.notifier).refresh();

      expect(
        container
            .read(productSearchHotProductsProvider)
            .map((product) => product.id)
            .toList(),
        ['B', 'C', 'A', 'D'],
      );
    });
  });
}

ProviderContainer _createContainer({
  required List<ProductModel> seedProducts,
}) {
  final repository = ProductCatalogRepository(
    runtimeCatalog: ProductRuntimeCatalog(seedProducts: seedProducts),
    storageService: StorageService(),
    runtimePersistenceKey:
        'product-search-provider-test-${seedProducts.length}-${DateTime.now().microsecondsSinceEpoch}',
  );
  final service = ProductService.forTesting(
    _UnexpectedApiService(),
    catalogRepository: repository,
  );

  return ProviderContainer(
    overrides: [
      productServiceProvider.overrideWithValue(service),
    ],
  );
}

class _UnexpectedApiService extends ApiService {
  _UnexpectedApiService() : super.forTesting();

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
        'product search provider test should not hit ApiService.get');
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
      'product search provider test should not hit ApiService.post',
    );
  }

  @override
  Future<ApiResult<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
        'product search provider test should not hit ApiService.put');
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
      'product search provider test should not hit ApiService.delete',
    );
  }
}

ProductModel _buildSeedProduct({
  required String id,
  required String name,
  String category = 'bracelet',
  double price = 399,
  int salesCount = 11,
  bool isHot = false,
  bool isNew = false,
}) {
  return ProductModel(
    id: id,
    name: name,
    description: 'search provider seed product',
    price: price,
    category: category,
    material: 'jade',
    images: const ['https://example.com/search-provider.jpg'],
    stock: 6,
    salesCount: salesCount,
    isHot: isHot,
    isNew: isNew,
  );
}
