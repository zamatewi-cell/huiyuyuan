library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_models.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_realtime_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationRealtimeServiceProvider =
    Provider<NotificationRealtimeService>((ref) {
  final service = NotificationRealtimeService();
  ref.onDispose(service.dispose);
  return service;
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final realtimeService = ref.watch(notificationRealtimeServiceProvider);
  return NotificationNotifier.withDependencies(
    repository,
    realtimeNotifications: realtimeService.watchNotifications(),
  );
});

final notificationUnreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((item) => !item.isRead).length;
});

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : this.withDependencies(NotificationRepository());

  NotificationNotifier.withDependencies(
    this._repository, {
    Stream<NotificationItem>? realtimeNotifications,
  }) : super([]) {
    _loadFromApi();
    _realtimeSubscription = realtimeNotifications?.listen(_mergeRealtimeItem);
  }

  final NotificationRepository _repository;
  StreamSubscription<NotificationItem>? _realtimeSubscription;

  Future<void> _loadFromApi() async {
    final items = await _repository.fetchNotifications();
    if (mounted) {
      state = _mergeNotificationLists(items, state);
    }
  }

  Future<void> refresh() async {
    await _loadFromApi();
  }

  void markAsRead(String id) {
    _repository.markAsRead(id);
    state = [
      for (final notification in state)
        if (notification.id == id)
          notification.copyWith(isRead: true)
        else
          notification,
    ];
  }

  void markAllAsRead() {
    _repository.markAllAsRead();
    state = [for (final notification in state) notification.copyWith(isRead: true)];
  }

  int get unreadCount => state.where((notification) => !notification.isRead).length;

  void _mergeRealtimeItem(NotificationItem item) {
    if (!mounted) {
      return;
    }
    state = _mergeNotificationLists([item], state);
  }

  List<NotificationItem> _mergeNotificationLists(
    Iterable<NotificationItem> incoming,
    Iterable<NotificationItem> existing,
  ) {
    final merged = <String, NotificationItem>{};

    for (final item in existing) {
      final signature = _notificationSignature(item);
      merged[signature] = item;
    }

    for (final item in incoming) {
      final signature = _notificationSignature(item);
      final previous = merged[signature];
      merged[signature] = previous == null
          ? item
          : _preferNewerNotification(previous, item);
    }

    final items = merged.values.toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  NotificationItem _preferNewerNotification(
    NotificationItem current,
    NotificationItem candidate,
  ) {
    final preferred =
        candidate.time.isAfter(current.time) ? candidate : current;
    final readState = current.isRead || candidate.isRead;
    return preferred.copyWith(isRead: readState);
  }

  String _notificationSignature(NotificationItem item) {
    return [
      item.type.name,
      item.titleKey ?? item.title,
      _mapSignature(item.titleArgs),
      item.bodyKey ?? item.body,
      _mapSignature(item.bodyArgs),
    ].join('|');
  }

  String _mapSignature(Map<String, Object?>? value) {
    if (value == null || value.isEmpty) {
      return '';
    }
    final sorted = Map.fromEntries(
      value.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return jsonEncode(sorted);
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
