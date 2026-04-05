library;

import 'json_parsing.dart';
import '../l10n/string_extension.dart';

enum NotificationType { order, promotion, system }

class NotificationItem {
  final String id;
  final String title;
  final String? titleKey;
  final Map<String, Object?>? titleArgs;
  final String body;
  final String? bodyKey;
  final Map<String, Object?>? bodyArgs;
  final NotificationType type;
  final DateTime time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    this.titleKey,
    this.titleArgs,
    required this.body,
    this.bodyKey,
    this.bodyArgs,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  String get localizedTitle {
    if (titleKey == null || titleKey!.isEmpty) {
      return title;
    }
    return titleKey!.trArgs(titleArgs ?? const {});
  }

  String get localizedBody {
    if (bodyKey == null || bodyKey!.isEmpty) {
      return body;
    }
    return bodyKey!.trArgs(bodyArgs ?? const {});
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: jsonAsString(json['id']),
      title: jsonAsString(json['title']),
      titleKey: jsonAsNullableString(json['title_key']),
      titleArgs: _jsonArgsMap(json['title_args']),
      body: jsonAsString(json['body']),
      bodyKey: jsonAsNullableString(json['body_key']),
      bodyArgs: _jsonArgsMap(json['body_args']),
      type: _parseType(jsonAsNullableString(json['type'])),
      time: jsonAsDateTime(json['time'] ?? json['created_at']),
      isRead: jsonAsBool(json['is_read']),
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? titleKey,
    Map<String, Object?>? titleArgs,
    String? body,
    String? bodyKey,
    Map<String, Object?>? bodyArgs,
    NotificationType? type,
    DateTime? time,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      titleKey: titleKey ?? this.titleKey,
      titleArgs: titleArgs ?? this.titleArgs,
      body: body ?? this.body,
      bodyKey: bodyKey ?? this.bodyKey,
      bodyArgs: bodyArgs ?? this.bodyArgs,
      type: type ?? this.type,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'order':
      case 'order_created':
      case 'order_shipped':
      case 'payment_success':
      case 'logistics':
        return NotificationType.order;
      case 'promotion':
        return NotificationType.promotion;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}

Map<String, Object?>? _jsonArgsMap(dynamic value) {
  final map = jsonAsNullableMap(value);
  return map?.map((key, item) => MapEntry(key, item));
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
