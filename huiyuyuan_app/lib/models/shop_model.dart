/// HuiYuYuan shop and influencer model.
library;

import 'package:flutter/material.dart';
import 'json_parsing.dart';

// Shop model

/// Supported e-commerce platforms.
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

/// Contact status enum.
enum ContactStatus {
  pending('shop_radar_status_pending', Color(0xFF6C757D)),
  contacted('shop_radar_status_contacted', Color(0xFF17A2B8)),
  interested('shop_radar_status_interested', Color(0xFFFFC107)),
  negotiating('shop_radar_status_negotiating', Color(0xFF007BFF)),
  cooperated('shop_radar_status_cooperated', Color(0xFF28A745)),
  rejected('shop_radar_status_rejected', Color(0xFFDC3545));

  final String labelKey;
  final Color color;
  const ContactStatus(this.labelKey, this.color);
}

/// Shop or influencer model.
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
      id: jsonAsString(json['id']),
      name: jsonAsString(json['name']),
      platform: jsonAsString(json['platform']),
      rating: jsonAsDouble(json['rating']),
      conversionRate: jsonAsDouble(json['conversion_rate']),
      followers: jsonAsInt(json['followers']),
      category: jsonAsString(json['category']),
      contactStatus: jsonEnumByName(
        ContactStatus.values,
        json['contact_status'],
        fallback: ContactStatus.pending,
      ),
      blockchainHash: jsonAsNullableString(json['blockchain_hash']),
      shopUrl: jsonAsNullableString(json['shop_url']),
      monthlySales: jsonAsNullableString(json['monthly_sales']) == null
          ? null
          : jsonAsInt(json['monthly_sales']),
      negativeRate: jsonAsNullableString(json['negative_rate']) == null
          ? null
          : jsonAsDouble(json['negative_rate']),
      dsrScore: jsonAsNullableString(json['dsr_score']) == null
          ? null
          : jsonAsDouble(json['dsr_score']),
      isInfluencer: jsonAsBool(json['is_influencer']),
      liveRoomUrl: jsonAsNullableString(json['live_room_url']),
      audienceMatchRate:
          jsonAsNullableString(json['audience_match_rate']) == null
              ? null
              : jsonAsDouble(json['audience_match_rate']),
      operatorId: jsonAsNullableString(json['operator_id']),
      lastContactAt: jsonAsNullableDateTime(json['last_contact_at']),
      aiPriority: jsonAsNullableString(json['ai_priority']) == null
          ? null
          : jsonAsInt(json['ai_priority']),
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
