library;

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/notification_models.dart';
import '../services/api_service.dart';

class NotificationRepository {
  NotificationRepository({ApiService? apiService})
      : _api = apiService ?? ApiService();

  final ApiService _api;

  Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final result = await _api.get<dynamic>(ApiConfig.notifications);
      if (!result.success || result.data == null) {
        return const [];
      }
      return parseNotifications(result.data);
    } catch (error) {
      debugPrint('[NotificationRepository] fetchNotifications failed: $error');
      return const [];
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final result = await _api.put<dynamic>(
        '${ApiConfig.notifications}/$id/read',
      );
      return result.success;
    } catch (error) {
      debugPrint('[NotificationRepository] markAsRead failed: $error');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final result = await _api.put<dynamic>(
        '${ApiConfig.notifications}/read-all',
      );
      return result.success;
    } catch (error) {
      debugPrint('[NotificationRepository] markAllAsRead failed: $error');
      return false;
    }
  }
}
