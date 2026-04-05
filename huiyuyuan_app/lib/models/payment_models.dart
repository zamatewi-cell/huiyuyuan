library;

import 'package:huiyuyuan/l10n/string_extension.dart';

import 'json_parsing.dart';
import 'payment_account.dart';

enum PaymentMethod {
  wechat('payment_method_wechat', 'wechat'),
  alipay('payment_method_alipay', 'alipay'),
  unionpay('payment_method_unionpay', 'unionpay'),
  balance('payment_method_balance', 'balance');

  final String labelKey;
  final String code;
  const PaymentMethod(this.labelKey, this.code);

  String get label => labelKey.tr;
}

PaymentMethod paymentMethodFromValue(
  dynamic value, {
  PaymentMethod fallback = PaymentMethod.alipay,
}) {
  final raw = jsonAsNullableString(value)?.toLowerCase();
  switch (raw) {
    case 'wechat':
    case 'wx':
      return PaymentMethod.wechat;
    case 'alipay':
    case 'ali':
      return PaymentMethod.alipay;
    case 'unionpay':
    case 'union':
      return PaymentMethod.unionpay;
    case 'balance':
      return PaymentMethod.balance;
    default:
      return fallback;
  }
}

enum PaymentStatus {
  pending('payment_status_pending'),
  awaitingConfirmation('payment_status_awaiting_confirmation'),
  confirmed('payment_status_confirmed'),
  cancelled('payment_status_cancelled'),
  timeout('payment_status_timeout'),
  disputed('payment_status_disputed'),
  refunded('payment_status_refunded');

  final String labelKey;
  const PaymentStatus(this.labelKey);

  String get label => labelKey.tr;
}

PaymentStatus paymentStatusFromValue(
  dynamic value, {
  PaymentStatus fallback = PaymentStatus.pending,
}) {
  final raw = jsonAsNullableString(value)?.toLowerCase();
  switch (raw) {
    case 'pending':
    case 'unpaid':
    case 'created':
      return PaymentStatus.pending;
    case 'awaiting_confirmation':
    case 'processing':
    case 'paying':
      return PaymentStatus.awaitingConfirmation;
    case 'confirmed':
    case 'success':
    case 'paid':
    case 'completed':
      return PaymentStatus.confirmed;
    case 'cancelled':
    case 'canceled':
      return PaymentStatus.cancelled;
    case 'timeout':
      return PaymentStatus.timeout;
    case 'disputed':
      return PaymentStatus.disputed;
    case 'refunded':
    case 'refunding':
      return PaymentStatus.refunded;
    default:
      return fallback;
  }
}

enum RefundStatus {
  processing('refund_status_processing'),
  refunded('refund_status_refunded'),
  failed('refund_status_failed'),
  cancelled('refund_status_cancelled');

  final String labelKey;
  const RefundStatus(this.labelKey);

  String get label => labelKey.tr;
}

RefundStatus refundStatusFromValue(
  dynamic value, {
  RefundStatus fallback = RefundStatus.processing,
}) {
  final raw = jsonAsNullableString(value)?.toLowerCase();
  switch (raw) {
    case 'processing':
    case 'pending':
    case 'refunding':
      return RefundStatus.processing;
    case 'refunded':
    case 'success':
    case 'completed':
      return RefundStatus.refunded;
    case 'failed':
    case 'failure':
      return RefundStatus.failed;
    case 'cancelled':
    case 'canceled':
      return RefundStatus.cancelled;
    default:
      return fallback;
  }
}

const Object _paymentModelUnset = Object();

class PaymentOrder {
  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? errorMessage;

