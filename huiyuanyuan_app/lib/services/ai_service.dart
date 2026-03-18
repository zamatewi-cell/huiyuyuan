/// 汇玉源 - AI智能服务
///
/// 功能:
/// - OpenRouter 多模态智能对话（珠宝行业专家角色）
/// - 独立思考决策
/// - 商务话术生成
/// - 聊天内容分析
/// - 敏感词过滤
/// - 商品上下文感知
/// - 流式输出支持
/// - 图片分析（预留）
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/product_service.dart';

/// AI服务类
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late final Dio _dio;
  final ProductService _productService = ProductService();
  bool _initialized = false;

  /// 初始化
  void _ensureInitialized() {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.openRouterBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': AppConfig.openRouterSiteUrl,
        'X-Title': AppConfig.openRouterAppName,
      },
    ));

    _initialized = true;
  }

  // ============ 核心对话功能 ============

  /// 智能对话
  ///
  /// [userMessage] 用户消息
  /// [history] 历史对话记录
  /// [systemPrompt] 系统提示词(可选)
  /// [includeProducts] 是否注入商品上下文
  Future<String> chat({
    required String userMessage,
    List<Map<String, String>>? history,
    String? systemPrompt,
    bool includeProducts = true,
    String language = 'zh_CN',
    bool forceOffline = false,
  }) async {
    _ensureInitialized();

    // 强制离线模式（供测试使用）
    if (forceOffline) {
      return _getOfflineResponse(userMessage, language: language);
    }

    // 预先计算系统提示词
    String finalSystemPrompt =
        systemPrompt ?? _getDefaultSystemPrompt(language: language);
    if (includeProducts && systemPrompt == null) {
      final productContext = await _getProductContext();
      if (productContext.isNotEmpty) {
        finalSystemPrompt += '\n\n$productContext';
      }
    }

    if (!AppConfig.openRouterApiKey.contains('YOUR_') &&
        AppConfig.openRouterApiKey.isNotEmpty) {
      try {
        final messages = _buildChatMessages(
          userMessage: userMessage,
          history: history,
          systemPrompt: finalSystemPrompt,
        );

        final response = await _dio.post(
          '/chat/completions',
          data: {
            'model': AppConfig.openRouterModel,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 2000,
            'stream': false,
            'reasoning': {'exclude': true},
          },
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final message = choices[0]['message'] as Map<String, dynamic>?;
            final content = _extractTextContent(message?['content']);
            if (content.isNotEmpty) {
              return _filterSensitiveWords(content);
            }
          }
        }
      } catch (_) {
        // OpenRouter 失败，降级到离线模式
      }
    }

    return _getOfflineResponse(userMessage, language: language);
  }

  /// 流式对话（逐步回调输出）
  ///
  /// [onToken] 每收到一个 token 时的回调
  /// [onDone] 全部结束时的回调
  Future<void> chatStream({
    required String userMessage,
    List<Map<String, String>>? history,
    String? systemPrompt,
    bool includeProducts = true,
    String language = 'zh_CN',
    required Function(String token) onToken,
    required Function(String fullResponse) onDone,
    Function(String error)? onError,
  }) async {
    _ensureInitialized();

    // 预先计算系统提示词
    String finalSystemPrompt =
        systemPrompt ?? _getDefaultSystemPrompt(language: language);
    if (includeProducts && systemPrompt == null) {
      final productContext = await _getProductContext();
      if (productContext.isNotEmpty) {
        finalSystemPrompt += '\n\n$productContext';
      }
    }

    if (!AppConfig.openRouterApiKey.contains('YOUR_') &&
        AppConfig.openRouterApiKey.isNotEmpty) {
      try {
        final messages = _buildChatMessages(
          userMessage: userMessage,
          history: history,
          systemPrompt: finalSystemPrompt,
        );

        final response = await _dio.post(
          '/chat/completions',
          data: {
            'model': AppConfig.openRouterModel,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 2000,
            'stream': true,
            'reasoning': {'exclude': true},
          },
          options: Options(responseType: ResponseType.stream),
        );

        final StringBuffer fullResponseBuffer = StringBuffer();
        final stream = response.data.stream as Stream<List<int>>;

        // SSE 行缓冲：防止 UTF-8 多字节字符或行被拆分到多个 chunk
        String sseBuffer = '';

        await for (final chunk in stream) {
          sseBuffer += utf8.decode(chunk, allowMalformed: true);

          while (sseBuffer.contains('\n')) {
            final newlineIndex = sseBuffer.indexOf('\n');
            final line = sseBuffer.substring(0, newlineIndex).trim();
            sseBuffer = sseBuffer.substring(newlineIndex + 1);

            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') continue;

              try {
                final jsonData = json.decode(data) as Map<String, dynamic>;
                final choices = jsonData['choices'] as List<dynamic>?;
                if (choices != null && choices.isNotEmpty) {
                  final delta = choices[0]['delta'] as Map<String, dynamic>?;
                  final content = _extractTextContent(delta?['content']);
                  if (content.isNotEmpty) {
                    fullResponseBuffer.write(content);
                    onToken(content);
                  }
                }
              } catch (_) {
                // JSON 解析失败忽略
              }
            }
          }
        }

        final result = _filterSensitiveWords(fullResponseBuffer.toString());
        onDone(result);
        return;
      } catch (_) {
        // OpenRouter 失败，降级到离线模式
      }
    }

    // 两者均不可用，降级到离线模式（打字机效果）
    final fallback =
        '[离线模式] ${_getOfflineResponse(userMessage, language: language)}';
    for (int i = 0; i < fallback.length; i++) {
      onToken(fallback[i]);
      await Future.delayed(const Duration(milliseconds: 20));
    }
    onDone(fallback);
  }

  List<Map<String, String>> _buildChatMessages({
    required String userMessage,
    List<Map<String, String>>? history,
    required String systemPrompt,
  }) {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
    ];

    if (history != null && history.isNotEmpty) {
      messages.addAll(history);
    }

    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    return messages;
  }

  String _extractTextContent(dynamic content) {
    if (content is String) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final text = item['text'];
          if (text is String) {
            buffer.write(text);
          }
        }
      }
      return buffer.toString();
    }

    return '';
  }

  /// 默认系统提示词 - 珠宝行业专家角色（支持多语言）
  String _getDefaultSystemPrompt({String language = 'zh_CN'}) {
    // 语言指令映射
    final langInstruction = switch (language) {
      'en' =>
        '\n\n【Language Requirement】\nYou MUST reply in English. All responses should be in English.',
      'zh_TW' => '\n\n【語言要求】\n你必須使用繁體中文回覆，所有回答都要使用繁體中文。',
      _ => '', // 简体中文为默认，无需额外指令
    };

    return '''你是"汇玉源智能助手"，一位专业的珠宝玉器行业顾问。

【品牌信息】
- 品牌：汇玉源（Hui Yu Yuan）
- 定位：B2B 珠宝玉器交易平台
- 主营：天然玉石福利款手链、翡翠、和田玉、南红玛瑙、紫水晶、蓝宝石、红宝石、黄金等
- 价位区间：199-15600元
- 特色：区块链溯源证书、正品保证、假一赔十、一件代发

【服务能力】
1. 珠宝知识咨询：解答关于和田玉、翡翠、南红玛瑙、紫水晶、蓝宝石、红宝石、
   黄金等各类珠宝玉石的鉴别、选购、保养知识。
2. 商品推荐：根据用户需求（预算、用途、偏好）推荐合适的商品。
3. 市场行情：提供珠宝行业动态、价格趋势分析。
4. 鉴定辅助：协助用户了解珠宝鉴定证书解读、真伪辨别要点。
5. 经营建议：为珠宝批发商提供进货、定价、营销等经营建议。
6. 售后服务：解答退换货、物流查询等问题。

【商品推荐格式要求（极其重要）】
当用户让你推荐商品时，你必须在回答的末尾使用以下标签格式列出推荐商品：
[PRODUCT:商品编号]
例如：
[PRODUCT:HYY-HT001]
[PRODUCT:HYY-FC002]
每行只写一个标签，不要加任何其他内容在标签行。
在标签前的文字描述中，正常用文字介绍这些商品的特点、价格等。

【回答风格】
- 专业但亲切，避免过于学术化
- 涉及价格时使用人民币（¥）
- 推荐商品时一定要附上 [PRODUCT:ID] 标签
- 如果问题超出珠宝领域，礼貌告知并引导回珠宝话题
- 适当使用emoji增加亲和力（如💎🌟✨🛡️📦等）
- 回答简洁明了，控制在300字以内
- 遵守《广告法》，不使用极限词

【合规要求】
- 不承诺保值增值
- 不宣传治疗功效
- 价格透明真实
- 材质如实描述$langInstruction''';
  }

  /// 生成商品上下文摘要（注入到 system prompt）
  Future<String> _getProductContext() async {
    try {
      final products = await _productService.getProducts(pageSize: 50);
      if (products.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln('【平台在售商品概览】');
      buffer.writeln('目前汇玉源商城共有 ${products.length} 件在售商品，摘要如下：');

      // 按材质分组
      final grouped = <String, List<String>>{};
      for (final p in products) {
        grouped.putIfAbsent(p.material, () => []);
        grouped[p.material]!.add(
            '${p.name}(编号:${p.id}, ¥${p.price.toInt()}, ${p.category}, ${p.origin ?? ""})');
      }

      for (final entry in grouped.entries) {
        buffer.writeln('\n${entry.key}系列:');
        for (final item in entry.value) {
          buffer.writeln('- $item');
        }
      }

      buffer.writeln('\n当用户询问或需要推荐商品时，请从以上商品中选择合适的商品，并使用 [PRODUCT:商品编号] 标签引用。');
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  // ============ 快捷提问预设 ============

  /// 获取快捷提问列表
  static List<Map<String, String>> getQuickQuestions() {
    return [
      {'label': '和田玉怎么鉴别真假？', 'icon': 'verified'},
      {'label': '翡翠保养注意什么？', 'icon': 'spa'},
      {'label': '500元预算推荐什么？', 'icon': 'shopping_bag'},
      {'label': '最近玉石行情如何？', 'icon': 'trending_up'},
      {'label': '南红和玛瑙有什么区别？', 'icon': 'help'},
      {'label': '你们有哪些热门手链？', 'icon': 'watch'},
      {'label': '黄金首饰怎么选？', 'icon': 'diamond'},
      {'label': '珠宝送礼怎么挑？', 'icon': 'card_giftcard'},
    ];
  }

  // ============ 商务话术生成 ============

  /// 生成商务邀约话术
  Future<String> generateBusinessDialogue({
    required String shopName,
    required String category,
    required double rating,
    String? platform,
    int? followers,
    List<Map<String, String>>? history,
  }) async {
    _ensureInitialized();

    final prompt = '''请为以下店铺生成一段商务合作邀约话术：

【店铺信息】
- 店铺名称：$shopName
- 主营品类：$category
- 店铺评分：$rating分
${platform != null ? '- 所属平台：$platform' : ''}
${followers != null ? '- 粉丝数量：$followers' : ''}

【我方信息】
- 品牌：汇玉源
- 主营：天然玉石福利款手链
- 价位：199-599元
- 优势：区块链溯源证书、一件代发、利润空间充足

【要求】
1. 开场白要有针对性，体现对店铺的了解
2. 突出合作优势和互惠点
3. 语气专业但不生硬
4. 字数控制在150字以内
5. 符合《广告法》，不使用极限词''';

    try {
      final response = await chat(
        userMessage: prompt,
        systemPrompt: '你是一位经验丰富的珠宝行业商务拓展专家，擅长撰写高转化率的商务邀约话术。',
        includeProducts: false,
      );
      return response;
    } catch (e) {
      return _generateOfflineDialogue(shopName, category, rating);
    }
  }

  /// 离线商务话术
  String _generateOfflineDialogue(
      String shopName, String category, double rating) {
    return '''您好！我是汇玉源珠宝商务代表。
    
看到贵店"$shopName"主营$category，评分高达$rating分，店铺经营得非常出色！

我们汇玉源专注天然玉石福利款手链，价位199-599元，每件商品都有区块链溯源证书，支持一件代发，利润空间充足。

诚邀您考虑合作，期待进一步交流！🤝''';
  }

  // ============ 产品描述优化 ============

  /// 生成AI优化的产品描述（珠宝行业特色增强版）
  Future<String> generateProductDescription({
    required String productName,
    required String material,
    required double price,
    String? features,
    String? origin,
  }) async {
    final prompt = '''请为以下珠宝产品生成一段精美的商品描述文案：

【产品信息】
- 产品名称：$productName
- 材质：$material
- 价格：¥$price
${origin != null ? '- 产地：$origin' : ''}
${features != null ? '- 特点：$features' : ''}

【文案要求】
1. 开头突出材质的产地特色和天然属性（如"新疆和田籽料"、"缅甸A货翡翠"）
2. 使用珠宝行业专业术语（如"种水"、"油润度"、"满色"、"冰种"等）
3. 融入文化寓意和情感价值（如"寓意平安"、"招财纳福"等）
4. 适当提及收藏价值和艺术价值（但不承诺升值）
5. 结尾强调品质保障（区块链溯源、鉴定证书）
6. 字数控制在100-200字
7. 风格温润典雅，体现珠宝的高雅气质
8. 符合《广告法》，不使用极限词和虚假宣传''';

    try {
      return await chat(
        userMessage: prompt,
        systemPrompt: '你是专业的珠宝文案撰写专家，深谙中国传统玉石文化，擅长用优美的语言描述珠宝的天然之美、文化底蕴和匠心工艺。',
        includeProducts: false,
      );
    } catch (e) {
      return _generateOfflineDescription(productName, material, price);
    }
  }

  /// 离线产品描述
  String _generateOfflineDescription(
      String productName, String material, double price) {
    return '''$productName，精选天然$material，质地细腻温润，光泽内敛优雅。

采用传统手工工艺精心打磨，每一颗珠子都经过严格筛选，呈现出$material独有的温润质感。

寓意美好，适合日常佩戴或作为礼物赠送亲友。搭配区块链溯源证书，品质有保障。

💰 福利价：¥${price.toInt()}元''';
  }

  // ============ 聊天内容分析 ============

  /// 分析聊天内容
  Future<Map<String, dynamic>> analyzeChatContent(String content) async {
    // 关键词提取
    final keywords = _extractKeywords(content);

    // 情感分析
    final sentiment = _analyzeSentiment(content);

    // 意图识别
    final intent = _identifyIntent(content);

    // 生成建议
    final suggestion = await _generateSuggestion(content, sentiment, intent);

    return {
      'keywords': keywords,
      'sentiment': sentiment,
      'intent': intent,
      'suggestion': suggestion,
      'urgency': _assessUrgency(content),
    };
  }

  /// 提取关键词
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

  /// 情感分析
  String _analyzeSentiment(String content) {
    final negativeWords = ['差', '假', '退', '骗', '垃圾', '投诉', '不满', '生气'];
    final positiveWords = ['好', '喜欢', '满意', '不错', '推荐', '合作', '可以', '考虑'];

    int negativeCount = 0;
    int positiveCount = 0;

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

  /// 意图识别
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

  /// 评估紧急程度
  String _assessUrgency(String content) {
    final urgentWords = ['急', '马上', '立刻', '尽快', '投诉', '退款'];
    for (final word in urgentWords) {
      if (content.contains(word)) return 'high';
    }
    return 'normal';
  }

  /// 生成建议
  Future<String> _generateSuggestion(
      String content, String sentiment, String intent) async {
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

  // ============ 敏感词过滤 ============

  /// 广告法敏感词列表
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

  /// 过滤敏感词
  String _filterSensitiveWords(String content) {
    String filtered = content;
    for (final word in _sensitiveWords) {
      filtered = filtered.replaceAll(word, '***');
    }
    return filtered;
  }

  /// 检查内容合规性
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

  // ============ 离线响应 ============

  /// 离线智能回复（增强版 - 支持多语言）
  String _getOfflineResponse(String message, {String language = 'zh_CN'}) {
    final lowered = message.toLowerCase();

    // 价格相关
    if (lowered.contains('价格') ||
        lowered.contains('多少钱') ||
        lowered.contains('预算')) {
      return '我们的商品价格覆盖面广，从入门到高端都有：\n\n'
          '💰 入门福利款：199-599元（南红转运珠、紫水晶手串等）\n'
          '✨ 中端精品：599-3000元（翡翠吊坠、和田玉手链等）\n'
          '👑 高端甄选：3000元以上（红宝石戒指、蓝宝石吊坠等）\n\n'
          '您可以在商城页面查看具体款式和价格，每件商品都有权威鉴定证书。有任何问题随时问我哦~ 😊';
    }

    // 鉴别真假
    if (lowered.contains('真假') ||
        lowered.contains('正品') ||
        lowered.contains('鉴别') ||
        lowered.contains('鉴定')) {
      return '珠宝鉴别的几个关键要点：\n\n'
          '🔍 **看证书**：正规珠宝必须有权威机构（如NGTC、GTC、GIA）出具的鉴定证书\n'
          '💧 **看质感**：天然玉石触感温润、有重感，假货通常偏轻偏涩\n'
          '🔦 **看透光**：用手电筒照射观察内部结构和纹理\n'
          '🛡️ **选平台**：汇玉源每件商品都配有区块链溯源证书，扫码即可查验真伪\n\n'
          '假一赔十，让您买得放心！💎';
    }

    // 保养相关
    if (lowered.contains('保养') ||
        lowered.contains('保存') ||
        lowered.contains('清洗')) {
      return '珠宝保养小贴士 ✨\n\n'
          '💎 **翡翠/玉石**：避免碰撞、远离高温、定期用清水擦拭\n'
          '🟡 **黄金**：避免接触化学品（香水、洗涤剂）、单独存放\n'
          '💜 **水晶**：避免长时间暴晒、用软布擦拭\n'
          '🔴 **南红玛瑙**：避免剧烈温差、防磕碰\n\n'
          '通用建议：不佩戴时放入软布袋或首饰盒中单独保管，定期清洁保持光泽。';
    }

    // 推荐相关
    if (lowered.contains('推荐') ||
        lowered.contains('送人') ||
        lowered.contains('送礼')) {
      return '为您推荐几款热门好物 🎁\n\n'
          '1. 🏆 新疆和田玉籽料福运手链 ¥299 — 油润细腻，寓意福运连连\n'
          '2. 💚 缅甸翡翠平安扣吊坠 ¥1580 — 冰种质地，高贵典雅\n'
          '3. ❤️ 凉山南红玛瑙转运珠手链 ¥199 — 色泽浓郁，性价比超高\n'
          '4. 💛 3D硬金转运珠吊坠 ¥580 — 时尚百搭，日常必备\n\n'
          '点击商城页面即可查看详情~ 💎';
    }

    // 退换货
    if (lowered.contains('退') ||
        lowered.contains('换') ||
        lowered.contains('售后')) {
      return '我们的售后保障 🛡️\n\n'
          '📦 **7天无理由退换**：收到商品7天内可申请退换\n'
          '🚚 **运费承担**：退换货运费由我们承担\n'
          '✅ **正品保障**：假一赔十，品质有保障\n'
          '📞 **快速响应**：在"我的订单"中提交申请，24小时内处理\n\n'
          '如需退换，请在「我的」→「我的订单」中提交申请，我们会尽快为您处理~ 😊';
    }

    // 行情相关
    if (lowered.contains('行情') ||
        lowered.contains('趋势') ||
        lowered.contains('市场')) {
      return '近期珠宝市场动态 📊\n\n'
          '📈 **和田玉**：优质籽料持续走俏，尤其是羊脂白玉\n'
          '💚 **翡翠**：缅甸翡翠原石开采收紧，中高端翡翠价格稳中有升\n'
          '🔴 **南红玛瑙**：凉山南红资源日益稀缺，精品收藏价值看好\n'
          '🟡 **黄金**：国际金价波动频繁，古法黄金工艺品市场备受青睐\n\n'
          '建议关注品质优良的天然玉石，在汇玉源商城有精选好货等您来~ 💎';
    }

    // 南红和玛瑙区别
    if (lowered.contains('南红') &&
        (lowered.contains('区别') ||
            lowered.contains('不同') ||
            lowered.contains('差别'))) {
      return '南红和普通玛瑙的区别 🔍\n\n'
          '南红是玛瑙的一个稀有品种，区别在于：\n\n'
          '1. **颜色**：南红以红色为主，色泽浓郁鲜艳；普通玛瑙颜色多样\n'
          '2. **质地**：南红质地温润如玉，有胶质感；普通玛瑙通常更透\n'
          '3. **产地**：优质南红产于四川凉山、云南保山\n'
          '4. **价值**：因稀缺性，南红价值远高于普通玛瑙\n'
          '5. **观赏性**：南红可雕可盘，蕴含丰富的文化寓意\n\n'
          '汇玉源有多款南红精品，欢迎到商城选购~ 💎';
    }

    // 默认欢迎（多语言）
    if (language == 'en') {
      return 'Hello! I\'m Hui Yu Yuan AI Assistant 🌟\n\n'
          'I can help you with:\n'
          '💎 Recommend jewelry that suits you\n'
          '🔍 Identify and authenticate gemstones\n'
          '📊 Analyze jewelry market trends\n'
          '📦 Track orders and logistics\n'
          '🛠️ Handle after-sales issues\n'
          '💡 Provide business advice\n\n'
          'How can I help you today?';
    }
    if (language == 'zh_TW') {
      return '您好！我是匯玉源智能助手 🌟\n\n'
          '我可以幫您：\n'
          '💎 推薦適合您的珠寶款式\n'
          '🔍 解答玉石鑑別相關問題\n'
          '📊 分析珠寶市場行情趨勢\n'
          '📦 查詢訂單和物流資訊\n'
          '🛠️ 處理售後退換問題\n'
          '💡 提供珠寶經營建議\n\n'
          '請問有什麼可以幫您的？';
    }
    return '您好！我是汇玉源智能助手 🌟\n\n'
        '我可以帮您：\n'
        '💎 推荐适合您的珠宝款式\n'
        '🔍 解答玉石鉴别相关问题\n'
        '📊 分析珠宝市场行情趋势\n'
        '📦 查询订单和物流信息\n'
        '🛠️ 处理售后退换问题\n'
        '💡 提供珠宝经营建议\n\n'
        '您可以试试问我：\n'
        '• "和田玉怎么鉴别真假？"\n'
        '• "500元预算推荐什么？"\n'
        '• "翡翠保养注意什么？"\n\n'
        '请问有什么可以帮您的？';
  }

  // ============ 独立思考决策 ============

  /// AI独立思考 - 店铺评估
  Future<Map<String, dynamic>> evaluateShop({
    required String shopName,
    required double rating,
    required double conversionRate,
    required int followers,
    double? negativeRate,
  }) async {
    // 评分计算
    double score = 0;
    final reasons = <String>[];

    // 评分维度
    if (rating >= 4.8) {
      score += 30;
      reasons.add('店铺评分优秀 (${rating}分)');
    } else if (rating >= 4.7) {
      score += 20;
      reasons.add('店铺评分良好 (${rating}分)');
    } else {
      score += 10;
      reasons.add('店铺评分一般 (${rating}分)');
    }

    // 转化率
    if (conversionRate >= 5) {
      score += 30;
      reasons.add('转化率出色 (${conversionRate}%)');
    } else if (conversionRate >= 3) {
      score += 20;
      reasons.add('转化率良好 (${conversionRate}%)');
    } else {
      score += 10;
      reasons.add('转化率一般 (${conversionRate}%)');
    }

    // 粉丝量
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

    // 差评率
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

    // 决策
    String decision;
    String priority;

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
}
