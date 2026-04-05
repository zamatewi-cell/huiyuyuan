/// 汇玉源 - 商品动态翻译服务
library;

import '../providers/app_settings_provider.dart';
import 'app_strings.dart';

/// 商品翻译器
class ProductTranslator {
  ProductTranslator._();

  static String translateName(
    AppLanguage lang,
    String name, {
    bool allowExact = true,
  }) {
    final source = name.trim();
    if (source.isEmpty || lang == AppLanguage.zhCN) {
      return source;
    }

    final exact = allowExact ? _exactTranslation(lang, source) : null;
    if (exact != null) {
      return normalizeLocalizedText(lang, exact);
    }

    if (lang == AppLanguage.zhTW) {
      return _toTraditional(source);
    }

    return _normalizeEnglishLabel(
      _translateByDictionary(source, _sortedNameKeywordsEn),
    );
  }

  static String translateDescription(
    AppLanguage lang,
    String desc, {
    bool allowExact = true,
  }) {
    final source = desc.trim();
    if (source.isEmpty || lang == AppLanguage.zhCN) {
      return source;
    }

    final exact = allowExact ? _exactTranslation(lang, source) : null;
    if (exact != null) {
      return normalizeLocalizedText(lang, exact, description: true);
    }

    if (lang == AppLanguage.zhTW) {
      return _toTraditional(source);
    }

    return _normalizeEnglishSentence(
      _translateByDictionary(source, _sortedDescKeywordsEn),
    );
  }

  static String translateMaterial(
    AppLanguage lang,
    String material, {
    bool allowExact = true,
  }) {
    final source = canonicalMaterial(material);
    if (source.isEmpty || lang == AppLanguage.zhCN) {
      return source;
    }

    final exact = allowExact ? _exactTranslation(lang, source) : null;
    if (exact != null) {
      return normalizeLocalizedText(lang, exact);
    }

    if (lang == AppLanguage.zhTW) {
      return _materialZhTW[source] ?? _toTraditional(source);
    }

    final mapped = _materialEn[source] ??
        _translateByDictionary(source, _sortedNameKeywordsEn);
    return _normalizeEnglishLabel(mapped);
  }

  static String canonicalMaterial(String material) {
    final normalized = material.trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    return _materialCanonical[normalized] ??
        _materialCanonical[normalized.toLowerCase()] ??
        normalized;
  }

  static String translateCategory(
    AppLanguage lang,
    String category, {
    bool allowExact = true,
  }) {
    final source = canonicalCategory(category);
    if (source.isEmpty || lang == AppLanguage.zhCN) {
      return source;
    }

    final exact = allowExact ? _exactTranslation(lang, source) : null;
    if (exact != null) {
      return normalizeLocalizedText(lang, exact);
    }

    if (lang == AppLanguage.zhTW) {
      return _categoryZhTW[source] ?? _toTraditional(source);
    }

    return _normalizeEnglishLabel(_categoryEn[source] ?? source);
  }

  static String canonicalCategory(String category) {
    final normalized = category.trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    return _categoryCanonical[normalized] ??
        _categoryCanonical[normalized.toLowerCase()] ??
        normalized;
  }

  static String translateOrigin(
    AppLanguage lang,
    String? origin, {
    bool allowExact = true,
  }) {
    final source = origin?.trim() ?? '';
    if (source.isEmpty || lang == AppLanguage.zhCN) {
      return source;
    }

    final exact = allowExact ? _exactTranslation(lang, source) : null;
    if (exact != null) {
      return normalizeLocalizedText(lang, exact);
    }

    if (lang == AppLanguage.zhTW) {
      return _toTraditional(source);
    }

    final mapped = _originEn[source] ??
        _translateByDictionary(source, _sortedOriginKeywordsEn);
    return _normalizeEnglishLabel(mapped);
  }

  static String translateMaterialVerify(
    AppLanguage lang,
    String verify, {
    bool allowExact = true,
  }) {
    final source = verify.trim();
    if (source.isEmpty || lang == AppLanguage.zhCN) {
      return source;
    }

    final exact = allowExact ? _exactTranslation(lang, source) : null;
    if (exact != null) {
      return normalizeLocalizedText(lang, exact);
    }

    if (lang == AppLanguage.zhTW) {
      return _toTraditional(source);
    }

    return _normalizeEnglishLabel(_verifyEn[source] ?? source);
  }

