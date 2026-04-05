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
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../themes/colors.dart';
import '../../widgets/common/error_handler.dart';
import '../order/order_list_screen.dart';

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
      message: 'payment_waiting_admin_confirm'.tr,
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

      setState(() {
        _paymentStatus = result;
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
            SnackBar(content: Text('payment_operation_retry'.tr)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('payment_page_title'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _payState == 'success'
          ? _buildSuccessView()
          : _buildPaymentView(isDark),
    );
  }

  Widget _buildPaymentView(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2332) : Colors.white;
    final textPrimary = isDark ? Colors.white : JewelryColors.textPrimary;
    final textSecondary = isDark ? Colors.white70 : JewelryColors.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAmountCard(),
          const SizedBox(height: 20),
          _buildOrderInfoCard(cardBg, textPrimary, textSecondary),
          const SizedBox(height: 20),
          _buildMethodCard(cardBg, textPrimary),
          if (_paymentStatus?.paymentAccount != null) ...[
            const SizedBox(height: 20),
            _buildCollectionCard(cardBg, textPrimary, textSecondary),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF2E8B57), Color(0xFF1A6B3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B57).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'payment_amount_title'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '¥ ${widget.order.totalPaid.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ref.tr('payment_remaining_time',
                  params: {'time': _formattedCountdown}),
              style: TextStyle(
                color: _remainingSeconds < 60 ? Colors.redAccent : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(
      Color cardBg, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark(context) ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment_order_info'.tr,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(ref.tr('order_number'), widget.order.id, textSecondary),
          _buildInfoRow(
            ref.tr('product_info_section'),
            widget.order.localizedProductName,
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

  Widget _buildMethodCard(Color cardBg, Color textPrimary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark(context) ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment_method_title'.tr,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            'wechat',
            'payment_method_wechat'.tr,
            Icons.chat_bubble_rounded,
            const Color(0xFF07C160),
            textPrimary,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            'alipay',
            'payment_method_alipay'.tr,
            Icons.account_balance_wallet_rounded,
            const Color(0xFF1677FF),
            textPrimary,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            'unionpay',
            'payment_bank_transfer'.tr,
            Icons.account_balance_rounded,
            const Color(0xFF1A3E7C),
            textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    final account = _paymentStatus?.paymentAccount;
    if (account == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark(context) ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment_collection_info'.tr,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JewelryColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _paymentStatus?.message ?? 'payment_waiting_admin_confirm'.tr,
              style: TextStyle(
                color: JewelryColors.primaryDark,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (account.qrCodeUrl != null && account.qrCodeUrl!.trim().isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _resolveImageUrl(account.qrCodeUrl!),
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildQrFallback(textSecondary),
                ),
              ),
            )
          else
            Center(child: _buildQrFallback(textSecondary)),
          const SizedBox(height: 16),
          _buildInfoRow(
            'payment_account_type'.tr,
            account.typeName.tr,
            textSecondary,
          ),
          _buildInfoRow(
            'payment_account_name'.tr,
            account.name,
            textSecondary,
          ),
          if (account.accountNumber != null &&
              account.accountNumber!.isNotEmpty)
            _buildInfoRow(
              'payment_account_number'.tr,
              account.accountNumber!,
              textSecondary,
            ),
          if (account.bankName != null && account.bankName!.isNotEmpty)
            _buildInfoRow(
              'payment_bank_name'.tr,
              account.bankName!,
              textSecondary,
            ),
          if ((_paymentStatus?.paymentId ?? '').isNotEmpty)
            _buildInfoRow(
              'payment_record_number'.tr,
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
        color: JewelryColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'payment_qr_unavailable'.tr,
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
                backgroundColor: JewelryColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: Text(
                'payment_refresh_status'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                side: const BorderSide(color: JewelryColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('payment_change_method'.tr),
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
              child: Text('payment_cancel_payment'.tr),
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
              backgroundColor: JewelryColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'payment_submitting'.tr,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                : Text(
                    'payment_submit_transfer'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                side: const BorderSide(color: JewelryColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('payment_retry'.tr),
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
        backgroundColor: isDark(context) ? const Color(0xFF1A2332) : Colors.white,
        title: Text('payment_cancel_confirm'.tr),
        content: Text('payment_cancel_prompt'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: JewelryColors.error),
            child: Text('common_confirm'.tr),
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
            content: Text('payment_status_cancelled'.tr),
            backgroundColor: JewelryColors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('payment_operation_retry'.tr),
            backgroundColor: JewelryColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('payment_operation_retry'.tr),
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
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
              ? JewelryColors.primary.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected ? JewelryColors.primary : Colors.grey.withOpacity(0.2),
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
                borderRadius: BorderRadius.circular(10),
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
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: JewelryColors.primary,
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_off,
                color: Colors.grey.withOpacity(0.4),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: ScaleTransition(
        scale: _successScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: JewelryColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: JewelryColors.primaryGreen,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'payment_success_title'.tr,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '¥ ${widget.order.totalPaid.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'redirecting_to_order'.tr,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
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

  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
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
