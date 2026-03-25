/// 汇玉源 - 购物车项模型
/// 强类型购物车数据结构，替代原有 Map<String, dynamic>
library;

import 'json_parsing.dart';
import 'product_model.dart';

/// 购物车项模型
class CartItemModel {
  /// 商品完整对象
  final ProductModel product;

  /// 数量
  final int quantity;

  /// 选中的规格（如有）
  final String? selectedSpec;

  /// 是否被勾选（批量操作用）
  final bool isSelected;

  /// 加入时间
  final DateTime addedAt;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedSpec,
    this.isSelected = true,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// 小计金额
  double get subtotal => product.price * quantity;

  /// 是否有库存
  bool get inStock => product.stock > 0;

  /// 是否超出库存
  bool get exceedsStock => quantity > product.stock;

  /// 从 JSON Map 创建（兼容旧格式 + 新格式）
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // 新格式: 包含 'product' key
    if (json.containsKey('product') && json['product'] is Map) {
      return CartItemModel(
        product: ProductModel.fromJson(jsonAsMap(json['product'])),
        quantity: jsonAsInt(json['quantity'], fallback: 1),
        selectedSpec: jsonAsNullableString(json['selected_spec']),
        isSelected: jsonAsBool(json['is_selected'], fallback: true),
        addedAt: jsonAsNullableDateTime(json['added_at']),
      );
    }

    // 旧格式: 扁平 Map（兼容现有 StorageService 数据）
    return CartItemModel(
      product: ProductModel.fromJson(json),
      quantity: jsonAsInt(json['quantity'], fallback: 1),
      selectedSpec: jsonAsNullableString(json['selected_spec']),
      isSelected: jsonAsBool(json['is_selected'], fallback: true),
      addedAt: jsonAsNullableDateTime(json['added_at']),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    final productJson = product.toJson();
    return {
      ...productJson,
      'quantity': quantity,
      'selected_spec': selectedSpec,
      'is_selected': isSelected,
      'added_at': addedAt.toIso8601String(),
    };
  }

  /// 序列化为嵌套 JSON（新格式）
  Map<String, dynamic> toNestedJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'selected_spec': selectedSpec,
      'is_selected': isSelected,
      'added_at': addedAt.toIso8601String(),
    };
  }

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? selectedSpec,
    bool? isSelected,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSpec: selectedSpec ?? this.selectedSpec,
      isSelected: isSelected ?? this.isSelected,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
