/// 汇玉源 - 内部库存 Provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_model.dart';
import '../data/product_data.dart';

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
  InventoryNotifier() : super(_buildInitialInventory());

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

  /// 获取统计快照
  InventoryStats get stats {
    final now = DateTime.now();
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
  InventoryTxNotifier() : super(_buildSampleTransactions());

  void addTransaction(InventoryTransaction tx) {
    state = [tx, ...state];
  }

  List<InventoryTransaction> get thisMonth {
    final now = DateTime.now();
    return state
        .where((t) => t.createdAt.year == now.year && t.createdAt.month == now.month)
        .toList();
  }
}

/// 生成一些示例历史流水（演示用）
List<InventoryTransaction> _buildSampleTransactions() {
  final now = DateTime.now();
  return [
    InventoryTransaction(
      id: 'TX-001',
      productId: 'HYY-HT001',
      productName: '新疆和田玉籽料福运手链',
      type: InventoryTxType.stockIn,
      quantity: 50,
      stockBefore: 106,
      stockAfter: 156,
      note: '供应商补货',
      operatorName: '管理员',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    InventoryTransaction(
      id: 'TX-002',
      productId: 'HYY-FC001',
      productName: '缅甸翡翠平安扣吊坠',
      type: InventoryTxType.stockOut,
      quantity: 5,
      stockBefore: 50,
      stockAfter: 45,
      note: '客户订单 #ORD-2026-0220',
      operatorName: '操作员1',
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    InventoryTransaction(
      id: 'TX-003',
      productId: 'HYY-NH001',
      productName: '凉山南红玛瑙转运珠手链',
      type: InventoryTxType.stockIn,
      quantity: 100,
      stockBefore: 134,
      stockAfter: 234,
      note: '季度大批量采购',
      operatorName: '管理员',
      createdAt: now.subtract(const Duration(days: 5)),
    ),
    InventoryTransaction(
      id: 'TX-004',
      productId: 'HYY-HT003',
      productName: '羊脂白玉貔貅手链',
      type: InventoryTxType.adjustment,
      quantity: 35,
      stockBefore: 38,
      stockAfter: 35,
      note: '年度盘点核减3件（展示损耗）',
      operatorName: '管理员',
      createdAt: now.subtract(const Duration(days: 8)),
    ),
    InventoryTransaction(
      id: 'TX-005',
      productId: 'HYY-FC002',
      productName: '满绿翡翠圆珠手链',
      type: InventoryTxType.returnIn,
      quantity: 2,
      stockBefore: 26,
      stockAfter: 28,
      note: '客户退货（质量无问题）',
      operatorName: '操作员3',
      createdAt: now.subtract(const Duration(days: 10)),
    ),
  ];
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
