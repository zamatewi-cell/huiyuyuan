library;

import 'json_parsing.dart';

enum NotificationType { order, promotion, system }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: jsonAsString(json['id']),
      title: jsonAsString(json['title']),
      body: jsonAsString(json['body']),
      type: _parseType(jsonAsNullableString(json['type'])),
      time: jsonAsDateTime(json['time']),
      isRead: jsonAsBool(json['is_read']),
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? time,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'order':
        return NotificationType.order;
      case 'promotion':
        return NotificationType.promotion;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}

List<NotificationItem> parseNotifications(dynamic payload) {
  if (payload is Iterable) {
    return payload
        .map((item) => NotificationItem.fromJson(jsonAsMap(item)))
        .toList(growable: false);
  }

  final map = jsonAsMap(payload);
  final candidates = <dynamic>[map['items'], map['data'], map['results']];
  for (final candidate in candidates) {
    if (candidate is Iterable) {
      return candidate
          .map((item) => NotificationItem.fromJson(jsonAsMap(item)))
          .toList(growable: false);
    }
  }

  return const [];
}
