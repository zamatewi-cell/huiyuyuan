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
import '../../providers/app_settings_provider.dart';
import 'dart:ui';
import '../../models/product_model.dart';
import '../../themes/colors.dart';
import '../../services/user_data_service.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/error_handler.dart';

class _FavoriteListBackdrop extends StatelessWidget {
  const _FavoriteListBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          const BoxDecoration(gradient: JewelryColors.jadeDepthGradient),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _FavoriteListGlowOrb(
              size: 320,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            bottom: 120,
            child: _FavoriteListGlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteListGlowOrb extends StatelessWidget {
  const _FavoriteListGlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 96, spreadRadius: 28),
        ],
      ),
    );
  }
}

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
      backgroundColor: JewelryColors.jadeBlack,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          const Positioned.fill(child: _FavoriteListBackdrop()),
          favoritesAsync.when(
            data: (favorites) => favorites.isEmpty
                ? _buildEmptyState()
                : _buildFavoriteList(context, favorites),
            loading: () => _buildLoadingState(),
            error: (error, _) => _buildErrorState(error),
          ),
        ],
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
            color: JewelryColors.jadeBlack.withOpacity(0.84),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: JewelryColors.jadeMist,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: JewelryColors.deepJade.withOpacity(0.62),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.14),
                          ),
                        ),
                        child: Text(
                          ref.tr('profile_favorites'),
                          style: const TextStyle(
                            color: JewelryColors.jadeMist,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: JewelryColors.jadeMist,
                    ),
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

  Widget _buildEmptyState() {
    return Center(
      child: GlassmorphicCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        borderRadius: 26,
        blur: 16,
        opacity: 0.18,
        borderColor: JewelryColors.champagneGold.withOpacity(0.14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: JewelryColors.jadeMist.withOpacity(0.34),
            ),
            const SizedBox(height: 16),
            Text(
              ref.tr('favorite_empty_title'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ref.tr('favorite_empty_subtitle'),
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.58),
                fontSize: 14,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.emeraldLuster,
                foregroundColor: JewelryColors.jadeBlack,
                elevation: 0,
              ),
              child: Text(ref.tr('browse_products')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: GlassmorphicCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        borderRadius: 26,
        blur: 16,
        opacity: 0.18,
        borderColor: JewelryColors.error.withOpacity(0.22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: JewelryColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              ref.tr(
                'favorite_load_failed',
                params: {'error': error.toString()},
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.68),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(favoritesProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.emeraldLuster,
                foregroundColor: JewelryColors.jadeBlack,
                elevation: 0,
              ),
              child: Text(ref.tr('retry')),
            ),
          ],
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
    List<ProductModel> favorites,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
          SnackBar(
            content: Text(ref.tr('product_removed_favorite')),
            backgroundColor: JewelryColors.emeraldShadow,
            behavior: SnackBarBehavior.floating,
          ),
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
    final lang = ref.watch(appSettingsProvider).language;
    final imageUrl = product.images.isEmpty ? null : product.images.first;
    final name = product.localizedTitleFor(lang);
    final material = product.localizedMaterialFor(lang);
    final price = product.price.toStringAsFixed(0);
    final originalPrice = product.originalPrice?.toStringAsFixed(0);
    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      blur: 16,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: JewelryColors.jadeBlack.withOpacity(0.28),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: JewelryColors.champagneGold.withOpacity(0.12),
                ),
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
                          color: JewelryColors.emeraldGlow.withOpacity(0.5),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.diamond_outlined,
                      size: 40,
                      color: JewelryColors.emeraldGlow.withOpacity(0.5),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: JewelryColors.jadeMist,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    material,
                    style: TextStyle(
                      fontSize: 12,
                      color: JewelryColors.jadeMist.withOpacity(0.58),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '¥$price',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: JewelryColors.champagneGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (originalPrice != null)
                        Text(
                          '¥$originalPrice',
                          style: const TextStyle(
                            fontSize: 12,
                            color: JewelryColors.jadeMist,
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
                    color: JewelryColors.error.withOpacity(0.9),
                  ),
                  onPressed: onRemove,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: JewelryColors.emeraldGlow,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ref.tr('product_added_cart')),
                        backgroundColor: JewelryColors.emeraldShadow,
                        behavior: SnackBarBehavior.floating,
                      ),
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
