// 汇玉源 - AI 服务测试
//
// 测试内容:
// - 智能对话离线回复
// - 商务话术生成（离线）
// - 产品描述生成（离线）
// - 聊天内容分析
// - 敏感词过滤
// - 店铺评估
//
// 注意: 这些测试主要验证离线逻辑，不依赖实际 API 调用
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuanyuan/config/api_config.dart';
import 'package:huiyuanyuan/services/ai_service.dart';
import 'package:huiyuanyuan/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AIService aiService;
  late bool originalUseMockApi;

  setUp(() async {
    originalUseMockApi = ApiConfig.useMockApi;
    ApiConfig.useMockApi = true;
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await StorageService().clearAll();
    aiService = AIService();
  });

  tearDown(() {
    ApiConfig.useMockApi = originalUseMockApi;
  });

  group('AI 服务初始化测试', () {
    test('AIService 应为单例', () {
      final instance1 = AIService();
      final instance2 = AIService();
      expect(identical(instance1, instance2), true);
    });
  });

  group('离线智能回复测试', () {
    test('价格相关问题应返回合理回复', () async {
      final response = await aiService.chat(
        userMessage: '这个多少钱？',
        forceOffline: true,
      );
      
      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
      // 离线模式应包含价格相关内容
      expect(response.contains('199') || response.contains('599') || response.contains('福利款'), true);
    });

    test('真假鉴定问题应返回合理回复', () async {
      final response = await aiService.chat(
        userMessage: '这个玉石是真的吗？怎么辨别真假？',
        forceOffline: true,
      );
      
      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
      // 应包含认证相关内容
      expect(response.contains('证书') || response.contains('天然') || response.contains('A货'), true);
    });

    test('推荐问题应返回商品推荐', () async {
      final response = await aiService.chat(
        userMessage: '推荐一款适合送人的手链',
        forceOffline: true,
      );
      
      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
      // 应包含推荐内容
      expect(response.contains('和田玉') || response.contains('翡翠') || response.contains('南红'), true);
    });

    test('退换货问题应返回售后政策', () async {
      final response = await aiService.chat(
        userMessage: '可以退货吗？',
        forceOffline: true,
      );
      
      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
      // 应包含退换货相关内容
      expect(response.contains('退') || response.contains('换') || response.contains('7天'), true);
    });

    test('一般问候应返回自我介绍', () async {
      final response = await aiService.chat(
        userMessage: '你好',
        forceOffline: true,
      );
      
      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
      // 应包含助手自我介绍
      expect(response.contains('汇玉源') || response.contains('玉小助') || response.contains('帮您'), true);
    });
  });

  group('商务话术生成测试（离线）', () {
    test('应生成商务邀约话术', () async {
      final dialogue = await aiService.generateBusinessDialogue(
        shopName: '玉石世家',
        category: '珠宝首饰',
        rating: 4.8,
        platform: '淘宝',
        followers: 50000,
      );
      
      expect(dialogue, isNotNull);
      expect(dialogue.isNotEmpty, true);
      // 离线模式应包含店铺名
      expect(dialogue.contains('玉石世家') || dialogue.contains('汇玉源'), true);
    });

    test('低评分店铺也应生成话术', () async {
      final dialogue = await aiService.generateBusinessDialogue(
        shopName: '新手小店',
        category: '饰品',
        rating: 3.5,
      );
      
      expect(dialogue, isNotNull);
      expect(dialogue.isNotEmpty, true);
    });
  });

  group('产品描述生成测试（离线）', () {
    test('应生成和田玉产品描述', () async {
      final description = await aiService.generateProductDescription(
        productName: '羊脂白玉手镯',
        material: '和田玉',
        price: 29999,
        features: '精雕细琢，油润细腻',
        origin: '新疆和田',
      );
      
      expect(description, isNotNull);
      expect(description.isNotEmpty, true);
      // 应包含产品名或材质相关内容
      expect(description.contains('手镯') || description.contains('和田玉'), true);
    });

    test('应生成翡翠产品描述', () async {
      final description = await aiService.generateProductDescription(
        productName: '冰种翡翠吊坠',
        material: '缅甸翡翠',
        price: 88888,
        origin: '缅甸',
      );
      
      expect(description, isNotNull);
      expect(description.isNotEmpty, true);
    });
  });

  group('聊天内容分析测试', () {
    test('应正确分析积极情感', () async {
      final analysis = await aiService.analyzeChatContent(
        '这个产品太好了！我非常喜欢，准备下单购买！'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['sentiment'], 'positive');
    });

    test('应正确分析消极情感', () async {
      final analysis = await aiService.analyzeChatContent(
        '太差了，质量很垃圾，要投诉。'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['sentiment'], 'negative');
    });

    test('应提取关键词', () async {
      final analysis = await aiService.analyzeChatContent(
        '我想买一款和田玉的手链，价格在多少钱'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['keywords'], isNotNull);
      expect(analysis['keywords'] is List, true);
      expect((analysis['keywords'] as List).contains('手链'), true);
    });

    test('应识别价格咨询意图', () async {
      final analysis = await aiService.analyzeChatContent(
        '这个多少钱？有优惠吗？'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['intent'], 'price_inquiry');
    });

    test('应识别真假鉴定意图', () async {
      final analysis = await aiService.analyzeChatContent(
        '怎么鉴定是不是正品？'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['intent'], 'authenticity_check');
    });

    test('应识别商务咨询意图', () async {
      final analysis = await aiService.analyzeChatContent(
        '想了解一下合作代发的事情'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['intent'], 'business_inquiry');
    });

    test('应评估高紧急程度', () async {
      final analysis = await aiService.analyzeChatContent(
        '急！马上要送礼，今天能发货吗？'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['urgency'], 'high');
    });

    test('应评估正常紧急程度', () async {
      final analysis = await aiService.analyzeChatContent(
        '什么时候发货？'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['urgency'], 'normal');
    });

    test('应生成回复建议', () async {
      final analysis = await aiService.analyzeChatContent(
        '这个戒指有其他颜色吗？'
      );
      
      expect(analysis, isNotNull);
      expect(analysis['suggestion'], isNotNull);
      expect(analysis['suggestion'].toString().isNotEmpty, true);
    });
  });

  group('内容合规检查测试', () {
    test('正常内容应通过检查', () {
      final result = aiService.checkCompliance(
        '这款和田玉手镯采用优质新疆和田玉料，白度高，油润性好。'
      );
      
      expect(result['isCompliant'], true);
      expect(result['violations'] as List, isEmpty);
    });

    test('包含极限词的内容应标记', () {
      final result = aiService.checkCompliance(
        '这是最好的玉石，绝对保值增值！'
      );
      
      expect(result['isCompliant'], false);
      expect((result['violations'] as List).isNotEmpty, true);
    });

    test('多个违禁词应全部检测', () {
      final result = aiService.checkCompliance(
        '全网第一，顶级品质，最佳选择！'
      );
      
      expect(result['isCompliant'], false);
      final violations = result['violations'] as List;
      expect(violations.length >= 2, true);
    });

    test('治疗类词汇应被检测', () {
      final result = aiService.checkCompliance(
        '佩戴可以治愈疾病，有保健功效。'
      );
      
      expect(result['isCompliant'], false);
    });
  });

  group('店铺评估测试', () {
    test('应正确评估高质量店铺', () async {
      final evaluation = await aiService.evaluateShop(
        shopName: '金牌珠宝店',
        rating: 4.9,
        conversionRate: 8.0,
        followers: 100000,
        negativeRate: 0.005,
      );
      
      expect(evaluation, isNotNull);
      expect(evaluation['score'], isNotNull);
      expect(evaluation['decision'], isNotNull);
      // 高质量店铺应有较高评分和积极决策
      expect(evaluation['score'] >= 70, true);
      expect(evaluation['priority'], 'high');
    });

    test('应正确评估中等质量店铺', () async {
      final evaluation = await aiService.evaluateShop(
        shopName: '普通店铺',
        rating: 4.7,
        conversionRate: 3.0,
        followers: 50000,
        negativeRate: 0.015,
      );
      
      expect(evaluation, isNotNull);
      expect(evaluation['score'], isNotNull);
      expect(evaluation['priority'], anyOf('medium', 'high'));
    });

    test('应正确评估低质量店铺', () async {
      final evaluation = await aiService.evaluateShop(
        shopName: '新店测试',
        rating: 4.0,
        conversionRate: 1.0,
        followers: 500,
        negativeRate: 0.15,
      );
      
      expect(evaluation, isNotNull);
      expect(evaluation['score'], isNotNull);
      expect(evaluation['score'] < 60, true);
      expect(evaluation['priority'], 'low');
    });

    test('应包含评估理由', () async {
      final evaluation = await aiService.evaluateShop(
        shopName: '测试店铺',
        rating: 4.8,
        conversionRate: 5.0,
        followers: 20000,
      );
      
      expect(evaluation, isNotNull);
      expect(evaluation['reasons'], isNotNull);
      expect(evaluation['reasons'] is List, true);
      expect((evaluation['reasons'] as List).isNotEmpty, true);
    });

    test('应给出行动建议', () async {
      final evaluation = await aiService.evaluateShop(
        shopName: '优质店铺',
        rating: 4.9,
        conversionRate: 6.0,
        followers: 80000,
      );
      
      expect(evaluation, isNotNull);
      expect(evaluation['suggestedAction'], isNotNull);
      expect(evaluation['suggestedAction'].toString().isNotEmpty, true);
    });
  });

  group('对话历史测试', () {
    test('应支持带历史的对话', () async {
      final history = [
        {'role': 'user', 'content': '你好'},
        {'role': 'assistant', 'content': '您好！有什么可以帮您的？'},
        {'role': 'user', 'content': '我想买和田玉'},
        {'role': 'assistant', 'content': '好的，请问您是要手镯、吊坠还是其他款式？'},
      ];

      final response = await aiService.chat(
        userMessage: '手镯吧，有什么推荐？',
        history: history,
      );
      
      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
      expect(aiService.lastProductContextFailure, isNull);
    });

    test('空历史对话应正常工作', () async {
      final response = await aiService.chat(
        userMessage: '你好',
        history: [],
      );
      
      expect(response, isNotNull);
    });
  });
}
