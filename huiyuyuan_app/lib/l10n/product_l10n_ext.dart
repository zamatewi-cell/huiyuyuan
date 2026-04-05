/// 汇玉源 - 商品模型多语言扩展
///
/// 根据当前语言设置，返回后端翻译好的字段。
/// 如果翻译字段为空，自动回退到中文原文。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../providers/app_settings_provider.dart';

/// 商品多语言翻译扩展
extension ProductModelL10n on ProductModel {
  /// 翻译后的商品名
  String localizedName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return nameEn ?? name;
      case AppLanguage.zhTW:
        return nameZhTw ?? name;
      case AppLanguage.zhCN:
        return name;
    }
  }

  /// 翻译后的商品描述
  String localizedDescription(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return descriptionEn ?? description;
      case AppLanguage.zhTW:
        return descriptionZhTw ?? description;
      case AppLanguage.zhCN:
        return description;
    }
  }

  /// 翻译后的材质
  String localizedMaterial(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return materialEn ?? material;
      case AppLanguage.zhTW:
        return materialZhTw ?? material;
      case AppLanguage.zhCN:
        return material;
    }
  }

  /// 翻译后的分类
  String localizedCategory(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return categoryEn ?? category;
      case AppLanguage.zhTW:
        return categoryZhTw ?? category;
      case AppLanguage.zhCN:
        return category;
    }
  }

  /// 翻译后的产地
  String localizedOrigin(AppLanguage lang) {
    if (origin == null) return '';
    switch (lang) {
      case AppLanguage.en:
        return originEn ?? origin!;
      case AppLanguage.zhTW:
        return originZhTw ?? origin!;
      case AppLanguage.zhCN:
        return origin!;
    }
  }

  /// 翻译后的材质验证状态
  String localizedMaterialVerify(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return materialVerifyEn ?? materialVerify;
      case AppLanguage.zhTW:
        return materialVerifyZhTw ?? materialVerify;
      case AppLanguage.zhCN:
        return materialVerify;
    }
  }
}

/// 用于在 Widget 中快速获取当前语言
AppLanguage currentLang(WidgetRef ref) =>
    ref.watch(appSettingsProvider).language;
