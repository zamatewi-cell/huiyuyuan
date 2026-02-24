/// 汇玉源 - 数据模型
/// 包含用户、商品、店铺、订单等完整模型定义
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';

// ============ 用户模型 ============

enum UserType {
  /// 超级管理员 - 固定账号18937766669
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
  bool get isSuperAdmin => phone == '18937766669' && userType == UserType.admin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'],
      userType: _parseUserType(json['user_type']),
      isActive: json['is_active'] ?? true,
      token: json['token'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
      paymentAccountId: json['payment_account_id'],
      operatorNumber: json['operator_number'],
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
    if (typeStr == 'admin') return UserType.admin;
    if (typeStr == 'operator') return UserType.operator;
    return UserType.customer;
  }
}

// ============ 商品模型 ============

/// 商品材质枚举
enum MaterialType {
  hetianYu('和田玉', Color(0xFFF5F5DC)),
  jadeite('缅甸翡翠', Color(0xFF32CD32)),
  nanHong('南红玛瑙', Color(0xFFFF6347)),
  amethyst('紫水晶', Color(0xFF9370DB)),
  biyu('碧玉', Color(0xFF228B22)),
  mila('蜜蜡', Color(0xFFFFD700)),
  gold('黄金', Color(0xFFDAA520)),
  ruby('红宝石', Color(0xFFDC143C)),
  sapphire('蓝宝石', Color(0xFF4169E1));

  final String label;
  final Color color;
  const MaterialType(this.label, this.color);
}

/// 商品分类枚举
enum ProductCategory {
  bracelet('手链'),
  pendant('吊坠'),
  ring('戒指'),
  bangle('手镯'),
  necklace('项链'),
  earring('耳饰');

  final String label;
  const ProductCategory(this.label);
}

/// 商品模型
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String material;
  final List<String> images;
  final int stock;
  final double rating;
  final int salesCount;
  final bool isHot;
  final bool isNew;
  final String? origin;

  /// 区块链证书编号
  final String? certificate;

  /// 区块链溯源哈希
  final String? blockchainHash;

  /// 是否为福利款
  final bool isWelfare;

  /// 材质验证状态（天然/处理）
  final String materialVerify;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.material,
    required this.images,
    required this.stock,
    this.rating = 5.0,
    this.salesCount = 0,
    this.isHot = false,
    this.isNew = false,
    this.origin,
    this.certificate,
    this.blockchainHash,
    this.isWelfare = false,
    this.materialVerify = '天然A货',
  });

  /// 折扣率
  double get discountRate {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  /// 是否为福利款（价格在199-599之间）
  bool get isWelfarePriceRange => price >= 199 && price <= 599;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      category: json['category'] ?? '',
      material: json['material'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      stock: json['stock'] ?? 0,
      rating: (json['rating'] ?? 5.0).toDouble(),
      salesCount: json['sales_count'] ?? 0,
      isHot: json['is_hot'] ?? false,
      isNew: json['is_new'] ?? false,
      origin: json['origin'],
      certificate: json['certificate'],
      blockchainHash: json['blockchain_hash'],
      isWelfare: json['is_welfare'] ?? false,
      materialVerify: json['material_verify'] ?? '天然A货',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'category': category,
      'material': material,
      'images': images,
      'stock': stock,
      'rating': rating,
      'sales_count': salesCount,
      'is_hot': isHot,
      'is_new': isNew,
      'origin': origin,
      'certificate': certificate,
      'blockchain_hash': blockchainHash,
      'is_welfare': isWelfare,
      'material_verify': materialVerify,
    };
  }
}

// ============ 店铺模型 ============

/// 电商平台枚举
enum Platform {
  taobao('淘宝', Color(0xFFFF6600)),
  douyin('抖音', Color(0xFF000000)),
  xiaohongshu('小红书', Color(0xFFFF2442)),
  kuaishou('快手', Color(0xFFFF4906)),
  jd('京东', Color(0xFFE4393C)),
  pinduoduo('拼多多', Color(0xFFE02E24));

  final String label;
  final Color color;
  const Platform(this.label, this.color);
}

/// 联系状态枚举
enum ContactStatus {
  pending('待联系', Color(0xFF6C757D)),
  contacted('已联系', Color(0xFF17A2B8)),
  interested('有意向', Color(0xFFFFC107)),
  negotiating('洽谈中', Color(0xFF007BFF)),
  cooperated('已合作', Color(0xFF28A745)),
  rejected('已拒绝', Color(0xFFDC3545));

  final String label;
  final Color color;
  const ContactStatus(this.label, this.color);
}

/// 店铺/达人模型
class ShopModel {
  final String id;
  final String name;
  final String platform;
  final double rating;
  final double conversionRate;
  final int followers;
  final String category;
  final ContactStatus contactStatus;
  final String? blockchainHash;

  /// 店铺链接
  final String? shopUrl;

  /// 月销量
  final int? monthlySales;

  /// 差评率
  final double? negativeRate;

  /// DSR评分
  final double? dsrScore;

  /// 是否为达人
  final bool isInfluencer;

  /// 达人直播间链接
  final String? liveRoomUrl;

  /// 粉丝画像匹配度
  final double? audienceMatchRate;

