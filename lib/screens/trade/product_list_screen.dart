import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/backend_service.dart';
import '../../data/product_data.dart';
import 'product_detail_screen.dart';
import '../../widgets/product_skeleton.dart';
import '../../widgets/promotional_banner.dart';
import '../../l10n/l10n_provider.dart';
import '../../widgets/animations/custom_shimmer.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../themes/jewelry_theme.dart';
import '../../themes/colors.dart';
import 'dart:ui';
import '../../widgets/common/glassmorphic_card.dart';
import '../product/search_screen.dart';
import '../notification/notification_screen.dart';

/// 产品列表 Provider
final productListProvider =
    StateNotifierProvider<ProductNotifier, List<ProductModel>>((ref) {
  return ProductNotifier();
});

class ProductNotifier extends StateNotifier<List<ProductModel>> {
  final _backend = BackendService();

  ProductNotifier() : super([]) {
    _backend.initialize(); // 初始化后端服务
    _loadProducts();
  }

  Future<void> _loadProducts({String category = '全部'}) async {
    // 优先尝试从后端获取（后端已按分类过滤）
    final products = await _backend.getProducts(category: category);
    if (products.isNotEmpty) {
      state = products;
    } else {
      // 如果后端没数据或连接失败，加载本地兜底数据
      _loadFallbackData();
      // 仅对本地兜底数据做分类过滤
      if (category != '全部' && state.isNotEmpty) {
        state = state.where((p) => p.category == category).toList();
      }
    }
  }

  void _loadFallbackData() {
    // 使用真实商品数据
    state = realProductData;
  }

  void filterByCategory(String? category) {
    _loadProducts(category: category ?? '全部');
  }

  void sortByPrice(bool ascending) {
    state = [...state]..sort((a, b) =>
        ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
  }

  void sortBySales() {
    state = [...state]..sort((a, b) => b.salesCount.compareTo(a.salesCount));
  }
}

/// 产品列表页面
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

// ... (imports moved to top)

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _selectedCategory = '全部';
  // 更新分类列表以匹配后端数据
  final List<String> _categories = [
    '全部',
    '手链',
    '吊坠',
    '戒指',
    '手镯',
    '项链',
    '手串',
    '耳饰'
  ];

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);
    final isLoading = products.isEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. 浮动 App Bar
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
                        MaterialPageRoute(
                            builder: (_) => const SearchScreen()),
                      ),
                  icon: Icon(Icons.search, color: context.adaptiveTextPrimary)),
              IconButton(
                  onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen()),
                      ),
                  icon: Icon(Icons.notifications_none,
                      color: context.adaptiveTextPrimary)),
            ],
          ),

          // 2. 轮播图区域
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
                      Text("💎 ${ref.tr('home_hot')}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${ref.tr('view_all')} >",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // 3. 吸顶分类栏
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyCategoryDelegate(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
                ref.read(productListProvider.notifier).filterByCategory(
                      category == '全部' ? null : category,
                    );
              },
              translate: (key) {
                switch (key) {
                  case '全部':
                    return ref.tr('cat_all');
                  case '手链':
                    return ref.tr('cat_bracelet');
                  case '吊坠':
                    return ref.tr('cat_pendant');
                  case '戒指':
                    return ref.tr('cat_ring');
                  case '手镯':
                    return ref.tr('cat_bangle');
                  case '项链':
                    return ref.tr('cat_necklace');
                  case '手串':
                    return ref.tr('cat_beads');
                  case '耳饰':
                    return ref.tr('cat_earring');
                  default:
                    return key;
                }
              },
              context: context,
            ),
          ),

          // 4. 商品网格
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
                            milliseconds:
                                (index < 6 ? index * 50 : 0)), // 仅首屏错峰
                        child: _buildProductCard(products[index], isDark),
                      ),
                      childCount: products.length,
                    ),
                  ),
          ),

          // 底部留白，防止被 TabBar 遮挡
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, bool isDark) {
    final bool hasImage = product.images.isNotEmpty;
    final String imageUrl = hasImage ? product.images.first : '';

    return PremiumCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      backgroundColor: isDark ? JewelryColors.darkCard : Colors.white,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 产品图片区
          AspectRatio(
            aspectRatio: 1,
            child: Hero(
              tag: 'product_image_${product.id}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: CustomShimmer.adaptive(
                          context,
                          child: Container(color: Colors.white),
                        ),
                      ),
                      errorWidget: (context, url, err) =>
                          _buildPlaceholderIcon(product.material),
                    )
                  else
                    _buildPlaceholderIcon(product.material),

                  // 标签 (Glassmorphism 风格)
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
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: JewelryColors.nanHong.withOpacity(0.85),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 0.5),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_fire_department,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('HOT',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        decoration: TextDecoration.none)),
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

          // 信息区
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
                        product.name,
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
                        product.material,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600]),
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
                          fontFamily: 'Roboto', // 或者选用更优雅的无衬线字体
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
                        child: const Icon(Icons.add_shopping_cart,
                            color: Colors.white, size: 14),
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

  // ... (保留 _buildPlaceholderIcon 和 _getMaterialColor 方法)
  Widget _buildPlaceholderIcon(String material) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.diamond,
          size: 60,
          color: _getMaterialColor(material),
        ),
      ),
    );
  }

  Color _getMaterialColor(String material) {
    switch (material) {
      case '和田玉':
        return const Color(0xFFF5F5DC);
      case '缅甸翡翠':
        return const Color(0xFF32CD32);
      case '南红玛瑙':
        return const Color(0xFFFF6347);
      case '紫水晶':
        return const Color(0xFF9370DB);
      case '红宝石':
        return Colors.red;
      case '蓝宝石':
        return Colors.blue;
      case '黄金':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF2E8B57);
    }
  }
}

/// 吸顶分类标签代理
class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final String Function(String) translate;
  final BuildContext context;

  _StickyCategoryDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.translate,
    required this.context,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                  offset: const Offset(0, 4))
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      translate(category),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : context.adaptiveTextSecondary,
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
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant _StickyCategoryDelegate oldDelegate) {
    return selectedCategory != oldDelegate.selectedCategory;
  }
}
