import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item_model.dart';
import '../../l10n/product_translator.dart';
import '../../themes/jewelry_theme.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';
import 'dart:ui';
import 'checkout_screen.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

// 向后兼容：旧代码如果 import cart_screen.dart 获取 cartProvider 仍然可用
export '../../providers/cart_provider.dart' show cartProvider;

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
      backgroundColor: context.adaptiveBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: context.adaptiveSurface.withOpacity(0.85),
              elevation: 0,
              centerTitle: true,
              title: Text(
                '${ref.tr('cart_title')} (${cartItems.length})',
                style: TextStyle(
                  color: context.adaptiveTextPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                if (cartItems.isNotEmpty)
                  TextButton(
                    onPressed: () => _showClearDialog(cartNotifier),
                    child: Text('cart_clear'.tr,
                        style: TextStyle(color: context.adaptiveTextSecondary)),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(cartItems[index], cartNotifier);
                    },
                  ),
                ),
                _buildBottomBar(cartNotifier),
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
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: JewelryColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: JewelryColors.primary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            ref.tr('cart_empty'),
            style: TextStyle(
              fontSize: 18,
              color: context.adaptiveTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            ref.tr('cart_empty_subtitle'),
            style: TextStyle(fontSize: 14, color: context.adaptiveTextHint),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(ref.tr('browse_products'),
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item, CartNotifier notifier) {
    final product = item.product;
    final name = product.titleL10n;
    final price = product.price;
    final quantity = item.quantity;
    final material = product.matL10n;
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => notifier.removeItem(product.id),
      child: PremiumCard(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        borderRadius: 20,
        backgroundColor: context.adaptiveSurface,
        child: Row(
          children: [
            // 商品图片
            Container(
              width: 88,
              height: 88,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: JewelryColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: imageUrl != null && imageUrl.startsWith("http")
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.diamond_outlined,
                      size: 40,
                      color: _getMaterialColor(material).withOpacity(0.5),
                    ),
            ),
            SizedBox(width: 16),
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.adaptiveTextPrimary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    material,
                    style: TextStyle(
                        fontSize: 12, color: context.adaptiveTextSecondary),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '¥${price.toInt()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: JewelryColors.price,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      // 数量选择器
                      Container(
                        decoration: BoxDecoration(
                          color: context.adaptiveBackground,
                          borderRadius: BorderRadius.circular(20),
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
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: quantity > 1
                                      ? context.adaptiveTextPrimary
                                      : context.adaptiveTextHint,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$quantity',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: context.adaptiveTextPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => notifier.updateQuantity(
                                  product.id, quantity + 1),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.add,
                                    size: 16,
                                    color: context.adaptiveTextPrimary),
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ref.tr('cart_total'),
                    style: TextStyle(
                        fontSize: 12, color: context.adaptiveTextSecondary),
                  ),
                  Text(
                    '¥${notifier.totalAmount.toInt()}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: JewelryColors.price,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              Spacer(),
              // 结算按钮
              Container(
                width: 140,
                decoration: BoxDecoration(
                  gradient: JewelryColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: JewelryShadows.light,
                ),
                child: ElevatedButton(
                  onPressed:
                      _isProcessingApi ? null : () => _checkout(notifier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isProcessingApi
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(ref.tr('cart_checkout'),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
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
      return Color(0xFFF5F5DC);
    } else if (canonicalMaterial == '缅甸翡翠') {
      return Color(0xFF32CD32);
    } else if (canonicalMaterial == '南红玛瑙') {
      return Color(0xFFFF6347);
    } else if (canonicalMaterial == '紫水晶') {
      return Color(0xFF9370DB);
    } else if (canonicalMaterial == '红宝石') {
      return Colors.red;
    } else if (canonicalMaterial == '蓝宝石') {
      return Colors.blue;
    } else if (canonicalMaterial == '黄金') {
      return Color(0xFFFFD700);
    } else {
      return Color(0xFF2E8B57);
    }
  }

  void _showClearDialog(CartNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cart_clear_title'.tr),
        content: Text('cart_clear_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('cancel')),
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
        SnackBar(content: Text('cart_select_checkout_items'.tr)),
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
