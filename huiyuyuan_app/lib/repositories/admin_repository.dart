library;

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/admin_models.dart';
import '../models/json_parsing.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';

class AdminRepository {
  AdminRepository({
    ApiService? apiService,
    ProductService? productService,
  })  : _api = apiService ?? ApiService(),
        _productService = productService ?? ProductService();

  final ApiService _api;
  final ProductService _productService;

  Future<void> initialize() async {
    await Future.wait([
      _api.initialize(),
      _productService.initialize(),
    ]);
  }

  Future<DashboardStats?> getDashboardStats() async {
    try {
      final result = await _api.get<dynamic>(ApiConfig.adminStats);
      final data = _extractMap(result);
      return data == null ? null : DashboardStats.fromJson(data);
    } catch (error) {
      debugPrint('[AdminRepository] getDashboardStats failed: $error');
      return null;
    }
  }

  Future<List<RestockSuggestion>> getRestockSuggestions() async {
    try {
      final products = await _productService.getProducts(
        page: 1,
        pageSize: 200,
      );
      final suggestions = products
          .where((product) => product.stock <= 20)
          .map(_buildRestockSuggestion)
          .toList(growable: false)
        ..sort((left, right) {
          final urgencyCompare = _restockUrgencyRank(left.urgency) -
              _restockUrgencyRank(right.urgency);
          if (urgencyCompare != 0) {
            return urgencyCompare;
          }
          return left.currentStock.compareTo(right.currentStock);
        });
      return suggestions;
    } catch (error) {
      debugPrint('[AdminRepository] getRestockSuggestions failed: $error');
      return const [];
    }
  }

  Future<List<ActivityItem>> getRecentActivities({String? filter}) async {
    try {
      final result = await _api.get<dynamic>(
        ApiConfig.adminActivities,
        params: {
          if (filter != null && filter != AdminActivityTags.all)
            'filter': filter,
        },
      );
      return _extractList(result, ActivityItem.fromJson);
    } catch (error) {
      debugPrint('[AdminRepository] getRecentActivities failed: $error');
      return const [];
    }
  }

  Future<List<ProductModel>> getProducts({
    String? category,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) {
    return _productService.getProducts(
      category: category,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<ProductModel?> createProduct(ProductUpsertRequest request) {
    return _productService.createProduct(request);
  }

  Future<ProductModel?> updateProduct(
    String productId,
    ProductUpsertRequest request,
  ) {
    return _productService.updateProduct(productId, request);
  }

  Future<bool> deleteProduct(String productId) {
    return _productService.deleteProduct(productId);
  }

  Future<List<OperatorAccount>> getOperatorAccounts() async {
    try {
      final result = await _api.get<dynamic>(ApiConfig.adminOperators);
      return _extractList(result, OperatorAccount.fromJson);
    } catch (error) {
      debugPrint('[AdminRepository] getOperatorAccounts failed: $error');
      return const [];
    }
  }

  Future<OperatorAccount?> updateOperatorAccount(
    String operatorId,
    OperatorAccountUpdateRequest request,
  ) async {
    try {
      final result = await _api.put<dynamic>(
        ApiConfig.adminOperator(operatorId),
        data: request.toJson(),
      );
      final data = _extractMap(result);
      if (data == null) {
        return null;
      }
      final operator = data['operator'];
      if (operator is Map || operator is Map<String, dynamic>) {
        return OperatorAccount.fromJson(jsonAsMap(operator));
      }
      return OperatorAccount.fromJson(data);
    } catch (error) {
      debugPrint('[AdminRepository] updateOperatorAccount failed: $error');
      return null;
    }
  }

  Future<OperatorReport?> getOperatorReport(int operatorId) async {
    try {
      final result = await _api.get<dynamic>(
        ApiConfig.adminOperatorReport(operatorId),
      );
      final data = _extractMap(result);
      return data == null ? null : OperatorReport.fromJson(data);
    } catch (error) {
      debugPrint('[AdminRepository] getOperatorReport failed: $error');
      return null;
    }
  }

  Future<List<OperatorReport>> getAllOperatorReports() async {
    try {
      final result = await _api.get<dynamic>(ApiConfig.adminOperatorReports);
      return _extractList(result, OperatorReport.fromJson);
    } catch (error) {
      debugPrint('[AdminRepository] getAllOperatorReports failed: $error');
      return const [];
    }
  }

  Future<SystemStatusSnapshot?> getSystemStatus() async {
    try {
      final result = await _api.get<dynamic>(ApiConfig.adminSystemStatus);
      final data = _extractMap(result);
      return data == null ? null : SystemStatusSnapshot.fromJson(data);
    } catch (error) {
      debugPrint('[AdminRepository] getSystemStatus failed: $error');
      return null;
    }
  }

  Future<ProductImageUploadResult?> uploadProductImage(
    String productId,
    String imagePath,
  ) async {
    try {
      final fileName = imagePath.split('/').last.split('\\').last;
      final result = await _api.upload<dynamic>(
        '${ApiConfig.productDetail(productId)}/image',
        filePath: imagePath,
        fileName: fileName,
        fieldName: 'image',
      );
      if (!result.success) {
        return null;
      }

      final data = _extractMap(result);
      return ProductImageUploadResult.fromJson({
        'success': result.success,
        'message': result.message,
        if (data != null) ...data,
        if (data == null) 'file_name': fileName,
      });
    } catch (error) {
      debugPrint('[AdminRepository] uploadProductImage failed: $error');
      return null;
    }
  }

  RestockSuggestion _buildRestockSuggestion(ProductModel product) {
    final urgency = _restockUrgency(product);
    final targetStock = switch (urgency) {
      'critical' => product.isHot ? 80 : 50,
      'high' => product.isHot ? 60 : 40,
      _ => product.isHot ? 40 : 30,
    };

    return RestockSuggestion(
      productId: product.id,
      productName: product.name,
      currentStock: product.stock,
      suggestedQuantity: (targetStock - product.stock).clamp(1, 100),
      urgency: urgency,
      price: product.price,
    );
  }

  String _restockUrgency(ProductModel product) {
    if (product.stock <= 5) {
      return 'critical';
    }
    if (product.stock <= 10) {
      return 'high';
    }
    return 'medium';
  }

  int _restockUrgencyRank(String urgency) {
    return switch (urgency) {
      'critical' => 0,
      'high' => 1,
      _ => 2,
    };
  }

  Map<String, dynamic>? _extractMap(ApiResult<dynamic> result) {
    if (!result.success || result.data == null) {
      return null;
    }

    final raw = result.data;
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'] ?? raw['item'] ?? raw['result'];
      if (nested is Map || nested is Map<String, dynamic>) {
        return jsonAsMap(nested);
      }
      return raw;
    }
    if (raw is Map) {
      final map = jsonAsMap(raw);
      final nested = map['data'] ?? map['item'] ?? map['result'];
      if (nested is Map || nested is Map<String, dynamic>) {
        return jsonAsMap(nested);
      }
      return map;
    }
    return null;
  }

  List<T> _extractList<T>(
    ApiResult<dynamic> result,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (!result.success || result.data == null) {
      return const [];
    }

    final raw = result.data;
    if (raw is Iterable) {
      return raw.map((item) => parser(jsonAsMap(item))).toList(growable: false);
    }

    final map = jsonAsMap(raw);
    final candidates = <dynamic>[map['items'], map['data'], map['results']];
    for (final candidate in candidates) {
      if (candidate is Iterable) {
        return candidate
            .map((item) => parser(jsonAsMap(item)))
            .toList(growable: false);
      }
    }

    return const [];
  }
}
