import 'package:huiyuyuan/l10n/translator_global.dart';

enum _PromptLanguage { zhCn, zhTw, en }

class AIPromptService {
  const AIPromptService();

  String getDefaultSystemPrompt({String language = 'zh_CN'}) {
    switch (_resolveLanguage(language)) {
      case _PromptLanguage.en:
        return _defaultSystemPromptEn;
      case _PromptLanguage.zhTw:
        return _defaultSystemPromptZhTw;
      case _PromptLanguage.zhCn:
        return _defaultSystemPromptZhCn;
    }
  }

  List<Map<String, String>> getQuickQuestions() {
    return [
      {'label': _t('ai_quick_1'), 'icon': 'verified'},
      {'label': _t('ai_quick_2'), 'icon': 'spa'},
      {'label': _t('ai_quick_3'), 'icon': 'shopping_bag'},
      {'label': _t('ai_quick_4'), 'icon': 'trending_up'},
      {'label': _t('ai_quick_5'), 'icon': 'help'},
      {'label': _t('ai_quick_6'), 'icon': 'watch'},
      {'label': _t('ai_quick_7'), 'icon': 'diamond'},
      {'label': _t('ai_quick_8'), 'icon': 'card_giftcard'},
    ];
  }

  String buildBusinessDialoguePrompt({
    required String shopName,
    required String category,
    required double rating,
    String? platform,
    int? followers,
  }) {
    final buffer = StringBuffer()
      ..writeln(_t('ai_business_prompt_intro'))
      ..writeln()
      ..writeln(
        _t('ai_business_prompt_shop_name', params: {'shopName': shopName}),
      )
      ..writeln(
        _t('ai_business_prompt_category', params: {'category': category}),
      )
      ..writeln(
        _t('ai_business_prompt_rating', params: {
          'rating': rating.toStringAsFixed(1),
        }),
      );

    if (platform != null && platform.isNotEmpty) {
      buffer.writeln(
        _t('ai_business_prompt_platform', params: {'platform': platform}),
      );
    }
    if (followers != null) {
      buffer.writeln(
        _t('ai_business_prompt_followers', params: {
          'followers': followers.toString(),
        }),
      );
    }

    buffer
      ..writeln()
      ..writeln(_t('ai_business_prompt_requirements'))
      ..writeln(_t('ai_business_prompt_requirement_1'))
      ..writeln(_t('ai_business_prompt_requirement_2'))
      ..writeln(_t('ai_business_prompt_requirement_3'))
      ..writeln(_t('ai_business_prompt_requirement_4'));

    return buffer.toString();
  }

  String get businessDialogueSystemPrompt =>
      _t('ai_business_dialogue_system_prompt');

  String buildOfflineDialogue({
    required String shopName,
    required String category,
    required double rating,
  }) {
    return _t('ai_business_dialogue_offline', params: {
      'shopName': shopName,
      'category': category,
      'rating': rating.toStringAsFixed(1),
    });
  }

  String buildProductDescriptionPrompt({
    required String productName,
    required String material,
    required double price,
    String? features,
    String? origin,
  }) {
    final buffer = StringBuffer()
      ..writeln(_productDescriptionPromptIntro)
      ..writeln()
      ..writeln('商品名称：$productName')
      ..writeln('材质：$material')
      ..writeln('价格：￥${price.toStringAsFixed(0)}');

    if (origin != null && origin.isNotEmpty) {
      buffer.writeln('产地：$origin');
    }
    if (features != null && features.isNotEmpty) {
      buffer.writeln('特点：$features');
    }

    buffer
      ..writeln()
      ..writeln('要求：');
    for (final requirement in _productDescriptionRequirements) {
      buffer.writeln(requirement);
    }

    return buffer.toString();
  }

  String get productDescriptionSystemPrompt =>
      _productDescriptionSystemPromptZhCn;

  String buildOfflineDescription({
    required String productName,
    required String material,
    required double price,
  }) {
    return '''
$productName，甄选天然$material打造，质感细腻，佩戴百搭。
整体风格简洁雅致，适合日常佩戴或送礼表达心意。参考价格：￥${price.toStringAsFixed(0)}。
''';
  }

