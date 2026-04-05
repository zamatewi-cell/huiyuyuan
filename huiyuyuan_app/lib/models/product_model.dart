/// HuiYuYuan product model.
library;

import 'package:flutter/material.dart';
import 'json_parsing.dart';

import '../l10n/app_strings.dart';
import '../l10n/product_translator.dart';
import '../l10n/translator_global.dart';
import '../providers/app_settings_provider.dart';

extension LocalizedProductModel on ProductModel {
  String get titleL10n => localizedTitleFor(TranslatorGlobal.currentLang);

  String localizedTitleFor(AppLanguage lang) {
    if (lang == AppLanguage.en) {
      return _resolveEnglish(
        source: name,
        localized: nameEn,
        translated: ProductTranslator.translateName(
          AppLanguage.en,
          name,
          allowExact: false,
        ),
        fallback: _buildEnglishFallbackName(),
      );
    }
    if (lang == AppLanguage.zhTW) {
      return _resolveLocalized(
        source: name,
        localized: nameZhTw,
        language: AppLanguage.zhTW,
        translated: ProductTranslator.translateName(
          AppLanguage.zhTW,
          name,
          allowExact: false,
        ),
      );
    }
    return name;
  }

  String get descL10n => localizedDescriptionFor(TranslatorGlobal.currentLang);

  String localizedDescriptionFor(AppLanguage lang) {
    if (lang == AppLanguage.en) {
      return _resolveEnglish(
        source: description,
        localized: descriptionEn,
        translated: ProductTranslator.translateDescription(
          AppLanguage.en,
          description,
          allowExact: false,
        ),
        fallback: _buildEnglishFallbackDescription(lang: lang),
        description: true,
      );
    }
    if (lang == AppLanguage.zhTW) {
      return _resolveLocalized(
        source: description,
        localized: descriptionZhTw,
        language: AppLanguage.zhTW,
        translated: ProductTranslator.translateDescription(
          AppLanguage.zhTW,
          description,
          allowExact: false,
        ),
      );
    }
    return description;
  }

  String get matL10n => localizedMaterialFor(TranslatorGlobal.currentLang);

  String localizedMaterialFor(AppLanguage lang) {
    if (lang == AppLanguage.en) {
      return _resolveEnglish(
        source: material,
        localized: materialEn,
        translated: ProductTranslator.translateMaterial(
          AppLanguage.en,
          material,
          allowExact: false,
        ),
        fallback: ProductTranslator.translateMaterial(
          AppLanguage.en,
          ProductTranslator.canonicalMaterial(material),
          allowExact: false,
        ),
      );
    }
    if (lang == AppLanguage.zhTW) {
      return _resolveLocalized(
        source: material,
        localized: materialZhTw,
        language: AppLanguage.zhTW,
        translated: ProductTranslator.translateMaterial(
          AppLanguage.zhTW,
          material,
          allowExact: false,
        ),
      );
    }
    return material;
  }

  String get catL10n => localizedCategoryFor(TranslatorGlobal.currentLang);

  String localizedCategoryFor(AppLanguage lang) {
    if (lang == AppLanguage.en) {
      return _resolveEnglish(
        source: category,
        localized: categoryEn,
        translated: ProductTranslator.translateCategory(
          AppLanguage.en,
          category,
          allowExact: false,
        ),
        fallback: ProductTranslator.translateCategory(
          AppLanguage.en,
          ProductTranslator.canonicalCategory(category),
          allowExact: false,
        ),
      );
    }
    if (lang == AppLanguage.zhTW) {
      return _resolveLocalized(
        source: category,
        localized: categoryZhTw,
        language: AppLanguage.zhTW,
        translated: ProductTranslator.translateCategory(
          AppLanguage.zhTW,
          category,
          allowExact: false,
        ),
      );
    }
    return category;
  }

  String get originL10n => localizedOriginFor(TranslatorGlobal.currentLang);

