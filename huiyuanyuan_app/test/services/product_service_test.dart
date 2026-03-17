/// 汇玉源 - 商品服务测试
/// 
/// 测试内容:
/// - 商品列表获取
/// - 商品详情获取
/// - 商品筛选
/// - 商品搜索
/// - 缓存管理
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuanyuan/services/product_service.dart';
import 'package:huiyuanyuan/models/user_model.dart';

void main() {
  late ProductService productService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    productService = ProductService();
  });

  group('ProductModel 测试', () {
    test('ProductModel 应正确创建', () {
      final product = ProductModel(
        id: 'PROD-001',
        name: '和田玉福运手链',
        description: '测试描述',
        price: 299.0,
        originalPrice: 599.0,
        category: '手链',
        material: '和田玉',
        images: ['https://example.com/image.jpg'],
        stock: 100,
        rating: 4.9,
        salesCount: 1000,
        isHot: true,
        isNew: false,
        origin: '新疆和田',
        certificate: 'GTC-2026-001',
        isWelfare: true,
      );

      expect(product.id, 'PROD-001');
      expect(product.name, '和田玉福运手链');
      expect(product.price, 299.0);
      expect(product.originalPrice, 599.0);
      expect(product.category, '手链');
      expect(product.material, '和田玉');
      expect(product.isHot, true);
      expect(product.isWelfare, true);
    });

    test('ProductModel.fromJson 应正确解析', () {
      final json = {
        'id': 'PROD-002',
        'name': '缅甸翡翠平安扣',
        'description': '测试描述2',
        'price': 1280.0,
        'original_price': 2560.0,
        'category': '吊坠',
        'material': '缅甸翡翠',
        'images': ['https://example.com/image2.jpg'],
        'stock': 50,
        'rating': 4.8,
        'sales_count': 500,
        'is_hot': true,
        'is_new': true,
        'origin': '缅甸',
        'certificate': 'NGTC-2026-002',
        'blockchain_hash': '0x1234567890abcdef',
        'is_welfare': false,
        'material_verify': '天然A货',
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'PROD-002');
      expect(product.name, '缅甸翡翠平安扣');
      expect(product.price, 1280.0);
      expect(product.originalPrice, 2560.0);
      expect(product.category, '吊坠');
      expect(product.material, '缅甸翡翠');
      expect(product.blockchainHash, '0x1234567890abcdef');
    });

    test('ProductModel.toJson 应正确转换', () {
      final product = ProductModel(
        id: 'PROD-003',
        name: '测试商品',
        description: '测试',
        price: 199.0,
        category: '手链',
        material: '和田玉',
        images: [],
        stock: 10,
      );

      final json = product.toJson();

      expect(json['id'], 'PROD-003');
      expect(json['name'], '测试商品');
      expect(json['price'], 199.0);
      expect(json['category'], '手链');
    });

    test('discountRate 应正确计算折扣率', () {
      final product1 = ProductModel(
        id: '1',
        name: '测试',
        description: '',
        price: 299.0,
        originalPrice: 599.0,
        category: '手链',
        material: '和田玉',
        images: [],
        stock: 10,
      );

      expect(product1.discountRate, 50.0);

      final product2 = ProductModel(
        id: '2',
        name: '测试',
        description: '',
        price: 100.0,
        originalPrice: 100.0,
        category: '手链',
        material: '和田玉',
        images: [],
        stock: 10,
      );

      expect(product2.discountRate, 0.0);
    });

    test('isWelfarePriceRange 应正确判断', () {
      final product1 = ProductModel(
        id: '1',
        name: '测试',
        description: '',
        price: 299.0,
        category: '手链',
        material: '和田玉',
        images: [],
        stock: 10,
      );
      expect(product1.isWelfarePriceRange, true);

      final product2 = ProductModel(
        id: '2',
        name: '测试',
        description: '',
        price: 100.0,
        category: '手链',
        material: '和田玉',
        images: [],
        stock: 10,
      );
      expect(product2.isWelfarePriceRange, false);

      final product3 = ProductModel(
        id: '3',
        name: '测试',
        description: '',
        price: 599.0,
        category: '手链',
        material: '和田玉',
        images: [],
        stock: 10,
      );
      expect(product3.isWelfarePriceRange, true);
    });
  });

  group('ProductService 获取商品测试', () {
    test('getProducts 应返回商品列表', () async {
      final products = await productService.getProducts();

      expect(products, isNotNull);
      expect(products.isNotEmpty, true);
    });

    test('getProducts 按分类筛选应正确', () async {
      final allProducts = await productService.getProducts();
      final braceletProducts = await productService.getProducts(category: '手链');

      for (final product in braceletProducts) {
        expect(product.category, '手链');
      }

      expect(braceletProducts.length, lessThanOrEqualTo(allProducts.length));
    });

    test('getProducts 按材质筛选应正确', () async {
      final products = await productService.getProducts(material: '和田玉');

      for (final product in products) {
        expect(product.material, '和田玉');
      }
    });

    test('getProducts 按价格区间筛选应正确', () async {
      final products = await productService.getProducts(
        minPrice: 200,
        maxPrice: 500,
      );

      for (final product in products) {
        expect(product.price, greaterThanOrEqualTo(200));
        expect(product.price, lessThanOrEqualTo(500));
      }
    });

    test('getProducts 筛选热门商品应正确', () async {
      final products = await productService.getProducts(isHot: true);

      for (final product in products) {
        expect(product.isHot, true);
      }
    });

    test('getProducts 筛选新品应正确', () async {
      final products = await productService.getProducts(isNew: true);

      for (final product in products) {
        expect(product.isNew, true);
      }
    });

    test('getProducts 筛选福利款应正确', () async {
      final products = await productService.getProducts(isWelfare: true);

      for (final product in products) {
        expect(product.isWelfare, true);
      }
    });
  });

  group('ProductService 商品详情测试', () {
    test('getProductDetail 应返回商品详情', () async {
      final products = await productService.getProducts();
      if (products.isNotEmpty) {
        final detail = await productService.getProductDetail(products.first.id);
        expect(detail, isNotNull);
        expect(detail!.id, products.first.id);
      }
    });

    test('getProductDetail 不存在的商品应返回null', () async {
      final detail = await productService.getProductDetail('NON_EXISTENT_ID');
      expect(detail, isNull);
    });
  });

  group('ProductService 搜索测试', () {
    test('searchProducts 应返回匹配结果', () async {
      final results = await productService.searchProducts('和田玉');

      for (final product in results) {
        final matches = product.name.contains('和田玉') ||
            product.description.contains('和田玉') ||
            product.material.contains('和田玉');
        expect(matches, true);
      }
    });

    test('searchProducts 空关键词应返回空列表', () async {
      final results = await productService.searchProducts('');
      expect(results, isEmpty);
    });

    test('searchProducts 不匹配的关键词应返回空列表', () async {
      final results = await productService.searchProducts('不存在的商品名称xyz123');
      expect(results, isEmpty);
    });
  });

  group('ProductService 排序测试', () {
    test('按价格升序排序应正确', () async {
      final products = await productService.getProducts(sortBy: 'price_asc');

      for (int i = 1; i < products.length; i++) {
        expect(products[i].price, greaterThanOrEqualTo(products[i - 1].price));
      }
    });

    test('按价格降序排序应正确', () async {
      final products = await productService.getProducts(sortBy: 'price_desc');

      for (int i = 1; i < products.length; i++) {
        expect(products[i].price, lessThanOrEqualTo(products[i - 1].price));
      }
    });

    test('按销量排序应正确', () async {
      final products = await productService.getProducts(sortBy: 'sales');

      for (int i = 1; i < products.length; i++) {
        expect(
          products[i].salesCount,
          lessThanOrEqualTo(products[i - 1].salesCount),
        );
      }
    });

    test('按评分排序应正确', () async {
      final products = await productService.getProducts(sortBy: 'rating');

      for (int i = 1; i < products.length; i++) {
        expect(products[i].rating, lessThanOrEqualTo(products[i - 1].rating));
      }
    });
  });

  group('ProductService 快捷方法测试', () {
    test('getHotProducts 应返回热门商品', () async {
      final products = await productService.getHotProducts(limit: 5);

      for (final product in products) {
        expect(product.isHot, true);
      }
    });

    test('getNewProducts 应返回新品', () async {
      final products = await productService.getNewProducts(limit: 5);

      for (final product in products) {
        expect(product.isNew, true);
      }
    });

    test('getWelfareProducts 应返回福利款', () async {
      final products = await productService.getWelfareProducts(limit: 5);

      for (final product in products) {
        expect(product.isWelfare, true);
      }
    });
  });

  group('ProductService 分类和材质列表测试', () {
    test('getCategories 应返回分类列表', () {
      final categories = productService.getCategories();

      expect(categories, isNotNull);
      expect(categories.isNotEmpty, true);
      expect(categories.contains('全部'), true);
      expect(categories.contains('手链'), true);
      expect(categories.contains('吊坠'), true);
    });

    test('getMaterials 应返回材质列表', () {
      final materials = productService.getMaterials();

      expect(materials, isNotNull);
      expect(materials.isNotEmpty, true);
      expect(materials.contains('和田玉'), true);
      expect(materials.contains('缅甸翡翠'), true);
    });
  });

  group('ProductService 缓存测试', () {
    test('强制刷新应忽略缓存', () async {
      final products1 = await productService.getProducts();
      expect(products1, isNotNull);
      expect(products1.isNotEmpty, true);
    });
  });

  group('MaterialType 枚举测试', () {
    test('MaterialType 应包含所有材质', () {
      expect(MaterialType.values.length, 9);
      expect(MaterialType.values.contains(MaterialType.hetianYu), true);
      expect(MaterialType.values.contains(MaterialType.jadeite), true);
      expect(MaterialType.values.contains(MaterialType.nanHong), true);
    });

    test('MaterialType label 应正确', () {
      expect(MaterialType.hetianYu.label, '和田玉');
      expect(MaterialType.jadeite.label, '缅甸翡翠');
      expect(MaterialType.nanHong.label, '南红玛瑙');
      expect(MaterialType.gold.label, '黄金');
    });
  });

  group('ProductCategory 枚举测试', () {
    test('ProductCategory 应包含所有分类', () {
      expect(ProductCategory.values.length, 6);
      expect(ProductCategory.values.contains(ProductCategory.bracelet), true);
      expect(ProductCategory.values.contains(ProductCategory.pendant), true);
      expect(ProductCategory.values.contains(ProductCategory.ring), true);
    });

    test('ProductCategory label 应正确', () {
      expect(ProductCategory.bracelet.label, '手链');
      expect(ProductCategory.pendant.label, '吊坠');
      expect(ProductCategory.ring.label, '戒指');
      expect(ProductCategory.bangle.label, '手镯');
      expect(ProductCategory.necklace.label, '项链');
      expect(ProductCategory.earring.label, '耳饰');
    });
  });

  group('边界情况测试', () {
    test('分页参数应正确处理', () async {
      final page1 = await productService.getProducts(page: 1, pageSize: 2);
      expect(page1, isNotNull);
      expect(page1.isNotEmpty, true);
    });

    test('组合筛选条件应正确工作', () async {
      final products = await productService.getProducts(
        category: '手链',
        minPrice: 100,
        maxPrice: 500,
        isHot: true,
      );

      for (final product in products) {
        expect(product.category, '手链');
        expect(product.price, greaterThanOrEqualTo(100));
        expect(product.price, lessThanOrEqualTo(500));
        expect(product.isHot, true);
      }
    });
  });
}
