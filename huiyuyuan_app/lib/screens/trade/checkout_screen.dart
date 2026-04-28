import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/address_model.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/address_service.dart';
import '../../services/order_service.dart';
import '../../themes/colors.dart';
import '../../widgets/common/error_handler.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../payment/payment_screen.dart';
import '../profile/address_list_screen.dart';
import 'dart:ui';

class _CheckoutBackdrop extends StatelessWidget {
  const _CheckoutBackdrop();

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
            child: _CheckoutGlowOrb(
              size: 340,
              color: JewelryColors.emeraldGlow.withOpacity(0.11),
            ),
          ),
          Positioned(
            left: -130,
            top: 280,
            child: _CheckoutGlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _CheckoutTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutGlowOrb extends StatelessWidget {
  const _CheckoutGlowOrb({
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
            spreadRadius: 32,
          ),
        ],
      ),
    );
  }
}

class _CheckoutTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.1 + i * 0.12);
      final path = Path()..moveTo(-20, y);
      path.cubicTo(
        size.width * 0.22,
        y + (i.isEven ? 20 : -20),
        size.width * 0.72,
        y + (i.isEven ? -20 : 20),
        size.width + 20,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckoutTracePainter oldDelegate) => false;
}

/// 纭璁㈠崟 (缁撶畻) 椤甸潰
class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItemModel> items;

  const CheckoutScreen({super.key, required this.items});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final AddressService _addressService = AddressService();
  AddressModel? _selectedAddress;
  bool _isLoadingAddress = true;
  bool _isProcessingPayment = false;
  String _paymentMethod = 'wechat';

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    await _addressService.init();
    final defaultAddr = await _addressService.getDefaultAddress();
    if (mounted) {
      setState(() {
        _selectedAddress = defaultAddr;
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressListScreen(isSelectMode: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  double get _totalAmount {
    return widget.items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  String _formatCurrency(double amount) => '¥${amount.toStringAsFixed(2)}';

  void _processPayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.tr('checkout_select_address_first'))),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      // 閫氳繃 OrderNotifier 鍒涘缓璁㈠崟
      final orderNotifier = ref.read(orderProvider.notifier);
      final paymentMethod = _paymentMethod == 'wechat'
          ? PaymentMethod.wechat
          : PaymentMethod.alipay;

      final order = await orderNotifier.createOrder(
        productName: widget.items.length == 1
            ? widget.items.first.product.titleL10n
            : ref.tr(
                'checkout_bundle_product_name',
                params: {
                  'title': widget.items.first.product.titleL10n,
                  'count': widget.items.length.toString(),
                },
              ),
        amount: _totalAmount,
        quantity: widget.items.fold(0, (sum, item) => sum + item.quantity),
        productId:
            widget.items.length == 1 ? widget.items.first.product.id : null,
        productImage: widget.items.first.product.images.isNotEmpty
            ? widget.items.first.product.images.first
            : '',
        paymentMethod: paymentMethod,
        addressId: _selectedAddress!.id,
        recipientName: _selectedAddress!.recipientName,
        recipientPhone: _selectedAddress!.phoneNumber,
        shippingAddress: _selectedAddress!.fullAddress,
      );

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      if (order != null) {
        // 浠庤喘鐗╄溅绉婚櫎宸茬粨绠楃殑鍟嗗搧
        final cartNotifier = ref.read(cartProvider.notifier);
        for (final item in widget.items) {
          cartNotifier.removeItem(item.product.id);
        }

        // 璺宠浆鍒扮嫭绔嬫敮浠橀〉闈?
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(order: order),
          ),
        );
      } else {
        context.showError(ref.tr('checkout_create_order_failed'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        context.showError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: JewelryColors.deepJade.withOpacity(0.62),
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
                  Icons.verified_outlined,
                  color: JewelryColors.jadeBlack,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ref.tr('checkout_title'),
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.82),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: JewelryColors.jadeMist),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _CheckoutBackdrop()),
          ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              _buildAddressSection(),
              _buildProductsSection(),
              _buildPaymentMethodSection(),
              _buildSummarySection(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return GlassmorphicCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 18,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.13),
      onTap: _selectAddress,
      child: _isLoadingAddress
          ? const Center(
              child: CircularProgressIndicator(
                color: JewelryColors.emeraldGlow,
              ),
            )
          : _selectedAddress == null
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: JewelryColors.emeraldGlow.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: JewelryColors.emeraldGlow.withOpacity(0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_location_alt,
                        color: JewelryColors.emeraldGlow,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      ref.tr('checkout_choose_address'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: JewelryColors.jadeMist,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: JewelryColors.jadeMist.withOpacity(0.34),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: JewelryColors.emeraldGlow.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: JewelryColors.emeraldGlow.withOpacity(0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: JewelryColors.emeraldGlow,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedAddress!.recipientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: JewelryColors.jadeMist,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedAddress!.maskedPhone,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      JewelryColors.jadeMist.withOpacity(0.58),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedAddress!.fullAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: JewelryColors.jadeMist.withOpacity(0.54),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: JewelryColors.jadeMist.withOpacity(0.34),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProductsSection() {
    return GlassmorphicCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 18,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.tr('checkout_product_details'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: JewelryColors.jadeMist,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.items.map((item) {
            final product = item.product;
            final quantity = item.quantity;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.images.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: JewelryColors.emeraldLusterGradient,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.diamond,
                              color: JewelryColors.jadeBlack,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.titleL10n,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: JewelryColors.jadeMist,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${ref.tr('product_material')}: ${product.matL10n}',
                          style: TextStyle(
                            fontSize: 12,
                            color: JewelryColors.jadeMist.withOpacity(0.52),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatCurrency(product.price),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: JewelryColors.champagneGold,
                              ),
                            ),
                            Text(
                              'x$quantity',
                              style: TextStyle(
                                fontSize: 14,
                                color: JewelryColors.jadeMist.withOpacity(0.52),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return GlassmorphicCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 18,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.tr('payment_method_title'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: JewelryColors.jadeMist,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption(
            'wechat',
            ref.tr('payment_method_wechat'),
            Icons.wechat,
            const Color(0xFF07C160),
          ),
          Divider(
            height: 24,
            color: JewelryColors.champagneGold.withOpacity(0.1),
          ),
          _buildPaymentOption(
            'alipay',
            ref.tr('payment_method_alipay'),
            Icons.qr_code,
            const Color(0xFF1677FF),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    Color color,
  ) {
    final selected = _paymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? JewelryColors.emeraldGlow.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? JewelryColors.emeraldGlow.withOpacity(0.18)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: JewelryColors.jadeMist,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
              activeColor: JewelryColors.emeraldGlow,
              fillColor:
                  WidgetStateProperty.all<Color>(JewelryColors.emeraldGlow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return GlassmorphicCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 18,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.13),
      child: Column(
        children: [
          _buildSummaryRow(
            ref.tr('checkout_item_total'),
            _formatCurrency(_totalAmount),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(ref.tr('order_shipping_fee'), _formatCurrency(0)),
          const SizedBox(height: 12),
          _buildSummaryRow(
            ref.tr('order_discount'),
            '-${_formatCurrency(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: JewelryColors.jadeMist.withOpacity(0.56),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
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
                      _formatCurrency(_totalAmount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: JewelryColors.champagneGold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.emeraldLuster,
                  foregroundColor: JewelryColors.jadeBlack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  elevation: 4,
                  shadowColor: JewelryColors.emeraldGlow.withOpacity(0.35),
                ),
                child: _isProcessingPayment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: JewelryColors.jadeBlack,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        ref.tr('checkout_submit_payment'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: JewelryColors.jadeBlack,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
