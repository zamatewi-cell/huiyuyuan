/// HuiYuYuan order service.
///
/// Responsibilities:
/// - create orders
/// - manage order status transitions
/// - load and filter order lists
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/json_parsing.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import 'api_service.dart';
import 'package:huiyuyuan/l10n/translator_global.dart';

/// Order providers.
final orderLoadedProvider = StateProvider<bool>((ref) => false);

final orderProvider =
    StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier(ref);
});

/// Order state notifier.
class OrderNotifier extends StateNotifier<List<OrderModel>> {
  // Reserved for future storage integration.
  // final StorageService _storage = StorageService();
  OrderNotifier(this._ref) : super([]) {
    Future<void>.microtask(_loadOrders);
  }

  final Ref _ref;

  bool _hasOperatorOrderAccess(UserModel? user) {
    if (user == null || user.userType != UserType.operator) {
      return true;
    }
    return user.hasPermission('orders') ||
        user.hasPermission('order_manage') ||
        user.hasPermission('payment_reconcile') ||
        user.hasPermission('payment_exception_mark');
  }

  bool _isPermissionDenied(int? code) => code == 401 || code == 403;

  /// Loads the order list.
  Future<void> _loadOrders() async {
    _ref.read(orderLoadedProvider.notifier).state = false;
    final user = _ref.read(currentUserProvider);

    try {
      if (!_hasOperatorOrderAccess(user)) {
        state = const <OrderModel>[];
        return;
      }

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
        if (_isPermissionDenied(result.code)) {
          state = const <OrderModel>[];
          return;
        }
      } catch (e) {
        // Keep an empty list when the API call fails.
        debugPrint('[OrderService] 加载订单失败: $e');
      }

      if (state.isEmpty) {
        state = _buildMockOrders();
      }
    } finally {
      if (mounted) {
        _ref.read(orderLoadedProvider.notifier).state = true;
      }
    }
  }

  /// Creates an order.
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
    String? addressId,
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
      final requestData = {
        'items': [
          {
            'product_id': productId ?? '',
            'quantity': quantity,
          },
        ],
        'address_id': addressId ?? '',
        'payment_method': paymentMethod?.name ?? 'wechat',
        if (remark != null) 'remark': remark,
      };
      debugPrint('[OrderService] 创建订单请求: $requestData');

      final result = await api.post<Map<String, dynamic>>(
        ApiConfig.orders,
        data: requestData,
      );

      debugPrint(
        '[OrderService] 创建订单响应: '
        'success=${result.success}, '
        'data=${result.data}, '
        'message=${result.message}, '
        'code=${result.code}',
      );

      if (result.success && result.data != null) {
        final json = result.data!;
        final order = OrderModel.fromJson(json);
        state = [order, ...state];
        return order;
      } else {
        debugPrint('[OrderService] 订单创建失败详情: ${result.message}');
        throw Exception(result.message ?? '创建订单失败');
      }
    } catch (e) {
      debugPrint('[OrderService] 创建订单异常: $e');
      rethrow;
    }
  }

  /// Updates an order status.
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

  /// Cancels an order and syncs with the backend when available.
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (!state[index].canCancel) return false;

    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.post<Map<String, dynamic>>(
          '${ApiConfig.orderDetail(orderId)}/cancel',
          data: {
            if (reason != null) 'cancel_reason': reason,
            if (reason != null) 'reason': reason,
          },
        );
        if (!result.success) {
          debugPrint('[OrderService] 取消订单 API 失败: ${result.message}');
          return false;
        }
        await _loadOrders();
        return true;
      } catch (e) {
        debugPrint('[OrderService] 取消订单异常: $e');
        return false;
      }
    }

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

  /// Simulates a successful payment.
  Future<bool> simulatePayment(String orderId, {PaymentMethod? method}) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (state[index].status != OrderStatus.pending) return false;

    final confirmedAt = DateTime.now();
    final updatedOrder = state[index].copyWith(
      status: OrderStatus.paid,
      paymentMethod: method ?? PaymentMethod.wechat,
      paymentId: 'PAY${DateTime.now().millisecondsSinceEpoch}',
      paidAt: confirmedAt,
      paymentRecordStatus: 'confirmed',
      paymentConfirmedAt: confirmedAt,
    );
    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// Marks an order as shipped.
  Future<bool> shipOrder(
    String orderId, {
    required String carrier,
    required String trackingNumber,
  }) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (state[index].status != OrderStatus.paid) return false;

    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.post<Map<String, dynamic>>(
          ApiConfig.adminShipOrder(orderId),
          data: {
            'carrier': carrier,
            'tracking_number': trackingNumber,
          },
        );
        if (!result.success) {
          debugPrint('[OrderService] 发货 API 失败: ${result.message}');
          return false;
        }
        await _loadOrders();
        return true;
      } catch (e) {
        debugPrint('[OrderService] 发货异常: $e');
        return false;
      }
    }

    final now = DateTime.now();
    final updatedOrder = state[index].copyWith(
      status: OrderStatus.shipped,
      logisticsCompany: carrier,
      trackingNumber: trackingNumber,
      shippedAt: now,
      logisticsEntries: [
        LogisticsEntry(
          description: _t(
            'logistics_entry_shipped_in_transit',
            params: {'carrier': carrier},
          ),
          time: now,
        ),
        LogisticsEntry(
          description:
              TranslatorGlobal.instance.translate('merchant_processing_order'),
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

  /// Confirms order receipt.
  Future<bool> confirmReceipt(String orderId) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (!state[index].canConfirmReceipt) return false;

    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.post<Map<String, dynamic>>(
          '${ApiConfig.orderDetail(orderId)}/confirm-receipt',
        );
        if (!result.success) {
          debugPrint('[OrderService] 确认收货 API 失败: ${result.message}');
          return false;
        }
        await _loadOrders();
        return true;
      } catch (e) {
        debugPrint('[OrderService] 确认收货异常: $e');
        return false;
      }
    }

    final now = DateTime.now();
    final existing = state[index].logisticsEntries ?? [];
    final updatedOrder = state[index].copyWith(
      status: OrderStatus.completed,
      deliveredAt: now,
      completedAt: now,
      logisticsEntries: [
        LogisticsEntry(
          description: _t('logistics_entry_delivered'),
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

  Future<bool> confirmPayment(String orderId) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (state[index].status != OrderStatus.pending) return false;

    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.post<Map<String, dynamic>>(
          ApiConfig.adminConfirmPayment(orderId),
          data: const {},
        );
        if (!result.success) {
          debugPrint('[OrderService] 确认到账 API 失败: ${result.message}');
          return false;
        }
        await _loadOrders();
        return true;
      } catch (e) {
        debugPrint('[OrderService] 确认到账异常: $e');
        return false;
      }
    }

    return simulatePayment(orderId);
  }

  Future<bool> markPaymentException(
    String orderId, {
    required String paymentId,
    required String reason,
  }) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (state[index].status != OrderStatus.pending) return false;

    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.post<Map<String, dynamic>>(
          ApiConfig.adminDisputePayment(paymentId),
          params: {'reason': reason},
        );
        if (!result.success) {
          debugPrint('[OrderService] 标记支付异常 API 失败: ${result.message}');
          return false;
        }
        await _loadOrders();
        return true;
      } catch (e) {
        debugPrint('[OrderService] 标记支付异常异常: $e');
        return false;
      }
    }

    final updatedOrder = state[index].copyWith(
      paymentRecordStatus: 'disputed',
      paymentAdminNote: reason,
    );
    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// Requests a refund and syncs with the backend when available.
  Future<bool> requestReturn(String orderId, {String? reason}) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    if (!state[index].canRefund) return false;

    // 1. Call the backend refund endpoint.
    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.post<Map<String, dynamic>>(
          '${ApiConfig.orderDetail(orderId)}/refund',
          data: {
            'reason': reason ?? _t('order_refund_reason_buyer_request'),
          },
        );
        // If the backend returns 404, keep the local fallback behavior.
        if (!result.success && result.code != 404 && result.code != 405) {
          debugPrint('[OrderService] 退款申请 API 失败: ${result.message}');
          return false;
        }
      } catch (e) {
        debugPrint('[OrderService] 退款申请异常: $e');
        // Fall back to a local state update on request errors.
      }
    }

    // 2. Update local state.
    final updatedOrder = state[index].copyWith(
      status: OrderStatus.refunding,
      refundReason: reason ?? _t('order_refund_reason_buyer_request'),
      refundAmount: state[index].totalPaid,
    );
    state = [
      ...state.sublist(0, index),
      updatedOrder,
      ...state.sublist(index + 1),
    ];
    return true;
  }

  /// Deletes an order when its status allows removal.
  Future<bool> deleteOrder(String orderId) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;

    final order = state[index];
    if (order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.completed &&
        order.status != OrderStatus.refunded) {
      return false;
    }

    // 1. Call the backend delete endpoint.
    if (!ApiConfig.useMockApi) {
      try {
        final api = ApiService();
        final result = await api.delete<Map<String, dynamic>>(
          ApiConfig.orderDetail(orderId),
        );
        // A 404 means the order is already gone server-side.
        if (!result.success && result.code != 404) {
          debugPrint('[OrderService] 删除订单 API 失败: ${result.message}');
          return false;
        }
      } catch (e) {
        debugPrint('[OrderService] 删除订单异常: $e');
        return false;
      }
    }

    // 2. Remove the order from local state.
    state = [...state]..removeAt(index);
    return true;
  }

  /// Returns a specific order by id.
  OrderModel? getOrder(String orderId) {
    try {
      return state.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  /// Filters orders by status.
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return state.where((o) => o.status == status).toList();
  }

  /// Refreshes the order list.
  Future<void> refresh() async {
    await _loadOrders();
  }

  List<OrderModel> _buildMockOrders() {
    final now = DateTime.now();
    return [
      OrderModel(
        id: 'ORD-MOCK-001',
        productId: 'HYY-HT001',
        productName: _t('mock_product_hotan_bracelet'),
        quantity: 1,
        amount: 299,
        status: OrderStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      OrderModel(
        id: 'ORD-MOCK-002',
        productId: 'HYY-FC005',
        productName: _t('mock_product_jade_pendant'),
        quantity: 1,
        amount: 3680,
        status: OrderStatus.paid,
        createdAt: now.subtract(const Duration(days: 2)),
        paidAt: now.subtract(const Duration(days: 2, hours: 23)),
      ),
      OrderModel(
        id: 'ORD-MOCK-003',
        productId: 'HYY-NH004',
        productName: _t('mock_product_nanhong_bracelet'),
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

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return TranslatorGlobal.instance.translate(key, params: params);
  }
}

/// Order statistics provider.
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
