/// 汇玉源 - 商品数据服务
///
/// 功能:
/// - 统一管理商品数据获取
/// - API-first product fetching with cache
/// - 缓存管理
/// - 商品CRUD操作
library;

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
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
    // 有筛选/排序/搜索参数时跳过缓存，确保返回正确过滤结果
    final hasFilters = material != null ||
        minPrice != null ||
        maxPrice != null ||
        isHot != null ||
        isNew != null ||
        isWelfare != null ||
        search != null ||
        sortBy != null;

    // 检查缓存（仅无筛选的首页请求使用缓存）
    if (!forceRefresh &&
        !hasFilters &&
        _isCacheValid() &&
        page == 1 &&
        _cachedProducts != null) {
      return _filterProducts(_cachedProducts!, category: category);
    }

    // 尝试从API获取
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
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // 更新缓存（仅第一页）
        if (page == 1) {
          _cachedProducts = products;
          _cacheTime = DateTime.now();
        }

        return products;
      }
    } catch (e) {
      // API失败，返回空列表
      debugPrint('[ProductService] 获取商品列表失败: $e');
    }

    // Keep the service API-only. Callers decide how to handle empty results.
    return [];
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
    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConfig.productDetail(productId),
      );

      if (result.success && result.data != null) {
        return ProductModel.fromJson(result.data!);
      }
    } catch (e) {
      debugPrint('[ProductService] 获取商品详情失败: $e');
    }

    return null;
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
    } catch (e) {
      debugPrint('[ProductService] 创建商品失败: $e');
    }
    return null;
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
    } catch (e) {
      debugPrint('[ProductService] 更新商品失败: $e');
    }
    return null;
  }

  /// 删除商品（管理员）
  Future<bool> deleteProduct(String productId) async {
    try {
      final result = await _api.delete<Map<String, dynamic>>(
        ApiConfig.productDetail(productId),
      );

      if (result.success) {
        _invalidateCache();
        return true;
      }
    } catch (e) {
      debugPrint('[ProductService] 删除商品失败: $e');
    }
    return false;
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
}
