import 'package:huiyuyuan/l10n/translator_global.dart';

class _AiTermRule {
  final List<String> aliases;

  const _AiTermRule(this.aliases);
}

class AIInsightService {
  const AIInsightService();

  Future<Map<String, dynamic>> analyzeChatContent(String content) async {
    final keywords = _extractKeywords(content);
    final sentiment = _analyzeSentiment(content);
    final intent = _identifyIntent(content);
    final suggestion = _generateSuggestion(sentiment, intent);

    return {
      'keywords': keywords,
      'sentiment': sentiment,
      'intent': intent,
      'suggestion': suggestion,
      'urgency': _assessUrgency(content),
    };
  }

  String filterSensitiveWords(String content) {
    var filtered = content;
    for (final word in _sensitiveWords) {
      filtered = filtered.replaceAll(word, '***');
    }
    return filtered;
  }

  Map<String, dynamic> checkCompliance(String content) {
    final violations = <String>[];

    for (final word in _sensitiveWords) {
      if (content.contains(word)) {
        violations.add(word);
      }
    }

    return {
      'isCompliant': violations.isEmpty,
      'violations': violations,
      'suggestion': violations.isNotEmpty
          ? _t('ai_compliance_violations', params: {
              'terms': violations.join(' / '),
            })
          : _t('ai_compliance_clean'),
    };
  }

  Future<Map<String, dynamic>> evaluateShop({
    required String shopName,
    required double rating,
    required double conversionRate,
    required int followers,
    double? negativeRate,
  }) async {
    var score = 0.0;
    final reasons = <String>[];
    final ratingText = rating.toStringAsFixed(1);
    final conversionText = conversionRate.toStringAsFixed(1);
    final followerText = followers.toString();

    if (rating >= 4.8) {
      score += 30;
      reasons.add(
        _t('ai_shop_eval_rating_excellent', params: {'rating': ratingText}),
      );
    } else if (rating >= 4.7) {
      score += 20;
      reasons.add(
        _t('ai_shop_eval_rating_good', params: {'rating': ratingText}),
      );
    } else {
      score += 10;
      reasons.add(
        _t('ai_shop_eval_rating_average', params: {'rating': ratingText}),
      );
    }

    if (conversionRate >= 5) {
      score += 30;
      reasons.add(
        _t('ai_shop_eval_conversion_excellent', params: {
          'rate': conversionText,
        }),
      );
    } else if (conversionRate >= 3) {
      score += 20;
      reasons.add(
        _t('ai_shop_eval_conversion_good', params: {'rate': conversionText}),
      );
    } else {
      score += 10;
      reasons.add(
        _t('ai_shop_eval_conversion_average', params: {'rate': conversionText}),
      );
    }

    if (followers >= 100000) {
      score += 25;
      reasons.add(
        _t('ai_shop_eval_followers_large', params: {'count': followerText}),
      );
    } else if (followers >= 50000) {
      score += 15;
      reasons.add(
        _t('ai_shop_eval_followers_medium', params: {'count': followerText}),
      );
    } else {
      score += 10;
      reasons.add(
        _t('ai_shop_eval_followers_small', params: {'count': followerText}),
      );
    }

    if (negativeRate != null) {
      final negativeText = (negativeRate * 100).toStringAsFixed(1);
      if (negativeRate < 0.01) {
        score += 15;
        reasons.add(
          _t('ai_shop_eval_negative_very_low', params: {'rate': negativeText}),
        );
      } else if (negativeRate < 0.02) {
        score += 10;
        reasons.add(
          _t('ai_shop_eval_negative_low', params: {'rate': negativeText}),
        );
      } else {
        reasons.add(
          _t('ai_shop_eval_negative_high', params: {'rate': negativeText}),
        );
      }
    }

    late final String decision;
    late final String priority;

    if (score >= 80) {
      decision = _t('ai_shop_eval_decision_strong');
      priority = 'high';
    } else if (score >= 60) {
      decision = _t('ai_shop_eval_decision_suggest');
      priority = 'medium';
    } else {
      decision = _t('ai_shop_eval_decision_hold');
      priority = 'low';
    }

    return {
      'shopName': shopName,
      'score': score.toInt(),
      'decision': decision,
      'priority': priority,
      'reasons': reasons,
      'suggestedAction': score >= 60
          ? _t('ai_shop_eval_action_contact')
          : _t('ai_shop_eval_action_observe'),
    };
  }

  List<String> _extractKeywords(String content) {
    final normalized = content.toLowerCase();
    final found = <String>[];
    for (final rule in _keywordRules) {
      for (final alias in rule.aliases) {
        if (normalized.contains(alias.toLowerCase())) {
          found.add(alias);
          break;
        }
      }
    }
    return found;
  }

  String _analyzeSentiment(String content) {
    final normalized = content.toLowerCase();

    var negativeCount = 0;
    var positiveCount = 0;

    for (final word in _negativeSentimentTerms) {
      if (normalized.contains(word)) negativeCount++;
    }
    for (final word in _positiveSentimentTerms) {
      if (normalized.contains(word)) positiveCount++;
    }

    if (negativeCount > positiveCount) return 'negative';
    if (positiveCount > negativeCount) return 'positive';
    return 'neutral';
  }

  String _identifyIntent(String content) {
    final normalized = content.toLowerCase();
    if (_containsAny(normalized, _priceInquiryTerms)) {
      return 'price_inquiry';
    }
    if (_containsAny(normalized, _authenticityTerms)) {
      return 'authenticity_check';
    }
    if (_containsAny(normalized, _afterSalesTerms)) {
      return 'after_sales';
    }
    if (_containsAny(normalized, _businessInquiryTerms)) {
      return 'business_inquiry';
    }
    if (_containsAny(normalized, _productRecommendationTerms)) {
      return 'product_recommendation';
    }
    return 'general_inquiry';
  }

