library;

import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/services/admin_service.dart';

void main() {
  group('DashboardStats', () {
    test('parses full json payload', () {
      final stats = DashboardStats.fromJson({
        'total_orders': 100,
        'total_amount': 50000.0,
        'pending_orders': 10,
        'shipped_orders': 80,
        'total_products': 50,
        'low_stock_products': 5,
        'total_customers': 200,
      });

      expect(stats.totalOrders, 100);
      expect(stats.totalAmount, 50000.0);
      expect(stats.pendingOrders, 10);
      expect(stats.shippedOrders, 80);
      expect(stats.totalProducts, 50);
      expect(stats.lowStockProducts, 5);
      expect(stats.totalCustomers, 200);
    });

    test('falls back to defaults for missing fields', () {
      final stats = DashboardStats.fromJson(<String, dynamic>{});

      expect(stats.totalOrders, 0);
      expect(stats.totalAmount, 0.0);
      expect(stats.pendingOrders, 0);
      expect(stats.shippedOrders, 0);
      expect(stats.totalProducts, 0);
      expect(stats.lowStockProducts, 0);
      expect(stats.totalCustomers, 0);
    });

    test('accepts current backend dashboard payload aliases', () {
      final stats = DashboardStats.fromJson({
        'total_orders': 18,
        'total_revenue': 12888.5,
        'pending_ship': 3,
        'total_products': 96,
        'low_stock_items': 7,
      });

      expect(stats.totalOrders, 18);
      expect(stats.totalAmount, 12888.5);
      expect(stats.pendingOrders, 3);
      expect(stats.totalProducts, 96);
      expect(stats.lowStockProducts, 7);
      expect(stats.shippedOrders, 0);
    });
  });

  group('RestockSuggestion', () {
    test('parses full json payload', () {
      final suggestion = RestockSuggestion.fromJson({
        'product_id': 'prod_001',
        'product_name': 'Hetian bracelet',
        'current_stock': 3,
        'suggested_quantity': 20,
        'urgency': 'high',
        'price': 9999.0,
      });

      expect(suggestion.productId, 'prod_001');
      expect(suggestion.productName, 'Hetian bracelet');
      expect(suggestion.currentStock, 3);
      expect(suggestion.suggestedQuantity, 20);
      expect(suggestion.urgency, 'high');
      expect(suggestion.price, 9999.0);
    });

    test('falls back to defaults for missing fields', () {
      final suggestion = RestockSuggestion.fromJson(<String, dynamic>{});

      expect(suggestion.productId, '');
      expect(suggestion.productName, '');
      expect(suggestion.currentStock, 0);
      expect(suggestion.suggestedQuantity, 0);
      expect(suggestion.urgency, 'medium');
      expect(suggestion.price, 0.0);
    });
  });

  group('ActivityItem', () {
    test('parses full json payload', () {
      final activity = ActivityItem.fromJson({
        'id': 'act_001',
        'tag': 'order',
        'title': 'New order',
        'subtitle': 'Customer created an order',
        'time': 'just now',
        'color': '#10B981',
        'icon': 'shopping_bag',
      });

      expect(activity.id, 'act_001');
      expect(activity.tag, 'order');
      expect(activity.title, 'New order');
      expect(activity.subtitle, 'Customer created an order');
      expect(activity.time, 'just now');
      expect(activity.color, '#10B981');
      expect(activity.icon, 'shopping_bag');
    });

    test('falls back to defaults for missing fields', () {
      final activity = ActivityItem.fromJson(<String, dynamic>{});

      expect(activity.id, '');
      expect(activity.tag, '');
      expect(activity.title, '');
      expect(activity.subtitle, '');
      expect(activity.time, '');
      expect(activity.color, '#06B6D4');
      expect(activity.icon, 'info');
    });

    test('normalizes current backend activity payloads', () {
      final activity = ActivityItem.fromJson({
        'type': 'order_paid',
        'tag': '支付',
        'title': '支付完成: 和田玉手链',
        'subtitle': '￥299',
        'time': '2026-03-23T10:00:00',
      });

      expect(activity.tag, '订单');
      expect(activity.icon, 'payment');
      expect(activity.color, '#06B6D4');
      expect(activity.id, contains('order_paid'));
    });
  });

  group('OperatorReport', () {
    test('parses full json payload', () {
      final report = OperatorReport.fromJson({
        'operator_id': 1,
        'operator_name': 'Operator A',
        'contact_shops': 50,
        'intention_count': 30,
        'success_count': 20,
        'ai_usage_count': 15,
        'order_amount': 50000.0,
      });

      expect(report.operatorId, 1);
      expect(report.operatorName, 'Operator A');
      expect(report.contactShops, 50);
      expect(report.intentionCount, 30);
      expect(report.successCount, 20);
      expect(report.aiUsageCount, 15);
      expect(report.orderAmount, 50000.0);
    });

    test('falls back to defaults for missing fields', () {
      final report = OperatorReport.fromJson(<String, dynamic>{});

      expect(report.operatorId, 0);
      expect(report.operatorName, '');
      expect(report.contactShops, 0);
      expect(report.intentionCount, 0);
      expect(report.successCount, 0);
      expect(report.aiUsageCount, 0);
      expect(report.orderAmount, 0.0);
    });
  });

  group('SystemStatusSnapshot', () {
    test('parses service map and metric map payloads', () {
      final snapshot = SystemStatusSnapshot.fromJson({
        'status': 'healthy',
        'message': 'all systems operational',
        'timestamp': '2026-03-20T10:00:00Z',
        'services': {
          'database': {'status': 'healthy', 'message': 'connected'},
          'redis': false,
        },
        'metrics': {
          'cpu_usage': {'value': 24, 'unit': '%'},
          'uptime': '72h',
        },
        'warnings': ['cache warmup pending'],
      });

      expect(snapshot.level, HealthLevel.healthy);
      expect(snapshot.message, 'all systems operational');
      expect(snapshot.checkedAt, isNotNull);
      expect(snapshot.services.length, 2);
      expect(snapshot.services.first.name, 'database');
      expect(snapshot.services.first.level, HealthLevel.healthy);
      expect(snapshot.services[1].level, HealthLevel.unhealthy);
      expect(snapshot.metrics.length, 2);
      expect(snapshot.metrics.first.name, 'cpu_usage');
      expect(snapshot.warnings, ['cache warmup pending']);
    });

    test('falls back to implicit top-level service and metric fields', () {
      final snapshot = SystemStatusSnapshot.fromJson({
        'health': 'degraded',
        'database': true,
        'cpu_usage': 48,
        'memory_usage': 73,
      });

      expect(snapshot.level, HealthLevel.degraded);
      expect(snapshot.services.any((item) => item.name == 'database'), true);
      expect(snapshot.metrics.any((item) => item.name == 'cpu_usage'), true);
      expect(snapshot.metrics.any((item) => item.name == 'memory_usage'), true);
    });
  });

  group('ProductImageUploadResult', () {
    test('parses common upload aliases', () {
      final result = ProductImageUploadResult.fromJson({
        'success': true,
        'url': 'https://cdn.example.com/image.png',
        'filename': 'image.png',
        'message': '上传成功',
      });

      expect(result.success, true);
      expect(result.imageUrl, 'https://cdn.example.com/image.png');
      expect(result.fileName, 'image.png');
      expect(result.message, '上传成功');
    });

    test('defaults missing upload fields safely', () {
      final result = ProductImageUploadResult.fromJson(<String, dynamic>{});

      expect(result.success, true);
      expect(result.imageUrl, isNull);
      expect(result.fileName, isNull);
      expect(result.message, isNull);
    });
  });

  group('ProductUpsertRequest', () {
    test('serializes create payload with optional fields', () {
      const request = ProductUpsertRequest(
        name: '羊脂白玉手镯',
        description: '温润细腻，适合日常佩戴',
        price: 2999,
        originalPrice: 3699,
        category: '手镯',
        material: '和田玉',
        images: ['https://cdn.example.com/bracelet.png'],
        stock: 12,
        isNew: true,
        certificate: 'NGTC-2026-NEW',
      );

      expect(request.toJson(), {
        'name': '羊脂白玉手镯',
        'description': '温润细腻，适合日常佩戴',
        'price': 2999.0,
        'original_price': 3699.0,
        'category': '手镯',
        'material': '和田玉',
        'images': ['https://cdn.example.com/bracelet.png'],
        'stock': 12,
        'is_new': true,
        'certificate': 'NGTC-2026-NEW',
      });
    });

    test('omits nullable fields when not provided', () {
      const request = ProductUpsertRequest(
        name: '南红手串',
        description: '精品南红，色泽浓郁',
        price: 599,
        category: '手串',
        material: '南红玛瑙',
        stock: 30,
      );

      expect(request.toJson(), {
        'name': '南红手串',
        'description': '精品南红，色泽浓郁',
        'price': 599.0,
        'category': '手串',
        'material': '南红玛瑙',
        'stock': 30,
      });
    });
  });
}
