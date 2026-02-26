/// 汇玉源 - 订单服务
///
/// 功能:
/// - 订单创建
/// - 订单状态管理
/// - 订单查询
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// 订单Provider
final orderProvider =
    StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier();
});

/// 订单状态管理
class OrderNotifier extends StateNotifier<List<OrderModel>> {
  // 预留用于后续存储集成
  // final StorageService _storage = StorageService();

  OrderNotifier() : super([]) {
    _loadOrders();
  }

  /// 加载订单列表
  Future<void> _loadOrders() async {
    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.get<List<dynamic>>(ApiConfig.orders);
        if (result.success && result.data != null) {
          state = result.data!.map((json) {
            // 解析订单状态
            OrderStatus status = OrderStatus.pending;
            switch (json['status']) {
              case 'pending':
                status = OrderStatus.pending;
                break;
              case 'paid':
                status = OrderStatus.paid;
                break;
              case 'shipped':
                status = OrderStatus.shipped;
                break;
              case 'delivered':
                status = OrderStatus.delivered;
                break;
              case 'completed':
                status = OrderStatus.completed;
                break;
              case 'cancelled':
                status = OrderStatus.cancelled;
                break;
              case 'refunded':
                status = OrderStatus.refunded;
                break;
            }
            return OrderModel(
              id: json['id'] ?? '',
              productId: json['product_id'] ?? '',
              productName: json['product_name'] ?? '',
              quantity: json['quantity'] ?? 1,
              amount: (json['amount'] ?? 0).toDouble(),
              status: status,
              createdAt: json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now(),
              operatorId: json['operator_id'],
            );
          }).toList();
          return;
        }
      } catch (_) {
        // API失败则后退到模拟数据
      }
    }

    // 从本地存储加载订单（模拟数据）
    state = _getMockOrders();
  }

  /// 创建订单
  Future<OrderModel?> createOrder({
    required String productName,
    required int quantity,
    required double amount,
    String? productId,
    String? productImage,
    String? productSpec,
    double? unitPrice,
    PaymentMethod? paymentMethod,
    String? recipientName,
    String? recipientPhone,
    String? shippingAddress,
    double shippingFee = 0,
    double discount = 0,
    String? remark,
    String? operatorId,
  }) async {
    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.post<Map<String, dynamic>>(
          ApiConfig.orders,
          data: {
            'product_id': productId ?? '',
            'product_name': productName,
            'quantity': quantity,
            'amount': amount,
            'product_image': productImage,
            'payment_method': paymentMethod?.name,
            'recipient_name': recipientName,
            'recipient_phone': recipientPhone,
            'shipping_address': shippingAddress,
            'operator_id': operatorId,
          },
        );
        if (result.success && result.data != null) {
          final json = result.data!;
          final order = OrderModel(
            id: json['id'] ?? 'ORD${DateTime.now().millisecondsSinceEpoch}',
            productId: productId ?? '',
            productName: productName,
            quantity: quantity,
            amount: amount,
            productImage: productImage,
            paymentMethod: paymentMethod ?? PaymentMethod.wechat,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            shippingAddress: shippingAddress,
            status: OrderStatus.pending,
            createdAt: json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now(),
            operatorId: operatorId,
          );
          state = [order, ...state];
          return order;
        }
      } catch (_) {}
    }

    final order = OrderModel(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
      productId: productId ?? '',
      productName: productName,
      quantity: quantity,
      amount: amount,
      productImage: productImage,
      paymentMethod: paymentMethod ?? PaymentMethod.wechat,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      shippingAddress: shippingAddress,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      operatorId: operatorId,
    );

    state = [order, ...state];
    return order;
  }

  /// 更新订单状态
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.put<Map<String, dynamic>>(
          ApiConfig.orderDetail(orderId),
          data: {
            'status': newStatus.name,
          },
        );
        if (!result.success) return false;
      } catch (_) {}
    }

    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;

    final updatedOrder = state[index].copyWith(status: newStatus);

    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// 取消订单
  Future<bool> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  /// 获取订单详情
  OrderModel? getOrder(String orderId) {
    try {
      return state.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  /// 按状态筛选订单
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return state.where((o) => o.status == status).toList();
  }

  /// 刷新订单列表
  Future<void> refresh() async {
    await _loadOrders();
  }

  /// 模拟订单数据
  List<OrderModel> _getMockOrders() {
    return [
      OrderModel(
        id: 'ORD202601310001',
        productId: 'prod_001',
        productName: '和田玉福运手链',
        quantity: 1,
        amount: 299,
        status: OrderStatus.paid,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      OrderModel(
        id: 'ORD202601300001',
        productId: 'prod_002',
        productName: '缅甸翡翠平安扣',
        quantity: 2,
        amount: 1198,
        status: OrderStatus.shipped,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      OrderModel(
        id: 'ORD202601280001',
        productId: 'prod_003',
        productName: '南红玛瑙转运珠',
        quantity: 1,
        amount: 199,
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
}

/// 订单统计Provider
final orderStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final orders = ref.watch(orderProvider);

  int pending = 0;
  int paid = 0;
  int shipped = 0;
  int completed = 0;
  double totalAmount = 0;

  for (final order in orders) {
    switch (order.status) {
      case OrderStatus.pending:
        pending++;
        break;
      case OrderStatus.paid:
        paid++;
        break;
      case OrderStatus.shipped:
        shipped++;
        break;
      case OrderStatus.completed:
      case OrderStatus.delivered:
        completed++;
        break;
      default:
        break;
    }
    totalAmount += order.amount;
  }

  return {
    'total': orders.length,
    'pending': pending,
    'paid': paid,
    'shipped': shipped,
    'completed': completed,
    'totalAmount': totalAmount,
  };
});
