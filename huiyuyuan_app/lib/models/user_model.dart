/// HuiYuYuan model barrel.
/// Exports the model surface while keeping backward compatibility.
/// Most models live in dedicated files and can also be imported directly.
library;

// The user model stays in this file for backward compatibility.
export 'product_model.dart';
export 'shop_model.dart';
export 'order_model.dart';
export 'cart_item_model.dart';
export 'chat_message_model.dart';
export 'business_models.dart';

import 'dart:typed_data'; // ignore: unused_import
import '../config/app_config.dart';
import 'json_parsing.dart';

// User model

enum UserType {
  /// Administrator account.
  admin,

  /// Operator account. The platform reserves 10 dedicated operators.
  operator,

  /// Regular customer account.
  customer,
}

/// User model.
class UserModel {
  final String id;
  final String username;
  final String? phone;
  final UserType userType;
  final bool isActive;
  final String? token;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  /// Payment account id bound to an operator.
  final String? paymentAccountId;

  /// Operator number in the reserved 1-10 range.
  final int? operatorNumber;

  /// Feature permissions granted to this account.
  final List<String> permissions;

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
    this.permissions = const <String>[],
  });

  /// Whether the current user is an administrator.
  bool get isAdmin => userType == UserType.admin;

  /// Whether the current user is a customer.
  bool get isCustomer => userType == UserType.customer;

  /// Whether this is the built-in administrator account.
  bool get isSuperAdmin =>
      phone == AppConfig.adminPhone && userType == UserType.admin;

  bool hasPermission(String permission) {
    return isAdmin || permissions.contains(permission);
  }

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
      permissions: jsonAsStringList(json['permissions']),
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
      'permissions': permissions,
    };
  }

  static UserType _parseUserType(String? typeStr) {
    if (typeStr == UserType.admin.name) return UserType.admin;
    if (typeStr == UserType.operator.name) return UserType.operator;
    return UserType.customer;
  }
}
