import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuyuan/data/product_data.dart';
import 'package:huiyuyuan/models/product_model.dart';
import 'package:huiyuyuan/services/storage_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await StorageService().clearAll();
    resetRuntimeProductData();
  });

  tearDown(() async {
    resetRuntimeProductData();
    await Future<void>.delayed(Duration.zero);
    await StorageService().clearAll();
  });

  group('Product runtime catalog compatibility', () {
    test('addProduct appends runtime-only products without mutating seed data',
        () {
      final seedLength = readOnlySeedProductData.length;
      final runtimeProduct = _buildRuntimeProduct(id: 'LOCAL-RUNTIME-001');

      addProduct(runtimeProduct);

      expect(readOnlySeedProductData.length, seedLength);
      expect(realProductData.length, seedLength + 1);
      expect(runtimeOnlyProductData.map((product) => product.id),
          contains(runtimeProduct.id));
      expect(getLocalProductById(runtimeProduct.id)?.name, runtimeProduct.name);
      expect(hasRuntimeProductOverrides, isTrue);
    });

    test('addProduct overlays seed ids instead of duplicating them', () {
      final seedProduct = readOnlySeedProductData.first;
      final overlayProduct = seedProduct.copyWith(
        name: '${seedProduct.name}-local',
        price: seedProduct.price + 88,
      );

      addProduct(overlayProduct);

      final visibleProducts = realProductData
          .where((product) => product.id == seedProduct.id)
          .toList();
      expect(visibleProducts, hasLength(1));
      expect(visibleProducts.single.name, overlayProduct.name);
      expect(visibleProducts.single.price, overlayProduct.price);
      expect(readOnlySeedProductData.first.name, seedProduct.name);
      expect(readOnlySeedProductData.first.price, seedProduct.price);
    });

    test('removeProduct hides seed products without deleting the seed snapshot',
        () {
      final seedProduct = readOnlySeedProductData.first;

      expect(removeProduct(seedProduct.id), isTrue);

      expect(getLocalProductById(seedProduct.id), isNull);
      expect(realProductData.any((product) => product.id == seedProduct.id),
          isFalse);
      expect(
        readOnlySeedProductData.any((product) => product.id == seedProduct.id),
        isTrue,
      );
      expect(hasRuntimeProductOverrides, isTrue);
    });

    test('resetRuntimeProductData restores the seed-backed runtime view', () {
      final seedProduct = readOnlySeedProductData.first;
      addProduct(_buildRuntimeProduct(id: 'LOCAL-RUNTIME-002'));
      removeProduct(seedProduct.id);

      resetRuntimeProductData();

      expect(runtimeOnlyProductData, isEmpty);
      expect(hasRuntimeProductOverrides, isFalse);
      expect(getLocalProductById(seedProduct.id)?.id, seedProduct.id);
      expect(realProductData.length, readOnlySeedProductData.length);
    });
  });
}

ProductModel _buildRuntimeProduct({required String id}) {
  return ProductModel(
    id: id,
    name: '运行态商品-$id',
    description: 'runtime overlay product',
    price: 888,
    category: '手链',
    material: '和田玉',
    images: const ['https://example.com/runtime.jpg'],
    stock: 5,
    isNew: true,
  );
}
