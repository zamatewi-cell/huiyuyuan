import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuanyuan/config/api_config.dart';
import 'package:huiyuanyuan/data/product_runtime_catalog.dart';
import 'package:huiyuanyuan/models/product_model.dart';
import 'package:huiyuanyuan/providers/auth_provider.dart';
import 'package:huiyuanyuan/providers/product_catalog_provider.dart';
import 'package:huiyuanyuan/repositories/product_catalog_repository.dart';
import 'package:huiyuanyuan/screens/trade/product_list_screen.dart';
import 'package:huiyuanyuan/services/api_service.dart';
import 'package:huiyuanyuan/services/product_service.dart';
import 'package:huiyuanyuan/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalOnError = FlutterError.onError;
  late bool originalUseMockApi;

  setUp(() async {
    originalUseMockApi = ApiConfig.useMockApi;
    ApiConfig.useMockApi = true;
    FlutterError.onError = (FlutterErrorDetails details) {
      final message = details.toString();
      if (message.contains('overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };

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

  Widget buildTestWidget({
    List<ProductModel> seedProducts = const <ProductModel>[],
  }) {
    final repository = ProductCatalogRepository(
      runtimeCatalog: ProductRuntimeCatalog(seedProducts: seedProducts),
      storageService: StorageService(),
      runtimePersistenceKey:
          'product-list-screen-test-${seedProducts.length}-${DateTime.now().microsecondsSinceEpoch}',
    );
    final service = ProductService.forTesting(
      _UnexpectedApiService(),
      catalogRepository: repository,
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(AuthNotifier.new),
        productServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(home: ProductListScreen()),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<ProductModel> seedProducts = const <ProductModel>[],
  }) async {
    await tester.pumpWidget(buildTestWidget(seedProducts: seedProducts));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('ProductListScreen renders scaffold', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('ProductListScreen shows AppBar area', (tester) async {
    await pumpScreen(tester);

    final appBars = find.byType(AppBar);
    final sliverAppBars = find.byType(SliverAppBar);
    expect(
      appBars.evaluate().isNotEmpty || sliverAppBars.evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('ProductListScreen contains scrollable content', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('ProductListScreen filters shared catalog categories', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      seedProducts: [
        _buildSeedProduct(id: 'A', name: 'screen-A', category: 'custom-alpha'),
        _buildSeedProduct(id: 'B', name: 'screen-B', category: 'custom-beta'),
      ],
    );

    expect(find.text('screen-A'), findsOneWidget);
    expect(find.text('screen-B'), findsOneWidget);
    expect(find.text('custom-alpha'), findsOneWidget);

    await tester.tap(find.text('custom-alpha'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('screen-A'), findsOneWidget);
    expect(find.text('screen-B'), findsNothing);
  });

  testWidgets('ProductListScreen renders on small screen', (tester) async {
    final currentOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.toString().contains('overflowed')) {
        return;
      }
      currentOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = currentOnError);

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpScreen(tester);

    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('ProductListScreen renders on large screen', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpScreen(tester);

    expect(find.byType(Scaffold), findsOneWidget);
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
    throw StateError('product list screen test should not hit ApiService.get');
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError('product list screen test should not hit ApiService.post');
  }

  @override
  Future<ApiResult<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError('product list screen test should not hit ApiService.put');
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
      'product list screen test should not hit ApiService.delete',
    );
  }
}

ProductModel _buildSeedProduct({
  required String id,
  required String name,
  required String category,
}) {
  return ProductModel(
    id: id,
    name: name,
    description: 'screen test product',
    price: 399,
    category: category,
    material: 'jade',
    images: const ['https://example.com/product.jpg'],
    stock: 8,
    salesCount: 12,
  );
}
