library;

export 'product_upsert_request.dart';

import 'json_parsing.dart';

abstract final class AdminActivityTags {
  static const String all = 'order_all';
  static const String orders = 'admin_tag_orders';
  static const String stock = 'product_stock';
  static const String system = 'admin_tag_system';
  static const String ai = 'admin_tag_ai';

  static const Set<String> localizedKeys = {
    orders,
    stock,
    system,
    ai,
  };
}

const Set<String> _orderActivityRawTags = {
  '支付',
  '物流',
  '完成',
};

class DashboardStats {
  final int totalOrders;
  final double totalAmount;
  final int todayOrders;
  final double todayRevenue;
  final int pendingOrders;
  final int shippedOrders;
  final int pendingRefund;
  final int totalProducts;
  final int lowStockProducts;
  final int totalCustomers;

  const DashboardStats({
    required this.totalOrders,
    required this.totalAmount,
    required this.todayOrders,
    required this.todayRevenue,
    required this.pendingOrders,
    required this.shippedOrders,
    required this.pendingRefund,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalCustomers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: jsonAsInt(json['total_orders']),
      totalAmount: json.containsKey('total_amount')
          ? jsonAsDouble(json['total_amount'])
          : jsonAsDouble(json['total_revenue']),
      todayOrders: jsonAsInt(json['today_orders']),
      todayRevenue: jsonAsDouble(json['today_revenue']),
      pendingOrders: json.containsKey('pending_orders')
          ? jsonAsInt(json['pending_orders'])
          : jsonAsInt(json['pending_ship']),
      shippedOrders: jsonAsInt(json['shipped_orders']),
      pendingRefund: jsonAsInt(json['pending_refund']),
      totalProducts: jsonAsInt(json['total_products']),
      lowStockProducts: json.containsKey('low_stock_products')
          ? jsonAsInt(json['low_stock_products'])
          : jsonAsInt(json['low_stock_items']),
      totalCustomers: jsonAsInt(json['total_customers']),
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

  const RestockSuggestion({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.suggestedQuantity,
    required this.urgency,
    required this.price,
  });

  factory RestockSuggestion.fromJson(Map<String, dynamic> json) {
    return RestockSuggestion(
      productId: jsonAsString(json['product_id']),
      productName: jsonAsString(json['product_name']),
      currentStock: jsonAsInt(json['current_stock']),
      suggestedQuantity: jsonAsInt(json['suggested_quantity']),
      urgency: jsonAsString(json['urgency'], fallback: 'medium'),
      price: jsonAsDouble(json['price']),
    );
  }
}

class ActivityItem {
  final String id;
  final String tag;
  final String? tagKey;
  final String title;
  final String? titleKey;
  final Map<String, Object?>? titleArgs;
  final String subtitle;
  final String? subtitleKey;
  final Map<String, Object?>? subtitleArgs;
  final String time;
  final String color;
  final String icon;

  const ActivityItem({
    required this.id,
    required this.tag,
    this.tagKey,
    required this.title,
    this.titleKey,
    this.titleArgs,
    required this.subtitle,
    this.subtitleKey,
    this.subtitleArgs,
    required this.time,
    required this.color,
    required this.icon,
  });

  String get resolvedTagKey => tagKey ?? tag;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final type = jsonAsString(json['type']);
    final rawTag = jsonAsString(json['tag']);
    final time = jsonAsString(json['time']);
    final fallbackId = type.isEmpty && time.isEmpty
        ? ''
        : '${type.isEmpty ? 'activity' : type}-$time';
    return ActivityItem(
      id: jsonAsString(
        json['id'],
        fallback: fallbackId,
      ),
      tag: rawTag,
      tagKey: jsonAsNullableString(json['tag_key']) ??
          _normalizeActivityTag(
            rawTag: rawTag,
            type: type,
          ),
      title: jsonAsString(json['title']),
      titleKey: jsonAsNullableString(json['title_key']),
      titleArgs: _jsonArgsMap(json['title_args']),
      subtitle: jsonAsString(json['subtitle']),
      subtitleKey: jsonAsNullableString(json['subtitle_key']),
      subtitleArgs: _jsonArgsMap(json['subtitle_args']),
      time: time,
      color: jsonAsString(json['color'], fallback: _activityColor(type)),
      icon: jsonAsString(json['icon'], fallback: _activityIcon(type)),
    );
  }
}

String _normalizeActivityTag({
  required String rawTag,
  required String type,
}) {
  final normalizedFromType = switch (type) {
    'order_new' ||
    'order_paid' ||
    'order_shipped' ||
    'order_completed' ||
    'order_refund' =>
      AdminActivityTags.orders,
    'stock_warning' => AdminActivityTags.stock,
    'system' => AdminActivityTags.system,
    'ai' || 'ai_reply' || 'ai_task' => AdminActivityTags.ai,
    _ => '',
  };

  if (normalizedFromType.isNotEmpty) {
    return normalizedFromType;
  }

  if (_orderActivityRawTags.contains(rawTag)) {
    return AdminActivityTags.orders;
  }

  return rawTag;
}

Map<String, Object?>? _jsonArgsMap(dynamic value) {
  final map = jsonAsNullableMap(value);
  return map?.map((key, item) => MapEntry(key, item));
}

String _activityColor(String type) {
  return switch (type) {
    'order_new' => '#10B981',
    'order_paid' => '#06B6D4',
    'order_shipped' => '#8B5CF6',
    'order_completed' => '#22C55E',
    'order_refund' || 'stock_warning' => '#F59E0B',
    'system' => '#6366F1',
    'ai' || 'ai_reply' || 'ai_task' => '#14B8A6',
    _ => '#06B6D4',
  };
}

String _activityIcon(String type) {
  return switch (type) {
    'order_new' => 'shopping_bag',
    'order_paid' => 'payment',
    'order_shipped' => 'local_shipping',
    'order_completed' => 'check_circle',
    'order_refund' || 'stock_warning' => 'warning',
    'system' => 'monitor_heart',
    _ => 'info',
  };
}

class OperatorReport {
  final String operatorUserId;
  final int operatorId;
  final String operatorName;
  final int contactShops;
  final int intentionCount;
  final int successCount;
  final int aiUsageCount;
  final double orderAmount;

