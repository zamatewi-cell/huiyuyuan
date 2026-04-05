library;

import 'translator_global.dart';

/// 汇玉源 - String 原生扩展语法糖
///
/// 允许在无法直接拿到 WidgetRef 的位置使用 `translation_key.tr` 读取翻译。
/// 这里只支持 key 查询，不支持把任意中文字面量反向翻译成其他语言。
extension StringTr on String {
  /// 将当前字符串作为 key 或默认中文文本进行翻译
  String get tr {
    return TranslatorGlobal.instance.translate(this);
  }

  String trArgs(Map<String, Object?> params) {
    return TranslatorGlobal.instance.translate(this, params: params);
  }
}
