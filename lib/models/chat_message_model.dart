/// 汇玉源 - 聊天消息模型
library;

import 'dart:typed_data';

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  /// 消息类型（text, image, voice, system, product_card）
  final String type;

  /// 附件URL
  final String? attachmentUrl;

  /// 图片内存字节（用于 Web 兼容，避免 Image.file 崩溃）
  final Uint8List? imageBytes;

  /// AI 推荐的商品 ID 列表（类型为 product_card 时使用）
  final List<String>? productIds;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = 'text',
    this.attachmentUrl,
    this.imageBytes,
    this.productIds,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
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
