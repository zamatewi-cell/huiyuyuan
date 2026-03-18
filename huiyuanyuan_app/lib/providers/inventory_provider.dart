library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/inventory_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';

const _kInventoryCacheKey = 'inventory_cache';
const _kInventoryTxCacheKey = 'inventory_tx_cache';

List<InventoryItem> _buildInventoryFromProducts(List<ProductModel> products) {
  return products.map((product) {
    final costRatio = 0.45 + (product.price % 3) * 0.05;
    return InventoryItem(
      productId: product.id,
      productName: product.name,
      category: product.category,
      imageUrl: product.images.isNotEmpty ? product.images.first : null,
      currentStock: product.stock,
      minStock: product.stock > 100 ? 20 : (product.stock > 30 ? 10 : 5),
      costPrice: double.parse((product.price * costRatio).toStringAsFixed(2)),
      sellingPrice: product.price.toDouble(),
    );
  }).toList();
}

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  InventoryNotifier() : super(const []) {
    _loadFromStorage();
  }

  final _api = ApiService();
  final _productService = ProductService();

  Future<void> _loadFromStorage() async {
    try {
      final res = await _api.get(ApiConfig.inventory);
      if (res.success && res.data is List) {
        final items = (res.data as List)
            .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (items.isNotEmpty) {
          state = items;
          return;
        }
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kInventoryCacheKey);
      if (cached != null) {
        final items = (jsonDecode(cached) as List)
            .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (items.isNotEmpty) {
          state = items;
          return;
        }
      }
    } catch (_) {}

    try {
      final products = await _productService.getProducts(
        pageSize: 100,
        forceRefresh: true,
      );
      if (products.isNotEmpty) {
        state = _buildInventoryFromProducts(products);
        await _saveToLocal();
      }
    } catch (_) {}
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.map((e) => e.toJson()).toList();
      await prefs.setString(_kInventoryCacheKey, jsonEncode(json));
    } catch (_) {}
  }

  Future<void> _syncStockToApi(String productId, int newStock) async {
    try {
      await _api.put(
        ApiConfig.inventoryStock(productId),
        data: {'current_stock': newStock},
      );
    } catch (_) {}
  }

  InventoryItem? getItem(String productId) {
    try {
      return state.firstWhere((e) => e.productId == productId);
    } catch (_) {
      return null;
    }
  }

  void _updateItem(String productId, InventoryItem updated) {
    state = [
      for (final item in state)
        if (item.productId == productId) updated else item,
    ];
    _saveToLocal();
    _syncStockToApi(productId, updated.currentStock);
  }

  bool stockIn({
    required String productId,
    required int quantity,
  }) {
    final item = getItem(productId);
    if (item == null || quantity <= 0) return false;
    _updateItem(
      productId,
      item.copyWith(
        currentStock: item.currentStock + quantity,
        lastUpdated: DateTime.now(),
      ),
    );
    return true;
  }

  bool stockOut({
    required String productId,
    required int quantity,
  }) {
    final item = getItem(productId);
    if (item == null || quantity <= 0) return false;
    if (item.currentStock < quantity) return false;
    _updateItem(
      productId,
      item.copyWith(
        currentStock: item.currentStock - quantity,
        lastUpdated: DateTime.now(),
      ),
    );
    return true;
  }

  bool adjust({
    required String productId,
    required int newStock,
  }) {
    final item = getItem(productId);
    if (item == null || newStock < 0) return false;
    _updateItem(
      productId,
      item.copyWith(
        currentStock: newStock,
        lastUpdated: DateTime.now(),
      ),
    );
    return true;
  }

  void updateMinStock(String productId, int minStock) {
    final item = getItem(productId);
    if (item == null) return;
    _updateItem(productId, item.copyWith(minStock: minStock));
  }

  void updateCostPrice(String productId, double costPrice) {
    final item = getItem(productId);
    if (item == null) return;
    _updateItem(productId, item.copyWith(costPrice: costPrice));
  }

  Future<void> refresh() async {
    await _loadFromStorage();
  }

  InventoryStats get stats {
    return InventoryStats(
      totalSkus: state.length,
      totalUnits: state.fold(0, (sum, item) => sum + item.currentStock),
      totalCostValue: state.fold(0.0, (sum, item) => sum + item.stockValue),
      totalSellingValue:
          state.fold(0.0, (sum, item) => sum + item.stockSellingValue),
      lowStockCount: state.where((item) => item.isLowStock).length,
      outOfStockCount: state.where((item) => item.isOutOfStock).length,
      txCountThisMonth: 0,
    );
  }
}

class InventoryTxNotifier extends StateNotifier<List<InventoryTransaction>> {
  InventoryTxNotifier() : super([]) {
    _loadTransactions();
  }

  final _api = ApiService();

  Future<void> _loadTransactions() async {
    try {
      final res = await _api.get(ApiConfig.inventoryTransactions);
      if (res.success && res.data is List) {
        final txs = (res.data as List)
            .map(
                (e) => InventoryTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        if (txs.isNotEmpty) {
          state = txs;
          return;
        }
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kInventoryTxCacheKey);
      if (cached != null) {
        final txs = (jsonDecode(cached) as List)
            .map(
                (e) => InventoryTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        if (txs.isNotEmpty) {
          state = txs;
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.map((e) => e.toJson()).toList();
      await prefs.setString(_kInventoryTxCacheKey, jsonEncode(json));
    } catch (_) {}
  }

  void addTransaction(InventoryTransaction tx) {
    state = [tx, ...state];
    _saveToLocal();
    try {
      _api.post(ApiConfig.inventoryTransactions, data: tx.toJson());
    } catch (_) {}
  }

  List<InventoryTransaction> get thisMonth {
    final now = DateTime.now();
    return state
        .where(
          (tx) =>
              tx.createdAt.year == now.year && tx.createdAt.month == now.month,
        )
        .toList();
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>(
  (ref) => InventoryNotifier(),
);

final inventoryTxProvider =
    StateNotifierProvider<InventoryTxNotifier, List<InventoryTransaction>>(
  (ref) => InventoryTxNotifier(),
);

final inventoryStatsProvider = Provider<InventoryStats>((ref) {
  final items = ref.watch(inventoryProvider);
  final txs = ref.watch(inventoryTxProvider);
  final now = DateTime.now();
  final thisMonthTxCount = txs
      .where((tx) =>
          tx.createdAt.year == now.year && tx.createdAt.month == now.month)
      .length;

  return InventoryStats(
    totalSkus: items.length,
    totalUnits: items.fold(0, (sum, item) => sum + item.currentStock),
    totalCostValue: items.fold(0.0, (sum, item) => sum + item.stockValue),
    totalSellingValue:
        items.fold(0.0, (sum, item) => sum + item.stockSellingValue),
    lowStockCount: items.where((item) => item.isLowStock).length,
    outOfStockCount: items.where((item) => item.isOutOfStock).length,
    txCountThisMonth: thisMonthTxCount,
  );
});

final lowStockItemsProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(inventoryProvider);
  return items.where((item) => item.isLowStock || item.isOutOfStock).toList()
    ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
});
