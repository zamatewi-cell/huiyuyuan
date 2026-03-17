/// 汇玉源 - 店铺/达人模型
library;

import 'package:flutter/material.dart';

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
  final String? shopUrl;
  final int? monthlySales;
  final double? negativeRate;
  final double? dsrScore;
  final bool isInfluencer;
  final String? liveRoomUrl;
  final double? audienceMatchRate;
  final String? operatorId;
  final DateTime? lastContactAt;
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

  bool get isQualified {
    return rating >= 4.7 &&
        (negativeRate == null || negativeRate! < 0.02) &&
        conversionRate >= 3.0;
  }

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
