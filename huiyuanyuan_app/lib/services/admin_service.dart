library;

export '../models/admin_models.dart';

import '../models/admin_models.dart';
import '../models/product_model.dart';
import '../repositories/admin_repository.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();

  factory AdminService() => _instance;

  AdminService._internal() : _repository = AdminRepository();

  final AdminRepository _repository;

  Future<void> initialize() async {
    await _repository.initialize();
  }

  Future<DashboardStats?> getDashboardStats() {
    return _repository.getDashboardStats();
  }

  Future<List<RestockSuggestion>> getRestockSuggestions() {
    return _repository.getRestockSuggestions();
  }

  Future<List<ActivityItem>> getRecentActivities({String? filter}) {
    return _repository.getRecentActivities(filter: filter);
  }

  Future<List<ProductModel>> getProducts({
    String? category,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) {
    return _repository.getProducts(
      category: category,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<ProductModel?> createProduct(ProductUpsertRequest request) {
    return _repository.createProduct(request);
  }

  Future<ProductModel?> updateProduct(
    String productId,
    ProductUpsertRequest request,
  ) {
    return _repository.updateProduct(productId, request);
  }

  Future<bool> deleteProduct(String productId) {
    return _repository.deleteProduct(productId);
  }

  Future<OperatorReport?> getOperatorReport(int operatorId) {
    return _repository.getOperatorReport(operatorId);
  }

  Future<List<OperatorReport>> getAllOperatorReports() {
    return _repository.getAllOperatorReports();
  }

  Future<SystemStatusSnapshot?> getSystemStatus() {
    return _repository.getSystemStatus();
  }

  Future<ProductImageUploadResult?> uploadProductImage(
    String productId,
    String imagePath,
  ) {
    return _repository.uploadProductImage(productId, imagePath);
  }
}
