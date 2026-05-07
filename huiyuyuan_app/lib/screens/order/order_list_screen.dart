/// HuiYuYuan order list screen.
///
/// Features:
/// - grouped order states
/// - order detail entry
/// - order actions such as cancel and confirm receipt
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../themes/colors.dart';
import '../../models/order_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/common/empty_state.dart';
import 'order_detail_screen.dart';
import 'publish_review_screen.dart';
import '../payment/payment_screen.dart';
import 'shipping_dialog.dart';
import 'logistics_screen.dart';

class _OrderTabItem {
  final String labelKey;
  final OrderStatus? status;

  const _OrderTabItem({required this.labelKey, this.status});
}

class _OrderBackdrop extends StatelessWidget {
  const _OrderBackdrop();

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
            right: -140,
            child: _OrderGlowOrb(
              size: 340,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -120,
            bottom: 120,
            child: _OrderGlowOrb(
              size: 260,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _OrderTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderGlowOrb extends StatelessWidget {
  const _OrderGlowOrb({
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

class _OrderTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 8; i++) {
      final path = Path();
      final y = size.height * (0.1 + i * 0.12);
      path.moveTo(-20, y);
      path.cubicTo(
        size.width * 0.22,
        y - 22,
        size.width * 0.72,
        y + 22,
        size.width + 20,
        y - 6,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrderTracePainter oldDelegate) => false;
}

BoxDecoration _orderGlassDecoration({
  double radius = 24,
  double borderOpacity = 0.13,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        JewelryColors.deepJade.withOpacity(0.78),
        JewelryColors.jadeSurface.withOpacity(0.52),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: JewelryColors.champagneGold.withOpacity(borderOpacity),
    ),
    boxShadow: JewelryShadows.liquidGlass,
  );
}

class OrderListScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const OrderListScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Timer? _loadTimer;

  static const List<_OrderTabItem> _tabs = [
    _OrderTabItem(labelKey: 'order_all'),
    _OrderTabItem(
      labelKey: 'order_pending_payment',
      status: OrderStatus.pending,
    ),
    _OrderTabItem(
      labelKey: 'order_pending_shipment',
      status: OrderStatus.paid,
    ),
    _OrderTabItem(
      labelKey: 'order_pending_receipt',
      status: OrderStatus.shipped,
    ),
    _OrderTabItem(
      labelKey: 'order_completed',
      status: OrderStatus.completed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadData();
  }

  void _loadData() {
    _loadTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const Positioned.fill(child: _OrderBackdrop()),
          _isLoading
              ? _buildLoadingState()
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    return _OrderTabContent(status: tab.status);
                  }).toList(),
                ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isAdmin = ref.watch(isAdminProvider);
    return PreferredSize(
      preferredSize: const Size.fromHeight(128),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.jadeBlack.withOpacity(0.96),
                  JewelryColors.deepJade.withOpacity(0.9),
                  JewelryColors.jadeSurface.withOpacity(0.68),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.12),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App bar.
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: JewelryColors.jadeMist,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: JewelryColors.emeraldLusterGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: JewelryShadows.emeraldHalo,
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: JewelryColors.jadeBlack,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isAdmin
                                    ? ref.tr('admin_orders')
                                    : ref.tr('order_list_title'),
                                style: const TextStyle(
                                  color: JewelryColors.jadeMist,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: JewelryColors.jadeBlack.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: JewelryColors.champagneGold.withOpacity(0.1),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: JewelryColors.champagneGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.18),
                          ),
                        ),
                        labelColor: JewelryColors.jadeMist,
                        unselectedLabelColor:
                            JewelryColors.jadeMist.withOpacity(0.52),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tabs: _tabs
                            .map(
                              (tab) => Tab(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Text(ref.tr(tab.labelKey)),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: 164,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: _orderGlassDecoration(),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: JewelryColors.jadeMist.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: JewelryColors.jadeMist.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: JewelryColors.jadeMist.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 28,
                    width: 96,
                    decoration: BoxDecoration(
                      color: JewelryColors.champagneGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Order tab content.
class _OrderTabContent extends ConsumerWidget {
  final OrderStatus? status;

  const _OrderTabContent({this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrders = ref.watch(orderProvider);
    final orders = status == null
        ? allOrders
        : allOrders.where((o) => o.status == status).toList();

    if (orders.isEmpty) {
      return EmptyStateWidget(
        type: EmptyType.order,
        onAction: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(orderProvider.notifier).refresh();
      },
      color: JewelryColors.emeraldGlow,
      backgroundColor: JewelryColors.deepJade,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: orders.length,
        itemBuilder: (context, index) => _OrderCard(order: orders[index]),
      ),
    );
  }
}

/// Order card.
class _OrderCard extends ConsumerWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appSettingsProvider).language;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: _orderGlassDecoration(radius: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Order header.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: JewelryColors.jadeBlack.withOpacity(0.24),
                  border: Border(
                    bottom: BorderSide(
                      color: JewelryColors.champagneGold.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${ref.tr('order_number')}: ${order.id}',
                        style: TextStyle(
                          fontSize: 13,
                          color: JewelryColors.jadeMist.withOpacity(0.58),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: order.status.color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: order.status.color.withOpacity(0.24),
                        ),
                      ),
                      child: Text(
                        order.status.localizedLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: order.status.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product summary.
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image.
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            JewelryColors.emeraldGlow.withOpacity(0.16),
                            JewelryColors.deepJade.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: JewelryColors.champagneGold.withOpacity(0.12),
                        ),
                      ),
                      child: order.productImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                order.productImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.diamond_outlined,
                                  size: 40,
                                  color: JewelryColors.emeraldGlow
                                      .withOpacity(0.7),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.diamond_outlined,
                              size: 40,
                              color: JewelryColors.emeraldGlow.withOpacity(0.7),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Product details.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.localizedProductNameFor(language),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: JewelryColors.jadeMist,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ref.tr('common_quantity')}: x${order.quantity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: JewelryColors.jadeMist.withOpacity(0.55),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '¥${order.totalPaid.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: JewelryColors.champagneGold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _formatLocalizedDate(
                                      context, order.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: JewelryColors.jadeMist
                                        .withOpacity(0.38),
                                  ),
                                  overflow: TextOverflow.ellipsis,
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

              // Action buttons.
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionButtons(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];
    final isAdmin = ref.watch(isAdminProvider);

    switch (order.status) {
      case OrderStatus.pending:
        if (isAdmin) {
          if (order.paymentId != null && order.paymentId!.isNotEmpty) {
            buttons
                .add(_buildPrimaryButton(ref.tr('order_confirm_payment'), () {
              _showConfirmPaymentDialog(context, ref);
            }));
          } else {
            buttons.add(_buildOutlineButton(ref.tr('common_view_detail'), () {
              _openOrderDetail(context);
            }, context));
          }
        } else {
          buttons.add(_buildOutlineButton(ref.tr('order_cancel_title'), () {
            _showCancelDialog(context, ref);
          }, context));
          buttons.add(const SizedBox(width: 12));
          buttons.add(_buildPrimaryButton(ref.tr('order_pay_now'), () {
            _showPaymentDialog(context, ref);
          }));
        }
        break;
      case OrderStatus.paid:
        if (isAdmin) {
          buttons.add(_buildPrimaryButton(ref.tr('order_ship'), () {
            _showShippingDialog(context, ref);
          }));
        } else {
          buttons.add(_buildOutlineButton(ref.tr('common_view_detail'), () {
            _openOrderDetail(context);
          }, context));
        }
        break;
      case OrderStatus.shipped:
        buttons.add(_buildOutlineButton(ref.tr('order_logistics'), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LogisticsScreen(order: order)),
          );
        }, context));
        if (!isAdmin) {
          buttons.add(const SizedBox(width: 12));
          buttons.add(_buildPrimaryButton(ref.tr('order_confirm_title'), () {
            _showConfirmReceiptDialog(context, ref);
          }));
        }
        break;
      case OrderStatus.completed:
      case OrderStatus.delivered:
        if (isAdmin) {
          buttons.add(_buildOutlineButton(ref.tr('common_view_detail'), () {
            _openOrderDetail(context);
          }, context));
        } else {
          buttons.add(_buildOutlineButton(ref.tr('order_return'), () {
            _showReturnDialog(context, ref);
          }, context));
          buttons.add(const SizedBox(width: 12));
          buttons.add(_buildPrimaryButton(ref.tr('order_review'), () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PublishReviewScreen(order: order)),
            );
            if (result == true) {
              debugPrint('评价成功!');
            }
          }));
        }
        break;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        if (isAdmin) {
          buttons.add(_buildOutlineButton(ref.tr('common_view_detail'), () {
            _openOrderDetail(context);
          }, context));
        } else {
          buttons.add(_buildOutlineButton(ref.tr('order_delete_title'), () {
            _showDeleteDialog(context, ref);
          }, context));
        }
        break;
      default:
        buttons.add(_buildOutlineButton(ref.tr('order_view_detail'), () {
          _openOrderDetail(context);
        }, context));
    }

    return buttons;
  }

  Widget _buildOutlineButton(
      String text, VoidCallback onPressed, BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: JewelryColors.jadeMist.withOpacity(0.72),
        side: BorderSide(
          color: JewelryColors.champagneGold.withOpacity(0.18),
        ),
        backgroundColor: JewelryColors.deepJade.withOpacity(0.42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: JewelryColors.emeraldLusterGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JewelryColors.emeraldGlow.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: JewelryColors.jadeBlack,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _formatLocalizedDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatShortDate(date);
  }

  // ---- Action dialog helpers ----

  void _showPaymentDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(order: order)),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('order_cancel_title')),
        content: Text(ref.tr('order_cancel_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ref.tr('order_cancel_back'))),
          TextButton(
            onPressed: () {
              ref.read(orderProvider.notifier).cancelOrder(order.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: JewelryColors.error),
            child: Text(ref.tr('order_cancel_ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _showShippingDialog(BuildContext context, WidgetRef ref) async {
    final result = await ShippingDialog.show(
      context,
      orderId: order.id,
      productName: order.localizedProductNameFor(
        ref.read(appSettingsProvider).language,
      ),
    );
    if (result != null && context.mounted) {
      final ok = await ref.read(orderProvider.notifier).shipOrder(
            order.id,
            carrier: result.carrier,
            trackingNumber: result.trackingNumber,
          );
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('order_ship_success'))),
        );
      }
    }
  }

  void _showConfirmPaymentDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('order_confirm_payment')),
        content: Text(ref.tr('order_confirm_payment_hint')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ref.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final ok = await ref.read(orderProvider.notifier).confirmPayment(
                    order.id,
                  );
              if (!ctx.mounted) {
                return;
              }
              Navigator.pop(ctx);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(ref.tr('order_confirm_payment_success'))),
                );
              }
            },
            child: Text(ref.tr('confirm')),
          ),
        ],
      ),
    );
  }

  void _showConfirmReceiptDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('order_confirm_title')),
        content: Text(ref.tr('order_confirm_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ref.tr('cancel'))),
          TextButton(
            onPressed: () {
              ref.read(orderProvider.notifier).confirmReceipt(order.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ref.tr('order_confirmed'))),
              );
            },
            child: Text(ref.tr('order_confirm_title')),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('order_return_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ref.tr('order_return_reason')),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: ref.tr('order_return_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ref.tr('cancel'))),
          TextButton(
            onPressed: () {
              ref.read(orderProvider.notifier).requestReturn(
                    order.id,
                    reason: controller.text.trim().isNotEmpty
                        ? controller.text.trim()
                        : null,
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ref.tr('order_return_submitted'))),
              );
            },
            child: Text(ref.tr('order_return_submit')),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('order_delete_title')),
        content: Text(ref.tr('order_delete_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ref.tr('cancel'))),
          TextButton(
            onPressed: () {
              ref.read(orderProvider.notifier).deleteOrder(order.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: JewelryColors.error),
            child: Text(ref.tr('order_delete_ok')),
          ),
        ],
      ),
    );
  }

  void _openOrderDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );
  }
}
