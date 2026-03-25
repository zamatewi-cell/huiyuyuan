import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item_model.dart';
import '../../themes/jewelry_theme.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';
import 'dart:ui';
import 'checkout_screen.dart';

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
                '购物车 (${cartItems.length})',
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
                    child: Text('清空',
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 24),
          Text(
            '购物车是空的',
            style: TextStyle(
              fontSize: 18,
              color: context.adaptiveTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '快去挑选心仪的珠宝吧',
            style: TextStyle(fontSize: 14, color: context.adaptiveTextHint),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('去逛逛',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item, CartNotifier notifier) {
    final product = item.product;
    final name = product.name;
    final price = product.price;
    final quantity = item.quantity;
    final material = product.material;
    final imageUrl =
        product.images.isNotEmpty ? product.images.first : null;

    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => notifier.removeItem(product.id),
      child: PremiumCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.adaptiveTextPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    material,
                    style: TextStyle(
                        fontSize: 12, color: context.adaptiveTextSecondary),
                  ),
                  const SizedBox(height: 12),
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
                                padding: const EdgeInsets.all(6),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
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
                                padding: const EdgeInsets.all(6),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '合计',
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
              const Spacer(),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isProcessingApi
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('去结算',
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

  void _showClearDialog(CartNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空购物车'),
        content: const Text('确定要清空购物车吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _checkout(CartNotifier notifier) {
    final selectedItems = notifier.selectedItems;
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择要结算的商品')),
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
