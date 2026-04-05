import 'dart:convert';
import 'dart:io';

import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';

Future<void> main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('http://127.0.0.1:8000/api/products?page=1&page_size=500'));
  final response = await request.close();
  final body = await utf8.decodeStream(response);
  final decoded = jsonDecode(body) as List<dynamic>;
  final products = decoded.map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  TranslatorGlobal.updateLanguage(AppLanguage.en);
  final issues = <Map<String, String>>[];
  final cn = RegExp(r'[\u4e00-\u9fff]');
  for (final p in products) {
    final title = p.titleL10n;
    final desc = p.descL10n;
    final origin = p.originL10n;
    final material = p.matL10n;
    final titleLower = title.toLowerCase();
    final hasMixed = cn.hasMatch(title) || cn.hasMatch(desc) || cn.hasMatch(origin) || cn.hasMatch(material);
    final awkward = titleLower.contains('beads bracelet') ||
        titleLower.contains('buddha beads 108 beads') ||
        titleLower.contains(' brand ') ||
        titleLower.contains(' dhard') ||
        RegExp(r'(^|\s)[a-z]').hasMatch(title) && !RegExp(r'^[A-Z0-9]').hasMatch(title) ||
        RegExp(r'\b([a-z]{3,})\b.*\b\1\b').hasMatch(titleLower);
    if (hasMixed || awkward) {
      issues.add({
        'id': p.id,
        'title': title,
        'material': material,
        'origin': origin,
        'desc': desc.length > 180 ? desc.substring(0, 180) : desc,
      });
    }
  }
  print(const JsonEncoder.withIndent('  ').convert({'count': issues.length, 'issues': issues.take(120).toList()}));
}
