/// HuiYuYuan order model with extended fulfillment metadata.
/// Includes shipping, payment, logistics, and lifecycle timestamps.
library;

import 'package:flutter/material.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';
import 'json_parsing.dart';
import 'payment_account.dart';
import '../l10n/product_translator.dart';
import '../l10n/translator_global.dart';
import '../providers/app_settings_provider.dart';

// Order models.

/// Order lifecycle status.
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

  String get translationKey {
    switch (this) {
      case OrderStatus.pending:
        return 'order_pending_payment';
      case OrderStatus.paid:
        return 'order_pending_shipment';
      case OrderStatus.shipped:
        return 'order_pending_receipt';
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 'order_completed';
      case OrderStatus.cancelled:
        return 'order_cancelled';
      case OrderStatus.refunding:
        return 'order_refunding';
      case OrderStatus.refunded:
        return 'order_refunded';
    }
  }

  String get localizedLabel => translationKey.tr;
}

/// Supported payment methods.
enum PaymentMethod {
  wechat('payment_method_wechat', Color(0xFF07C160)),
  alipay('payment_method_alipay', Color(0xFF1677FF)),
  balance('payment_method_balance', Color(0xFFD4AF37)),
  unionpay('payment_method_unionpay', Color(0xFF1A3E7C));

  final String labelKey;
  final Color color;
  const PaymentMethod(this.labelKey, this.color);

  String get label => labelKey.tr;
}

/// Logistics timeline entry.
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
    final description = jsonAsString(json['description']);
    return LogisticsEntry(
      description: _localizeDescriptionV2(description),
      time: jsonAsDateTime(json['time']),
      location: jsonAsNullableString(json['location']),
    );
  }

  static String _localizeDescription(String description) {
    final shipped =
        RegExp(r'^商家已发货，\s*(.+?)\s*运单号\s*(.+)$').firstMatch(description);
    if (shipped != null) {
      return 'logistics_entry_shipped'.trArgs({
        'company': shipped.group(1)!.trim(),
        'number': shipped.group(2)!.trim(),
      });
    }

    final pickedUp = RegExp(r'^快件已被\s*(.+?)\s*揽收$').firstMatch(description);
    if (pickedUp != null) {
      return 'logistics_entry_picked_up'.trArgs({
        'company': pickedUp.group(1)!.trim(),
      });
    }

    final paid = RegExp(r'^订单已支付\s*[¥￥]?\s*([0-9.]+)\s*\(([^)]+)\)$')
        .firstMatch(description);
    if (paid != null) {
      return 'logistics_entry_order_paid'.trArgs({
        'amount': paid.group(1)!.trim(),
        'method': paid.group(2)!.trim(),
      });
    }

    return description.tr;
  }

  static String _localizeDescriptionV2(String description) {
    final shipped = RegExp(
      r'^\u5546\u5bb6\u5df2\u53d1\u8d27\uff0c\s*(.+?)\s*\u8fd0\u5355\u53f7\s*(.+)$',
    ).firstMatch(description);
    if (shipped != null) {
      return 'logistics_entry_shipped'.trArgs({
        'company': shipped.group(1)!.trim(),
        'number': shipped.group(2)!.trim(),
      });
    }

    final pickedUp = RegExp(
      r'^\u5feb\u4ef6\u5df2\u88ab\s*(.+?)\s*\u63fd\u6536$',
    ).firstMatch(description);
    if (pickedUp != null) {
      return 'logistics_entry_picked_up'.trArgs({
        'company': pickedUp.group(1)!.trim(),
      });
    }

    final paid = RegExp(
      r'^\u8ba2\u5355\u5df2\u652f\u4ed8\s*[\u00A5\uFFE5]?\s*([0-9.]+)\s*\(([^)]+)\)$',
    ).firstMatch(description);
    if (paid != null) {
      return 'logistics_entry_order_paid'.trArgs({
        'amount': paid.group(1)!.trim(),
        'method': paid.group(2)!.trim(),
      });
    }

    return _localizeDescription(description);
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'time': time.toIso8601String(),
        if (location != null) 'location': location,
      };
}

