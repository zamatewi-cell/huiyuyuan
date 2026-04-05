import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuyuan/services/storage_service.dart';

/// 汇玉源 - 本地存储服务测试
///
/// 测试内容:
/// - 用户数据存储和读取
/// - 购物车操作
/// - 收藏管理
/// - 浏览记录
/// - 搜索历史

void main() {
  late StorageService storage;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final Map<String, String> secureStore = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'write':
          final key = call.arguments['key'] as String;
          final value = call.arguments['value'] as String?;
          if (value != null) secureStore[key] = value;
          return null;
        case 'read':
          final key = call.arguments['key'] as String;
          return secureStore[key];
        case 'delete':
          final key = call.arguments['key'] as String;
          secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(secureStore);
        case 'containsKey':
          final key = call.arguments['key'] as String;
          return secureStore.containsKey(key);
        default:
          return null;
      }
    });

    // 设置 Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    // 确保每个 test 从空白状态开始
    await storage.clearAll();
  });

  group('用户数据存储测试', () {
    test('应正确保存和读取用户信息', () async {
      final userData = {
        'id': 'test_user',
        'username': '测试用户',
        'user_type': 'admin',
        'is_active': true,
      };

      await storage.saveUser(userData);
      final retrieved = await storage.getUser();

      expect(retrieved, isNotNull);
      expect(retrieved!['id'], 'test_user');
      expect(retrieved['username'], '测试用户');
      expect(retrieved['user_type'], 'admin');
    });

    test('清除用户后应返回 null', () async {
      await storage.saveUser({'id': 'to_be_cleared'});
      await storage.clearUser();
      
      final result = await storage.getUser();
      expect(result, isNull);
    });

    test('应正确保存和读取操作员ID', () async {
      await storage.saveOperatorId('operator_5');
      final operatorId = await storage.getOperatorId();
      
      expect(operatorId, 'operator_5');
    });
  });

  group('购物车操作测试', () {
    test('初始购物车应为空', () async {
      final cart = await storage.getCart();
      expect(cart, isEmpty);
    });

    test('应正确添加商品到购物车', () async {
      final product = {
        'id': 'prod_001',
        'name': '和田玉手链',
        'price': 9999,
      };

      await storage.addToCart(product);
      final cart = await storage.getCart();

      expect(cart.length, 1);
      expect(cart.first['id'], 'prod_001');
      expect(cart.first['name'], '和田玉手链');
      expect(cart.first['quantity'], 1);
    });

    test('添加相同商品应增加数量', () async {
      final product = {
        'id': 'prod_001',
        'name': '和田玉手链',
        'price': 9999,
      };

      await storage.addToCart(product);
      await storage.addToCart(product);
      final cart = await storage.getCart();

      expect(cart.length, 1);
      expect(cart.first['quantity'], 2);
    });

    test('应正确更新商品数量', () async {
      await storage.addToCart({
        'id': 'prod_002',
        'name': '翡翠吊坠',
        'price': 5999,
      });

      await storage.updateCartQuantity('prod_002', 5);
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

    test('应正确移除商品', () async {
      await storage.addToCart({'id': 'prod_001', 'name': '商品1', 'price': 100});
      await storage.addToCart({'id': 'prod_002', 'name': '商品2', 'price': 200});

      await storage.removeFromCart('prod_001');
      final cart = await storage.getCart();

      expect(cart.length, 1);
      expect(cart.first['id'], 'prod_002');
    });

    test('应正确清空购物车', () async {
      await storage.addToCart({'id': 'prod_001', 'name': '商品1', 'price': 100});
      await storage.addToCart({'id': 'prod_002', 'name': '商品2', 'price': 200});

      await storage.clearCart();
      final cart = await storage.getCart();

      expect(cart, isEmpty);
    });

    test('应正确计算购物车数量', () async {
      await storage.addToCart({'id': 'p1', 'name': '商品1', 'price': 100});
      await storage.updateCartQuantity('p1', 2);
      await storage.addToCart({'id': 'p2', 'name': '商品2', 'price': 200});
      await storage.updateCartQuantity('p2', 3);

      final count = await storage.getCartCount();
      expect(count, 5); // 2 + 3
    });
  });

  group('收藏管理测试', () {
    test('初始收藏应为空', () async {
      final favorites = await storage.getFavorites();
      expect(favorites, isEmpty);
    });

    test('应正确添加收藏', () async {
      await storage.addFavorite('prod_001');
      await storage.addFavorite('prod_002');
      
      final favorites = await storage.getFavorites();
      expect(favorites.length, 2);
      expect(favorites.contains('prod_001'), true);
      expect(favorites.contains('prod_002'), true);
    });

    test('应正确检查是否已收藏', () async {
      await storage.addFavorite('prod_001');
      
      expect(await storage.isFavorite('prod_001'), true);
      expect(await storage.isFavorite('prod_002'), false);
    });

    test('切换收藏应正确工作', () async {
      // 初始未收藏，切换后应收藏
      await storage.toggleFavorite('prod_001');
      expect(await storage.isFavorite('prod_001'), true);

      // 已收藏，切换后应取消
      await storage.toggleFavorite('prod_001');
      expect(await storage.isFavorite('prod_001'), false);
    });

    test('应正确移除收藏', () async {
      await storage.addFavorite('prod_001');
      await storage.removeFavorite('prod_001');
      
      expect(await storage.isFavorite('prod_001'), false);
    });

    test('重复添加收藏不应重复', () async {
      await storage.addFavorite('prod_001');
      await storage.addFavorite('prod_001');
      
      final favorites = await storage.getFavorites();
      expect(favorites.length, 1);
    });
  });

  group('浏览记录测试', () {
    test('初始浏览记录应为空', () async {
      final history = await storage.getBrowseHistory();
      expect(history, isEmpty);
    });

    test('应正确添加浏览记录', () async {
      await storage.addBrowseHistory('prod_001');
      await storage.addBrowseHistory('prod_002');
      
      final history = await storage.getBrowseHistory();
      expect(history.length, 2);
    });

    test('重复浏览应移动到最前', () async {
      await storage.addBrowseHistory('prod_001');
      await storage.addBrowseHistory('prod_002');
      await storage.addBrowseHistory('prod_001'); // 再次浏览

      final history = await storage.getBrowseHistory();
      expect(history.first, 'prod_001'); // 应该在最前面
      expect(history.length, 2); // 不应重复
    });

    test('应正确清空浏览记录', () async {
      await storage.addBrowseHistory('prod_001');
      await storage.clearBrowseHistory();
      
      final history = await storage.getBrowseHistory();
      expect(history, isEmpty);
    });
  });

  group('提醒设置测试', () {
    test('应正确保存和读取提醒设置', () async {
      final settings = {
        'followUpEnabled': true,
        'liveScheduleEnabled': true,
        'orderShipmentEnabled': false,
      };

      await storage.saveReminderSettings(settings);
      final retrieved = await storage.getReminderSettings();

      expect(retrieved['followUpEnabled'], true);
      expect(retrieved['orderShipmentEnabled'], false);
    });

    test('默认提醒设置应合理', () async {
      final defaults = await storage.getReminderSettings();
      
      // 检查是否有默认值
      expect(defaults.containsKey('followUpEnabled'), true);
      expect(defaults.containsKey('liveScheduleEnabled'), true);
    });
  });

  group('主题模式测试', () {
    test('应正确保存和读取主题模式', () async {
      await storage.saveThemeMode('dark');
      final mode = await storage.getThemeMode();
      
      expect(mode, 'dark');
    });

    test('默认主题模式应为 light', () async {
      final mode = await storage.getThemeMode();
      expect(mode, 'light');
    });
  });

  group('搜索历史测试', () {
    test('初始搜索历史应为空', () async {
      final history = await storage.getSearchHistory();
      expect(history, isEmpty);
    });

    test('应正确保存搜索历史', () async {
      await storage.addSearchHistory('和田玉');
      await storage.addSearchHistory('翡翠');
      await storage.addSearchHistory('南红');

      final history = await storage.getSearchHistory();
      expect(history.length, 3);
      expect(history.contains('和田玉'), true);
    });

    test('搜索历史应按时间排序（最新在前）', () async {
      await storage.addSearchHistory('关键词1');
      await storage.addSearchHistory('关键词2');
      await storage.addSearchHistory('关键词3');

      final history = await storage.getSearchHistory();
      expect(history.first, '关键词3');
    });

    test('重复搜索应移动到最前', () async {
      await storage.addSearchHistory('关键词1');
      await storage.addSearchHistory('关键词2');
      await storage.addSearchHistory('关键词1'); // 重复

      final history = await storage.getSearchHistory();
      expect(history.first, '关键词1');
      expect(history.length, 2);
    });

    test('应正确清空搜索历史', () async {
      await storage.addSearchHistory('测试搜索');
      await storage.clearSearchHistory();
      
      final history = await storage.getSearchHistory();
      expect(history, isEmpty);
    });
  });

  group('清除所有数据测试', () {
    test('应正确清除所有存储数据', () async {
      // 预设一些数据
      await storage.saveUser({'id': 'user'});
      await storage.addToCart({'id': 'item', 'name': 'test', 'price': 100});
      await storage.addFavorite('prod_001');

      // 清除所有数据
      await storage.clearAll();

      // 验证数据已清空
      expect(await storage.getUser(), isNull);
      expect(await storage.getCart(), isEmpty);
      expect(await storage.getFavorites(), isEmpty);
    });
  });

  group('存储大小估算测试', () {
    test('空存储应返回 0', () async {
      final size = await storage.getStorageSize();
      expect(size, 0);
    });

    test('有数据时应返回正数', () async {
      await storage.saveUser({'id': 'user', 'name': '测试用户'});
      await storage.addSearchHistory('测试');

      final size = await storage.getStorageSize();
      expect(size > 0, true);
    });
  });
}
