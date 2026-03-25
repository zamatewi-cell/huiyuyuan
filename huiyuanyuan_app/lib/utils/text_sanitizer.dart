library;

bool hasMalformedUtf16(String input) {
  final units = input.codeUnits;
  for (var index = 0; index < units.length; index++) {
    final unit = units[index];
    if (_isHighSurrogate(unit)) {
      if (index + 1 >= units.length || !_isLowSurrogate(units[index + 1])) {
        return true;
      }
      index++;
      continue;
    }
    if (_isLowSurrogate(unit)) {
      return true;
    }
  }
  return false;
}

String sanitizeUtf16(String input, {String replacement = ''}) {
  if (input.isEmpty || !hasMalformedUtf16(input)) {
    return input;
  }

  final buffer = StringBuffer();
  final units = input.codeUnits;
  for (var index = 0; index < units.length; index++) {
    final unit = units[index];
    if (_isHighSurrogate(unit)) {
      if (index + 1 < units.length && _isLowSurrogate(units[index + 1])) {
        buffer.writeCharCode(unit);
        buffer.writeCharCode(units[index + 1]);
        index++;
        continue;
      }
      if (replacement.isNotEmpty) {
        buffer.write(replacement);
      }
      continue;
    }
    if (_isLowSurrogate(unit)) {
      if (replacement.isNotEmpty) {
        buffer.write(replacement);
      }
      continue;
    }
    buffer.writeCharCode(unit);
  }
  return buffer.toString();
}

bool _isHighSurrogate(int value) => value >= 0xD800 && value <= 0xDBFF;

bool _isLowSurrogate(int value) => value >= 0xDC00 && value <= 0xDFFF;
