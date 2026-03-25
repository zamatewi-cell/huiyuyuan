/// 汇玉源 - 订单模型（v3.1 增强版）
/// 新增: 收货地址、商品图片、支付方式、物流信息、时间戳等完整字段
library;

import 'package:flutter/material.dart';
import 'json_parsing.dart';

// ============ 订单模型 ============

/// 订单状态
enum OrderStatus {
  pending('待支付', Color(0xFFFFC107)),
  paid('已支付', Color(0xFF17A2B8)),
  shipped('已发货', Color(0xFF007BFF)),
  delivered('已签收', Color(0xFF28A745)),
  completed('已完成', Color(0xFF6C757D)),
  cancelled('已取消', Color(0xFFDC3545)),
  refunding('退款中', Color(0xFFFF6B6B)),
  refunded('已退款', Color(0xFF868E96));

  final String label;
  final Color color;
  const OrderStatus(this.label, this.color);
}

/// 支付方式枚举
enum PaymentMethod {
  wechat('微信支付', Color(0xFF07C160)),
  alipay('支付宝', Color(0xFF1677FF)),
  balance('余额支付', Color(0xFFD4AF37)),
  unionpay('银联支付', Color(0xFF1A3E7C));

  final String label;
  final Color color;
  const PaymentMethod(this.label, this.color);
}

/// 物流轨迹条目
class LogisticsEntry {
  final String description;
  final DateTime time;
  final String? location;

  LogisticsEntry({
    required this.description,
    required this.time,
    this.location,
  });

  factory LogisticsEntry.fromJson(Map<String, dynamic> json) {
    return LogisticsEntry(
      description: jsonAsString(json['description']),
      time: jsonAsDateTime(json['time']),
      location: jsonAsNullableString(json['location']),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'time': time.toIso8601String(),
        if (location != null) 'location': location,
      };
}

/// 订单模型（v3.1 增强）
class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double amount;
  final OrderStatus status;
  final DateTime createdAt;

  /// 区块链交易哈希
  final String? txHash;

  /// 操作员ID
  final String? operatorId;

  /// 收款账户ID
  final String? paymentAccountId;

  // ---- v3.1 新增字段 ----

  /// 商品图片 URL（首图）
  final String? productImage;

  /// 商品规格/材质
  final String? productSpec;

  /// 单价
  final double? unitPrice;

  /// 支付方式
  final PaymentMethod? paymentMethod;

  /// 支付单号
  final String? paymentId;

  /// 支付时间
  final DateTime? paidAt;

  /// 发货时间
  final DateTime? shippedAt;

  /// 签收时间
  final DateTime? deliveredAt;

  /// 完成时间
  final DateTime? completedAt;

  /// 取消时间
  final DateTime? cancelledAt;

  /// 取消原因
  final String? cancelReason;

  /// 物流公司
  final String? logisticsCompany;

  /// 物流单号
  final String? trackingNumber;

  /// 物流轨迹
  final List<LogisticsEntry>? logisticsEntries;

  /// 收货人姓名
  final String? recipientName;

  /// 收货人电话
  final String? recipientPhone;

  /// 收货地址（完整）
  final String? shippingAddress;

  /// 运费
  final double shippingFee;

  /// 优惠金额
  final double discount;

  /// 订单备注
  final String? remark;

  /// 退款原因
  final String? refundReason;

