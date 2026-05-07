library;

import '../data/product_runtime_catalog.dart';
import '../data/product_runtime_store.dart';
import '../l10n/app_strings.dart';
import '../l10n/product_translator.dart';
import '../l10n/translator_global.dart';
import '../models/product_model.dart';
import '../models/product_upsert_request.dart';
import '../providers/app_settings_provider.dart';
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
      (category != null && !_isAllCategory(category)) ||
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
      if (category != null && !_isAllCategory(category)) 'category': category,
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

    if (query.category != null && !_isAllCategory(query.category)) {
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
            (product.nameEn?.toLowerCase().contains(keyword) ?? false) ||
            (product.nameZhTw?.toLowerCase().contains(keyword) ?? false) ||
            product.description.toLowerCase().contains(keyword) ||
            (product.descriptionEn?.toLowerCase().contains(keyword) ?? false) ||
            (product.descriptionZhTw?.toLowerCase().contains(keyword) ??
                false) ||
            product.material.toLowerCase().contains(keyword) ||
            (product.materialEn?.toLowerCase().contains(keyword) ?? false) ||
            (product.materialZhTw?.toLowerCase().contains(keyword) ?? false) ||
            product.category.toLowerCase().contains(keyword) ||
            (product.categoryEn?.toLowerCase().contains(keyword) ?? false) ||
            (product.categoryZhTw?.toLowerCase().contains(keyword) ?? false);
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
    return [
      _t('platform_all'),
      ..._uniqueValues((product) => product.category)
    ];
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
    final materialVerify = existing?.materialVerify ??
        AppStrings.get(AppLanguage.zhCN, 'product_material_verify_natural_a');
    final canonicalCategory =
        ProductTranslator.canonicalCategory(request.category);
    final canonicalMaterial =
        ProductTranslator.canonicalMaterial(request.material);

    return ProductModel(
      id: productId,
      name: request.name,
      description: request.description,
      price: request.price,
      originalPrice: request.originalPrice ?? existing?.originalPrice,
      category: canonicalCategory,
      material: canonicalMaterial,
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
      materialVerify: materialVerify,
      nameEn: ProductTranslator.translateName(AppLanguage.en, request.name),
      nameZhTw: ProductTranslator.translateName(AppLanguage.zhTW, request.name),
      descriptionEn: ProductTranslator.translateDescription(
        AppLanguage.en,
        request.description,
      ),
      descriptionZhTw: ProductTranslator.translateDescription(
        AppLanguage.zhTW,
        request.description,
      ),
      materialEn: ProductTranslator.translateMaterial(
        AppLanguage.en,
        canonicalMaterial,
      ),
      materialZhTw: ProductTranslator.translateMaterial(
        AppLanguage.zhTW,
        canonicalMaterial,
      ),
      categoryEn: ProductTranslator.translateCategory(
        AppLanguage.en,
        canonicalCategory,
      ),
      categoryZhTw: ProductTranslator.translateCategory(
        AppLanguage.zhTW,
        canonicalCategory,
      ),
      originEn: ProductTranslator.translateOrigin(
        AppLanguage.en,
        request.origin ?? existing?.origin,
      ),
      originZhTw: ProductTranslator.translateOrigin(
        AppLanguage.zhTW,
        request.origin ?? existing?.origin,
      ),
      materialVerifyEn: ProductTranslator.translateMaterialVerify(
        AppLanguage.en,
        materialVerify,
      ),
      materialVerifyZhTw: ProductTranslator.translateMaterialVerify(
        AppLanguage.zhTW,
        materialVerify,
      ),
      appraisalNote: request.appraisalNote ?? existing?.appraisalNote,
      appraisalNoteEn: request.appraisalNoteEn ?? existing?.appraisalNoteEn,
      appraisalNoteZhTw:
          request.appraisalNoteZhTw ?? existing?.appraisalNoteZhTw,
      craftHighlights: request.craftHighlights ?? existing?.craftHighlights,
      craftHighlightsEn:
          request.craftHighlightsEn ?? existing?.craftHighlightsEn,
      craftHighlightsZhTw:
          request.craftHighlightsZhTw ?? existing?.craftHighlightsZhTw,
      weightG: request.weightG ?? existing?.weightG,
      dimensions: request.dimensions ?? existing?.dimensions,
      audienceTags: request.audienceTags ?? existing?.audienceTags,
      audienceTagsEn: request.audienceTagsEn ?? existing?.audienceTagsEn,
      audienceTagsZhTw: request.audienceTagsZhTw ?? existing?.audienceTagsZhTw,
      originStory: request.originStory ?? existing?.originStory,
      originStoryEn: request.originStoryEn ?? existing?.originStoryEn,
      originStoryZhTw: request.originStoryZhTw ?? existing?.originStoryZhTw,
      flawNotes: request.flawNotes ?? existing?.flawNotes,
      flawNotesEn: request.flawNotesEn ?? existing?.flawNotesEn,
      flawNotesZhTw: request.flawNotesZhTw ?? existing?.flawNotesZhTw,
      certificateAuthority:
          request.certificateAuthority ?? existing?.certificateAuthority,
      certificateAuthorityEn:
          request.certificateAuthorityEn ?? existing?.certificateAuthorityEn,
      certificateAuthorityZhTw: request.certificateAuthorityZhTw ??
          existing?.certificateAuthorityZhTw,
      certificateImageUrl:
          request.certificateImageUrl ?? existing?.certificateImageUrl,
      certificateVerifyUrl:
          request.certificateVerifyUrl ?? existing?.certificateVerifyUrl,
      galleryDetail: request.galleryDetail ?? existing?.galleryDetail,
      galleryHand: request.galleryHand ?? existing?.galleryHand,
    );
  }

  static String _defaultLocalProductIdBuilder() {
    return 'LOCAL-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return TranslatorGlobal.instance.translate(key, params: params);
  }
}

bool _isAllCategory(String? category) {
  final value = category?.trim();
  if (value == null || value.isEmpty) {
    return false;
  }
  if (value == 'platform_all') {
    return true;
  }
  return AppLanguage.values.any(
    (language) => AppStrings.get(language, 'platform_all') == value,
  );
}
