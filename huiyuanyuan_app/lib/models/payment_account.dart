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

  PaymentAccount({
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
    final now = DateTime.now();
    return PaymentAccount(
      id: '',
      name: name,
      accountNumber: accountNumber,
      bankName: bankName,
      type: type,
      qrCodeUrl: qrCodeUrl,
      isActive: isActive,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  PaymentAccount copyWith({
    String? id,
    String? userId,
    String? name,
    String? accountNumber,
    String? bankName,
    PaymentType? type,
    String? qrCodeUrl,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      type: type ?? this.type,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      accountNumber: map['account_number'],
      bankName: map['bank_name'],
      type: PaymentTypeExtension.fromString(map['type']),
      qrCodeUrl: map['qr_code_url'],
      isActive: map['is_active'] ?? true,
      isDefault: map['is_default'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PaymentAccount.fromJson(String source) =>
      PaymentAccount.fromMap(json.decode(source));

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
}
