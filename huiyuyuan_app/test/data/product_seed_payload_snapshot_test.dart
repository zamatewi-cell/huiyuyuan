import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/data/product_seed_catalog.dart';

void main() {
  test('checked-in seed payload snapshot stays in sync with exporter', () {
    final seedFile = File('backend/data/product_seed_payloads.json');

    expect(
      seedFile.existsSync(),
      isTrue,
      reason: 'Run flutter test tool/export_product_seed_test.dart to regenerate the shared seed JSON.',
    );

    final checkedInPayloads = jsonDecode(seedFile.readAsStringSync()) as List<dynamic>;
    final exportedPayloads = exportProductSeedPayloads();

    expect(jsonEncode(checkedInPayloads), jsonEncode(exportedPayloads));
  });
}
