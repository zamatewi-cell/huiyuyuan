library;

import '../models/product_model.dart';
import '../models/user_data_models.dart';
import '../repositories/user_data_repository.dart';

class UserDataService {
  static final UserDataService _instance = UserDataService._internal();

  factory UserDataService() => _instance;

  UserDataService._internal() : _repository = UserDataRepository();

  final UserDataRepository _repository;

  Future<void> initialize() async {
    await _repository.initialize();
  }

  Future<List<ProductModel>> getFavorites() {
    return _repository.getFavorites();
  }

  Future<bool> addToFavorites(String productId) {
    return _repository.addToFavorites(productId);
  }

  Future<bool> removeFromFavorites(String productId) {
    return _repository.removeFromFavorites(productId);
  }

  Future<bool> isFavorite(String productId) {
    return _repository.isFavorite(productId);
  }

  Future<List<String>> getBrowseHistory({int limit = 50}) {
    return _repository.getBrowseHistory(limit: limit);
  }

  Future<List<BrowseHistoryItem>> getBrowseHistoryWithDetails(
      {int limit = 50}) {
    return _repository.getBrowseHistoryWithDetails(limit: limit);
  }

  Future<bool> addToBrowseHistory(String productId) {
    return _repository.addToBrowseHistory(productId);
  }

  Future<bool> clearBrowseHistory() {
    return _repository.clearBrowseHistory();
  }

  Future<List<String>> getSearchHistory({int limit = 20}) {
    return _repository.getSearchHistory(limit: limit);
  }

  Future<bool> addSearchHistory(String query) {
    return _repository.addSearchHistory(query);
  }

  Future<bool> clearSearchHistory() {
    return _repository.clearSearchHistory();
  }

  Future<bool> removeSearchHistoryItem(String query) {
    return _repository.removeSearchHistoryItem(query);
  }
}
