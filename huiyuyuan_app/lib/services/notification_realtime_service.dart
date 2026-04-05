library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import '../models/notification_models.dart';
import 'api_service.dart';

class NotificationRealtimeService {
  NotificationRealtimeService({
    ApiService? apiService,
    WebSocketChannel Function(Uri uri)? channelFactory,
    Duration reconnectDelay = const Duration(seconds: 3),
  })  : _apiService = apiService ?? ApiService(),
        _channelFactory = channelFactory ?? WebSocketChannel.connect,
        _reconnectDelay = reconnectDelay;

  final ApiService _apiService;
  final WebSocketChannel Function(Uri uri) _channelFactory;
  final Duration _reconnectDelay;

  final StreamController<NotificationItem> _controller =
      StreamController<NotificationItem>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _reconnectTimer;
  bool _started = false;
  bool _disposed = false;

  Stream<NotificationItem> watchNotifications() {
    if (!_started) {
      _started = true;
      unawaited(_connect());
    }
    return _controller.stream;
  }

  Future<void> _connect() async {
    if (_disposed || _channelSubscription != null) {
      return;
    }

    await _apiService.initialize();
    final token = _apiService.token;
    if (token == null || token.isEmpty) {
      return;
    }

    final uri = buildNotificationWebSocketUri(
      baseUrl: ApiConfig.baseUrl,
      token: token,
    );
    final channel = _channelFactory(uri);
    _channel = channel;
    _channelSubscription = channel.stream.listen(
      _handleIncomingData,
      onError: (_) => _handleDisconnect(),
      onDone: _handleDisconnect,
      cancelOnError: true,
    );
  }

  void _handleIncomingData(dynamic data) {
    final notification = parseRealtimeNotificationPayload(data);
    if (notification != null && !_controller.isClosed) {
      _controller.add(notification);
    }
  }

  void _handleDisconnect() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;
    if (_disposed) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      unawaited(_connect());
    });
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _controller.close();
  }

  static Uri buildNotificationWebSocketUri({
    required String baseUrl,
    required String token,
  }) {
    final resolvedBase = baseUrl.isNotEmpty ? Uri.parse(baseUrl) : Uri.base;
    final scheme = resolvedBase.scheme == 'https' ? 'wss' : 'ws';
    return resolvedBase.replace(
      scheme: scheme,
      path: '/ws/notifications',
      queryParameters: {'token': token},
    );
  }

  static NotificationItem? parseRealtimeNotificationPayload(dynamic data) {
    if (data == null) {
      return null;
    }

    Map<String, dynamic>? payload;
    if (data is String) {
      if (data.trim().isEmpty || data.trim() == 'pong') {
        return null;
      }
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    } else if (data is Map<String, dynamic>) {
      payload = data;
    } else if (data is Map) {
      payload = Map<String, dynamic>.from(data);
    }

    if (payload == null) {
      return null;
    }

    final eventType = jsonAsNullableString(payload['type']) ?? '';
    if (eventType == 'connected' || eventType == 'subscribed') {
      return null;
    }

    final title = jsonAsNullableString(payload['title']) ??
        jsonAsNullableString(payload['message']) ??
        '';
    final body = jsonAsNullableString(payload['body']) ??
        jsonAsNullableString(payload['message']) ??
        title;

    if (title.isEmpty && body.isEmpty) {
      return null;
    }

    return NotificationItem.fromJson({
      ...payload,
      'id': jsonAsNullableString(payload['id']) ?? _buildSyntheticId(payload),
      'title': title,
      'body': body,
      'is_read': false,
      'time': DateTime.now().toIso8601String(),
    });
  }

  static String _buildSyntheticId(Map<String, dynamic> payload) {
    final eventType = jsonAsNullableString(payload['type']) ?? 'system';
    final orderId = jsonAsNullableString(payload['order_id']);
    final refId = jsonAsNullableString(payload['ref_id']);
    final titleKey = jsonAsNullableString(payload['title_key']);

    if (orderId != null) {
      return 'ws:$eventType:$orderId';
    }
    if (refId != null) {
      return 'ws:$eventType:$refId';
    }
    if (titleKey != null) {
      return 'ws:$eventType:$titleKey';
    }
    return 'ws:$eventType:${DateTime.now().microsecondsSinceEpoch}';
  }
}
