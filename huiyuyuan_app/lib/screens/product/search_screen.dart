library;

import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_model.dart';
import '../../providers/product_catalog_provider.dart';
import '../../providers/product_search_provider.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../widgets/common/error_handler.dart';
import '../../widgets/image/product_image_view.dart';
import '../trade/product_detail_screen.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

typedef _SortType = ProductSearchSortType;

const List<String> _hotSearchKeys = <String>[
  'search_hot_hetian_jade',
  'search_hot_jadeite_bracelet',
  'search_hot_nanhong',
  'search_hot_peace_pendant',
  'search_hot_amethyst',
  'search_hot_beeswax',
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _animController;

  ProductSearchNotifier get _searchNotifier =>
      ref.read(productSearchProvider.notifier);

  List<ProductModel> get _filteredResults =>
      ref.watch(productSearchFilteredResultsProvider);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusNode.requestFocus();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String keyword) async {
    await _searchNotifier.search(keyword);
    if (mounted) {
      _animController.forward(from: 0);
    }
  }

  Future<void> _onSearchChanged(String value) {
    return _searchNotifier.updateSuggestions(value);
  }

  void _selectKeyword(String keyword) {
    _searchController.text = keyword;
    _performSearch(keyword);
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchNotifier.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final searchState = ref.watch(productSearchProvider);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(isDark),
            if (!searchState.showResults && searchState.suggestions.isNotEmpty)
              _buildSuggestionList(searchState.suggestions, isDark),
            if (!searchState.showResults && searchState.suggestions.isEmpty)
              Expanded(child: _buildDiscoveryView(isDark)),
            if (searchState.showResults) ...[
              if (searchState.results.isNotEmpty) _buildFilterBar(isDark),
              Expanded(child: _buildResultList(isDark, searchState)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? JewelryColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.adaptiveTextSecondary,
              size: 20,
            ),
          ),
          Expanded(
            child: Container(
              height: 42,
              padding: EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFF5F5F8),
                borderRadius: BorderRadius.circular(21),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: JewelryColors.textHint, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: ref.tr('search_hint'),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(color: context.adaptiveTextPrimary),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () => _performSearch(_searchController.text),
            child: Text(
              ref.tr('search'),
              style: TextStyle(
                color: JewelryColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionList(List<ProductModel> suggestions, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      color: isDark ? JewelryColors.darkCard : Colors.white,
      child: ListView(
        shrinkWrap: true,
        children: suggestions.map((product) {
          return ListTile(
            leading: Icon(Icons.search, color: Colors.grey[400], size: 18),
            title: Text(
              product.titleL10n,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(product.catL10n),
            trailing: Icon(Icons.north_west, color: Colors.grey[400], size: 16),
            onTap: () => _selectKeyword(product.titleL10n),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildDiscoveryView(bool isDark) {
    final historyAsync = ref.watch(productSearchHistoryProvider);
    final hotProducts = ref.watch(productSearchHotProductsProvider);
    final catalogState = ref.watch(productCatalogProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ref.tr('search_history'),
                          style: TextStyle(
                              color: context.adaptiveTextPrimary,
                              fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () async {
                          final service =
                              ref.read(productSearchUserDataServiceProvider);
                          final success = await service.clearSearchHistory();
                          if (success) {
                            ref.invalidate(productSearchHistoryProvider);
                          } else if (mounted) {
                            context.showError(ref.tr('search_clear_fail'));
                          }
                        },
                        child: Text(ref.tr('search_clear_action')),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: history
                        .map((keyword) => _buildChip(keyword, isDark))
                        .toList(growable: false),
                  ),
                  SizedBox(height: 24),
                ],
              );
            },
            loading: () => SizedBox.shrink(),
            error: (_, __) => SizedBox.shrink(),
          ),
          Text(ref.tr('search_hot'),
              style: TextStyle(
                  color: context.adaptiveTextPrimary,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hotSearchKeys
                .map((key) => _buildChip(key.tr, isDark, hot: true))
                .toList(growable: false),
          ),
          SizedBox(height: 28),
          Text(ref.tr('search_discover'),
              style: TextStyle(
                  color: context.adaptiveTextPrimary,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          if (catalogState.isLoading && hotProducts.isEmpty)
            Center(child: CircularProgressIndicator())
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: hotProducts.length,
              itemBuilder: (_, index) =>
                  _buildMiniProductCard(hotProducts[index], isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, bool isDark, {bool hot = false}) {
    return GestureDetector(
      onTap: () => _selectKeyword(text),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: hot
              ? JewelryColors.primary.withOpacity(isDark ? 0.2 : 0.08)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFF2F3F5)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: hot ? JewelryColors.primary : context.adaptiveTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniProductCard(ProductModel product, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? JewelryColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                child: ProductImageView(
                  product: product,
                  imageUrl:
                      product.images.isNotEmpty ? product.images.first : null,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                product.titleL10n,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.adaptiveTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final searchState = ref.watch(productSearchProvider);
    final categories = ref.watch(productSearchResultCategoriesProvider);

    return Container(
      color: isDark ? JewelryColors.darkSurface : Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: categories.length,
              itemBuilder: (_, index) {
                final category = categories[index];
                final isSelected = category == searchState.filterCategory;
                return GestureDetector(
                  onTap: () => _searchNotifier.setFilterCategory(category),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? JewelryColors.primary
                          : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFFF2F3F5)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.adaptiveTextSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                    ref.tr('search_result_count',
                        params: {'count': _filteredResults.length}),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                Spacer(),
                _buildSortChip(
                    ref.tr('sort_comprehensive'), _SortType.relevance),
                _buildSortChip(ref.tr('sort_price_asc'), _SortType.priceLow),
                _buildSortChip(ref.tr('sort_price_desc'), _SortType.priceHigh),
                _buildSortChip(ref.tr('sort_sales'), _SortType.sales),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, _SortType type) {
    final selected =
        ref.watch(productSearchProvider.select((state) => state.sortType)) ==
            type;

    return GestureDetector(
      onTap: () => _searchNotifier.setSortType(type),
      child: Container(
        margin: EdgeInsets.only(left: 8),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? JewelryColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? JewelryColors.primary : Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildResultList(bool isDark, ProductSearchState searchState) {
    if (searchState.isSearching) {
      return Center(child: CircularProgressIndicator());
    }
    if (_filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(ref.tr('search_empty'),
                style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _filteredResults.length,
      itemBuilder: (_, index) =>
          _buildResultCard(_filteredResults[index], isDark, index),
    );
  }

  Widget _buildResultCard(ProductModel product, bool isDark, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? JewelryColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ProductImageView(
                product: product,
                imageUrl:
                    product.images.isNotEmpty ? product.images.first : null,
                width: 90,
                height: 90,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.titleL10n,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: context.adaptiveTextPrimary,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text(product.matL10n,
                      style: TextStyle(
                          color: context.adaptiveTextSecondary, fontSize: 12)),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('¥${product.price.toInt()}',
                          style: const TextStyle(
                              color: JewelryColors.price,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Spacer(),
                      Text(
                          ref.tr('search_paid_count',
                              params: {'count': product.salesCount}),
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
