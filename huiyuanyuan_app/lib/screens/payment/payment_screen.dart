/// \u6C47\u7389\u6E90 - \u652F\u4ED8\u9875\u9762
///
/// \u529F\u80FD:
/// - \u8BA2\u5355\u4FE1\u606F\u5361\u7247
/// - \u652F\u4ED8\u65B9\u5F0F\u9009\u62E9(\u5FAE\u4FE1/\u652F\u4ED8\u5B9D/\u4F59\u989D)
/// - 15\u5206\u949F\u5012\u8BA1\u65F6
/// - \u8F6E\u8BE2\u652F\u4ED8\u72B6\u6001
/// - \u652F\u4ED8\u6210\u529F\u52A8\u753B
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/colors.dart';
import '../../models/order_model.dart' hide PaymentMethod;
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../order/order_list_screen.dart';

/// \u652F\u4ED8\u9875\u9762
class PaymentScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const PaymentScreen({super.key, required this.order});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with TickerProviderStateMixin {
  // \u652F\u4ED8\u65B9\u5F0F
  String _selectedMethod = 'wechat';
  // \u72B6\u6001: idle / processing / success / failed
  String _payState = 'idle';
  // \u5012\u8BA1\u65F6 (15\u5206\u949F = 900\u79D2)
  int _remainingSeconds = 900;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  // \u52A8\u753B
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

    try {
      // 1. ͨ�� PaymentService ����֧����
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

      // 2. ͨ�� ApiService ���ú�� /pay �˵㣨ͳһ��Ȩ������ʹ�� mock_token��
      final api = ApiService();
      try {
        await api.post<dynamic>(
          '${ApiConfig.orderDetail(widget.order.id)}/pay',
          data: {'method': _selectedMethod},
        );
      } catch (_) {
        // ��˲�����ʱ������ѯ
      }

      // 3. ��ѯ֧��״̬��ÿ��һ�Σ����30�� = 30�룬��ʱ����ʾ�û���
      int pollCount = 0;
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        pollCount++;
        if (pollCount > 30 || !mounted) {
          timer.cancel();
          if (_payState == 'processing' && mounted) {
            // ��ʱ����ʾ�û����֧��״̬�������Զ� mock �ɹ�
            setState(() => _payState = 'failed');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('֧����ʱ������֧���Ƿ�ɹ����Ժ�����'),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
          return;
        }

        // ��ѯ���֧��״̬
        try {
          final result = await api.get<dynamic>(
            '${ApiConfig.orderDetail(widget.order.id)}/pay-status',
          );
          if (result.success) {
            final data = result.data;
            if (data is Map && data['status'] == 'success') {
              timer.cancel();
              _onPaymentSuccess();
              return;
            }
          }
        } catch (_) {
          // ������ѯ
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _payState = 'failed');
      }
    }
  }

  void _onPaymentSuccess() {
    if (!mounted || _payState == 'success') return;

    // ���ڿ���ģʽ��ʹ�ñ���ģ����¶���״̬
    // ��������Ӧ�ɺ�� webhook ����
    if (kDebugMode) {
      ref.read(orderProvider.notifier).simulatePayment(
        widget.order.id,
      );
    }

    setState(() => _payState = 'success');
    _countdownTimer?.cancel();
    _successController.forward();

    // 2\u79D2\u540E\u8DF3\u8F6C
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
        title: const Text('\u786E\u8BA4\u652F\u4ED8'),
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
          // \u91D1\u989D\u5361\u7247
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
                  '\u652F\u4ED8\u91D1\u989D',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '\u00A5 ${widget.order.amount.toStringAsFixed(2)}',
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
                    '\u5269\u4F59\u652F\u4ED8\u65F6\u95F4 $_formattedCountdown',
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

          // \u8BA2\u5355\u4FE1\u606F
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
                Text('\u8BA2\u5355\u4FE1\u606F',
                    style: TextStyle(color: textPri, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildInfoRow('\u8BA2\u5355\u53F7', widget.order.id, textSec),
                _buildInfoRow('\u5546\u54C1', widget.order.productName, textSec),
                _buildInfoRow('\u6570\u91CF', '${widget.order.quantity} \u4EF6', textSec),
                if (widget.order.shippingAddress != null && widget.order.shippingAddress!.isNotEmpty)
                  _buildInfoRow('\u6536\u8D27\u5730\u5740', widget.order.shippingAddress!, textSec),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // \u652F\u4ED8\u65B9\u5F0F
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
                Text('\u652F\u4ED8\u65B9\u5F0F',
                    style: TextStyle(color: textPri, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildPaymentOption(
                  'wechat',
                  '\u5FAE\u4FE1\u652F\u4ED8',
                  Icons.chat_bubble_rounded,
                  const Color(0xFF07C160),
                  textPri,
                ),
                const SizedBox(height: 10),
                _buildPaymentOption(
                  'alipay',
                  '\u652F\u4ED8\u5B9D',
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFF1677FF),
                  textPri,
                ),
                const SizedBox(height: 10),
                _buildPaymentOption(
                  'balance',
                  '\u4F59\u989D\u652F\u4ED8',
                  Icons.savings_rounded,
                  JewelryColors.gold,
                  textPri,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // \u786E\u8BA4\u652F\u4ED8\u6309\u94AE
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
                        Text('\u652F\u4ED8\u4E2D...', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : const Text(
                      '\u786E\u8BA4\u652F\u4ED8',
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
                child: const Text('\u91CD\u65B0\u652F\u4ED8'),
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
              '\u652F\u4ED8\u6210\u529F',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '\u00A5 ${widget.order.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u6B63\u5728\u8DF3\u8F6C\u8BA2\u5355\u9875...',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
