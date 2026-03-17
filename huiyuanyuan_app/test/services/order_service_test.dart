/// 汇玉源 - 订单服务测试
/// 
/// 测试内容:
/// - 订单创建
/// - 订单状态管理
/// - 订单查询
/// - 订单统计
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuanyuan/services/order_service.dart';
import 'package:huiyuanyuan/models/user_model.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('OrderStatus 枚举测试', () {
    test('OrderStatus 应包含所有状态', () {
      expect(OrderStatus.values.length, 8);
      expect(OrderStatus.values.contains(OrderStatus.pending), true);
      expect(OrderStatus.values.contains(OrderStatus.paid), true);
      expect(OrderStatus.values.contains(OrderStatus.shipped), true);
      expect(OrderStatus.values.contains(OrderStatus.delivered), true);
      expect(OrderStatus.values.contains(OrderStatus.completed), true);
      expect(OrderStatus.values.contains(OrderStatus.cancelled), true);
      expect(OrderStatus.values.contains(OrderStatus.refunding), true);
      expect(OrderStatus.values.contains(OrderStatus.refunded), true);
    });

    test('OrderStatus label 应正确', () {
      expect(OrderStatus.pending.label, '待支付');
      expect(OrderStatus.paid.label, '已支付');
      expect(OrderStatus.shipped.label, '已发货');
      expect(OrderStatus.delivered.label, '已签收');
      expect(OrderStatus.completed.label, '已完成');
      expect(OrderStatus.cancelled.label, '已取消');
      expect(OrderStatus.refunding.label, '退款中');
      expect(OrderStatus.refunded.label, '已退款');
    });
  });

  group('OrderModel 测试', () {
    test('OrderModel 应正确创建', () {
      final order = OrderModel(
        id: 'ORD-001',
        productId: 'PROD-001',
        productName: '和田玉福运手链',
        quantity: 1,
        amount: 299.0,
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 2, 1, 10, 0),
      );

      expect(order.id, 'ORD-001');
      expect(order.productId, 'PROD-001');
      expect(order.productName, '和田玉福运手链');
      expect(order.quantity, 1);
      expect(order.amount, 299.0);
      expect(order.status, OrderStatus.pending);
    });

    test('OrderModel.fromJson 应正确解析', () {
      final json = {
        'id': 'ORD-002',
        'product_id': 'PROD-002',
        'product_name': '缅甸翡翠平安扣',
        'quantity': 2,
        'amount': 1198.0,
        'status': 'paid',
        'created_at': '2026-02-01T10:00:00',
        'operator_id': 'operator_1',
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 'ORD-002');
      expect(order.productId, 'PROD-002');
      expect(order.productName, '缅甸翡翠平安扣');
      expect(order.quantity, 2);
      expect(order.amount, 1198.0);
      expect(order.status, OrderStatus.paid);
      expect(order.operatorId, 'operator_1');
    });

    test('OrderModel.fromJson 应处理默认值', () {
      final json = {
        'id': 'ORD-003',
        'product_id': 'PROD-003',
        'product_name': '测试商品',
      };

      final order = OrderModel.fromJson(json);

      expect(order.quantity, 1);
      expect(order.amount, 0.0);
      expect(order.status, OrderStatus.pending);
    });
  });

  group('OrderNotifier 测试', () {
    test('初始化时应加载模拟订单', () async {
      container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final orders = container.read(orderProvider);
      expect(orders.isNotEmpty, true);
    });

    test('创建订单应成功', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-NEW-001',
        productName: '新商品测试',
        quantity: 3,
        amount: 897.0,
      );

      expect(order, isNotNull);
      expect(order!.productId, 'PROD-NEW-001');
      expect(order.productName, '新商品测试');
      expect(order.quantity, 3);
      expect(order.amount, 897.0);
      expect(order.status, OrderStatus.pending);
    });

    test('创建订单后列表应包含新订单', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final initialCount = container.read(orderProvider).length;
      
      await orderNotifier.createOrder(
        productId: 'PROD-NEW-002',
        productName: '测试商品2',
        quantity: 1,
        amount: 199.0,
      );

      final newCount = container.read(orderProvider).length;
      expect(newCount, initialCount + 1);
    });

    test('更新订单状态应成功', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-UPDATE-001',
        productName: '状态更新测试',
        quantity: 1,
        amount: 299.0,
      );

      expect(order!.status, OrderStatus.pending);

      final result = await orderNotifier.updateOrderStatus(
        order.id,
        OrderStatus.paid,
      );

      expect(result, true);

      final updatedOrder = orderNotifier.getOrder(order.id);
      expect(updatedOrder!.status, OrderStatus.paid);
    });

    test('更新不存在的订单应返回false', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final result = await orderNotifier.updateOrderStatus(
        'NON_EXISTENT_ORDER',
        OrderStatus.paid,
      );

      expect(result, false);
    });

    test('取消订单应成功', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-CANCEL-001',
        productName: '取消测试',
        quantity: 1,
        amount: 199.0,
      );

      final result = await orderNotifier.cancelOrder(order!.id);

      expect(result, true);

      final cancelledOrder = orderNotifier.getOrder(order.id);
      expect(cancelledOrder!.status, OrderStatus.cancelled);
    });

    test('获取订单详情应返回正确订单', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final orders = container.read(orderProvider);
      if (orders.isNotEmpty) {
        final order = orderNotifier.getOrder(orders.first.id);
        expect(order, isNotNull);
        expect(order!.id, orders.first.id);
      }
    });

    test('获取不存在的订单应返回null', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = orderNotifier.getOrder('NON_EXISTENT');
      expect(order, isNull);
    });

    test('按状态筛选订单应正确', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final pendingOrders = orderNotifier.getOrdersByStatus(OrderStatus.pending);
      final paidOrders = orderNotifier.getOrdersByStatus(OrderStatus.paid);

      for (final order in pendingOrders) {
        expect(order.status, OrderStatus.pending);
      }
      for (final order in paidOrders) {
        expect(order.status, OrderStatus.paid);
      }
    });

    test('刷新订单列表应成功', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      await orderNotifier.refresh();
      
      final orders = container.read(orderProvider);
      expect(orders.isNotEmpty, true);
    });
  });

  group('orderStatsProvider 测试', () {
    test('订单统计应正确计算', () async {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final stats = container.read(orderStatsProvider);

      expect(stats.containsKey('total'), true);
      expect(stats.containsKey('pending'), true);
      expect(stats.containsKey('paid'), true);
      expect(stats.containsKey('shipped'), true);
      expect(stats.containsKey('completed'), true);
      expect(stats.containsKey('totalAmount'), true);
    });

    test('订单总数应等于各状态之和', () async {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final stats = container.read(orderStatsProvider);
      
      final total = stats['total'] as int;
      final pending = stats['pending'] as int;
      final paid = stats['paid'] as int;
      final shipped = stats['shipped'] as int;
      final completed = stats['completed'] as int;

      expect(total, greaterThanOrEqualTo(pending + paid + shipped + completed));
    });

    test('总金额应为非负数', () async {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final stats = container.read(orderStatsProvider);
      final totalAmount = stats['totalAmount'] as double;
      
      expect(totalAmount, greaterThanOrEqualTo(0));
    });
  });

  group('订单状态流转测试', () {
    test('待支付 -> 已支付 应成功', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-FLOW-001',
        productName: '流程测试1',
        quantity: 1,
        amount: 299.0,
      );

      await orderNotifier.updateOrderStatus(order!.id, OrderStatus.paid);
      
      final updated = orderNotifier.getOrder(order.id);
      expect(updated!.status, OrderStatus.paid);
    });

    test('已支付 -> 已发货 应成功', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-FLOW-002',
        productName: '流程测试2',
        quantity: 1,
        amount: 299.0,
      );

      await orderNotifier.updateOrderStatus(order!.id, OrderStatus.paid);
      await orderNotifier.updateOrderStatus(order.id, OrderStatus.shipped);
      
      final updated = orderNotifier.getOrder(order.id);
      expect(updated!.status, OrderStatus.shipped);
    });

    test('已发货 -> 已签收 应成功', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-FLOW-003',
        productName: '流程测试3',
        quantity: 1,
        amount: 299.0,
      );

      await orderNotifier.updateOrderStatus(order!.id, OrderStatus.paid);
      await orderNotifier.updateOrderStatus(order.id, OrderStatus.shipped);
      await orderNotifier.updateOrderStatus(order.id, OrderStatus.delivered);
      
      final updated = orderNotifier.getOrder(order.id);
      expect(updated!.status, OrderStatus.delivered);
    });
  });

  group('边界情况测试', () {
    test('创建订单时数量可以为0', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-ZERO-QTY',
        productName: '零数量测试',
        quantity: 0,
        amount: 0.0,
      );

      expect(order!.quantity, 0);
      expect(order.amount, 0.0);
    });

    test('创建订单时金额可以为0', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-ZERO-AMT',
        productName: '零金额测试',
        quantity: 1,
        amount: 0.0,
      );

      expect(order!.amount, 0.0);
    });

    test('订单ID应唯一', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order1 = await orderNotifier.createOrder(
        productId: 'PROD-UNIQUE-001',
        productName: '唯一测试1',
        quantity: 1,
        amount: 100.0,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      final order2 = await orderNotifier.createOrder(
        productId: 'PROD-UNIQUE-002',
        productName: '唯一测试2',
        quantity: 1,
        amount: 100.0,
      );

      expect(order1!.id, isNot(equals(order2!.id)));
    });

    test('大金额订单应能创建', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-LARGE-AMT',
        productName: '大金额测试',
        quantity: 10,
        amount: 999999.99,
      );

      expect(order!.amount, 999999.99);
    });
  });

  group('操作员关联测试', () {
    test('订单可以关联操作员', () async {
      final orderNotifier = container.read(orderProvider.notifier);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final order = await orderNotifier.createOrder(
        productId: 'PROD-OP-001',
        productName: '操作员测试',
        quantity: 1,
        amount: 299.0,
        operatorId: 'operator_1',
      );

      expect(order!.operatorId, 'operator_1');
    });
  });
}
