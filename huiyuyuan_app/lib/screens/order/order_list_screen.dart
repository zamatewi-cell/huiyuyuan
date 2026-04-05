/// HuiYuYuan order list screen.
///
/// Features:
/// - grouped order states
/// - order detail entry
/// - order actions such as cancel and confirm receipt
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/glassmorphic_card.dart';
import 'order_detail_screen.dart';
import 'publish_review_screen.dart';
import '../payment/payment_screen.dart';
import 'shipping_dialog.dart';
import 'logistics_screen.dart';

class _OrderTabItem {
  final String label;
  final OrderStatus? status;

  const _OrderTabItem({required this.label, this.status});
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

  List<_OrderTabItem> get _tabs => [
        _OrderTabItem(label: ref.tr('order_all')),
        _OrderTabItem(
            label: ref.tr('order_pending_payment'),
            status: OrderStatus.pending),
        _OrderTabItem(
            label: ref.tr('order_pending_shipment'), status: OrderStatus.paid),
        _OrderTabItem(
            label: ref.tr('order_pending_receipt'),
            status: OrderStatus.shipped),
        _OrderTabItem(
            label: ref.tr('order_completed'), status: OrderStatus.completed),
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
      backgroundColor: context.adaptiveBackground,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                return _OrderTabContent(status: tab.status);
              }).toList(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isAdmin = ref.watch(isAdminProvider);
    return PreferredSize(
      preferredSize: const Size.fromHeight(112),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.primary.withOpacity(0.9),
                  JewelryColors.primaryDark.withOpacity(0.9),
                ],
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
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            isAdmin
                                ? ref.tr('admin_orders')
                                : ref.tr('order_list_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // Filter tabs.
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
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
      itemBuilder: (context, index) => const OrderCardSkeleton(),
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
      color: JewelryColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      borderRadius: 20,
      backgroundColor: context.adaptiveSurface,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Column(
        children: [
          // Order header.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.adaptiveBackground.withOpacity(0.5),
              border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ref.tr('order_number')}: ${order.id}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.adaptiveTextSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: order.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.localizedLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: order.status.color,
                      fontWeight: FontWeight.w600,
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: JewelryColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: order.productImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            order.productImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.diamond_outlined,
                              size: 40,
                              color: JewelryColors.primary.withOpacity(0.5),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.diamond_outlined,
                          size: 40,
                          color: JewelryColors.primary.withOpacity(0.5),
                        ),
                ),
                const SizedBox(width: 12),

                // Product details.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.localizedProductName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.adaptiveTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${ref.tr('common_quantity')}: x${order.quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.adaptiveTextSecondary,
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
                              fontWeight: FontWeight.w700,
                              color: JewelryColors.price,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          Text(
                            _formatLocalizedDate(context, order.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.adaptiveTextHint,
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
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];
    final isAdmin = ref.watch(isAdminProvider);

    switch (order.status) {
      case OrderStatus.pending:
        if (isAdmin) {
          if (order.paymentId != null && order.paymentId!.isNotEmpty) {
            buttons.add(_buildPrimaryButton('order_confirm_payment'.tr, () {
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
        foregroundColor: context.adaptiveTextSecondary,
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
        gradient: JewelryColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JewelryColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
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
      productName: order.localizedProductName,
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
        title: Text('order_confirm_payment'.tr),
        content: Text('order_confirm_payment_hint'.tr),
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
                  SnackBar(content: Text('order_confirm_payment_success'.tr)),
                );
              }
            },
            child: Text('confirm'.tr),
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
