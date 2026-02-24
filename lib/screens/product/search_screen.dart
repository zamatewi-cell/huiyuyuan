/// 汇玉源 - 商品搜索页面
///
/// 功能:
/// - 搜索历史
/// - 热门搜索
/// - 实时搜索建议
/// - 搜索结果筛选
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';

/// 搜索历史Provider
final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final storage = StorageService();
  await storage.init();
  return storage.getSearchHistory();
});

/// 热门搜索
const List<String> hotSearches = [
  '和田玉',
  '翡翠',
  '南红',
  '手链',
  '吊坠',
  '福利款',
  '平安扣',
  '转运珠',
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() => _isSearching = true);

    // 保存搜索历史
    final storage = StorageService();
    await storage.addSearchHistory(keyword.trim());

    // 模拟搜索延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 模拟搜索结果
    _searchResults = _getMockSearchResults(keyword);

    setState(() {
      _isSearching = false;
      _showResults = true;
    });
  }

  List<Map<String, dynamic>> _getMockSearchResults(String keyword) {
    final allProducts = [
      {'id': '1', 'name': '和田玉福运手链', 'price': 299, 'material': '和田玉'},
      {'id': '2', 'name': '和田玉平安扣吊坠', 'price': 399, 'material': '和田玉'},
      {'id': '3', 'name': '缅甸翡翠手镯', 'price': 2999, 'material': '翡翠'},
      {'id': '4', 'name': '冰种翡翠观音吊坠', 'price': 1599, 'material': '翡翠'},
      {'id': '5', 'name': '南红玛瑙转运珠手链', 'price': 199, 'material': '南红'},
      {'id': '6', 'name': '南红玛瑙貔貅吊坠', 'price': 599, 'material': '南红'},
      {'id': '7', 'name': '紫水晶手链', 'price': 159, 'material': '紫水晶'},
      {'id': '8', 'name': '蜜蜡琥珀平安扣', 'price': 899, 'material': '蜜蜡'},
    ];

    return allProducts.where((p) {
      final name = p['name'] as String;
      final material = p['material'] as String;
      return name.contains(keyword) || material.contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _showResults
                  ? _buildSearchResults()
                  : _buildSearchSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? JewelryColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: JewelryColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // 搜索框
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A3A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: JewelryColors.textHint,
                    size: 20,
                  ),
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
                      ),
                      style: const TextStyle(fontSize: 14),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        if (value.isEmpty && _showResults) {
                          setState(() => _showResults = false);
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _showResults = false);
                      },
                      child: Icon(
                        Icons.cancel,
                        color: JewelryColors.textHint,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 搜索按钮
          GestureDetector(
            onTap: () => _performSearch(_searchController.text),
            child: Text(
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

  Widget _buildSearchSuggestions() {
    final historyAsync = ref.watch(searchHistoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '搜索历史',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: JewelryColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final storage = StorageService();
                          await storage.clearSearchHistory();
                          ref.invalidate(searchHistoryProvider);
                        },
                        child: Icon(
                          Icons.delete_outline,
                          color: JewelryColors.textHint,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: history.map((keyword) {
                      return _buildTag(keyword, onTap: () {
                        _searchController.text = keyword;
                        _performSearch(keyword);
                      });
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 热门搜索
          const Text(
            '热门搜索',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: JewelryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hotSearches.map((keyword) {
              return _buildTag(
                keyword,
                isHot: true,
                onTap: () {
                  _searchController.text = keyword;
                  _performSearch(keyword);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {bool isHot = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isHot
              ? JewelryColors.primary.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: isHot
              ? Border.all(color: JewelryColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isHot ? JewelryColors.primary : JewelryColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const ProductListSkeleton(itemCount: 4);
    }

    if (_searchResults.isEmpty) {
      return const EmptyStateWidget(type: EmptyType.search);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 结果数量
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '找到 ${_searchResults.length} 件相关商品',
            style: TextStyle(
              fontSize: 13,
              color: JewelryColors.textSecondary,
            ),
          ),
        ),

        // 结果列表
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return _SearchResultCard(product: product);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _SearchResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? JewelryColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 商品图片
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: JewelryColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.diamond_outlined,
              size: 36,
              color: JewelryColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),

          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: JewelryColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['material'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: JewelryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¥${product['price']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: JewelryColors.price,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
