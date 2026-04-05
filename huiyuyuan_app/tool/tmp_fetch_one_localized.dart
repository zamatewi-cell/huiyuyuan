import 'dart:convert';
import 'dart:io';

import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';

Future<void> main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('http://127.0.0.1:8000/api/products/HYY-HT005'));
  final response = await request.close();
  final body = await utf8.decodeStream(response);
  final raw = jsonDecode(body) as Map<String, dynamic>;
  final product = ProductModel.fromJson(raw);
  TranslatorGlobal.updateLanguage(AppLanguage.en);
  print('title=' + product.titleL10n);
  print('origin=' + product.originL10n);
  print('desc=' + product.descL10n);
}
