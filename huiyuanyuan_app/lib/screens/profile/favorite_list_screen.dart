/// 汇玉源 - 收藏列表页面
///
/// 功能:
/// - 收藏商品展示
/// - 取消收藏
/// - 加入购物车
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import '../../data/product_data.dart';

/// \u6536\u85CFProvider
final favoritesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final storage = StorageService();
  await storage.init();
  final favoriteIds = await storage.getFavorites();

  // \u4ECE\u771F\u5B9E\u5546\u54C1\u6570\u636E\u4E2D\u67E5\u627E
  return favoriteIds.map((id) => _findProduct(id)).toList();
});

Map<String, dynamic> _findProduct(String id) {
  final match = realProductData.where((p) => p.id == id);
  if (match.isNotEmpty) {
    final p = match.first;
    return {
      'id': p.id,
      'name': p.name,
      'price': p.price,
      'originalPrice': p.originalPrice ?? p.price,
      'material': p.material,
      'image': p.images.isNotEmpty ? p.images.first : null,
    };
  }
  return {
    'id': id,
    'name': '\u672A\u77E5\u5546\u54C1',
    'price': 0,
    'material': '',
    'image': null,
  };
}

class FavoriteListScreen extends ConsumerWidget {
  const FavoriteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: _buildAppBar(context),
      body: favoritesAsync.when(
        data: (favorites) => favorites.isEmpty
            ? EmptyStateWidget(
                type: EmptyType.favorite,
                onAction: () => Navigator.pop(context),
              )
            : _buildFavoriteList(context, ref, favorites),
        loading: () => _buildLoadingState(),
        error: (_, __) => const ErrorStateWidget(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.primary.withOpacity(0.9),
                  JewelryColors.primaryDark.withOpacity(0.9),
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '我的收藏',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => const ListItemSkeleton(),
    );
  }

  Widget _buildFavoriteList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> favorites,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _FavoriteCard(product: favorites[index]);
      },
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _FavoriteCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? JewelryColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 商品图片 — 优先使用真实图片
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: JewelryColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: product['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.diamond_outlined,
                          size: 40,
                          color: JewelryColors.primary.withOpacity(0.5),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.diamond_outlined,
                      size: 40,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? JewelryColors.darkTextPrimary
                          : JewelryColors.textPrimary,
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
                  Row(
                    children: [
                      Text(
                        '¥${product['price']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: JewelryColors.price,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product['originalPrice'] != null)
                        Text(
                          '¥${product['originalPrice']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: JewelryColors.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 操作按钮
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.red.shade400,
                  ),
                  onPressed: () async {
                    final storage = StorageService();
                    await storage.toggleFavorite(product['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已取消收藏')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: JewelryColors.primary,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已加入购物车')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
