/// HuiYuYuan business support models.
library;

import 'json_parsing.dart';

/// Daily report model.
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
      id: jsonAsString(json['id']),
      operatorId: jsonAsString(json['operator_id']),
      date: jsonAsDateTime(json['date']),
      contactedShops: jsonAsInt(json['contacted_shops']),
      interestedCount: jsonAsInt(json['interested_count']),
      cooperatedCount: jsonAsInt(json['cooperated_count']),
      aiUsageCount: jsonAsInt(json['ai_usage_count']),
      orderAmount: jsonAsDouble(json['order_amount']),
      newCustomers: jsonAsInt(json['new_customers']),
      autoAcquiredCount: jsonAsInt(json['auto_acquired_count']),
      isReported: jsonAsBool(json['is_reported']),
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

/// Reminder model.
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
      id: jsonAsString(json['id']),
      title: jsonAsString(json['title']),
      content: jsonAsString(json['content']),
      type: jsonAsString(json['type']),
      remindAt: jsonAsDateTime(json['remind_at']),
      customSound: jsonAsNullableString(json['custom_sound']),
      isTriggered: jsonAsBool(json['is_triggered']),
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

/// Blockchain certificate model.
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
      id: jsonAsString(json['id']),
      certNo: jsonAsString(json['cert_no']),
      materialType: jsonAsString(json['material_type']),
      origin: jsonAsString(json['origin']),
      certDate: jsonAsDateTime(json['cert_date']),
      institution: jsonAsString(json['institution']),
      compositionData: jsonAsNullableMap(json['composition_data']),
      txHash: jsonAsString(json['tx_hash']),
      isVerified: jsonAsBool(json['is_verified'], fallback: true),
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
