library;

import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import 'product_service.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

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

  Future<String> buildProductContext({int pageSize = 50}) async {
    _lastError = null;
    try {
      final products = await _productLoader(pageSize: pageSize);
      if (products.isEmpty) {
        return '';
      }

      final buffer = StringBuffer();
      buffer.writeln('ai_product_context_title'.tr);
      buffer.writeln(
        'ai_product_context_summary'.trArgs({'count': products.length}),
      );

      final groupedProducts = <String, List<String>>{};
      for (final product in products) {
        groupedProducts.putIfAbsent(product.matL10n, () => []);
        final origin = (product.origin ?? '').trim();
        groupedProducts[product.matL10n]!.add(
          'ai_product_context_item'.trArgs({
            'title': product.titleL10n,
            'id': product.id,
            'price': product.price.toInt(),
            'category': product.catL10n,
            'origin': origin.isEmpty ? '-' : origin,
          }),
        );
      }

      for (final entry in groupedProducts.entries) {
        buffer.writeln(
          '\n${'ai_product_context_series'.trArgs({'material': entry.key})}',
        );
        for (final item in entry.value) {
          buffer.writeln('- $item');
        }
      }

      buffer.writeln('\n${'ai_product_context_closing'.tr}');
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
}
