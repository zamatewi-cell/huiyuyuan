library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

/// SharedPreferences cache key for stored notifications.
const _kNotificationsCacheKey = 'push_notifications_cache';

/// Supported notification categories.
enum NotificationType {
  order('order'),
  promotion('promotion'),
  system('system'),
  live('live'),
  logistics('logistics'),
  chat('chat');

  final String value;

  const NotificationType(this.value);

  String get label {
    switch (this) {
      case NotificationType.order:
        return 'push_type_order'.tr;
      case NotificationType.promotion:
        return 'push_type_promotion'.tr;
      case NotificationType.system:
        return 'push_type_system'.tr;
      case NotificationType.live:
        return 'push_type_live'.tr;
      case NotificationType.logistics:
        return 'push_type_logistics'.tr;
      case NotificationType.chat:
        return 'push_type_chat'.tr;
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// Serializable push notification model.
class PushNotification {
  final String id;
  final String title;
  final String? titleKey;
  final Map<String, Object?>? titleArgs;
  final String body;
  final String? bodyKey;
  final Map<String, Object?>? bodyArgs;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime receivedAt;
  final bool isRead;

  PushNotification({
    required this.id,
    required this.title,
    this.titleKey,
    this.titleArgs,
    required this.body,
    this.bodyKey,
    this.bodyArgs,
    required this.type,
    this.data,
    required this.receivedAt,
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

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      id: jsonAsString(json['id']),
      title: jsonAsString(json['title']),
      titleKey: jsonAsNullableString(json['title_key']),
      titleArgs: _jsonArgsMap(json['title_args']),
      body: jsonAsString(json['body']),
      bodyKey: jsonAsNullableString(json['body_key']),
      bodyArgs: _jsonArgsMap(json['body_args']),
      type: NotificationType.fromString(
        jsonAsString(json['type'], fallback: NotificationType.system.value),
      ),
      data: jsonAsNullableMap(json['data']),
      receivedAt: jsonAsDateTime(
        json['received_at'] ?? json['created_at'] ?? json['time'],
      ),
      isRead: jsonAsBool(json['is_read']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_key': titleKey,
      'title_args': titleArgs,
      'body': body,
      'body_key': bodyKey,
      'body_args': bodyArgs,
      'type': type.value,
      'data': data,
      'received_at': receivedAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  PushNotification copyWith({bool? isRead}) {
    return PushNotification(
      id: id,
      title: title,
      titleKey: titleKey,
      titleArgs: titleArgs,
      body: body,
      bodyKey: bodyKey,
      bodyArgs: bodyArgs,
      type: type,
      data: data,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

Map<String, Object?>? _jsonArgsMap(dynamic value) {
  final map = jsonAsNullableMap(value);
  return map?.map((key, item) => MapEntry(key, item));
}

List<PushNotification> parsePushNotifications(dynamic payload) {
  if (payload is Iterable) {
    return payload
        .map((item) => PushNotification.fromJson(jsonAsMap(item)))
        .toList(growable: false);
  }

  final map = jsonAsMap(payload);
  final candidates = <dynamic>[map['items'], map['data'], map['results']];
  for (final candidate in candidates) {
    if (candidate is Iterable) {
      return candidate
          .map((item) => PushNotification.fromJson(jsonAsMap(item)))
          .toList(growable: false);
    }
  }

  return const [];
}

/// Persisted user notification settings.
class NotificationSettings {
  final bool enabled;
  final bool orderEnabled;
  final bool promotionEnabled;
  final bool liveEnabled;
  final bool logisticsEnabled;
  final bool chatEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String? silentStartTime;
  final String? silentEndTime;

  NotificationSettings({
    this.enabled = true,
    this.orderEnabled = true,
    this.promotionEnabled = true,
    this.liveEnabled = true,
    this.logisticsEnabled = true,
    this.chatEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.silentStartTime,
    this.silentEndTime,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: jsonAsBool(json['enabled'], fallback: true),
      orderEnabled: jsonAsBool(json['order_enabled'], fallback: true),
      promotionEnabled: jsonAsBool(json['promotion_enabled'], fallback: true),
      liveEnabled: jsonAsBool(json['live_enabled'], fallback: true),
      logisticsEnabled: jsonAsBool(json['logistics_enabled'], fallback: true),
      chatEnabled: jsonAsBool(json['chat_enabled'], fallback: true),
      soundEnabled: jsonAsBool(json['sound_enabled'], fallback: true),
      vibrationEnabled: jsonAsBool(json['vibration_enabled'], fallback: true),
      silentStartTime: jsonAsNullableString(json['silent_start_time']),
      silentEndTime: jsonAsNullableString(json['silent_end_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'order_enabled': orderEnabled,
      'promotion_enabled': promotionEnabled,
      'live_enabled': liveEnabled,
      'logistics_enabled': logisticsEnabled,
      'chat_enabled': chatEnabled,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'silent_start_time': silentStartTime,
      'silent_end_time': silentEndTime,
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? orderEnabled,
    bool? promotionEnabled,
    bool? liveEnabled,
    bool? logisticsEnabled,
    bool? chatEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? silentStartTime,
    String? silentEndTime,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      orderEnabled: orderEnabled ?? this.orderEnabled,
      promotionEnabled: promotionEnabled ?? this.promotionEnabled,
      liveEnabled: liveEnabled ?? this.liveEnabled,
      logisticsEnabled: logisticsEnabled ?? this.logisticsEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      silentStartTime: silentStartTime ?? this.silentStartTime,
      silentEndTime: silentEndTime ?? this.silentEndTime,
    );
  }

  /// Returns whether a notification type is currently enabled.
  bool isTypeEnabled(NotificationType type) {
    if (!enabled) {
      return false;
    }

    switch (type) {
      case NotificationType.order:
        return orderEnabled;
      case NotificationType.promotion:
        return promotionEnabled;
      case NotificationType.live:
        return liveEnabled;
      case NotificationType.logistics:
        return logisticsEnabled;
      case NotificationType.chat:
        return chatEnabled;
      case NotificationType.system:
        return true;
    }
  }

  /// Returns whether the current time falls inside quiet hours.
  bool get isInSilentPeriod {
    if (silentStartTime == null || silentEndTime == null) {
      return false;
    }

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startParts = silentStartTime!.split(':');
    final endParts = silentEndTime!.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }

    // Quiet hours can cross midnight, for example 22:00 to 08:00.
    return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
  }
}

/// HuiYuYuan push notification service singleton.
class PushService {
  static final PushService _instance = PushService._internal();

  factory PushService() => _instance;

  PushService._internal();

  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  final List<PushNotification> _notifications = [];
  final StreamController<PushNotification> _notificationController =
      StreamController<PushNotification>.broadcast();

  String? _deviceToken;
  NotificationSettings _settings = NotificationSettings();
  Timer? _pollTimer;

  /// Stream of new notifications.
  Stream<PushNotification> get onNotification => _notificationController.stream;

  /// Count of unread notifications.
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  /// Immutable list of cached notifications.
  List<PushNotification> get notifications => List.unmodifiable(_notifications);

  /// Current notification settings.
  NotificationSettings get settings => _settings;

  /// Initializes local state and the remote registration flow.
  Future<void> initialize() async {
    await _loadSettings();
    await _loadNotifications();
    await _initializeFirebase();
    _startPolling();
  }

  /// Prepares Firebase push registration when the dependency is available.
  Future<void> _initializeFirebase() async {
    // TODO: Wire in Firebase Messaging once native push is enabled.
    // The service currently falls back to API polling and a debug token.

    if (kDebugMode && _deviceToken == null) {
      _deviceToken =
          'debug_device_token_${DateTime.now().millisecondsSinceEpoch}';
    }
    debugPrint('[PushService] Initialized device token: $_deviceToken');

    await _registerDevice();
  }

  /// Polls the API for notifications when native push is unavailable.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      fetchFromServer();
    });
  }

  /// Fetches the latest notifications from the backend.
  Future<void> fetchFromServer() async {
    try {
      final response = await _api.get(ApiConfig.notifications);
      final serverNotifications = parsePushNotifications(response.data);
      if (response.success && serverNotifications.isNotEmpty) {

        final existingIds = _notifications.map((item) => item.id).toSet();
        for (final notification in serverNotifications) {
          if (!existingIds.contains(notification.id)) {
            _notifications.insert(0, notification);
            _notificationController.add(notification);
          }
        }

        await _saveNotifications();
      }
    } catch (_) {}
  }

  /// Registers the current device token and settings with the backend.
  Future<void> _registerDevice() async {
    if (_deviceToken == null) {
      return;
    }

    try {
      await _api.post(
        ApiConfig.registerDevice,
        data: {
          'device_token': _deviceToken,
          'platform':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'settings': _settings.toJson(),
        },
      );
    } catch (error) {
      debugPrint('[PushService] Failed to register device: $error');
    }
  }

  /// Handles token refresh events.
  // ignore: unused_element
  void _onTokenRefresh(String token) {
    _deviceToken = token;
    _registerDevice();
  }

  /// Handles foreground push messages.
  // ignore: unused_element
  void _handleForegroundMessage(dynamic message) {
    // TODO: Replace dynamic with Firebase RemoteMessage once integrated.
    /*
    final notification = PushNotification(
      id: message.messageId ?? '',
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: NotificationType.fromString(message.data['type'] ?? 'system'),
      data: message.data,
      receivedAt: DateTime.now(),
    );

    _addNotification(notification);
    _showLocalNotification(notification);
    */
  }

  /// Handles notification taps that reopen the app.
  // ignore: unused_element
  void _handleMessageOpenedApp(dynamic message) {
    // TODO: Route to the correct screen after integrating navigation here.
    /*
    final data = message.data;
    final type = NotificationType.fromString(data['type'] ?? 'system');

    switch (type) {
      case NotificationType.order:
        // Navigate to the order detail page.
        Navigator.pushNamed(context, '/order/${data['order_id']}');
        break;
      case NotificationType.promotion:
        // Navigate to the product detail page.
        Navigator.pushNamed(context, '/product/${data['product_id']}');
        break;
      default:
        break;
    }
    */
  }

  /// Adds a new notification to the local cache.
  void _addNotification(PushNotification notification) {
    _notifications.insert(0, notification);
    _notificationController.add(notification);
    _saveNotifications();
  }

  /// Shows a local notification when notifications are enabled.
  Future<void> _showLocalNotification(PushNotification notification) async {
    if (!_settings.isTypeEnabled(notification.type) ||
        _settings.isInSilentPeriod) {
      return;
    }

    // TODO: Use flutter_local_notifications for on-device alerts.
    /*
    final androidDetails = AndroidNotificationDetails(
      'huiyuyuan_channel',
      'push_channel_name'.tr,
      channelDescription: 'push_channel_description'.tr,
      importance: Importance.high,
      priority: Priority.high,
      playSound: _settings.soundEnabled,
      enableVibration: _settings.vibrationEnabled,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _settings.soundEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notification.id.hashCode,
      notification.localizedTitle,
      notification.localizedBody,
      details,
      payload: jsonEncode(notification.toJson()),
    );
    */

    debugPrint(
      '[PushService] Display local notification: '
      '${notification.localizedTitle}',
    );
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String notificationId) async {
    final index =
        _notifications.indexWhere((item) => item.id == notificationId);
    if (index < 0) {
      return;
    }

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    await _saveNotifications();
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    for (int index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    await _saveNotifications();
  }

  /// Deletes a single notification.
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((item) => item.id == notificationId);
    await _saveNotifications();
  }

  /// Clears all cached notifications.
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
  }

  /// Updates settings locally and syncs them to the backend.
  Future<void> updateSettings(NotificationSettings settings) async {
    _settings = settings;
    await _saveSettings();
    await _registerDevice();
  }

  Future<void> _loadSettings() async {
    final data = await _storage.getReminderSettings();
    _settings = NotificationSettings.fromJson(data);
  }

  Future<void> _saveSettings() async {
    await _storage.saveReminderSettings(_settings.toJson());
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kNotificationsCacheKey);
      if (cached != null) {
        final list = (jsonDecode(cached) as List)
            .map((item) => PushNotification.fromJson(jsonAsMap(item)))
            .toList();
        _notifications.addAll(list);
      }
    } catch (_) {}
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave =
          _notifications.take(200).map((item) => item.toJson()).toList();
      await prefs.setString(_kNotificationsCacheKey, jsonEncode(toSave));
    } catch (_) {}
  }

  /// Sends a local test notification for development flows.
  void sendTestNotification({
    String? title,
    String? body,
    NotificationType type = NotificationType.system,
  }) {
    final titleKey = title == null ? 'push_test_title' : null;
    final bodyKey = body == null ? 'push_test_body' : null;
    final notification = PushNotification(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? titleKey!.tr,
      titleKey: titleKey,
      body: body ?? bodyKey!.tr,
      bodyKey: bodyKey,
      type: type,
      receivedAt: DateTime.now(),
    );

    _addNotification(notification);
    _showLocalNotification(notification);
  }

  /// Releases timers and stream resources.
  void dispose() {
    _pollTimer?.cancel();
    _notificationController.close();
  }
}
