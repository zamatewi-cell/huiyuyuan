library;

import 'dart:async';

import '../l10n/product_translator.dart';
import '../models/product_model.dart';
import '../providers/app_settings_provider.dart';
import '../repositories/product_catalog_repository.dart';
import 'product_runtime_store.dart';

final ProductCatalogRepository _compatCatalogRepository =
    ProductCatalogRepository(
  runtimeCatalog: productRuntimeCatalog,
);

List<ProductModel> get readOnlySeedProductData =>
    _compatCatalogRepository.getSeedProducts();

List<ProductModel> get runtimeOnlyProductData =>
    _compatCatalogRepository.getRuntimeOnlyProducts();

bool get hasRuntimeProductOverrides =>
    _compatCatalogRepository.hasRuntimeOverrides;

List<ProductModel> get realProductData =>
    _compatCatalogRepository.listAllProducts();

List<ProductModel> getProductsByCategory(String? category) {
  final normalizedCategory = category?.trim() ?? '';
  final canonicalCategory = ProductTranslator.canonicalCategory(
    normalizedCategory,
  );

  if (normalizedCategory.isEmpty ||
      canonicalCategory.isEmpty ||
      canonicalCategory.toLowerCase() == 'all') {
    return realProductData;
  }
  return realProductData
      .where(
        (product) {
          final localizedCategories = AppLanguage.values
              .map(product.localizedCategoryFor)
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty);
          return ProductTranslator.canonicalCategory(product.category) ==
                  canonicalCategory ||
              localizedCategories.any(
                (value) =>
                    value == normalizedCategory ||
                    ProductTranslator.canonicalCategory(value) ==
                        canonicalCategory,
              );
        },
      )
      .toList();
}

List<ProductModel> getHotProducts() {
  return realProductData.where((product) => product.isHot).toList();
}

List<ProductModel> getWelfareProducts() {
  return realProductData.where((product) => product.isWelfare).toList();
}

List<ProductModel> getNewProducts() {
  return realProductData.where((product) => product.isNew).toList();
}

List<ProductModel> sortByPrice(List<ProductModel> products, bool ascending) {
  final sorted = List<ProductModel>.from(products);
  sorted.sort(
    (left, right) => ascending
        ? left.price.compareTo(right.price)
        : right.price.compareTo(left.price),
  );
  return sorted;
}

List<ProductModel> sortBySales(List<ProductModel> products) {
  final sorted = List<ProductModel>.from(products);
  sorted.sort((left, right) => right.salesCount.compareTo(left.salesCount));
  return sorted;
}

List<ProductModel> searchProducts(String keyword) {
  final lowered = keyword.toLowerCase();
  return realProductData.where((product) {
    return product.name.toLowerCase().contains(lowered) ||
        (product.nameEn?.toLowerCase().contains(lowered) ?? false) ||
        (product.nameZhTw?.toLowerCase().contains(lowered) ?? false) ||
        product.material.toLowerCase().contains(lowered) ||
        (product.materialEn?.toLowerCase().contains(lowered) ?? false) ||
        (product.materialZhTw?.toLowerCase().contains(lowered) ?? false) ||
        product.category.toLowerCase().contains(lowered) ||
        (product.categoryEn?.toLowerCase().contains(lowered) ?? false) ||
        (product.categoryZhTw?.toLowerCase().contains(lowered) ?? false) ||
        product.description.toLowerCase().contains(lowered) ||
        (product.descriptionEn?.toLowerCase().contains(lowered) ?? false) ||
        (product.descriptionZhTw?.toLowerCase().contains(lowered) ?? false);
  }).toList();
}

List<ProductModel> get allProducts => realProductData;

ProductModel? getLocalProductById(String productId) {
  return _compatCatalogRepository.getProductDetail(productId);
}

void addProduct(ProductModel product) {
  _compatCatalogRepository.saveRuntimeProduct(product);
  unawaited(_compatCatalogRepository.persistRuntimeOverrides());
}

bool removeProduct(String productId) {
  final removed = _compatCatalogRepository.deleteRuntimeProduct(productId);
  if (removed) {
    unawaited(_compatCatalogRepository.persistRuntimeOverrides());
  }
  return removed;
}

void resetRuntimeProductData() {
  _compatCatalogRepository.resetRuntimeOverrides();
  unawaited(_compatCatalogRepository.persistRuntimeOverrides());
}

List<String> getAllMaterials() {
  return realProductData.map((product) => product.material).toSet().toList();
}

List<String> getAllCategories() {
  return realProductData.map((product) => product.category).toSet().toList();
}

String getDefaultImageForMaterial(String material) {
  const imageMap = {
    '和田玉': 'photo-1611591437281-460bfbe1220a',
    '缅甸翡翠': 'photo-1588444837495-c6cfeb53f32d',
    '南红玛瑙': 'photo-1602751584552-8ba73aad10e1',
    '紫水晶': 'photo-1629224316810-9d8805b95e76',
    '黄金': 'photo-1619119069152-a2b331eb392a',
    '红宝石': 'photo-1573408301185-9146fe634ad0',
    '蓝宝石': 'photo-1515562141207-7a88fb7ce338',
    '碧玉': 'photo-1610375461246-83df859d849d',
    '蜜蜡': 'photo-1608042314453-ae338d80c427',
    '钻石': 'photo-1605100804763-247f67b3557e',
    '珍珠': 'photo-1739700285847-2f173370e8a7',
    '纯银': 'photo-1605100804763-247f67b3557e',
    '绿松石': 'photo-1515562141207-7a88fb7ce338',
    '玛瑙': 'photo-1602751584552-8ba73aad10e1',
    '天珠': 'photo-1602751584552-8ba73aad10e1',
    '琥珀': 'photo-1608042314453-ae338d80c427',
    '红珊瑚': 'photo-1573408301185-9146fe634ad0',
    '珊瑚': 'photo-1573408301185-9146fe634ad0',
    '祖母绿': 'photo-1610375461246-83df859d849d',
    '坦桑石': 'photo-1515562141207-7a88fb7ce338',
    '粉水晶': 'photo-1629224316810-9d8805b95e76',
    '黄水晶': 'photo-1608042314453-ae338d80c427',
    '碧玺': 'photo-1629224316810-9d8805b95e76',
    '沉香': 'photo-1608042314453-ae338d80c427',
    '小叶紫檀': 'photo-1608042314453-ae338d80c427',
    '黄花梨': 'photo-1608042314453-ae338d80c427',
    '砗磲': 'photo-1739700285847-2f173370e8a7',
    '天河石': 'photo-1515562141207-7a88fb7ce338',
    '青金石': 'photo-1515562141207-7a88fb7ce338',
    '月光石': 'photo-1605100804763-247f67b3557e',
    '石榴石': 'photo-1573408301185-9146fe634ad0',
    '拉长石': 'photo-1515562141207-7a88fb7ce338',
    '草莓晶': 'photo-1629224316810-9d8805b95e76',
    '发晶': 'photo-1605100804763-247f67b3557e',
    '孔雀石': 'photo-1610375461246-83df859d849d',
    '天然石': 'photo-1602751584552-8ba73aad10e1',
    '苗银': 'photo-1605100804763-247f67b3557e',
  };
  final photoId = imageMap[material] ?? 'photo-1611591437281-460bfbe1220a';
  return 'https://images.unsplash.com/$photoId?w=800&h=800&fit=crop';
}
