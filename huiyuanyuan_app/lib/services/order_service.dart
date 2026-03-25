/// 汇玉源 - 订单服务
///
/// 功能:
/// - 订单创建
/// - 订单状态管理
/// - 订单查询
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/json_parsing.dart';
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
    if (ApiConfig.useMockApi) {
      state = _buildMockOrders();
      return;
    }

    try {
      final api = ApiService();
      final result = await api.get<List<dynamic>>(ApiConfig.orders);
      if (result.success && result.data != null) {
        state = result.data!
            .map((json) => OrderModel.fromJson(jsonAsMap(json)))
            .toList();
        return;
      }
    } catch (e) {
      // API失败，保持空列表
      debugPrint('[OrderService] 加载订单失败: $e');
    }

    if (state.isEmpty) {
      state = _buildMockOrders();
    }
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
    if (ApiConfig.useMockApi) {
      final order = _buildLocalOrder(
        productId: productId,
        productName: productName,
        quantity: quantity,
        amount: amount,
        productImage: productImage,
        productSpec: productSpec,
        unitPrice: unitPrice,
        paymentMethod: paymentMethod,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        shippingAddress: shippingAddress,
        shippingFee: shippingFee,
        discount: discount,
        remark: remark,
        operatorId: operatorId,
      );
      state = [order, ...state];
      return order;
    }

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
          id: jsonAsString(
            json['id'],
            fallback: 'ORD${DateTime.now().millisecondsSinceEpoch}',
          ),
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
          createdAt: jsonAsDateTime(json['created_at']),
          operatorId: jsonAsNullableString(json['operator_id']) ?? operatorId,
        );
        state = [order, ...state];
        return order;
      }
    } catch (e) {
      debugPrint('[OrderService] 创建订单失败: $e');
    }
    return null;
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
      } catch (e) {
        debugPrint('[OrderService] 更新订单状态失败: $e');
        return false;
      }
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

  /// 取消订单——同步到服务端
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (!state[index].canCancel) return false;

    // 1. 首先调用后端 API
    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.put<Map<String, dynamic>>(
          ApiConfig.orderDetail(orderId),
          data: {
            'status': 'cancelled',
            if (reason != null) 'cancel_reason': reason,
          },
        );
        if (!result.success) {
          debugPrint('[OrderService] 取消订单 API 失败: ${result.message}');
          return false;
        }
      } catch (e) {
        debugPrint('[OrderService] 取消订单异常: $e');
        return false;
      }
    }

    // 2. API 成功后更新本地 state
    final updatedOrder = state[index].copyWith(
      status: OrderStatus.cancelled,
      cancelReason: reason,
      cancelledAt: DateTime.now(),
    );
    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// 模拟支付订单
  Future<bool> simulatePayment(String orderId, {PaymentMethod? method}) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (state[index].status != OrderStatus.pending) return false;

    final updatedOrder = state[index].copyWith(
      status: OrderStatus.paid,
      paymentMethod: method ?? PaymentMethod.wechat,
      paymentId: 'PAY${DateTime.now().millisecondsSinceEpoch}',
      paidAt: DateTime.now(),
    );
    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// 商家发货
  Future<bool> shipOrder(
    String orderId, {
    required String carrier,
    required String trackingNumber,
  }) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (state[index].status != OrderStatus.paid) return false;

    final now = DateTime.now();
    final updatedOrder = state[index].copyWith(
      status: OrderStatus.shipped,
      logisticsCompany: carrier,
      trackingNumber: trackingNumber,
      shippedAt: now,
      logisticsEntries: [
        LogisticsEntry(
          description: '商家已发货，$carrier运送中',
          time: now,
        ),
        LogisticsEntry(
          description: '商家正在处理您的订单',
          time: now.subtract(const Duration(hours: 1)),
        ),
      ],
    );
    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// 确认收货
  Future<bool> confirmReceipt(String orderId) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (!state[index].canConfirmReceipt) return false;

    final now = DateTime.now();
    final existing = state[index].logisticsEntries ?? [];
    final updatedOrder = state[index].copyWith(
      status: OrderStatus.completed,
      deliveredAt: now,
      completedAt: now,
      logisticsEntries: [
        LogisticsEntry(
          description: '已签收，订单完成',
          time: now,
        ),
        ...existing,
      ],
    );
    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// 申请退货/退款——同步到服务端
  Future<bool> requestReturn(String orderId, {String? reason}) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (!state[index].canRefund) return false;

    // 1. 调用后端退款接口
    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.post<Map<String, dynamic>>(
          '${ApiConfig.orderDetail(orderId)}/refund',
          data: {
            'reason': reason ?? '买家申请退款',
          },
        );
        // 后端若返回 404（接口尚未实现）则仅更新本地状态
        if (!result.success && result.code != 404 && result.code != 405) {
          debugPrint('[OrderService] 退款申请 API 失败: ${result.message}');
          return false;
        }
      } catch (e) {
        debugPrint('[OrderService] 退款申请异常: $e');
        // 接口异常时仅更新本地状态，不阻断用户操作
      }
    }

    // 2. 更新本地 state
    final updatedOrder = state[index].copyWith(
      status: OrderStatus.refunding,
      refundReason: reason ?? '买家申请退款',
      refundAmount: state[index].totalPaid,
    );
    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// 删除订单（仅已取消/已完成/已退款的订单可删除）
  Future<bool> deleteOrder(String orderId) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;

    final order = state[index];
    if (order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.completed &&
        order.status != OrderStatus.refunded) {
      return false;
    }

    // 1. 调用后端删除接口
    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.delete<Map<String, dynamic>>(
          ApiConfig.orderDetail(orderId),
        );
        // 404 表示订单已不在服务端，仍可从本地移除
        if (!result.success && result.code != 404) {
          debugPrint('[OrderService] 删除订单 API 失败: ${result.message}');
          return false;
        }
      } catch (e) {
        debugPrint('[OrderService] 删除订单异常: $e');
        return false;
      }
    }

    // 2. 从本地 state 移除
    state = [...state]..removeAt(index);
    return true;
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

  List<OrderModel> _buildMockOrders() {
    final now = DateTime.now();
    return [
      OrderModel(
        id: 'ORD-MOCK-001',
        productId: 'HYY-HT001',
        productName: '新疆和田玉籽料福运手链',
        quantity: 1,
        amount: 299,
        status: OrderStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      OrderModel(
        id: 'ORD-MOCK-002',
        productId: 'HYY-FC005',
        productName: '老坑冰种翡翠福瓜吊坠',
        quantity: 1,
        amount: 3680,
        status: OrderStatus.paid,
        createdAt: now.subtract(const Duration(days: 2)),
        paidAt: now.subtract(const Duration(days: 2, hours: 23)),
      ),
      OrderModel(
        id: 'ORD-MOCK-003',
        productId: 'HYY-NH004',
        productName: '保山南红柿子红圆珠手链',
        quantity: 2,
        amount: 1160,
        status: OrderStatus.shipped,
        createdAt: now.subtract(const Duration(days: 3)),
        paidAt: now.subtract(const Duration(days: 3, hours: 22)),
        shippedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  OrderModel _buildLocalOrder({
    String? productId,
    required String productName,
    required int quantity,
    required double amount,
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
  }) {
    final now = DateTime.now();
    return OrderModel(
      id: 'ORD${now.microsecondsSinceEpoch}',
      productId: productId ?? '',
      productName: productName,
      quantity: quantity,
      amount: amount,
      status: OrderStatus.pending,
      createdAt: now,
      productImage: productImage,
      productSpec: productSpec,
      unitPrice: unitPrice,
      paymentMethod: paymentMethod ?? PaymentMethod.wechat,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      shippingAddress: shippingAddress,
      shippingFee: shippingFee,
      discount: discount,
      remark: remark,
      operatorId: operatorId,
    );
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
