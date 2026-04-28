import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/config/local_debug_config.dart';
import 'package:huiyuyuan/services/ai_dashscope_service.dart';

void main() {
  late bool originalUseMockApi;

  setUp(() {
    originalUseMockApi = ApiConfig.useMockApi;
    ApiConfig.useMockApi = true;
  });

  tearDown(() {
    ApiConfig.useMockApi = originalUseMockApi;
    LocalDebugConfig.instance.clearForTesting();
  });

  test('reports missing key before calling DashScope', () async {
    LocalDebugConfig.instance.replaceValuesForTesting(const {});
    final service = AIDashScopeService();

    final response = await service.createChatCompletion(
      messages: const [
        {'role': 'user', 'content': 'hello'},
      ],
    );

    expect(response, isNull);
    expect(service.isConfigured, isFalse);
    expect(service.lastError, contains('DASHSCOPE_API_KEY'));
  });

  test('rejects placeholder key from local debug config', () async {
    LocalDebugConfig.instance.replaceValuesForTesting({
      'DASHSCOPE_API_KEY': 'Fill in your Qwen API Key here',
    });
    final service = AIDashScopeService();

    await service.createChatCompletion(
      messages: const [
        {'role': 'user', 'content': 'hello'},
      ],
    );

    expect(service.isConfigured, isFalse);
    expect(service.lastError, contains('placeholder'));
  });

  test('reports invalid local debug config before calling DashScope', () async {
    LocalDebugConfig.instance.replaceValuesForTesting(
      const {},
      loadedFromPath: 'huiyuyuan_app/.env.json',
      loadError: 'invalid json',
    );
    final service = AIDashScopeService();

    await service.createChatCompletion(
      messages: const [
        {'role': 'user', 'content': 'hello'},
      ],
    );

    expect(service.isConfigured, isFalse);
    expect(service.lastError, contains('.env.json parse failed'));
    expect(service.lastError, contains('huiyuyuan_app/.env.json'));
  });

  test('does not send OpenRouter-only headers', () {
    final service = AIDashScopeService();

    expect(service.debugHeaders['HTTP-Referer'], isNull);
    expect(service.debugHeaders['X-Title'], isNull);
    expect(service.debugHeaders['Authorization'], startsWith('Bearer '));
  });
}
