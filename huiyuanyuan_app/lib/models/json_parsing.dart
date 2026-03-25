library;

import '../utils/text_sanitizer.dart';

String jsonAsString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return sanitizeUtf16(value);
  return sanitizeUtf16(value.toString());
}

String? jsonAsNullableString(dynamic value) {
  if (value == null) return null;
  final result = jsonAsString(value).trim();
  return result.isEmpty ? null : result;
}

int jsonAsInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? jsonAsNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is String && value.trim().isEmpty) return null;
  return jsonAsInt(value);
}

double jsonAsDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? jsonAsNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is String && value.trim().isEmpty) return null;
  return jsonAsDouble(value);
}

bool jsonAsBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'n':
      case 'off':
        return false;
    }
  }
  return fallback;
}

DateTime? jsonAsNullableDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}

DateTime jsonAsDateTime(dynamic value, {DateTime? fallback}) {
  return jsonAsNullableDateTime(value) ?? fallback ?? DateTime.now();
}

Map<String, dynamic> jsonAsMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

Map<String, dynamic>? jsonAsNullableMap(dynamic value) {
  if (value == null) return null;
  final result = jsonAsMap(value);
  return result.isEmpty ? null : result;
}

List<String> jsonAsStringList(dynamic value) {
  if (value is! Iterable) return const [];
  return value.map((item) => jsonAsString(item)).toList();
}

List<T> jsonAsList<T>(dynamic value, T Function(dynamic item) mapper) {
  if (value is! Iterable) return const [];
  return value.map(mapper).toList();
}

T jsonEnumByName<T extends Enum>(
  List<T> values,
  dynamic value, {
  required T fallback,
}) {
  final raw = jsonAsNullableString(value);
  if (raw == null) return fallback;
  return values.firstWhere(
    (entry) => entry.name == raw,
    orElse: () => fallback,
  );
}
