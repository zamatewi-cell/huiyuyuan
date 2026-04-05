import 'dart:io';

void main() {
  final localeKeys = _loadLocaleKeys();
  final parityIssues = _collectLocaleParityIssues(localeKeys);
  final duplicateMapKeyIssues = _collectDuplicateMapKeyIssues();
  final primaryMapLiteralIssues = _collectPrimaryMapLiteralIssues();
  final legacyCompatibilityKeys = _loadLegacyCompatibilityKeys();
  final newLegacyCompatibilityKeys = _collectNewLegacyCompatibilityKeys(
    legacyCompatibilityKeys,
  );
  final staleLegacyAllowlistEntries = _collectStaleLegacyAllowlistEntries(
    legacyCompatibilityKeys,
  );
  final missingKeyReferences = _collectMissingKeyReferences(
    localeKeys['zhCN'] ?? const <String>{},
  );
  final rawChineseWarnings = _collectRawChineseTranslationWarnings();
  final eagerDataWarnings = _collectEagerDataTranslationWarnings();

  stdout.writeln('I18n audit summary');
  stdout.writeln('===================');
  stdout.writeln('Locale parity issues: ${parityIssues.length}');
  stdout.writeln('Duplicate map keys: ${duplicateMapKeyIssues.length}');
  stdout
      .writeln('Primary map literal issues: ${primaryMapLiteralIssues.length}');
  stdout
      .writeln('Legacy compatibility keys: ${legacyCompatibilityKeys.length}');
  stdout.writeln(
    'New legacy compatibility keys: ${newLegacyCompatibilityKeys.length}',
  );
  stdout.writeln('Missing key references: ${missingKeyReferences.length}');
  stdout.writeln('Raw Chinese .tr warnings: ${rawChineseWarnings.length}');
  stdout.writeln('Top-level data .tr warnings: ${eagerDataWarnings.length}');

  if (parityIssues.isNotEmpty) {
    stdout.writeln('\n[FAIL] Locale parity');
    for (final issue in parityIssues) {
      stdout.writeln('- $issue');
    }
  }

  if (duplicateMapKeyIssues.isNotEmpty) {
    stdout.writeln('\n[FAIL] Duplicate translation keys');
    for (final issue in duplicateMapKeyIssues) {
      stdout.writeln('- $issue');
    }
  }

  if (missingKeyReferences.isNotEmpty) {
    stdout.writeln('\n[FAIL] Missing translation keys');
    for (final issue in missingKeyReferences) {
      stdout.writeln('- $issue');
    }
  }

  if (primaryMapLiteralIssues.isNotEmpty) {
    stdout.writeln('\n[FAIL] Primary locale maps contain non-stable keys');
    for (final issue in primaryMapLiteralIssues) {
      stdout.writeln('- $issue');
    }
  }

  if (newLegacyCompatibilityKeys.isNotEmpty) {
    stdout.writeln('\n[FAIL] Legacy compatibility allowlist grew');
    for (final issue in newLegacyCompatibilityKeys) {
      stdout.writeln('- $issue');
    }
  }

  if (rawChineseWarnings.isNotEmpty) {
    stdout
        .writeln('\n[WARN] Chinese literals translated directly in UI layers');
    for (final issue in rawChineseWarnings.take(30)) {
      stdout.writeln('- $issue');
    }
    if (rawChineseWarnings.length > 30) {
      stdout.writeln(
        '- ... ${rawChineseWarnings.length - 30} more warning(s) omitted',
      );
    }
  }

  if (eagerDataWarnings.isNotEmpty) {
    stdout.writeln('\n[WARN] Top-level .tr usage in lib/data');
    for (final issue in eagerDataWarnings) {
      stdout.writeln('- $issue');
    }
  }

  if (staleLegacyAllowlistEntries.isNotEmpty) {
    stdout
        .writeln('\n[WARN] Legacy compatibility allowlist contains stale keys');
    for (final issue in staleLegacyAllowlistEntries) {
      stdout.writeln('- $issue');
    }
  }

  if (parityIssues.isNotEmpty ||
      duplicateMapKeyIssues.isNotEmpty ||
      primaryMapLiteralIssues.isNotEmpty ||
      newLegacyCompatibilityKeys.isNotEmpty ||
      missingKeyReferences.isNotEmpty) {
    exitCode = 1;
    return;
  }

  stdout.writeln('\nAudit passed: no blocking i18n issues found.');
}

Map<String, Set<String>> _loadLocaleKeys() {
  final localeKeys = <String, Set<String>>{};
  for (final locale in ['zhCN', 'en', 'zhTW']) {
    localeKeys[locale] = _loadMapKeys('_$locale').where(_isStableKey).toSet();
  }

  return localeKeys;
}

List<String> _collectPrimaryMapLiteralIssues() {
  final issues = <String>[];
  for (final locale in ['zhCN', 'en', 'zhTW']) {
    final literalKeys = _loadMapKeys('_$locale')
        .where((key) => !_isStableKey(key))
        .toList()
      ..sort();
    for (final key in literalKeys) {
      issues.add('$locale -> $key');
    }
  }
  return issues;
}

Set<String> _loadLegacyCompatibilityKeys() {
  final keys = <String>{};
  for (final locale in [
    '_zhCNLegacyCompatibility',
    '_enLegacyCompatibility',
    '_zhTWLegacyCompatibility',
  ]) {
    keys.addAll(_loadMapKeys(locale).where((key) => !_isStableKey(key)));
  }
  return keys;
}

