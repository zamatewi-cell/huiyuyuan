import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/l10n/app_strings.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';

void main() {
  group('I18n guardrails', () {
    test('all locales keep the same translation keys', () {
      final baseKeys =
          AppStrings.of(AppLanguage.zhCN).keys.where(_isStableKey).toSet();

      for (final language in AppLanguage.values) {
        final currentKeys =
            AppStrings.of(language).keys.where(_isStableKey).toSet();
        final missing = baseKeys.difference(currentKeys).toList()..sort();
        final extra = currentKeys.difference(baseKeys).toList()..sort();

        expect(
          missing,
          isEmpty,
          reason: '$language is missing translation keys: $missing',
        );
        expect(
          extra,
          isEmpty,
          reason: '$language has unexpected translation keys: $extra',
        );
      }
    });

    test('translation source maps do not contain duplicate keys', () {
      final duplicatesByMap = _collectDuplicateMapKeys();

      expect(
        duplicatesByMap,
        isEmpty,
        reason: _formatDuplicateKeyReport(duplicatesByMap),
      );
    });

    test('identifier-style translation references exist in AppStrings', () {
      final knownKeys =
          AppStrings.of(AppLanguage.zhCN).keys.where(_isStableKey).toSet();
      final missingByFile = <String, List<String>>{};
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
            .where((key) => !knownKeys.contains(key))
            .toList()
          ..sort();
        if (missingKeys.isNotEmpty) {
          missingByFile[normalizedPath] = missingKeys;
        }
      }

      expect(
        missingByFile,
        isEmpty,
        reason: _formatMissingKeyReport(missingByFile),
      );
    });

    test('primary locale maps only contain stable keys', () {
      for (final language in AppLanguage.values) {
        final nonStableKeys = AppStrings.of(language)
            .keys
            .where((key) => !_isStableKey(key))
            .toList()
          ..sort();

        expect(
          nonStableKeys,
          isEmpty,
          reason:
              '$language primary locale map still contains legacy literal keys: '
              '$nonStableKeys',
        );
      }
    });

    test('legacy compatibility keys stay within the frozen allowlist', () {
      final allowlist = File('tool/i18n_legacy_literal_keys_allowlist.txt')
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toSet();

      final currentLegacyKeys = <String>{};
      for (final language in AppLanguage.values) {
        currentLegacyKeys.addAll(
          AppStrings.legacyCompatibilityOf(language).keys.where(
                (key) => !_isStableKey(key),
              ),
        );
      }

      final additions = currentLegacyKeys.difference(allowlist).toList()
        ..sort();

      expect(
        additions,
        isEmpty,
        reason: 'Legacy compatibility allowlist grew unexpectedly: $additions',
      );
    });
  });
}

bool _isStableKey(String key) => RegExp(r'^[A-Za-z0-9_]+$').hasMatch(key);

Map<String, List<String>> _collectDuplicateMapKeys() {
  final duplicatesByMap = <String, List<String>>{};
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
        .map((entry) => '${entry.key} (${entry.value}x)')
        .toList()
      ..sort();

    if (duplicates.isNotEmpty) {
      duplicatesByMap[mapName] = duplicates;
    }
  }
  return duplicatesByMap;
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

  final counts = <String, int>{};
  final body = match.group(1)!;
  for (final keyMatch in keyPattern.allMatches(body)) {
    final key = keyMatch.group(1)!;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

String _formatMissingKeyReport(Map<String, List<String>> missingByFile) {
  if (missingByFile.isEmpty) {
    return 'No missing translation keys.';
  }

  final buffer = StringBuffer(
    'Some translation keys are referenced in code but missing from AppStrings:\n',
  );

  final entries = missingByFile.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (final entry in entries) {
    buffer.writeln('- ${entry.key}: ${entry.value.join(', ')}');
  }

  return buffer.toString().trimRight();
}

String _formatDuplicateKeyReport(Map<String, List<String>> duplicatesByMap) {
  if (duplicatesByMap.isEmpty) {
    return 'No duplicate translation keys.';
  }

  final buffer = StringBuffer(
    'Some translation maps contain duplicate keys:\n',
  );

  final entries = duplicatesByMap.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (final entry in entries) {
    buffer.writeln('- ${entry.key}: ${entry.value.join(', ')}');
  }

  return buffer.toString().trimRight();
}
