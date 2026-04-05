import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../models/address_model.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../services/address_service.dart';
import '../../services/order_service.dart';
import '../../providers/cart_provider.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/common/error_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/address_list_screen.dart';
import '../payment/payment_screen.dart';

/// 确认订单 (结算) 页面
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

  void _processPayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.tr('checkout_select_address_first'))),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      // 通过 OrderNotifier 创建订单
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
        productImage: widget.items.first.product.images.isNotEmpty
            ? widget.items.first.product.images.first
            : '',
        paymentMethod: paymentMethod,
        recipientName: _selectedAddress!.recipientName,
        recipientPhone: _selectedAddress!.phoneNumber,
        shippingAddress: _selectedAddress!.fullAddress,
      );

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      if (order != null) {
        // 从购物车移除已结算的商品
        final cartNotifier = ref.read(cartProvider.notifier);
        for (final item in widget.items) {
          cartNotifier.removeItem(item.product.id);
        }

        // 跳转到独立支付页面
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
      backgroundColor: context.adaptiveBackground,
      appBar: AppBar(
        title: Text(ref.tr('checkout_title'),
            style: TextStyle(
                color: context.adaptiveTextPrimary,
                fontWeight: FontWeight.bold)),
        backgroundColor: context.adaptiveSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.adaptiveTextPrimary),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: 120), // 为底部悬浮栏留出空间
            children: [
              _buildAddressSection(),
              _buildProductsSection(),
              _buildPaymentMethodSection(),
              _buildSummarySection(),
            ],
          ),

          // 底部悬浮结算栏
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
    return PremiumCard(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      borderRadius: 20,
      backgroundColor: context.adaptiveSurface,
      onTap: _selectAddress,
      child: _isLoadingAddress
          ? Center(child: CircularProgressIndicator())
          : _selectedAddress == null
              ? Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: JewelryColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_location_alt,
                          color: JewelryColors.primary),
                    ),
                    SizedBox(width: 16),
                    Text(
                      ref.tr('checkout_choose_address'),
                      style: TextStyle(
                          fontSize: 16,
                          color: context.adaptiveTextPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: JewelryColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.location_on, color: JewelryColors.primary),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedAddress!.recipientName,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.adaptiveTextPrimary),
                              ),
                              SizedBox(width: 12),
                              Text(
                                _selectedAddress!.maskedPhone,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: context.adaptiveTextSecondary),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            _selectedAddress!.fullAddress,
                            style: TextStyle(
                                fontSize: 14,
                                color: context.adaptiveTextSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
    );
  }

  Widget _buildProductsSection() {
    return PremiumCard(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      borderRadius: 20,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('checkout_product_details'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.adaptiveTextPrimary)),
          SizedBox(height: 16),
          ...widget.items.map((item) {
            final product = item.product;
            final quantity = item.quantity;

            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                            color: Colors.grey[200],
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.titleL10n,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.adaptiveTextPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${ref.tr('product_material')}: ${product.matL10n}',
                          style: TextStyle(
                              fontSize: 12,
                              color: context.adaptiveTextSecondary),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '¥${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE53935)),
                            ),
                            Text(
                              'x$quantity',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: context.adaptiveTextSecondary),
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
    return PremiumCard(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      borderRadius: 20,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('payment_method_title'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.adaptiveTextPrimary)),
          SizedBox(height: 16),
          _buildPaymentOption('wechat', ref.tr('payment_method_wechat'),
              Icons.wechat, Color(0xFF07C160)),
          Divider(height: 24),
          _buildPaymentOption('alipay', ref.tr('payment_method_alipay'),
              Icons.qr_code, Color(0xFF1677FF)),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      String value, String title, IconData icon, Color color) {
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(width: 12),
          Text(title,
              style:
                  TextStyle(fontSize: 15, color: context.adaptiveTextPrimary)),
          Spacer(),
          Radio<String>(
            value: value,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
            activeColor: JewelryColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return PremiumCard(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      borderRadius: 20,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        children: [
          _buildSummaryRow(ref.tr('checkout_item_total'),
              '¥${_totalAmount.toStringAsFixed(2)}'),
          SizedBox(height: 12),
          _buildSummaryRow(ref.tr('order_shipping_fee'), '¥0.00'),
          SizedBox(height: 12),
          _buildSummaryRow(ref.tr('order_discount'), '-¥0.00'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 14, color: context.adaptiveTextSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                color: context.adaptiveTextPrimary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: context.adaptiveSurface.withOpacity(0.85),
            border:
                Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ref.tr('cart_total'),
                        style: TextStyle(
                            fontSize: 12,
                            color: context.adaptiveTextSecondary)),
                    Text(
                      '¥${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  shadowColor: JewelryColors.primary.withOpacity(0.4),
                ),
                child: _isProcessingPayment
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(ref.tr('checkout_submit_payment'),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
