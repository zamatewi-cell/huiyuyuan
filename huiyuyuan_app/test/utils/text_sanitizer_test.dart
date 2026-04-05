import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/utils/text_sanitizer.dart';

void main() {
  test('removes lone high surrogate', () {
    final malformed = String.fromCharCodes([0x41, 0xD800, 0x42]);

    expect(hasMalformedUtf16(malformed), isTrue);
    expect(sanitizeUtf16(malformed), 'AB');
  });

  test('removes lone low surrogate', () {
    final malformed = String.fromCharCodes([0x41, 0xDC00, 0x42]);

    expect(hasMalformedUtf16(malformed), isTrue);
    expect(sanitizeUtf16(malformed), 'AB');
  });

  test('keeps valid surrogate pairs', () {
    final validPair = String.fromCharCodes([0xD83D, 0xDE0A]);

    expect(hasMalformedUtf16(validPair), isFalse);
    expect(sanitizeUtf16(validPair), validPair);
  });
}
