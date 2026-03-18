library;

import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuanyuan/services/admin_service.dart';

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
}
