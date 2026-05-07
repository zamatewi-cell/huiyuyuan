/// 汇玉源 - 支付页面
///
/// 功能:
/// - 订单信息卡片
/// - 支付方式选择
/// - 平台收款账户展示
/// - 轮询管理员确认到账状态
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

import '../../config/api_config.dart';
import '../../l10n/l10n_provider.dart';
import '../../models/order_model.dart' hide PaymentMethod;
import '../../providers/app_settings_provider.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../themes/colors.dart';
import '../../widgets/common/error_handler.dart';
import '../../widgets/common/resilient_network_image.dart';
import '../order/order_list_screen.dart';

class _PaymentBackdrop extends StatelessWidget {
  const _PaymentBackdrop();

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
            child: _PaymentGlowOrb(
              size: 340,
              color: JewelryColors.emeraldGlow.withOpacity(0.11),
            ),
          ),
          Positioned(
            left: -140,
            top: 290,
            child: _PaymentGlowOrb(
              size: 290,
              color: JewelryColors.champagneGold.withOpacity(0.11),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _PaymentTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentGlowOrb extends StatelessWidget {
  const _PaymentGlowOrb({
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

class _PaymentTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.1 + i * 0.12);
      final path = Path()..moveTo(-20, y);
      path.quadraticBezierTo(
        size.width * 0.5,
        y + (i.isEven ? 26 : -24),
        size.width + 20,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaymentTracePainter oldDelegate) => false;
}

BoxDecoration _paymentGlassDecoration({
  double radius = 24,
  double borderOpacity = 0.13,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        JewelryColors.deepJade.withOpacity(0.78),
        JewelryColors.jadeSurface.withOpacity(0.5),
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

class PaymentScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const PaymentScreen({super.key, required this.order});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with TickerProviderStateMixin {
  String _selectedMethod = 'wechat';
  String _payState = 'idle'; // idle / creating / waiting / success / failed
  int _remainingSeconds = 900;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  OrderPaymentStatusResult? _paymentStatus;

  late final AnimationController _successController;
  late final Animation<double> _successScale;

  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.order.paymentMethod?.name == 'balance'
        ? 'unionpay'
        : (widget.order.paymentMethod?.name ?? 'wechat');
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _startCountdown();
    _restorePendingPaymentIfNeeded();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _successController.dispose();
    super.dispose();
  }

  void _restorePendingPaymentIfNeeded() {
    if (widget.order.paymentId == null ||
        widget.order.status != OrderStatus.pending) {
      return;
    }

    _paymentStatus = OrderPaymentStatusResult(
      status: PaymentStatus.pending,
      paymentId: widget.order.paymentId,
      amount: widget.order.totalPaid,
      method: _methodFromCode(widget.order.paymentMethod?.name),
      paymentAccountId: widget.order.paymentAccountId,
      paymentAccount: widget.order.paymentAccount,
      message: ref.tr('payment_waiting_admin_confirm'),
    );
    _payState = 'waiting';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPaymentStatus();
      _startPolling();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _pollTimer?.cancel();
        if (mounted && _payState != 'success') {
          setState(() => _payState = 'failed');
        }
        return;
      }

      if (mounted) {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshPaymentStatus();
    });
  }

  Future<void> _refreshPaymentStatus() async {
    if (!mounted || _paymentStatus?.paymentId == null) {
      return;
    }

    // Preserve the payment account info across polls to prevent collection card from disappearing
    final preservedAccount = _paymentStatus?.paymentAccount;

    try {
      final result =
          await _paymentService.queryOrderPaymentStatus(widget.order.id);
      if (!mounted || result == null) {
        return;
      }

      if (result.isSuccess) {
        _onPaymentSuccess();
        return;
      }

      if (result.status == PaymentStatus.disputed ||
          result.status == PaymentStatus.cancelled) {
        _pollTimer?.cancel();
        setState(() {
          _paymentStatus = result;
          _payState = 'failed';
        });
        return;
      }

      // Merge: use fresh status but preserve payment account if new result lacks it
      setState(() {
        _paymentStatus = result.copyWith(
          paymentAccount: result.paymentAccount ?? preservedAccount,
        );
        _payState = 'waiting';
      });
    } catch (_) {
      // 继续等待下一次轮询
    }
  }

  String get _formattedCountdown {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startPayment() async {
    setState(() => _payState = 'creating');

    try {
      final result = await _paymentService.submitOrderPayment(
        orderId: widget.order.id,
        method: _methodFromCode(_selectedMethod),
      );

      if (!mounted || result == null) {
        setState(() => _payState = 'failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.tr('payment_operation_retry'))),
          );
        }
        return;
      }

      if (result.isSuccess) {
        _onPaymentSuccess();
        return;
      }

      setState(() {
        _paymentStatus = result;
        _payState = 'waiting';
      });
      _startPolling();
    } catch (e) {
      if (mounted) {
        setState(() => _payState = 'failed');
        context.showError(e);
      }
    }
  }

  Future<void> _onPaymentSuccess() async {
    if (!mounted || _payState == 'success') {
      return;
    }

    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    await ref.read(orderProvider.notifier).refresh();

    if (!mounted) {
      return;
    }

    setState(() => _payState = 'success');
    _successController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const OrderListScreen(initialTab: 2),
        ),
        (route) => route.isFirst,
      );
    });
  }

  void _resetPaymentFlow() {
    _pollTimer?.cancel();
    setState(() {
      _paymentStatus = null;
      _payState = 'idle';
    });
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
                  Icons.payments_outlined,
                  color: JewelryColors.jadeBlack,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ref.tr('payment_page_title'),
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
          const Positioned.fill(child: _PaymentBackdrop()),
          _payState == 'success' ? _buildSuccessView() : _buildPaymentView(),
        ],
      ),
    );
  }

  Widget _buildPaymentView() {
    const textPrimary = JewelryColors.jadeMist;
    final textSecondary = JewelryColors.jadeMist.withOpacity(0.58);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAmountCard(),
          const SizedBox(height: 20),
          _buildOrderInfoCard(textPrimary, textSecondary),
          const SizedBox(height: 20),
          _buildMethodCard(textPrimary),
          if (_paymentStatus?.paymentAccount != null) ...[
            const SizedBox(height: 20),
            _buildCollectionCard(textPrimary, textSecondary),
          ],
          const SizedBox(height: 32),
          _buildBottomActions(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.emeraldGlow.withOpacity(0.92),
            JewelryColors.emeraldLuster,
            JewelryColors.emeraldShadow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: JewelryColors.emeraldGlow.withOpacity(0.22),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            ref.tr('payment_amount_title'),
            style: TextStyle(
              color: JewelryColors.jadeBlack.withOpacity(0.68),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥ ${widget.order.totalPaid.toStringAsFixed(2)}',
            style: const TextStyle(
              color: JewelryColors.jadeBlack,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: JewelryColors.jadeBlack.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: JewelryColors.jadeBlack.withOpacity(0.12),
              ),
            ),
            child: Text(
              ref.tr('payment_remaining_time',
                  params: {'time': _formattedCountdown}),
              style: TextStyle(
                color: _remainingSeconds < 60
                    ? JewelryColors.error
                    : JewelryColors.jadeBlack,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(Color textPrimary, Color textSecondary) {
    final language = ref.watch(appSettingsProvider).language;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _paymentGlassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.tr('payment_order_info'),
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(ref.tr('order_number'), widget.order.id, textSecondary),
          _buildInfoRow(
            ref.tr('product_info_section'),
            widget.order.localizedProductNameFor(language),
            textSecondary,
          ),
          _buildInfoRow(
            ref.tr('common_quantity'),
            '${widget.order.quantity}',
            textSecondary,
          ),
          if (widget.order.shippingAddress != null &&
              widget.order.shippingAddress!.isNotEmpty)
            _buildInfoRow(
              ref.tr('profile_address'),
              widget.order.shippingAddress!,
              textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(Color textPrimary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _paymentGlassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.tr('payment_method_title'),
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            'wechat',
            ref.tr('payment_method_wechat'),
            Icons.chat_bubble_rounded,
            const Color(0xFF07C160),
            textPrimary,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            'alipay',
            ref.tr('payment_method_alipay'),
            Icons.account_balance_wallet_rounded,
            const Color(0xFF1677FF),
            textPrimary,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            'unionpay',
            ref.tr('payment_bank_transfer'),
            Icons.account_balance_rounded,
            const Color(0xFF1A3E7C),
            textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(Color textPrimary, Color textSecondary) {
    final account = _paymentStatus?.paymentAccount;
    if (account == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _paymentGlassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.tr('payment_collection_info'),
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: JewelryColors.emeraldGlow.withOpacity(0.16),
              ),
            ),
            child: Text(
              _paymentStatus?.message ??
                  ref.tr('payment_waiting_admin_confirm'),
              style: const TextStyle(
                color: JewelryColors.emeraldGlow,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (account.qrCodeUrl != null && account.qrCodeUrl!.trim().isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ResilientNetworkImage(
                  imageUrl: _resolveImageUrl(account.qrCodeUrl!),
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorWidget: _buildQrFallback(textSecondary),
                ),
              ),
            )
          else
            Center(child: _buildQrFallback(textSecondary)),
          const SizedBox(height: 16),
          _buildInfoRow(
            ref.tr('payment_account_type'),
            account.typeName.tr,
            textSecondary,
          ),
          _buildInfoRow(
            ref.tr('payment_account_name'),
            account.name,
            textSecondary,
          ),
          if (account.accountNumber != null &&
              account.accountNumber!.isNotEmpty)
            _buildInfoRow(
              ref.tr('payment_account_number'),
              account.accountNumber!,
              textSecondary,
            ),
          if (account.bankName != null && account.bankName!.isNotEmpty)
            _buildInfoRow(
              ref.tr('payment_bank_name'),
              account.bankName!,
              textSecondary,
            ),
          if ((_paymentStatus?.paymentId ?? '').isNotEmpty)
            _buildInfoRow(
              ref.tr('payment_record_number'),
              _paymentStatus!.paymentId!,
              textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildQrFallback(Color textSecondary) {
    return Container(
      width: 220,
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: JewelryColors.deepJade.withOpacity(0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.12),
        ),
      ),
      child: Text(
        ref.tr('payment_qr_unavailable'),
        style: TextStyle(color: textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_payState == 'waiting') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _refreshPaymentStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.emeraldLuster,
                foregroundColor: JewelryColors.jadeBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
                shadowColor: JewelryColors.emeraldGlow.withOpacity(0.25),
              ),
              child: Text(
                ref.tr('payment_refresh_status'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _resetPaymentFlow,
              style: OutlinedButton.styleFrom(
                foregroundColor: JewelryColors.jadeMist,
                side: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.28),
                ),
                backgroundColor: JewelryColors.deepJade.withOpacity(0.38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(ref.tr('payment_change_method')),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: _confirmCancelPayment,
              style: TextButton.styleFrom(
                foregroundColor: JewelryColors.error,
              ),
              child: Text(ref.tr('payment_cancel_payment')),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _payState == 'creating' || _remainingSeconds <= 0
                ? null
                : _startPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.emeraldLuster,
              foregroundColor: JewelryColors.jadeBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 4,
              shadowColor: JewelryColors.emeraldGlow.withOpacity(0.25),
            ),
            child: _payState == 'creating'
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: JewelryColors.jadeBlack,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        ref.tr('payment_submitting'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                : Text(
                    ref.tr('payment_submit_transfer'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
        if (_payState == 'failed') ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _payState = 'idle';
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: JewelryColors.jadeMist,
                side: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.28),
                ),
                backgroundColor: JewelryColors.deepJade.withOpacity(0.38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(ref.tr('payment_retry')),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmCancelPayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          ref.tr('payment_cancel_confirm'),
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          ref.tr('payment_cancel_prompt'),
          style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.68)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              ref.tr('common_cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.56)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: JewelryColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(ref.tr('common_confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final success = await _paymentService.cancelPayment(
        _paymentStatus?.paymentId ?? '',
      );
      if (!mounted) return;
      if (success) {
        _pollTimer?.cancel();
        setState(() => _payState = 'failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.tr('payment_status_cancelled')),
            backgroundColor: JewelryColors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.tr('payment_operation_retry')),
            backgroundColor: JewelryColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.tr('payment_operation_retry')),
            backgroundColor: JewelryColors.error,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.88),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String method,
    String label,
    IconData icon,
    Color iconColor,
    Color textColor,
  ) {
    final selected = _selectedMethod == method;
    final canChange = _payState != 'waiting' && _payState != 'creating';

    return GestureDetector(
      onTap: canChange ? () => setState(() => _selectedMethod = method) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? JewelryColors.emeraldGlow.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? JewelryColors.emeraldGlow.withOpacity(0.22)
                : JewelryColors.champagneGold.withOpacity(0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: iconColor.withOpacity(0.16)),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: JewelryColors.emeraldGlow,
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_off,
                color: JewelryColors.jadeMist.withOpacity(0.28),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ScaleTransition(
          scale: _successScale,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration:
                _paymentGlassDecoration(radius: 30, borderOpacity: 0.18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: JewelryColors.emeraldLusterGradient,
                    boxShadow: [
                      BoxShadow(
                        color: JewelryColors.emeraldGlow.withOpacity(0.34),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: JewelryColors.jadeBlack,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  ref.tr('payment_success_title'),
                  style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '¥ ${widget.order.totalPaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: JewelryColors.champagneGold,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: JewelryColors.emeraldGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: JewelryColors.emeraldGlow.withOpacity(0.16),
                    ),
                  ),
                  child: Text(
                    ref.tr('redirecting_to_order'),
                    style: TextStyle(
                      color: JewelryColors.jadeMist.withOpacity(0.68),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PaymentMethod _methodFromCode(String? raw) {
    switch (raw) {
      case 'wechat':
        return PaymentMethod.wechat;
      case 'balance':
      case 'unionpay':
        return PaymentMethod.unionpay;
      case 'alipay':
      default:
        return PaymentMethod.alipay;
    }
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
