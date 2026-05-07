import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/services/ai_product_context_service.dart';

void main() {
  ProductModel buildProduct({
    required String id,
    required String name,
    required String material,
    required String category,
    required double price,
    String? origin,
    List<String>? audienceTags,
    String? originStory,
    List<String>? flawNotes,
  }) {
    return ProductModel(
      id: id,
      name: name,
      description: '$name 描述',
      price: price,
      category: category,
      material: material,
      images: const ['https://example.com/product.png'],
      stock: 10,
      origin: origin,
      audienceTags: audienceTags,
      originStory: originStory,
      flawNotes: flawNotes,
    );
  }

  group('AI 商品上下文服务测试', () {
    test('应按材质分组构建商品上下文', () async {
      final service = AIProductContextService(
        productLoader: ({int pageSize = 50}) async => [
          buildProduct(
            id: 'HYY-HT001',
            name: '和田玉手链',
            material: '和田玉',
            category: '手链',
            price: 299,
            origin: '新疆',
            audienceTags: const ['自戴', '礼赠'],
            originStory: '精选新疆和田老料，保留自然温润质感。',
            flawNotes: const ['天然棉线'],
          ),
          buildProduct(
            id: 'HYY-FC002',
            name: '翡翠吊坠',
            material: '缅甸翡翠',
            category: '吊坠',
            price: 1580,
            origin: '缅甸',
          ),
        ],
      );

      final context = await service.buildProductContext();

      expect(context, contains('【平台在售商品概览】'));
      expect(context, contains('目前汇玉源商城共有 2 件在售商品'));
      expect(context, contains('和田玉系列：'));
      expect(context, contains('缅甸翡翠系列：'));
      expect(context, contains('[PRODUCT:商品编号]'));
      expect(context, contains('和田玉手链'));
      expect(context, contains('编号:HYY-HT001'));
      expect(context, contains('¥299'));
      expect(context, contains('适合：自戴/礼赠'));
      expect(context, contains('来源：精选新疆和田老料'));
      expect(context, contains('特征：天然棉线'));
    });

    test('商品加载失败时应返回空字符串', () async {
      final service = AIProductContextService(
        productLoader: ({int pageSize = 50}) async {
          throw Exception('mock failure');
        },
      );

      final context = await service.buildProductContext();

      expect(context, isEmpty);
      expect(service.lastError, contains('mock failure'));
    });

    test('应正确提取推荐商品标签', () {
      final service = AIProductContextService();

      final productIds = service.extractProductIds(
        '推荐这两款给您：\n[PRODUCT:HYY-HT001]\n[PRODUCT:HYY-FC002]',
      );

      expect(productIds, ['HYY-HT001', 'HYY-FC002']);
    });

    test('应正确移除推荐商品标签', () {
      final service = AIProductContextService();

      final cleanContent = service.stripProductTags(
        '这两款都很适合日常佩戴。\n[PRODUCT:HYY-HT001]\n[PRODUCT:HYY-FC002]',
      );

      expect(cleanContent, '这两款都很适合日常佩戴。');
    });
  });
}
