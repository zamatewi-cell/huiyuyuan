import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/data/product_seed_catalog.dart';
import 'package:huiyuyuan/data/product_seed_generated.dart';

void main() {
  test('generated dart seed stays in sync with shared json snapshot', () {
    final seedFile = File('backend/data/product_seed_payloads.json');

    expect(
      seedFile.existsSync(),
      isTrue,
      reason:
          'Run flutter test tool/export_product_seed_test.dart to regenerate shared seed artifacts.',
    );

    final checkedInPayloads =
        jsonDecode(seedFile.readAsStringSync()) as List<dynamic>;

    expect(
      jsonEncode(generatedAllProductSeedPayloads),
      jsonEncode(checkedInPayloads),
    );
    expect(
        jsonEncode(exportProductSeedPayloads()), jsonEncode(checkedInPayloads));
  });
}
