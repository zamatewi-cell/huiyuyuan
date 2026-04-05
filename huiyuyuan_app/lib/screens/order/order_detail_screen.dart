/// 汇玉源 - 订单详情页面
///
/// 功能:
/// - 订单信息展示
/// - 订单状态流程
/// - 商品信息
/// - 操作按钮
library;

import 'package:huiyuyuan/l10n/string_extension.dart';

import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import '../../providers/app_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../config/api_config.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../providers/auth_provider.dart';
import 'publish_review_screen.dart';
import 'shipping_dialog.dart';
import 'logistics_screen.dart';
import '../../services/order_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../payment/payment_screen.dart';
import '../../widgets/payment/payment_voucher_uploader.dart';

class OrderDetailScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: _buildAppBar(context, ref),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusCard(),
            _buildOrderInfo(context, ref),
            _buildProductCard(context),
            _buildPaymentInfo(context),
            SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
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
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      ref.tr('order_detail'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.white),
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
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
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
          SizedBox(height: 12),
          Text(
            order.status.localizedLabel,
            style: TextStyle(
              color: order.status.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _getStatusDescription(),
            style: const TextStyle(
              color: JewelryColors.textSecondary,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 16),
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
        if (order.paymentId != null && order.paymentId!.isNotEmpty) {
          return 'payment_waiting_admin_confirm'.tr;
        }
        return 'order_status_pending_desc'.tr;
      case OrderStatus.paid:
        return TranslatorGlobal.instance
            .translate('merchant_preparing_shipment');
      case OrderStatus.shipped:
        return 'order_status_shipped_desc'.tr;
      case OrderStatus.delivered:
        return 'order_status_delivered_desc'.tr;
      case OrderStatus.completed:
        return 'order_status_completed_desc'.tr;
      case OrderStatus.cancelled:
        return 'order_status_cancelled_desc'.tr;
      default:
        return '';
    }
  }

  Widget _buildStatusTimeline() {
    // ignore: unused_local_variable
    final steps = [
      'order_step_placed'.tr,
      'order_step_paid'.tr,
      'order_step_shipped'.tr,
      'order_step_received'.tr,
      'order_step_completed'.tr,
    ];
    final currentStep = _getCurrentStep();
    final localizedSteps = switch (TranslatorGlobal.currentLang) {
      AppLanguage.en => steps,
      AppLanguage.zhTW => steps,
      AppLanguage.zhCN => steps,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(localizedSteps.length, (index) {
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
            SizedBox(height: 4),
            Text(
              localizedSteps[index],
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

  Widget _buildOrderInfo(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_info_section'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.adaptiveTextPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(context, ref.tr('order_number'), order.id),
          _buildInfoRow(
              context, ref.tr('order_time'), _formatDate(order.createdAt)),
          if (order.operatorId != null)
            _buildInfoRow(context, ref.tr('order_operator_id'), order.operatorId!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
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

  // ── 支付状态辅助方法 ──

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return JewelryColors.success;
      case 'awaiting_confirmation':
        return JewelryColors.warning;
      case 'cancelled':
      case 'timeout':
        return JewelryColors.error;
      case 'disputed':
        return Colors.orange;
      case 'pending':
      default:
        return JewelryColors.primary;
    }
  }

  IconData _paymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'awaiting_confirmation':
        return Icons.hourglass_top;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'timeout':
        return Icons.schedule;
      case 'disputed':
        return Icons.report_problem_outlined;
      case 'pending':
      default:
        return Icons.pending_outlined;
    }
  }

  String _paymentStatusLabel(String status) {
    final key = 'payment_status_${status.toLowerCase()}';;
    return key.tr;
  }

  Widget _buildProductCard(BuildContext context) {
    return PremiumCard(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_product_info'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.adaptiveTextPrimary,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: JewelryColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: order.productImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
              SizedBox(width: 12),
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
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '¥${(order.unitPrice ?? (order.amount / order.quantity)).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: JewelryColors.price,
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      borderRadius: 24,
      backgroundColor: context.adaptiveSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_payment_info'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.adaptiveTextPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            context,
            'order_goods_amount'.tr,
            '\u00A5${order.amount.toStringAsFixed(2)}',
          ),
          _buildInfoRow(
            context,
            'order_shipping_fee'.tr,
            '\u00A5${order.shippingFee.toStringAsFixed(2)}',
          ),
          _buildInfoRow(
            context,
            'order_discount'.tr,
            '-\u00A5${order.discount.toStringAsFixed(2)}',
          ),
          if (order.paymentMethod != null)
            _buildInfoRow(
              context,
              'payment_method_title'.tr,
              order.paymentMethod!.label.tr,
            ),
          if (order.paymentAccount != null) ...[
            _buildInfoRow(
              context,
              'payment_account_name'.tr,
              order.paymentAccount!.name,
            ),
            if ((order.paymentAccount!.accountNumber ?? '').isNotEmpty)
              _buildInfoRow(
                context,
                'payment_account_number'.tr,
                order.paymentAccount!.accountNumber!,
              ),
            if ((order.paymentAccount!.bankName ?? '').isNotEmpty)
              _buildInfoRow(
                context,
                'payment_bank_name'.tr,
                order.paymentAccount!.bankName!,
              ),
            if ((order.paymentAccount!.qrCodeUrl ?? '').isNotEmpty) ...[
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _resolveImageUrl(order.paymentAccount!.qrCodeUrl!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SizedBox.shrink(),
                ),
              ),
            ],
          ],
          // 支付状态指示器
          if (order.paymentRecordStatus != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _paymentStatusColor(order.paymentRecordStatus!).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _paymentStatusIcon(order.paymentRecordStatus!),
                    size: 16,
                    color: _paymentStatusColor(order.paymentRecordStatus!),
                  ),
                  SizedBox(width: 6),
                  Text(
                    _paymentStatusLabel(order.paymentRecordStatus!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _paymentStatusColor(order.paymentRecordStatus!),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 管理员备注
          if (order.paymentAdminNote != null && order.paymentAdminNote!.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JewelryColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: JewelryColors.gold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 14, color: JewelryColors.gold),
                      SizedBox(width: 4),
                      Text(
                        'payment_admin_note_label'.tr,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: JewelryColors.gold),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    order.paymentAdminNote!,
                    style: TextStyle(fontSize: 12, color: JewelryColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          // 支付凭证上传
          if (order.status == OrderStatus.pending || order.paymentRecordStatus == 'awaiting_confirmation') ...[
            SizedBox(height: 16),
            PaymentVoucherUploader(
              paymentId: order.paymentId ?? order.id,
              currentVoucherUrl: order.paymentVoucherUrl,
              onUploaded: (url) {
                // TODO: 调用后端API保存凭证URL
              },
            ),
          ],
          Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'order_actual_paid'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.adaptiveTextPrimary,
                ),
              ),
              Text(
                '\u00A5${order.totalPaid.toStringAsFixed(2)}',
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    final isAdmin = ref.watch(isAdminProvider);
    switch (order.status) {
      case OrderStatus.pending:
        if (isAdmin) {
          return [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: JewelryColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: JewelryShadows.light,
                ),
                child: ElevatedButton(
                  onPressed: order.paymentId == null || order.paymentId!.isEmpty
                      ? null
                      : () {
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
                                    final ok = await ref
                                        .read(orderProvider.notifier)
                                        .confirmPayment(order.id);
                                    if (!ctx.mounted) {
                                      return;
                                    }
                                    Navigator.pop(ctx);
                                    if (ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'order_confirm_payment_success'.tr,
                                          ),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Text('confirm'.tr),
                                ),
                              ],
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'order_confirm_payment'.tr,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ),
          ];
        }

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
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(ref.tr('order_cancel_title'),
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 12),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(order: order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(ref.tr('order_pay_now'),
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ),
        ];
      case OrderStatus.paid:
        if (!isAdmin) {
          return [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.adaptiveSurface,
                  foregroundColor: context.adaptiveTextPrimary,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'common_back'.tr,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ];
        }
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
                    productName: order.localizedProductName,
                  );
                  if (result != null && context.mounted) {
                    await ref.read(orderProvider.notifier).shipOrder(
                          order.id,
                          carrier: result.carrier,
                          trackingNumber: result.trackingNumber,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ref.tr('order_ship_success'))),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(ref.tr('order_ship'),
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
                  MaterialPageRoute(
                      builder: (_) => LogisticsScreen(order: order)),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.adaptiveTextSecondary,
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(ref.tr('order_logistics'),
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          if (!isAdmin) ...[
            SizedBox(width: 12),
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
                        title: Text(ref.tr('order_confirm_title')),
                        content: Text('order_confirm_received_hint'.tr),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(ref.tr('cancel'))),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(orderProvider.notifier)
                                  .confirmReceipt(order.id);
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: Text(ref.tr('confirm')),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(ref.tr('order_confirm_title'),
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ),
          ],
        ];
      case OrderStatus.completed:
      case OrderStatus.delivered:
        if (isAdmin) {
          return [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.adaptiveSurface,
                  foregroundColor: context.adaptiveTextPrimary,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'common_back'.tr,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ];
        }
        return [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(ref.tr('order_return_title')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ref.tr('order_return_reason')),
                        SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: ref.tr('order_return_hint'),
                            border: OutlineInputBorder(),
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
                          Navigator.pop(context);
                        },
                        child: Text('common_submit'.tr),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.adaptiveTextSecondary,
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(ref.tr('order_return'),
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 12),
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
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(ref.tr('order_review'),
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
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child:
                  Text('common_back'.tr,
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

String _resolveImageUrl(String rawUrl) {
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  if (rawUrl.startsWith('/')) {
    return '${ApiConfig.apiUrl}$rawUrl';
  }
  return rawUrl;
}