  const OperatorReport({
    this.operatorUserId = '',
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
      operatorUserId: jsonAsString(json['operator_user_id']),
      operatorId: jsonAsInt(json['operator_id']),
      operatorName: jsonAsString(json['operator_name']),
      contactShops: jsonAsInt(json['contact_shops']),
      intentionCount: jsonAsInt(json['intention_count']),
      successCount: jsonAsInt(json['success_count']),
      aiUsageCount: jsonAsInt(json['ai_usage_count']),
      orderAmount: jsonAsDouble(json['order_amount']),
    );
  }
}

class OperatorAccount {
  final String id;
  final String username;
  final String? phone;
  final int? operatorNumber;
  final bool isActive;
  final List<String> permissions;
  final OperatorReport? report;

  const OperatorAccount({
    required this.id,
    required this.username,
    this.phone,
    this.operatorNumber,
    this.isActive = true,
    this.permissions = const <String>[],
    this.report,
  });

  factory OperatorAccount.fromJson(Map<String, dynamic> json) {
    final reportMap = jsonAsNullableMap(json['report']);
    return OperatorAccount(
      id: jsonAsString(json['id']),
      username: jsonAsString(json['username']),
      phone: jsonAsNullableString(json['phone']),
      operatorNumber: jsonAsNullableInt(json['operator_number']),
      isActive: jsonAsBool(json['is_active'], fallback: true),
      permissions: jsonAsStringList(json['permissions']),
      report: reportMap == null ? null : OperatorReport.fromJson(reportMap),
    );
  }

