import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/data/product_runtime_catalog.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/providers/product_catalog_provider.dart';
import 'package:huiyuyuan/repositories/product_catalog_repository.dart';
import 'package:huiyuyuan/screens/product/search_screen.dart';
import 'package:huiyuyuan/services/api_service.dart';
import 'package:huiyuyuan/services/product_service.dart';
import 'package:huiyuyuan/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool originalUseMockApi;

  setUp(() async {
    originalUseMockApi = ApiConfig.useMockApi;
    ApiConfig.useMockApi = true;

    const secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final store = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'write':
          store[call.arguments['key'] as String] =
              call.arguments['value'] as String? ?? '';
          return null;
        case 'read':
          return store[call.arguments['key'] as String];
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
        case 'deleteAll':
          store.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        case 'containsKey':
          return store.containsKey(call.arguments['key'] as String);
        default:
          return null;
      }
    });

    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await StorageService().clearAll();
  });

  tearDown(() {
    ApiConfig.useMockApi = originalUseMockApi;
  });

  testWidgets('SearchScreen initial query searches shared catalog', (
    tester,
  ) async {
    final repository = ProductCatalogRepository(
      runtimeCatalog: ProductRuntimeCatalog(
        seedProducts: [
          _buildSeedProduct(id: 'A', name: 'search-alpha'),
          _buildSeedProduct(id: 'B', name: 'search-beta'),
        ],
      ),
      storageService: StorageService(),
      runtimePersistenceKey:
          'search-screen-test-${DateTime.now().microsecondsSinceEpoch}',
    );
    final service = ProductService.forTesting(
      _UnexpectedApiService(),
      catalogRepository: repository,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: SearchScreen(initialQuery: 'search-alpha'),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('search-alpha'), findsOneWidget);
    expect(find.text('search-beta'), findsNothing);
  });
}

class _UnexpectedApiService extends ApiService {
  _UnexpectedApiService() : super.forTesting();

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError('search screen test should not hit ApiService.get');
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError('search screen test should not hit ApiService.post');
  }

  @override
  Future<ApiResult<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError('search screen test should not hit ApiService.put');
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError('search screen test should not hit ApiService.delete');
  }
}

ProductModel _buildSeedProduct({
  required String id,
  required String name,
}) {
  return ProductModel(
    id: id,
    name: name,
    description: 'search test product',
    price: 299,
    category: 'test-category',
    material: 'jade',
    images: const ['https://example.com/search.jpg'],
    stock: 6,
    salesCount: 9,
  );
}
