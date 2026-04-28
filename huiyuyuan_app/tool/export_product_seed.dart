import 'dart:convert';
import 'dart:io';

import 'package:huiyuyuan/data/product_seed_catalog.dart';

Map<String, Object?> exportProductSeedArtifacts({
  String? sourceJsonPath,
  String jsonOutputPath = 'backend/data/product_seed_payloads.json',
  String dartOutputPath = 'lib/data/product_seed_generated.dart',
}) {
  final payloads = _resolvePayloads(sourceJsonPath);
  final jsonOutputFile = File(jsonOutputPath);
  jsonOutputFile.parent.createSync(recursive: true);
  jsonOutputFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(payloads)}\n',
    encoding: utf8,
  );

  final dartOutputFile = File(dartOutputPath);
  dartOutputFile.parent.createSync(recursive: true);
  dartOutputFile.writeAsStringSync(
    _buildGeneratedDartSource(payloads),
    encoding: utf8,
  );

  return {
    'json_output': jsonOutputFile.path,
    'dart_output': dartOutputFile.path,
    'total': payloads.length,
    'first_id': payloads.isEmpty ? null : payloads.first['id'],
    'last_id': payloads.isEmpty ? null : payloads.last['id'],
  };
}

List<Map<String, dynamic>> _resolvePayloads(String? sourceJsonPath) {
  final normalizedPath = sourceJsonPath?.trim() ?? '';
  if (normalizedPath.isEmpty) {
    return exportProductSeedPayloads()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  final sourceFile = File(normalizedPath);
  final decoded = jsonDecode(sourceFile.readAsStringSync()) as List<dynamic>;
  return decoded
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}

String _buildGeneratedDartSource(List<Map<String, dynamic>> payloads) {
  final basePayloads = payloads
      .where((payload) => payload['seed_source'] == 'base')
      .toList(growable: false);
  final extendedPayloads = payloads
      .where((payload) => payload['seed_source'] == 'extended')
      .toList(growable: false);

  const encoder = JsonEncoder.withIndent('  ');
  final baseLiteral = encoder.convert(basePayloads);
  final extendedLiteral = encoder.convert(extendedPayloads);

  return '''
library;

import '../models/product_model.dart';

List<Map<String, dynamic>> _buildPayloads(List<dynamic> items) {
  return List<Map<String, dynamic>>.unmodifiable(
    items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false),
  );
}

List<ProductModel> _buildProducts(List<Map<String, dynamic>> payloads) {
  return List<ProductModel>.unmodifiable(
    payloads
        .map((payload) => ProductModel.fromJson(payload))
        .toList(growable: false),
  );
}

final List<Map<String, dynamic>> generatedBaseProductSeedPayloads =
    _buildPayloads(
  $baseLiteral,
);

final List<Map<String, dynamic>> generatedExtendedProductSeedPayloads =
    _buildPayloads(
  $extendedLiteral,
);

final List<Map<String, dynamic>> generatedAllProductSeedPayloads =
    List<Map<String, dynamic>>.unmodifiable([
  ...generatedBaseProductSeedPayloads,
  ...generatedExtendedProductSeedPayloads,
]);

final List<ProductModel> generatedBaseProductData = _buildProducts(
  generatedBaseProductSeedPayloads,
);

final List<ProductModel> generatedExtendedProductData = _buildProducts(
  generatedExtendedProductSeedPayloads,
);

final List<ProductModel> generatedAllProductData = List<ProductModel>.unmodifiable([
  ...generatedBaseProductData,
  ...generatedExtendedProductData,
]);
''';
}