  static String normalizeLocalizedText(
    AppLanguage lang,
    String text, {
    bool description = false,
  }) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return '';
    }

    if (lang == AppLanguage.zhTW) {
      return _toTraditional(normalized);
    }

    if (lang == AppLanguage.en) {
      return description
          ? _normalizeEnglishSentence(normalized)
          : _normalizeEnglishLabel(normalized);
    }

    return normalized;
  }

  static bool containsChinese(String? text) => chineseCharCount(text) > 0;

  static int chineseCharCount(String? text) {
    if (text == null || text.isEmpty) {
      return 0;
    }
    return RegExp(r'[\u4e00-\u9fff]').allMatches(text).length;
  }

  static String joinUniqueParts(Iterable<String> parts) {
    final joined = <String>[];
    final seen = <String>{};

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final normalized =
          trimmed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
      if (normalized.isEmpty || seen.add(normalized)) {
        joined.add(trimmed);
      }
    }

    return joined.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String buildEnglishDisplayName({
    required String source,
    required String material,
    required String category,
    String? origin,
  }) {
    final sourceText = source.trim();
    if (sourceText.isEmpty) {
      return '';
    }

    final translated = translateName(
      AppLanguage.en,
      sourceText,
      allowExact: false,
    );
    final materialText = translateMaterial(
      AppLanguage.en,
      material,
      allowExact: false,
    );
    final categoryText = translateCategory(
      AppLanguage.en,
      category,
      allowExact: false,
    );
    final originText = translateOrigin(
      AppLanguage.en,
      origin,
      allowExact: false,
    );
    final includeOrigin = origin != null &&
        origin.trim().isNotEmpty &&
        sourceText.contains(origin.trim()) &&
        _shouldKeepOriginInEnglishName(originText);

    final cleaned = _sanitizeEnglishDisplayName(
      translated,
      materialText: materialText,
      categoryText: categoryText,
      originText: includeOrigin ? originText : '',
    );

    if (cleaned.isNotEmpty && !containsChinese(cleaned)) {
      final tokenCount = cleaned.split(RegExp(r'\s+')).length;
      if (tokenCount >= 2 || _hasEnglishProductType(cleaned)) {
        return cleaned;
      }
    }

    return joinUniqueParts([
      if (includeOrigin) originText,
      materialText,
      categoryText,
    ]);
  }

  static String? _exactTranslation(AppLanguage lang, String source) {
    if (lang == AppLanguage.zhCN) {
      return source;
    }

    final translated = AppStrings.get(lang, source);
    return translated == source ? null : translated;
  }

  static String _translateByDictionary(
    String source,
    List<MapEntry<String, String>> dictionary,
  ) {
    var result = source;
    for (final entry in dictionary) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  static List<MapEntry<String, String>> _sortByKeyLength(
    Map<String, String> source,
  ) {
    final entries = source.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return entries;
  }

  static String _normalizeEnglishLabel(String value) {
    var result = _normalizeEnglishCommon(value);
    if (result.isEmpty) {
      return result;
    }

    final smallWords = {
      'and',
      'or',
      'of',
      'with',
      'from',
      'in',
      'on',
      'for',
      'to',
      'the',
      'a',
      'an',
    };

    final tokens = result.split(' ');
    for (var index = 0; index < tokens.length; index++) {
      final token = tokens[index];
      if (token.isEmpty) {
        continue;
      }

      final lower = token.toLowerCase();
      if (index != 0 && index != tokens.length - 1 && smallWords.contains(lower)) {
        tokens[index] = lower;
        continue;
      }

      tokens[index] = _titleCaseToken(token);
    }

    result = tokens.join(' ');
    result = result.replaceAllMapped(
      RegExp(r'(\d+)\s+Mm\b'),
      (match) => '${match.group(1)}mm',
    );
    return _normalizeEnglishTitlePhrases(result).trim();
  }

  static String _normalizeEnglishSentence(String value) {
    var result = _normalizeEnglishCommon(value);
    if (result.isEmpty) {
      return result;
    }

    result = result
        .replaceAll(' .', '.')
        .replaceAll(' ,', ',')
        .replaceAll(' :', ':')
        .replaceAll(' ;', ';');

    result = result.replaceAllMapped(
      RegExp(r'(^|[.!?]\s+)([a-z])'),
      (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
    );

    return _normalizeEnglishSentencePhrases(result).trim();
  }

  static String _normalizeEnglishCommon(String value) {
    var result = value
        .replaceAll('，', ', ')
        .replaceAll('。', '. ')
        .replaceAll('；', '; ')
        .replaceAll('：', ': ')
        .replaceAll('、', ', ')
        .replaceAll('（', ' (')
        .replaceAll('）', ') ')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', '\'')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Za-z])(\d)'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'(\d)([A-Za-z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([\u4e00-\u9fff])([A-Za-z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Za-z])([\u4e00-\u9fff])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('+', ' + ')
        .replaceAll('/', ' / ')
        .replaceAll('&', ' & ');

    result = result.replaceAllMapped(
      RegExp(r'([A-Z])([A-Z][a-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    result = result.replaceAllMapped(
      RegExp(r'\b([A-Z]{2,}(?:-\d{2,4}){1,2}-[A-Z]{1,6})\s+(\d{2,4})\b'),
      (match) => '${match.group(1)}${match.group(2)}',
    );
    result = _collapseRepeatedTokens(result);
    return result;
  }

  static String _normalizeEnglishTitlePhrases(String value) {
    var result = value;
    result = result.replaceAllMapped(
      RegExp(r'\b(\d+)\s+D\s+Hard\b', caseSensitive: false),
      (match) => '${match.group(1)}D Hard',
    );
    result = result.replaceAllMapped(
      RegExp(r'\b(\d+)\s+Dhard\b', caseSensitive: false),
      (match) => '${match.group(1)}D Hard',
    );
    result = result.replaceAllMapped(
      RegExp(r'\b(18|24|14)\s+K\b', caseSensitive: false),
      (match) => '${match.group(1)}K',
    );
    result = result.replaceAll(
      RegExp(r'\bBuddha Beads\s+108 Beads\b', caseSensitive: false),
      '108 Buddha Beads',
    );
    result = result.replaceAll(
      RegExp(r'\bBeads Bracelet\b', caseSensitive: false),
      'Beaded Bracelet',
    );
    result = result.replaceAll(
      RegExp(r'\bBeaded Bracelet Beads\b', caseSensitive: false),
      'Beaded Bracelet',
    );
    result = result.replaceAll(
      RegExp(r'\bBeaded Bracelet\s+108 Beads\b', caseSensitive: false),
      '108-Bead Bracelet',
    );
    result = result.replaceAll(
      RegExp(r'\b108 Beads\s+Beaded Bracelet\b', caseSensitive: false),
      '108-Bead Bracelet',
    );
    result = result.replaceAll(
      RegExp(r'\b108-Bead Bracelet Beads\b', caseSensitive: false),
      '108-Bead Bracelet',
    );
    result = result.replaceAllMapped(
      RegExp(r'\b(\d+)-bead\b', caseSensitive: false),
      (match) => '${match.group(1)}-Bead',
    );
    result = result.replaceAll(
      RegExp(r'\bOrnaments\b', caseSensitive: false),
      'Ornament',
    );
    result = result.replaceAll(
      RegExp(r'\bGuanyin Brand\b', caseSensitive: false),
      'Guanyin Plaque',
    );
    result = result.replaceAll(
      RegExp(r'\bDragon Brand\b', caseSensitive: false),
      'Dragon Plaque',
    );
    result = result.replaceAll(
      RegExp(r'\bWushi Brand\b', caseSensitive: false),
      'Wushi Plaque',
    );
    result = result.replaceAllMapped(
      RegExp(r'\b(\d+)\s+Yuan\b', caseSensitive: false),
      (match) => '¥${match.group(1)}',
    );
    result = result.replaceAllMapped(
      RegExp(
        r'(.+\bLucky Bag)\b(?:\s+(?:Natural|Stone|Bracelet|Bangle|Pendant|Necklace|Ring|Earring|Set|Ornament|Beads))+$',
        caseSensitive: false,
      ),
      (match) => match.group(1)!,
    );
    result = result.replaceAllMapped(
      RegExp(
        r'(.+\b(?:Bracelet|Bangle|Pendant|Necklace|Ring|Earring|Stud Earring|Drop Earring|Brooch|Set|Ornament))\s+(?:Gold|Silver|Platinum|Hetian Jade|Jadeite|Pearl|Amber|Agate|Southern Red Agate|Ruby|Sapphire|Diamond|Lapis Lazuli|Tourmaline|Jasper|Natural Stone)\b',
        caseSensitive: false,
      ),
      (match) => match.group(1)!,
    );
    result = _collapseRepeatedTokens(result);
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _normalizeEnglishSentencePhrases(String value) {
    var result = _normalizeEnglishTitlePhrases(value);
    result = result.replaceAllMapped(
      RegExp(r'(^|[.!?]\s+)([a-z])'),
      (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
    );
    return result;
  }

  static String _collapseRepeatedTokens(String value) {
    final tokens = value.split(RegExp(r'\s+'));
    final collapsed = <String>[];

    String normalizeToken(String token) =>
        token.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();

    for (final token in tokens) {
      if (token.isEmpty) {
        continue;
      }
      if (collapsed.isNotEmpty &&
          normalizeToken(collapsed.last) == normalizeToken(token) &&
          normalizeToken(token).isNotEmpty) {
        continue;
      }
      collapsed.add(token);
    }

    return collapsed.join(' ');
  }

  static String _titleCaseToken(String token) {
    if (token.isEmpty) {
      return token;
    }

    if (RegExp(r'^[A-Z0-9]+$').hasMatch(token)) {
      return token;
    }

    if (RegExp(r'^\d+(\.\d+)?(mm)?$', caseSensitive: false).hasMatch(token)) {
      return token.toLowerCase().endsWith('mm') ? token.toLowerCase() : token;
    }

    if (token.contains('\'')) {
      return token
          .split('\'')
          .map(_capitalizeSimple)
          .join('\'');
    }

    return _capitalizeSimple(token);
  }

  static String _capitalizeSimple(String token) {
    if (token.isEmpty) {
      return token;
    }
    if (token.length == 1) {
      return token.toUpperCase();
    }
    return '${token[0].toUpperCase()}${token.substring(1).toLowerCase()}';
  }

  static String _sanitizeEnglishDisplayName(
    String value, {
    required String materialText,
    required String categoryText,
    required String originText,
  }) {
    var cleaned = value
        .replaceAll(RegExp(r'[\u4e00-\u9fff]+'), ' ')
        .replaceAll('（', ' ')
        .replaceAll('）', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    cleaned = _normalizeEnglishLabel(cleaned);
    final parts = <String>[];
    if (originText.isNotEmpty && !_containsComparableToken(cleaned, originText)) {
      parts.add(originText);
    }
    if (cleaned.isNotEmpty) {
      parts.add(cleaned);
    }
    if (materialText.isNotEmpty &&
        !_containsComparableToken(cleaned, materialText)) {
      parts.add(materialText);
    }
    if (categoryText.isNotEmpty &&
        !_containsComparableToken(cleaned, categoryText)) {
      parts.add(categoryText);
    }
    return joinUniqueParts(parts);
  }

  static bool _containsComparableToken(String haystack, String needle) {
    final normalizedHaystack = _normalizedComparableValue(haystack);
    final normalizedNeedle = _normalizedComparableValue(needle);
    if (normalizedHaystack.isEmpty || normalizedNeedle.isEmpty) {
      return false;
    }
    return normalizedHaystack.contains(normalizedNeedle);
  }

  static String _normalizedComparableValue(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  }

  static bool _shouldKeepOriginInEnglishName(String originText) {
    final normalized = originText.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'china') {
      return false;
    }
    return !normalized.endsWith(', china');
  }

  static bool _hasEnglishProductType(String value) {
    return RegExp(
      r'\b(bracelet|bangle|pendant|ring|necklace|earring|stud earring|beads|ornament|set|brooch)\b',
      caseSensitive: false,
    ).hasMatch(value);
  }

  // ═══════════════════════════════════════════
  //  英文翻译词库
  // ═══════════════════════════════════════════

  static const _materialEn = {
    '和田玉': 'Hetian Jade',
    '缅甸翡翠': 'Jadeite',
    '南红玛瑙': 'Southern Red Agate',
    '紫水晶': 'Amethyst',
    '碧玉': 'Jasper',
    '蜜蜡': 'Amber',
    '黄金': 'Gold',
    '红宝石': 'Ruby',
    '蓝宝石': 'Sapphire',
    '钻石': 'Diamond',
    '珍珠': 'Pearl',
    '纯银': 'Sterling Silver',
    '绿松石': 'Turquoise',
    '玛瑙': 'Agate',
    '天珠': 'Dzi Bead',
    '琥珀': 'Amber',
    '红珊瑚': 'Red Coral',
    '珊瑚': 'Coral',
    '祖母绿': 'Emerald',
    '坦桑石': 'Tanzanite',
    '粉水晶': 'Rose Quartz',
    '黄水晶': 'Citrine',
    '碧玺': 'Tourmaline',
    '沉香': 'Agarwood',
    '小叶紫檀': 'Rosewood',
    '黄花梨': 'Huanghuali Wood',
    '砗磲': 'Tridacna',
    '天河石': 'Amazonite',
    '青金石': 'Lapis Lazuli',
    '月光石': 'Moonstone',
    '石榴石': 'Garnet',
    '拉长石': 'Labradorite',
    '草莓晶': 'Strawberry Quartz',
    '发晶': 'Rutilated Quartz',
    '孔雀石': 'Malachite',
    '天然石': 'Natural Stone',
    '苗银': 'Miao Silver',
  };

  static final Map<String, String> _materialCanonical = {
    for (final entry in _materialEn.entries) entry.key: entry.key,
    for (final entry in _materialEn.entries) entry.value: entry.key,
    for (final entry in _materialEn.entries) entry.value.toLowerCase(): entry.key,
    '緬甸翡翠': '缅甸翡翠',
    '南紅瑪瑙': '南红玛瑙',
    '蜜蠟': '蜜蜡',
    '黃金': '黄金',
    '紅寶石': '红宝石',
    '藍寶石': '蓝宝石',
    '鑽石': '钻石',
    '綠松石': '绿松石',
    '瑪瑙': '玛瑙',
    '紅珊瑚': '红珊瑚',
    '祖母綠': '祖母绿',
    '粉水晶': '粉水晶',
    '黃水晶': '黄水晶',
    '碧璽': '碧玺',
    '沉香木': '沉香',
    '小葉紫檀': '小叶紫檀',
    '黃花梨': '黄花梨',
    '硨磲': '砗磲',
    '青金石': '青金石',
    '月光石': '月光石',
    '石榴石': '石榴石',
    '拉長石': '拉长石',
    '草莓晶': '草莓晶',
    '發晶': '发晶',
    '孔雀石': '孔雀石',
    '天然石': '天然石',
    '純銀': '纯银',
    '925銀': '纯银',
    '999銀': '纯银',
  };

  static const _categoryEn = {
    '手链': 'Bracelet',
    '手串': 'Beads',
    '吊坠': 'Pendant',
    '戒指': 'Ring',
    '手镯': 'Bangle',
    '项链': 'Necklace',
    '耳饰': 'Earring',
    '耳环': 'Earring',
    '摆件': 'Ornament',
    '套装': 'Set',
  };

  static final Map<String, String> _categoryCanonical = {
    for (final entry in _categoryEn.entries) entry.key: entry.key,
    for (final entry in _categoryEn.entries) entry.value: entry.key,
    for (final entry in _categoryEn.entries) entry.value.toLowerCase(): entry.key,
    '手鏈': '手链',
    '吊墜': '吊坠',
    '手鐲': '手镯',
    '項鏈': '项链',
    '耳飾': '耳饰',
    '耳環': '耳环',
    '擺件': '摆件',
    '套裝': '套装',
    'figurine': '摆件',
    'Figurine': '摆件',
  };

  static const _originEn = {
    '中国': 'China',
    '中国云南': 'Yunnan, China',
    '中国台湾': 'Taiwan, China',
    '中国四川': 'Sichuan, China',
    '中国海南': 'Hainan, China',
    '中国浙江': 'Zhejiang, China',
    '中国湖北': 'Hubei, China',
    '中国贵州': 'Guizhou, China',
    '中国辽宁': 'Liaoning, China',
    '新疆和田': 'Xinjiang Hetian',
    '新疆': 'Xinjiang',
    '缅甸': 'Myanmar',
    '缅甸莫西沙': 'Myanmar Moxisha',
    '云南保山': 'Yunnan Baoshan',
    '四川凉山': 'Sichuan Liangshan',
    '保山': 'Baoshan',
    '凉山': 'Liangshan',
    '巴西': 'Brazil',
    '乌拉圭': 'Uruguay',
    '俄罗斯': 'Russia',
    '波罗的海': 'Baltic',
    '斯里兰卡': 'Sri Lanka',
    '南非': 'South Africa',
    '日本': 'Japan',
    '西藏': 'Tibet',
    '哥伦比亚': 'Colombia',
    '坦桑尼亚': 'Tanzania',
    '大溪地': 'Tahitian',
    '印度尼西亚': 'Indonesia',
    '意大利': 'Italy',
    '越南': 'Vietnam',
    '印度': 'India',
    '阿富汗': 'Afghanistan',
    '莫桑比克': 'Mozambique',
    '马达加斯加': 'Madagascar',
    '刚果': 'Congo',
  };

  static const _verifyEn = {
    '天然A货': 'Natural Grade A',
    '天然': 'Natural',
    '优化处理': 'Enhanced',
  };

  static const _nameKeywordsEn = {
    // 产地 / 来源
    '新疆和田': 'Xinjiang Hetian',
    '云南保山': 'Yunnan Baoshan',
    '四川凉山': 'Sichuan Liangshan',
    '保山': 'Baoshan',
    '凉山': 'Liangshan',
    '波罗的海': 'Baltic',
    '斯里兰卡': 'Sri Lanka',
    '乌拉圭': 'Uruguay',
    '俄罗斯': 'Russia',
    '大溪地': 'Tahitian',
    '巴西': 'Brazil',
    '日本': 'Japan',
    '西藏': 'Tibet',
    '中国浙江': 'Zhejiang, China',
    '中国海南': 'Hainan, China',
    '中国湖北': 'Hubei, China',
    '中国贵州': 'Guizhou, China',
    '中国辽宁': 'Liaoning, China',
    '中国云南': 'Yunnan, China',
    '中国四川': 'Sichuan, China',
    '中国台湾': 'Taiwan, China',
    '中国': 'China',
    '缅甸': 'Myanmar',
    '和田': 'Hetian',
    '阿卡': 'Aka',

    // 材质
    'AKOYA海水珍珠': 'AKOYA Saltwater Pearl',
    '海水珍珠': 'Saltwater Pearl',
    '大溪地黑珍珠': 'Tahitian Black Pearl',
    '南洋金珠': 'South Sea Golden Pearl',
    '淡水珍珠': 'Freshwater Pearl',
    '巴洛克珍珠': 'Baroque Pearl',
    '天然珍珠': 'Natural Pearl',
    '珍珠': 'Pearl',
    '新疆和田玉': 'Xinjiang Hetian Jade',
    '和田玉': 'Hetian Jade',
    '缅甸翡翠': 'Jadeite',
    '翡翠': 'Jadeite',
    '南红玛瑙': 'Southern Red Agate',
    '南红': 'Southern Red Agate',
    '战国红玛瑙': 'Warring States Red Agate',
    '黑玛瑙': 'Black Agate',
    '缠丝玛瑙': 'Sardonyx',
    '糖心玛瑙': 'Sugar Heart Agate',
    '玛瑙': 'Agate',
    '紫水晶': 'Amethyst',
    '粉水晶': 'Rose Quartz',
    '黄水晶': 'Citrine',
    '碧玉': 'Jasper',
    '蜜蜡': 'Amber',
    '老蜜蜡': 'Antique Amber',
    '白花蜜蜡': 'White Blossom Amber',
    '鸡油黄蜜蜡': 'Golden Amber',
    '鸡油黄': 'Golden',
    '琥珀虫珀': 'Insect Amber',
    '琥珀': 'Amber',
    '血珀': 'Blood Amber',
    '黄金': 'Gold',
    '古法黄金': 'Classic Gold',
    '黄金古法': 'Classic Gold',
    '足金999': '999 Gold',
    '18K玫瑰金': '18K Rose Gold',
    '18K白金': '18K Platinum',
    '18K金': '18K Gold',
    '玫瑰金': 'Rose Gold',
    '白金': 'Platinum',
    '925银': '925 Silver',
    '足银999': '999 Silver',
    '足银': 'Silver',
    '纯银999': '999 Sterling Silver',
    '纯银': 'Sterling Silver',
    '苗银': 'Miao Silver',
    '红宝石': 'Ruby',
    '蓝宝石': 'Sapphire',
    '祖母绿': 'Emerald',
    '坦桑石': 'Tanzanite',
    '钻石': 'Diamond',
    '绿松石': 'Turquoise',
    '高瓷蓝绿松石': 'High-Grade Blue Turquoise',
    '乌兰花绿松石': 'Ulan Flower Turquoise',
    '紫晶洞': 'Amethyst Geode',
    '紫水晶洞': 'Amethyst Geode',
    '青金石': 'Lapis Lazuli',
    '天河石': 'Amazonite',
    '月光石': 'Moonstone',
    '石榴石': 'Garnet',
    '拉长石': 'Labradorite',
    '草莓晶': 'Strawberry Quartz',
    '发晶': 'Rutilated Quartz',
    '孔雀石': 'Malachite',
    '碧玺': 'Tourmaline',
    '天珠': 'Dzi Bead',
    '九眼天珠': 'Nine-Eyed Dzi Bead',
    '三眼天珠': 'Three-Eyed Dzi Bead',
    '虎牙天珠': 'Tiger Tooth Dzi Bead',
    '天珠配金刚菩提': 'Dzi Bead with Vajra Bodhi',
    '红珊瑚': 'Red Coral',
    '阿卡红珊瑚': 'Aka Red Coral',
    '粉珊瑚': 'Pink Coral',
    '深水珊瑚': 'Deep-Sea Coral',
    '珊瑚': 'Coral',
    '沉香木': 'Agarwood',
    '沉香': 'Agarwood',
    '小叶紫檀': 'Rosewood',
    '海南黄花梨': 'Hainan Huanghuali',
    '黄花梨': 'Huanghuali',
    '玉化砗磲': 'Jade Tridacna',
    '砗磲': 'Tridacna',
    '天然石': 'Natural Stone',

    // 材质修饰 / 颜色
    '籽料': 'Seed Jade',
    '青白玉': 'Green-White Jade',
    '青玉': 'Green Jade',
    '白玉': 'White Jade',
    '墨玉': 'Ink Jade',
    '羊脂白玉': 'Suet White Jade',
    '羊脂': 'Suet Jade',
    '糖白玉': 'Sugar White Jade',
    '糖玉': 'Sugar Jade',
    '冰糯种': 'Icy Glutinous',
    '冰种': 'Icy',
    '糯冰种': 'Glutinous Icy',
    '糯冰': 'Glutinous Icy',
    '糯种': 'Glutinous',
    '满绿翡翠': 'Full Green Jadeite',
    '满绿': 'Full Green',
    '飘花': 'Floating Flowers',
    '帝王绿': 'Imperial Green',
    '阳绿': 'Bright Green',
    '柿子红': 'Persimmon Red',
    '锦红': 'Brocade Red',
    '火焰纹': 'Flame Pattern',
    '樱桃红': 'Cherry Red',
    '樱花红': 'Cherry Blossom Red',
    '玫瑰红': 'Rose Red',
    '冰飘花': 'Icy Floating Flower',
    '冰飘': 'Icy Float',
    '菠菜绿': 'Spinach Green',
    '鸭蛋青': 'Duck Egg Green',
    '白加绿': 'White-Green',
    '苹果绿': 'Apple Green',
    '白花': 'White Blossom',
    '玫瑰': 'Rose',
    '紫罗兰': 'Lavender',
    '深蓝': 'Deep Blue',
    '天然': 'Natural',
    '优雅': 'Elegant',
    '老坑': 'Old Pit',
    '无色': 'Colorless',
    '满色': 'Full-Color',

    // 形制 / 类型
    '手链': 'Bracelet',
    '手串': 'Beads Bracelet',
    '手镯': 'Bangle',
    '吊坠': 'Pendant',
    '项链': 'Necklace',
    '戒指': 'Ring',
    '耳饰': 'Earring',
    '耳环': 'Earring',
    '耳钉': 'Stud Earring',
    '耳坠': 'Drop Earring',
    '摆件': 'Ornament',
    '挂件': 'Pendant',
    '配饰': 'Accessory',
    '套装': 'Set',
    '三件套': 'Three-Piece Set',
    '胸针': 'Brooch',

    // 造型 / 工艺
    '平安扣': 'Safety Buckle',
    '平安锁': 'Safety Lock',
    '如意锁': 'Ruyi Lock',
    '如意': 'Ruyi',
    '观音牌': 'Guanyin Plaque',
    '观音': 'Guanyin',
    '佛公': 'Buddha Pendant',
    '佛头': 'Buddha Head',
    '佛珠': 'Buddha Beads',
    '佛': 'Buddha',
    '貔貅': 'Pixiu',
    '蝴蝶结': 'Bow',
    '转运珠': 'Lucky Bead',
    '金蟾': 'Golden Toad',
    '葫芦': 'Gourd',
    '福瓜': 'Fortune Gourd',
    '无事牌': 'Wushi Plaque',
    '龙凤对牌': 'Dragon Phoenix Pair Plaques',
    '龙凤': 'Dragon Phoenix',
    '龙牌': 'Dragon Plaque',
    '福运': 'Fortune',
    '福气': 'Fortune',
    '福字': 'Fu Character',
    '吉祥': 'Auspicious',
    '圆珠': 'Round Bead',
    '桶珠': 'Barrel Bead',
    '蛋面': 'Cabochon',
    '水滴': 'Teardrop',
    '心形': 'Heart-Shaped',
    '马眼': 'Marquise',
    '方牌': 'Square Plaque',
    '叶子': 'Leaf',
    '莲花': 'Lotus',
    '花朵款': 'Floral',
    '雕花': 'Carved',
    '竹节': 'Bamboo',
    '山水': 'Landscape',
    '树枝': 'Branch',
    '四季豆': 'Peapod',
    '马鞍戒': 'Saddle Ring',
    '马鞍': 'Saddle',
    '把件': 'Handheld Ornament',
    '猫眼': 'Cat\'s Eye',
    '狐狸': 'Fox',
    '一克拉': 'One-Carat',
    '50分': 'Half-Carat',
    '六爪': 'Six-Prong',
    '108佛珠': '108 Buddha Beads',
    '108颗': '108 Beads',
    '小号': 'Small',
    '圆条': 'Round',
    '三通': 'Three-Way',
    '花丝': 'Filigree',
    '红绳': 'Red Cord',
    '招财': 'Fortune',
    '福袋': 'Lucky Bag',
    '超值福袋': 'Value Lucky Bag',
    '68元': '¥68',
    '宝宝': 'Baby',
    '生肖虎': 'Tiger Zodiac',
    '永恒': 'Eternity',
    '镶嵌': 'Inlaid',
    '镶': 'Inlaid',
    '传承': 'Heritage',
    '古法': 'Classic',
    '足金': 'Pure Gold',
    '硬金': 'Hard Gold',
    '异形': 'Baroque',
  };

  static final _sortedNameKeywordsEn = _sortByKeyLength(_nameKeywordsEn);
  static final _sortedOriginKeywordsEn = _sortByKeyLength(_originEn);

  static const _descKeywordsEn = {
    '深蓝带金星': 'deep blue with golden flecks',
    '古代皇家尊贵之石': 'a gemstone once treasured by royalty',
    '男女通用': 'suitable for both men and women',
    '适合男士佩戴': 'well suited for men',
    '适合日常佩戴': 'suitable for daily wear',
    '高贵典雅': 'refined and elegant',
    '古法工艺': 'classic handmade craftsmanship',
    '樱桃红': 'cherry-red tone',
    '附GRS证书': 'with a GRS certificate',
    '精选': 'premium selected',
    '甄选': 'carefully selected',
    '严选': 'strictly selected',
    '玉质温润细腻': 'warm and delicate jade texture',
    '油性十足': 'rich oily luster',
    '色泽淡雅': 'elegant color tone',
    '质地均匀': 'uniform texture',
    '采用传统手工编织工艺': 'crafted with traditional hand weaving',
    '手工编织': 'hand-woven',
    '天然形成': 'naturally formed',
    '寓意': 'symbolizing',
    '平安健康': 'peace and good health',
    '好运连连': 'continuous good luck',
    '万事如意': 'all the best',
    '吉祥如意': 'good fortune and prosperity',
    '招财进宝': 'wealth and prosperity',
    '每颗珠子均为天然': 'each bead is naturally formed',
    '无优化处理': 'without enhancement treatment',
    '佩戴舒适': 'comfortable to wear',
    '附赠权威机构鉴定证书': 'with an authoritative authentication certificate',
    '区块链溯源码': 'with a blockchain traceability code',
    '鉴定证书': 'authentication certificate',
    '馈赠亲友': 'ideal for gifting',
    '可调节松紧': 'adjustable fit',
    '弹力绳穿制': 'strung on an elastic cord',
    '限量发行': 'limited edition',
    '收藏价值': 'collectible value',
    '投资级': 'investment grade',
  };

  static final _sortedDescKeywordsEn = _sortByKeyLength({
    ..._originEn,
    ..._nameKeywordsEn,
    ..._descKeywordsEn,
  });

  // ═══════════════════════════════════════════
  //  繁体中文转换
  // ═══════════════════════════════════════════

  static const _materialZhTW = {
    '和田玉': '和田玉',
    '缅甸翡翠': '緬甸翡翠',
    '南红玛瑙': '南紅瑪瑙',
    '紫水晶': '紫水晶',
    '碧玉': '碧玉',
    '蜜蜡': '蜜蠟',
    '黄金': '黃金',
    '红宝石': '紅寶石',
    '蓝宝石': '藍寶石',
    '钻石': '鑽石',
    '珍珠': '珍珠',
    '纯银': '純銀',
    '绿松石': '綠松石',
    '玛瑙': '瑪瑙',
    '天珠': '天珠',
    '琥珀': '琥珀',
    '红珊瑚': '紅珊瑚',
    '珊瑚': '珊瑚',
    '祖母绿': '祖母綠',
    '坦桑石': '坦桑石',
    '粉水晶': '粉水晶',
    '黄水晶': '黃水晶',
    '碧玺': '碧璽',
    '沉香': '沉香',
    '小叶紫檀': '小葉紫檀',
    '黄花梨': '黃花梨',
    '砗磲': '硨磲',
    '天河石': '天河石',
    '青金石': '青金石',
    '月光石': '月光石',
    '石榴石': '石榴石',
    '拉长石': '拉長石',
    '草莓晶': '草莓晶',
    '发晶': '發晶',
    '孔雀石': '孔雀石',
    '天然石': '天然石',
    '苗银': '苗銀',
  };

  static const _categoryZhTW = {
    '手链': '手鏈',
    '手串': '手串',
    '吊坠': '吊墜',
    '戒指': '戒指',
    '手镯': '手鐲',
    '项链': '項鏈',
    '耳饰': '耳飾',
    '耳环': '耳環',
    '摆件': '擺件',
    '套装': '套裝',
  };

  static const _phraseZhTW = {
    'AKOYA': '阿古屋',
    'NGTC': '國檢',
    '南红玛瑙': '南紅瑪瑙',
    '战国红玛瑙': '戰國紅瑪瑙',
    '缅甸翡翠': '緬甸翡翠',
    '红宝石': '紅寶石',
    '蓝宝石': '藍寶石',
    '和田玉': '和田玉',
    '项链': '項鏈',
    '吊坠': '吊墜',
    '手链': '手鏈',
    '手镯': '手鐲',
    '耳饰': '耳飾',
    '耳环': '耳環',
    '摆件': '擺件',
    '套装': '套裝',
    '如意锁': '如意鎖',
    '平安锁': '平安鎖',
    '观音': '觀音',
    '庄严': '莊嚴',
    '扣头': '扣頭',
    '樱桃红': '櫻桃紅',
    '圆条': '圓條',
    '内径': '內徑',
    '正圆': '正圓',
    '色泽': '色澤',
    '光泽': '光澤',
    '光线下': '光線下',
    '一线天光': '一線天光',
    '耳钉': '耳釘',
    '链长': '鏈長',
    '经典': '經典',
    '优雅': '優雅',
    '天然珍珠': '天然珍珠',
    '天然海水珍珠': '天然海水珍珠',
    '中国': '中國',
    '中国浙江': '中國浙江',
    '中国海南': '中國海南',
    '中国湖北': '中國湖北',
    '中国贵州': '中國貴州',
    '中国辽宁': '中國遼寧',
    '中国云南': '中國雲南',
    '中国四川': '中國四川',
    '中国台湾': '中國台灣',
    '云南保山': '雲南保山',
    '四川凉山': '四川涼山',
    '新疆和田': '新疆和田',
    '波罗的海': '波羅的海',
    '鸡油黄': '雞油黃',
    '白花蜜蜡': '白花蜜蠟',
    '纯银999': '純銀999',
    '足银999': '足銀999',
    '足金999': '足金999',
    '绿松石': '綠松石',
    '乌兰花绿松石': '烏蘭花綠松石',
    '高瓷蓝绿松石': '高瓷藍綠松石',
    '小叶紫檀': '小葉紫檀',
    '海南黄花梨': '海南黃花梨',
    '黄花梨': '黃花梨',
    '玉化砗磲': '玉化硨磲',
    '青金石': '青金石',
    '月光石': '月光石',
    '拉长石': '拉長石',
    '草莓晶': '草莓晶',
    '发晶': '發晶',
    '孔雀石': '孔雀石',
    '碧玺': '碧璽',
    '黄水晶': '黃水晶',
    '祖母绿': '祖母綠',
    '阿卡红珊瑚': '阿卡紅珊瑚',
    '红珊瑚': '紅珊瑚',
    '粉珊瑚': '粉珊瑚',
    '深水珊瑚': '深水珊瑚',
    '三眼天珠': '三眼天珠',
    '九眼天珠': '九眼天珠',
    '虎牙天珠': '虎牙天珠',
    '天珠配金刚菩提': '天珠配金剛菩提',
    '超值福袋': '超值福袋',
    '佛珠': '佛珠',
  };

  static final _sortedPhraseZhTW = _sortByKeyLength(_phraseZhTW);

  static const _s2t = {
    '链': '鏈',
    '坠': '墜',
    '镯': '鐲',
    '项': '項',
    '饰': '飾',
    '红': '紅',
    '绿': '綠',
    '蓝': '藍',
    '黄': '黃',
    '宝': '寶',
    '钻': '鑽',
    '银': '銀',
    '铂': '鉑',
    '缅': '緬',
    '选': '選',
    '观': '觀',
    '质': '質',
    '润': '潤',
    '温': '溫',
    '细': '細',
    '腻': '膩',
    '编': '編',
    '织': '織',
    '传': '傳',
    '统': '統',
    '设': '設',
    '计': '計',
    '颗': '顆',
    '优': '優',
    '处': '處',
    '证': '證',
    '书': '書',
    '赠': '贈',
    '权': '權',
    '威': '威',
    '构': '構',
    '鉴': '鑑',
    '码': '碼',
    '调': '調',
    '节': '節',
    '适': '適',
    '亲': '親',
    '馈': '餽',
    '发': '發',
    '纹': '紋',
    '图': '圖',
    '龙': '龍',
    '凤': '鳳',
    '圆': '圓',
    '内': '內',
    '头': '頭',
    '钉': '釘',
    '樱': '櫻',
    '径': '徑',
    '泽': '澤',
    '艳': '艷',
    '显': '顯',
    '长': '長',
    '经': '經',
    '线': '線',
    '种': '種',
    '极': '極',
    '价': '價',
    '强': '強',
    '稳': '穩',
    '庄': '莊',
    '严': '嚴',
    '运': '運',
    '气': '氣',
    '锁': '鎖',
    '当': '當',
    '装': '裝',
    '国': '國',
    '货': '貨',
    '号': '號',
    '礼': '禮',
    '广': '廣',
    '凉': '涼',
    '艺': '藝',
    '妈': '媽',
    '玛': '瑪',
    '层': '層',
    '灵': '靈',
    '满': '滿',
    '猫': '貓',
    '纯': '純',
    '乌': '烏',
    '辽': '遼',
    '丽': '麗',
    '瓷': '瓷',
    '罗': '羅',
    '鸡': '雞',
    '珊': '珊',
  };

  static String _toTraditional(String text) {
    var normalized = text;
    for (final entry in _sortedPhraseZhTW) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }

    final buffer = StringBuffer();
    for (final char in normalized.split('')) {
      buffer.write(_s2t[char] ?? char);
    }
    return buffer.toString();
  }
}
