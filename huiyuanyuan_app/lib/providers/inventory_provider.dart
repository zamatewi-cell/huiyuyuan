/// 汇玉源 - 内部库存 Provider
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_model.dart';
import '../data/product_data.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

// ──────────────────────────── 本地缓存 Key ────────────────────────────
const _kInventoryCacheKey = 'inventory_cache';
const _kInventoryTxCacheKey = 'inventory_tx_cache';

// ──────────────────────────── 初始化工具 ────────────────────────────

/// 将 realProductData 转换为 InventoryItem 列表（作为初始库存）
List<InventoryItem> _buildInitialInventory() {
  return realProductData.map((p) {
    // 成本价按售价的 40%–60% 估算
    final costRatio = 0.45 + (p.price % 3) * 0.05;
    return InventoryItem(
      productId: p.id,
      productName: p.name,
      category: p.category,
      imageUrl: p.images.isNotEmpty ? p.images.first : null,
      currentStock: p.stock,
      minStock: p.stock > 100 ? 20 : (p.stock > 30 ? 10 : 5),
      costPrice: double.parse((p.price * costRatio).toStringAsFixed(2)),
      sellingPrice: p.price.toDouble(),
    );
  }).toList();
}

// ──────────────────────────── Inventory StateNotifier ────────────────────────────

class InventoryNotifier extends StateNotifier<List<InventoryItem>> {
  InventoryNotifier() : super(_buildInitialInventory()) {
    _loadFromStorage();
  }

  final _api = ApiService();

  /// 从后端 / 本地缓存加载库存，覆盖初始静态数据
  Future<void> _loadFromStorage() async {
    // 1. 尝试后端 API
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

    // 2. 尝试本地缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kInventoryCacheKey);
      if (cached != null) {
        final list = (jsonDecode(cached) as List)
            .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          state = list;
          return;
        }
      }
    } catch (_) {}

    // 3. 保持 _buildInitialInventory() 初始值
  }

  /// 持久化当前库存到本地
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.map((e) => e.toJson()).toList();
      await prefs.setString(_kInventoryCacheKey, jsonEncode(json));
    } catch (_) {}
  }

  /// 向后端同步单项库存变更
  Future<void> _syncStockToApi(String productId, int newStock) async {
    try {
      await _api.put(
        ApiConfig.inventoryStock(productId),
        data: {'current_stock': newStock},
      );
    } catch (_) {}
  }

  /// 根据产品 ID 获取条目
  InventoryItem? getItem(String productId) {
    try {
      return state.firstWhere((e) => e.productId == productId);
    } catch (_) {
      return null;
    }
  }

  /// 更新单条条目
  void _updateItem(String productId, InventoryItem updated) {
    state = [
      for (final item in state)
        if (item.productId == productId) updated else item,
    ];
    _saveToLocal();
    _syncStockToApi(productId, updated.currentStock);
  }

  /// 入库：增加库存
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

  /// 出库：减少库存
  bool stockOut({
    required String productId,
    required int quantity,
  }) {
    final item = getItem(productId);
    if (item == null || quantity <= 0) return false;
    if (item.currentStock < quantity) return false; // 库存不足
    _updateItem(
      productId,
      item.copyWith(
        currentStock: item.currentStock - quantity,
        lastUpdated: DateTime.now(),
      ),
    );
    return true;
  }

  /// 盘点调整：直接设置库存数量
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

  /// 修改安全库存阈值
  void updateMinStock(String productId, int minStock) {
    final item = getItem(productId);
    if (item == null) return;
    _updateItem(productId, item.copyWith(minStock: minStock));
  }

  /// 修改成本价
  void updateCostPrice(String productId, double costPrice) {
    final item = getItem(productId);
    if (item == null) return;
    _updateItem(productId, item.copyWith(costPrice: costPrice));
  }

  /// 强制刷新（从后端重新拉取）
  Future<void> refresh() async {
    await _loadFromStorage();
  }

  /// 获取统计快照
  InventoryStats get stats {
    return InventoryStats(
      totalSkus: state.length,
      totalUnits: state.fold(0, (s, e) => s + e.currentStock),
      totalCostValue: state.fold(0.0, (s, e) => s + e.stockValue),
      totalSellingValue: state.fold(0.0, (s, e) => s + e.stockSellingValue),
      lowStockCount: state.where((e) => e.isLowStock).length,
      outOfStockCount: state.where((e) => e.isOutOfStock).length,
      txCountThisMonth: 0, // 由 transaction provider 提供
    );
  }
}

// ──────────────────────────── Transaction StateNotifier ────────────────────────────

class InventoryTxNotifier extends StateNotifier<List<InventoryTransaction>> {
  InventoryTxNotifier() : super([]) {
    _loadTransactions();
  }

  final _api = ApiService();

  /// 从后端 / 本地缓存加载流水
  Future<void> _loadTransactions() async {
    // 1. 尝试后端 API
    try {
      final res = await _api.get(ApiConfig.inventoryTransactions);
      if (res.success && res.data is List) {
        final txs = (res.data as List)
            .map((e) =>
                InventoryTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        if (txs.isNotEmpty) {
          state = txs;
          return;
        }
      }
    } catch (_) {}

    // 2. 尝试本地缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kInventoryTxCacheKey);
      if (cached != null) {
        final list = (jsonDecode(cached) as List)
            .map((e) =>
                InventoryTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          state = list;
          return;
        }
      }
    } catch (_) {}

    // 3. 无数据则保持空列表
  }

  /// 持久化流水到本地
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
    // 同步到后端
    try {
      _api.post(ApiConfig.inventoryTransactions, data: tx.toJson());
    } catch (_) {}
  }

  List<InventoryTransaction> get thisMonth {
    final now = DateTime.now();
    return state
        .where((t) => t.createdAt.year == now.year && t.createdAt.month == now.month)
        .toList();
  }
}

// ──────────────────────────── Providers ────────────────────────────

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItem>>(
        (ref) => InventoryNotifier());

final inventoryTxProvider =
    StateNotifierProvider<InventoryTxNotifier, List<InventoryTransaction>>(
        (ref) => InventoryTxNotifier());

/// 派生 Provider：库存统计
final inventoryStatsProvider = Provider<InventoryStats>((ref) {
  final items = ref.watch(inventoryProvider);
  final txs = ref.watch(inventoryTxProvider);
  final now = DateTime.now();
  final thisMonthTxCount = txs
      .where((t) =>
          t.createdAt.year == now.year && t.createdAt.month == now.month)
      .length;

  return InventoryStats(
    totalSkus: items.length,
    totalUnits: items.fold(0, (s, e) => s + e.currentStock),
    totalCostValue: items.fold(0.0, (s, e) => s + e.stockValue),
    totalSellingValue: items.fold(0.0, (s, e) => s + e.stockSellingValue),
    lowStockCount: items.where((e) => e.isLowStock).length,
    outOfStockCount: items.where((e) => e.isOutOfStock).length,
    txCountThisMonth: thisMonthTxCount,
  );
});

/// 派生 Provider：低库存 / 售罄商品列表
final lowStockItemsProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(inventoryProvider);
  return items.where((e) => e.isLowStock || e.isOutOfStock).toList()
    ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
});
