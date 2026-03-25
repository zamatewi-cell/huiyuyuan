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
          ? '内容包含以下违禁词：${violations.join("、")}，请修改后发送。'
          : '内容符合规范。',
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

    if (rating >= 4.8) {
      score += 30;
      reasons.add('店铺评分优秀 ($rating分)');
    } else if (rating >= 4.7) {
      score += 20;
      reasons.add('店铺评分良好 ($rating分)');
    } else {
      score += 10;
      reasons.add('店铺评分一般 ($rating分)');
    }

    if (conversionRate >= 5) {
      score += 30;
      reasons.add('转化率出色 ($conversionRate%)');
    } else if (conversionRate >= 3) {
      score += 20;
      reasons.add('转化率良好 ($conversionRate%)');
    } else {
      score += 10;
      reasons.add('转化率一般 ($conversionRate%)');
    }

    if (followers >= 100000) {
      score += 25;
      reasons.add('粉丝量大 (${(followers / 10000).toStringAsFixed(1)}万)');
    } else if (followers >= 50000) {
      score += 15;
      reasons.add('粉丝量中等 (${(followers / 10000).toStringAsFixed(1)}万)');
    } else {
      score += 10;
      reasons.add('粉丝量较少 ($followers)');
    }

    if (negativeRate != null) {
      if (negativeRate < 0.01) {
        score += 15;
        reasons.add('差评率极低 (${(negativeRate * 100).toStringAsFixed(1)}%)');
      } else if (negativeRate < 0.02) {
        score += 10;
        reasons.add('差评率较低 (${(negativeRate * 100).toStringAsFixed(1)}%)');
      } else {
        reasons.add('⚠️ 差评率偏高 (${(negativeRate * 100).toStringAsFixed(1)}%)');
      }
    }

    late final String decision;
    late final String priority;

    if (score >= 80) {
      decision = '强烈推荐联系';
      priority = 'high';
    } else if (score >= 60) {
      decision = '建议联系';
      priority = 'medium';
    } else {
      decision = '暂不推荐';
      priority = 'low';
    }

    return {
      'shopName': shopName,
      'score': score.toInt(),
      'decision': decision,
      'priority': priority,
      'reasons': reasons,
      'suggestedAction': score >= 60 ? '可使用AI生成个性化话术后主动联系' : '建议观察一段时间后再评估',
    };
  }

  List<String> _extractKeywords(String content) {
    final keywordPatterns = [
      '手链',
      '玉石',
      '翡翠',
      '和田玉',
      '价格',
      '多少钱',
      '质量',
      '真假',
      '鉴定',
      '优惠',
      '折扣',
      '发货',
      '退货',
      '退款',
      '换货',
      '尺寸',
      '款式',
      '颜色',
      '证书',
      '保真',
      '正品',
      '合作',
      '代发',
      '批发',
    ];

    final found = <String>[];
    for (final keyword in keywordPatterns) {
      if (content.contains(keyword)) {
        found.add(keyword);
      }
    }
    return found;
  }

  String _analyzeSentiment(String content) {
    final negativeWords = ['差', '假', '退', '骗', '垃圾', '投诉', '不满', '生气'];
    final positiveWords = ['好', '喜欢', '满意', '不错', '推荐', '合作', '可以', '考虑'];

    var negativeCount = 0;
    var positiveCount = 0;

    for (final word in negativeWords) {
      if (content.contains(word)) negativeCount++;
    }
    for (final word in positiveWords) {
      if (content.contains(word)) positiveCount++;
    }

    if (negativeCount > positiveCount) return 'negative';
    if (positiveCount > negativeCount) return 'positive';
    return 'neutral';
  }

  String _identifyIntent(String content) {
    if (content.contains('多少钱') ||
        content.contains('价格') ||
        content.contains('优惠')) {
      return 'price_inquiry';
    }
    if (content.contains('真假') ||
        content.contains('鉴定') ||
        content.contains('正品')) {
      return 'authenticity_check';
    }
    if (content.contains('退') ||
        content.contains('换') ||
        content.contains('售后')) {
      return 'after_sales';
    }
    if (content.contains('合作') ||
        content.contains('代发') ||
        content.contains('批发')) {
      return 'business_inquiry';
    }
    if (content.contains('推荐') ||
        content.contains('款式') ||
        content.contains('选择')) {
      return 'product_recommendation';
    }
    return 'general_inquiry';
  }

  String _assessUrgency(String content) {
    const urgentWords = ['急', '马上', '立刻', '尽快', '投诉', '退款'];
    for (final word in urgentWords) {
      if (content.contains(word)) return 'high';
    }
    return 'normal';
  }

  String _generateSuggestion(String sentiment, String intent) {
    if (sentiment == 'negative') {
      return '客户情绪负面，建议立即安抚，提供质检证书和无理由退换承诺。';
    }

    switch (intent) {
      case 'price_inquiry':
        return '客户询价意向明确，可推荐福利款手链（199-599元），强调性价比。';
      case 'authenticity_check':
        return '客户关注真伪，重点介绍区块链溯源证书，可提供质检报告链接。';
      case 'business_inquiry':
        return '客户有合作意向，可详细介绍一件代发政策和利润空间。';
      case 'after_sales':
        return '售后问题需优先处理，查询订单状态并提供解决方案。';
      default:
        return '客户意向良好，可主动推荐热销福利款手链。';
    }
  }

  static const _sensitiveWords = [
    '最',
    '第一',
    '绝对',
    '唯一',
    '顶级',
    '极致',
    '最佳',
    '最好',
    '最优',
    '最高',
    '最低',
    '最大',
    '首选',
    '国家级',
    '全网第一',
    '销量第一',
    '治疗',
    '治愈',
    '保健',
    '药效',
    '保值',
    '增值',
    '投资回报',
  ];
}
