// 汇玉源 - AI 对话流程集成测试
//
// 测试场景:
// 1. AI 助手页面加载
// 2. AI 服务功能
// 3. ChatMessage 模型
// 4. 内容分析功能
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:huiyuanyuan/screens/chat/ai_assistant_screen.dart';
import 'package:huiyuanyuan/services/ai_service.dart';
import 'package:huiyuanyuan/models/user_model.dart';

void _mockSecureStorage() {
  const MethodChannel ch = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final Map<String, String> store = {};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(ch, (call) async {
    switch (call.method) {
      case 'write':
        final v = call.arguments['value'] as String?;
        if (v != null) store[call.arguments['key'] as String] = v;
        return null;
      case 'read':
        return store[call.arguments['key'] as String];
      case 'delete':
        store.remove(call.arguments['key'] as String);
        return null;
      case 'deleteAll':
        store.clear();
        return null;
      case 'readAll':
        return Map<String, String>.from(store);
      case 'containsKey':
        return store.containsKey(call.arguments['key'] as String);
      default:
        return null;
    }
  });
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _mockSecureStorage();
  });

  group('AI 助手页面 UI 测试', () {
    testWidgets('AI 助手页面应正确加载', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AIAssistantScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证 AI 助手页面存在
      expect(find.byType(AIAssistantScreen), findsOneWidget);
    });
  });

  group('AI 服务集成测试', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('AI 服务应正常初始化', () {
      expect(aiService, isNotNull);
    });

    test('发送消息应返回回复', () async {
      final response = await aiService.chat(userMessage: '你好');
      
      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
    });

    test('商务话术生成应返回内容', () async {
      final dialogue = await aiService.generateBusinessDialogue(
        shopName: '测试店铺',
        category: '珠宝',
        rating: 4.5,
      );
      
      expect(dialogue, isNotNull);
      expect(dialogue.isNotEmpty, true);
    });

    test('产品描述生成应返回内容', () async {
      final description = await aiService.generateProductDescription(
        productName: '和田玉吊坠',
        material: '和田玉',
        price: 5999,
      );
      
      expect(description, isNotNull);
      expect(description.isNotEmpty, true);
    });
  });

  group('ChatMessage 模型测试', () {
    test('用户消息应正确创建', () {
      final message = ChatMessage(
        id: 'msg_1',
        content: '你好',
        isUser: true,
        timestamp: DateTime.now(),
      );

      expect(message.id, 'msg_1');
      expect(message.content, '你好');
      expect(message.isUser, true);
      expect(message.type, 'text');
    });

    test('AI 消息应正确创建', () {
      final message = ChatMessage(
        id: 'msg_2',
        content: '您好，有什么可以帮您的？',
        isUser: false,
        timestamp: DateTime.now(),
      );

      expect(message.isUser, false);
    });

    test('消息时间戳应正确', () {
      final now = DateTime.now();
      final message = ChatMessage(
        id: 'msg_3',
        content: '测试',
        isUser: true,
        timestamp: now,
      );

      expect(message.timestamp, now);
    });

    test('消息类型默认为 text', () {
      final message = ChatMessage(
        id: 'msg_4',
        content: '测试',
        isUser: true,
        timestamp: DateTime.now(),
      );

      expect(message.type, 'text');
    });
  });

  group('对话历史测试', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('带历史的对话应正常工作', () async {
      final history = [
        {'role': 'user', 'content': '你好'},
        {'role': 'assistant', 'content': '您好！'},
      ];

      final response = await aiService.chat(
        userMessage: '推荐一款玉石',
        history: history,
      );

      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
    });

    test('空历史对话应正常工作', () async {
      final response = await aiService.chat(
        userMessage: '你好',
        history: [],
      );

      expect(response, isNotNull);
    });
  });

  group('内容分析功能测试', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('分析积极内容应返回 positive', () async {
      final analysis = await aiService.analyzeChatContent(
        '这个产品太好了，我很喜欢！'
      );

      expect(analysis, isNotNull);
      expect(analysis['sentiment'], 'positive');
    });

    test('分析消极内容应返回 negative', () async {
      final analysis = await aiService.analyzeChatContent(
        '太差了，质量很垃圾'
      );

      expect(analysis, isNotNull);
      expect(analysis['sentiment'], 'negative');
    });

    test('分析应提取关键词', () async {
      final analysis = await aiService.analyzeChatContent(
        '我想买一款手链'
      );

      expect(analysis['keywords'], isNotNull);
      expect((analysis['keywords'] as List).contains('手链'), true);
    });

    test('分析应识别意图', () async {
      final analysis = await aiService.analyzeChatContent(
        '这个多少钱？'
      );

      expect(analysis['intent'], 'price_inquiry');
    });

    test('分析应评估紧急程度', () async {
      final analysis = await aiService.analyzeChatContent(
        '急！马上要用'
      );

      expect(analysis['urgency'], 'high');
    });
  });

  group('店铺评估功能测试', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('评估高质量店铺', () async {
      final evaluation = await aiService.evaluateShop(
        shopName: '优质店铺',
        rating: 4.9,
        conversionRate: 10.0,
        followers: 100000,
      );

      expect(evaluation['score'], isNotNull);
      expect(evaluation['decision'], isNotNull);
      expect(evaluation['priority'], 'high');
    });

    test('评估低质量店铺', () async {
      final evaluation = await aiService.evaluateShop(
        shopName: '新店铺',
        rating: 4.0,
        conversionRate: 1.0,
        followers: 100,
      );

      expect(evaluation['score'], isNotNull);
      expect(evaluation['priority'], 'low');
    });

    test('评估应包含理由', () async {
      final evaluation = await aiService.evaluateShop(
        shopName: '测试店铺',
        rating: 4.8,
        conversionRate: 5.0,
        followers: 50000,
      );

      expect(evaluation['reasons'], isNotNull);
      expect((evaluation['reasons'] as List).isNotEmpty, true);
    });
  });

  group('合规检查功能测试', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    test('正常内容应通过检查', () {
      final result = aiService.checkCompliance(
        '这款和田玉采用优质原料，做工精细。'
      );

      expect(result['isCompliant'], true);
    });

    test('包含违禁词应不通过', () {
      final result = aiService.checkCompliance(
        '这是最好的产品，绝对第一！'
      );

      expect(result['isCompliant'], false);
    });
  });
}
