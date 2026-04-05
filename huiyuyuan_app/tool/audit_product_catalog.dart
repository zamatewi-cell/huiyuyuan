import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:huiyuyuan/l10n/product_translator.dart';
import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';

Future<void> main() async {
  final baseUrl =
      Platform.environment['PRODUCT_AUDIT_BASE_URL'] ?? 'http://127.0.0.1:8000';
  final products = await _fetchProducts(baseUrl);

  final englishIssues = _collectLanguageIssues(products, AppLanguage.en);
  final traditionalIssues = _collectLanguageIssues(products, AppLanguage.zhTW);
  final brokenImages = await _collectBrokenImages(products);

  final report = <String, Object?>{
    'base_url': baseUrl,
    'total_products': products.length,
    'english_issue_count': englishIssues.length,
    'traditional_issue_count': traditionalIssues.length,
    'broken_image_count': brokenImages.length,
    'english_issues': englishIssues,
    'traditional_issues': traditionalIssues,
    'broken_images': brokenImages,
  };

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}

Future<List<ProductModel>> _fetchProducts(String baseUrl) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('$baseUrl/api/products?page=1&page_size=500'),
    );
    final response = await request.close();
    final body = await utf8.decodeStream(response);
    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to fetch products: ${response.statusCode}',
        uri: Uri.parse('$baseUrl/api/products?page=1&page_size=500'),
      );
    }

    final decoded = jsonDecode(body) as List<dynamic>;
    return decoded
        .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  } finally {
    client.close(force: true);
  }
}

List<Map<String, Object?>> _collectLanguageIssues(
  List<ProductModel> products,
  AppLanguage language,
) {
  TranslatorGlobal.updateLanguage(language);

  final issues = <Map<String, Object?>>[];
  for (final product in products) {
    final localizedTitle = product.titleL10n;
    final localizedDesc = product.descL10n;
    final localizedMaterial = product.matL10n;
    final localizedCategory = product.catL10n;
    final localizedOrigin = product.originL10n;

    final hasEnglishResidueInTraditional =
        language == AppLanguage.zhTW && RegExp(r'[A-Za-z]{3,}').hasMatch(localizedTitle);
    final hasChineseResidueInEnglish =
        language == AppLanguage.en && ProductTranslator.containsChinese(localizedTitle);
    final hasChineseDescInEnglish =
        language == AppLanguage.en && ProductTranslator.containsChinese(localizedDesc);
    final hasEnglishDescInTraditional =
        language == AppLanguage.zhTW && RegExp(r'[A-Za-z]{4,}').hasMatch(localizedDesc);
    final materialIssue =
        language == AppLanguage.en && ProductTranslator.containsChinese(localizedMaterial);
    final categoryIssue =
        language == AppLanguage.en && ProductTranslator.containsChinese(localizedCategory);
    final originIssue =
        language == AppLanguage.en && ProductTranslator.containsChinese(localizedOrigin);

    if (hasChineseResidueInEnglish ||
        hasChineseDescInEnglish ||
        hasEnglishResidueInTraditional ||
        hasEnglishDescInTraditional ||
        materialIssue ||
        categoryIssue ||
        originIssue) {
      issues.add({
        'id': product.id,
        'source_name': product.name,
        'localized_title': localizedTitle,
        'localized_material': localizedMaterial,
        'localized_category': localizedCategory,
        'localized_origin': localizedOrigin,
        'localized_description_preview':
            localizedDesc.split('\n').join(' ').substring(0, localizedDesc.length > 160 ? 160 : localizedDesc.length),
      });
    }
  }

  return issues;
}

Future<List<Map<String, Object?>>> _collectBrokenImages(
  List<ProductModel> products,
) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 5);

  final broken = <Map<String, Object?>>[];
  try {
    for (final product in products) {
      final imageUrl = product.images.isNotEmpty ? product.images.first : null;
      if (imageUrl == null || imageUrl.trim().isEmpty) {
        broken.add({
          'id': product.id,
          'name': product.name,
          'image_url': null,
          'status': 'missing',
        });
        continue;
      }

      final uri = Uri.tryParse(imageUrl);
      if (uri == null) {
        broken.add({
          'id': product.id,
          'name': product.name,
          'image_url': imageUrl,
          'status': 'invalid-url',
        });
        continue;
      }

      try {
        final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
        final response = await request.close().timeout(const Duration(seconds: 5));
        if (response.statusCode >= 400) {
          broken.add({
            'id': product.id,
            'name': product.name,
            'image_url': imageUrl,
            'status': response.statusCode,
          });
        }
        await response.drain<void>();
      } catch (error) {
        broken.add({
          'id': product.id,
          'name': product.name,
          'image_url': imageUrl,
          'status': error.runtimeType.toString(),
        });
      }
    }
  } finally {
    client.close(force: true);
  }

  return broken;
}
