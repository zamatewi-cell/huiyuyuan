library;

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import '../models/product_model.dart';
import '../models/user_data_models.dart';
import '../services/api_service.dart';

class UserDataRepository {
  UserDataRepository({ApiService? apiService})
      : _api = apiService ?? ApiService();

  final ApiService _api;

  Future<void> initialize() async {
    await _api.initialize();
  }

  Future<List<ProductModel>> getFavorites() async {
    try {
      final result = await _api.get<dynamic>(ApiConfig.favorites);
      if (!result.success || result.data == null) return const [];
      return parseProductSummaries(result.data);
    } catch (error) {
      debugPrint('[UserDataRepository] getFavorites failed: $error');
      return const [];
    }
  }

  Future<bool> addToFavorites(String productId) async {
    try {
      final result =
          await _api.post<dynamic>(ApiConfig.favoriteToggle(productId));
      return result.success;
    } catch (error) {
      debugPrint('[UserDataRepository] addToFavorites failed: $error');
      return false;
    }
  }

  Future<bool> removeFromFavorites(String productId) async {
    try {
      final result =
          await _api.delete<dynamic>(ApiConfig.favoriteToggle(productId));
      return result.success;
    } catch (error) {
      debugPrint('[UserDataRepository] removeFromFavorites failed: $error');
      return false;
    }
  }

  Future<bool> isFavorite(String productId) async {
    try {
      final result =
          await _api.get<dynamic>(ApiConfig.favoriteToggle(productId));
      if (!result.success || result.data == null) return false;
      return jsonAsBool(jsonAsMap(result.data)['is_favorite']);
    } catch (error) {
      debugPrint('[UserDataRepository] isFavorite failed: $error');
      return false;
    }
  }

  Future<List<String>> getBrowseHistory({int limit = 50}) async {
    try {
      final result = await _api.get<dynamic>(
        '${ApiConfig.userProfile}/browse-history',
        params: {'limit': limit},
      );
      if (!result.success || result.data == null) return const [];
      return extractEnvelopeItems(result.data)
          .map((id) => jsonAsString(id))
          .toList(growable: false);
    } catch (error) {
      debugPrint('[UserDataRepository] getBrowseHistory failed: $error');
      return const [];
    }
  }

  Future<List<BrowseHistoryItem>> getBrowseHistoryWithDetails({
    int limit = 50,
  }) async {
    try {
      final result = await _api.get<dynamic>(
        '${ApiConfig.userProfile}/browse-history/details',
        params: {'limit': limit},
      );
      if (!result.success || result.data == null) return const [];
      return parseBrowseHistoryItems(result.data);
    } catch (error) {
      debugPrint(
          '[UserDataRepository] getBrowseHistoryWithDetails failed: $error');
      return const [];
    }
  }

  Future<bool> addToBrowseHistory(String productId) async {
    try {
      final result = await _api.post<dynamic>(
        '${ApiConfig.userProfile}/browse-history',
        data: {'product_id': productId},
      );
      return result.success;
    } catch (error) {
      debugPrint('[UserDataRepository] addToBrowseHistory failed: $error');
      return false;
    }
  }

  Future<bool> clearBrowseHistory() async {
    try {
      final result = await _api.delete<dynamic>(
        '${ApiConfig.userProfile}/browse-history',
      );
      return result.success;
    } catch (error) {
      debugPrint('[UserDataRepository] clearBrowseHistory failed: $error');
      return false;
    }
  }

  Future<List<String>> getSearchHistory({int limit = 20}) async {
    try {
      final result = await _api.get<dynamic>(
        '${ApiConfig.userProfile}/search-history',
        params: {'limit': limit},
      );
      if (!result.success || result.data == null) return const [];
      return extractEnvelopeItems(result.data)
          .map((query) => jsonAsString(query))
          .toList(growable: false);
    } catch (error) {
      debugPrint('[UserDataRepository] getSearchHistory failed: $error');
      return const [];
    }
  }

  Future<bool> addSearchHistory(String query) async {
    try {
      final result = await _api.post<dynamic>(
        '${ApiConfig.userProfile}/search-history',
        data: {'query': query},
      );
      return result.success;
    } catch (error) {
      debugPrint('[UserDataRepository] addSearchHistory failed: $error');
      return false;
    }
  }

  Future<bool> clearSearchHistory() async {
    try {
      final result = await _api.delete<dynamic>(
        '${ApiConfig.userProfile}/search-history',
      );
      return result.success;
    } catch (error) {
      debugPrint('[UserDataRepository] clearSearchHistory failed: $error');
      return false;
    }
  }

  Future<bool> removeSearchHistoryItem(String query) async {
    try {
      final result = await _api.delete<dynamic>(
        '${ApiConfig.userProfile}/search-history',
        data: {'query': query},
      );
      return result.success;
    } catch (error) {
      debugPrint('[UserDataRepository] removeSearchHistoryItem failed: $error');
      return false;
    }
  }
}
