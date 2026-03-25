// 汇玉源 - 购物流程集成测试
//
// 测试场景:
// 1. 购物车页面 UI
// 2. 购物车状态管理
// 3. 与存储服务集成
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:huiyuanyuan/screens/trade/cart_screen.dart';
import 'package:huiyuanyuan/services/storage_service.dart';

void _mockSecureStorage() {
  const MethodChannel ch = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final Map<String, String> store = {};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(ch, (call) async {
    switch (call.method) {
      case 'write':
        final v = call.arguments['value'] as String?;
        if (v != null) store[call.arguments['key'] as String] = v;
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
}

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _mockSecureStorage();
    storage = StorageService();
    await storage.init();
    await storage.clearAll();
  });

  group('购物车页面 UI 测试', () {
    testWidgets('购物车页面应正确加载', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证购物车页面存在
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('购物车应显示 AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证 AppBar 存在
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('购物车存储集成测试', () {
    test('添加商品后应能正确读取', () async {
      await storage.addToCart({
        'id': 'test_prod',
        'name': '测试商品',
        'price': 999,
      });

      final cart = await storage.getCart();
      expect(cart.length, 1);
      expect(cart.first['name'], '测试商品');
      expect(cart.first['quantity'], 1);
    });

    test('购物车应与存储同步', () async {
      // 添加多个商品
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});

      final cart = await storage.getCart();
      expect(cart.length, 2);

      // 清空
      await storage.clearCart();
      final emptyCart = await storage.getCart();
      expect(emptyCart, isEmpty);
    });

    test('更新数量应正确反映', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.updateCartQuantity('p1', 5);

      final cart = await storage.getCart();
      expect(cart.first['quantity'], 5);
    });

    test('数量为0时应移除商品', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.updateCartQuantity('p1', 0);

      final cart = await storage.getCart();
      expect(cart, isEmpty);
    });

    test('移除商品应正确工作', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});

      await storage.removeFromCart('p1');

      final cart = await storage.getCart();
      expect(cart.length, 1);
      expect(cart.first['id'], 'p2');
    });
  });

  group('金额计算测试', () {
    test('应正确计算总金额', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.updateCartQuantity('p1', 2);
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});
      await storage.updateCartQuantity('p2', 3);

      final cart = await storage.getCart();
      
      double total = cart.fold(0.0, (sum, item) {
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        return sum + price * quantity;
      });

      expect(total, 800.0); // 100*2 + 200*3
    });

    test('空购物车总金额应为 0', () async {
      final cart = await storage.getCart();
      
      double total = cart.fold(0.0, (sum, item) {
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        return sum + price * quantity;
      });

      expect(total, 0.0);
    });
  });

  group('购物车商品数量测试', () {
    test('应正确统计商品数量', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.updateCartQuantity('p1', 2);
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});
      await storage.updateCartQuantity('p2', 3);

      final count = await storage.getCartCount();
      expect(count, 5); // 2 + 3
    });

    test('空购物车数量应为 0', () async {
      final count = await storage.getCartCount();
      expect(count, 0);
    });
  });

  group('边界情况测试', () {
    test('添加同一商品多次应增加数量', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});

      final cart = await storage.getCart();
      expect(cart.length, 1);
      expect(cart.first['quantity'], 3);
    });

    test('移除不存在的商品不应报错', () async {
      await storage.removeFromCart('non_existent');
      
      final cart = await storage.getCart();
      expect(cart, isEmpty);
    });

    test('更新不存在的商品不应报错', () async {
      await storage.updateCartQuantity('non_existent', 5);
      
      final cart = await storage.getCart();
      expect(cart, isEmpty);
    });
  });
}
