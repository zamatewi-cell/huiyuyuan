import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/data/product_runtime_catalog.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/providers/auth_provider.dart';
import 'package:huiyuyuan/providers/notification_provider.dart';
import 'package:huiyuyuan/providers/product_catalog_provider.dart';
import 'package:huiyuyuan/repositories/product_catalog_repository.dart';
import 'package:huiyuyuan/screens/trade/product_list_screen.dart';
import 'package:huiyuyuan/services/api_service.dart';
import 'package:huiyuyuan/services/product_service.dart';
import 'package:huiyuyuan/services/storage_service.dart';
import 'package:huiyuyuan/widgets/common/notification_badge_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/notification_test_helpers.dart';

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
    NotificationNotifier? notificationNotifier,
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
        if (notificationNotifier != null)
          notificationProvider.overrideWith((ref) => notificationNotifier)
        else
          notificationUnreadCountProvider.overrideWith((ref) => 0),
      ],
      child: const MaterialApp(home: ProductListScreen()),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<ProductModel> seedProducts = const <ProductModel>[],
    NotificationNotifier? notificationNotifier,
  }) async {
    await tester.pumpWidget(
      buildTestWidget(
        seedProducts: seedProducts,
        notificationNotifier: notificationNotifier,
      ),
    );
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

  testWidgets(
    'header badge clears after marking notifications as read in center',
    (tester) async {
      final notifier = StaticNotificationNotifier([
        NotificationItem(
          id: 'notification-1',
          title: 'Order shipped',
          body: 'Your order has been shipped.',
          type: NotificationType.order,
          time: DateTime(2026, 4, 4, 10, 0),
        ),
        NotificationItem(
          id: 'notification-2',
          title: 'Promotion update',
          body: 'A new campaign is now live.',
          type: NotificationType.promotion,
          time: DateTime(2026, 4, 4, 10, 1),
        ),
      ]);

      await pumpScreen(
        tester,
        notificationNotifier: notifier,
      );

      expect(find.byType(NotificationBadgeIcon), findsOneWidget);
      expect(notificationBadgeCount(tester), 2);

      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();

      expect(find.text('Order shipped'), findsWidgets);
      expect(find.text('Promotion update'), findsWidgets);
      expect(find.byType(TextButton), findsOneWidget);
      await markAllNotificationsAsRead(tester);

      expect(notifier.unreadCount, 0);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationBadgeIcon), findsOneWidget);
      expect(notificationBadgeCount(tester), 0);
    },
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
