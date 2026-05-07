import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item_model.dart';
import '../../l10n/product_translator.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';
import 'dart:ui';
import 'checkout_screen.dart';

// 向后兼容：旧代码如果 import cart_screen.dart 获取 cartProvider 仍然可用
export '../../providers/cart_provider.dart' show cartProvider;

class _CartBackdrop extends StatelessWidget {
  const _CartBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _CartGlowOrb(
              size: 330,
              color: JewelryColors.emeraldGlow.withOpacity(0.11),
            ),
          ),
          Positioned(
            left: -140,
            bottom: 120,
            child: _CartGlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _CartSilkPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartGlowOrb extends StatelessWidget {
  const _CartGlowOrb({
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
            blurRadius: 100,
            spreadRadius: 34,
          ),
        ],
      ),
    );
  }
}

class _CartSilkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.13 + i * 0.13);
      final path = Path()..moveTo(-24, y);
      path.quadraticBezierTo(
        size.width * 0.5,
        y + (i.isEven ? 28 : -24),
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CartSilkPainter oldDelegate) => false;
}

/// 购物车页面
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final bool _isProcessingApi = false;

  @override
  void initState() {
    super.initState();
    // 刷新购物车
    Future.microtask(() => ref.read(cartProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              backgroundColor: JewelryColors.jadeBlack.withOpacity(0.82),
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: JewelryColors.jadeMist),
              title: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: JewelryColors.deepJade.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: JewelryColors.champagneGold.withOpacity(0.14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: JewelryColors.emeraldLusterGradient,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: JewelryColors.jadeBlack,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ref.tr('cart_title')} (${cartItems.length})',
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (cartItems.isNotEmpty)
                  TextButton(
                    onPressed: () => _showClearDialog(cartNotifier),
                    child: Text(ref.tr('cart_clear'),
                        style: TextStyle(
                          color: JewelryColors.jadeMist.withOpacity(0.62),
                          fontWeight: FontWeight.w700,
                        )),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _CartBackdrop()),
          cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          return _buildCartItem(
                            cartItems[index],
                            cartNotifier,
                          );
                        },
                      ),
                    ),
                    _buildBottomBar(cartNotifier),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: JewelryColors.deepJade.withOpacity(0.68),
              shape: BoxShape.circle,
              border: Border.all(
                color: JewelryColors.champagneGold.withOpacity(0.14),
              ),
              boxShadow: JewelryShadows.liquidGlass,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: JewelryColors.champagneGold.withOpacity(0.62),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            ref.tr('cart_empty'),
            style: const TextStyle(
              fontSize: 18,
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ref.tr('cart_empty_subtitle'),
            style: TextStyle(
              fontSize: 14,
              color: JewelryColors.jadeMist.withOpacity(0.48),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.emeraldLuster,
              foregroundColor: JewelryColors.jadeBlack,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(ref.tr('browse_products'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item, CartNotifier notifier) {
    final lang = ref.watch(appSettingsProvider).language;
    final product = item.product;
    final name = product.localizedTitleFor(lang);
    final price = product.price;
    final quantity = item.quantity;
    final material = product.localizedMaterialFor(lang);
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: JewelryColors.error.withOpacity(0.78),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => notifier.removeItem(product.id),
      child: GlassmorphicCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        borderRadius: 20,
        blur: 18,
        opacity: 0.17,
        borderColor: JewelryColors.champagneGold.withOpacity(0.13),
        child: Row(
          children: [
            // 商品图片
            Container(
              width: 88,
              height: 88,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    JewelryColors.emeraldGlow.withOpacity(0.14),
                    JewelryColors.deepJade.withOpacity(0.82),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: JewelryColors.champagneGold.withOpacity(0.12),
                ),
              ),
              child: imageUrl != null && imageUrl.startsWith("http")
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.diamond_outlined,
                      size: 40,
                      color: _getMaterialColor(material).withOpacity(0.78),
                    ),
            ),
            const SizedBox(width: 16),
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: JewelryColors.jadeMist,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    material,
                    style: TextStyle(
                      fontSize: 12,
                      color: JewelryColors.jadeMist.withOpacity(0.52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '¥${price.toInt()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: JewelryColors.champagneGold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      // 数量选择器
                      Container(
                        decoration: BoxDecoration(
                          color: JewelryColors.jadeBlack.withOpacity(0.38),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: quantity > 1
                                  ? () => notifier.updateQuantity(
                                      product.id, quantity - 1)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: quantity > 1
                                      ? JewelryColors.jadeMist
                                      : JewelryColors.jadeMist
                                          .withOpacity(0.28),
                                ),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: JewelryColors.jadeMist,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => notifier.updateQuantity(
                                  product.id, quantity + 1),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.add,
                                    size: 16, color: JewelryColors.jadeMist),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildBottomBar(CartNotifier notifier) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
            gradient: LinearGradient(
              colors: [
                JewelryColors.deepJade.withOpacity(0.9),
                JewelryColors.jadeBlack.withOpacity(0.96),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              top: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: JewelryColors.jadeBlack.withOpacity(0.34),
                blurRadius: 26,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ref.tr('cart_total'),
                    style: TextStyle(
                      fontSize: 12,
                      color: JewelryColors.jadeMist.withOpacity(0.58),
                    ),
                  ),
                  Text(
                    '¥${notifier.totalAmount.toInt()}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: JewelryColors.champagneGold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 结算按钮
              Container(
                width: 140,
                decoration: BoxDecoration(
                  gradient: JewelryColors.emeraldLusterGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: JewelryShadows.emeraldHalo,
                ),
                child: ElevatedButton(
                  onPressed:
                      _isProcessingApi ? null : () => _checkout(notifier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessingApi
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: JewelryColors.jadeBlack))
                      : Text(ref.tr('cart_checkout'),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: JewelryColors.jadeBlack)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMaterialColor(String material) {
    final canonicalMaterial = ProductTranslator.canonicalMaterial(material);
    if (canonicalMaterial == '和田玉') {
      return const Color(0xFFF5F5DC);
    } else if (canonicalMaterial == '缅甸翡翠') {
      return const Color(0xFF32CD32);
    } else if (canonicalMaterial == '南红玛瑙') {
      return const Color(0xFFFF6347);
    } else if (canonicalMaterial == '紫水晶') {
      return const Color(0xFF9370DB);
    } else if (canonicalMaterial == '红宝石') {
      return Colors.red;
    } else if (canonicalMaterial == '蓝宝石') {
      return Colors.blue;
    } else if (canonicalMaterial == '黄金') {
      return const Color(0xFFFFD700);
    } else {
      return const Color(0xFF2E8B57);
    }
  }

  void _showClearDialog(CartNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(ref.tr('cart_clear_title')),
        titleTextStyle: const TextStyle(
          color: JewelryColors.jadeMist,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        content: Text(
          ref.tr('cart_clear_confirm'),
          style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.68)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              ref.tr('cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.56)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(ref.tr('confirm')),
          ),
        ],
      ),
    );
  }

  void _checkout(CartNotifier notifier) {
    final selectedItems = notifier.selectedItems;
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.tr('cart_select_checkout_items'))),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(items: selectedItems),
      ),
    );
  }
}
