/// 汇玉源 - 内部库存模型
library;

/// 库存操作类型
enum InventoryTxType {
  stockIn, // 入库
  stockOut, // 出库
  adjustment, // 盘点调整
  returnIn, // 退货入库
}

extension InventoryTxTypeExt on InventoryTxType {
  String get label {
    switch (this) {
      case InventoryTxType.stockIn:
        return '入库';
      case InventoryTxType.stockOut:
        return '出库';
      case InventoryTxType.adjustment:
        return '盘点调整';
      case InventoryTxType.returnIn:
        return '退货入库';
    }
  }

  bool get isPositive =>
      this == InventoryTxType.stockIn || this == InventoryTxType.returnIn;
}

/// 库存商品条目（每种SKU当前库存状态）
class InventoryItem {
  final String productId;
  final String productName;
  final String category;
  final String? imageUrl;
  int currentStock; // 当前库存（件）
  int minStock; // 最低安全库存（件）
  double costPrice; // 进货成本价（元/件）
  double sellingPrice; // 销售价（元/件）
  DateTime lastUpdated;

  InventoryItem({
    required this.productId,
    required this.productName,
    required this.category,
    this.imageUrl,
    required this.currentStock,
    this.minStock = 10,
    required this.costPrice,
    required this.sellingPrice,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// 是否低库存预警
  bool get isLowStock => currentStock <= minStock && currentStock > 0;

  /// 是否已售罄
  bool get isOutOfStock => currentStock <= 0;

  /// 当前库存总值（按成本价）
  double get stockValue => currentStock * costPrice;

  /// 当前库存总值（按售价）
  double get stockSellingValue => currentStock * sellingPrice;

  InventoryItem copyWith({
    int? currentStock,
    int? minStock,
    double? costPrice,
    double? sellingPrice,
    DateTime? lastUpdated,
  }) {
    return InventoryItem(
      productId: productId,
      productName: productName,
      category: category,
      imageUrl: imageUrl,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'category': category,
        'image_url': imageUrl,
        'current_stock': currentStock,
        'min_stock': minStock,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'last_updated': lastUpdated.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        productId: json['product_id'],
        productName: json['product_name'],
        category: json['category'],
        imageUrl: json['image_url'],
        currentStock: json['current_stock'],
        minStock: json['min_stock'] ?? 10,
        costPrice: (json['cost_price'] as num).toDouble(),
        sellingPrice: (json['selling_price'] as num).toDouble(),
        lastUpdated: json['last_updated'] != null
            ? DateTime.parse(json['last_updated'])
            : DateTime.now(),
      );
}

/// 单条库存流水记录
class InventoryTransaction {
  final String id;
  final String productId;
  final String productName;
  final InventoryTxType type;
  final int quantity; // 正数
  final int stockBefore; // 操作前库存
  final int stockAfter; // 操作后库存
  final String? note; // 备注
  final String? operatorName; // 经办人
  final DateTime createdAt;

  const InventoryTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.note,
    this.operatorName,
    required this.createdAt,
  });

  int get delta => type.isPositive ? quantity : -quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'type': type.name,
        'quantity': quantity,
        'stock_before': stockBefore,
        'stock_after': stockAfter,
        'note': note,
        'operator_name': operatorName,
        'created_at': createdAt.toIso8601String(),
      };

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) =>
      InventoryTransaction(
        id: json['id'],
        productId: json['product_id'],
        productName: json['product_name'],
        type: InventoryTxType.values
            .firstWhere((e) => e.name == json['type'],
                orElse: () => InventoryTxType.stockIn),
        quantity: json['quantity'],
        stockBefore: json['stock_before'],
        stockAfter: json['stock_after'],
        note: json['note'],
        operatorName: json['operator_name'],
        createdAt: DateTime.parse(json['created_at']),
      );
}

/// 库存统计快照
class InventoryStats {
  final int totalSkus; // 总SKU数
  final int totalUnits; // 总库存件数
  final double totalCostValue; // 总库存成本值
  final double totalSellingValue; // 总库存售价值
  final int lowStockCount; // 低库存预警数
  final int outOfStockCount; // 售罄数
  final int txCountThisMonth; // 本月流水笔数

  const InventoryStats({
    required this.totalSkus,
    required this.totalUnits,
    required this.totalCostValue,
    required this.totalSellingValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.txCountThisMonth,
  });
}
