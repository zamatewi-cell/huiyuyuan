import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/data/product_data.dart';
import 'package:huiyuyuan/data/product_seed_catalog.dart';

void main() {
  group('Product seed catalog', () {
    test('merges base and extended seed products', () {
      expect(
        productSeedCatalog.allProducts.length,
        baseProductSeedData.length + extendedProductSeedData.length,
      );
    });

    test('builds import records with stable ordering metadata', () {
      final records = productSeedImportRecords;
      final firstBaseRecord = records.first;
      final firstExtendedRecord = records[baseProductSeedData.length];

      expect(firstBaseRecord.seedSource, ProductSeedSource.base);
      expect(firstBaseRecord.sortOrder, 1);
      expect(firstBaseRecord.sourceOrder, 1);

      expect(firstExtendedRecord.seedSource, ProductSeedSource.extended);
      expect(firstExtendedRecord.sortOrder, baseProductSeedData.length + 1);
      expect(firstExtendedRecord.sourceOrder, 1);
    });

    test('exports flat payloads for migration scripts', () {
      final payload = exportProductSeedPayloads().first;
      final firstProduct = productSeedImportRecords.first.product;

      expect(payload['seed_id'], firstProduct.id);
      expect(payload['seed_source'], ProductSeedSource.base.name);
      expect(payload['sort_order'], 1);
      expect(payload['category'], firstProduct.category);
      expect(payload['material'], firstProduct.material);
      expect(payload['images'], firstProduct.images);
    });

    test('compatibility lookup still finds extended seed products', () {
      final extendedProduct = extendedProductSeedData.first;

      expect(getLocalProductById(extendedProduct.id)?.id, extendedProduct.id);
    });
  });
}