  String getOfflineResponse(String message, {String language = 'zh_CN'}) {
    final lower = message.toLowerCase();
    final promptLanguage = _resolveLanguage(language);

    if (_containsAny(lower, _budgetKeywords(promptLanguage))) {
      return _budgetReply(promptLanguage);
    }

    if (_containsAny(lower, _authenticityKeywords(promptLanguage))) {
      return _authenticityReply(promptLanguage);
    }

    if (_containsAny(lower, _careKeywords(promptLanguage))) {
      return _careReply(promptLanguage);
    }

    if (_containsAny(lower, _recommendationKeywords(promptLanguage))) {
      return _recommendationReply(promptLanguage);
    }

    if (_containsAny(lower, _afterSalesKeywords(promptLanguage))) {
      return _afterSalesReply(promptLanguage);
    }

    return _genericReply(promptLanguage);
  }

  _PromptLanguage _resolveLanguage(String language) {
    switch (language.toLowerCase().replaceAll('-', '_')) {
      case 'en':
      case 'en_us':
      case 'en_gb':
        return _PromptLanguage.en;
      case 'zh_tw':
      case 'zh_hk':
      case 'zh_mo':
        return _PromptLanguage.zhTw;
      default:
        return _PromptLanguage.zhCn;
    }
  }

  List<String> _budgetKeywords(_PromptLanguage language) {
    switch (language) {
      case _PromptLanguage.en:
        return ['price', 'budget', 'how much', 'cost'];
      case _PromptLanguage.zhTw:
        return ['價格', '預算', '多少錢', '價', '预算', '价'];
      case _PromptLanguage.zhCn:
        return ['价格', '预算', '多少钱'];
    }
  }

  List<String> _authenticityKeywords(_PromptLanguage language) {
    switch (language) {
      case _PromptLanguage.en:
        return ['authentic', 'real', 'fake', 'certificate'];
      case _PromptLanguage.zhTw:
        return ['真假', '真偽', '鑑定', '證書', '证书'];
      case _PromptLanguage.zhCn:
        return ['真假', '鉴定', '证书'];
    }
  }

  List<String> _careKeywords(_PromptLanguage language) {
    switch (language) {
      case _PromptLanguage.en:
        return ['care', 'maintain', 'clean', 'storage'];
      case _PromptLanguage.zhTw:
        return ['保養', '清潔', '保存', '存放'];
      case _PromptLanguage.zhCn:
        return ['保养', '清洁', '保存'];
    }
  }

  List<String> _recommendationKeywords(_PromptLanguage language) {
    switch (language) {
      case _PromptLanguage.en:
        return ['recommend', 'gift', 'bracelet', 'necklace'];
      case _PromptLanguage.zhTw:
        return ['推薦', '送禮', '手鍊', '項鍊', '手链', '项链'];
      case _PromptLanguage.zhCn:
        return ['推荐', '送礼', '手链', '项链'];
    }
  }

  List<String> _afterSalesKeywords(_PromptLanguage language) {
    switch (language) {
      case _PromptLanguage.en:
        return ['return', 'refund', 'exchange', 'after-sales'];
      case _PromptLanguage.zhTw:
        return ['退貨', '退款', '換貨', '售後', '退货', '退款', '换货'];
      case _PromptLanguage.zhCn:
        return ['退货', '退款', '换货', '售后'];
    }
  }

  String _budgetReply(_PromptLanguage language) {
    return _selectByLanguage(
      language,
      en: '''
Our catalog covers a wide range of budgets.

- Entry level: around RMB 199 to 599
- Mid range: around RMB 599 to 3000
- Premium: above RMB 3000

If you share your budget and style preference, I can narrow it down for you.''',
      zhTw: '''
我們的商品價格涵蓋不同預算區間：

- 入門款：約人民幣 199 到 599 元
- 精選款：約人民幣 599 到 3000 元
- 高端款：人民幣 3000 元以上

如果您告訴我預算與偏好，我可以幫您更精準地推薦。''',
      zhCn: '''
我们的商品覆盖不同预算区间：

- 入门款：约 199 到 599 元
- 精选款：约 599 到 3000 元
- 高端款：3000 元以上

如果你告诉我预算和偏好，我可以继续帮你缩小范围。''',
    );
  }

