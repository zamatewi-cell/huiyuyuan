/// 汇玉源 - 推送通知服务
///
/// 功能:
/// - Firebase Cloud Messaging (FCM) 集成
/// - 本地通知管理
/// - 通知权限处理
/// - 消息处理和路由
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/json_parsing.dart';
import 'storage_service.dart';
import 'api_service.dart';
import '../config/api_config.dart';

/// 本地通知缓存 Key
const _kNotificationsCacheKey = 'push_notifications_cache';

/// 通知类型
enum NotificationType {
  /// 订单相关
  order('order', '订单通知'),

  /// 促销活动
  promotion('promotion', '促销通知'),

  /// 系统消息
  system('system', '系统通知'),

  /// 直播提醒
  live('live', '直播提醒'),

  /// 物流通知
  logistics('logistics', '物流通知'),

  /// 聊天消息
  chat('chat', '消息通知');

  final String value;
  final String label;
  const NotificationType(this.value, this.label);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// 通知消息模型
class PushNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime receivedAt;
  final bool isRead;

  PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.receivedAt,
    this.isRead = false,
  });

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      id: jsonAsString(json['id']),
      title: jsonAsString(json['title']),
      body: jsonAsString(json['body']),
      type: NotificationType.fromString(
        jsonAsString(json['type'], fallback: NotificationType.system.value),
      ),
      data: jsonAsNullableMap(json['data']),
      receivedAt: jsonAsDateTime(json['received_at']),
      isRead: jsonAsBool(json['is_read']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
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
      body: body,
      type: type,
      data: data,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// 通知设置
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

  /// 检查某类型通知是否启用
  bool isTypeEnabled(NotificationType type) {
    if (!enabled) return false;

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
        return true; // 系统通知始终启用
    }
  }

  /// 是否在静默时段内
  bool get isInSilentPeriod {
    if (silentStartTime == null || silentEndTime == null) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startParts = silentStartTime!.split(':');
    final endParts = silentEndTime!.split(':');

    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 跨日静默（如22:00 - 08:00）
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

/// 推送服务
class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  String? _deviceToken;
  NotificationSettings _settings = NotificationSettings();
  final List<PushNotification> _notifications = [];

  // 通知流控制器
  final StreamController<PushNotification> _notificationController =
      StreamController<PushNotification>.broadcast();

  /// 通知流
  Stream<PushNotification> get onNotification => _notificationController.stream;

  /// 未读通知数量
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// 所有通知
  List<PushNotification> get notifications => List.unmodifiable(_notifications);

  /// 通知设置
  NotificationSettings get settings => _settings;

  /// 初始化推送服务
  Future<void> initialize() async {
    await _loadSettings();
    await _loadNotifications();

    // 初始化 Firebase（需要实际集成 firebase_messaging 后取消注释）
    await _initializeFirebase();

    // 启动 API 轮询作为 fallback
    _startPolling();
  }

  /// 初始化Firebase
  Future<void> _initializeFirebase() async {
    // TODO: 实际集成Firebase Messaging
    // 这里是伪代码，需要添加firebase_messaging依赖后实现

    /*
    final messaging = FirebaseMessaging.instance;
    
    // 请求权限
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 获取FCM Token
      _deviceToken = await messaging.getToken();
      
      // Token刷新监听
      messaging.onTokenRefresh.listen(_onTokenRefresh);
      
      // 前台消息监听
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // 后台消息点击处理
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // 注册设备到后端
      await _registerDevice();
    }
    */

    // 模拟初始化（仅 Debug 构建）
    if (kDebugMode && _deviceToken == null) {
      _deviceToken =
          'debug_device_token_${DateTime.now().millisecondsSinceEpoch}';
    }
    debugPrint('[PushService] 初始化完成，设备Token: $_deviceToken');

    // 注册设备到后端
    await _registerDevice();
  }

  Timer? _pollTimer;

  /// 后端轮询获取新通知（FCM 不可用时的 fallback）
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      fetchFromServer();
    });
  }

  /// 从服务器拉取通知
  Future<void> fetchFromServer() async {
    try {
      final res = await _api.get(ApiConfig.notifications);
      if (res.success && res.data is List) {
        final serverNotifs = (res.data as List)
            .map((e) => PushNotification.fromJson(jsonAsMap(e)))
            .toList();

        // 只添加本地没有的新通知
        final existingIds = _notifications.map((n) => n.id).toSet();
        for (final n in serverNotifs) {
          if (!existingIds.contains(n.id)) {
            _notifications.insert(0, n);
            _notificationController.add(n);
          }
        }
        await _saveNotifications();
      }
    } catch (_) {}
  }

  /// 注册设备到后端
  Future<void> _registerDevice() async {
    if (_deviceToken == null) return;

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
    } catch (e) {
      debugPrint('[PushService] 设备注册失败: $e');
    }
  }

  /// Token刷新处理
  // ignore: unused_element
  void _onTokenRefresh(String token) {
    _deviceToken = token;
    _registerDevice();
  }

  /// 处理前台消息
  // ignore: unused_element
  void _handleForegroundMessage(dynamic message) {
    // TODO: 解析Firebase RemoteMessage
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

  /// 处理后台消息点击
  // ignore: unused_element
  void _handleMessageOpenedApp(dynamic message) {
    // TODO: 处理消息点击，进行页面跳转
    /*
    final data = message.data;
    final type = NotificationType.fromString(data['type'] ?? 'system');
    
    switch (type) {
      case NotificationType.order:
        // 跳转到订单详情
        Navigator.pushNamed(context, '/order/${data['order_id']}');
        break;
      case NotificationType.promotion:
        // 跳转到商品详情
        Navigator.pushNamed(context, '/product/${data['product_id']}');
        break;
      // ... 其他类型
    }
    */
  }

  /// 添加通知
  void _addNotification(PushNotification notification) {
    _notifications.insert(0, notification);
    _notificationController.add(notification);
    _saveNotifications();
  }

  /// 显示本地通知
  Future<void> _showLocalNotification(PushNotification notification) async {
    if (!_settings.isTypeEnabled(notification.type)) return;
    if (_settings.isInSilentPeriod) return;

    // TODO: 使用flutter_local_notifications显示通知
    /*
    final androidDetails = AndroidNotificationDetails(
      'huiyuanyuan_channel',
      '汇玉源通知',
      channelDescription: '汇玉源App通知',
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
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.toJson()),
    );
    */

    debugPrint('[PushService] 显示通知: ${notification.title}');
  }

  /// 标记通知已读
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
    }
  }

  /// 标记所有通知已读
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _saveNotifications();
  }

  /// 删除通知
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
  }

  /// 清空所有通知
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
  }

  /// 更新通知设置
  Future<void> updateSettings(NotificationSettings settings) async {
    _settings = settings;
    await _saveSettings();
    await _registerDevice(); // 同步到后端
  }

  // ============ 本地存储 ============

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
            .map((e) => PushNotification.fromJson(jsonAsMap(e)))
            .toList();
        _notifications.addAll(list);
      }
    } catch (_) {}
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 只保留最近 200 条
      final toSave = _notifications.take(200).map((n) => n.toJson()).toList();
      await prefs.setString(_kNotificationsCacheKey, jsonEncode(toSave));
    } catch (_) {}
  }

  // ============ 测试方法 ============

  /// 发送测试通知（仅用于开发测试）
  void sendTestNotification({
    String title = '测试通知',
    String body = '这是一条测试通知内容',
    NotificationType type = NotificationType.system,
  }) {
    final notification = PushNotification(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      receivedAt: DateTime.now(),
    );

    _addNotification(notification);
    _showLocalNotification(notification);
  }

  /// 释放资源
  void dispose() {
    _pollTimer?.cancel();
    _notificationController.close();
  }
}