  const PaymentOrder({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.paidAt,
    this.errorMessage,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: jsonAsString(json['id']),
      orderId: jsonAsString(json['order_id']),
      amount: jsonAsDouble(json['amount']),
      method: paymentMethodFromValue(
        json['method'],
        fallback: PaymentMethod.alipay,
      ),
      status: paymentStatusFromValue(
        json['status'],
        fallback: PaymentStatus.pending,
      ),
      transactionId: jsonAsNullableString(json['transaction_id']),
      createdAt: jsonAsDateTime(json['created_at']),
      paidAt: jsonAsNullableDateTime(json['paid_at']),
      errorMessage: jsonAsNullableString(json['error_message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'method': method.code,
      'status': status.name,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'error_message': errorMessage,
    };
  }

  PaymentOrder copyWith({
    String? id,
    String? orderId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    Object? transactionId = _paymentModelUnset,
    DateTime? createdAt,
    Object? paidAt = _paymentModelUnset,
    Object? errorMessage = _paymentModelUnset,
  }) {
    return PaymentOrder(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: identical(transactionId, _paymentModelUnset)
          ? this.transactionId
          : transactionId as String?,
      createdAt: createdAt ?? this.createdAt,
      paidAt: identical(paidAt, _paymentModelUnset)
          ? this.paidAt
          : paidAt as DateTime?,
      errorMessage: identical(errorMessage, _paymentModelUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class WechatPayParams {
  final String appId;
  final String partnerId;
  final String prepayId;
  final String packageValue;
  final String nonceStr;
  final String timeStamp;
  final String sign;

  const WechatPayParams({
    required this.appId,
    required this.partnerId,
    required this.prepayId,
    required this.packageValue,
    required this.nonceStr,
    required this.timeStamp,
    required this.sign,
  });

  factory WechatPayParams.fromJson(Map<String, dynamic> json) {
    return WechatPayParams(
      appId: jsonAsString(json['appId']),
      partnerId: jsonAsString(json['partnerId']),
      prepayId: jsonAsString(json['prepayId']),
      packageValue: jsonAsString(
        json['package'] ?? json['packageValue'],
        fallback: 'Sign=WXPay',
      ),
      nonceStr: jsonAsString(json['nonceStr']),
      timeStamp: jsonAsString(json['timeStamp']),
      sign: jsonAsString(json['sign']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'partnerId': partnerId,
      'prepayId': prepayId,
      'package': packageValue,
      'nonceStr': nonceStr,
      'timeStamp': timeStamp,
      'sign': sign,
    };
  }
}

class AlipayPaymentRequest {
  final String orderString;

  const AlipayPaymentRequest({required this.orderString});

  factory AlipayPaymentRequest.fromJson(Map<String, dynamic> json) {
    return AlipayPaymentRequest(
      orderString: jsonAsString(
        json['order_string'] ?? json['pay_string'] ?? json['payment_string'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'order_string': orderString};
  }
}

class RefundRequestResult {
  final bool success;
  final String refundId;
  final String message;

  const RefundRequestResult({
    required this.success,
    required this.refundId,
    required this.message,
  });

  factory RefundRequestResult.fromJson(Map<String, dynamic> json) {
    return RefundRequestResult(
      success: jsonAsBool(json['success'], fallback: true),
      refundId: jsonAsString(json['refund_id']),
      message: jsonAsString(json['message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'refund_id': refundId,
      'message': message,
    };
  }
}

class RefundStatusResult {
  final String refundId;
  final RefundStatus status;
  final String message;

  const RefundStatusResult({
    required this.refundId,
    required this.status,
    required this.message,
  });

  factory RefundStatusResult.fromJson(Map<String, dynamic> json) {
    return RefundStatusResult(
      refundId: jsonAsString(json['refund_id']),
      status: refundStatusFromValue(json['status']),
      message: jsonAsString(json['message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refund_id': refundId,
      'status': status.name,
      'message': message,
    };
  }
}

class OrderPaymentStatusResult {
  final PaymentStatus status;
  final String? paymentId;
  final String? message;
  final double? amount;
  final PaymentMethod? method;
  final DateTime? paidAt;
  final String? paymentAccountId;
  final PaymentAccount? paymentAccount;

  const OrderPaymentStatusResult({
    required this.status,
    this.paymentId,
    this.message,
    this.amount,
    this.method,
    this.paidAt,
    this.paymentAccountId,
    this.paymentAccount,
  });

  bool get isSuccess => status == PaymentStatus.confirmed;
  bool get isPending => status == PaymentStatus.pending;

  factory OrderPaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return OrderPaymentStatusResult(
      status: paymentStatusFromValue(
        json['status'] ?? json['payment_status'],
        fallback: PaymentStatus.pending,
      ),
      paymentId: jsonAsNullableString(json['payment_id'] ?? json['id']),
      message: jsonAsNullableString(json['message']),
      amount: json['amount'] == null ? null : jsonAsDouble(json['amount']),
      method: json['method'] == null
          ? null
          : paymentMethodFromValue(
              json['method'],
              fallback: PaymentMethod.wechat,
            ),
      paidAt: jsonAsNullableDateTime(json['paid_at']),
      paymentAccountId: jsonAsNullableString(json['payment_account_id']),
      paymentAccount: json['payment_account'] == null
          ? null
          : PaymentAccount.fromMap(jsonAsMap(json['payment_account'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'payment_id': paymentId,
      'message': message,
      'amount': amount,
      'method': method?.code,
      'paid_at': paidAt?.toIso8601String(),
      'payment_account_id': paymentAccountId,
      'payment_account': paymentAccount?.toMap(),
    };
  }
}

class PaymentConfig {
  static const String gatewayUrl = 'https://api.huiyuyuan.com/payment';
  static const String wechatMchId = 'YOUR_MCH_ID';
  static const String wechatAppId = 'YOUR_WECHAT_APP_ID';
  static const String alipayAppId = 'YOUR_ALIPAY_APP_ID';
  static const String notifyUrl = 'https://api.huiyuyuan.com/payment/notify';
  static const bool isSandbox = true;
}
