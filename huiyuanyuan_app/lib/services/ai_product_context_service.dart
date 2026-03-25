library;

import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
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

  Future<String> buildProductContext({int pageSize = 50}) async {
    _lastError = null;
    try {
      final products = await _productLoader(pageSize: pageSize);
      if (products.isEmpty) {
        return '';
      }

      final buffer = StringBuffer();
      buffer.writeln('【平台在售商品概览】');
      buffer.writeln('目前汇玉源商城共有 ${products.length} 件在售商品，摘要如下：');

      final groupedProducts = <String, List<String>>{};
      for (final product in products) {
        groupedProducts.putIfAbsent(product.material, () => []);
        groupedProducts[product.material]!.add(
          '${product.name}(编号:${product.id}, ¥${product.price.toInt()}, ${product.category}, ${product.origin ?? ""})',
        );
      }

      for (final entry in groupedProducts.entries) {
        buffer.writeln('\n${entry.key}系列:');
        for (final item in entry.value) {
          buffer.writeln('- $item');
        }
      }

      buffer.writeln('\n当用户询问或需要推荐商品时，请从以上商品中选择合适的商品，并使用 [PRODUCT:商品编号] 标签引用。');
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