  OperatorAccount copyWith({
    String? username,
    String? phone,
    int? operatorNumber,
    bool? isActive,
    List<String>? permissions,
    OperatorReport? report,
  }) {
    return OperatorAccount(
      id: id,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      operatorNumber: operatorNumber ?? this.operatorNumber,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
      report: report ?? this.report,
    );
  }
}

class OperatorAccountUpdateRequest {
  const OperatorAccountUpdateRequest({
    this.username,
    this.phone,
    this.isActive,
    this.password,
    this.permissions,
  });

  final String? username;
  final String? phone;
  final bool? isActive;
  final String? password;
  final List<String>? permissions;

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (phone != null) 'phone': phone,
      if (isActive != null) 'is_active': isActive,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (permissions != null) 'permissions': permissions,
    };
  }
}

enum HealthLevel { healthy, degraded, unhealthy, unknown }

HealthLevel healthLevelFromValue(dynamic value) {
  if (value is bool) {
    return value ? HealthLevel.healthy : HealthLevel.unhealthy;
  }

  final raw = jsonAsNullableString(value)?.toLowerCase();
  switch (raw) {
    case 'healthy':
    case 'ok':
    case 'up':
    case 'running':
    case 'success':
      return HealthLevel.healthy;
    case 'warning':
    case 'degraded':
    case 'partial':
      return HealthLevel.degraded;
    case 'unhealthy':
    case 'error':
    case 'failed':
    case 'down':
      return HealthLevel.unhealthy;
    default:
      return HealthLevel.unknown;
  }
}

class SystemServiceStatus {
  final String name;
  final HealthLevel level;
  final String? message;

  const SystemServiceStatus({
    required this.name,
    required this.level,
    this.message,
  });

  bool get isHealthy => level == HealthLevel.healthy;

  factory SystemServiceStatus.fromJson(Map<String, dynamic> json) {
    return SystemServiceStatus(
      name: jsonAsString(json['name']),
      level: healthLevelFromValue(
        json['status'] ?? json['level'] ?? json['healthy'],
      ),
      message: jsonAsNullableString(
        json['message'] ?? json['detail'] ?? json['description'],
      ),
    );
  }

  factory SystemServiceStatus.fromEntry(String name, dynamic value) {
    if (value is Map || value is Map<String, dynamic>) {
      final map = jsonAsMap(value);
      return SystemServiceStatus(
        name: name,
        level: healthLevelFromValue(
          map['status'] ?? map['level'] ?? map['healthy'],
        ),
        message: jsonAsNullableString(
          map['message'] ?? map['detail'] ?? map['description'],
        ),
      );
    }

    return SystemServiceStatus(
      name: name,
      level: healthLevelFromValue(value),
      message: value is String ? value : null,
    );
  }
}

class SystemMetric {
  final String name;
  final String value;
  final String? unit;

  const SystemMetric({
    required this.name,
    required this.value,
    this.unit,
  });

  factory SystemMetric.fromJson(Map<String, dynamic> json) {
    return SystemMetric(
      name: jsonAsString(json['name']),
      value: jsonAsString(json['value']),
      unit: jsonAsNullableString(json['unit']),
    );
  }

  factory SystemMetric.fromEntry(String name, dynamic value) {
    if (value is Map || value is Map<String, dynamic>) {
      final map = jsonAsMap(value);
      return SystemMetric(
        name: name,
        value: jsonAsString(map['value']),
        unit: jsonAsNullableString(map['unit']),
      );
    }

    return SystemMetric(
      name: name,
      value: jsonAsString(value),
    );
  }
}

class SystemStatusSnapshot {
  final HealthLevel level;
  final String? message;
  final DateTime? checkedAt;
  final List<SystemServiceStatus> services;
  final List<SystemMetric> metrics;
  final List<String> warnings;

