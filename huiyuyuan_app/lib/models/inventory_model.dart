/// HuiYuYuan internal inventory models.
library;

import '../l10n/translator_global.dart';

import 'json_parsing.dart';

/// Inventory transaction types.
enum InventoryTxType {
  stockIn, // Stock intake
  stockOut, // Stock removal
  adjustment, // Manual stock adjustment
  returnIn, // Returned stock intake
}

extension InventoryTxTypeExt on InventoryTxType {
  String get label {
    switch (this) {
      case InventoryTxType.stockIn:
        return TranslatorGlobal.instance.translate('inventory_action_stock_in');
      case InventoryTxType.stockOut:
        return TranslatorGlobal.instance
            .translate('inventory_action_stock_out');
      case InventoryTxType.adjustment:
        return TranslatorGlobal.instance
            .translate('inventory_action_adjustment');
      case InventoryTxType.returnIn:
        return TranslatorGlobal.instance
            .translate('inventory_action_return_in');
    }
  }

  bool get isPositive =>
      this == InventoryTxType.stockIn || this == InventoryTxType.returnIn;
}

/// Inventory entry representing the current state of a SKU.
class InventoryItem {
  final String productId;
  final String productName;
  final String category;
  final String? imageUrl;
  int currentStock; // Current stock in units
  int minStock; // Minimum safe stock in units
  double costPrice; // Cost price per unit
  double sellingPrice; // Selling price per unit
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

  /// Whether the item is below the low-stock threshold.
  bool get isLowStock => currentStock <= minStock && currentStock > 0;

  /// Whether the item is out of stock.
  bool get isOutOfStock => currentStock <= 0;

  /// Inventory value based on cost price.
  double get stockValue => currentStock * costPrice;

  /// Inventory value based on selling price.
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
        productId: jsonAsString(json['product_id']),
        productName: jsonAsString(json['product_name']),
        category: jsonAsString(json['category']),
        imageUrl: jsonAsNullableString(json['image_url']),
        currentStock: jsonAsInt(json['current_stock']),
        minStock: jsonAsInt(json['min_stock'], fallback: 10),
        costPrice: jsonAsDouble(json['cost_price']),
        sellingPrice: jsonAsDouble(json['selling_price']),
        lastUpdated: jsonAsDateTime(json['last_updated']),
      );
}

/// Single inventory transaction record.
class InventoryTransaction {
  final String id;
  final String productId;
  final String productName;
  final InventoryTxType type;
  final int quantity; // Always positive
  final int stockBefore; // Stock level before the change
  final int stockAfter; // Stock level after the change
  final String? note; // Optional note
  final String? operatorName; // Operator who handled the change
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
        id: jsonAsString(json['id']),
        productId: jsonAsString(json['product_id']),
        productName: jsonAsString(json['product_name']),
        type: jsonEnumByName(
          InventoryTxType.values,
          json['type'],
          fallback: InventoryTxType.stockIn,
        ),
        quantity: jsonAsInt(json['quantity']),
        stockBefore: jsonAsInt(json['stock_before']),
        stockAfter: jsonAsInt(json['stock_after']),
        note: jsonAsNullableString(json['note']),
        operatorName: jsonAsNullableString(json['operator_name']),
        createdAt: jsonAsDateTime(json['created_at']),
      );
}

/// Inventory statistics snapshot.
class InventoryStats {
  final int totalSkus; // Total number of SKUs
  final int totalUnits; // Total stock units
  final double totalCostValue; // Total inventory value at cost
  final double totalSellingValue; // Total inventory value at selling price
  final int lowStockCount; // Number of low-stock items
  final int outOfStockCount; // Number of sold-out items
  final int txCountThisMonth; // Number of transactions this month

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
