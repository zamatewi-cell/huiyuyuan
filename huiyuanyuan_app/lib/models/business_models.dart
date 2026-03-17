/// 汇玉源 - 操作简报模型
library;

/// 日报简报模型
class DailyReportModel {
  final String id;
  final String operatorId;
  final DateTime date;
  final int contactedShops;
  final int interestedCount;
  final int cooperatedCount;
  final int aiUsageCount;
  final double orderAmount;
  final int newCustomers;
  final int autoAcquiredCount;
  final bool isReported;

  DailyReportModel({
    required this.id,
    required this.operatorId,
    required this.date,
    this.contactedShops = 0,
    this.interestedCount = 0,
    this.cooperatedCount = 0,
    this.aiUsageCount = 0,
    this.orderAmount = 0,
    this.newCustomers = 0,
    this.autoAcquiredCount = 0,
    this.isReported = false,
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    return DailyReportModel(
      id: json['id'] ?? '',
      operatorId: json['operator_id'] ?? '',
      date: DateTime.parse(json['date']),
      contactedShops: json['contacted_shops'] ?? 0,
      interestedCount: json['interested_count'] ?? 0,
      cooperatedCount: json['cooperated_count'] ?? 0,
      aiUsageCount: json['ai_usage_count'] ?? 0,
      orderAmount: (json['order_amount'] ?? 0).toDouble(),
      newCustomers: json['new_customers'] ?? 0,
      autoAcquiredCount: json['auto_acquired_count'] ?? 0,
      isReported: json['is_reported'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operator_id': operatorId,
      'date': date.toIso8601String(),
      'contacted_shops': contactedShops,
      'interested_count': interestedCount,
      'cooperated_count': cooperatedCount,
      'ai_usage_count': aiUsageCount,
      'order_amount': orderAmount,
      'new_customers': newCustomers,
      'auto_acquired_count': autoAcquiredCount,
      'is_reported': isReported,
    };
  }
}

/// 收款账户模型
class PaymentAccountModel {
  final String id;
  final String operatorId;
  final String accountType;
  final String accountName;
  final String accountNumber;
  final bool isDefault;
  final DateTime createdAt;

  PaymentAccountModel({
    required this.id,
    required this.operatorId,
    required this.accountType,
    required this.accountName,
    required this.accountNumber,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentAccountModel.fromJson(Map<String, dynamic> json) {
    return PaymentAccountModel(
      id: json['id'] ?? '',
      operatorId: json['operator_id'] ?? '',
      accountType: json['account_type'] ?? 'alipay',
      accountName: json['account_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operator_id': operatorId,
      'account_type': accountType,
      'account_name': accountName,
      'account_number': accountNumber,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 提醒模型
class ReminderModel {
  final String id;
  final String title;
  final String content;
  final String type;
  final DateTime remindAt;
  final String? customSound;
  final bool isTriggered;

  ReminderModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.remindAt,
    this.customSound,
    this.isTriggered = false,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      remindAt: DateTime.parse(json['remind_at']),
      customSound: json['custom_sound'],
      isTriggered: json['is_triggered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'remind_at': remindAt.toIso8601String(),
      'custom_sound': customSound,
      'is_triggered': isTriggered,
    };
  }
}

/// 区块链证书模型
class BlockchainCertificate {
  final String id;
  final String certNo;
  final String materialType;
  final String origin;
  final DateTime certDate;
  final String institution;
  final Map<String, dynamic>? compositionData;
  final String txHash;
  final bool isVerified;

  BlockchainCertificate({
    required this.id,
    required this.certNo,
    required this.materialType,
    required this.origin,
    required this.certDate,
    required this.institution,
    this.compositionData,
    required this.txHash,
    this.isVerified = true,
  });

  factory BlockchainCertificate.fromJson(Map<String, dynamic> json) {
    return BlockchainCertificate(
      id: json['id'] ?? '',
      certNo: json['cert_no'] ?? '',
      materialType: json['material_type'] ?? '',
      origin: json['origin'] ?? '',
      certDate: DateTime.parse(json['cert_date']),
      institution: json['institution'] ?? '',
      compositionData: json['composition_data'],
      txHash: json['tx_hash'] ?? '',
      isVerified: json['is_verified'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cert_no': certNo,
      'material_type': materialType,
      'origin': origin,
      'cert_date': certDate.toIso8601String(),
      'institution': institution,
      'composition_data': compositionData,
      'tx_hash': txHash,
      'is_verified': isVerified,
    };
  }
}
