library;

import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuanyuan/models/user_model.dart';

void main() {
  group('favorite payloads', () {
    test('favorite item contains required fields', () {
      final favorite = {
        'id': 'prod_001',
        'name': 'Hetian bracelet',
        'price': 9999,
        'original_price': 12999,
        'material': 'Hetian jade',
        'image': 'https://example.com/image.jpg',
      };

      expect(favorite['id'], 'prod_001');
      expect(favorite['name'], 'Hetian bracelet');
      expect(favorite['price'], 9999);
      expect(favorite['original_price'], 12999);
      expect(favorite['material'], 'Hetian jade');
      expect(favorite['image'], isNotNull);
    });

    test('favorite list preserves payload order', () {
      final favorites = [
        {'id': 'prod_001', 'name': 'Item 1', 'price': 100},
        {'id': 'prod_002', 'name': 'Item 2', 'price': 200},
      ];

      expect(favorites.length, 2);
      expect(favorites.first['id'], 'prod_001');
      expect(favorites.last['price'], 200);
    });
  });

  group('browse history payloads', () {
    test('history item contains product details', () {
      final historyItem = {
        'id': 'prod_001',
        'name': 'Jade pendant',
        'price': 5999,
        'material': 'Jadeite',
        'image': 'https://example.com/image.jpg',
        'viewed_at': '2024-01-01T10:00:00Z',
      };

      expect(historyItem['id'], 'prod_001');
      expect(historyItem['name'], 'Jade pendant');
      expect(historyItem['price'], 5999);
      expect(historyItem['material'], 'Jadeite');
      expect(historyItem['viewed_at'], '2024-01-01T10:00:00Z');
    });

    test('history can be sorted by viewed_at descending', () {
      final history = [
        {'id': 'prod_001', 'viewed_at': '2024-01-01T10:00:00Z'},
        {'id': 'prod_002', 'viewed_at': '2024-01-01T11:00:00Z'},
        {'id': 'prod_003', 'viewed_at': '2024-01-01T12:00:00Z'},
      ];

      history.sort(
        (a, b) =>
            (b['viewed_at'] as String).compareTo(a['viewed_at'] as String),
      );

      expect(history.first['id'], 'prod_003');
      expect(history.last['id'], 'prod_001');
    });
  });

  group('search history payloads', () {
    test('search keywords are stored as strings', () {
      final history = ['hetian', 'jadeite', 'ruby'];

      expect(history.length, 3);
      expect(history.first, 'hetian');
      expect(history.last, 'ruby');
    });

    test('duplicate search can be moved to the front', () {
      final history = ['bracelet', 'pendant', 'ring'];
      const newSearch = 'pendant';

      history.remove(newSearch);
      history.insert(0, newSearch);

      expect(history.first, 'pendant');
      expect(history.length, 3);
    });

    test('search history can be capped to 20 items', () {
      final history = List.generate(30, (index) => 'keyword_$index');
      final limited = history.take(20).toList();

      expect(limited.length, 20);
      expect(limited.first, 'keyword_0');
      expect(limited.last, 'keyword_19');
    });
  });

  group('product search results', () {
    test('ProductModel parses search result payload', () {
      final product = ProductModel(
        id: 'prod_001',
        name: 'Hetian bracelet',
        description: 'Premium Hetian bracelet',
        price: 9999,
        category: 'bracelet',
        material: 'Hetian jade',
        images: ['https://example.com/image.jpg'],
        stock: 10,
        salesCount: 100,
        rating: 4.8,
      );

      expect(product.id, 'prod_001');
      expect(product.name, 'Hetian bracelet');
      expect(product.price, 9999);
      expect(product.material, 'Hetian jade');
      expect(product.category, 'bracelet');
      expect(product.salesCount, 100);
      expect(product.rating, 4.8);
    });

    test('keyword matching can use name material or category', () {
      final products = [
        ProductModel(
          id: 'prod_001',
          name: 'Hetian bracelet',
          description: 'Premium Hetian jade',
          price: 9999,
          category: 'bracelet',
          material: 'Hetian jade',
          images: const [],
          stock: 10,
        ),
        ProductModel(
          id: 'prod_002',
          name: 'Jade pendant',
          description: 'Natural jadeite',
          price: 5999,
          category: 'pendant',
          material: 'Jadeite',
          images: const [],
          stock: 15,
        ),
      ];

      const keyword = 'hetian';
      final results = products.where((product) {
        return product.name.toLowerCase().contains(keyword) ||
            product.material.toLowerCase().contains(keyword) ||
            product.category.toLowerCase().contains(keyword);
      }).toList();

      expect(results.length, 1);
      expect(results.first.id, 'prod_001');
    });

    test('hot products can be sorted by sales count descending', () {
      final products = [
        ProductModel(
          id: 'prod_001',
          name: 'Item 1',
          description: '',
          price: 100,
          category: 'bracelet',
          material: 'Hetian jade',
          images: const [],
          stock: 10,
          salesCount: 500,
        ),
        ProductModel(
          id: 'prod_002',
          name: 'Item 2',
          description: '',
          price: 200,
          category: 'pendant',
          material: 'Jadeite',
          images: const [],
          stock: 15,
          salesCount: 800,
        ),
        ProductModel(
          id: 'prod_003',
          name: 'Item 3',
          description: '',
          price: 300,
          category: 'ring',
          material: 'Ruby',
          images: const [],
          stock: 20,
          salesCount: 300,
        ),
      ];

      products.sort((a, b) => b.salesCount.compareTo(a.salesCount));

      expect(products.first.id, 'prod_002');
      expect(products.first.salesCount, 800);
      expect(products.last.id, 'prod_003');
    });
  });

  group('api payload shapes', () {
    test('favorites response shape is valid', () {
      final response = {
        'success': true,
        'data': [
          {
            'id': 'prod_001',
            'name': 'Hetian bracelet',
            'price': 9999,
            'original_price': 12999,
            'material': 'Hetian jade',
            'image': 'https://example.com/image.jpg',
          },
        ],
      };

      expect(response['success'], true);
      expect((response['data'] as List).length, 1);
      expect((response['data'] as List).first['id'], 'prod_001');
    });

    test('browse history response shape is valid', () {
      final response = {
        'success': true,
        'data': [
          {
            'id': 'prod_001',
            'name': 'Jade pendant',
            'price': 5999,
            'material': 'Jadeite',
            'image': 'https://example.com/image.jpg',
          },
        ],
      };

      expect(response['success'], true);
      final data = response['data'] as List;
      expect(data.length, 1);
      expect(data.first['name'], 'Jade pendant');
    });

    test('search history response shape is valid', () {
      final response = {
        'success': true,
        'data': ['hetian', 'jadeite', 'ruby'],
      };

      expect(response['success'], true);
      final data = response['data'] as List;
      expect(data.length, 3);
      expect(data.first, 'hetian');
      expect(data.last, 'ruby');
    });

    test('product search response can be parsed into ProductModel', () {
      final response = {
        'success': true,
        'data': [
          {
            'id': 'prod_001',
            'name': 'Hetian bracelet',
            'description': 'Premium Hetian bracelet',
            'price': 9999,
            'original_price': 12999,
            'category': 'bracelet',
            'material': 'Hetian jade',
            'images': ['https://example.com/image.jpg'],
            'stock': 10,
            'sales_count': 100,
            'rating': 4.8,
          },
        ],
      };

      expect(response['success'], true);
      final data = response['data'] as List;
      final product = ProductModel.fromJson(data.first as Map<String, dynamic>);

      expect(product.id, 'prod_001');
      expect(product.name, 'Hetian bracelet');
      expect(product.salesCount, 100);
      expect(product.rating, 4.8);
    });
  });
}
