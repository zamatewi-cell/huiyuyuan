library;

import '../data/product_runtime_catalog.dart';
import '../data/product_runtime_store.dart';
import '../models/product_model.dart';
import '../models/product_upsert_request.dart';
import '../services/storage_service.dart';

typedef LocalProductIdBuilder = String Function();

class ProductCatalogQuery {
  final String? category;
  final String? material;
  final double? minPrice;
  final double? maxPrice;
  final bool? isHot;
  final bool? isNew;
  final bool? isWelfare;
  final String? search;
  final String? sortBy;
  final int page;
  final int pageSize;

  const ProductCatalogQuery({
    this.category,
    this.material,
    this.minPrice,
    this.maxPrice,
    this.isHot,
    this.isNew,
    this.isWelfare,
    this.search,
    this.sortBy,
    this.page = 1,
    this.pageSize = 20,
  });

  bool get hasFilters =>
      (category != null && category != '全部') ||
      material != null ||
      minPrice != null ||
      maxPrice != null ||
      isHot != null ||
      isNew != null ||
      isWelfare != null ||
      search != null ||
      sortBy != null;

  Map<String, dynamic> toApiParams() {
    return {
      if (category != null && category != '全部') 'category': category,
      if (material != null) 'material': material,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (isHot != null) 'is_hot': isHot,
      if (isNew != null) 'is_new': isNew,
      if (isWelfare != null) 'is_welfare': isWelfare,
      if (search != null) 'search': search,
      if (sortBy != null) 'sort_by': sortBy,
      'page': page,
      'page_size': pageSize,
    };
  }
}

class ProductCatalogRepository {
  ProductCatalogRepository({
    List<ProductModel> Function()? productLoader,
    ProductRuntimeCatalog? runtimeCatalog,
    LocalProductIdBuilder? localProductIdBuilder,
    StorageService? storageService,
    String runtimePersistenceKey = _defaultRuntimePersistenceKey,
  })  : _runtimeCatalog = runtimeCatalog ??
            (productLoader == null ? productRuntimeCatalog : null),
        _productLoader = productLoader ??
            (() => (runtimeCatalog ?? productRuntimeCatalog).allProducts),
        _localProductIdBuilder =
            localProductIdBuilder ?? _defaultLocalProductIdBuilder,
        _storageService = storageService ?? StorageService(),
        _runtimePersistenceKey = runtimePersistenceKey;

  final ProductRuntimeCatalog? _runtimeCatalog;
  final List<ProductModel> Function() _productLoader;
  final LocalProductIdBuilder _localProductIdBuilder;
  final StorageService _storageService;
  final String _runtimePersistenceKey;

  static const String _defaultRuntimePersistenceKey =
      'product_catalog_runtime_overlay';

  bool get hasRuntimeOverrides => _runtimeCatalog?.hasRuntimeOverrides ?? false;

  List<ProductModel> listAllProducts() =>
      List<ProductModel>.unmodifiable(_productLoader());

  List<ProductModel> listProducts(ProductCatalogQuery query) {
    var products = List<ProductModel>.from(_productLoader());

    if (query.category != null && query.category != '全部') {
      products = products.where((p) => p.category == query.category).toList();
    }
    if (query.material != null) {
      products = products.where((p) => p.material == query.material).toList();
    }
    if (query.minPrice != null) {
      products = products.where((p) => p.price >= query.minPrice!).toList();
    }
    if (query.maxPrice != null) {
      products = products.where((p) => p.price <= query.maxPrice!).toList();
    }
    if (query.isHot != null) {
      products = products.where((p) => p.isHot == query.isHot).toList();
    }
    if (query.isNew != null) {
      products = products.where((p) => p.isNew == query.isNew).toList();
    }
    if (query.isWelfare != null) {
      products = products.where((p) => p.isWelfare == query.isWelfare).toList();
    }
    if (query.search != null && query.search!.trim().isNotEmpty) {
      final keyword = query.search!.trim().toLowerCase();
      products = products.where((product) {
        return product.name.toLowerCase().contains(keyword) ||
            product.description.toLowerCase().contains(keyword) ||
            product.material.toLowerCase().contains(keyword);
      }).toList();
    }

    switch (query.sortBy) {
      case 'price_asc':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'sales':
        products.sort((a, b) => b.salesCount.compareTo(a.salesCount));
        break;
      case 'rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    if (query.pageSize <= 0) {
      return const [];
    }

    final safePage = query.page < 1 ? 1 : query.page;
    final start = (safePage - 1) * query.pageSize;
    if (start >= products.length) {
      return const [];
    }

    final end = start + query.pageSize > products.length
        ? products.length
        : start + query.pageSize;
    return products.sublist(start, end);
  }