  String _authenticityReply(_PromptLanguage language) {
    return _selectByLanguage(
      language,
      en: '''
When checking authenticity, focus on three things:

1. Certificate source and traceability
2. Material texture, weight, and natural structure
3. Seller credibility and after-sales support

If you tell me the material or send a product description, I can help you review it.''',
      zhTw: '''
判斷珠寶真偽時，建議重點看：

1. 證書與溯源資訊是否完整
2. 材質紋理、光澤與手感是否自然
3. 商家售後與平台保障是否可靠

若您提供材質或商品資訊，我可以協助一起判斷。''',
      zhCn: '''
判断珠宝真假时，建议重点看：

1. 证书和溯源信息是否完整
2. 材质纹理、光泽和手感是否自然
3. 商家售后和平台保障是否可靠

如果你愿意提供材质或商品信息，我可以帮你一起判断。''',
    );
  }

  String _careReply(_PromptLanguage language) {
    return _selectByLanguage(
      language,
      en: '''
For daily care:

- Avoid collisions and harsh chemicals
- Store pieces separately
- Wipe gently with a soft cloth
- Keep jade and gemstones away from extreme heat

If you tell me the exact material, I can give more precise care advice.''',
      zhTw: '''
日常保養建議：

- 避免碰撞與化學品接觸
- 分開存放，減少摩擦
- 使用柔軟乾布擦拭
- 玉石與彩寶避免長時間高溫曝曬

如果您告訴我具體材質，我可以提供更精準的保養方式。''',
      zhCn: '''
日常保养建议：

- 避免碰撞和化学品接触
- 分开存放，减少摩擦
- 用柔软干布擦拭
- 玉石和彩宝避免长时间高温暴晒

如果你告诉我具体材质，我可以给你更细的保养建议。''',
    );
  }

  String _recommendationReply(_PromptLanguage language) {
    return _selectByLanguage(
      language,
      en: '''
I can help recommend pieces by:

- Budget
- Material preference
- Daily wear or gifting use
- Elegant, classic, or statement style

Tell me those preferences and I will narrow down suitable options for you.''',
      zhTw: '''
我可以依據以下條件幫您推薦：

- 預算範圍
- 材質偏好
- 自戴或送禮
- 喜歡簡約、典雅或更有存在感的風格

您告訴我需求後，我就能幫您縮小選擇。''',
      zhCn: '''
我可以根据这些条件帮你推荐：

- 预算范围
- 材质偏好
- 自戴还是送礼
- 喜欢简约、典雅还是更有存在感的风格

把需求告诉我，我就能继续帮你筛选。''',
    );
  }

  String _afterSalesReply(_PromptLanguage language) {
    return _selectByLanguage(
      language,
      en: '''
For after-sales support, we recommend confirming:

- whether the item is still within the return or exchange window
- whether the certificate, packaging, and invoice are complete
- whether the item shows signs of wear or custom processing

If you tell me the order status and issue, I can help you judge the next step.''',
      zhTw: '''
關於售後處理，建議您先確認：

- 是否仍在退換貨時效內
- 證書、包裝與票據是否齊全
- 商品是否有佩戴痕跡或客製化處理

如果您告訴我訂單狀態與具體情況，我可以幫您一起判斷下一步。''',
      zhCn: '''
关于售后处理，建议你先确认：

- 是否仍在退换货时效内
- 证书、包装和票据是否齐全
- 商品是否有佩戴痕迹或定制处理

如果你告诉我订单状态和具体情况，我可以帮你一起判断下一步。''',
    );
  }

  String _genericReply(_PromptLanguage language) {
    return _selectByLanguage(
      language,
      en: '''
Hello! I am the Huiyuyuan AI assistant.

I can help with:
- jewelry recommendations
- jade and gemstone basics
- order and logistics guidance
- after-sales questions
- market and business suggestions

Tell me what you would like to know.''',
      zhTw: '''
您好！我是匯玉源 AI 助手。

我可以幫您：
- 推薦適合的珠寶款式
- 解答玉石與彩寶問題
- 提供訂單與物流指引
- 協助售後問題
- 分享市場與經營建議

請告訴我您想了解什麼。''',
      zhCn: '''
您好！我是汇玉源 AI 助手。

我可以帮您：
- 推荐适合的珠宝款式
- 解答玉石和彩宝问题
- 提供订单与物流指引
- 协助售后问题
- 分享市场与经营建议

请告诉我您想了解什么。''',
    );
  }

