library;

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class DashboardStats {
  final int totalOrders;
  final double totalAmount;
  final int pendingOrders;
  final int shippedOrders;
  final int totalProducts;
  final int lowStockProducts;
  final int totalCustomers;

  DashboardStats({
    required this.totalOrders,
    required this.totalAmount,
    required this.pendingOrders,
    required this.shippedOrders,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalCustomers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: json['total_orders'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      pendingOrders: json['pending_orders'] as int? ?? 0,
      shippedOrders: json['shipped_orders'] as int? ?? 0,
      totalProducts: json['total_products'] as int? ?? 0,
      lowStockProducts: json['low_stock_products'] as int? ?? 0,
      totalCustomers: json['total_customers'] as int? ?? 0,
    );
  }
}

class RestockSuggestion {
  final String productId;
  final String productName;
  final int currentStock;
  final int suggestedQuantity;
  final String urgency;
  final double price;

  RestockSuggestion({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.suggestedQuantity,
    required this.urgency,
    required this.price,
  });

  factory RestockSuggestion.fromJson(Map<String, dynamic> json) {
    return RestockSuggestion(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      currentStock: json['current_stock'] as int? ?? 0,
      suggestedQuantity: json['suggested_quantity'] as int? ?? 0,
      urgency: json['urgency'] as String? ?? 'medium',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ActivityItem {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final String time;
  final String color;
  final String icon;

  ActivityItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.icon,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      time: json['time'] as String? ?? '',
      color: json['color'] as String? ?? '#06B6D4',
      icon: json['icon'] as String? ?? 'info',
    );
  }
}

class OperatorReport {
  final int operatorId;
  final String operatorName;
  final int contactShops;
  final int intentionCount;
  final int successCount;
  final int aiUsageCount;
  final double orderAmount;

  OperatorReport({
    required this.operatorId,
    required this.operatorName,
    required this.contactShops,
    required this.intentionCount,
    required this.successCount,
    required this.aiUsageCount,
    required this.orderAmount,
  });

  factory OperatorReport.fromJson(Map<String, dynamic> json) {
    return OperatorReport(
      operatorId: json['operator_id'] as int? ?? 0,
      operatorName: json['operator_name'] as String? ?? '',
      contactShops: json['contact_shops'] as int? ?? 0,
      intentionCount: json['intention_count'] as int? ?? 0,
      successCount: json['success_count'] as int? ?? 0,
      aiUsageCount: json['ai_usage_count'] as int? ?? 0,
      orderAmount: (json['order_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final ApiService _api = ApiService();

  Future<void> initialize() async {
    await _api.initialize();
  }

  Future<DashboardStats?> getDashboardStats() async {
    try {
      final result =
          await _api.get<Map<String, dynamic>>(ApiConfig.adminStats);
      if (result.success && result.data != null) {
        return DashboardStats.fromJson(result.data!);
      }
      return null;
    } catch (e) {
      debugPrint('[AdminService] 获取仪表盘统计失败: $e');
      return null;
    }
  }

  Future<List<RestockSuggestion>> getRestockSuggestions() async {
    try {
      final result = await _api.get<List<dynamic>>(
        ApiConfig.adminRestockSuggestions,
      );
      if (result.success && result.data != null) {
        return result.data!
            .map((json) => RestockSuggestion.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AdminService] 获取补货建议失败: $e');
      return [];
    }
  }

  Future<List<ActivityItem>> getRecentActivities({String? filter}) async {
    try {
      final result = await _api.get<List<dynamic>>(
        ApiConfig.adminActivities,
        params: {
          if (filter != null && filter != '全部') 'filter': filter,
        },
      );
      if (result.success && result.data != null) {
        return result.data!
            .map((json) => ActivityItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AdminService] 获取最近活动失败: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getProducts({
    String? category,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final result = await _api.get<List<dynamic>>(
        ApiConfig.products,
        params: {
          if (category != null && category != '全部') 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
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
      debugPrint('[AdminService] 获取商品列表失败: $e');
      return [];
    }
  }

  Future<ProductModel?> createProduct(Map<String, dynamic> productData) async {
    try {
      final result = await _api.post<Map<String, dynamic>>(
        ApiConfig.products,
        data: productData,
      );
      if (result.success && result.data != null) {
        return ProductModel.fromJson(result.data!);
      }
      return null;
    } catch (e) {
      debugPrint('[AdminService] 创建商品失败: $e');
      return null;
    }
  }

  Future<ProductModel?> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      final result = await _api.put<Map<String, dynamic>>(
        ApiConfig.productDetail(productId),
        data: productData,
      );
      if (result.success && result.data != null) {
        return ProductModel.fromJson(result.data!);
      }
      return null;
    } catch (e) {
      debugPrint('[AdminService] 更新商品失败: $e');
      return null;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final result = await _api.delete(ApiConfig.productDetail(productId));
      return result.success;
    } catch (e) {
      debugPrint('[AdminService] 删除商品失败: $e');
      return false;
    }
  }

  Future<OperatorReport?> getOperatorReport(int operatorId) async {
    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConfig.adminOperatorReport(operatorId),
      );
      if (result.success && result.data != null) {
        return OperatorReport.fromJson(result.data!);
      }
      return null;
    } catch (e) {
      debugPrint('[AdminService] 获取操作员报告失败: $e');
      return null;
    }
  }

  Future<List<OperatorReport>> getAllOperatorReports() async {
    try {
      final result = await _api.get<List<dynamic>>(
        ApiConfig.adminOperatorReports,
      );
      if (result.success && result.data != null) {
        return result.data!
            .map((json) => OperatorReport.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AdminService] 获取所有操作员报告失败: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSystemStatus() async {
    try {
      final result = await _api.get<Map<String, dynamic>>(
        '/api/admin/system/status',
      );
      if (result.success && result.data != null) {
        return result.data!;
      }
      return null;
    } catch (e) {
      debugPrint('[AdminService] 获取系统状态失败: $e');
      return null;
    }
  }

  Future<bool> uploadProductImage(String productId, String imagePath) async {
    try {
      final fileName = imagePath.split('/').last.split('\\').last;
      final result = await _api.upload<Map<String, dynamic>>(
        '${ApiConfig.productDetail(productId)}/image',
        filePath: imagePath,
        fileName: fileName,
        fieldName: 'image',
      );
      return result.success;
    } catch (e) {
      debugPrint('[AdminService] 上传商品图片失败: $e');
      return false;
    }
  }
}
