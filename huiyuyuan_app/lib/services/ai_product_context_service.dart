library;

import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../models/product_model.dart';
import '../providers/app_settings_provider.dart';
import 'product_service.dart';

typedef ProductListLoader = Future<List<ProductModel>> Function({
  int pageSize,
});

class AIProductContextService {
  AIProductContextService({ProductListLoader? productLoader})
      : _productLoader = productLoader ?? _defaultProductLoader;

  final ProductListLoader _productLoader;
  String? _lastError;
  static final ProductService _defaultProductService = ProductService();
  static Future<void>? _defaultInitialization;

  String? get lastError => _lastError;

  static Future<List<ProductModel>> _defaultProductLoader({
    int pageSize = 50,
  }) async {
    _defaultInitialization ??= _defaultProductService.initialize();
    await _defaultInitialization;
    return _defaultProductService.getProducts(pageSize: pageSize);
  }

  Future<String> buildProductContext({
    int pageSize = 50,
    AppLanguage language = AppLanguage.zhCN,
  }) async {
    _lastError = null;
    try {
      final products = await _productLoader(pageSize: pageSize);
      if (products.isEmpty) {
        return '';
      }

      final buffer = StringBuffer();
      buffer.writeln(_t(language, 'ai_product_context_title'));
      buffer.writeln(
        _t(
          language,
          'ai_product_context_summary',
          params: {'count': products.length},
        ),
      );

      final groupedProducts = <String, List<String>>{};
      for (final product in products) {
        final material = product.localizedMaterialFor(language);
        groupedProducts.putIfAbsent(material, () => []);
        final origin = product.localizedOriginFor(language).trim();
        final appraisal =
            product.localizedAppraisalNoteFor(language)?.trim() ?? '';
        final craftItems = product.localizedCraftHighlightsFor(language);
        final craft = craftItems.join(' / ');
        final audience = product.localizedAudienceTagsFor(language);
        final originStory =
            product.localizedOriginStoryFor(language)?.trim() ?? '';
        final flawNotes = product.localizedFlawNotesFor(language);

        // Base catalogue line
        final line = StringBuffer(
          _t(
            language,
            'ai_product_context_item',
            params: {
              'title': product.localizedTitleFor(language),
              'id': product.id,
              'price': product.price.toInt(),
              'category': product.localizedCategoryFor(language),
              'origin': origin.isEmpty ? '-' : origin,
            },
          ),
        );

        // Append concise appraisal or craft snippet when available
        // (keeps the prompt small — only first 60 chars per field)
        if (appraisal.isNotEmpty) {
          final snippet = appraisal.length > 60
              ? '${appraisal.substring(0, 60)}…'
              : appraisal;
          line.write(
            ' | ${_t(language, 'ai_product_context_appraisal_label')}：$snippet',
          );
        } else if (craft.isNotEmpty) {
          final snippet =
              craft.length > 60 ? '${craft.substring(0, 60)}…' : craft;
          line.write(
            ' | ${_t(language, 'ai_product_context_craft_label')}：$snippet',
          );
        }
        if (audience.isNotEmpty) {
          line.write(
            ' | ${_t(language, 'ai_product_context_audience_label')}：${audience.take(3).join('/')}',
          );
        }
        if (originStory.isNotEmpty) {
          final snippet = originStory.length > 48
              ? '${originStory.substring(0, 48)}…'
              : originStory;
          line.write(
            ' | ${_t(language, 'ai_product_context_origin_label')}：$snippet',
          );
        }
        if (flawNotes.isNotEmpty) {
          line.write(
            ' | ${_t(language, 'ai_product_context_flaw_label')}：${flawNotes.take(2).join('/')}',
          );
        }

        groupedProducts[material]!.add(line.toString());
      }

      for (final entry in groupedProducts.entries) {
        buffer.writeln(
          '\n${_t(
            language,
            'ai_product_context_series',
            params: {'material': entry.key},
          )}',
        );
        for (final item in entry.value) {
          buffer.writeln('- $item');
        }
      }

      buffer.writeln('\n${_t(language, 'ai_product_context_closing')}');
      return buffer.toString();
    } catch (error) {
      _lastError = 'Failed to build product context: $error';
      debugPrint('[$runtimeType] $_lastError');
      return '';
    }
  }

  List<String> extractProductIds(String content) {
    final matches = RegExp(r'\[PRODUCT:([^\]]+)\]').allMatches(content);
    return matches.map((match) => match.group(1)!.trim()).toList();
  }

  String stripProductTags(String content) {
    return content.replaceAll(RegExp(r'\[PRODUCT:[^\]]+\]\s*'), '').trim();
  }

  String _t(
    AppLanguage language,
    String key, {
    Map<String, Object?> params = const {},
  }) {
    return AppStrings.get(language, key, params: params);
  }
}
