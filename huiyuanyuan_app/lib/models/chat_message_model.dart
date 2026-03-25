library;

import 'dart:typed_data';

import '../utils/text_sanitizer.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String type;
  final String? attachmentUrl;
  final Uint8List? imageBytes;
  final List<String>? productIds;

  ChatMessage({
    required String id,
    required String content,
    required this.isUser,
    required this.timestamp,
    String type = 'text',
    String? attachmentUrl,
    this.imageBytes,
    List<String>? productIds,
  })  : id = sanitizeUtf16(id),
        content = sanitizeUtf16(content),
        type = sanitizeUtf16(type),
        attachmentUrl =
            attachmentUrl == null ? null : sanitizeUtf16(attachmentUrl),
        productIds = productIds?.map(sanitizeUtf16).toList(growable: false);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String? ?? 'text',
      attachmentUrl: json['attachmentUrl'] as String?,
      productIds: (json['productIds'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (productIds != null) 'productIds': productIds,
    };
  }
}
