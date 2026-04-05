library;

import '../models/product_model.dart';

class ProductRuntimeSnapshot {
  const ProductRuntimeSnapshot({
    this.overrideProducts = const <ProductModel>[],
    this.removedSeedProductIds = const <String>[],
  });

  final List<ProductModel> overrideProducts;
  final List<String> removedSeedProductIds;

  bool get isEmpty => overrideProducts.isEmpty && removedSeedProductIds.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'override_products': overrideProducts
          .map((product) => product.toJson())
          .toList(growable: false),
      'removed_seed_product_ids':
          List<String>.from(removedSeedProductIds, growable: false),
    };
  }

  factory ProductRuntimeSnapshot.fromJson(Map<String, dynamic> json) {
    final rawOverrideProducts =
        json['override_products'] as List<dynamic>? ?? const <dynamic>[];
    final rawRemovedSeedProductIds =
        json['removed_seed_product_ids'] as List<dynamic>? ?? const <dynamic>[];

    return ProductRuntimeSnapshot(
      overrideProducts: rawOverrideProducts
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      removedSeedProductIds: rawRemovedSeedProductIds
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class ProductRuntimeCatalog {
  ProductRuntimeCatalog({
    required List<ProductModel> seedProducts,
  })  : _seedProducts = List<ProductModel>.unmodifiable(seedProducts),
        _seedProductById = {
          for (final product in seedProducts) product.id: product,
        };

  final List<ProductModel> _seedProducts;
  final Map<String, ProductModel> _seedProductById;
  final Map<String, ProductModel> _runtimeOverrides = <String, ProductModel>{};
  final Set<String> _removedSeedProductIds = <String>{};

  List<ProductModel> get seedProducts => _seedProducts;

  List<ProductModel> get runtimeOnlyProducts =>
      List<ProductModel>.unmodifiable(_runtimeOverrides.values);

  List<ProductModel> get runtimeOverrideProducts =>
      List<ProductModel>.unmodifiable(_runtimeOverrides.values);

  List<String> get removedSeedProductIds =>
      List<String>.unmodifiable(_removedSeedProductIds);

  bool get hasRuntimeOverrides =>
      _runtimeOverrides.isNotEmpty || _removedSeedProductIds.isNotEmpty;

  List<ProductModel> get allProducts {
    final merged = <ProductModel>[];
    final appendedRuntimeIds = <String>{};

    for (final seedProduct in _seedProducts) {
      if (_removedSeedProductIds.contains(seedProduct.id)) {
        continue;
      }

      final override = _runtimeOverrides[seedProduct.id];
      if (override != null) {
        merged.add(override);
        appendedRuntimeIds.add(seedProduct.id);
        continue;
      }

      merged.add(seedProduct);
    }

    for (final entry in _runtimeOverrides.entries) {
      if (appendedRuntimeIds.contains(entry.key) ||
          _seedProductById.containsKey(entry.key)) {
        continue;
      }
      merged.add(entry.value);
    }

    return List<ProductModel>.unmodifiable(merged);
  }

  ProductModel? getProductById(String productId) {
    final override = _runtimeOverrides[productId];
    if (override != null) {
      return override;
    }

    if (_removedSeedProductIds.contains(productId)) {
      return null;
    }

    return _seedProductById[productId];
  }

  void addProduct(ProductModel product) {
    _runtimeOverrides[product.id] = product;
    _removedSeedProductIds.remove(product.id);
  }

  bool removeProduct(String productId) {
    final removedRuntimeProduct = _runtimeOverrides.remove(productId) != null;
    final removedSeedProduct = _seedProductById.containsKey(productId);

    if (removedSeedProduct) {
      _removedSeedProductIds.add(productId);
    }

    return removedRuntimeProduct || removedSeedProduct;
  }

  void reset() {
    _runtimeOverrides.clear();
    _removedSeedProductIds.clear();
  }

  ProductRuntimeSnapshot buildSnapshot() {
    return ProductRuntimeSnapshot(
      overrideProducts: runtimeOverrideProducts,
      removedSeedProductIds: removedSeedProductIds,
    );
  }

  void restoreSnapshot(ProductRuntimeSnapshot snapshot) {
    _runtimeOverrides
      ..clear()
      ..addEntries(
        snapshot.overrideProducts.map(
          (product) => MapEntry(product.id, product),
        ),
      );

    _removedSeedProductIds
      ..clear()
      ..addAll(snapshot.removedSeedProductIds);
  }
}
