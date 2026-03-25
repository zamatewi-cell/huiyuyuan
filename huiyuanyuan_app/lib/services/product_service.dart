library;

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/product_model.dart';
import '../models/product_upsert_request.dart';
import '../repositories/product_catalog_repository.dart';
import 'api_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();

  factory ProductService() => _instance;

  ProductService._internal({
    ApiService? api,
    ProductCatalogRepository? catalogRepository,
  })  : _api = api ?? ApiService(),
        _catalogRepository = catalogRepository ?? ProductCatalogRepository();

  @visibleForTesting
  factory ProductService.forTesting(
    ApiService api, {
    ProductCatalogRepository? catalogRepository,
  }) =>
      ProductService._internal(
        api: api,
        catalogRepository: catalogRepository,
      );

  final ApiService _api;
  final ProductCatalogRepository _catalogRepository;

  List<ProductModel>? _cachedProducts;
  DateTime? _cacheTime;

  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<void> initialize() async {
    await _catalogRepository.initializeRuntimeOverrides();
    _invalidateCache();
  }

  Future<List<ProductModel>> getProducts({
    String? category,
    String? material,
    double? minPrice,
    double? maxPrice,
    bool? isHot,
    bool? isNew,
    bool? isWelfare,
    String? search,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    final query = ProductCatalogQuery(
      category: category,
      material: material,
      minPrice: minPrice,
      maxPrice: maxPrice,
      isHot: isHot,
      isNew: isNew,
      isWelfare: isWelfare,
      search: search,
      sortBy: sortBy,
      page: page,
      pageSize: pageSize,
    );

    if (!forceRefresh &&
        !query.hasFilters &&
        _isCacheValid() &&
        page == 1 &&
        _cachedProducts != null) {
      return _cachedProducts!;
    }

    if (ApiConfig.useMockApi) {
      return _getCatalogProducts(query);
    }

    try {
      final result = await _api.get<List<dynamic>>(
        ApiConfig.products,
        params: query.toApiParams(),
      );

      if (result.success && result.data != null) {
        final products = result.data!
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (page == 1) {
          _cachedProducts = products;
          _cacheTime = DateTime.now();
        }

        return products;
      }
    } catch (e) {
      debugPrint('[ProductService] failed to load products: $e');
    }

    return _getCatalogProducts(query);
  }

  Future<ProductModel?> getProductDetail(String productId) async {
    if (ApiConfig.useMockApi) {
      return _catalogRepository.getProductDetail(productId);
    }

    if (_cachedProducts != null) {
      final cached = _cachedProducts!.where((p) => p.id == productId);
      if (cached.isNotEmpty) {
        return cached.first;
      }
    }

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConfig.productDetail(productId),
      );

      if (result.success && result.data != null) {
        return ProductModel.fromJson(result.data!);
      }
    } catch (e) {
      debugPrint('[ProductService] failed to load product detail: $e');
    }

    return _catalogRepository.getProductDetail(productId);
  }

  Future<ProductModel?> createProduct(ProductUpsertRequest request) async {
    if (ApiConfig.useMockApi) {
      final product = _catalogRepository.createRuntimeProduct(request);
      _invalidateCache();
      await _catalogRepository.persistRuntimeOverrides();
      return product;
    }

    try {
      final result = await _api.post<Map<String, dynamic>>(
        ApiConfig.products,
        data: request.toJson(),
      );

      if (result.success && result.data != null) {
        final product = ProductModel.fromJson(result.data!);
        _invalidateCache();
        return product;
      }
    } catch (e) {
      debugPrint('[ProductService] failed to create product: $e');
    }
    return null;
  }

  Future<ProductModel?> updateProduct(
    String productId,
    ProductUpsertRequest request,
  ) async {
    if (ApiConfig.useMockApi) {
      final product = _catalogRepository.updateRuntimeProduct(
        productId,
        request,
      );
      if (product != null) {
        _invalidateCache();
        await _catalogRepository.persistRuntimeOverrides();
      }
      return product;
    }

    try {
      final result = await _api.put<Map<String, dynamic>>(
        ApiConfig.productDetail(productId),
        data: request.toJson(),
      );

      if (result.success && result.data != null) {
        final product = ProductModel.fromJson(result.data!);
        _invalidateCache();
        return product;
      }
    } catch (e) {
      debugPrint('[ProductService] failed to update product: $e');
    }
    return null;
  }

  Future<bool> deleteProduct(String productId) async {
    if (ApiConfig.useMockApi) {
      final deleted = _catalogRepository.deleteRuntimeProduct(productId);
      if (deleted) {
        _invalidateCache();
        await _catalogRepository.persistRuntimeOverrides();
      }
      return deleted;
    }

    try {
      final result = await _api.delete<Map<String, dynamic>>(
        ApiConfig.productDetail(productId),
      );

      if (result.success) {
        _invalidateCache();
        return true;
      }
    } catch (e) {
      debugPrint('[ProductService] failed to delete product: $e');
    }
    return false;
  }

  Future<List<ProductModel>> getHotProducts({int limit = 10}) async {
    return getProducts(isHot: true, pageSize: limit);
  }

  Future<List<ProductModel>> getNewProducts({int limit = 10}) async {
    return getProducts(isNew: true, pageSize: limit);
  }

  Future<List<ProductModel>> getWelfareProducts({int limit = 10}) async {
    return getProducts(isWelfare: true, pageSize: limit);
  }

  Future<List<ProductModel>> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      return const [];
    }
    return getProducts(search: keyword);
  }

  List<String> getCategories() {
    return _catalogRepository.getCategories();
  }

  List<String> getMaterials() {
    return _catalogRepository.getMaterials();
  }

  bool _isCacheValid() {
    if (_cacheTime == null) {
      return false;
    }
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  void _invalidateCache() {
    _cachedProducts = null;
    _cacheTime = null;
  }

  List<ProductModel> _getCatalogProducts(ProductCatalogQuery query) {
    final products = _catalogRepository.listProducts(query);

    if (query.page == 1 && !query.hasFilters) {
      _cachedProducts = List<ProductModel>.from(products);
      _cacheTime = DateTime.now();
    }

    return products;
  }
}
