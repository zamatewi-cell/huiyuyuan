/// 汇玉源 - 收藏列表页面
///
/// 功能:
/// - 收藏商品展示
/// - 取消收藏
/// - 加入购物车
library;

import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../models/product_model.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../services/user_data_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/error_handler.dart';

final _userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

final favoritesProvider = FutureProvider<List<ProductModel>>((ref) async {
  final service = ref.watch(_userDataServiceProvider);
  await service.initialize();
  return await service.getFavorites();
});

class FavoriteListScreen extends ConsumerStatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  ConsumerState<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends ConsumerState<FavoriteListScreen> {
  @override
  Widget build(BuildContext context) {
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
            : _buildFavoriteList(context, favorites),
        loading: () => _buildLoadingState(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: JewelryColors.error),
              SizedBox(height: 16),
              Text(
                ref.tr(
                  'favorite_load_failed',
                  params: {'error': error.toString()},
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(favoritesProvider),
                child: Text(ref.tr('retry')),
              ),
            ],
          ),
        ),
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
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      ref.tr('profile_favorites'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.white),
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
      padding: EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => const ListItemSkeleton(),
    );
  }

  Widget _buildFavoriteList(
    BuildContext context,
    List<ProductModel> favorites,
  ) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _FavoriteCard(
          product: favorites[index],
          onRemove: () => _removeFavorite(favorites[index].id),
        );
      },
    );
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      final service = ref.read(_userDataServiceProvider);
      final success = await service.removeFromFavorites(productId);
      if (success && mounted) {
        ref.invalidate(favoritesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('product_removed_favorite'))),
        );
      } else if (mounted) {
        context.showError(ref.tr('favorite_remove_failed'));
      }
    } catch (e) {
      if (mounted) {
        context.showError(e);
      }
    }
  }
}

class _FavoriteCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.product,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = product.images.isEmpty ? null : product.images.first;
    final name = product.titleL10n;
    final material = product.matL10n;
    final price = product.price.toStringAsFixed(0);
    final originalPrice = product.originalPrice?.toStringAsFixed(0);
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
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: JewelryColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
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
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                  SizedBox(height: 4),
                  Text(
                    material,
                    style: const TextStyle(
                      fontSize: 12,
                      color: JewelryColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '¥$price',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: JewelryColors.price,
                        ),
                      ),
                      SizedBox(width: 8),
                      if (originalPrice != null)
                        Text(
                          '¥$originalPrice',
                          style: const TextStyle(
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
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.red.shade400,
                  ),
                  onPressed: onRemove,
                ),
                IconButton(
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    color: JewelryColors.primary,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ref.tr('product_added_cart'))),
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
