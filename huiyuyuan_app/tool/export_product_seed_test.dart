import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'export_product_seed.dart';

void main() {
  test('exports product seed artifacts', () {
    const jsonOutputPath = String.fromEnvironment(
      'PRODUCT_SEED_JSON_OUTPUT',
      defaultValue: 'backend/data/product_seed_payloads.json',
    );
    const dartOutputPath = String.fromEnvironment(
      'PRODUCT_SEED_DART_OUTPUT',
      defaultValue: 'lib/data/product_seed_generated.dart',
    );

    final summary = exportProductSeedArtifacts(
      jsonOutputPath: jsonOutputPath,
      dartOutputPath: dartOutputPath,
    );

    expect(summary['total'], greaterThan(0));
    debugPrint(jsonEncode(summary));
  });
}