  String localizedOriginFor(AppLanguage lang) {
    if (origin == null || origin!.trim().isEmpty) {
      return '';
    }
    if (lang == AppLanguage.en) {
      final sourceText = origin!.trim();
      final directTranslation = ProductTranslator.translateOrigin(
        AppLanguage.en,
        origin,
        allowExact: false,
      );
      final exactTranslation =
          AppStrings.lookup(AppLanguage.en, sourceText)?.trim();
      final storedTranslation = originEn?.trim();

      for (final candidate in <String?>[
        directTranslation,
        exactTranslation,
        storedTranslation,
      ]) {
        final normalized = ProductTranslator.normalizeLocalizedText(
          AppLanguage.en,
          candidate ?? '',
        );
        if (normalized.isNotEmpty &&
            normalized != sourceText &&
            !ProductTranslator.containsChinese(normalized)) {
          return normalized;
        }
      }

      return _resolveEnglish(
        source: sourceText,
        localized: storedTranslation,
        translated: directTranslation,
      );
    }
    if (lang == AppLanguage.zhTW) {
      return _resolveLocalized(
        source: origin!,
        localized: originZhTw,
        language: AppLanguage.zhTW,
        translated: ProductTranslator.translateOrigin(
          AppLanguage.zhTW,
          origin,
          allowExact: false,
        ),
      );
    }
    return origin!;
  }

  String get materialVerifyL10n =>
      localizedMaterialVerifyFor(TranslatorGlobal.currentLang);

  String localizedMaterialVerifyFor(AppLanguage lang) {
    if (lang == AppLanguage.en) {
      return _resolveEnglish(
        source: materialVerify,
        localized: materialVerifyEn,
        translated: ProductTranslator.translateMaterialVerify(
          AppLanguage.en,
          materialVerify,
          allowExact: false,
        ),
      );
    }
    if (lang == AppLanguage.zhTW) {
      return _resolveLocalized(
        source: materialVerify,
        localized: materialVerifyZhTw,
        language: AppLanguage.zhTW,
        translated: ProductTranslator.translateMaterialVerify(
          AppLanguage.zhTW,
          materialVerify,
          allowExact: false,
        ),
      );
    }
    return materialVerify;
  }

  String _resolveEnglish({
    required String source,
    required String? localized,
    required String translated,
    String? fallback,
    bool description = false,
  }) {
    final sourceText = source.trim();
    final candidates = <String?>[
      AppStrings.lookup(AppLanguage.en, sourceText),
      localized,
      translated,
      fallback,
    ];

    String? best;
    var bestScore = -1 << 20;
    final cleanFallback = ProductTranslator.normalizeLocalizedText(
      AppLanguage.en,
      fallback?.trim() ?? '',
      description: description,
    );

    for (final candidate in candidates) {
      final normalized = ProductTranslator.normalizeLocalizedText(
        AppLanguage.en,
        candidate?.trim() ?? '',
        description: description,
      );
      if (normalized.isEmpty || normalized == sourceText) {
        continue;
      }

      final score = _scoreEnglishCandidate(
        normalized,
        sourceText,
        description: description,
      );
      if (score > bestScore) {
        best = normalized;
        bestScore = score;
      }
    }

    if (best != null && best.isNotEmpty) {
      if (cleanFallback.isNotEmpty) {
        final fallbackScore = _scoreEnglishCandidate(
          cleanFallback,
          sourceText,
          description: description,
        );
        if (fallbackScore >= bestScore) {
          return cleanFallback;
        }
      }
      return best;
    }

    if (cleanFallback.isNotEmpty) {
      return cleanFallback;
    }

    return sourceText;
  }

  String _resolveLocalized({
    required String source,
    required String? localized,
    required AppLanguage language,
    required String translated,
    String? fallback,
  }) {
    final sourceText = source.trim();
    final exact = AppStrings.lookup(language, sourceText)?.trim();
    if (exact != null && exact.isNotEmpty && exact != sourceText) {
      return ProductTranslator.normalizeLocalizedText(
        language,
        exact,
        description: sourceText.length > 24,
      );
    }

    final text = localized?.trim();
    final generated = translated.trim();
    if (_shouldPreferGenerated(text, generated, sourceText)) {
      return ProductTranslator.normalizeLocalizedText(
        language,
        generated,
        description: sourceText.length > 24,
      );
    }

    if (text != null && text.isNotEmpty && text != sourceText) {
      return ProductTranslator.normalizeLocalizedText(
        language,
        text,
        description: sourceText.length > 24,
      );
    }

    if (generated.isNotEmpty && generated != sourceText) {
      return ProductTranslator.normalizeLocalizedText(
        language,
        generated,
        description: sourceText.length > 24,
      );
    }

    final resolvedFallback = fallback?.trim();
    if (resolvedFallback != null &&
        resolvedFallback.isNotEmpty &&
        resolvedFallback != sourceText) {
      return ProductTranslator.normalizeLocalizedText(
        language,
        resolvedFallback,
        description: sourceText.length > 24,
      );
    }

    return sourceText;
  }