  const SystemStatusSnapshot({
    required this.level,
    this.message,
    this.checkedAt,
    this.services = const [],
    this.metrics = const [],
    this.warnings = const [],
  });

  factory SystemStatusSnapshot.fromJson(Map<String, dynamic> json) {
    final services = _parseServices(json);
    final metrics = _parseMetrics(json);
    return SystemStatusSnapshot(
      level: healthLevelFromValue(
        json['status'] ?? json['overall_status'] ?? json['health'],
      ),
      message: jsonAsNullableString(json['message']),
      checkedAt: jsonAsNullableDateTime(
        json['checked_at'] ?? json['timestamp'] ?? json['updated_at'],
      ),
      services: services,
      metrics: metrics,
      warnings: jsonAsStringList(json['warnings']),
    );
  }

  static List<SystemServiceStatus> _parseServices(Map<String, dynamic> json) {
    final explicitServices = json['services'] ?? json['components'];
    if (explicitServices is Iterable) {
      return explicitServices
          .map((item) => SystemServiceStatus.fromJson(jsonAsMap(item)))
          .toList(growable: false);
    }

    if (explicitServices is Map || explicitServices is Map<String, dynamic>) {
      return jsonAsMap(explicitServices)
          .entries
          .map((entry) => SystemServiceStatus.fromEntry(entry.key, entry.value))
          .toList(growable: false);
    }

    const reservedKeys = {
      'status',
      'overall_status',
      'health',
      'message',
      'checked_at',
      'timestamp',
      'updated_at',
      'metrics',
      'warnings',
      'cpu_usage',
      'memory_usage',
      'disk_usage',
      'uptime',
      'uptime_seconds',
    };

    final services = <SystemServiceStatus>[];
    for (final entry in json.entries) {
      if (reservedKeys.contains(entry.key)) {
        continue;
      }
      final value = entry.value;
      if (value is bool ||
          value is String ||
          value is Map ||
          value is Map<String, dynamic>) {
        services.add(SystemServiceStatus.fromEntry(entry.key, value));
      }
    }
    return services;
  }

  static List<SystemMetric> _parseMetrics(Map<String, dynamic> json) {
    final explicitMetrics = json['metrics'];
    if (explicitMetrics is Iterable) {
      return explicitMetrics
          .map((item) => SystemMetric.fromJson(jsonAsMap(item)))
          .toList(growable: false);
    }

    if (explicitMetrics is Map || explicitMetrics is Map<String, dynamic>) {
      return jsonAsMap(explicitMetrics)
          .entries
          .map((entry) => SystemMetric.fromEntry(entry.key, entry.value))
          .toList(growable: false);
    }

    final metrics = <SystemMetric>[];
    const metricKeys = {
      'cpu_usage': '%',
      'memory_usage': '%',
      'disk_usage': '%',
      'uptime_seconds': 's',
      'uptime': null,
    };

    for (final entry in metricKeys.entries) {
      if (json.containsKey(entry.key)) {
        metrics.add(
          SystemMetric(
            name: entry.key,
            value: jsonAsString(json[entry.key]),
            unit: entry.value,
          ),
        );
      }
    }

    return metrics;
  }
}

class ProductImageUploadResult {
  final bool success;
  final String? imageUrl;
  final String? fileName;
  final String? message;

  const ProductImageUploadResult({
    required this.success,
    this.imageUrl,
    this.fileName,
    this.message,
  });

  factory ProductImageUploadResult.fromJson(Map<String, dynamic> json) {
    return ProductImageUploadResult(
      success: jsonAsBool(json['success'], fallback: true),
      imageUrl: jsonAsNullableString(
        json['image_url'] ??
            json['url'] ??
            json['file_url'] ??
            json['path'] ??
            json['location'],
      ),
      fileName: jsonAsNullableString(
        json['file_name'] ?? json['filename'] ?? json['name'],
      ),
      message: jsonAsNullableString(json['message']),
    );
  }
}
