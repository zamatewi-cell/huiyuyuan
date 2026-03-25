library;

import '../models/product_model.dart';
import 'product_seed_generated.dart';

enum ProductSeedSource {
  base,
  extended,
}

class ProductSeedImportRecord {
  const ProductSeedImportRecord({
    required this.seedId,
    required this.seedSource,
    required this.sortOrder,
    required this.sourceOrder,
    required this.product,
  });

  final String seedId;
  final ProductSeedSource seedSource;
  final int sortOrder;
  final int sourceOrder;
  final ProductModel product;

  Map<String, dynamic> toJson() {
    return {
      'seed_id': seedId,
      'seed_source': seedSource.name,
      'sort_order': sortOrder,
      'source_order': sourceOrder,
      ...product.toJson(),
    };
  }
}

class ProductSeedCatalog {
  const ProductSeedCatalog({
    required this.baseProducts,
    required this.extendedProducts,
  });

  final List<ProductModel> baseProducts;
  final List<ProductModel> extendedProducts;

  List<ProductModel> get allProducts => [
        ...baseProducts,
        ...extendedProducts,
      ];

  List<ProductSeedImportRecord> buildImportRecords() {
    final records = <ProductSeedImportRecord>[];

    records.addAll(
      _buildRecords(
        products: baseProducts,
        seedSource: ProductSeedSource.base,
        sortOffset: 0,
      ),
    );
    records.addAll(
      _buildRecords(
        products: extendedProducts,
        seedSource: ProductSeedSource.extended,
        sortOffset: baseProducts.length,
      ),
    );

    return records;
  }

  List<Map<String, dynamic>> exportImportPayloads() {
    return buildImportRecords()
        .map((record) => record.toJson())
        .toList(growable: false);
  }

  static List<ProductSeedImportRecord> _buildRecords({
    required List<ProductModel> products,
    required ProductSeedSource seedSource,
    required int sortOffset,
  }) {
    return [
      for (var index = 0; index < products.length; index++)
        ProductSeedImportRecord(
          seedId: products[index].id,
          seedSource: seedSource,
          sortOrder: sortOffset + index + 1,
          sourceOrder: index + 1,
          product: products[index],
        ),
    ];
  }
}

final List<ProductModel> baseProductSeedData =
    List<ProductModel>.unmodifiable(generatedBaseProductData);

final List<ProductModel> extendedProductSeedData =
    List<ProductModel>.unmodifiable(generatedExtendedProductData);

final productSeedCatalog = ProductSeedCatalog(
  baseProducts: baseProductSeedData,
  extendedProducts: extendedProductSeedData,
);

List<ProductSeedImportRecord> get productSeedImportRecords =>
    productSeedCatalog.buildImportRecords();

List<Map<String, dynamic>> exportProductSeedPayloads() {
  return productSeedCatalog.exportImportPayloads();
}