  /// 退款金额
  final double? refundAmount;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.txHash,
    this.operatorId,
    this.paymentAccountId,
    this.productImage,
    this.productSpec,
    this.unitPrice,
    this.paymentMethod,
    this.paymentId,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.logisticsCompany,
    this.trackingNumber,
    this.logisticsEntries,
    this.recipientName,
    this.recipientPhone,
    this.shippingAddress,
    this.shippingFee = 0,
    this.discount = 0,
    this.remark,
    this.refundReason,
    this.refundAmount,
  });

  /// 实付金额 = 商品总额 + 运费 - 优惠
  double get totalPaid => amount + shippingFee - discount;

  /// 是否可支付
  bool get canPay => status == OrderStatus.pending;

  /// 是否可取消
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.paid;

  /// 是否可确认收货
  bool get canConfirmReceipt =>
      status == OrderStatus.shipped || status == OrderStatus.delivered;

  /// 是否可申请退款
  bool get canRefund =>
      status == OrderStatus.paid || status == OrderStatus.shipped;

  /// 是否可删除
  bool get canDelete =>
      status == OrderStatus.completed ||
      status == OrderStatus.cancelled ||
      status == OrderStatus.refunded;

  /// 是否可评价
  bool get canReview =>
      status == OrderStatus.completed || status == OrderStatus.delivered;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: jsonAsString(json['id']),
      productId: jsonAsString(json['product_id']),
      productName: jsonAsString(json['product_name']),
      quantity: jsonAsInt(json['quantity'], fallback: 1),
      amount: jsonAsDouble(json['amount']),
      status: jsonEnumByName(
        OrderStatus.values,
        json['status'],
        fallback: OrderStatus.pending,
      ),
      createdAt: jsonAsDateTime(json['created_at']),
      txHash: jsonAsNullableString(json['tx_hash']),
      operatorId: jsonAsNullableString(json['operator_id']),
      paymentAccountId: jsonAsNullableString(json['payment_account_id']),
      productImage: jsonAsNullableString(json['product_image']),
      productSpec: jsonAsNullableString(json['product_spec']),
      unitPrice: jsonAsNullableString(json['unit_price']) == null
          ? null
          : jsonAsDouble(json['unit_price']),
      paymentMethod: jsonAsNullableString(json['payment_method']) == null
          ? null
          : jsonEnumByName(
              PaymentMethod.values,
              json['payment_method'],
              fallback: PaymentMethod.wechat,
            ),
      paymentId: jsonAsNullableString(json['payment_id']),
      paidAt: jsonAsNullableDateTime(json['paid_at']),
      shippedAt: jsonAsNullableDateTime(json['shipped_at']),
      deliveredAt: jsonAsNullableDateTime(json['delivered_at']),
      completedAt: jsonAsNullableDateTime(json['completed_at']),
      cancelledAt: jsonAsNullableDateTime(json['cancelled_at']),
      cancelReason: jsonAsNullableString(json['cancel_reason']),
      logisticsCompany: jsonAsNullableString(json['logistics_company']),
      trackingNumber: jsonAsNullableString(json['tracking_number']),
      logisticsEntries: json['logistics_entries'] == null
          ? null
          : jsonAsList(
              json['logistics_entries'],
              (entry) => LogisticsEntry.fromJson(jsonAsMap(entry)),
            ),
      recipientName: jsonAsNullableString(json['recipient_name']),
      recipientPhone: jsonAsNullableString(json['recipient_phone']),
      shippingAddress: jsonAsNullableString(json['shipping_address']),
      shippingFee: jsonAsDouble(json['shipping_fee']),
      discount: jsonAsDouble(json['discount']),
      remark: jsonAsNullableString(json['remark']),
      refundReason: jsonAsNullableString(json['refund_reason']),
      refundAmount: jsonAsNullableString(json['refund_amount']) == null
          ? null
          : jsonAsDouble(json['refund_amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'amount': amount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'tx_hash': txHash,
      'operator_id': operatorId,
      'payment_account_id': paymentAccountId,
      'product_image': productImage,
      'product_spec': productSpec,
      'unit_price': unitPrice,
      'payment_method': paymentMethod?.name,
      'payment_id': paymentId,
      'paid_at': paidAt?.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancel_reason': cancelReason,
      'logistics_company': logisticsCompany,
      'tracking_number': trackingNumber,
      'logistics_entries':
          logisticsEntries?.map((e) => e.toJson()).toList(),
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'shipping_address': shippingAddress,
      'shipping_fee': shippingFee,
      'discount': discount,
      'remark': remark,
      'refund_reason': refundReason,
      'refund_amount': refundAmount,
    };
  }

  OrderModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? amount,
    OrderStatus? status,
    DateTime? createdAt,
    String? txHash,
    String? operatorId,
    String? paymentAccountId,
    String? productImage,
    String? productSpec,
    double? unitPrice,
    PaymentMethod? paymentMethod,
    String? paymentId,
    DateTime? paidAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelReason,
    String? logisticsCompany,
    String? trackingNumber,
    List<LogisticsEntry>? logisticsEntries,
    String? recipientName,
    String? recipientPhone,
    String? shippingAddress,
    double? shippingFee,
    double? discount,
    String? remark,
    String? refundReason,
    double? refundAmount,
  }) {
    return OrderModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      txHash: txHash ?? this.txHash,
      operatorId: operatorId ?? this.operatorId,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      productImage: productImage ?? this.productImage,
      productSpec: productSpec ?? this.productSpec,
      unitPrice: unitPrice ?? this.unitPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      paidAt: paidAt ?? this.paidAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      logisticsCompany: logisticsCompany ?? this.logisticsCompany,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      logisticsEntries: logisticsEntries ?? this.logisticsEntries,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      remark: remark ?? this.remark,
      refundReason: refundReason ?? this.refundReason,
      refundAmount: refundAmount ?? this.refundAmount,
    );
  }
}
