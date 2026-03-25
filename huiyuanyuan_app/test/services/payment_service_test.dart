// 汇玉源 - 支付服务测试
//
// 测试内容:
// - 支付订单创建
// - 支付状态查询
// - 退款申请
// - 支付方式枚举
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuanyuan/services/payment_service.dart';

void main() {
  late PaymentService paymentService;

  setUp(() {
    paymentService = PaymentService();
  });

  group('PaymentMethod 枚举测试', () {
    test('PaymentMethod 应包含所有支付方式', () {
      expect(PaymentMethod.values.length, 4);
      expect(PaymentMethod.values.contains(PaymentMethod.wechat), true);
      expect(PaymentMethod.values.contains(PaymentMethod.alipay), true);
      expect(PaymentMethod.values.contains(PaymentMethod.unionpay), true);
      expect(PaymentMethod.values.contains(PaymentMethod.balance), true);
    });

    test('PaymentMethod label 应正确', () {
      expect(PaymentMethod.wechat.label, '微信支付');
      expect(PaymentMethod.alipay.label, '支付宝');
      expect(PaymentMethod.unionpay.label, '银联支付');
      expect(PaymentMethod.balance.label, '余额支付');
    });

    test('PaymentMethod code 应正确', () {
      expect(PaymentMethod.wechat.code, 'wechat');
      expect(PaymentMethod.alipay.code, 'alipay');
      expect(PaymentMethod.unionpay.code, 'unionpay');
      expect(PaymentMethod.balance.code, 'balance');
    });
  });

  group('PaymentStatus 枚举测试', () {
    test('PaymentStatus 应包含所有状态', () {
      expect(PaymentStatus.values.length, 7);
    });

    test('PaymentStatus label 应正确', () {
      expect(PaymentStatus.pending.label, '待支付');
      expect(PaymentStatus.processing.label, '支付中');
      expect(PaymentStatus.success.label, '支付成功');
      expect(PaymentStatus.failed.label, '支付失败');
      expect(PaymentStatus.cancelled.label, '已取消');
      expect(PaymentStatus.refunding.label, '退款中');
      expect(PaymentStatus.refunded.label, '已退款');
    });
  });

  group('PaymentOrder 模型测试', () {
    test('fromJson 应正确解析', () {
      final json = {
        'id': 'PAY-001',
        'order_id': 'ORD-001',
        'amount': 299.0,
        'method': 'wechat',
        'status': 'success',
        'transaction_id': 'TXN-001',
        'created_at': '2026-02-01T10:00:00',
        'paid_at': '2026-02-01T10:05:00',
      };

      final order = PaymentOrder.fromJson(json);

      expect(order.id, 'PAY-001');
      expect(order.orderId, 'ORD-001');
      expect(order.amount, 299.0);
      expect(order.method, PaymentMethod.wechat);
      expect(order.status, PaymentStatus.success);
      expect(order.transactionId, 'TXN-001');
    });

    test('toJson 应正确转换', () {
      final order = PaymentOrder(
        id: 'PAY-002',
        orderId: 'ORD-002',
        amount: 599.0,
        method: PaymentMethod.alipay,
        status: PaymentStatus.pending,
        createdAt: DateTime(2026, 2, 1, 10, 0),
      );

      final json = order.toJson();

      expect(json['id'], 'PAY-002');
      expect(json['order_id'], 'ORD-002');
      expect(json['amount'], 599.0);
      expect(json['method'], 'alipay');
      expect(json['status'], 'pending');
    });

    test('应处理缺失的可选字段', () {
      final json = {
        'id': 'PAY-003',
        'order_id': 'ORD-003',
        'amount': 199.0,
        'method': 'balance',
        'status': 'pending',
        'created_at': '2026-02-01T10:00:00',
      };

      final order = PaymentOrder.fromJson(json);

      expect(order.transactionId, isNull);
      expect(order.paidAt, isNull);
      expect(order.errorMessage, isNull);
    });
  });

  group('创建支付订单测试', () {
    test('创建微信支付订单应成功', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-TEST-001',
        amount: 299.0,
        method: PaymentMethod.wechat,
        description: '测试商品',
      );

      expect(order, isNotNull);
      expect(order.orderId, 'ORD-TEST-001');
      expect(order.amount, 299.0);
      expect(order.method, PaymentMethod.wechat);
      expect(order.status, PaymentStatus.pending);
    });

    test('创建支付宝订单应成功', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-TEST-002',
        amount: 599.0,
        method: PaymentMethod.alipay,
      );

      expect(order, isNotNull);
      expect(order.method, PaymentMethod.alipay);
    });

    test('创建余额支付订单应成功', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-TEST-003',
        amount: 199.0,
        method: PaymentMethod.balance,
      );

      expect(order, isNotNull);
      expect(order.method, PaymentMethod.balance);
    });

    test('不同订单应生成不同ID', () async {
      final order1 = await paymentService.createPaymentOrder(
        orderId: 'ORD-TEST-004',
        amount: 100.0,
        method: PaymentMethod.wechat,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      final order2 = await paymentService.createPaymentOrder(
        orderId: 'ORD-TEST-005',
        amount: 100.0,
        method: PaymentMethod.wechat,
      );

      expect(order1.id, isNot(equals(order2.id)));
    });
  });

  group('微信支付测试', () {
    test('发起微信支付应返回支付参数', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-WECHAT-001',
        amount: 299.0,
        method: PaymentMethod.wechat,
      );

      final params = await paymentService.initiateWechatPay(order);

      expect(params, isNotNull);
      expect(params.appId, isNotEmpty);
      expect(params.partnerId, isNotEmpty);
      expect(params.prepayId, isNotEmpty);
      expect(params.sign, isNotEmpty);
    });

    test('微信支付参数应包含必要字段', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-WECHAT-002',
        amount: 599.0,
        method: PaymentMethod.wechat,
      );

      final params = await paymentService.initiateWechatPay(order);
      final json = params.toJson();

      expect(json.containsKey('appId'), true);
      expect(json.containsKey('partnerId'), true);
      expect(json.containsKey('prepayId'), true);
      expect(json.containsKey('package'), true);
      expect(json.containsKey('nonceStr'), true);
      expect(json.containsKey('timeStamp'), true);
      expect(json.containsKey('sign'), true);
    });
  });

  group('支付宝支付测试', () {
    test('发起支付宝支付应返回支付字符串', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-ALIPAY-001',
        amount: 299.0,
        method: PaymentMethod.alipay,
      );

      final payRequest = await paymentService.initiateAlipay(order);

      expect(payRequest.orderString, isNotEmpty);
    });

    test('支付宝支付字符串应包含必要信息', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-ALIPAY-002',
        amount: 1280.0,
        method: PaymentMethod.alipay,
      );

      final payRequest = await paymentService.initiateAlipay(order);

      expect(payRequest.orderString.contains('alipay'), true);
    });
  });

  group('支付状态查询测试', () {
    test('查询支付状态应返回状态', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-STATUS-001',
        amount: 299.0,
        method: PaymentMethod.wechat,
      );

      final status = await paymentService.queryPaymentStatus(order.id);

      expect(status, isNotNull);
      expect(status, PaymentStatus.pending);
    });
  });

  group('模拟支付成功测试', () {
    test('模拟支付成功应更新状态', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-SIM-001',
        amount: 299.0,
        method: PaymentMethod.wechat,
      );

      final paidOrder = await paymentService.simulatePaymentSuccess(order);

      expect(paidOrder.status, PaymentStatus.success);
      expect(paidOrder.transactionId, isNotNull);
      expect(paidOrder.paidAt, isNotNull);
    });
  });

  group('取消支付测试', () {
    test('取消支付应成功', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-CANCEL-001',
        amount: 299.0,
        method: PaymentMethod.wechat,
      );

      final result = await paymentService.cancelPayment(order.id);

      expect(result, true);
    });
  });

  group('退款测试', () {
    test('申请退款应成功', () async {
      final result = await paymentService.requestRefund(
        orderId: 'ORD-REFUND-001',
        paymentId: 'PAY-REFUND-001',
        amount: 299.0,
        reason: '用户申请退款',
      );

      expect(result.success, true);
      expect(result.refundId, isNotEmpty);
      expect(result.message, isNotEmpty);
    });

    test('退款申请应包含退款ID', () async {
      final result = await paymentService.requestRefund(
        orderId: 'ORD-REFUND-002',
        paymentId: 'PAY-REFUND-002',
        amount: 599.0,
      );

      expect(result.refundId, isNotEmpty);
      expect(result.refundId.contains('REFUND'), true);
    });

    test('查询退款状态应返回结果', () async {
      final result = await paymentService.queryRefundStatus('REFUND-TEST-001');

      expect(result, isNotNull);
      expect(result.refundId, 'REFUND-TEST-001');
      expect(result.status, RefundStatus.processing);
    });
  });

  group('辅助方法测试', () {
    test('getPaymentIcon 应返回正确图标', () {
      expect(PaymentService.getPaymentIcon(PaymentMethod.wechat), '💚');
      expect(PaymentService.getPaymentIcon(PaymentMethod.alipay), '💙');
      expect(PaymentService.getPaymentIcon(PaymentMethod.unionpay), '❤️');
      expect(PaymentService.getPaymentIcon(PaymentMethod.balance), '💰');
    });

    test('formatAmount 应正确格式化金额', () {
      expect(PaymentService.formatAmount(299.0), '¥299.00');
      expect(PaymentService.formatAmount(99.5), '¥99.50');
      expect(PaymentService.formatAmount(1000.0), '¥1000.00');
      expect(PaymentService.formatAmount(0.0), '¥0.00');
    });
  });

  group('边界情况测试', () {
    test('零金额订单应能创建', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-ZERO-001',
        amount: 0.0,
        method: PaymentMethod.balance,
      );

      expect(order.amount, 0.0);
    });

    test('大金额订单应能创建', () async {
      final order = await paymentService.createPaymentOrder(
        orderId: 'ORD-LARGE-001',
        amount: 999999.99,
        method: PaymentMethod.wechat,
      );

      expect(order.amount, 999999.99);
    });

    test('退款金额可以等于支付金额', () async {
      final result = await paymentService.requestRefund(
        orderId: 'ORD-FULL-REFUND',
        paymentId: 'PAY-FULL-REFUND',
        amount: 299.0,
      );

      expect(result.success, true);
    });
  });

  group('支付响应 DTO 测试', () {
    test('订单支付状态应正确解析', () {
      final result = OrderPaymentStatusResult.fromJson({
        'status': 'success',
        'payment_id': 'PAY-STATUS-001',
        'message': '支付成功',
      });

      expect(result.isSuccess, true);
      expect(result.paymentId, 'PAY-STATUS-001');
      expect(result.message, '支付成功');
    });

    test('微信支付参数 toJson 应保留 package 字段', () {
      const params = WechatPayParams(
        appId: 'wx-app',
        partnerId: 'mch-1',
        prepayId: 'prepay-1',
        packageValue: 'Sign=WXPay',
        nonceStr: 'nonce',
        timeStamp: '123456',
        sign: 'sign',
      );

      final json = params.toJson();

      expect(json['package'], 'Sign=WXPay');
    });
  });

  group('PaymentConfig 测试', () {
    test('PaymentConfig 应包含必要配置', () {
      expect(PaymentConfig.wechatMchId, isNotNull);
      expect(PaymentConfig.wechatAppId, isNotNull);
      expect(PaymentConfig.alipayAppId, isNotNull);
      expect(PaymentConfig.notifyUrl, isNotNull);
    });

    test('PaymentConfig 沙箱模式应默认开启', () {
      expect(PaymentConfig.isSandbox, true);
    });
  });
}
