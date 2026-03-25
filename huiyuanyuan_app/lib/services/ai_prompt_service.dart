class AIPromptService {
  const AIPromptService();

  String getDefaultSystemPrompt({String language = 'zh_CN'}) {
    final langInstruction = switch (language) {
      'en' =>
        '\n\n【Language Requirement】\nYou MUST reply in English. All responses should be in English.',
      'zh_TW' => '\n\n【語言要求】\n你必須使用繁體中文回覆，所有回答都要使用繁體中文。',
      _ => '',
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

  List<Map<String, String>> getQuickQuestions() {
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

  String buildBusinessDialoguePrompt({
    required String shopName,
    required String category,
    required double rating,
    String? platform,
    int? followers,
  }) {
    return '''请为以下店铺生成一段商务合作邀约话术：

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
  }

  String get businessDialogueSystemPrompt =>
      '你是一位经验丰富的珠宝行业商务拓展专家，擅长撰写高转化率的商务邀约话术。';

  String buildOfflineDialogue({
    required String shopName,
    required String category,
    required double rating,
  }) {
    return '''您好！我是汇玉源珠宝商务代表。

看到贵店"$shopName"主营$category，评分高达$rating分，店铺经营得非常出色！

我们汇玉源专注天然玉石福利款手链，价位199-599元，每件商品都有区块链溯源证书，支持一件代发，利润空间充足。

诚邀您考虑合作，期待进一步交流！🤝''';
  }

  String buildProductDescriptionPrompt({
    required String productName,
    required String material,
    required double price,
    String? features,
    String? origin,
  }) {
    return '''请为以下珠宝产品生成一段精美的商品描述文案：

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
  }

  String get productDescriptionSystemPrompt =>
      '你是专业的珠宝文案撰写专家，深谙中国传统玉石文化，擅长用优美的语言描述珠宝的天然之美、文化底蕴和匠心工艺。';

  String buildOfflineDescription({
    required String productName,
    required String material,
    required double price,
  }) {
    return '''$productName，精选天然$material，质地细腻温润，光泽内敛优雅。

采用传统手工工艺精心打磨，每一颗珠子都经过严格筛选，呈现出$material独有的温润质感。

寓意美好，适合日常佩戴或作为礼物赠送亲友。搭配区块链溯源证书，品质有保障。

💰 福利价：¥${price.toInt()}元''';
  }

  String getOfflineResponse(String message, {String language = 'zh_CN'}) {
    final lowered = message.toLowerCase();

    if (lowered.contains('价格') ||
        lowered.contains('多少钱') ||
        lowered.contains('预算')) {
      return '我们的商品价格覆盖面广，从入门到高端都有：\n\n'
          '💰 入门福利款：199-599元（南红转运珠、紫水晶手串等）\n'
          '✨ 中端精品：599-3000元（翡翠吊坠、和田玉手链等）\n'
          '👑 高端甄选：3000元以上（红宝石戒指、蓝宝石吊坠等）\n\n'
          '您可以在商城页面查看具体款式和价格，每件商品都有权威鉴定证书。有任何问题随时问我哦~ 😊';
    }

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
}
