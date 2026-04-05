import 'dart:convert';
import 'dart:io';

import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';

Future<void> main() async {
  final ids = ['HYY-HT005', 'HYY-SP006', 'HYY-SP013', 'HYY-HJ009', 'HYY-HT010'];
  final client = HttpClient();
  for (final id in ids) {
    final request = await client.getUrl(Uri.parse('http://127.0.0.1:8000/api/products/$id'));
    final response = await request.close();
    final body = await utf8.decodeStream(response);
    final product = ProductModel.fromJson(jsonDecode(body) as Map<String, dynamic>);
    TranslatorGlobal.updateLanguage(AppLanguage.en);
    print('ID=$id');
    print('TITLE=${product.titleL10n}');
    print('ORIGIN=${product.originL10n}');
    print('DESC=${product.descL10n}');
    print('---');
  }
  client.close(force: true);
}
