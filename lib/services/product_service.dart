/// 汇玉源 - 商品数据服务
///
/// 功能:
/// - 统一管理商品数据获取
/// - 自动切换API/本地数据源
/// - 缓存管理
/// - 商品CRUD操作
library;

import '../models/user_model.dart';
import '../config/api_config.dart';
import '../data/product_data.dart';
import 'api_service.dart';

/// 商品服务
class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final ApiService _api = ApiService();

  // 缓存
  List<ProductModel>? _cachedProducts;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// 获取商品列表
  ///
  /// [category] 分类筛选
  /// [forceRefresh] 强制刷新（忽略缓存）
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
    // 检查缓存
    if (!forceRefresh &&
        _isCacheValid() &&
        page == 1 &&
        _cachedProducts != null) {
      return _filterProducts(_cachedProducts!, category: category);
    }

    // 尝试从API获取
    if (!ApiConfig.useMockApi) {
      try {
        final result = await _api.get<List<dynamic>>(
          ApiConfig.products,
          params: {
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
          },
        );

        if (result.success && result.data != null) {
          final products = result.data!
              .map(
                  (json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // 更新缓存（仅第一页）
          if (page == 1) {
            _cachedProducts = products;
            _cacheTime = DateTime.now();
          }

          return products;
        }
      } catch (_) {
        // API失败，回退使用本地数据
      }
    }

    // 使用本地模拟数据
    return _getLocalProducts(
      category: category,
      material: material,
      minPrice: minPrice,
      maxPrice: maxPrice,
      isHot: isHot,
      isNew: isNew,
      isWelfare: isWelfare,
      search: search,
      sortBy: sortBy,
    );
  }

  /// 获取商品详情
  Future<ProductModel?> getProductDetail(String productId) async {
    // 先从缓存查找
    if (_cachedProducts != null) {
      final cached = _cachedProducts!.where((p) => p.id == productId);
      if (cached.isNotEmpty) {
        return cached.first;
      }
    }

    // 从API获取
    if (!ApiConfig.useMockApi) {
      try {
        final result = await _api.get<Map<String, dynamic>>(
          ApiConfig.productDetail(productId),
        );

        if (result.success && result.data != null) {
          return ProductModel.fromJson(result.data!);
        }
      } catch (_) {
        // API失败
      }
    }

    // 从本地数据查找
    return getLocalProductById(productId);
  }

  /// 创建商品（管理员）
  Future<ProductModel?> createProduct({
    required String name,
    required String description,
    required double price,
    double? originalPrice,
    required String category,
    required String material,
    List<String> images = const [],
    int stock = 0,
    bool isHot = false,
    bool isNew = true,
    String? origin,
    bool isWelfare = false,
  }) async {
    if (!ApiConfig.useMockApi) {
      try {
        final result = await _api.post<Map<String, dynamic>>(
          ApiConfig.products,
          data: {
            'name': name,
            'description': description,
            'price': price,
            'original_price': originalPrice,
            'category': category,
            'material': material,
            'images': images,
            'stock': stock,
            'is_hot': isHot,
            'is_new': isNew,
            'origin': origin,
            'is_welfare': isWelfare,
          },
        );

        if (result.success && result.data != null) {
          final product = ProductModel.fromJson(result.data!);
          _invalidateCache();
          return product;
        }
      } catch (_) {
        // 创建失败
      }
      return null;
    }

    // Mock模式
    final newId = 'HYY-MOCK${DateTime.now().millisecondsSinceEpoch}';
    final product = ProductModel(
      id: newId,
      name: name,
      description: description,
      price: price,
      originalPrice: originalPrice,
      category: category,
      material: material,
      origin: origin,
      images:
          images.isNotEmpty ? images : [getDefaultImageForMaterial(material)],
      stock: stock,
      isHot: isHot,
      isNew: isNew,
      isWelfare: isWelfare,
      certificate: 'MOCK-CERT-$newId',
      materialVerify: material,
    );

    addProduct(product);
    _invalidateCache();
    return product;
  }

  /// 更新商品（管理员）
  Future<ProductModel?> updateProduct(
    String productId, {
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? material,
    List<String>? images,
    int? stock,
    bool? isHot,
    bool? isNew,
    String? origin,
    bool? isWelfare,
  }) async {
    if (!ApiConfig.useMockApi) {
      try {
        final result = await _api.put<Map<String, dynamic>>(
          ApiConfig.productDetail(productId),
          data: {
            if (name != null) 'name': name,
            if (description != null) 'description': description,
            if (price != null) 'price': price,
            if (originalPrice != null) 'original_price': originalPrice,
            if (category != null) 'category': category,
            if (material != null) 'material': material,
            if (images != null) 'images': images,
            if (stock != null) 'stock': stock,
            if (isHot != null) 'is_hot': isHot,
            if (isNew != null) 'is_new': isNew,
            if (origin != null) 'origin': origin,
            if (isWelfare != null) 'is_welfare': isWelfare,
          },
        );

        if (result.success && result.data != null) {
          final product = ProductModel.fromJson(result.data!);
          _invalidateCache();
          return product;
        }
      } catch (_) {
        // 更新失败
      }
      return null;
    }

    // Mock模式
    final existingIndex = allProducts.indexWhere((p) => p.id == productId);
    if (existingIndex < 0) return null;

    final old = allProducts[existingIndex];
    final updated = ProductModel(
      id: old.id,
      name: name ?? old.name,
      description: description ?? old.description,
      price: price ?? old.price,
      originalPrice: originalPrice ?? old.originalPrice,
      category: category ?? old.category,
      material: material ?? old.material,
      origin: origin ?? old.origin,
      images: images ?? old.images,
      stock: stock ?? old.stock,
      isHot: isHot ?? old.isHot,
      isNew: isNew ?? old.isNew,
      isWelfare: isWelfare ?? old.isWelfare,
      rating: old.rating,
      salesCount: old.salesCount,
      certificate: old.certificate,
      blockchainHash: old.blockchainHash,
      materialVerify: old.materialVerify,
    );

    allProducts[existingIndex] = updated;
    _invalidateCache();
    return updated;
  }

  /// 删除商品（管理员）
  Future<bool> deleteProduct(String productId) async {
    if (!ApiConfig.useMockApi) {
      try {
        final result = await _api.delete<Map<String, dynamic>>(
          ApiConfig.productDetail(productId),
        );

        if (result.success) {
          _invalidateCache();
          return true;
        }
      } catch (_) {
        // 删除失败
      }
      return false;
    }

    // Mock模式
    final result = removeProduct(productId);
    if (result) _invalidateCache();
    return result;
  }

  /// 获取热门商品
  Future<List<ProductModel>> getHotProducts({int limit = 10}) async {
    return getProducts(isHot: true, pageSize: limit);
  }

  /// 获取新品
  Future<List<ProductModel>> getNewProducts({int limit = 10}) async {
    return getProducts(isNew: true, pageSize: limit);
  }

  /// 获取福利款
  Future<List<ProductModel>> getWelfareProducts({int limit = 10}) async {
    return getProducts(isWelfare: true, pageSize: limit);
  }

  /// 搜索商品
  Future<List<ProductModel>> searchProducts(String keyword) async {
    if (keyword.isEmpty) return [];
    return getProducts(search: keyword);
  }

  /// 获取分类列表
  List<String> getCategories() {
    return ['全部', '手链', '吊坠', '戒指', '手镯', '项链', '耳饰', '手串'];
  }

  /// 获取材质列表
  List<String> getMaterials() {
    return ['和田玉', '缅甸翡翠', '南红玛瑙', '紫水晶', '碧玉', '蜜蜡', '黄金', '红宝石', '蓝宝石'];
  }

  // ============ 私有方法 ============

  /// 检查缓存是否有效
  bool _isCacheValid() {
    if (_cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  /// 清除缓存
  void _invalidateCache() {
    _cachedProducts = null;
    _cacheTime = null;
  }

  /// 筛选商品
  List<ProductModel> _filterProducts(
    List<ProductModel> products, {
    String? category,
  }) {
    if (category == null || category == '全部') {
      return products;
    }
    return products.where((p) => p.category == category).toList();
  }

  /// 获取本地商品数据
  List<ProductModel> _getLocalProducts({
    String? category,
    String? material,
    double? minPrice,
    double? maxPrice,
    bool? isHot,
    bool? isNew,
    bool? isWelfare,
    String? search,
    String? sortBy,
  }) {
    List<ProductModel> products = List.from(allProducts);

    // 分类筛选
    if (category != null && category != '全部') {
      products = products.where((p) => p.category == category).toList();
    }

    // 材质筛选
    if (material != null) {
      products = products.where((p) => p.material == material).toList();
    }

    // 价格筛选
    if (minPrice != null) {
      products = products.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      products = products.where((p) => p.price <= maxPrice).toList();
    }

    // 标签筛选
    if (isHot == true) {
      products = products.where((p) => p.isHot).toList();
    }
    if (isNew == true) {
      products = products.where((p) => p.isNew).toList();
    }
    if (isWelfare == true) {
      products = products.where((p) => p.isWelfare).toList();
    }

    // 搜索
    if (search != null && search.isNotEmpty) {
      final keyword = search.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(keyword) ||
              p.description.toLowerCase().contains(keyword) ||
              p.material.toLowerCase().contains(keyword))
          .toList();
    }

    // 排序
    switch (sortBy) {
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

    return products;
  }
}
