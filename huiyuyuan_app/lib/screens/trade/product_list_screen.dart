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
  static const int _productGridColumns = 2;
  static const double _productGridSpacing = 12;
  static const double _productGridContentHeight = 138;

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
    final unreadCount = ref.watch(notificationUnreadCountProvider);

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      body: Stack(
        children: [
          const _CurationBackdrop(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            cacheExtent: 1200,
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                elevation: 0,
                backgroundColor: JewelryColors.deepJade.withOpacity(0.78),
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: JewelryColors.champagneGold.withOpacity(
                              0.08,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('nav_products'),
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      ref.tr('product_list_subtitle'),
                      style: TextStyle(
                        color: JewelryColors.champagneGold.withOpacity(0.62),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    icon: const Icon(
                      Icons.search_rounded,
                      color: JewelryColors.jadeMist,
                    ),
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
                      color: JewelryColors.jadeMist,
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 80),
                      child: _CurationHero(
                        totalCount: productCatalogState.products.length,
                        visibleCount: products.length,
                        hotCount: products.where((product) {
                          return product.isHot;
                        }).length,
                        selectedCategory:
                            _translateCategory(selectedCategory, language),
                        title: ref.tr('product_list_private_room_title'),
                        description: ref.tr('product_list_private_room_desc'),
                        searchHint: ref.tr('product_list_search_hint'),
                        hotPicksLabel: ref.tr('product_list_hot_picks_metric'),
                        catalogLabel: ref.tr('product_list_catalog_metric'),
                        onSearch: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _QuickSelectionRail(
                      products: products.take(3).toList(growable: false),
                      language: language,
                      onCategorySelected: (category) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                    const SizedBox(height: 14),
                    const FadeSlideTransition(
                      delay: Duration(milliseconds: 140),
                      child: PromotionalBanner(),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      eyebrow: ref.tr('product_list_curated_shelf'),
                      title: ref.tr('home_hot'),
                      action: '${ref.tr('view_all')} >',
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
                  language: language,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                sliver: isLoading
                    ? SliverGrid(
                        gridDelegate: _buildProductGridDelegate(context),
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
                            gridDelegate: _buildProductGridDelegate(context),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => FadeSlideTransition(
                                key: ValueKey(products[index].id),
                                delay: Duration(
                                  milliseconds: index < 6 ? index * 50 : 0,
                                ),
                                child: _buildProductCard(
                                    products[index], language),
                              ),
                              childCount: products.length,
                            ),
                          ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: GlassmorphicCard(
        borderRadius: 28,
        blur: 18,
        opacity: 0.16,
        borderColor: JewelryColors.champagneGold.withOpacity(0.16),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: JewelryColors.champagneGold.withOpacity(0.56),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: JewelryColors.jadeMist.withOpacity(0.72),
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
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, AppLanguage lang) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: JewelryColors.liquidGlassGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.13),
          ),
          boxShadow: JewelryShadows.liquidGlass,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
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
                        imageUrl: product.images.isNotEmpty
                            ? product.images.first
                            : null,
                        memCacheWidth: 400,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.04),
                              Colors.transparent,
                              Colors.black.withOpacity(0.28),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            if (product.isHot)
                              _ProductBadge(
                                label: ref.tr('product_badge_hot'),
                                icon: Icons.local_fire_department_rounded,
                                color: JewelryColors.nanHong,
                              ),
                            if (product.isHot && product.isNew)
                              const SizedBox(width: 6),
                            if (product.isNew)
                              _ProductBadge(
                                label: ref.tr('home_new'),
                                icon: Icons.auto_awesome_rounded,
                                color: JewelryColors.champagneGold,
                                darkText: true,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: JewelryColors.deepJade.withOpacity(0.62),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: JewelryColors.champagneGold
                                        .withOpacity(0.95),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: JewelryColors.jadeMist,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
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
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.localizedTitleFor(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.28,
                              color: JewelryColors.jadeMist,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: JewelryColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    JewelryColors.emeraldGlow.withOpacity(0.16),
                              ),
                            ),
                            child: Text(
                              product.localizedMaterialFor(lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: JewelryColors.jadeMist.withOpacity(0.72),
                                fontWeight: FontWeight.w600,
                              ),
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
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: JewelryColors.champagneGold,
                              fontFamily: 'Roboto',
                              height: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: JewelryColors.emeraldLusterGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: JewelryShadows.emeraldHalo,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: JewelryColors.jadeBlack,
                              size: 15,
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
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _buildProductGridDelegate(
    BuildContext context,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth =
        (screenWidth - 24 - _productGridSpacing) / _productGridColumns;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _productGridColumns,
      crossAxisSpacing: _productGridSpacing,
      mainAxisSpacing: _productGridSpacing,
      mainAxisExtent: itemWidth + _productGridContentHeight,
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
}

class _CurationBackdrop extends StatelessWidget {
  const _CurationBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -120,
            child: _GlowOrb(
              size: 320,
              color: JewelryColors.primary.withOpacity(0.22),
            ),
          ),
          Positioned(
            right: -140,
            top: 210,
            child: _GlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.13),
            ),
          ),
          Positioned(
            left: -70,
            bottom: 120,
            child: _GlowOrb(
              size: 240,
              color: JewelryColors.emeraldGlow.withOpacity(0.08),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _CurationGrainPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
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
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

class _CurationGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.7
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 10; i++) {
      final y = size.height * (0.08 + i * 0.105);
      final path = Path()..moveTo(-20, y);
      for (var x = -20.0; x < size.width + 20; x += 34) {
        path.lineTo(
          x,
          y + (i.isEven ? 1 : -1) * ((x / size.width) * 10 - 5),
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurationGrainPainter oldDelegate) => false;
}

class _CurationHero extends StatelessWidget {
  const _CurationHero({
    required this.totalCount,
    required this.visibleCount,
    required this.hotCount,
    required this.selectedCategory,
    required this.title,
    required this.description,
    required this.searchHint,
    required this.hotPicksLabel,
    required this.catalogLabel,
    required this.onSearch,
  });

  final int totalCount;
  final int visibleCount;
  final int hotCount;
  final String selectedCategory;
  final String title;
  final String description;
  final String searchHint;
  final String hotPicksLabel;
  final String catalogLabel;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.11),
              JewelryColors.primary.withOpacity(0.08),
              JewelryColors.champagneGold.withOpacity(0.055),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.16),
          ),
          boxShadow: JewelryShadows.liquidGlass,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -42,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JewelryColors.champagneGold.withOpacity(0.16),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRIVATE JADE DROP',
                            style: TextStyle(
                              color:
                                  JewelryColors.emeraldGlow.withOpacity(0.72),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: const TextStyle(
                              color: JewelryColors.jadeMist,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: JewelryColors.emeraldLusterGradient,
                        boxShadow: JewelryShadows.emeraldHalo,
                      ),
                      child: const Icon(
                        Icons.diamond_outlined,
                        color: JewelryColors.jadeBlack,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.66),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: onSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: JewelryColors.deepJade.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: JewelryColors.champagneGold.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: JewelryColors.emeraldGlow.withOpacity(0.82),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            searchHint,
                            style: TextStyle(
                              color: JewelryColors.jadeMist.withOpacity(0.58),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: JewelryColors.champagneGold.withOpacity(0.72),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CurationMetric(
                        value: '$visibleCount',
                        label: selectedCategory,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CurationMetric(
                        value: '$hotCount',
                        label: hotPicksLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CurationMetric(
                        value: '$totalCount',
                        label: catalogLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurationMetric extends StatelessWidget {
  const _CurationMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: JewelryColors.champagneGold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.52),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.action,
  });

  final String eyebrow;
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: JewelryColors.emeraldGlow.withOpacity(0.56),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            action,
            style: TextStyle(
              fontSize: 12,
              color: JewelryColors.champagneGold.withOpacity(0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSelectionRail extends StatelessWidget {
  const _QuickSelectionRail({
    required this.products,
    required this.language,
    required this.onCategorySelected,
  });

  final List<ProductModel> products;
  final AppLanguage language;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () => onCategorySelected(
              ProductTranslator.canonicalCategory(product.category),
            ),
            child: Container(
              width: 178,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JewelryColors.deepJade.withOpacity(0.62),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: JewelryColors.champagneGold.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.localizedTitleFor(language),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: JewelryColors.jadeMist,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.localizedCategoryFor(language),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: JewelryColors.champagneGold.withOpacity(0.58),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductBadge extends StatelessWidget {
  const _ProductBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.darkText = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final foreground = darkText ? JewelryColors.jadeBlack : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(darkText ? 0.82 : 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
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
    required this.language,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final String Function(String) translate;
  final AppLanguage language;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: JewelryColors.deepJade.withOpacity(0.86),
            border: Border(
              top: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.06),
              ),
              bottom: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.08),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 9),
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
                      gradient: isSelected
                          ? JewelryColors.emeraldLusterGradient
                          : null,
                      color:
                          isSelected ? null : Colors.white.withOpacity(0.055),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? JewelryColors.emeraldGlow.withOpacity(0.22)
                            : Colors.white.withOpacity(0.07),
                      ),
                      boxShadow: isSelected ? JewelryShadows.emeraldHalo : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      translate(category),
                      style: TextStyle(
                        color: isSelected
                            ? JewelryColors.jadeBlack
                            : JewelryColors.jadeMist.withOpacity(0.62),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
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
