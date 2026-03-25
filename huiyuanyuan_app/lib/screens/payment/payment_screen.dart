/// 汇玉源 - 支付页面
///
/// 功能:
/// - 订单信息卡片
/// - 支付方式选择(微信/支付宝/余额)
/// - 15分钟倒计时
/// - 轮询支付状态
/// - 支付成功动画
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/colors.dart';
import '../../models/order_model.dart' hide PaymentMethod;
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/error_handler.dart';
import '../order/order_list_screen.dart';

/// 支付页面
class PaymentScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const PaymentScreen({super.key, required this.order});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with TickerProviderStateMixin {
  // 支付方式
  String _selectedMethod = 'wechat';
  // 状态: idle / processing / success / failed
  String _payState = 'idle';
  // 倒计时 (15分钟 = 900秒)
  int _remainingSeconds = 900;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  // 动画
  late AnimationController _successController;
  late Animation<double> _successScale;
  // PaymentService
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _successController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (_payState == 'idle') {
          setState(() => _payState = 'failed');
        }
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  String get _formattedCountdown {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _startPayment() async {
    setState(() => _payState = 'processing');
    _pollTimer?.cancel();

    try {
      final payMethod = _selectedMethod == 'wechat'
          ? PaymentMethod.wechat
          : _selectedMethod == 'alipay'
              ? PaymentMethod.alipay
              : PaymentMethod.balance;

      await _paymentService.createPaymentOrder(
        orderId: widget.order.id,
        amount: widget.order.amount,
        method: payMethod,
      );

      await _paymentService.submitOrderPayment(
        orderId: widget.order.id,
        method: payMethod,
      );

      int pollCount = 0;
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        pollCount++;
        if (pollCount > 30 || !mounted) {
          timer.cancel();
          if (_payState == 'processing' && mounted) {
            // 超时，提示用户检查支付状态，稍后自动 mock 成功
            setState(() => _payState = 'failed');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('支付超时，请检查支付是否成功，稍后重试'),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
          return;
        }

        try {
          final result = await _paymentService.queryOrderPaymentStatus(
            widget.order.id,
          );
          if (result?.isSuccess ?? false) {
            timer.cancel();
            _onPaymentSuccess();
            return;
          }
        } catch (_) {
          // 继续轮询
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _payState = 'failed');
        context.showError(e);
      }
    }
  }

  void _onPaymentSuccess() {
    if (!mounted || _payState == 'success') return;

    // 在调试模式下使用本地模拟更新订单状态
    // 生产环境应由后端 webhook 触发
    if (kDebugMode) {
      ref.read(orderProvider.notifier).simulatePayment(
        widget.order.id,
      );
    }

    setState(() => _payState = 'success');
    _countdownTimer?.cancel();
    _successController.forward();

    // 2秒后跳转
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const OrderListScreen(initialTab: 2),
          ),
          (route) => route.isFirst,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('确认支付'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _payState == 'success' ? _buildSuccessView() : _buildPaymentView(isDark),
    );
  }

  Widget _buildPaymentView(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2332) : Colors.white;
    final textPri = isDark ? Colors.white : JewelryColors.textPrimary;
    final textSec = isDark ? Colors.white70 : JewelryColors.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 金额卡片
          Container(
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
                const Text(
                  '支付金额',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '¥ ${widget.order.amount.toStringAsFixed(2)}',
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
                    '剩余支付时间 $_formattedCountdown',
                    style: TextStyle(
                      color: _remainingSeconds < 60 ? Colors.redAccent : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 订单信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('订单信息',
                    style: TextStyle(color: textPri, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildInfoRow('订单号', widget.order.id, textSec),
                _buildInfoRow('商品', widget.order.productName, textSec),
                _buildInfoRow('数量', '${widget.order.quantity} 件', textSec),
                if (widget.order.shippingAddress != null && widget.order.shippingAddress!.isNotEmpty)
                  _buildInfoRow('收货地址', widget.order.shippingAddress!, textSec),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 支付方式
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('支付方式',
                    style: TextStyle(color: textPri, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildPaymentOption(
                  'wechat',
                  '微信支付',
                  Icons.chat_bubble_rounded,
                  const Color(0xFF07C160),
                  textPri,
                ),
                const SizedBox(height: 10),
                _buildPaymentOption(
                  'alipay',
                  '支付宝',
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFF1677FF),
                  textPri,
                ),
                const SizedBox(height: 10),
                _buildPaymentOption(
                  'balance',
                  '余额支付',
                  Icons.savings_rounded,
                  JewelryColors.gold,
                  textPri,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 确认支付按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _payState == 'processing' || _remainingSeconds <= 0
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
              child: _payState == 'processing'
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('支付中...', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : const Text(
                      '确认支付',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    _remainingSeconds = 900;
                  });
                  _countdownTimer?.cancel();
                  _startCountdown();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: JewelryColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('重新支付'),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(color: textColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
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
    String method, String label, IconData icon, Color iconColor, Color textColor,
  ) {
    final selected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? JewelryColors.primary.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? JewelryColors.primary
                : Colors.grey.withOpacity(0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
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
              const Icon(Icons.check_circle, color: JewelryColors.primary, size: 22)
            else
              Icon(Icons.radio_button_off, color: Colors.grey.withOpacity(0.4), size: 22),
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
              width: 100, height: 100,
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
            const Text(
              '支付成功',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '¥ ${widget.order.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '正在跳转订单页...',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
