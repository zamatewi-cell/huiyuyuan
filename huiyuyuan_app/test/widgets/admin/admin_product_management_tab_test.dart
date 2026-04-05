import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/data/product_runtime_catalog.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/providers/product_catalog_provider.dart';
import 'package:huiyuyuan/repositories/product_catalog_repository.dart';
import 'package:huiyuyuan/services/api_service.dart';
import 'package:huiyuyuan/services/product_service.dart';
import 'package:huiyuyuan/services/storage_service.dart';
import 'package:huiyuyuan/widgets/admin/admin_product_management_tab.dart';

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

  testWidgets('AdminProductManagementTab filters shared catalog products', (
    tester,
  ) async {
    final repository = ProductCatalogRepository(
      runtimeCatalog: ProductRuntimeCatalog(
        seedProducts: [
          _buildSeedProduct(id: 'A', name: 'alpha-bracelet'),
          _buildSeedProduct(id: 'B', name: 'beta-pendant'),
        ],
      ),
      storageService: StorageService(),
      runtimePersistenceKey:
          'admin-product-management-test-${DateTime.now().microsecondsSinceEpoch}',
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
          home: Scaffold(body: AdminProductManagementTab()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('alpha-bracelet'), findsOneWidget);
    expect(find.text('beta-pendant'), findsOneWidget);

    final textField = find.byType(TextField).first;
    await tester.enterText(textField, 'alpha');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('alpha-bracelet'), findsOneWidget);
    expect(find.text('beta-pendant'), findsNothing);
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
    throw StateError(
      'admin product management tab test should not hit ApiService.get',
    );
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
      'admin product management tab test should not hit ApiService.post',
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
      'admin product management tab test should not hit ApiService.put',
    );
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? params,
    T Function(dynamic data)? fromJson,
  }) {
    throw StateError(
      'admin product management tab test should not hit ApiService.delete',
    );
  }
}

ProductModel _buildSeedProduct({
  required String id,
  required String name,
}) {
  return ProductModel(
    id: id,
    name: name,
    description: 'admin widget test product',
    price: 299,
    category: 'bracelet',
    material: 'jade',
    images: const [],
    stock: 6,
    salesCount: 9,
  );
}
