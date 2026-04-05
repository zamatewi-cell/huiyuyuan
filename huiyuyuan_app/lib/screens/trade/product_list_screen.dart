import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../l10n/product_translator.dart';
import '../../models/user_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_catalog_provider.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/common/notification_badge_icon.dart';
import '../../widgets/image/product_image_view.dart';
import '../../widgets/product_skeleton.dart';
import '../../widgets/promotional_banner.dart';
import '../notification/notification_screen.dart';
import '../product/search_screen.dart';
import 'product_detail_screen.dart';

bool _isAllCategory(String category) {
  return category == productCatalogAllCategory;
}

List<ProductModel> _filterProductsByCategory(
  List<ProductModel> products,
  String category,
) {
  if (_isAllCategory(category)) {
    return products;
  }

  return products.where((product) {
    return ProductTranslator.canonicalCategory(product.category) == category;
  }).toList(
    growable: false,
  );
}

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _selectedCategory = productCatalogAllCategory;

  @override
  Widget build(BuildContext context) {
    final productCatalogState = ref.watch(productCatalogProvider);
    final categories = ref.watch(productCatalogCategoriesProvider);
    final language = ref.watch(appSettingsProvider).language;
    final selectedCategory = categories.contains(_selectedCategory)
        ? _selectedCategory
        : productCatalogAllCategory;
    final products = _filterProductsByCategory(
      productCatalogState.products,
      selectedCategory,
    );
    final isLoading = productCatalogState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = ref.watch(notificationUnreadCountProvider);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            elevation: 0,
            backgroundColor: context.adaptiveSurface.withOpacity(0.9),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: Text(
              ref.tr('nav_products'),
              style: TextStyle(
                color: context.adaptiveTextPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                icon: Icon(Icons.search, color: context.adaptiveTextPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                ),
                icon: NotificationBadgeIcon(
                  icon: Icons.notifications_none,
                  count: unreadCount,
                  color: context.adaptiveTextPrimary,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FadeSlideTransition(
                  delay: Duration(milliseconds: 100),
                  child: PromotionalBanner(),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: JewelryColors.nanHong,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ref.tr('home_hot'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${ref.tr('view_all')} >',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyCategoryDelegate(
              categories: categories,
              selectedCategory: selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
              translate: (key) => _translateCategory(key, language),
              context: context,
              language: language,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: isLoading
                ? SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ProductSkeleton(),
                      childCount: 6,
                    ),
                  )
                : products.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyState(
                          message: productCatalogState.errorMessage ??
                              ref.tr('shop_empty_title'),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => FadeSlideTransition(
                            key: ValueKey(products[index].id),
                            delay: Duration(
                              milliseconds: index < 6 ? index * 50 : 0,
                            ),
                            child: _buildProductCard(products[index], isDark),
                          ),
                          childCount: products.length,
                        ),
                      ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  String _translateCategory(String key, AppLanguage language) {
    if (_isAllCategory(key)) {
      return ref.tr('cat_all');
    }
    final translated = ProductTranslator.translateCategory(
      language,
      key,
      allowExact: false,
    ).trim();
    return translated.isNotEmpty ? translated : key;
  }

  Widget _buildEmptyState({required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: context.adaptiveTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () =>
                ref.read(productCatalogProvider.notifier).refresh(),
            child: Text(ref.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, bool isDark) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      backgroundColor: isDark ? JewelryColors.darkCard : Colors.white,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Hero(
              tag: 'product_image_${product.id}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImageView(
                    product: product,
                    imageUrl:
                        product.images.isNotEmpty ? product.images.first : null,
                    memCacheWidth: 400,
                  ),
                  if (product.isHot)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: JewelryColors.nanHong.withOpacity(0.85),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 0.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ref.tr('product_badge_hot'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.titleL10n,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.matL10n,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${product.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: JewelryColors.price,
                          fontFamily: 'Roboto',
                          height: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: JewelryColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: JewelryShadows.light,
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  const _StickyCategoryDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.translate,
    required this.context,
    required this.language,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final String Function(String) translate;
  final BuildContext context;
  final AppLanguage language;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: isDark ? JewelryColors.darkCard : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onCategorySelected(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected ? JewelryColors.primaryGradient : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : JewelryColors.background),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: JewelryColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      translate(category),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : this.context.adaptiveTextSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _StickyCategoryDelegate oldDelegate) {
    return selectedCategory != oldDelegate.selectedCategory ||
        language != oldDelegate.language ||
        !listEquals(categories, oldDelegate.categories);
  }
}