  String _selectByLanguage(
    _PromptLanguage language, {
    required String en,
    required String zhTw,
    required String zhCn,
  }) {
    switch (language) {
      case _PromptLanguage.en:
        return en;
      case _PromptLanguage.zhTw:
        return zhTw;
      case _PromptLanguage.zhCn:
        return zhCn;
    }
  }

  bool _containsAny(String message, List<String> keywords) {
    for (final keyword in keywords) {
      if (message.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return TranslatorGlobal.instance.translate(key, params: params);
  }
}

const String _defaultSystemPromptEn = '''
You are the Huiyuyuan AI assistant, a professional advisor for jewelry and jade commerce.

Brand profile:
- Brand: Huiyuyuan
- Positioning: B2B jewelry and jade trading platform
- Main categories: Hetian jade, jadeite, Southern Red agate, crystal, gemstones, gold jewelry
- Price range: RMB 99 to RMB 15,600
- Advantages: blockchain traceability, authenticity guarantee, drop shipping support

What you can do:
1. Answer jewelry and jade questions clearly and accurately.
2. Recommend suitable products based on budget, use case, and style.
3. Explain market trends in a practical business tone.
4. Help interpret certificates, materials, and authenticity cues.
5. Provide useful order, logistics, and after-sales guidance.

Important recommendation format:
When recommending products, append each product on its own line as:
[PRODUCT:PRODUCT_ID]

Style rules:
- Reply in English only.
- Be professional, warm, and concise.
- Use RMB when discussing prices.
- Do not use exaggerated or illegal advertising claims.
''';

const String _defaultSystemPromptZhTw = '''
你是「匯玉源 AI 助手」，是一位專業的珠寶玉石商務顧問。

品牌資訊：
- 品牌：匯玉源
- 定位：B2B 珠寶玉石交易平台
- 主營：和田玉、翡翠、南紅瑪瑙、水晶、彩寶、黃金飾品
- 價格區間：人民幣 99 到 15600 元
- 優勢：區塊鏈溯源、正品保障、支援一件代發

你的能力：
1. 解答珠寶玉石相關問題。
2. 根據預算、用途和風格推薦商品。
3. 提供市場趨勢和經營建議。
4. 協助理解證書、材質和真偽判斷。
5. 提供訂單、物流和售後指引。

商品推薦格式要求：
當你推薦商品時，請在回覆末尾逐行附上：
[PRODUCT:商品編號]

風格要求：
- 全程使用繁體中文。
- 專業、溫和、簡潔。
- 涉及價格時使用人民幣。
- 不可使用誇大或違規宣傳用語。
''';

const String _defaultSystemPromptZhCn = '''
你是“汇玉源 AI 助手”，是一位专业的珠宝玉石商务顾问。

品牌信息：
- 品牌：汇玉源
- 定位：B2B 珠宝玉石交易平台
- 主营：和田玉、翡翠、南红玛瑙、水晶、彩宝、黄金饰品
- 价格区间：人民币 99 到 15600 元
- 优势：区块链溯源、正品保障、支持一件代发

你的能力：
1. 解答珠宝玉石相关问题。
2. 根据预算、用途和风格推荐商品。
3. 提供市场趋势和经营建议。
4. 协助理解证书、材质和真假判断。
5. 提供订单、物流和售后指引。

商品推荐格式要求：
当你推荐商品时，请在回复末尾逐行附上：
[PRODUCT:商品编号]

风格要求：
- 全程使用简体中文。
- 专业、亲切、简洁。
- 涉及价格时使用人民币。
- 不可使用夸大或违规宣传用语。
''';

const String _productDescriptionPromptIntro = '请为以下珠宝商品生成一段精炼、合规、适合电商展示的描述文案：';

const List<String> _productDescriptionRequirements = [
  '1. 突出材质、佩戴场景和审美特点。',
  '2. 可以点到寓意，但不承诺升值或功效。',
  '3. 控制在 120 到 180 字。',
  '4. 风格温润高级。',
];

const String _productDescriptionSystemPromptZhCn =
    '你是一位专业的珠宝商品文案顾问，擅长输出简洁、准确、合规的商品描述。';
