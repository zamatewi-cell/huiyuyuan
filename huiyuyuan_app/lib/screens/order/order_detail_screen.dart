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
import '../../providers/auth_provider.dart';
import 'publish_review_screen.dart';
import 'shipping_dialog.dart';
import 'logistics_screen.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/common/resilient_network_image.dart';
import '../payment/payment_screen.dart';
import '../../widgets/payment/payment_voucher_uploader.dart';

class _OrderDetailBackdrop extends StatelessWidget {
  const _OrderDetailBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -120,
            child: _OrderDetailGlowOrb(
              size: 320,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            bottom: 160,
            child: _OrderDetailGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _OrderDetailTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailGlowOrb extends StatelessWidget {
  const _OrderDetailGlowOrb({
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
            blurRadius: 96,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

class _OrderDetailTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = JewelryColors.champagneGold.withOpacity(0.04);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.12 + i * 0.13);
      final path = Path()..moveTo(-24, y);
      path.cubicTo(
        size.width * 0.22,
        y - 32,
        size.width * 0.72,
        y + 38,
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrderDetailTracePainter oldDelegate) => false;
}

class OrderDetailScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: _buildAppBar(context, ref),
      body: Stack(
        children: [
          const Positioned.fill(child: _OrderDetailBackdrop()),
          SingleChildScrollView(
            child: Column(
              children: [
                _buildStatusCard(),
                _buildOrderInfo(context, ref),
                _buildProductCard(context),
                _buildPaymentInfo(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
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
              color: JewelryColors.jadeBlack.withOpacity(0.84),
              border: Border(
                bottom: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.1),
                ),
              ),
            ),
            child: SafeArea(
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
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: JewelryColors.deepJade.withOpacity(0.62),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.14),
                          ),
                        ),
                        child: Text(
                          ref.tr('order_detail'),
                          style: const TextStyle(
                            color: JewelryColors.jadeMist,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: JewelryColors.jadeMist,
                    ),
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
    final statusColor = order.status.color;

    return GlassmorphicCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: 30,
      blur: 18,
      opacity: 0.18,
      borderColor: statusColor.withOpacity(0.32),
      boxShadow: [
        BoxShadow(
          color: statusColor.withOpacity(0.16),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ],
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.96),
                  JewelryColors.emeraldShadow.withOpacity(0.92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(
              _getStatusIcon(),
              color: JewelryColors.jadeBlack,
              size: 42,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            order.status.localizedLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(),
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.66),
              fontSize: 13,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
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
                color: isActive
                    ? JewelryColors.emeraldLuster
                    : JewelryColors.deepJade.withOpacity(0.72),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? JewelryColors.champagneGold.withOpacity(0.28)
                      : JewelryColors.champagneGold.withOpacity(0.08),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: JewelryColors.emeraldGlow.withOpacity(0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                color: isActive
                    ? JewelryColors.jadeBlack
                    : JewelryColors.jadeMist.withOpacity(0.18),
                size: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localizedSteps[index],
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(
                  isActive ? 0.9 : 0.34,
                ),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
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
    return GlassmorphicCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 16,
      opacity: 0.18,
      borderColor: JewelryColors.champagneGold.withOpacity(0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_info_section'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: JewelryColors.jadeMist,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, ref.tr('order_number'), order.id),
          _buildInfoRow(
              context, ref.tr('order_time'), _formatDate(order.createdAt)),
          if (order.operatorId != null)
            _buildInfoRow(
                context, ref.tr('order_operator_id'), order.operatorId!),
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
              color: JewelryColors.jadeMist.withOpacity(0.58),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.9),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
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
        return JewelryColors.emeraldGlow;
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
    final key = 'payment_status_${status.toLowerCase()}';
    return key.tr;
  }

  Widget _buildProductCard(BuildContext context) {
    return GlassmorphicCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 16,
      opacity: 0.18,
      borderColor: JewelryColors.champagneGold.withOpacity(0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_product_info'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: JewelryColors.jadeMist,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: JewelryColors.deepJade.withOpacity(0.58),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: JewelryColors.champagneGold.withOpacity(0.12),
                  ),
                ),
                child: order.productImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ResilientNetworkImage(
                          imageUrl: _resolveImageUrl(order.productImage!),
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorWidget: Icon(
                            Icons.diamond_outlined,
                            size: 40,
                            color: JewelryColors.emeraldGlow.withOpacity(0.48),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.diamond_outlined,
                        size: 40,
                        color: JewelryColors.emeraldGlow.withOpacity(0.48),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.localizedProductName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: JewelryColors.jadeMist,
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
                          '¥${(order.unitPrice ?? (order.amount / order.quantity)).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: JewelryColors.champagneGold,
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: JewelryColors.emeraldGlow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  JewelryColors.emeraldGlow.withOpacity(0.16),
                            ),
                          ),
                          child: Text(
                            'x${order.quantity}',
                            style: const TextStyle(
                              color: JewelryColors.emeraldGlow,
                              fontWeight: FontWeight.w800,
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
    return GlassmorphicCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 16,
      opacity: 0.18,
      borderColor: JewelryColors.champagneGold.withOpacity(0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_payment_info'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: JewelryColors.jadeMist,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ResilientNetworkImage(
                  imageUrl: _resolveImageUrl(order.paymentAccount!.qrCodeUrl!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: const SizedBox.shrink(),
                ),
              ),
            ],
          ],
          // 支付状态指示器
          if (order.paymentRecordStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _paymentStatusColor(order.paymentRecordStatus!)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _paymentStatusColor(order.paymentRecordStatus!)
                      .withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _paymentStatusIcon(order.paymentRecordStatus!),
                    size: 16,
                    color: _paymentStatusColor(order.paymentRecordStatus!),
                  ),
                  const SizedBox(width: 6),
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
          if (order.paymentAdminNote != null &&
              order.paymentAdminNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JewelryColors.champagneGold.withOpacity(0.09),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: JewelryColors.champagneGold.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 14,
                        color: JewelryColors.champagneGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'payment_admin_note_label'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: JewelryColors.champagneGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.paymentAdminNote!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: JewelryColors.jadeMist.withOpacity(0.66),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 支付凭证上传
          if (order.status == OrderStatus.pending ||
              order.paymentRecordStatus == 'awaiting_confirmation') ...[
            const SizedBox(height: 16),
            PaymentVoucherUploader(
              paymentId: order.paymentId ?? order.id,
              currentVoucherUrl: order.paymentVoucherUrl,
              onUploaded: (url) {
                // TODO: 调用后端API保存凭证URL
              },
            ),
          ],
          Divider(
            height: 32,
            color: JewelryColors.champagneGold.withOpacity(0.12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'order_actual_paid'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: JewelryColors.jadeMist,
                ),
              ),
              Text(
                '\u00A5${order.totalPaid.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Roboto',
                  color: JewelryColors.champagneGold,
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
            color: JewelryColors.jadeBlack.withOpacity(0.74),
            border: Border(
              top: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 28,
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
                  gradient: JewelryColors.emeraldLusterGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: JewelryShadows.emeraldHalo,
                ),
                child: ElevatedButton(
                  onPressed: order.paymentId == null || order.paymentId!.isEmpty
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: JewelryColors.deepJade,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              title: Text(
                                'order_confirm_payment'.tr,
                                style: const TextStyle(
                                  color: JewelryColors.jadeMist,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              content: Text(
                                'order_confirm_payment_hint'.tr,
                                style: TextStyle(
                                  color:
                                      JewelryColors.jadeMist.withOpacity(0.66),
                                  height: 1.45,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    ref.tr('cancel'),
                                    style: TextStyle(
                                      color: JewelryColors.jadeMist
                                          .withOpacity(0.58),
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    final ok = await ref
                                        .read(orderProvider.notifier)
                                        .confirmPayment(order.id);
                                    if (!ctx.mounted) {
                                      return;
                                    }
                                    Navigator.pop(ctx);
                                    if (ok && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'order_confirm_payment_success'.tr,
                                          ),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        JewelryColors.emeraldLuster,
                                    foregroundColor: JewelryColors.jadeBlack,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text('confirm'.tr),
                                ),
                              ],
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: JewelryColors.jadeBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  child: Text(
                    'order_confirm_payment'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
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
                foregroundColor: JewelryColors.jadeMist,
                backgroundColor: JewelryColors.deepJade.withOpacity(0.36),
                side: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.28),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              child: Text(ref.tr('order_cancel_title'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: JewelryColors.emeraldLusterGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: JewelryShadows.emeraldHalo,
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
                  foregroundColor: JewelryColors.jadeBlack,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: Text(ref.tr('order_pay_now'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    )),
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
                  backgroundColor: JewelryColors.deepJade.withOpacity(0.62),
                  foregroundColor: JewelryColors.jadeMist,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'common_back'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ];
        }
        return [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: JewelryColors.emeraldLusterGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: JewelryShadows.emeraldHalo,
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
                  foregroundColor: JewelryColors.jadeBlack,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: Text(ref.tr('order_ship'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    )),
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
                foregroundColor: JewelryColors.jadeMist,
                backgroundColor: JewelryColors.deepJade.withOpacity(0.36),
                side: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.28),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              child: Text(ref.tr('order_logistics'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: JewelryColors.emeraldLusterGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: JewelryShadows.emeraldHalo,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: JewelryColors.deepJade,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: Text(
                          ref.tr('order_confirm_title'),
                          style: const TextStyle(
                            color: JewelryColors.jadeMist,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        content: Text(
                          'order_confirm_received_hint'.tr,
                          style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.66),
                            height: 1.45,
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                ref.tr('cancel'),
                                style: TextStyle(
                                  color:
                                      JewelryColors.jadeMist.withOpacity(0.58),
                                ),
                              )),
                          FilledButton(
                            onPressed: () {
                              ref
                                  .read(orderProvider.notifier)
                                  .confirmReceipt(order.id);
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: JewelryColors.emeraldLuster,
                              foregroundColor: JewelryColors.jadeBlack,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(ref.tr('confirm')),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: JewelryColors.jadeBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  child: Text(ref.tr('order_confirm_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      )),
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
                  backgroundColor: JewelryColors.deepJade.withOpacity(0.62),
                  foregroundColor: JewelryColors.jadeMist,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'common_back'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                    backgroundColor: JewelryColors.deepJade,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: Text(
                      ref.tr('order_return_title'),
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ref.tr('order_return_reason'),
                          style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.66),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          maxLines: 3,
                          style: const TextStyle(color: JewelryColors.jadeMist),
                          decoration: InputDecoration(
                            hintText: ref.tr('order_return_hint'),
                            hintStyle: TextStyle(
                              color: JewelryColors.jadeMist.withOpacity(0.34),
                            ),
                            filled: true,
                            fillColor: JewelryColors.jadeBlack.withOpacity(0.3),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: JewelryColors.champagneGold
                                    .withOpacity(0.14),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color:
                                    JewelryColors.emeraldGlow.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            ref.tr('cancel'),
                            style: TextStyle(
                              color: JewelryColors.jadeMist.withOpacity(0.58),
                            ),
                          )),
                      FilledButton(
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
                        style: FilledButton.styleFrom(
                          backgroundColor: JewelryColors.emeraldLuster,
                          foregroundColor: JewelryColors.jadeBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text('common_submit'.tr),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: JewelryColors.jadeMist,
                backgroundColor: JewelryColors.deepJade.withOpacity(0.36),
                side: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.28),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
              child: Text(ref.tr('order_return'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
                backgroundColor: JewelryColors.champagneGold,
                foregroundColor: JewelryColors.jadeBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                elevation: 0,
              ),
              child: Text(ref.tr('order_review'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
            ),
          ),
        ];
      default:
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.deepJade.withOpacity(0.62),
                foregroundColor: JewelryColors.jadeMist,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                elevation: 0,
              ),
              child: Text('common_back'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
