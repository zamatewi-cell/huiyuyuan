/// HuiYuYuan cart item model.
/// Provides a strongly typed cart structure instead of a loose map.
library;

import 'json_parsing.dart';
import 'product_model.dart';

/// Cart item model.
class CartItemModel {
  /// Full product payload.
  final ProductModel product;

  /// Selected quantity.
  final int quantity;

  /// Selected spec when the product supports variants.
  final String? selectedSpec;

  /// Whether the item is selected for batch actions.
  final bool isSelected;

  /// Timestamp for when the item was added to the cart.
  final DateTime addedAt;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedSpec,
    this.isSelected = true,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Subtotal price for this cart entry.
  double get subtotal => product.price * quantity;

  /// Whether the product still has stock.
  bool get inStock => product.stock > 0;

  /// Whether the selected quantity exceeds stock.
  bool get exceedsStock => quantity > product.stock;

  /// Builds a cart item from JSON in either the legacy or nested format.
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Nested format with a dedicated product payload.
    if (json.containsKey('product') && json['product'] is Map) {
      return CartItemModel(
        product: ProductModel.fromJson(jsonAsMap(json['product'])),
        quantity: jsonAsInt(json['quantity'], fallback: 1),
        selectedSpec: jsonAsNullableString(json['selected_spec']),
        isSelected: jsonAsBool(json['is_selected'], fallback: true),
        addedAt: jsonAsNullableDateTime(json['added_at']),
      );
    }

    // Legacy flat map kept for existing StorageService data.
    return CartItemModel(
      product: ProductModel.fromJson(json),
      quantity: jsonAsInt(json['quantity'], fallback: 1),
      selectedSpec: jsonAsNullableString(json['selected_spec']),
      isSelected: jsonAsBool(json['is_selected'], fallback: true),
      addedAt: jsonAsNullableDateTime(json['added_at']),
    );
  }

  /// Serializes the item to the legacy flat JSON structure.
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

  /// Serializes the item to the nested JSON structure.
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