/// Order model.
class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double amount;
  final OrderStatus status;
  final DateTime createdAt;

  /// Blockchain transaction hash.
  final String? txHash;

  /// Operator id.
  final String? operatorId;

  /// Bound payment account id.
  final String? paymentAccountId;

  /// Bound payment account details.
  final PaymentAccount? paymentAccount;

  // Extended v3.1 fields.

  /// Primary product image URL.
  final String? productImage;

  /// Product specification or material.
  final String? productSpec;

  /// Unit price.
  final double? unitPrice;

  /// Payment method.
  final PaymentMethod? paymentMethod;

  /// Payment identifier.
  final String? paymentId;

  /// Payment timestamp.
  final DateTime? paidAt;

  /// Shipment timestamp.
  final DateTime? shippedAt;

  /// Delivery confirmation timestamp.
  final DateTime? deliveredAt;

  /// Completion timestamp.
  final DateTime? completedAt;

  /// Cancellation timestamp.
  final DateTime? cancelledAt;

  /// Cancellation reason.
  final String? cancelReason;

  /// Logistics provider.
  final String? logisticsCompany;

  /// Tracking number.
  final String? trackingNumber;

  /// Logistics timeline.
  final List<LogisticsEntry>? logisticsEntries;

  /// Recipient name.
  final String? recipientName;

  /// Recipient phone number.
  final String? recipientPhone;

  /// Full shipping address.
  final String? shippingAddress;

  /// Shipping fee.
  final double shippingFee;

  /// Discount amount.
  final double discount;

  /// Order remark.
  final String? remark;

  /// Refund reason.
  final String? refundReason;

  /// Refund amount.
  final double? refundAmount;

  /// Payment voucher URL (uploaded by user).
  final String? paymentVoucherUrl;

  /// Admin note for payment confirmation.
  final String? paymentAdminNote;

  /// Payment status (backend payment_record status).
  final String? paymentRecordStatus;

  /// Confirmed by admin ID.
  final String? paymentConfirmedBy;

  /// Payment confirmation timestamp.
  final DateTime? paymentConfirmedAt;

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
    this.paymentAccount,
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
    this.paymentVoucherUrl,
    this.paymentAdminNote,
    this.paymentRecordStatus,
    this.paymentConfirmedBy,
    this.paymentConfirmedAt,
  });

  /// Total paid amount after shipping and discounts.
  double get totalPaid => amount + shippingFee - discount;

  /// Whether the order can be paid.
  bool get canPay => status == OrderStatus.pending;

  /// Whether the order can be cancelled.
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.paid;

  /// Whether receipt can be confirmed.
  bool get canConfirmReceipt =>
      status == OrderStatus.shipped || status == OrderStatus.delivered;

  /// Whether a refund can be requested.
  bool get canRefund =>
      status == OrderStatus.paid || status == OrderStatus.shipped;

  /// Whether the order can be deleted.
  bool get canDelete =>
      status == OrderStatus.completed ||
      status == OrderStatus.cancelled ||
      status == OrderStatus.refunded;

  /// Whether the order can be reviewed.
  bool get canReview =>
      status == OrderStatus.completed || status == OrderStatus.delivered;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = jsonAsList(json['items'], (item) => jsonAsMap(item));
    final firstItem =
        items.isNotEmpty ? items.first : const <String, dynamic>{};
    final address =
        jsonAsNullableMap(json['address']) ?? const <String, dynamic>{};

    return OrderModel(
      id: jsonAsString(json['id']),
      productId: jsonAsNullableString(json['product_id']) ??
          jsonAsString(firstItem['product_id']),
      productName: jsonAsNullableString(json['product_name']) ??
          jsonAsString(firstItem['product_name']),
      quantity: _resolveQuantity(json, items),
      amount: json['amount'] != null
          ? jsonAsDouble(json['amount'])
          : jsonAsDouble(json['total_amount']),
      status: jsonEnumByName(
        OrderStatus.values,
        json['status'],
        fallback: OrderStatus.pending,
      ),
      createdAt: jsonAsDateTime(json['created_at']),
      txHash: jsonAsNullableString(json['tx_hash']),
      operatorId: jsonAsNullableString(json['operator_id']),
      paymentAccountId: jsonAsNullableString(json['payment_account_id']),
      paymentAccount: json['payment_account'] == null
          ? null
          : PaymentAccount.fromMap(jsonAsMap(json['payment_account'])),
      productImage: jsonAsNullableString(json['product_image']) ??
          jsonAsNullableString(firstItem['image']),
      productSpec: jsonAsNullableString(json['product_spec']),
      unitPrice: jsonAsNullableDouble(json['unit_price']) != null
          ? jsonAsDouble(json['unit_price'])
          : jsonAsNullableDouble(firstItem['price']),
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
      recipientName: jsonAsNullableString(json['recipient_name']) ??
          jsonAsNullableString(address['recipient_name']),
      recipientPhone: jsonAsNullableString(json['recipient_phone']) ??
          jsonAsNullableString(address['phone_number']),
      shippingAddress: jsonAsNullableString(json['shipping_address']) ??
          _composeAddress(address),
      shippingFee: jsonAsDouble(json['shipping_fee']),
      discount: jsonAsDouble(json['discount']),
      remark: jsonAsNullableString(json['remark']),
      refundReason: jsonAsNullableString(json['refund_reason']),
      refundAmount: jsonAsNullableString(json['refund_amount']) == null
          ? null
          : jsonAsDouble(json['refund_amount']),
      paymentVoucherUrl: jsonAsNullableString(json['payment_voucher_url']),
      paymentAdminNote: jsonAsNullableString(json['payment_admin_note']),
      paymentRecordStatus: jsonAsNullableString(json['payment_record_status']),
      paymentConfirmedBy: jsonAsNullableString(json['payment_confirmed_by']),
      paymentConfirmedAt: jsonAsNullableDateTime(json['payment_confirmed_at']),
    );
  }

  static int _resolveQuantity(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> items,
  ) {
    if (json['quantity'] != null) {
      return jsonAsInt(json['quantity'], fallback: 1);
    }
    if (items.isEmpty) {
      return 1;
    }

    final total = items.fold<int>(
      0,
      (sum, item) => sum + jsonAsInt(item['quantity'], fallback: 1),
    );
    return total <= 0 ? 1 : total;
  }

  static String? _composeAddress(Map<String, dynamic> address) {
    if (address.isEmpty) {
      return null;
    }

    final parts = <String>[
      jsonAsString(address['province']).trim(),
      jsonAsString(address['city']).trim(),
      jsonAsString(address['district']).trim(),
      jsonAsString(address['detail_address']).trim(),
    ].where((part) => part.isNotEmpty).toList();

    return parts.isEmpty ? null : parts.join(' ');
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
      'payment_account': paymentAccount?.toMap(),
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
      'logistics_entries': logisticsEntries?.map((e) => e.toJson()).toList(),
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'shipping_address': shippingAddress,
      'shipping_fee': shippingFee,
      'discount': discount,
      'remark': remark,
      'refund_reason': refundReason,
      'refund_amount': refundAmount,
      'payment_voucher_url': paymentVoucherUrl,
      'payment_admin_note': paymentAdminNote,
      'payment_record_status': paymentRecordStatus,
      'payment_confirmed_by': paymentConfirmedBy,
      'payment_confirmed_at': paymentConfirmedAt?.toIso8601String(),
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
    PaymentAccount? paymentAccount,
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
    String? paymentVoucherUrl,
    String? paymentAdminNote,
    String? paymentRecordStatus,
    String? paymentConfirmedBy,
    DateTime? paymentConfirmedAt,
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
      paymentAccount: paymentAccount ?? this.paymentAccount,
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
      paymentVoucherUrl: paymentVoucherUrl ?? this.paymentVoucherUrl,
      paymentAdminNote: paymentAdminNote ?? this.paymentAdminNote,
      paymentRecordStatus: paymentRecordStatus ?? this.paymentRecordStatus,
      paymentConfirmedBy: paymentConfirmedBy ?? this.paymentConfirmedBy,
      paymentConfirmedAt: paymentConfirmedAt ?? this.paymentConfirmedAt,
    );
  }
}

extension LocalizedOrderModel on OrderModel {
  String get localizedProductName =>
      localizedProductNameFor(TranslatorGlobal.currentLang);

  String localizedProductNameFor(AppLanguage lang) {
    final source = productName.trim();
    if (source.isEmpty) {
      return '';
    }

    try {
      return ProductTranslator.translateName(
        lang,
        source,
        allowExact: true,
      );
    } catch (_) {
      return source;
    }
  }
}
