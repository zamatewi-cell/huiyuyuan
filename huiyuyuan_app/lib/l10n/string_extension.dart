library;

import 'translator_global.dart';

/// 汇玉源 - String 原生扩展语法糖
///
/// ⚠️ **废弃方向**：
/// - 在 Widget 中请改用 `ref.tr(...)` (来自 `l10n/l10n_provider.dart`)，
///   因为 `ref.tr` 订阅 `appSettingsProvider`，语言切换时 Widget 会自动重建。
/// - `String.tr` 读取 `TranslatorGlobal.currentLang` 静态字段，Widget 调用它
///   时**不会**随语言切换而刷新，必须靠 MaterialApp 整树重建作弊（已移除）。
/// - 在服务层 / Provider / 非 Widget 上下文中，`String.tr` 仍然可用，
///   因为这些位置由语言变化事件主动触发，不依赖 Widget 重建。
extension StringTr on String {
  /// 将当前字符串作为 key 查询当前语言的翻译。
  ///
  /// **Widget 中已废弃**：改用 `ref.tr(...)`。
  /// 服务层 / Provider 中可继续使用。
  @Deprecated(
    'Use ref.tr(...) inside widgets. '
    'String.tr reads a static field and will not trigger widget rebuilds '
    'when the language changes.',
  )
  String get tr {
    return TranslatorGlobal.instance.translate(this);
  }

  /// 带插值参数版本。Widget 中请改用 `ref.tr(..., params: {...})`。
  @Deprecated(
    'Use ref.tr(..., params: {...}) inside widgets.',
  )
  String trArgs(Map<String, Object?> params) {
    return TranslatorGlobal.instance.translate(this, params: params);
  }
}
