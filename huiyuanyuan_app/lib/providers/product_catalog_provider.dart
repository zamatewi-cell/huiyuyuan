library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../models/product_upsert_request.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

class ProductCatalogState {
  const ProductCatalogState({
    this.products = const <ProductModel>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ProductModel> products;
  final bool isLoading;
  final String? errorMessage;

  ProductCatalogState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductCatalogState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProductCatalogNotifier extends StateNotifier<ProductCatalogState> {
  ProductCatalogNotifier({
    required ProductService productService,
  })  : _productService = productService,
        super(const ProductCatalogState(isLoading: true)) {
    unawaited(refresh());
  }

  final ProductService _productService;
  bool _initialized = false;

  Future<void> refresh({bool forceRefresh = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _ensureInitialized();
      final products = await _productService.getProducts(
        pageSize: 200,
        forceRefresh: forceRefresh,
      );

      state = ProductCatalogState(
        products: products,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load products.',
      );
    }
  }

  Future<ProductModel?> createProduct(ProductUpsertRequest request) async {
    await _ensureInitialized();
    final product = await _productService.createProduct(request);
    if (product != null) {
      await refresh();
    }
    return product;
  }

  Future<ProductModel?> updateProduct(
    String productId,
    ProductUpsertRequest request,
  ) async {
    await _ensureInitialized();
    final product = await _productService.updateProduct(productId, request);
    if (product != null) {
      await refresh();
    }
    return product;
  }

  Future<bool> deleteProduct(String productId) async {
    await _ensureInitialized();
    final deleted = await _productService.deleteProduct(productId);
    if (deleted) {
      await refresh();
    }
    return deleted;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _productService.initialize();
    _initialized = true;
  }
}

final productCatalogProvider =
    StateNotifierProvider<ProductCatalogNotifier, ProductCatalogState>((ref) {
  return ProductCatalogNotifier(
    productService: ref.watch(productServiceProvider),
  );
});

final productCatalogProductsProvider = Provider<List<ProductModel>>((ref) {
  return ref.watch(productCatalogProvider).products;
});

final productCatalogCategoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productCatalogProductsProvider);
  final categories = <String>['全部'];
  final seen = <String>{};

  for (final product in products) {
    if (seen.add(product.category)) {
      categories.add(product.category);
    }
  }

  return List<String>.unmodifiable(categories);
});
