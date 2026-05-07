library;

import '../l10n/translator_global.dart';
import '../utils/text_sanitizer.dart';
import '../providers/app_settings_provider.dart';
import 'ai_insight_service.dart';
import 'ai_dashscope_service.dart';
import 'ai_product_context_service.dart';
import 'ai_prompt_service.dart';

class AIService {
  static final AIService _instance = AIService._internal();

  factory AIService() => _instance;

  AIService._internal();

  final AIInsightService _insightService = const AIInsightService();
  final AIDashScopeService _dashScopeService = AIDashScopeService();
  final AIProductContextService _productContextService =
      AIProductContextService();
  final AIPromptService _promptService = const AIPromptService();

  bool get isOnlineConfigured => _dashScopeService.isConfigured;

  String? get lastFailureReason =>
      _dashScopeService.lastError ?? _productContextService.lastError;

  String? get lastProductContextFailure => _productContextService.lastError;

  Future<String> chat({
    required String userMessage,
    List<Map<String, String>>? history,
    String? systemPrompt,
    bool includeProducts = true,
    String language = 'zh_CN',
    bool forceOffline = false,
  }) async {
    final safeUserMessage = sanitizeUtf16(userMessage);

    if (forceOffline) {
      return sanitizeUtf16(
        _promptService.getOfflineResponse(safeUserMessage, language: language),
      );
    }

    final messages = _buildChatMessages(
      userMessage: safeUserMessage,
      history: history,
      systemPrompt: await _buildFinalSystemPrompt(
        systemPrompt: systemPrompt,
        includeProducts: includeProducts,
        language: language,
      ),
    );

    final response = await _dashScopeService.createChatCompletion(
      messages: messages,
    );
    if (response != null && response.isNotEmpty) {
      return _filterSensitiveWords(response);
    }

    return sanitizeUtf16(
      _promptService.getOfflineResponse(safeUserMessage, language: language),
    );
  }

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
    final safeUserMessage = sanitizeUtf16(userMessage);
    final messages = _buildChatMessages(
      userMessage: safeUserMessage,
      history: history,
      systemPrompt: await _buildFinalSystemPrompt(
        systemPrompt: systemPrompt,
        includeProducts: includeProducts,
        language: language,
      ),
    );

    final streamedResponse = await _dashScopeService.createChatCompletionStream(
      messages: messages,
      onToken: (token) => onToken(sanitizeUtf16(token)),
    );
    if (streamedResponse != null && streamedResponse.isNotEmpty) {
      final result = _filterSensitiveWords(streamedResponse);
      onDone(result);
      return;
    }

    final failureReason = _dashScopeService.lastError;
    if (failureReason != null && failureReason.isNotEmpty) {
      onError?.call(failureReason);
    }

    final offlineResponse = sanitizeUtf16(
      _promptService.getOfflineResponse(safeUserMessage, language: language),
    );
    final fallback = sanitizeUtf16(
      _t('ai_offline_message', params: {'content': offlineResponse}),
    );
    for (int index = 0; index < fallback.length; index++) {
      onToken(fallback[index]);
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
        'content': sanitizeUtf16(systemPrompt),
      },
    ];

    if (history != null && history.isNotEmpty) {
      messages.addAll(
        history.map(
          (entry) => {
            'role': sanitizeUtf16(entry['role'] ?? ''),
            'content': sanitizeUtf16(entry['content'] ?? ''),
          },
        ),
      );
    }

    messages.add({
      'role': 'user',
      'content': sanitizeUtf16(userMessage),
    });

    return messages;
  }

  Future<String> _buildFinalSystemPrompt({
    required String? systemPrompt,
    required bool includeProducts,
    required String language,
  }) async {
    var finalSystemPrompt = systemPrompt ??
        _promptService.getDefaultSystemPrompt(language: language);
    if (!includeProducts || systemPrompt != null) {
      return sanitizeUtf16(finalSystemPrompt);
    }

    final productContext = await _productContextService.buildProductContext(
      language: _languageFromCode(language),
    );
    if (productContext.isNotEmpty) {
      finalSystemPrompt += '\n\n$productContext';
    }
    return sanitizeUtf16(finalSystemPrompt);
  }

  static List<Map<String, String>> getQuickQuestions() {
    return const AIPromptService().getQuickQuestions();
  }

  static AppLanguage _languageFromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('-', '_');
    if (normalized.startsWith('en')) return AppLanguage.en;
    if (normalized == 'zh_tw' ||
        normalized == 'zhtw' ||
        normalized == 'tw' ||
        normalized == 'zh_hk' ||
        normalized == 'zhhk' ||
        normalized == 'hk') {
      return AppLanguage.zhTW;
    }
    return AppLanguage.zhCN;
  }

  Future<String> generateBusinessDialogue({
    required String shopName,
    required String category,
    required double rating,
    String? platform,
    int? followers,
    List<Map<String, String>>? history,
  }) async {
    final prompt = _promptService.buildBusinessDialoguePrompt(
      shopName: shopName,
      category: category,
      rating: rating,
      platform: platform,
      followers: followers,
    );

    try {
      final response = await chat(
        userMessage: prompt,
        systemPrompt: _promptService.businessDialogueSystemPrompt,
        includeProducts: false,
      );
      return sanitizeUtf16(response);
    } catch (_) {
      return _promptService.buildOfflineDialogue(
        shopName: shopName,
        category: category,
        rating: rating,
      );
    }
  }

  Future<String> generateProductDescription({
    required String productName,
    required String material,
    required double price,
    String? features,
    String? origin,
  }) async {
    final prompt = _promptService.buildProductDescriptionPrompt(
      productName: productName,
      material: material,
      price: price,
      features: features,
      origin: origin,
    );

    if (!isOnlineConfigured) {
      return _promptService.buildOfflineDescription(
        productName: productName,
        material: material,
        price: price,
      );
    }

    try {
      return await chat(
        userMessage: prompt,
        systemPrompt: _promptService.productDescriptionSystemPrompt,
        includeProducts: false,
      );
    } catch (_) {
      return _promptService.buildOfflineDescription(
        productName: productName,
        material: material,
        price: price,
      );
    }
  }

  Future<Map<String, dynamic>> analyzeChatContent(String content) {
    return _insightService.analyzeChatContent(sanitizeUtf16(content));
  }

  String _filterSensitiveWords(String content) {
    return sanitizeUtf16(_insightService.filterSensitiveWords(content));
  }

  Map<String, dynamic> checkCompliance(String content) {
    return _insightService.checkCompliance(sanitizeUtf16(content));
  }

  Future<Map<String, dynamic>> evaluateShop({
    required String shopName,
    required double rating,
    required double conversionRate,
    required int followers,
    double? negativeRate,
  }) async {
    return _insightService.evaluateShop(
      shopName: shopName,
      rating: rating,
      conversionRate: conversionRate,
      followers: followers,
      negativeRate: negativeRate,
    );
  }

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return TranslatorGlobal.instance.translate(key, params: params);
  }
}
