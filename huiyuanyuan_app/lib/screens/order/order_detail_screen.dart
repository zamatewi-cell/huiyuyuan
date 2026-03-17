/// 汇玉源 - 订单详情页面
///
/// 功能:
/// - 订单信息展示
/// - 订单状态流程
/// - 商品信息
/// - 操作按钮
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import 'publish_review_screen.dart';
import 'shipping_dialog.dart';
import 'logistics_screen.dart';
import '../../services/order_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/glassmorphic_card.dart';

class OrderDetailScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusCard(),
            _buildOrderInfo(context),
            _buildProductCard(context),
            _buildPaymentInfo(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '订单详情',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            order.status.color.withOpacity(0.15),
            order.status.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: order.status.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(),
            color: order.status.color,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            order.status.label,
            style: TextStyle(
              color: order.status.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(),
            style: TextStyle(
              color: JewelryColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // 状态流程
          _buildStatusTimeline(),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (order.status) {
      case OrderStatus.pending:
        return Icons.payment;
      case OrderStatus.paid:
        return Icons.check_circle;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.home;
      case OrderStatus.completed:
        return Icons.verified;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusDescription() {
    switch (order.status) {
      case OrderStatus.pending:
        return '请在24小时内完成支付，逾期订单将自动取消';
      case OrderStatus.paid:
        return '商家正在准备发货，请耐心等待';
      case OrderStatus.shipped:
        return '商品已发出，预计3-5天送达';
      case OrderStatus.delivered:
        return '商品已送达，请确认收货';
      case OrderStatus.completed:
        return '交易完成，感谢您的购买';
      case OrderStatus.cancelled:
        return '订单已取消';
      default:
        return '';
    }
  }

  Widget _buildStatusTimeline() {
    final steps = ['下单', '付款', '发货', '收货', '完成'];
    final currentStep = _getCurrentStep();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;

        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? order.status.color : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[index],
              style: TextStyle(
                color: isActive
                    ? JewelryColors.textPrimary
                    : JewelryColors.textHint,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  int _getCurrentStep() {
    switch (order.status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.paid:
        return 1;
      case OrderStatus.shipped:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.completed:
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildOrderInfo(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '订单信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, '订单编号', order.id),
          _buildInfoRow(context, '下单时间', _formatDate(order.createdAt)),
          if (order.operatorId != null)
            _buildInfoRow(context, '处理人ID', order.operatorId!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.adaptiveTextSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: context.adaptiveTextPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '商品信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: JewelryColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.diamond_outlined,
                  size: 40,
                  color: JewelryColors.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.adaptiveTextPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '¥${order.amount / order.quantity}',
                          style: const TextStyle(
                            color: JewelryColors.price,
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.adaptiveBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'x${order.quantity}',
                            style: TextStyle(
                              color: context.adaptiveTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '支付信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, '商品金额', '¥${order.amount}'),
          _buildInfoRow(context, '运费', '¥0.00'),
          _buildInfoRow(context, '优惠', '-¥0.00'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '实付金额',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.adaptiveTextPrimary,
                ),
              ),
              Text(
                '¥${order.amount}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                  color: JewelryColors.price,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
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
            children: _buildActionButtons(context, ref),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, WidgetRef ref) {
    switch (order.status) {
      case OrderStatus.pending:
        return [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ref.read(orderProvider.notifier).cancelOrder(order.id);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.adaptiveTextSecondary,
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('取消订单',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: JewelryColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: JewelryShadows.light,
              ),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('支付功能开发中...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('立即付款',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ),
        ];
      case OrderStatus.paid:
        return [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: JewelryColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: JewelryShadows.light,
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await ShippingDialog.show(
                    context,
                    orderId: order.id,
                    productName: order.productName,
                  );
                  if (result != null && context.mounted) {
                    await ref.read(orderProvider.notifier).shipOrder(
                          order.id,
                          carrier: result.carrier,
                          trackingNumber: result.trackingNumber,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('\u53D1\u8D27\u6210\u529F\uFF01')),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('\u53BB\u53D1\u8D27',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ),
        ];

      case OrderStatus.shipped:
        return [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LogisticsScreen(order: order)),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.adaptiveTextSecondary,
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('\u67E5\u770B\u7269\u6D41',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: JewelryColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: JewelryShadows.light,
              ),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('\u786E\u8BA4\u6536\u8D27'),
                      content: const Text('\u8BF7\u786E\u8BA4\u5DF2\u6536\u5230\u5546\u54C1'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('\u53D6\u6D88')),
                        TextButton(
                          onPressed: () {
                            ref.read(orderProvider.notifier).confirmReceipt(order.id);
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('\u786E\u8BA4'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('\u786E\u8BA4\u6536\u8D27',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ),
        ];
      case OrderStatus.completed:
        return [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('\u7533\u8BF7\u9000\u8D27'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('\u8BF7\u586B\u5199\u9000\u8D27\u539F\u56E0\uFF1A'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: '\u8BF7\u8F93\u5165\u9000\u8D27\u539F\u56E0...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('\u53D6\u6D88')),
                      TextButton(
                        onPressed: () {
                          ref.read(orderProvider.notifier).requestReturn(
                                order.id,
                                reason: controller.text.trim().isNotEmpty
                                    ? controller.text.trim()
                                    : null,
                              );
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('\u63D0\u4EA4'),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.adaptiveTextSecondary,
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('发起退货',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PublishReviewScreen(order: order)),
                );
                if (result == true) {
                  // 这里实际应更新订单服务标记该商品已评价
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.gold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('评价晒单',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ];
      default:
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.adaptiveSurface,
                foregroundColor: context.adaptiveTextPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('返回',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
