library;

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../data/product_data.dart';
import '../l10n/product_translator.dart';
import '../models/product_model.dart';
import '../models/product_upsert_request.dart';
import '../providers/app_settings_provider.dart';
import '../repositories/product_catalog_repository.dart';
import 'api_service.dart';

class ProductService {
  static const Set<String> _knownBrokenUnsplashIds = {
    '1661645464570-9a4f3d4dd061',
    '1681276170092-446cd1b5b32d',
    '1661645473770-90d750452fa0',
    '1726743629168-77847c4cbb6a',
    '1678749105251-b15e8fd164bf',
    '1724088684005-4f9f2e1ec43c',
    '1739899051444-fcbdb848db5d',
    '1674255466849-b23fc5f5d3eb',
    '1674255466836-f38d1cc6fd0d',
    '1736818881523-87556344c1a2',
    '1681276170281-cf50a487a1b7',
    '1674157905253-1f5dc638a588',
    '1664202526641-4203eaa33844',
    '1681276169919-d89839416ef7',
    '1674748385691-a185ad303097',
    '1667206795522-430ed80bd9d8',
    '1728216320421-acadfa847591',
    '1673284258408-3341659fbc87',
    '1734315041597-a561152a875b',
    '1671209796002-5da9a14106de',
    '1670728016218-3a3ceec0a483',
    '1661811815190-b99942bf3b74',
  };

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
            .map((json) => _sanitizeProduct(
                  ProductModel.fromJson(json as Map<String, dynamic>),
                ))
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
        return _sanitizeProduct(ProductModel.fromJson(result.data!));
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
        final product = _sanitizeProduct(ProductModel.fromJson(result.data!));
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
        final product = _sanitizeProduct(ProductModel.fromJson(result.data!));
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
    final products = _catalogRepository
        .listProducts(query)
        .map(_sanitizeProduct)
        .toList(growable: false);

    if (query.page == 1 && !query.hasFilters) {
      _cachedProducts = List<ProductModel>.from(products);
      _cacheTime = DateTime.now();
    }

    return products;
  }

  ProductModel _sanitizeProduct(ProductModel product) {
    final staged = product.copyWith(
      images: _sanitizeImageUrls(product.images, product.material),
      materialEn: ProductTranslator.translateMaterial(
        AppLanguage.en,
        product.material,
        allowExact: false,
      ),
      materialZhTw: ProductTranslator.translateMaterial(
        AppLanguage.zhTW,
        product.material,
        allowExact: false,
      ),
      categoryEn: ProductTranslator.translateCategory(
        AppLanguage.en,
        product.category,
        allowExact: false,
      ),
      categoryZhTw: ProductTranslator.translateCategory(
        AppLanguage.zhTW,
        product.category,
        allowExact: false,
      ),
      originEn: product.origin == null
          ? null
          : ProductTranslator.translateOrigin(
              AppLanguage.en,
              product.origin,
              allowExact: false,
            ),
      originZhTw: product.origin == null
          ? null
          : ProductTranslator.translateOrigin(
              AppLanguage.zhTW,
              product.origin,
              allowExact: false,
            ),
      materialVerifyEn: ProductTranslator.translateMaterialVerify(
        AppLanguage.en,
        product.materialVerify,
        allowExact: false,
      ),
      materialVerifyZhTw: ProductTranslator.translateMaterialVerify(
        AppLanguage.zhTW,
        product.materialVerify,
        allowExact: false,
      ),
    );

    final enriched = staged.copyWith(
      nameEn: staged.localizedTitleFor(AppLanguage.en),
      nameZhTw: staged.localizedTitleFor(AppLanguage.zhTW),
      descriptionEn: staged.localizedDescriptionFor(AppLanguage.en),
      descriptionZhTw: staged.localizedDescriptionFor(AppLanguage.zhTW),
    );

    return enriched;
  }

  List<String> _sanitizeImageUrls(List<String> images, String material) {
    final validImages = images
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty && !_isKnownBrokenUrl(image))
        .toList(growable: false);
    if (validImages.isNotEmpty) {
      return validImages;
    }
    return [getDefaultImageForMaterial(material)];
  }

  bool _isKnownBrokenUrl(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.host.contains('images.unsplash.com')) {
      return false;
    }
    final path = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    return _knownBrokenUnsplashIds.contains(path);
  }
}
