import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/data/product_runtime_catalog.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/models/product_upsert_request.dart';
import 'package:huiyuyuan/providers/inventory_provider.dart';
import 'package:huiyuyuan/providers/product_catalog_provider.dart';
import 'package:huiyuyuan/repositories/product_catalog_repository.dart';
import 'package:huiyuyuan/services/api_service.dart';
import 'package:huiyuyuan/services/product_service.dart';
import 'package:huiyuyuan/services/storage_service.dart';

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

  group('Product catalog provider', () {
    test('refresh should expose seed-backed products and categories', () async {
      final container = _createContainer(
        seedProducts: [
          _buildSeedProduct(id: 'SEED-001', category: 'bracelet'),
          _buildSeedProduct(id: 'SEED-002', category: 'pendant'),
          _buildSeedProduct(id: 'SEED-003', category: 'bracelet'),
        ],
      );
      addTearDown(container.dispose);

      await container.read(productCatalogProvider.notifier).refresh();

      final state = container.read(productCatalogProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(
        state.products.map((product) => product.id).toList(growable: false),
        ['SEED-001', 'SEED-002', 'SEED-003'],
      );
      expect(
        container.read(productCatalogCategoriesProvider),
        [productCatalogAllCategory, '手链', '吊坠'],
      );
    });

    test('createProduct should refresh shared provider state', () async {
      final container = _createContainer(
        seedProducts: [_buildSeedProduct(id: 'SEED-001')],
        localProductIdBuilder: () => 'LOCAL-001',
      );
      addTearDown(container.dispose);

      await container.read(productCatalogProvider.notifier).refresh();
      final created =
          await container.read(productCatalogProvider.notifier).createProduct(
                const ProductUpsertRequest(
                  name: 'provider-local-product',
                  description: 'runtime product',
                  price: 288,
                  category: 'bracelet',
                  material: 'jade',
                  stock: 8,
                ),
              );

      expect(created, isNotNull);
      final state = container.read(productCatalogProvider);
      expect(state.products, hasLength(2));
      expect(
        state.products.any((product) => product.id == 'LOCAL-001'),
        isTrue,
      );
    });

    test('inventoryProvider should sync when catalog products change',
        () async {
      final container = _createContainer(
        seedProducts: [_buildSeedProduct(id: 'SEED-001')],
        localProductIdBuilder: () => 'LOCAL-INV-001',
      );
      addTearDown(container.dispose);

      await container.read(productCatalogProvider.notifier).refresh();
      await container.read(inventoryProvider.notifier).refresh();

      expect(
        container
            .read(inventoryProvider)
            .map((item) => item.productId)
            .toList(),
        ['SEED-001'],
      );

      await container.read(productCatalogProvider.notifier).createProduct(
            const ProductUpsertRequest(
              name: 'inventory-linked-product',
              description: 'runtime product',
              price: 399,
              category: 'bracelet',
              material: 'jade',
              stock: 4,
            ),
          );
      await Future<void>.delayed(Duration.zero);

      expect(
        container
            .read(inventoryProvider)
            .map((item) => item.productId)
            .toList(),
        ['SEED-001', 'LOCAL-INV-001'],
      );

      await container
          .read(productCatalogProvider.notifier)
          .deleteProduct('SEED-001');
      await Future<void>.delayed(Duration.zero);

      expect(
        container
            .read(inventoryProvider)
            .map((item) => item.productId)
            .toList(),
        ['LOCAL-INV-001'],
      );
    });
  });
}

ProviderContainer _createContainer({
  required List<ProductModel> seedProducts,
  String Function()? localProductIdBuilder,
}) {
  final repository = ProductCatalogRepository(
    runtimeCatalog: ProductRuntimeCatalog(seedProducts: seedProducts),
    storageService: StorageService(),
    runtimePersistenceKey:
        'product-catalog-provider-test-${seedProducts.length}-${DateTime.now().microsecondsSinceEpoch}',
    localProductIdBuilder: localProductIdBuilder,
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
        'mock catalog provider tests should not hit ApiService.get');
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
        'mock catalog provider tests should not hit ApiService.post');
  }

  @override
  Future<ApiResult<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
        'mock catalog provider tests should not hit ApiService.put');
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
      'mock catalog provider tests should not hit ApiService.delete',
    );
  }
}

ProductModel _buildSeedProduct({
  required String id,
  String category = 'bracelet',
  String material = 'jade',
}) {
  return ProductModel(
    id: id,
    name: 'seed-$id',
    description: 'seed product',
    price: 399,
    category: category,
    material: material,
    images: const ['https://example.com/seed.jpg'],
    stock: 6,
    salesCount: 11,
  );
}
