#!/usr/bin/env dart
// ignore_for_file: avoid_print
/// 汇玉源 i18n 反模式检测工具
///
/// 用法：
///   dart run tool/lint_i18n.dart
///   dart run tool/lint_i18n.dart --strict      # 裸中文也计入退出码
///   dart run tool/lint_i18n.dart lib/screens   # 仅扫描指定目录
///
/// 退出码：
///   0 — 无违规
///   1 — 发现废弃 API 或高风险反模式
library;

import 'dart:io';

// ──────────────────────────────────────────────
// 规则定义
// ──────────────────────────────────────────────

/// 每条规则的严重级别。
enum Severity {
  /// 必须修复：会导致语言切换时 Widget 不刷新。
  error,

  /// 建议修复：代码气味，不影响当前正确性。
  warning,

  /// 仅提示：可能是误报。
  info,
}

class LintRule {
  const LintRule({
    required this.id,
    required this.description,
    required this.pattern,
    required this.severity,
    this.hint = '',
  });

  final String id;
  final String description;
  final RegExp pattern;
  final Severity severity;
  final String hint;
}

final List<LintRule> _rules = [
  LintRule(
    id: 'I18N001',
    description: '使用了废弃的 String.tr 扩展（Widget 层不响应语言切换）',
    pattern: RegExp(r"""['"][^'"]+['"]\.tr(?!Args)\b"""),
    severity: Severity.error,
    hint: '改用 ref.tr("key")（需要 WidgetRef），'
        '或在服务层保留并暂时忽略警告',
  ),
  LintRule(
    id: 'I18N002',
    description: '使用了废弃的 String.trArgs 扩展',
    pattern: RegExp(r"""['"][^'"]+['"]\.trArgs\("""),
    severity: Severity.error,
    hint: '改用 ref.tr("key", params: {...})',
  ),
  LintRule(
    id: 'I18N003',
    description: '访问了废弃的 product.titleL10n 静态 getter',
    pattern: RegExp(r'\bproduct\.\btitleL10n\b'),
    severity: Severity.error,
    hint: '改用 product.localizedTitleFor(lang)，'
        'lang 来自 ref.watch(appSettingsProvider).language',
  ),
  LintRule(
    id: 'I18N004',
    description: '访问了废弃的 product.matL10n 静态 getter',
    pattern: RegExp(r'\bproduct\.\bmatL10n\b'),
    severity: Severity.error,
    hint: '改用 product.localizedMaterialFor(lang)',
  ),
  LintRule(
    id: 'I18N005',
    description: '访问了废弃的 product.catL10n 静态 getter',
    pattern: RegExp(r'\bproduct\.\bcatL10n\b'),
    severity: Severity.error,
    hint: '改用 product.localizedCategoryFor(lang)',
  ),
  LintRule(
    id: 'I18N006',
    description: '访问了废弃的 product.descL10n 静态 getter',
    pattern: RegExp(r'\bproduct\.\bdescL10n\b'),
    severity: Severity.error,
    hint: '改用 product.localizedDescriptionFor(lang)',
  ),
  LintRule(
    id: 'I18N007',
    description: '访问了废弃的 product.originL10n 静态 getter',
    pattern: RegExp(r'\bproduct\.\boriginL10n\b'),
    severity: Severity.error,
    hint: '改用 product.localizedOriginFor(lang)',
  ),
  LintRule(
    id: 'I18N008',
    description: '访问了废弃的 product.materialVerifyL10n 静态 getter',
    pattern: RegExp(r'\bproduct\.\bmaterialVerifyL10n\b'),
    severity: Severity.error,
    hint: '改用 product.localizedMaterialVerifyFor(lang)',
  ),
  LintRule(
    id: 'I18N009',
    description: '直接读取 TranslatorGlobal.currentLang（非服务层慎用）',
    pattern: RegExp(r'TranslatorGlobal\.currentLang'),
    severity: Severity.warning,
    hint: '在 Widget 里改用 ref.watch(appSettingsProvider).language',
  ),
  LintRule(
    id: 'I18N010',
    description: '使用 _copyByLanguage 内联三语切换（已废弃模式）',
    pattern: RegExp(r'\b_copyByLanguage\s*\('),
    severity: Severity.warning,
    hint: '将字符串移入 AppStrings 并改用 ref.tr("key")',
  ),
  LintRule(
    id: 'I18N011',
    description: 'MaterialApp 使用了 key: ValueKey 整树重建（已移除，无需再加）',
    pattern: RegExp(r'MaterialApp\([\s\S]*?key:\s*ValueKey'),
    severity: Severity.error,
    hint: '语言切换依赖 Riverpod appSettingsProvider，无需 ValueKey',
  ),
  // 裸中文仅在 --strict 模式下退出码为 1
  LintRule(
    id: 'I18N012',
    description: '硬编码中文字面量（排除注释行）',
    pattern: RegExp(r'''(?<![//].*?)['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''),
    severity: Severity.info,
    hint: '将中文文本提取为 AppStrings key，并在三语 map 中补充翻译',
  ),
];

// ──────────────────────────────────────────────
// 扫描逻辑
// ──────────────────────────────────────────────

class Violation {
  final String file;
  final int line;
  final String column;
  final LintRule rule;
  final String snippet;

  const Violation({
    required this.file,
    required this.line,
    required this.column,
    required this.rule,
    required this.snippet,
  });
}

LintRule _effectiveRuleForFile(LintRule rule, String filePath) {
  final normalized = filePath.replaceAll('\\', '/');
  final isNonWidgetLayer = normalized.startsWith('lib/services/') ||
      normalized.startsWith('lib/repositories/') ||
      normalized.startsWith('lib/providers/') ||
      normalized.contains('/lib/services/') ||
      normalized.contains('/lib/repositories/') ||
      normalized.contains('/lib/providers/');

  if (isNonWidgetLayer && (rule.id == 'I18N001' || rule.id == 'I18N002')) {
    return LintRule(
      id: rule.id,
      description: '${rule.description}（非 Widget 层暂按 warning 迁移）',
      pattern: rule.pattern,
      severity: Severity.warning,
      hint: rule.hint,
    );
  }

  return rule;
}

List<Violation> scanFile(File file, List<LintRule> rules) {
  final violations = <Violation>[];
  final lines = file.readAsLinesSync();

  for (var i = 0; i < lines.length; i++) {
    final rawLine = lines[i];
    // 跳过纯注释行
    final trimmed = rawLine.trimLeft();
    final isCommentLine = trimmed.startsWith('//') || trimmed.startsWith('*');

    for (final rule in rules) {
      if (rule.id == 'I18N012' && isCommentLine) continue;

      final matches = rule.pattern.allMatches(rawLine);
      for (final match in matches) {
        final effectiveRule = _effectiveRuleForFile(rule, file.path);
        violations.add(Violation(
          file: file.path,
          line: i + 1,
          column: (match.start + 1).toString(),
          rule: effectiveRule,
          snippet: rawLine.trim(),
        ));
      }
    }
  }
  return violations;
}

List<Violation> scanDirectory(
  Directory dir,
  List<LintRule> rules, {
  Set<String>? skipIds,
}) {
  final violations = <Violation>[];
  final dartFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // 不扫描工具自身、AppStrings 定义、ProductModel 定义
      .where((f) => !f.path.contains('lint_i18n.dart'))
      .where((f) => !f.path.contains('app_strings.dart'))
      .where((f) => !f.path.contains('product_model.dart'))
      .where((f) => !f.path.contains('string_extension.dart'));

  final activeRules = skipIds == null
      ? rules
      : rules.where((r) => !skipIds.contains(r.id)).toList();

  for (final file in dartFiles) {
    violations.addAll(scanFile(file, activeRules));
  }
  return violations;
}

// ──────────────────────────────────────────────
// CLI 入口
// ──────────────────────────────────────────────

void main(List<String> args) {
  final strict = args.contains('--strict');
  final targetPaths = args.where((a) => !a.startsWith('--')).toList();

  // 不展示 I18N012（裸中文）除非 --strict
  final skipIds = strict ? <String>{} : {'I18N012'};

  final roots = targetPaths.isEmpty
      ? [Directory('lib')]
      : targetPaths.map(Directory.new).toList();

  final allViolations = <Violation>[];
  for (final root in roots) {
    if (!root.existsSync()) {
      print('⚠  目录不存在：${root.path}，已跳过');
      continue;
    }
    allViolations.addAll(scanDirectory(root, _rules, skipIds: skipIds));
  }

  if (allViolations.isEmpty) {
    print('✅ lint_i18n：未发现违规');
    exit(0);
  }

  // 按文件分组输出
  final byFile = <String, List<Violation>>{};
  for (final v in allViolations) {
    byFile.putIfAbsent(v.file, () => []).add(v);
  }

  int errors = 0;
  int warnings = 0;
  int infos = 0;

  for (final entry in byFile.entries) {
    print('\n📄 ${entry.key}');
    for (final v in entry.value) {
      final icon = switch (v.rule.severity) {
        Severity.error => '❌',
        Severity.warning => '⚠️ ',
        Severity.info => 'ℹ️ ',
      };
      print('  $icon [${v.rule.id}] ${v.rule.description}');
      print('     行 ${v.line}:${v.column}  ${v.snippet}');
      if (v.rule.hint.isNotEmpty) {
        print('     💡 ${v.rule.hint}');
      }
      switch (v.rule.severity) {
        case Severity.error:
          errors++;
        case Severity.warning:
          warnings++;
        case Severity.info:
          infos++;
      }
    }
  }

  print('\n─────────────────────────────────────────');
  print('汇总：$errors 个错误 / $warnings 个警告 / $infos 个提示');
  print('运行 `dart run tool/lint_i18n.dart --strict` 以同时检测裸中文。');

  if (errors > 0 || (strict && infos > 0)) {
    exit(1);
  }
}