List<String> _collectNewLegacyCompatibilityKeys(Set<String> currentKeys) {
  final allowlist = _loadLegacyCompatibilityAllowlist();
  final additions = currentKeys.difference(allowlist).toList()..sort();
  return additions;
}

List<String> _collectStaleLegacyAllowlistEntries(Set<String> currentKeys) {
  final allowlist = _loadLegacyCompatibilityAllowlist();
  final stale = allowlist.difference(currentKeys).toList()..sort();
  return stale;
}

Set<String> _loadLegacyCompatibilityAllowlist() {
  final file = File('tool/i18n_legacy_literal_keys_allowlist.txt');
  if (!file.existsSync()) {
    return const <String>{};
  }

  return file
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

Set<String> _loadMapKeys(String mapName) {
  return _loadMapKeyOccurrences(mapName).keys.toSet();
}

Map<String, int> _loadMapKeyOccurrences(String mapName) {
  final file = File('lib/l10n/app_strings.dart');
  final content = file.readAsStringSync();
  final mapPattern = RegExp(
    'static const Map<String, String> ${RegExp.escape(mapName)} = \\{([\\s\\S]*?)\\};',
  );
  final keyPattern = RegExp(r"'([^']+)'\s*:");
  final match = mapPattern.firstMatch(content);
  if (match == null) {
    return const <String, int>{};
  }

  final keyCounts = <String, int>{};
  final body = match.group(1)!;
  for (final keyMatch in keyPattern.allMatches(body)) {
    final key = keyMatch.group(1)!;
    keyCounts[key] = (keyCounts[key] ?? 0) + 1;
  }
  return keyCounts;
}

List<String> _collectDuplicateMapKeyIssues() {
  final issues = <String>[];
  for (final mapName in [
    '_zhCN',
    '_en',
    '_zhTW',
    '_zhCNLegacyCompatibility',
    '_enLegacyCompatibility',
    '_zhTWLegacyCompatibility',
  ]) {
    final duplicates = _loadMapKeyOccurrences(mapName)
        .entries
        .where((entry) => entry.value > 1)
        .toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in duplicates) {
      issues.add('$mapName -> ${entry.key} (${entry.value}x)');
    }
  }
  return issues;
}

List<String> _collectLocaleParityIssues(Map<String, Set<String>> localeKeys) {
  final issues = <String>[];
  final baseKeys = localeKeys['zhCN'] ?? const <String>{};

  for (final entry in localeKeys.entries) {
    final missing = baseKeys.difference(entry.value).toList()..sort();
    final extra = entry.value.difference(baseKeys).toList()..sort();

    if (missing.isNotEmpty) {
      issues.add('${entry.key} missing keys: ${missing.join(', ')}');
    }
    if (extra.isNotEmpty) {
      issues.add('${entry.key} has extra keys: ${extra.join(', ')}');
    }
  }

  return issues;
}

List<String> _collectMissingKeyReferences(Set<String> knownKeys) {
  final issues = <String>[];
  final libDir = Directory('lib');
  final refPattern = RegExp(
    r"""ref\.tr\(\s*'([A-Za-z0-9_]+)'\s*(?:,|\))""",
  );
  final stringExtensionPattern = RegExp(
    r"""'([A-Za-z0-9_]+)'\.tr(?:Args)?\b""",
  );

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final normalizedPath = entity.path.replaceAll('\\', '/');
    if (normalizedPath.endsWith('/l10n/app_strings.dart')) {
      continue;
    }

    final content = entity.readAsStringSync();
    final referencedKeys = <String>{};

    for (final match in refPattern.allMatches(content)) {
      referencedKeys.add(match.group(1)!);
    }
    for (final match in stringExtensionPattern.allMatches(content)) {
      referencedKeys.add(match.group(1)!);
    }

    final missingKeys = referencedKeys
        .where((key) => _isStableKey(key) && !knownKeys.contains(key))
        .toList()
      ..sort();
    for (final key in missingKeys) {
      issues.add('$normalizedPath -> $key');
    }
  }

  return issues;
}

List<String> _collectRawChineseTranslationWarnings() {
  final warnings = <String>[];
  final roots = [
    Directory('lib/app'),
    Directory('lib/screens'),
    Directory('lib/widgets'),
  ];
  final pattern = RegExp(r"""'([^']*[\u4e00-\u9fff][^']*)'\.tr(?:Args)?\b""");

  for (final root in roots) {
    if (!root.existsSync()) {
      continue;
    }

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final normalizedPath = entity.path.replaceAll('\\', '/');
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (pattern.hasMatch(lines[index])) {
          warnings.add('$normalizedPath:${index + 1}');
        }
      }
    }
  }

  return warnings;
}

List<String> _collectEagerDataTranslationWarnings() {
  final warnings = <String>[];
  final dataDir = Directory('lib/data');
  final pattern = RegExp(r'\.tr(?:Args)?\b');

  if (!dataDir.existsSync()) {
    return warnings;
  }

  for (final entity in dataDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final normalizedPath = entity.path.replaceAll('\\', '/');
    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (pattern.hasMatch(lines[index])) {
        warnings.add('$normalizedPath:${index + 1}');
      }
    }
  }

  return warnings;
}

bool _isStableKey(String key) => RegExp(r'^[A-Za-z0-9_]+$').hasMatch(key);
