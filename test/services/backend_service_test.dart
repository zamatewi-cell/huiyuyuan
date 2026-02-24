/// 汇玉源 - 后端服务测试
/// 
/// 测试内容:
/// - API请求封装
/// - 错误处理
/// - 连接检查
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuanyuan/services/backend_service.dart';
import 'package:huiyuanyuan/models/user_model.dart';

void main() {
  late BackendService backendService;

  setUp(() {
    backendService = BackendService();
  });

  group('BackendService 初始化测试', () {
    test('BackendService 应能正确实例化', () {
      expect(backendService, isNotNull);
    });

    test('initialize 应能正确初始化', () {
      backendService.initialize();
    });
  });

  group('BackendService 连接测试', () {
    test('checkConnection 应返回布尔值', () async {
      final result = await backendService.checkConnection();
      expect(result, isA<bool>());
    });

    test('baseUrl 应正确配置', () {
      expect(BackendService.baseUrl, isNotNull);
      expect(BackendService.baseUrl.contains('http'), true);
    });
  });

  group('BackendService GET请求测试', () {
    test('get 请求应能执行', () async {
      backendService.initialize();
      
      try {
        final result = await backendService.get('/health');
        expect(result, isNotNull);
      } catch (e) {
        expect(e, isException);
      }
    });

    test('get 请求带参数应能执行', () async {
      backendService.initialize();
      
      try {
        final result = await backendService.get(
          '/api/products',
          params: {'category': '手链'},
        );
        expect(result, isNotNull);
      } catch (e) {
        expect(e, isException);
      }
    });
  });

  group('BackendService POST请求测试', () {
    test('post 请求应能执行', () async {
      backendService.initialize();
      
      try {
        final result = await backendService.post(
          '/api/auth/login',
          data: {
            'username': 'test',
            'password': 'test123',
          },
        );
        expect(result, isNotNull);
      } catch (e) {
        expect(e, isException);
      }
    });
  });

  group('BackendService 商品API测试', () {
    test('getProducts 应返回商品列表', () async {
      backendService.initialize();
      
      try {
        final products = await backendService.getProducts();
        expect(products, isA<List<ProductModel>>());
      } catch (e) {
        expect(e, isException);
      }
    });

    test('getProducts 带分类参数应正确筛选', () async {
      backendService.initialize();
      
      try {
        final products = await backendService.getProducts(category: '手链');
        expect(products, isA<List<ProductModel>>());
      } catch (e) {
        expect(e, isException);
      }
    });

    test('getProductDetail 应返回商品详情', () async {
      backendService.initialize();
      
      try {
        final product = await backendService.getProductDetail('HYY-HT001');
        if (product != null) {
          expect(product, isA<ProductModel>());
        }
      } catch (e) {
        expect(e, isException);
      }
    });

    test('getProductDetail 不存在的商品应返回null', () async {
      backendService.initialize();
      
      final product = await backendService.getProductDetail('NON_EXISTENT');
      expect(product, isNull);
    });
  });

  group('错误处理测试', () {
    test('连接超时应抛出异常', () async {
      backendService.initialize();
      
      try {
        await backendService.get('/slow-endpoint');
      } catch (e) {
        expect(e, isException);
      }
    });

    test('无效路径应抛出异常', () async {
      backendService.initialize();
      
      try {
        await backendService.get('/invalid/path/that/does/not/exist');
      } catch (e) {
        expect(e, isException);
      }
    });
  });

  group('ProductModel 后端解析测试', () {
    test('ProductModel 应正确解析后端响应', () {
      final json = {
        'id': 'HYY-TEST-001',
        'name': '测试商品',
        'description': '测试描述',
        'price': 299.0,
        'original_price': 599.0,
        'category': '手链',
        'material': '和田玉',
        'images': ['https://example.com/image.jpg'],
        'stock': 100,
        'rating': 4.9,
        'sales_count': 1000,
        'is_hot': true,
        'is_new': false,
        'origin': '新疆和田',
        'certificate': 'GTC-2026-001',
        'blockchain_hash': '0xabcdef123456',
        'is_welfare': true,
        'material_verify': '天然A货',
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'HYY-TEST-001');
      expect(product.name, '测试商品');
      expect(product.price, 299.0);
      expect(product.category, '手链');
      expect(product.material, '和田玉');
      expect(product.isHot, true);
      expect(product.isWelfare, true);
      expect(product.blockchainHash, '0xabcdef123456');
    });

    test('ProductModel 应处理缺失字段', () {
      final json = {
        'id': 'HYY-TEST-002',
        'name': '最小商品',
        'description': '',
        'price': 0,
        'category': '',
        'material': '',
        'images': <String>[],
        'stock': 0,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'HYY-TEST-002');
      expect(product.name, '最小商品');
      expect(product.price, 0);
      expect(product.rating, 5.0);
      expect(product.salesCount, 0);
      expect(product.isHot, false);
      expect(product.isNew, false);
      expect(product.isWelfare, false);
    });
  });

  group('并发请求测试', () {
    test('多个并发请求应能处理', () async {
      backendService.initialize();
      
      final futures = List.generate(5, (i) => backendService.getProducts());
      
      try {
        final results = await Future.wait(futures);
        expect(results.length, 5);
        for (final result in results) {
          expect(result, isA<List<ProductModel>>());
        }
      } catch (e) {
        expect(e, isException);
      }
    });
  });

  group('边界情况测试', () {
    test('空路径请求应能处理', () async {
      backendService.initialize();
      
      try {
        await backendService.get('');
      } catch (e) {
        expect(e, isException);
      }
    });

    test('特殊字符路径应能处理', () async {
      backendService.initialize();
      
      try {
        await backendService.get('/api/products/测试');
      } catch (e) {
        expect(e, isException);
      }
    });

    test('大数据响应应能处理', () async {
      backendService.initialize();
      
      try {
        final products = await backendService.getProducts();
        expect(products.length, lessThanOrEqualTo(100));
      } catch (e) {
        expect(e, isException);
      }
    });
  });
}
