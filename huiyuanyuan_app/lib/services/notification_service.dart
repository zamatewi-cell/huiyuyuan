/// 汇玉源 - 通知服务
///
/// 功能:
/// - 从后端 API 获取通知列表
/// - 标记已读 / 全部已读
/// - 后端不可用时返回空列表（不再使用假数据）
library;

import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../config/api_config.dart';

/// 通知类型
enum NotificationType { order, promotion, system }

/// 通知数据模型
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime time;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _parseType(json['type'] as String?),
      time: json['time'] != null
          ? DateTime.tryParse(json['time']) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'order':
        return NotificationType.order;
      case 'promotion':
        return NotificationType.promotion;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}

/// 通知服务 — 封装 API 调用
class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  final ApiService _api = ApiService();

  /// 获取通知列表
  Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final result = await _api.get<dynamic>(ApiConfig.notifications);
      if (result.success && result.data != null) {
        final data = result.data;
        List<dynamic> items;
        if (data is Map && data['items'] != null) {
          items = data['items'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        } else {
          return [];
        }
        return items
            .map((json) =>
                NotificationItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[NotificationService] 获取通知失败: $e');
    }
    return [];
  }

  /// 标记单条通知已读
  Future<bool> markAsRead(String id) async {
    try {
      final result = await _api.put<dynamic>(
        '${ApiConfig.notifications}/$id/read',
      );
      return result.success;
    } catch (e) {
      debugPrint('[NotificationService] 标记已读失败: $e');
    }
    return false;
  }

  /// 标记全部已读
  Future<bool> markAllAsRead() async {
    try {
      final result = await _api.put<dynamic>(
        '${ApiConfig.notifications}/read-all',
      );
      return result.success;
    } catch (e) {
      debugPrint('[NotificationService] 全部已读失败: $e');
    }
    return false;
  }
}
