/// HuiYuYuan local storage service.
///
/// Responsibilities:
/// - encrypted user data storage
/// - operator data isolation
/// - cart and favorites persistence
/// - reminder and settings persistence
///
/// Security notes:
/// - AES-backed secure storage where available
/// - isolated key spaces for operator data
/// - browser fallback when secure storage is unavailable
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

/// Shared local storage service.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  /// Secure storage instance used for auth tokens.
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Initializes the backing shared preferences instance.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns an initialized shared preferences handle.
  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // User data.

  /// Persists the current user payload.
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await _storage;
    await prefs.setString('current_user', jsonEncode(user));
  }

  /// Returns the stored current user payload.
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _storage;
    final data = prefs.getString('current_user');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Persists the current operator id.
  Future<void> saveOperatorId(String operatorId) async {
    final prefs = await _storage;
    await prefs.setString('current_operator_id', operatorId);
  }

  /// Returns the current operator id.
  Future<String?> getOperatorId() async {
    final prefs = await _storage;
    return prefs.getString('current_operator_id');
  }

  /// Clears user session data.
  Future<void> clearUser() async {
    final prefs = await _storage;
    await prefs.remove('current_user');
    await prefs.remove('current_operator_id');
    await deleteToken(); // Clear the secure token as part of logout.
  }

  // Secure token storage.
  //
  // On web over plain HTTP, crypto.subtle is unavailable, so token storage
  // falls back to SharedPreferences.

  /// Saves the auth token using secure storage when available.
  Future<void> saveToken(String token) async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      await _secure.write(key: 'auth_token', value: token);
    } catch (_) {
      // Fall back to SharedPreferences when secure storage is unavailable.
      final prefs = await _storage;
      await prefs.setString('_fallback_auth_token', token);
    }
  }

  /// Saves the refresh token using secure storage when available.
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      await _secure.write(key: 'auth_refresh_token', value: refreshToken);
    } catch (_) {
      final prefs = await _storage;
      await prefs.setString('_fallback_refresh_token', refreshToken);
    }
  }

  /// Reads the auth token.
  Future<String?> getToken() async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      return await _secure.read(key: 'auth_token');
    } catch (_) {
      final prefs = await _storage;
      return prefs.getString('_fallback_auth_token');
    }
  }

  /// Reads the refresh token.
  Future<String?> getRefreshToken() async {
    try {
      if (kIsWeb) throw UnsupportedError('Web HTTP fallback');
      return await _secure.read(key: 'auth_refresh_token');
    } catch (_) {
      final prefs = await _storage;
      return prefs.getString('_fallback_refresh_token');
    }
  }

  /// Deletes auth credentials during logout.
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

  // Operator-isolated storage.

  /// Builds an operator-scoped storage key.
  String _getOperatorKey(String operatorId, String key) {
    return 'op_${operatorId}_$key';
  }

  /// Saves operator-specific data in an isolated key space.
  Future<void> saveOperatorData(String key, String value) async {
    final opId = await getOperatorId();
    if (opId == null) throw Exception('Operator is not logged in');
    final prefs = await _storage;
    await prefs.setString(_getOperatorKey(opId, key), value);
  }

  /// Reads operator-specific data.
  Future<String?> getOperatorData(String key) async {
    final opId = await getOperatorId();
    if (opId == null) return null;
    final prefs = await _storage;
    return prefs.getString(_getOperatorKey(opId, key));
  }

  /// Allows admins to read operator-scoped data.
  Future<String?> getDataAsAdmin(String operatorId, String key) async {
    final prefs = await _storage;
    return prefs.getString(_getOperatorKey(operatorId, key));
  }

  // Cart.

  /// Returns the current cart items.
  Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await _storage;
    final data = prefs.getString('cart');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// Adds a product to the cart.
  Future<void> addToCart(Map<String, dynamic> product) async {
    final cart = await getCart();

    // Check whether the product already exists in the cart.
    final existingIndex =
        cart.indexWhere((item) => item['id'] == product['id']);
    if (existingIndex >= 0) {
      // Increase quantity for an existing item.
      cart[existingIndex]['quantity'] =
          (cart[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      // Add a new line item.
      product['quantity'] = 1;
      cart.add(product);
    }

    final prefs = await _storage;
    await prefs.setString('cart', jsonEncode(cart));
  }

  /// Persists the full cart payload.
  Future<void> saveCart(List<Map<String, dynamic>> cart) async {
    final prefs = await _storage;
    await prefs.setString('cart', jsonEncode(cart));
  }

  /// Updates the quantity for a cart item.
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

  /// Removes a product from the cart.
  Future<void> removeFromCart(String productId) async {
    final cart = await getCart();
    cart.removeWhere((item) => item['id'] == productId);
    final prefs = await _storage;
    await prefs.setString('cart', jsonEncode(cart));
  }

  /// Clears the cart.
  Future<void> clearCart() async {
    final prefs = await _storage;
    await prefs.remove('cart');
  }

  /// Returns the total cart item count.
  Future<int> getCartCount() async {
    final cart = await getCart();
    int count = 0;
    for (final item in cart) {
      count += (item['quantity'] as int? ?? 1);
    }
    return count;
  }

  // Favorites.

  /// Returns favorite product ids.
  Future<List<String>> getFavorites() async {
    final prefs = await _storage;
    final data = prefs.getStringList('favorites');
    return data ?? [];
  }

  /// Checks whether a product is favorited.
  Future<bool> isFavorite(String productId) async {
    final favorites = await getFavorites();
    return favorites.contains(productId);
  }

  /// Toggles the favorite state for a product.
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

  /// Adds a product to favorites.
  Future<void> addFavorite(String productId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      final prefs = await _storage;
      await prefs.setStringList('favorites', favorites);
    }
  }

  /// Removes a product from favorites.
  Future<void> removeFavorite(String productId) async {
    final favorites = await getFavorites();
    favorites.remove(productId);
    final prefs = await _storage;
    await prefs.setStringList('favorites', favorites);
  }

  // Browsing history.

  /// Adds a product to browsing history.
  Future<void> addBrowseHistory(String productId) async {
    final prefs = await _storage;
    final history = prefs.getStringList('browse_history') ?? [];

    // Remove an existing occurrence to avoid duplicates.
    history.remove(productId);
    // Insert at the front.
    history.insert(0, productId);
    // Cap the history length.
    if (history.length > 50) {
      history.removeLast();
    }

    await prefs.setStringList('browse_history', history);
  }

  /// Returns browsing history.
  Future<List<String>> getBrowseHistory() async {
    final prefs = await _storage;
    return prefs.getStringList('browse_history') ?? [];
  }

  /// Clears browsing history.
  Future<void> clearBrowseHistory() async {
    final prefs = await _storage;
    await prefs.remove('browse_history');
  }

  // Reminder settings.

  /// Saves reminder settings.
  Future<void> saveReminderSettings(Map<String, dynamic> settings) async {
    final prefs = await _storage;
    await prefs.setString('reminder_settings', jsonEncode(settings));
  }

  /// Returns reminder settings.
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

  /// Saves a custom reminder sound path.
  Future<void> saveCustomSound(String reminderType, String soundPath) async {
    final settings = await getReminderSettings();
    settings['customSound_$reminderType'] = soundPath;
    await saveReminderSettings(settings);
  }

  // Search history.

  /// Adds a keyword to search history.
  Future<void> addSearchHistory(String keyword) async {
    final prefs = await _storage;
    final history = prefs.getStringList('search_history') ?? [];

    // Remove an existing occurrence.
    history.remove(keyword);
    // Insert at the front.
    history.insert(0, keyword);
    // Cap the history length.
    if (history.length > 20) {
      history.removeLast();
    }

    await prefs.setStringList('search_history', history);
  }

  /// Returns search history.
  Future<List<String>> getSearchHistory() async {
    final prefs = await _storage;
    return prefs.getStringList('search_history') ?? [];
  }

  /// Clears search history.
  Future<void> clearSearchHistory() async {
    final prefs = await _storage;
    await prefs.remove('search_history');
  }

  // Theme settings.

  /// Saves the preferred theme mode.
  Future<void> saveThemeMode(String mode) async {
    final prefs = await _storage;
    await prefs.setString('theme_mode', mode);
  }

  /// Returns the preferred theme mode.
  Future<String> getThemeMode() async {
    final prefs = await _storage;
    return prefs.getString('theme_mode') ?? 'light';
  }

  // General utilities.

  /// Saves runtime product overlay data.
  Future<void> saveProductRuntimeOverlay(
    String key,
    Map<String, dynamic> payload,
  ) async {
    final prefs = await _storage;
    await prefs.setString(
        _getProductRuntimeOverlayKey(key), jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> getProductRuntimeOverlay(String key) async {
    final prefs = await _storage;
    final data = prefs.getString(_getProductRuntimeOverlayKey(key));
    if (data == null) {
      return null;
    }
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearProductRuntimeOverlay(String key) async {
    final prefs = await _storage;
    await prefs.remove(_getProductRuntimeOverlayKey(key));
  }

  Future<void> clearAll() async {
    final prefs = await _storage;
    await prefs.clear();
  }

  /// Returns an estimated storage footprint.
  Future<int> getStorageSize() async {
    final prefs = await _storage;
    final keys = prefs.getKeys();
    int size = 0;
    for (final key in keys) {
      final value = prefs.get(key);
      if (value is String) {
        size += value.length;
      } else if (value is List) {
        size += value.length * 50; // Approximation for list entries.
      }
    }
    return size;
  }

  // Chat history.

  /// Builds the runtime overlay key for a product.
  String _getProductRuntimeOverlayKey(String key) {
    return 'product_runtime_overlay_$key';
  }

  Future<void> saveChatHistory(
      String userId, List<ChatMessage> messages) async {
    final prefs = await _storage;
    final list = messages
        .where((m) => m.id != 'welcome') // Skip the seeded welcome message.
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    // Keep at most 200 messages.
    if (list.length > 200) {
      list.removeRange(0, list.length - 200);
    }
    await prefs.setStringList('chat_history_$userId', list);
  }

  /// Loads chat history.
  Future<List<ChatMessage>> loadChatHistory(String userId) async {
    final prefs = await _storage;
    final list = prefs.getStringList('chat_history_$userId');
    if (list == null || list.isEmpty) return [];
    try {
      final messages = list
          .map((s) =>
              ChatMessage.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      final normalized = messages
          .map((message) => jsonEncode(message.toJson()))
          .toList(growable: false);
      if (!_sameStringList(list, normalized)) {
        await prefs.setStringList('chat_history_$userId', normalized);
      }
      return messages;
    } catch (_) {
      await prefs.remove('chat_history_$userId');
      return [];
    }
  }

  /// Clears chat history.
  Future<void> clearChatHistory(String userId) async {
    final prefs = await _storage;
    await prefs.remove('chat_history_$userId');
  }

  /// Returns all chat session ids for history entry points.
  Future<List<String>> getChatSessionIds() async {
    final prefs = await _storage;
    final keys = prefs.getKeys();
    return keys
        .where((k) => k.startsWith('chat_history_'))
        .map((k) => k.replaceFirst('chat_history_', ''))
        .toList();
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
