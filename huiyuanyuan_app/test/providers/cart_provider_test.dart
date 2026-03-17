/// 汇玉源 - 购物车 Provider 测试
/// 
/// 测试内容:
/// - 购物车存储操作
/// - 金额计算
/// - 商品数量管理
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuanyuan/services/storage_service.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    // 初始化 Mock SharedPreferences（每次都清空，防止测试间状态污染）
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    await storage.saveCart([]);
  });

  group('购物车存储操作测试', () {
    test('初始购物车应为空', () async {
      final cart = await storage.getCart();
      expect(cart, isEmpty);
    });

    test('添加商品到购物车应正确工作', () async {
      await storage.addToCart({
        'id': 'prod_001',
        'name': '和田玉手链',
        'price': 9999,
      });

      final cart = await storage.getCart();
      expect(cart.length, 1);
      expect(cart.first['name'], '和田玉手链');
      expect(cart.first['quantity'], 1);
    });

    test('添加相同商品应增加数量', () async {
      await storage.addToCart({
        'id': 'prod_001',
        'name': '和田玉手链',
        'price': 9999,
      });
      await storage.addToCart({
        'id': 'prod_001',
        'name': '和田玉手链',
        'price': 9999,
      });

      final cart = await storage.getCart();
      expect(cart.length, 1);
      expect(cart.first['quantity'], 2);
    });

    test('更新商品数量应正确工作', () async {
      await storage.addToCart({
        'id': 'prod_001',
        'name': '测试商品',
        'price': 1000,
      });

      await storage.updateCartQuantity('prod_001', 5);
      final cart = await storage.getCart();

      expect(cart.first['quantity'], 5);
    });

    test('数量为0时应移除商品', () async {
      await storage.addToCart({
        'id': 'prod_001',
        'name': '商品1',
        'price': 100,
      });

      await storage.updateCartQuantity('prod_001', 0);
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

    test('清空购物车应正确工作', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});

      await storage.clearCart();
      final cart = await storage.getCart();

      expect(cart, isEmpty);
    });

    test('购物车商品数量计算应正确', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.updateCartQuantity('p1', 2);
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});
      await storage.updateCartQuantity('p2', 3);

      final count = await storage.getCartCount();
      expect(count, 5); // 2 + 3
    });
  });

  group('金额计算测试', () {
    test('应正确计算总金额', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.updateCartQuantity('p1', 2);
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});
      await storage.updateCartQuantity('p2', 3);

      final cart = await storage.getCart();
      
      // 手动计算总金额 (模拟 CartNotifier.totalAmount)
      double total = cart.fold(0.0, (sum, item) {
        final price = (item['price'] ?? 0).toDouble();
        final quantity = item['quantity'] ?? 1;
        return sum + price * quantity;
      });

      expect(total, 100 * 2 + 200 * 3); // 800
    });

    test('空购物车总金额应为 0', () async {
      final cart = await storage.getCart();
      
      double total = cart.fold(0.0, (sum, item) {
        final price = (item['price'] ?? 0).toDouble();
        final quantity = item['quantity'] ?? 1;
        return sum + price * quantity;
      });

      expect(total, 0.0);
    });

    test('单个商品多数量金额计算', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 999});
      await storage.updateCartQuantity('p1', 3);

      final cart = await storage.getCart();
      double total = cart.fold(0.0, (sum, item) {
        final price = (item['price'] ?? 0).toDouble();
        final quantity = item['quantity'] ?? 1;
        return sum + price * quantity;
      });

      expect(total, 999 * 3);
    });
  });

  group('边界情况测试', () {
    test('移除不存在的商品不应报错', () async {
      await storage.removeFromCart('non_existent');
      // 不抛出异常即为通过
      final cart = await storage.getCart();
      expect(cart, isEmpty);
    });

    test('更新不存在的商品不应报错', () async {
      await storage.updateCartQuantity('non_existent', 5);
      // 不抛出异常即为通过
      final cart = await storage.getCart();
      expect(cart, isEmpty);
    });

    test('添加多个不同商品', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});
      await storage.addToCart({'id': 'p3', 'name': '商品3', 'price': 300});

      final cart = await storage.getCart();
      expect(cart.length, 3);
    });

    test('保存整个购物车应正确工作', () async {
      final customCart = [
        {'id': 'p1', 'name': '商品1', 'price': 100, 'quantity': 2},
        {'id': 'p2', 'name': '商品2', 'price': 200, 'quantity': 1},
      ];

      await storage.saveCart(customCart);
      final cart = await storage.getCart();

      expect(cart.length, 2);
      expect(cart.first['quantity'], 2);
    });
  });
}
