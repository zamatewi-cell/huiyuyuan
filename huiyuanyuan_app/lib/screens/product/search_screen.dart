/// 汇玉源 - 商品搜索页面（完整版）
///
/// 功能:
/// - 真实商品数据搜索（名称/材质/分类/编号/描述）
/// - 搜索历史（本地持久化）
/// - 热门搜索标签（排名高亮）
/// - 实时搜索建议（边输入边推荐）
/// - 搜索结果分类筛选 + 价格/销量排序
/// - 搜索结果点击跳转商品详情
/// - 发现好物推荐（热销 Top4）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../services/user_data_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/error_handler.dart';
import '../trade/product_detail_screen.dart';

final _userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(_userDataServiceProvider);
  await service.initialize();
  return await service.getSearchHistory();
});

final hotProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final service = ref.watch(_userDataServiceProvider);
  await service.initialize();
  return await service.getHotProducts(limit: 4);
});

const List<String> hotSearches = [
  '和田玉',
  '翡翠手链',
  '南红玛瑙',
  '平安扣',
  '貔貅',
  '福利款',
  '紫水晶',
  '蜜蜡',
];

enum _SortType { relevance, priceLow, priceHigh, sales }

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<ProductModel> _searchResults = [];
  List<ProductModel> _suggestions = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _filterCategory = '全部';
  _SortType _sortType = _SortType.relevance;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _focusNode.requestFocus();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
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
    final kw = keyword.trim();
    if (kw.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showResults = true;
      _filterCategory = '全部';
      _sortType = _SortType.relevance;
      _suggestions = [];
    });

    final service = ref.read(_userDataServiceProvider);
    await service.addSearchHistory(kw);
    ref.invalidate(searchHistoryProvider);

    _searchResults = await service.searchProducts(keyword: kw);

    if (mounted) {
      setState(() => _isSearching = false);
      _animController.forward(from: 0.0);
    }
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        if (!_showResults) return;
      });
      return;
    }
    final kw = value.trim();
    final service = ref.read(_userDataServiceProvider);
    final results = await service.searchProducts(keyword: kw, pageSize: 6);
    if (mounted) {
      setState(() {
        _suggestions = results;
      });
    }
  }

  List<ProductModel> get _filteredResults {
    var results = _filterCategory == '全部'
        ? List<ProductModel>.from(_searchResults)
        : _searchResults.where((p) => p.category == _filterCategory).toList();

    switch (_sortType) {
      case _SortType.priceLow:
        results.sort((a, b) => a.price.compareTo(b.price));
      case _SortType.priceHigh:
        results.sort((a, b) => b.price.compareTo(a.price));
      case _SortType.sales:
        results.sort((a, b) => b.salesCount.compareTo(a.salesCount));
      case _SortType.relevance:
        break;
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(isDark),
            if (!_showResults && _suggestions.isNotEmpty)
              _buildSuggestionList(isDark),
            if (!_showResults && _suggestions.isEmpty)
              Expanded(child: _buildSearchSuggestions(isDark)),
            if (_showResults) ...[
              if (_searchResults.isNotEmpty) _buildFilterSortBar(isDark),
              Expanded(child: _buildSearchResults(isDark)),
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
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.adaptiveTextSecondary, size: 20),
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
                  Icon(Icons.search_rounded,
                      color: JewelryColors.textHint, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: '搜索商品、材质、品类...',
                        hintStyle: TextStyle(
                          color: JewelryColors.textHint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: TextStyle(
                          fontSize: 14,
                          color: context.adaptiveTextPrimary),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        _onSearchChanged(value);
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _showResults = false;
                          _suggestions = [];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _performSearch(_searchController.text);
              FocusScope.of(context).unfocus();
            },
            child: Text(
              '搜索',
              style: TextStyle(
                color: JewelryColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionList(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: isDark ? JewelryColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: _suggestions.map((product) {
          return InkWell(
            onTap: () {
              _searchController.text = product.name;
              _performSearch(product.name);
              FocusScope.of(context).unfocus();
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: _highlightText(
                          product.name, _searchController.text.trim()),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(product.category,
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(width: 8),
                  Icon(Icons.north_west, size: 14, color: Colors.grey[400]),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  TextSpan _highlightText(String text, String query) {
    final base = TextStyle(
        color: context.adaptiveTextPrimary, fontSize: 14);
    if (query.isEmpty) return TextSpan(text: text, style: base);
    final idx = text.toLowerCase().indexOf(query.toLowerCase());
    if (idx == -1) return TextSpan(text: text, style: base);
    return TextSpan(children: [
      if (idx > 0) TextSpan(text: text.substring(0, idx), style: base),
      TextSpan(
        text: text.substring(idx, idx + query.length),
        style: base.copyWith(
            color: JewelryColors.primary, fontWeight: FontWeight.bold),
      ),
      if (idx + query.length < text.length)
        TextSpan(text: text.substring(idx + query.length), style: base),
    ]);
  }

  Widget _buildSearchSuggestions(bool isDark) {
    final historyAsync = ref.watch(searchHistoryProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('搜索历史',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.adaptiveTextPrimary,
                          )),
                      GestureDetector(
                        onTap: () async {
                          final service = ref.read(_userDataServiceProvider);
                          final success = await service.clearSearchHistory();
                          if (success && mounted) {
                            ref.invalidate(searchHistoryProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('搜索历史已清空')),
                            );
                          } else if (mounted) {
                            context.showError('清空失败，请重试');
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.grey[400], size: 16),
                            const SizedBox(width: 4),
                            Text('清空',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: history.map((keyword) {
                      return _buildHistoryTag(keyword, isDark);
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          Row(
            children: [
              Text('热门搜索',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.adaptiveTextPrimary,
                  )),
              const SizedBox(width: 6),
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6B6B), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: List.generate(hotSearches.length, (i) {
              return _buildHotTag(hotSearches[i], i, isDark);
            }),
          ),

          const SizedBox(height: 36),
          Text('发现好物',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.adaptiveTextPrimary,
              )),
          const SizedBox(height: 12),
          _buildRecommendGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildHistoryTag(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _performSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 13, color: context.adaptiveTextSecondary)),
      ),
    );
  }

  Widget _buildHotTag(String text, int index, bool isDark) {
    final isTop3 = index < 3;
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _performSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isTop3
              ? JewelryColors.primary.withOpacity(isDark ? 0.2 : 0.08)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFF2F3F5)),
          borderRadius: BorderRadius.circular(18),
          border: isTop3
              ? Border.all(
                  color: JewelryColors.primary.withOpacity(0.3), width: 0.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTop3)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text('${index + 1}',
                    style: TextStyle(
                      color: JewelryColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    )),
              ),
            Text(text,
                style: TextStyle(
                  fontSize: 13,
                  color: isTop3
                      ? JewelryColors.primary
                      : context.adaptiveTextSecondary,
                  fontWeight: isTop3 ? FontWeight.w500 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendGrid(bool isDark) {
    final hotProductsAsync = ref.watch(hotProductsProvider);
    return hotProductsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => _buildMiniProductCard(products[i], isDark),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniProductCard(ProductModel product, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? JewelryColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  memCacheWidth: 300,
                  errorWidget: (_, __, ___) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    child: Icon(Icons.diamond_rounded,
                        color: Colors.grey[400], size: 32),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.adaptiveTextPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('¥${product.price.toInt()}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: JewelryColors.price,
                          )),
                      const Spacer(),
                      Text('${product.salesCount}人付款',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 10)),
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

  // ─────────────── 筛选/排序栏 ───────────────
  Widget _buildFilterSortBar(bool isDark) {
    final cats = ['全部', ...{..._searchResults.map((p) => p.category)}];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? JewelryColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.12)),
        ),
      ),
      child: Column(
        children: [
          // 分类标签
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final cat = cats[i];
                final selected = cat == _filterCategory;
                return GestureDetector(
                  onTap: () => setState(() => _filterCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient:
                          selected ? JewelryColors.primaryGradient : null,
                      color: selected
                          ? null
                          : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFFF2F3F5)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(cat,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : context.adaptiveTextSecondary,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
          // 排序栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text('共 ${_filteredResults.length} 件',
                    style:
                        TextStyle(color: Colors.grey[400], fontSize: 12)),
                const Spacer(),
                _buildSortChip('综合', _SortType.relevance, isDark),
                _buildSortChip('价格↑', _SortType.priceLow, isDark),
                _buildSortChip('价格↓', _SortType.priceHigh, isDark),
                _buildSortChip('销量', _SortType.sales, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, _SortType type, bool isDark) {
    final selected = _sortType == type;
    return GestureDetector(
      onTap: () => setState(() => _sortType = type),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? JewelryColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? JewelryColors.primary : Colors.grey[500],
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }

  // ─────────────── 搜索结果列表 ───────────────
  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 114,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    final results = _filteredResults;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('未找到相关商品',
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('换个关键词试试吧',
                style:
                    TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: results.length,
      itemBuilder: (_, i) => _buildResultCard(results[i], isDark, i),
    );
  }

  Widget _buildResultCard(ProductModel product, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? JewelryColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 商品图片
              Hero(
                tag: 'search_product_${product.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          memCacheWidth: 180,
                          errorWidget: (_, __, ___) =>
                              _buildImagePlaceholder(isDark),
                        )
                      : _buildImagePlaceholder(isDark),
                ),
              ),
              const SizedBox(width: 12),
              // 商品信息
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.adaptiveTextPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildSmallTag(product.material, isDark),
                              const SizedBox(width: 6),
                              _buildSmallTag(product.category, isDark),
                              if (product.isHot) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B6B)
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: const Text('热销',
                                      style: TextStyle(
                                          color: Color(0xFFFF6B6B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text('¥',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: JewelryColors.price,
                                  )),
                              Text('${product.price.toInt()}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: JewelryColors.price,
                                    height: 1,
                                  )),
                              if (product.originalPrice != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                    '¥${product.originalPrice!.toInt()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                      decoration:
                                          TextDecoration.lineThrough,
                                    )),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFB800), size: 14),
                              Text('${product.rating}',
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11)),
                              Text(' · ${product.salesCount}付款',
                                  style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallTag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: context.adaptiveTextSecondary, fontSize: 10)),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          Icon(Icons.diamond_rounded, color: Colors.grey[400], size: 36),
    );
  }
}
