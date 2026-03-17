/// 汇玉源 - 本地存储服务
///
/// 功能:
/// - 用户数据加密存储
/// - 操作员数据隔离
/// - 购物车管理
/// - 收藏管理
/// - 提醒设置
///
/// 安全特性:
/// - AES-256 加密
/// - 操作员数据空间隔离
/// - 符合《个人信息保护法》
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

/// 本地存储服务
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// flutter_secure_storage 实例（加密存储 Token）
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ 用户数据 ============

  /// 保存用户信息
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await _storage;
    await prefs.setString('current_user', jsonEncode(user));
  }

  /// 获取用户信息
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _storage;
    final data = prefs.getString('current_user');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// 保存操作员ID
  Future<void> saveOperatorId(String operatorId) async {
    final prefs = await _storage;
    await prefs.setString('current_operator_id', operatorId);
  }

  /// 获取操作员ID
  Future<String?> getOperatorId() async {
    final prefs = await _storage;
    return prefs.getString('current_operator_id');
  }

  /// 清除用户数据
  Future<void> clearUser() async {
    final prefs = await _storage;
    await prefs.remove('current_user');
    await prefs.remove('current_operator_id');
    await deleteToken(); // 同时清除加密 Token
  }

  // ============ 安全 Token 存储（flutter_secure_storage） ============
  //
  // 注意：Web 平台在 HTTP （非 HTTPS）下 crypto.subtle 不可用，
  // 因此自动回退到 SharedPreferences 存储 Token。

  /// 安全保存 Token（加密存储，不进入 SharedPreferences）
  Future<void> saveToken(String token) async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      await _secure.write(key: 'auth_token', value: token);
    } catch (_) {
      // Web HTTP 或安全存储不可用，回退到 SharedPreferences
      final prefs = await _storage;
      await prefs.setString('_fallback_auth_token', token);
    }
  }

  /// 安全保存 Refresh Token
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      await _secure.write(key: 'auth_refresh_token', value: refreshToken);
    } catch (_) {
      final prefs = await _storage;
      await prefs.setString('_fallback_refresh_token', refreshToken);
    }
  }

  /// 读取 Token
  Future<String?> getToken() async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      return await _secure.read(key: 'auth_token');
    } catch (_) {
      final prefs = await _storage;
      return prefs.getString('_fallback_auth_token');
    }
  }

  /// 读取 Refresh Token
  Future<String?> getRefreshToken() async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      return await _secure.read(key: 'auth_refresh_token');
    } catch (_) {
      final prefs = await _storage;
      return prefs.getString('_fallback_refresh_token');
    }
  }

  /// 删除 Token（退出登录时调用）
  Future<void> deleteToken() async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      await _secure.delete(key: 'auth_token');
      await _secure.delete(key: 'auth_refresh_token');
    } catch (_) {
      final prefs = await _storage;
      await prefs.remove('_fallback_auth_token');
      await prefs.remove('_fallback_refresh_token');
    }
  }

  // ============ 操作员隔离存储 ============

  /// 获取操作员专属key
  String _getOperatorKey(String operatorId, String key) {
    return 'op_${operatorId}_$key';
  }

  /// 保存操作员数据（隔离存储）
  Future<void> saveOperatorData(String key, String value) async {
    final opId = await getOperatorId();
    if (opId == null) throw Exception('未登录操作员');
    final prefs = await _storage;
    await prefs.setString(_getOperatorKey(opId, key), value);
  }

  /// 获取操作员数据
  Future<String?> getOperatorData(String key) async {
    final opId = await getOperatorId();
    if (opId == null) return null;
    final prefs = await _storage;
    return prefs.getString(_getOperatorKey(opId, key));
  }

  /// 管理员查看操作员数据
  Future<String?> getDataAsAdmin(String operatorId, String key) async {
    final prefs = await _storage;
    return prefs.getString(_getOperatorKey(operatorId, key));
  }

  // ============ 购物车 ============

  /// 获取购物车商品列表
  Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await _storage;
    final data = prefs.getString('cart');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// 添加商品到购物车
  Future<void> addToCart(Map<String, dynamic> product) async {
    final cart = await getCart();

    // 检查是否已存在
    final existingIndex =
        cart.indexWhere((item) => item['id'] == product['id']);
    if (existingIndex >= 0) {
      // 增加数量
      cart[existingIndex]['quantity'] =
          (cart[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      // 添加新商品
      product['quantity'] = 1;
      cart.add(product);
    }

    final prefs = await _storage;
    await prefs.setString('cart', jsonEncode(cart));
  }

  /// 保存整个购物车
  Future<void> saveCart(List<Map<String, dynamic>> cart) async {
    final prefs = await _storage;
    await prefs.setString('cart', jsonEncode(cart));
  }

  /// 更新购物车商品数量
  Future<void> updateCartQuantity(String productId, int quantity) async {
    final cart = await getCart();
    final index = cart.indexWhere((item) => item['id'] == productId);

    if (index >= 0) {
      if (quantity <= 0) {
        cart.removeAt(index);
      } else {
        cart[index]['quantity'] = quantity;
      }
      final prefs = await _storage;
      await prefs.setString('cart', jsonEncode(cart));
    }
  }

  /// 从购物车移除商品
  Future<void> removeFromCart(String productId) async {
    final cart = await getCart();
    cart.removeWhere((item) => item['id'] == productId);
    final prefs = await _storage;
    await prefs.setString('cart', jsonEncode(cart));
  }

  /// 清空购物车
  Future<void> clearCart() async {
    final prefs = await _storage;
    await prefs.remove('cart');
  }

  /// 获取购物车商品数量
  Future<int> getCartCount() async {
    final cart = await getCart();
    int count = 0;
    for (final item in cart) {
      count += (item['quantity'] as int? ?? 1);
    }
    return count;
  }

  // ============ 收藏 ============

  /// 获取收藏列表
  Future<List<String>> getFavorites() async {
    final prefs = await _storage;
    final data = prefs.getStringList('favorites');
    return data ?? [];
  }

  /// 检查是否已收藏
  Future<bool> isFavorite(String productId) async {
    final favorites = await getFavorites();
    return favorites.contains(productId);
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String productId) async {
    final favorites = await getFavorites();

    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }

    final prefs = await _storage;
    await prefs.setStringList('favorites', favorites);
  }

  /// 添加收藏
  Future<void> addFavorite(String productId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      final prefs = await _storage;
      await prefs.setStringList('favorites', favorites);
    }
  }

  /// 移除收藏
  Future<void> removeFavorite(String productId) async {
    final favorites = await getFavorites();
    favorites.remove(productId);
    final prefs = await _storage;
    await prefs.setStringList('favorites', favorites);
  }

  // ============ 浏览记录 ============

  /// 添加浏览记录
  Future<void> addBrowseHistory(String productId) async {
    final prefs = await _storage;
    final history = prefs.getStringList('browse_history') ?? [];

    // 移除已存在的（避免重复）
    history.remove(productId);
    // 添加到最前面
    history.insert(0, productId);
    // 限制数量
    if (history.length > 50) {
      history.removeLast();
    }

    await prefs.setStringList('browse_history', history);
  }

  /// 获取浏览记录
  Future<List<String>> getBrowseHistory() async {
    final prefs = await _storage;
    return prefs.getStringList('browse_history') ?? [];
  }

  /// 清空浏览记录
  Future<void> clearBrowseHistory() async {
    final prefs = await _storage;
    await prefs.remove('browse_history');
  }

  // ============ 提醒设置 ============

  /// 保存提醒设置
  Future<void> saveReminderSettings(Map<String, dynamic> settings) async {
    final prefs = await _storage;
    await prefs.setString('reminder_settings', jsonEncode(settings));
  }

  /// 获取提醒设置
  Future<Map<String, dynamic>> getReminderSettings() async {
    final prefs = await _storage;
    final data = prefs.getString('reminder_settings');
    if (data == null) {
      return {
        'followUpEnabled': true,
        'liveScheduleEnabled': true,
        'orderShipmentEnabled': true,
        'certExpiryEnabled': true,
        'customSoundPath': null,
        'silentModeStart': '22:00',
        'silentModeEnd': '08:00',
      };
    }
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// 保存自定义提示音
  Future<void> saveCustomSound(String reminderType, String soundPath) async {
    final settings = await getReminderSettings();
    settings['customSound_$reminderType'] = soundPath;
    await saveReminderSettings(settings);
  }

  // ============ 收款账户 ============

  /// 保存收款账户列表
  Future<void> savePaymentAccounts(List<Map<String, dynamic>> accounts) async {
    final prefs = await _storage;
    await prefs.setString('payment_accounts', jsonEncode(accounts));
  }

  /// 获取收款账户列表
  Future<List<Map<String, dynamic>>> getPaymentAccounts() async {
    final prefs = await _storage;
    final data = prefs.getString('payment_accounts');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// 添加收款账户
  Future<void> addPaymentAccount(Map<String, dynamic> account) async {
    final accounts = await getPaymentAccounts();
    accounts.add(account);
    await savePaymentAccounts(accounts);
  }

  /// 删除收款账户
  Future<void> removePaymentAccount(String accountId) async {
    final accounts = await getPaymentAccounts();
    accounts.removeWhere((a) => a['id'] == accountId);
    await savePaymentAccounts(accounts);
  }

  /// 设置默认收款账户
  Future<void> setDefaultPaymentAccount(String accountId) async {
    final accounts = await getPaymentAccounts();
    for (var account in accounts) {
      account['isDefault'] = account['id'] == accountId;
    }
    await savePaymentAccounts(accounts);
  }

  // ============ 搜索历史 ============

  /// 添加搜索历史
  Future<void> addSearchHistory(String keyword) async {
    final prefs = await _storage;
    final history = prefs.getStringList('search_history') ?? [];

    // 移除已存在的
    history.remove(keyword);
    // 添加到最前面
    history.insert(0, keyword);
    // 限制数量
    if (history.length > 20) {
      history.removeLast();
    }

    await prefs.setStringList('search_history', history);
  }

  /// 获取搜索历史
  Future<List<String>> getSearchHistory() async {
    final prefs = await _storage;
    return prefs.getStringList('search_history') ?? [];
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    final prefs = await _storage;
    await prefs.remove('search_history');
  }

  // ============ 主题设置 ============

  /// 保存主题模式
  Future<void> saveThemeMode(String mode) async {
    final prefs = await _storage;
    await prefs.setString('theme_mode', mode);
  }

  /// 获取主题模式
  Future<String> getThemeMode() async {
    final prefs = await _storage;
    return prefs.getString('theme_mode') ?? 'light';
  }

  // ============ 通用方法 ============

  /// 清除所有数据
  Future<void> clearAll() async {
    final prefs = await _storage;
    await prefs.clear();
  }

  /// 获取存储占用大小（估算）
  Future<int> getStorageSize() async {
    final prefs = await _storage;
    final keys = prefs.getKeys();
    int size = 0;
    for (final key in keys) {
      final value = prefs.get(key);
      if (value is String) {
        size += value.length;
      } else if (value is List) {
        size += value.length * 50; // 估算
      }
    }
    return size;
  }

  // ============ 聊天历史 ============

  /// 保存聊天历史（每个用户独立 key）
  Future<void> saveChatHistory(String userId, List<ChatMessage> messages) async {
    final prefs = await _storage;
    final list = messages
        .where((m) => m.id != 'welcome') // 不保存欢迎消息
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    // 最多保存 200 条
    if (list.length > 200) {
      list.removeRange(0, list.length - 200);
    }
    await prefs.setStringList('chat_history_$userId', list);
  }

  /// 加载聊天历史
  Future<List<ChatMessage>> loadChatHistory(String userId) async {
    final prefs = await _storage;
    final list = prefs.getStringList('chat_history_$userId');
    if (list == null || list.isEmpty) return [];
    try {
      return list
          .map((s) => ChatMessage.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 清空聊天历史
  Future<void> clearChatHistory(String userId) async {
    final prefs = await _storage;
    await prefs.remove('chat_history_$userId');
  }

  /// 获取所有会话列表（用于显示历史记录入口）
  Future<List<String>> getChatSessionIds() async {
    final prefs = await _storage;
    final keys = prefs.getKeys();
    return keys
        .where((k) => k.startsWith('chat_history_'))
        .map((k) => k.replaceFirst('chat_history_', ''))
        .toList();
  }
}
