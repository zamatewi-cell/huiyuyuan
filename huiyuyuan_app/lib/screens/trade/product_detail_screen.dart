import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/image/product_image_view.dart';
import '../../widgets/product_reviews_widget.dart';
import 'checkout_screen.dart';

/// Product detail screen.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with TickerProviderStateMixin {
  final _storage = StorageService();
  final _aiService = AIService();
  final _pageController = PageController();
  bool _isFavorite = false;
  bool _isGeneratingDesc = false;
  String? _aiDescription;
  int _currentImagePage = 0;
  int _quantity = 1;

  // Entry animations.
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkFavorite();

    // Initialize entry animations.
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start the entry animations after the first frame settles.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  Future<void> _checkFavorite() async {
    final isFav = await _storage.isFavorite(widget.product.id);
    setState(() => _isFavorite = isFav);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(appSettingsProvider).language;
    final localizedTitle = widget.product.localizedTitleFor(currentLanguage);
    final localizedDescription =
        widget.product.localizedDescriptionFor(currentLanguage);
    final localizedMaterial =
        widget.product.localizedMaterialFor(currentLanguage);
    final localizedCategory =
        widget.product.localizedCategoryFor(currentLanguage);
    final localizedOrigin = widget.product.localizedOriginFor(currentLanguage);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: CustomScrollView(
        slivers: [
          // Hero image gallery.
          SliverAppBar(
            expandedHeight: 400, // Taller image for lifestyle
            pinned: true,
            stretch: true,
            backgroundColor: context.adaptiveSurface.withOpacity(0.9),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_image_${widget.product.id}',
                child: widget.product.images.isNotEmpty
                    ? Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: widget.product.images.length,
                            onPageChanged: (index) {
                              setState(() => _currentImagePage = index);
                            },
                            itemBuilder: (context, index) {
                              return ProductImageView(
                                product: widget.product,
                                imageUrl: widget.product.images[index],
                                memCacheWidth: 800,
                              );
                            },
                          ),
                          if (widget.product.images.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.product.images.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: _currentImagePage == index ? 20 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _currentImagePage == index
                                          ? JewelryColors.primary
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : ProductImageView(
                        product: widget.product,
                        memCacheWidth: 800,
                      ),
              ),
            ),
            actions: [
              _buildTopGlassButton(
                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
                onTap: _toggleFavorite,
              ),
              const SizedBox(width: 8),
              _buildTopGlassButton(
                icon: Icons.ios_share,
                color: Colors.white,
                onTap: () => _showShareSheet(),
              ),
              const SizedBox(width: 16),
            ],
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and badges.
                      PremiumCard(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 12),
                        borderRadius: 24,
                        backgroundColor: context.adaptiveSurface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '¥${widget.product.price.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.product.originalPrice != null)
                                  Text(
                                    '¥${widget.product.originalPrice!.toInt()}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        JewelryColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    ref.tr(
                                      'admin_sold_inline',
                                      params: {
                                        'count': widget.product.salesCount
                                            .toString(),
                                      },
                                    ),
                                    style: const TextStyle(
                                      color: JewelryColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              localizedTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (widget.product.isHot)
                                  _buildTag(ref.tr('product_hot'), Colors.red),
                                if (widget.product.isNew)
                                  _buildTag(
                                      ref.tr('product_new'), Colors.orange),
                                _buildTag(localizedCategory, Colors.blue),
                                _buildTag(
                                    localizedMaterial, const Color(0xFF2E8B57)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Product information.
                      PremiumCard(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 12),
                        borderRadius: 24,
                        backgroundColor: context.adaptiveSurface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ref.tr('product_info'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.adaptiveTextPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                                ref.tr('product_origin'),
                                localizedOrigin.isNotEmpty
                                    ? localizedOrigin
                                    : ref.tr('product_unknown')),
                            _buildInfoRow(
                                ref.tr('product_material'), localizedMaterial),
                            _buildInfoRow(
                                ref.tr('product_stock'),
                                ref.tr(
                                  'product_stock_value',
                                  params: {'count': widget.product.stock},
                                )),
                            _buildInfoRow(
                              ref.tr('product_rating'),
                              ref.tr(
                                'product_rating_value',
                                params: {
                                  'score':
                                      widget.product.rating.toStringAsFixed(1),
                                },
                              ),
                            ),
                            if (widget.product.certificate != null)
                              _buildInfoRow(ref.tr('product_cert_no'),
                                  widget.product.certificate!),
                          ],
                        ),
                      ),

                      // Product description.
                      PremiumCard(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 12),
                        borderRadius: 24,
                        backgroundColor: context.adaptiveSurface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ref.tr('product_description'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: context.adaptiveTextPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _isGeneratingDesc
                                      ? null
                                      : _generateAIDescription,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: _isGeneratingDesc
                                          ? null
                                          : JewelryColors.primaryGradient,
                                      color: _isGeneratingDesc
                                          ? Colors.grey[300]
                                          : null,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: _isGeneratingDesc
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: JewelryColors.primary
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isGeneratingDesc)
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        else
                                          const Icon(Icons.auto_awesome,
                                              size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isGeneratingDesc
                                              ? ref.tr('product_ai_generating')
                                              : ref.tr('product_ai_optimize'),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _aiDescription ?? localizedDescription,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Service guarantees.
                      PremiumCard(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        borderRadius: 24,
                        backgroundColor: context.adaptiveSurface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ref.tr('product_service_guarantee'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.adaptiveTextPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildServiceItem(Icons.verified,
                                    ref.tr('product_service_authentic')),
                                _buildServiceItem(Icons.local_shipping,
                                    ref.tr('product_service_shipping')),
                                _buildServiceItem(Icons.refresh,
                                    ref.tr('product_service_return')),
                                _buildServiceItem(Icons.security,
                                    ref.tr('product_service_compensation')),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Review section.
                      PremiumCard(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        margin: const EdgeInsets.only(bottom: 24),
                        borderRadius: 24,
                        backgroundColor: context.adaptiveSurface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                ref.tr('product_reviews'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: context.adaptiveTextPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ProductReviewsWidget(productId: widget.product.id),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 16,
            ),
            decoration: BoxDecoration(
              color: context.adaptiveSurface.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity selector.
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        iconSize: 20,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => _quantity++),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Add to cart.
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                          color: JewelryColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _addToCart,
                    child: Text(ref.tr('product_add_to_cart'),
                        style: const TextStyle(
                            color: JewelryColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                // Buy now.
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: JewelryColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: JewelryShadows.light,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _buyNow,
                      child: Text(ref.tr('product_buy_now'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopGlassButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: JewelryColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: JewelryColors.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
                fontSize: 12,
                color: context.adaptiveTextSecondary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    await _storage.toggleFavorite(widget.product.id);
    // Check mounted after await to avoid using context after disposal.
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite
            ? ref.tr('product_added_favorite')
            : ref.tr('product_removed_favorite')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _generateAIDescription() async {
    final currentLanguage = ref.read(appSettingsProvider).language;
    final localizedTitle = widget.product.localizedTitleFor(currentLanguage);
    final localizedMaterial =
        widget.product.localizedMaterialFor(currentLanguage);
    final localizedOrigin = widget.product.localizedOriginFor(currentLanguage);

    setState(() => _isGeneratingDesc = true);

    final desc = await _aiService.generateProductDescription(
      productName: localizedTitle,
      material: localizedMaterial,
      price: widget.product.price,
      features: ref.tr(
        'product_ai_origin_feature',
        params: {
          'origin': localizedOrigin.isNotEmpty
              ? localizedOrigin
              : ref.tr('product_unknown'),
        },
      ),
    );

    setState(() {
      _isGeneratingDesc = false;
      _aiDescription = desc;
    });
  }

  Future<void> _addToCart() async {
    await ref.read(cartProvider.notifier).addItem(
          widget.product,
          quantity: _quantity,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.tr('product_added_cart')),
          backgroundColor: const Color(0xFF2E8B57),
        ),
      );
    }
  }

  void _buyNow() {
    final cartItem = CartItemModel(
      product: widget.product,
      quantity: _quantity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(items: [cartItem]),
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ref.tr('product_share'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareItem(
                    Icons.chat, ref.tr('share_wechat'), Colors.green),
                _buildShareItem(
                    Icons.group, ref.tr('share_moments'), Colors.green),
                _buildShareItem(Icons.qr_code, ref.tr('share_qq'), Colors.blue),
                _buildShareItem(Icons.link, ref.tr('share_link'), Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.tr('share_success', params: {'label': label}),
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