  /// 归属操作员ID
  final String? operatorId;

  /// 最后联系时间
  final DateTime? lastContactAt;

  /// AI推荐优先级 (1-100)
  final int? aiPriority;

  ShopModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.rating,
    required this.conversionRate,
    required this.followers,
    required this.category,
    this.contactStatus = ContactStatus.pending,
    this.blockchainHash,
    this.shopUrl,
    this.monthlySales,
    this.negativeRate,
    this.dsrScore,
    this.isInfluencer = false,
    this.liveRoomUrl,
    this.audienceMatchRate,
    this.operatorId,
    this.lastContactAt,
    this.aiPriority,
  });

  /// 是否符合筛选条件（口碑好、成交率高）
  bool get isQualified {
    return rating >= 4.7 &&
        (negativeRate == null || negativeRate! < 0.02) &&
        conversionRate >= 3.0;
  }

  /// 获取平台颜色
  Color get platformColor {
    try {
      return Platform.values.firstWhere((p) => p.label == platform).color;
    } catch (_) {
      return const Color(0xFF6C757D);
    }
  }

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      platform: json['platform'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
      followers: json['followers'] ?? 0,
      category: json['category'] ?? '',
      contactStatus: ContactStatus.values.firstWhere(
        (s) => s.name == json['contact_status'],
        orElse: () => ContactStatus.pending,
      ),
      blockchainHash: json['blockchain_hash'],
      shopUrl: json['shop_url'],
      monthlySales: json['monthly_sales'],
      negativeRate: json['negative_rate']?.toDouble(),
      dsrScore: json['dsr_score']?.toDouble(),
      isInfluencer: json['is_influencer'] ?? false,
      liveRoomUrl: json['live_room_url'],
      audienceMatchRate: json['audience_match_rate']?.toDouble(),
      operatorId: json['operator_id'],
      lastContactAt: json['last_contact_at'] != null
          ? DateTime.parse(json['last_contact_at'])
          : null,
      aiPriority: json['ai_priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'rating': rating,
      'conversion_rate': conversionRate,
      'followers': followers,
      'category': category,
      'contact_status': contactStatus.name,
      'blockchain_hash': blockchainHash,
      'shop_url': shopUrl,
      'monthly_sales': monthlySales,
      'negative_rate': negativeRate,
      'dsr_score': dsrScore,
      'is_influencer': isInfluencer,
      'live_room_url': liveRoomUrl,
      'audience_match_rate': audienceMatchRate,
      'operator_id': operatorId,
      'last_contact_at': lastContactAt?.toIso8601String(),
      'ai_priority': aiPriority,
    };
  }
}

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

/// 订单模型
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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      amount: (json['amount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      txHash: json['tx_hash'],
      operatorId: json['operator_id'],
      paymentAccountId: json['payment_account_id'],
    );
  }
}

// ============ 操作简报模型 ============

/// 日报简报模型
class DailyReportModel {
  final String id;
  final String operatorId;
  final DateTime date;

  /// 联系店铺数
  final int contactedShops;

  /// 成交意向数
  final int interestedCount;

  /// 成功合作数
  final int cooperatedCount;

  /// AI使用次数
  final int aiUsageCount;

  /// 订单金额
  final double orderAmount;

  /// 新增客户数
  final int newCustomers;

  /// 自动获客数
  final int autoAcquiredCount;

  /// 已上报管理员
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
}

// ============ 聊天消息模型 ============

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  /// 消息类型（text, image, voice, system, product_card）
  final String type;

  /// 附件URL
  final String? attachmentUrl;

  /// 图片内存字节（用于 Web 兼容，避免 Image.file 崩溃）
  final Uint8List? imageBytes;

  /// AI 推荐的商品 ID 列表（类型为 product_card 时使用）
  final List<String>? productIds;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = 'text',
    this.attachmentUrl,
    this.imageBytes,
    this.productIds,
  });

  /// 从 JSON 反序列化
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String? ?? 'text',
      attachmentUrl: json['attachmentUrl'] as String?,
      productIds: (json['productIds'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// 序列化为 JSON（imageBytes 不持久化）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (productIds != null) 'productIds': productIds,
    };
  }
}

// ============ 收款账户模型 ============

/// 收款账户模型
class PaymentAccountModel {
  final String id;
  final String operatorId;

  /// 账户类型（alipay, wechat, bank）
  final String accountType;

  /// 账户名称
  final String accountName;

  /// 账户号码（脱敏后）
  final String accountNumber;

  /// 是否为默认账户
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
}

// ============ 提醒模型 ============

/// 提醒模型
class ReminderModel {
  final String id;
  final String title;
  final String content;

  /// 提醒类型
  final String type;

  /// 提醒时间
  final DateTime remindAt;

  /// 自定义提示音路径
  final String? customSound;

  /// 是否已提醒
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
}

// ============ 区块链证书模型 ============

/// 区块链证书模型
class BlockchainCertificate {
  final String id;
  final String certNo;
  final String materialType;
  final String origin;
  final DateTime certDate;

  /// 检测机构
  final String institution;

  /// 成分数据
  final Map<String, dynamic>? compositionData;

  /// 上链哈希
  final String txHash;

  /// 是否已验证
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
}
