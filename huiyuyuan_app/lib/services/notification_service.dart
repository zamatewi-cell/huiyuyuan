library;

import '../models/notification_models.dart';
import '../repositories/notification_repository.dart';

class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();

  factory NotificationApiService() => _instance;

  NotificationApiService._internal() : _repository = NotificationRepository();

  final NotificationRepository _repository;

  Future<List<NotificationItem>> fetchNotifications() {
    return _repository.fetchNotifications();
  }

  Future<bool> markAsRead(String id) {
    return _repository.markAsRead(id);
  }

  Future<bool> markAllAsRead() {
    return _repository.markAllAsRead();
  }
}
