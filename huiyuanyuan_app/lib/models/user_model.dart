/// 汇玉源 - 数据模型（Barrel File）
/// 统一导出所有模型，保持向后兼容
/// 各模型已拆分到独立文件，可按需单独导入
library;

// 用户模型保留在本文件中
export 'product_model.dart';
export 'shop_model.dart';
export 'order_model.dart';
export 'cart_item_model.dart';
export 'chat_message_model.dart';
export 'business_models.dart';

import 'dart:typed_data'; // ignore: unused_import
import '../config/app_config.dart';
import 'json_parsing.dart';

// ============ 用户模型 ============

enum UserType {
  /// 超级管理员
  admin,

  /// 操作员 - 10个独立账户
  operator,

  /// 普通用户
  customer,
}

/// 用户模型
class UserModel {
  final String id;
  final String username;
  final String? phone;
  final UserType userType;
  final bool isActive;
  final String? token;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  /// 操作员绑定的收款账户ID
  final String? paymentAccountId;

  /// 操作员编号 (1-10)
  final int? operatorNumber;

  UserModel({
    required this.id,
    required this.username,
    this.phone,
    required this.userType,
    this.isActive = true,
    this.token,
    this.createdAt,
    this.lastLoginAt,
    this.paymentAccountId,
    this.operatorNumber,
  });

  /// 是否为管理员
  bool get isAdmin => userType == UserType.admin;

  /// 是否为普通用户
  bool get isCustomer => userType == UserType.customer;

  /// 是否为固定管理员账号
  bool get isSuperAdmin => phone == AppConfig.adminPhone && userType == UserType.admin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: jsonAsString(json['id']),
      username: jsonAsString(json['username']),
      phone: jsonAsNullableString(json['phone']),
      userType: _parseUserType(jsonAsNullableString(json['user_type'])),
      isActive: jsonAsBool(json['is_active'], fallback: true),
      token: jsonAsNullableString(json['token']),
      createdAt: jsonAsNullableDateTime(json['created_at']),
      lastLoginAt: jsonAsNullableDateTime(json['last_login_at']),
      paymentAccountId: jsonAsNullableString(json['payment_account_id']),
      operatorNumber: jsonAsNullableInt(json['operator_number']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phone': phone,
      'user_type': userType.name,
      'is_active': isActive,
      'token': token,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'payment_account_id': paymentAccountId,
      'operator_number': operatorNumber,
    };
  }

  static UserType _parseUserType(String? typeStr) {
    if (typeStr == UserType.admin.name) return UserType.admin;
    if (typeStr == UserType.operator.name) return UserType.operator;
    return UserType.customer;
  }
}
