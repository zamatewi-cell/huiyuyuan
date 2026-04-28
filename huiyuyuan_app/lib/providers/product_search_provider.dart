library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/product_translator.dart';
import '../models/product_model.dart';
import '../services/user_data_service.dart';
import 'product_catalog_provider.dart';

final productSearchUserDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

final productSearchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(productSearchUserDataServiceProvider);
  await service.initialize();
  return service.getSearchHistory();
});

final productSearchHotProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productCatalogProductsProvider);
  final rankedProducts = [...products]..sort((left, right) {
      if (left.isHot != right.isHot) {
        return left.isHot ? -1 : 1;
      }
      if (left.isNew != right.isNew) {
        return left.isNew ? -1 : 1;
      }
      final salesComparison = right.salesCount.compareTo(left.salesCount);
      if (salesComparison != 0) {
        return salesComparison;
      }
      return right.rating.compareTo(left.rating);
    });

  return rankedProducts.take(4).toList(growable: false);
});

enum ProductSearchSortType { relevance, priceLow, priceHigh, sales }

class ProductSearchState {
  const ProductSearchState({
    this.query = '',
    this.results = const <ProductModel>[],
    this.suggestions = const <ProductModel>[],
    this.isSearching = false,
    this.showResults = false,
    this.filterCategory = productCatalogAllCategory,
    this.sortType = ProductSearchSortType.relevance,
  });

  final String query;
  final List<ProductModel> results;
  final List<ProductModel> suggestions;
  final bool isSearching;
  final bool showResults;
  final String filterCategory;
  final ProductSearchSortType sortType;

  ProductSearchState copyWith({
    String? query,
    List<ProductModel>? results,
    List<ProductModel>? suggestions,
    bool? isSearching,
    bool? showResults,
    String? filterCategory,
    ProductSearchSortType? sortType,
  }) {
    return ProductSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      isSearching: isSearching ?? this.isSearching,
      showResults: showResults ?? this.showResults,
      filterCategory: filterCategory ?? this.filterCategory,
      sortType: sortType ?? this.sortType,
    );
  }
}

class ProductSearchNotifier extends StateNotifier<ProductSearchState> {
  ProductSearchNotifier(this._ref) : super(const ProductSearchState());

  final Ref _ref;

  Future<void> search(String keyword) async {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      clear();
      return;
    }

    state = state.copyWith(
      query: normalizedKeyword,
      isSearching: true,
      showResults: true,
      filterCategory: productCatalogAllCategory,
      sortType: ProductSearchSortType.relevance,
      suggestions: const <ProductModel>[],
    );

    final service = _ref.read(productSearchUserDataServiceProvider);
    await service.addSearchHistory(normalizedKeyword);
    _ref.invalidate(productSearchHistoryProvider);

    final catalogProducts = await _loadCatalogProducts();
    state = state.copyWith(
      query: normalizedKeyword,
      results: _searchCatalogProducts(
        products: catalogProducts,
        keyword: normalizedKeyword,
      ),
      isSearching: false,
      showResults: true,
    );
  }

  Future<void> updateSuggestions(String value) async {
    final normalizedKeyword = value.trim();
    if (normalizedKeyword.isEmpty) {
      state = state.copyWith(query: '', suggestions: const <ProductModel>[]);
      return;
    }

    final catalogProducts = await _loadCatalogProducts();
    state = state.copyWith(
      query: normalizedKeyword,
      suggestions: _searchCatalogProducts(
        products: catalogProducts,
        keyword: normalizedKeyword,
        limit: 6,
      ),
    );
  }

  void setFilterCategory(String category) {
    state = state.copyWith(filterCategory: category);
  }

  void setSortType(ProductSearchSortType sortType) {
    state = state.copyWith(sortType: sortType);
  }

  void clear() {
    state = const ProductSearchState();
  }

  Future<List<ProductModel>> _loadCatalogProducts() async {
    final catalogState = _ref.read(productCatalogProvider);
    if (catalogState.products.isEmpty) {
      await _ref.read(productCatalogProvider.notifier).refresh(
            forceRefresh: false,
          );
    }

    return _ref.read(productCatalogProductsProvider);
  }
}

final productSearchProvider = StateNotifierProvider.autoDispose<
    ProductSearchNotifier, ProductSearchState>((ref) {
  return ProductSearchNotifier(ref);
});

final productSearchFilteredResultsProvider =
    Provider.autoDispose<List<ProductModel>>((ref) {
  final state = ref.watch(productSearchProvider);
  final normalizedCategory = state.filterCategory;
  final results = normalizedCategory == productCatalogAllCategory
      ? List<ProductModel>.from(state.results)
      : state.results
          .where(
            (product) =>
                ProductTranslator.canonicalCategory(product.category) ==
                normalizedCategory,
          )
          .toList(growable: false);

  switch (state.sortType) {
    case ProductSearchSortType.priceLow:
      results.sort((left, right) => left.price.compareTo(right.price));
    case ProductSearchSortType.priceHigh:
      results.sort((left, right) => right.price.compareTo(left.price));
    case ProductSearchSortType.sales:
      results.sort(
        (left, right) => right.salesCount.compareTo(left.salesCount),
      );
    case ProductSearchSortType.relevance:
      break;
  }

  return results;
});

final productSearchResultCategoriesProvider =
    Provider.autoDispose<List<String>>((ref) {
  final results =
      ref.watch(productSearchProvider.select((state) => state.results));
  final categories = <String>[productCatalogAllCategory];
  final seen = <String>{};

  for (final product in results) {
    final canonicalCategory = ProductTranslator.canonicalCategory(
      product.category,
    );
    if (canonicalCategory.isEmpty) {
      continue;
    }
    if (seen.add(canonicalCategory)) {
      categories.add(canonicalCategory);
    }
  }

  return List<String>.unmodifiable(categories);
});

List<ProductModel> _searchCatalogProducts({
  required List<ProductModel> products,
  required String keyword,
  int limit = 20,
}) {
  final normalizedKeyword = keyword.trim().toLowerCase();
  if (normalizedKeyword.isEmpty) {
    return const <ProductModel>[];
  }

  final results = products.where((product) {
    final searchableText = <String>[
      product.id,
      product.name,
      product.nameEn ?? '',
      product.nameZhTw ?? '',
      product.description,
      product.descriptionEn ?? '',
      product.descriptionZhTw ?? '',
      product.category,
      product.categoryEn ?? '',
      product.categoryZhTw ?? '',
      product.material,
      product.materialEn ?? '',
      product.materialZhTw ?? '',
      product.origin ?? '',
      product.originEn ?? '',
      product.originZhTw ?? '',
    ].join(' ').toLowerCase();
    return searchableText.contains(normalizedKeyword);
  }).toList(growable: false);

  if (results.length <= limit) {
    return results;
  }

  return results.take(limit).toList(growable: false);
}