  ProductModel? getProductDetail(String productId) {
    try {
      return _productLoader().firstWhere((product) => product.id == productId);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> getSeedProducts() {
    return List<ProductModel>.unmodifiable(
        _requireRuntimeCatalog().seedProducts);
  }

  List<ProductModel> getRuntimeOnlyProducts() {
    return List<ProductModel>.unmodifiable(
      _requireRuntimeCatalog().runtimeOnlyProducts,
    );
  }

  void saveRuntimeProduct(ProductModel product) {
    _requireRuntimeCatalog().addProduct(product);
  }

  ProductModel createRuntimeProduct(ProductUpsertRequest request) {
    final product = _buildProductFromRequest(
      request,
      productId: _localProductIdBuilder(),
    );
    saveRuntimeProduct(product);
    return product;
  }

  ProductModel? updateRuntimeProduct(
    String productId,
    ProductUpsertRequest request,
  ) {
    final existing = _requireRuntimeCatalog().getProductById(productId);
    if (existing == null) {
      return null;
    }

    final product = _buildProductFromRequest(
      request,
      productId: productId,
      existing: existing,
    );
    saveRuntimeProduct(product);
    return product;
  }

  bool deleteRuntimeProduct(String productId) {
    return _requireRuntimeCatalog().removeProduct(productId);
  }

  void resetRuntimeOverrides() {
    _requireRuntimeCatalog().reset();
  }

  Future<void> initializeRuntimeOverrides() async {
    final runtimeCatalog = _runtimeCatalog;
    if (runtimeCatalog == null) {
      return;
    }

    final payload =
        await _storageService.getProductRuntimeOverlay(_runtimePersistenceKey);
    if (payload == null) {
      runtimeCatalog.reset();
      return;
    }

    runtimeCatalog.restoreSnapshot(ProductRuntimeSnapshot.fromJson(payload));
  }

  Future<void> persistRuntimeOverrides() async {
    final runtimeCatalog = _runtimeCatalog;
    if (runtimeCatalog == null) {
      return;
    }

    final snapshot = runtimeCatalog.buildSnapshot();
    if (snapshot.isEmpty) {
      await _storageService.clearProductRuntimeOverlay(_runtimePersistenceKey);
      return;
    }

    await _storageService.saveProductRuntimeOverlay(
      _runtimePersistenceKey,
      snapshot.toJson(),
    );
  }

  List<String> getCategories() {
    return ['全部', ..._uniqueValues((product) => product.category)];
  }

  List<String> getMaterials() {
    return _uniqueValues((product) => product.material);
  }

  List<String> _uniqueValues(String Function(ProductModel product) pickValue) {
    final values = <String>{};
    for (final product in _productLoader()) {
      values.add(pickValue(product));
    }
    return values.toList(growable: false);
  }

  ProductRuntimeCatalog _requireRuntimeCatalog() {
    final runtimeCatalog = _runtimeCatalog;
    if (runtimeCatalog == null) {
      throw StateError(
        'Runtime catalog support is unavailable for a read-only productLoader.',
      );
    }
    return runtimeCatalog;
  }

  ProductModel _buildProductFromRequest(
    ProductUpsertRequest request, {
    required String productId,
    ProductModel? existing,
  }) {
    return ProductModel(
      id: productId,
      name: request.name,
      description: request.description,
      price: request.price,
      originalPrice: request.originalPrice ?? existing?.originalPrice,
      category: request.category,
      material: request.material,
      images: List<String>.from(request.images ?? existing?.images ?? const []),
      stock: request.stock,
      rating: existing?.rating ?? 5.0,
      salesCount: existing?.salesCount ?? 0,
      isHot: request.isHot ?? existing?.isHot ?? false,
      isNew: request.isNew ?? existing?.isNew ?? false,
      origin: request.origin ?? existing?.origin,
      certificate: request.certificate ?? existing?.certificate,
      blockchainHash: existing?.blockchainHash,
      isWelfare: request.isWelfare ??
          existing?.isWelfare ??
          (request.price >= 199 && request.price <= 599),
      materialVerify: existing?.materialVerify ?? '天然A货',
    );
  }

  static String _defaultLocalProductIdBuilder() {
    return 'LOCAL-${DateTime.now().microsecondsSinceEpoch}';
  }
}
