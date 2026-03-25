import 'dart:convert';

enum PaymentType {
  bank,
  alipay,
  wechat,
  cash,
  other,
}

extension PaymentTypeExtension on PaymentType {
  String get value {
    switch (this) {
      case PaymentType.bank:
        return 'bank';
      case PaymentType.alipay:
        return 'alipay';
      case PaymentType.wechat:
        return 'wechat';
      case PaymentType.cash:
        return 'cash';
      case PaymentType.other:
        return 'other';
    }
  }

  static PaymentType fromString(String? value) {
    switch (value) {
      case 'bank':
        return PaymentType.bank;
      case 'alipay':
        return PaymentType.alipay;
      case 'wechat':
        return PaymentType.wechat;
      case 'cash':
        return PaymentType.cash;
      case 'other':
      default:
        return PaymentType.other;
    }
  }
}

const Object _paymentFieldUnset = Object();

class PaymentAccount {
  final String id;
  final String? userId;
  final String name;
  final String? accountNumber;
  final String? bankName;
  final PaymentType type;
  final String? qrCodeUrl;
  final bool isActive;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentAccount({
    required this.id,
    this.userId,
    required this.name,
    this.accountNumber,
    this.bankName,
    required this.type,
    this.qrCodeUrl,
    this.isActive = true,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentAccount.create({
    required String name,
    required PaymentType type,
    String? accountNumber,
    String? bankName,
    String? qrCodeUrl,
    bool isActive = true,
    bool isDefault = false,
  }) {
    return PaymentAccount(
      id: '',
      name: name,
      accountNumber: accountNumber,
      bankName: bankName,
      type: type,
      qrCodeUrl: qrCodeUrl,
      isActive: isActive,
      isDefault: isDefault,
    );
  }

  PaymentAccount copyWith({
    String? id,
    Object? userId = _paymentFieldUnset,
    String? name,
    Object? accountNumber = _paymentFieldUnset,
    Object? bankName = _paymentFieldUnset,
    PaymentType? type,
    Object? qrCodeUrl = _paymentFieldUnset,
    bool? isActive,
    bool? isDefault,
    Object? createdAt = _paymentFieldUnset,
    Object? updatedAt = _paymentFieldUnset,
  }) {
    return PaymentAccount(
      id: id ?? this.id,
      userId: identical(userId, _paymentFieldUnset)
          ? this.userId
          : userId as String?,
      name: name ?? this.name,
      accountNumber: identical(accountNumber, _paymentFieldUnset)
          ? this.accountNumber
          : accountNumber as String?,
      bankName: identical(bankName, _paymentFieldUnset)
          ? this.bankName
          : bankName as String?,
      type: type ?? this.type,
      qrCodeUrl: identical(qrCodeUrl, _paymentFieldUnset)
          ? this.qrCodeUrl
          : qrCodeUrl as String?,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: identical(createdAt, _paymentFieldUnset)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _paymentFieldUnset)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'account_number': accountNumber,
      'bank_name': bankName,
      'type': type.value,
      'qr_code_url': qrCodeUrl,
      'is_active': isActive,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'type': type.value,
      'account_number': accountNumber,
      'bank_name': bankName,
      'qr_code_url': qrCodeUrl,
      'is_active': isActive,
      'is_default': isDefault,
    };
  }

  factory PaymentAccount.fromMap(Map<String, dynamic> map) {
    return PaymentAccount(
      id: map['id']?.toString() ?? '',
      userId: _asNullableString(map['user_id']),
      name: map['name']?.toString() ?? '',
      accountNumber: _asNullableString(map['account_number']),
      bankName: _asNullableString(map['bank_name']),
      type: PaymentTypeExtension.fromString(map['type']?.toString()),
      qrCodeUrl: _asNullableString(map['qr_code_url']),
      isActive: _asBool(map['is_active'], fallback: true),
      isDefault: _asBool(map['is_default'], fallback: false),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory PaymentAccount.fromJson(String source) =>
      PaymentAccount.fromMap(json.decode(source) as Map<String, dynamic>);

  String get typeName {
    switch (type) {
      case PaymentType.bank:
        return '银行卡';
      case PaymentType.alipay:
        return '支付宝';
      case PaymentType.wechat:
        return '微信支付';
      case PaymentType.cash:
        return '现金';
      case PaymentType.other:
        return '其他';
    }
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return fallback;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
