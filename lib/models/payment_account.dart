import 'dart:convert';

enum PaymentType {
  bank,
  alipay,
  wechat,
  cash,
  other,
}

class PaymentAccount {
  final String id;
  final String name;
  final String? accountNumber;
  final String? bankName; // For bank accounts
  final PaymentType type;
  final String? qrCodeUrl;
  final bool isActive;

  PaymentAccount({
    required this.id,
    required this.name,
    this.accountNumber,
    this.bankName,
    required this.type,
    this.qrCodeUrl,
    this.isActive = true,
  });

  PaymentAccount copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? bankName,
    PaymentType? type,
    String? qrCodeUrl,
    bool? isActive,
  }) {
    return PaymentAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      type: type ?? this.type,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'type': type.index,
      'qrCodeUrl': qrCodeUrl,
      'isActive': isActive,
    };
  }

  factory PaymentAccount.fromMap(Map<String, dynamic> map) {
    return PaymentAccount(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      accountNumber: map['accountNumber'],
      bankName: map['bankName'],
      type: PaymentType.values[map['type'] ?? 0],
      qrCodeUrl: map['qrCodeUrl'],
      isActive: map['isActive'] ?? true,
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
