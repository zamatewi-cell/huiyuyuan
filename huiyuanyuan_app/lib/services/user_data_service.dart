library;

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final ApiService _api = ApiService();

  Future<void> initialize() async {
    await _api.initialize();
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final result = await _api.get<List<dynamic>>(ApiConfig.favorites);
      if (result.success && result.data != null) {
        return result.data!
            .map((json) => json as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[UserDataService] 获取收藏列表失败: $e');
      return [];
    }
  }

  Future<bool> addToFavorites(String productId) async {
    try {
      final result = await _api.post(ApiConfig.favoriteToggle(productId));
      return result.success;
    } catch (e) {
      debugPrint('[UserDataService] 添加收藏失败: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites(String productId) async {
    try {
      final result = await _api.delete(ApiConfig.favoriteToggle(productId));
      return result.success;
    } catch (e) {
      debugPrint('[UserDataService] 取消收藏失败: $e');
      return false;
    }
  }

  Future<bool> isFavorite(String productId) async {
    try {
      final result =
          await _api.get<Map<String, dynamic>>(ApiConfig.favoriteToggle(productId));
      if (result.success && result.data != null) {
        return result.data!['is_favorite'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('[UserDataService] 检查收藏状态失败: $e');
      return false;
    }
  }

  Future<List<String>> getBrowseHistory({int limit = 50}) async {
    try {
      final result = await _api.get<List<dynamic>>(
        '${ApiConfig.userProfile}/browse-history',
        params: {'limit': limit},
      );
      if (result.success && result.data != null) {
        return result.data!.map((id) => id.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[UserDataService] 获取浏览记录失败: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBrowseHistoryWithDetails({int limit = 50}) async {
    try {
      final result = await _api.get<List<dynamic>>(
        '${ApiConfig.userProfile}/browse-history/details',
        params: {'limit': limit},
      );
      if (result.success && result.data != null) {
        return result.data!
            .map((json) => json as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[UserDataService] 获取浏览记录详情失败: $e');
      return [];
    }
  }

  Future<bool> addToBrowseHistory(String productId) async {
    try {
      final result = await _api.post(
        '${ApiConfig.userProfile}/browse-history',
        data: {'product_id': productId},
      );
      return result.success;
    } catch (e) {
      debugPrint('[UserDataService] 添加浏览记录失败: $e');
      return false;
    }
  }

  Future<bool> clearBrowseHistory() async {
    try {
      final result = await _api.delete('${ApiConfig.userProfile}/browse-history');
      return result.success;
    } catch (e) {
      debugPrint('[UserDataService] 清空浏览记录失败: $e');
      return false;
    }
  }

  Future<List<String>> getSearchHistory({int limit = 20}) async {
    try {
      final result = await _api.get<List<dynamic>>(
        '${ApiConfig.userProfile}/search-history',
        params: {'limit': limit},
      );
      if (result.success && result.data != null) {
        return result.data!.map((q) => q.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[UserDataService] 获取搜索历史失败: $e');
      return [];
    }
  }

  Future<bool> addSearchHistory(String query) async {
    try {
      final result = await _api.post(
        '${ApiConfig.userProfile}/search-history',
        data: {'query': query},
      );
      return result.success;
    } catch (e) {
      debugPrint('[UserDataService] 添加搜索历史失败: $e');
      return false;
    }
  }

  Future<bool> clearSearchHistory() async {
    try {
      final result = await _api.delete('${ApiConfig.userProfile}/search-history');
      return result.success;
    } catch (e) {
      debugPrint('[UserDataService] 清空搜索历史失败: $e');
      return false;
    }
  }

  Future<bool> removeSearchHistoryItem(String query) async {
    try {
      final result = await _api.delete(
        '${ApiConfig.userProfile}/search-history',
        data: {'query': query},
      );
      return result.success;
    } catch (e) {
      debugPrint('[UserDataService] 删除搜索历史项失败: $e');
      return false;
    }
  }

  Future<List<ProductModel>> searchProducts({
    required String keyword,
    String? category,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _api.get<List<dynamic>>(
        ApiConfig.products,
        params: {
          'search': keyword,
          if (category != null && category != '全部') 'category': category,
          if (sortBy != null) 'sort_by': sortBy,
          'page': page,
          'page_size': pageSize,
        },
      );

      if (result.success && result.data != null) {
        return result.data!
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[UserDataService] 搜索商品失败: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getHotProducts({int limit = 4}) async {
    try {
      final result = await _api.get<List<dynamic>>(
        ApiConfig.products,
        params: {
          'is_hot': true,
          'sort_by': 'sales',
          'page_size': limit,
        },
      );

      if (result.success && result.data != null) {
        return result.data!
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[UserDataService] 获取热门商品失败: $e');
      return [];
    }
  }
}
