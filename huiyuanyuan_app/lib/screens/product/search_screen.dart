library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product_model.dart';
import '../../providers/product_catalog_provider.dart';
import '../../providers/product_search_provider.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../widgets/common/error_handler.dart';
import '../trade/product_detail_screen.dart';

typedef _SortType = ProductSearchSortType;

const List<String> _hotSearches = <String>[
  '和田玉',
  '翡翠手链',
  '南红',
  '平安扣',
  '紫水晶',
  '蜜蜡',
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
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFF5F5F8),
                borderRadius: BorderRadius.circular(21),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: JewelryColors.textHint, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: '搜索商品、材质、分类...',
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
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _performSearch(_searchController.text),
            child: const Text(
              '搜索',
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
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(product.category),
            trailing: Icon(Icons.north_west, color: Colors.grey[400], size: 16),
            onTap: () => _selectKeyword(product.name),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('搜索历史',
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
                            context.showError('清空失败，请重试');
                          }
                        },
                        child: const Text('清空'),
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
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Text('热门搜索',
              style: TextStyle(
                  color: context.adaptiveTextPrimary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hotSearches
                .map((keyword) => _buildChip(keyword, isDark, hot: true))
                .toList(growable: false),
          ),
          const SizedBox(height: 28),
          Text('发现好物',
              style: TextStyle(
                  color: context.adaptiveTextPrimary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (catalogState.isLoading && hotProducts.isEmpty)
            const Center(child: CircularProgressIndicator())
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl:
                      product.images.isNotEmpty ? product.images.first : '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.diamond_rounded),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                product.name,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: categories.length,
              itemBuilder: (_, index) {
                final category = categories[index];
                final isSelected = category == searchState.filterCategory;
                return GestureDetector(
                  onTap: () => _searchNotifier.setFilterCategory(category),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text('共 ${_filteredResults.length} 件',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const Spacer(),
                _buildSortChip('综合', _SortType.relevance),
                _buildSortChip('价格↑', _SortType.priceLow),
                _buildSortChip('价格↓', _SortType.priceHigh),
                _buildSortChip('销量', _SortType.sales),
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
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('未找到相关商品',
                style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? JewelryColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.images.first,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
                    )
                  : _buildPlaceholder(isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: context.adaptiveTextPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(product.material,
                      style: TextStyle(
                          color: context.adaptiveTextSecondary, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('¥${product.price.toInt()}',
                          style: const TextStyle(
                              color: JewelryColors.price,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const Spacer(),
                      Text('${product.salesCount}付款',
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

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 90,
      height: 90,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      child: Icon(Icons.diamond_rounded, color: Colors.grey[400]),
    );
  }
}
