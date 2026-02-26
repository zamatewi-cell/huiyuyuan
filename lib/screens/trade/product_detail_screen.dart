import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/storage_service.dart';
import '../../services/ai_service.dart';
import '../../providers/cart_provider.dart';
import '../../themes/jewelry_theme.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/product_reviews_widget.dart';
import 'dart:ui';
import 'checkout_screen.dart';

/// 产品详情页面
class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _storage = StorageService();
  final _aiService = AIService();
  final _pageController = PageController();
  bool _isFavorite = false;
  bool _isGeneratingDesc = false;
  String? _aiDescription;
  int _currentImagePage = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await _storage.isFavorite(widget.product.id);
    setState(() => _isFavorite = isFav);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      body: CustomScrollView(
        slivers: [
          // 顶部图片
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
                              return CachedNetworkImage(
                                imageUrl: widget.product.images[index],
                                fit: BoxFit.cover,
                                memCacheWidth: 800,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[100],
                                  child: Icon(Icons.broken_image,
                                      size: 60, color: Colors.grey[400]),
                                ),
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
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
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
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getMaterialColor(widget.product.material)
                                  .withOpacity(0.3),
                              Colors.white,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.diamond,
                            size: 150,
                            color: _getMaterialColor(widget.product.material),
                          ),
                        ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 价格和标签
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
                                color: JewelryColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '已售 ${widget.product.salesCount}',
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
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (widget.product.isHot)
                              _buildTag('热销', Colors.red),
                            if (widget.product.isNew)
                              _buildTag('新品', Colors.orange),
                            _buildTag(widget.product.category, Colors.blue),
                            _buildTag(widget.product.material,
                                const Color(0xFF2E8B57)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 产品信息
                  PremiumCard(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 12),
                    borderRadius: 24,
                    backgroundColor: context.adaptiveSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '产品信息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.adaptiveTextPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('产地', widget.product.origin ?? '未知'),
                        _buildInfoRow('材质', widget.product.material),
                        _buildInfoRow('库存', '${widget.product.stock} 件'),
                        _buildInfoRow('评分', '${widget.product.rating} 分'),
                        if (widget.product.certificate != null)
                          _buildInfoRow('证书编号', widget.product.certificate!),
                      ],
                    ),
                  ),

                  // 产品描述
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
                              '产品描述',
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
                                      _isGeneratingDesc ? '生成中...' : 'AI优化',
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
                          _aiDescription ?? widget.product.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 服务保障
                  PremiumCard(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    borderRadius: 24,
                    backgroundColor: context.adaptiveSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '服务保障',
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
                            _buildServiceItem(Icons.verified, '正品保证'),
                            _buildServiceItem(Icons.local_shipping, '包邮'),
                            _buildServiceItem(Icons.refresh, '7天无理由'),
                            _buildServiceItem(Icons.security, '假一赔十'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 评价组件
                  PremiumCard(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    margin: const EdgeInsets.only(bottom: 24),
                    borderRadius: 24,
                    backgroundColor: context.adaptiveSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '商品评价',
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
                // 数量选择
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
                // 加入购物车
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side:
                          BorderSide(color: JewelryColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _addToCart,
                    child: Text('加入购物车',
                        style: TextStyle(
                            color: JewelryColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                // 立即购买
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
                      child: const Text('立即购买',
                          style: TextStyle(
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
      case '碧玉':
        return const Color(0xFF228B22);
      case '蜜蜡':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF2E8B57);
    }
  }

  Future<void> _toggleFavorite() async {
    await _storage.toggleFavorite(widget.product.id);
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '已加入收藏' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _generateAIDescription() async {
    setState(() => _isGeneratingDesc = true);

    final desc = await _aiService.generateProductDescription(
      productName: widget.product.name,
      material: widget.product.material,
      price: widget.product.price,
      features: '产地：${widget.product.origin}',
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
        const SnackBar(
          content: Text('已加入购物车'),
          backgroundColor: Color(0xFF2E8B57),
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
            const Text(
              '分享商品',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareItem(Icons.chat, '微信', Colors.green),
                _buildShareItem(Icons.group, '朋友圈', Colors.green),
                _buildShareItem(Icons.qr_code, 'QQ', Colors.blue),
                _buildShareItem(Icons.link, '复制链接', Colors.grey),
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
          SnackBar(content: Text('分享到$label')),
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