  String _assessUrgency(String content) {
    final normalized = content.toLowerCase();
    for (final word in _urgentTerms) {
      if (normalized.contains(word)) return 'high';
    }
    return 'normal';
  }

  String _generateSuggestion(String sentiment, String intent) {
    if (sentiment == 'negative') {
      return _t('ai_chat_suggestion_negative');
    }

    switch (intent) {
      case 'price_inquiry':
        return _t('ai_chat_suggestion_price_inquiry');
      case 'authenticity_check':
        return _t('ai_chat_suggestion_authenticity');
      case 'business_inquiry':
        return _t('ai_chat_suggestion_business');
      case 'after_sales':
        return _t('ai_chat_suggestion_after_sales');
      default:
        return _t('ai_chat_suggestion_default');
    }
  }

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return TranslatorGlobal.instance.translate(key, params: params);
  }

  List<String> get _sensitiveWords => _sensitiveTerms;

  bool _containsAny(String normalized, List<String> terms) {
    for (final term in terms) {
      if (normalized.contains(term)) {
        return true;
      }
    }
    return false;
  }

  static const List<_AiTermRule> _keywordRules = [
    _AiTermRule(['手链', '手鍊', 'bracelet']),
    _AiTermRule(['玉石', 'jade']),
    _AiTermRule(['翡翠', 'jadeite']),
    _AiTermRule(['和田玉', 'hotan jade']),
    _AiTermRule(['价格', '價格', '多少钱', '多少錢', 'price', 'cost']),
    _AiTermRule(['质量', '品質', 'quality']),
    _AiTermRule(['真假', '真偽', 'authentic']),
    _AiTermRule(['鉴定', '鑑定', 'certificate']),
    _AiTermRule(['优惠', '優惠', '折扣', 'discount']),
    _AiTermRule(['发货', '發貨', 'shipping']),
    _AiTermRule(['退货', '退貨', '退款', 'refund']),
    _AiTermRule(['换货', '換貨', 'exchange']),
    _AiTermRule(['尺寸', 'size']),
    _AiTermRule(['款式', 'style']),
    _AiTermRule(['颜色', '顏色', 'color']),
    _AiTermRule(['证书', '證書', 'certificate']),
    _AiTermRule(['保真', '正品', 'genuine']),
    _AiTermRule(['合作', 'cooperate']),
    _AiTermRule(['代发', '代發', 'dropshipping']),
    _AiTermRule(['批发', '批發', 'wholesale']),
  ];

  static const List<String> _negativeSentimentTerms = [
    '差',
    '假',
    '退款',
    '退货',
    '騙',
    '骗',
    '垃圾',
    '投诉',
    '投訴',
    '不满',
    '不滿',
    '生气',
    '生氣',
    'bad',
    'fake',
    'angry',
    'complaint',
  ];

  static const List<String> _positiveSentimentTerms = [
    '好',
    '喜欢',
    '喜歡',
    '满意',
    '滿意',
    '不错',
    '不錯',
    '推荐',
    '推薦',
    '合作',
    '可以',
    '考虑',
    '考慮',
    'good',
    'love',
    'satisfied',
    'recommend',
  ];

  static const List<String> _priceInquiryTerms = [
    '多少钱',
    '多少錢',
    '价格',
    '價格',
    '优惠',
    '優惠',
    '折扣',
    '预算',
    '預算',
    'price',
    'cost',
    'budget',
    'discount',
  ];

  static const List<String> _authenticityTerms = [
    '真假',
    '真偽',
    '鉴定',
    '鑑定',
    '正品',
    '证书',
    '證書',
    'authentic',
    'genuine',
    'certificate',
    'verify',
  ];

  static const List<String> _afterSalesTerms = [
    '退',
    '退款',
    '退货',
    '退貨',
    '换',
    '換',
    '换货',
    '換貨',
    '售后',
    '售後',
    'after-sales',
    'refund',
    'return',
    'exchange',
  ];

  static const List<String> _businessInquiryTerms = [
    '合作',
    '代发',
    '代發',
    '批发',
    '批發',
    'cooperate',
    'dropshipping',
    'wholesale',
    'distribution',
  ];

  static const List<String> _productRecommendationTerms = [
    '推荐',
    '推薦',
    '款式',
    '选择',
    '選擇',
    '送礼',
    '送禮',
    'style',
    'recommend',
    'choose',
    'gift',
  ];

  static const List<String> _urgentTerms = [
    '急',
    '马上',
    '馬上',
    '立刻',
    '尽快',
    '儘快',
    '投诉',
    '投訴',
    '退款',
    'urgent',
    'asap',
    'immediately',
  ];

  static const List<String> _sensitiveTerms = [
    '最',
    '第一',
    '绝对',
    '絕對',
    '唯一',
    '顶级',
    '頂級',
    '极致',
    '極致',
    '最佳',
    '最好',
    '最优',
    '最優',
    '最高',
    '最低',
    '最大',
    '首选',
    '首選',
    '国家级',
    '國家級',
    '全网第一',
    '全網第一',
    '销量第一',
    '銷量第一',
    '治疗',
    '治療',
    '治愈',
    '治癒',
    '保健',
    '药效',
    '藥效',
    '保值',
    '增值',
    '投资回报',
    '投資回報',
    'best',
    'number one',
    'top tier',
    'top-tier',
    'cure',
    'healing',
    'medical effect',
    'investment return',
  ];
}