  int _scoreEnglishCandidate(
    String candidate,
    String sourceText, {
    required bool description,
  }) {
    var score = 0;
    final chineseCount = ProductTranslator.chineseCharCount(candidate);
    score -= chineseCount * 120;

    if (!ProductTranslator.containsChinese(candidate)) {
      score += 240;
    }
    if (candidate != sourceText) {
      score += 25;
    }
    if (RegExp(r'[A-Za-z]').hasMatch(candidate)) {
      score += 30;
    }
    if (!description && candidate.split(RegExp(r'\s+')).length >= 2) {
      score += 12;
    }
    if (description && candidate.length >= 36) {
      score += 25;
    }
    if (!description && RegExp(r'^[A-Z0-9]').hasMatch(candidate)) {
      score += 12;
    }
    if (!description && RegExp(r'^[a-z]').hasMatch(candidate)) {
      score -= 18;
    }
    if (RegExp(r'[a-z][A-Z]').hasMatch(candidate)) {
      score -= 24;
    }
    if (RegExp(r'[\u4e00-\u9fff][A-Za-z]|[A-Za-z][\u4e00-\u9fff]')
        .hasMatch(candidate)) {
      score -= 60;
    }
    if (RegExp(r'\bbrand\b', caseSensitive: false).hasMatch(candidate)) {
      score -= 18;
    }
    if (RegExp(
      r'\bbeads bracelet\b|\bbuddha beads 108 beads\b',
      caseSensitive: false,
    ).hasMatch(candidate)) {
      score -= 24;
    }
    final fullWidthPunctuationCount =
        RegExp(r'[，。；：、（）【】《》「」『』]').allMatches(candidate).length;
    score -= fullWidthPunctuationCount * 45;
    score -= _countRepeatedEnglishContentTokens(candidate) * 26;
    if (description && RegExp(r'[.!?]').hasMatch(candidate)) {
      score += 10;
    }
    return score;
  }

  int _countRepeatedEnglishContentTokens(String text) {
    const stopWords = {
      'a',
      'an',
      'and',
      'as',
      'at',
      'be',
      'for',
      'from',
      'in',
      'is',
      'of',
      'on',
      'or',
      'the',
      'to',
      'with',
      'piece',
      'selected',
      'daily',
      'wear',
      'gifting',
      'collection',
      'currently',
      'available',
      'certificate',
      'no',
    };

    final counts = <String, int>{};
    for (final token in text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 3 && !stopWords.contains(token))) {
      counts[token] = (counts[token] ?? 0) + 1;
    }

    var repeated = 0;
    for (final count in counts.values) {
      if (count > 1) {
        repeated += count - 1;
      }
    }
    return repeated;
  }

  bool _shouldPreferGenerated(
    String? localized,
    String generated,
    String sourceText,
  ) {
    if (generated.isEmpty || generated == sourceText) {
      return false;
    }
    if (localized == null || localized.isEmpty || localized == sourceText) {
      return true;
    }

    final localizedChineseCount =
        RegExp(r'[\u4e00-\u9fff]').allMatches(localized).length;
    final generatedChineseCount =
        RegExp(r'[\u4e00-\u9fff]').allMatches(generated).length;
    if (generatedChineseCount < localizedChineseCount) {
      return true;
    }

    final hasChinese = localizedChineseCount > 0;
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(localized);
    final mashedWords = RegExp(r'[a-z][A-Z]').hasMatch(localized);

    return (hasChinese && hasLatin) || mashedWords;
  }

  String _buildEnglishFallbackName() {
    return ProductTranslator.buildEnglishDisplayName(
      source: name,
      material: material,
      category: category,
      origin: origin,
    );
  }

  String _buildEnglishFallbackDescription({required AppLanguage lang}) {
    final resolvedTitle = localizedTitleFor(lang);
    final generatedTitle = _buildEnglishFallbackName();
    final cleanName = _scoreEnglishCandidate(
              resolvedTitle,
              name,
              description: false,
            ) >=
            _scoreEnglishCandidate(
              generatedTitle,
              name,
              description: false,
            )
        ? resolvedTitle
        : generatedTitle;
    final materialText = localizedMaterialFor(lang);
    final originText = localizedOriginFor(lang);
    final categoryText = localizedCategoryFor(lang);
    final certificateText = certificate?.trim() ?? '';
    final pieceType = switch (categoryText.toLowerCase()) {
      'beads' => 'beaded jewelry piece',
      'ornament' => 'display ornament',
      '' => 'jewelry piece',
      final value => value,
    };

    final parts = <String>[];
    final summary = StringBuffer(
        cleanName.isNotEmpty ? cleanName : _buildEnglishFallbackName());
    if (originText.isNotEmpty) {
      summary.write(' from $originText');
    }
    if (materialText.isNotEmpty &&
        !summary
            .toString()
            .toLowerCase()
            .contains(materialText.toLowerCase())) {
      summary.write(' crafted with $materialText');
    }
    summary.write('.');
    parts.add(summary.toString());
    parts.add(
      'A refined $pieceType selected for daily wear, gifting, and collection.',
    );
    if (certificateText.isNotEmpty) {
      parts.add('Certificate No. $certificateText.');
    }
    if (stock > 0) {
      parts.add('$stock pieces currently available.');
    }

    return parts.join(' ');
  }
}

