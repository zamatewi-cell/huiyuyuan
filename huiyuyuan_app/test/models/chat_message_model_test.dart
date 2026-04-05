import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/chat_message_model.dart';

void main() {
  test('sanitizes malformed content in constructor', () {
    final malformed = String.fromCharCodes([0xD800, 0x41]);

    final message = ChatMessage(
      id: 'msg-1',
      content: malformed,
      isUser: false,
      timestamp: DateTime.parse('2026-03-23T00:00:00.000Z'),
    );

    expect(message.content, 'A');
    expect(message.toJson()['content'], 'A');
  });

  test('sanitizes malformed content from json', () {
    final malformed = String.fromCharCodes([0x41, 0xDC00, 0x42]);

    final message = ChatMessage.fromJson({
      'id': 'msg-2',
      'content': malformed,
      'isUser': true,
      'timestamp': '2026-03-23T00:00:00.000Z',
    });

    expect(message.content, 'AB');
  });
}
