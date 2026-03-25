library;

import '../models/product_model.dart';
import 'product_data_extended.dart';
import 'product_runtime_catalog.dart';
import 'product_seed_generated.dart';

final List<ProductModel> seedProductData = List<ProductModel>.unmodifiable([
  ...generatedBaseProductData,
  ...extendedProductData,
]);

final ProductRuntimeCatalog productRuntimeCatalog = ProductRuntimeCatalog(
  seedProducts: seedProductData,
);