// Product model

/// Product material enum.
enum MaterialType {
  hetianYu('和田玉', Color(0xFFF5F5DC)),
  jadeite('缅甸翡翠', Color(0xFF32CD32)),
  nanHong('南红玛瑙', Color(0xFFFF6347)),
  amethyst('紫水晶', Color(0xFF9370DB)),
  biyu('碧玉', Color(0xFF228B22)),
  mila('蜜蜡', Color(0xFFFFD700)),
  gold('黄金', Color(0xFFDAA520)),
  ruby('红宝石', Color(0xFFDC143C)),
  sapphire('蓝宝石', Color(0xFF4169E1));

  final String label;
  final Color color;
  const MaterialType(this.label, this.color);
}

/// Product category enum.
enum ProductCategory {
  bracelet('手链'),
  pendant('吊坠'),
  ring('戒指'),
  bangle('手镯'),
  necklace('项链'),
  earring('耳饰');

  final String label;
  const ProductCategory(this.label);
}

/// Product model.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String material;
  final List<String> images;
  final int stock;
  final double rating;
  final int salesCount;
  final bool isHot;
  final bool isNew;
  final String? origin;

  /// Blockchain certificate id.
  final String? certificate;

  /// Blockchain traceability hash.
  final String? blockchainHash;

  /// Whether the product is part of the welfare pricing tier.
  final bool isWelfare;

  /// Material verification state, such as natural or treated.
  final String materialVerify;

  // Localized fields
  final String? nameEn;
  final String? nameZhTw;
  final String? descriptionEn;
  final String? descriptionZhTw;
  final String? materialEn;
  final String? materialZhTw;
  final String? categoryEn;
  final String? categoryZhTw;
  final String? originEn;
  final String? originZhTw;
  final String? materialVerifyEn;
  final String? materialVerifyZhTw;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.material,
    required this.images,
    required this.stock,
    this.rating = 5.0,
    this.salesCount = 0,
    this.isHot = false,
    this.isNew = false,
    this.origin,
    this.certificate,
    this.blockchainHash,
    this.isWelfare = false,
    this.materialVerify = '天然A货',
    this.nameEn,
    this.nameZhTw,
    this.descriptionEn,
    this.descriptionZhTw,
    this.materialEn,
    this.materialZhTw,
    this.categoryEn,
    this.categoryZhTw,
    this.originEn,
    this.originZhTw,
    this.materialVerifyEn,
    this.materialVerifyZhTw,
  });

  /// Discount rate.
  double get discountRate {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  /// Whether the price falls into the welfare price band.
  bool get isWelfarePriceRange => price >= 199 && price <= 599;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: jsonAsString(json['id']),
      name: jsonAsString(json['name']),
      description: jsonAsString(json['description']),
      price: jsonAsDouble(json['price']),
      originalPrice: jsonAsNullableString(json['original_price']) == null
          ? null
          : jsonAsDouble(json['original_price']),
      category: jsonAsString(json['category']),
      material: jsonAsString(json['material']),
      images: jsonAsStringList(json['images']),
      stock: jsonAsInt(json['stock']),
      rating: jsonAsDouble(json['rating'], fallback: 5.0),
      salesCount: jsonAsInt(json['sales_count']),
      isHot: jsonAsBool(json['is_hot']),
      isNew: jsonAsBool(json['is_new']),
      origin: jsonAsNullableString(json['origin']),
      certificate: jsonAsNullableString(json['certificate']),
      blockchainHash: jsonAsNullableString(json['blockchain_hash']),
      isWelfare: jsonAsBool(json['is_welfare']),
      materialVerify: jsonAsString(
        json['material_verify'],
        fallback: '天然A货',
      ),
      nameEn: jsonAsNullableString(json['name_en']),
      nameZhTw: jsonAsNullableString(json['name_zh_tw']),
      descriptionEn: jsonAsNullableString(json['description_en']),
      descriptionZhTw: jsonAsNullableString(json['description_zh_tw']),
      materialEn: jsonAsNullableString(json['material_en']),
      materialZhTw: jsonAsNullableString(json['material_zh_tw']),
      categoryEn: jsonAsNullableString(json['category_en']),
      categoryZhTw: jsonAsNullableString(json['category_zh_tw']),
      originEn: jsonAsNullableString(json['origin_en']),
      originZhTw: jsonAsNullableString(json['origin_zh_tw']),
      materialVerifyEn: jsonAsNullableString(json['material_verify_en']),
      materialVerifyZhTw: jsonAsNullableString(json['material_verify_zh_tw']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'category': category,
      'material': material,
      'images': images,
      'stock': stock,
      'rating': rating,
      'sales_count': salesCount,
      'is_hot': isHot,
      'is_new': isNew,
      'origin': origin,
      'certificate': certificate,
      'blockchain_hash': blockchainHash,
      'is_welfare': isWelfare,
      'material_verify': materialVerify,
      'name_en': nameEn,
      'name_zh_tw': nameZhTw,
      'description_en': descriptionEn,
      'description_zh_tw': descriptionZhTw,
      'material_en': materialEn,
      'material_zh_tw': materialZhTw,
      'category_en': categoryEn,
      'category_zh_tw': categoryZhTw,
      'origin_en': originEn,
      'origin_zh_tw': originZhTw,
      'material_verify_en': materialVerifyEn,
      'material_verify_zh_tw': materialVerifyZhTw,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? material,
    List<String>? images,
    int? stock,
    double? rating,
    int? salesCount,
    bool? isHot,
    bool? isNew,
    String? origin,
    String? certificate,
    String? blockchainHash,
    bool? isWelfare,
    String? materialVerify,
    String? nameEn,
    String? nameZhTw,
    String? descriptionEn,
    String? descriptionZhTw,
    String? materialEn,
    String? materialZhTw,
    String? categoryEn,
    String? categoryZhTw,
    String? originEn,
    String? originZhTw,
    String? materialVerifyEn,
    String? materialVerifyZhTw,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      material: material ?? this.material,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      salesCount: salesCount ?? this.salesCount,
      isHot: isHot ?? this.isHot,
      isNew: isNew ?? this.isNew,
      origin: origin ?? this.origin,
      certificate: certificate ?? this.certificate,
      blockchainHash: blockchainHash ?? this.blockchainHash,
      isWelfare: isWelfare ?? this.isWelfare,
      materialVerify: materialVerify ?? this.materialVerify,
      nameEn: nameEn ?? this.nameEn,
      nameZhTw: nameZhTw ?? this.nameZhTw,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionZhTw: descriptionZhTw ?? this.descriptionZhTw,
      materialEn: materialEn ?? this.materialEn,
      materialZhTw: materialZhTw ?? this.materialZhTw,
      categoryEn: categoryEn ?? this.categoryEn,
      categoryZhTw: categoryZhTw ?? this.categoryZhTw,
      originEn: originEn ?? this.originEn,
      originZhTw: originZhTw ?? this.originZhTw,
      materialVerifyEn: materialVerifyEn ?? this.materialVerifyEn,
      materialVerifyZhTw: materialVerifyZhTw ?? this.materialVerifyZhTw,
    );
  }
}
