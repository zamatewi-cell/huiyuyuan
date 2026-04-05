import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/payment_account.dart';

void main() {
  group('PaymentAccount', () {
    test('typeName returns localized labels', () {
      const bank = PaymentAccount(
        id: '1',
        name: 'A',
        type: PaymentType.bank,
      );
      const alipay = PaymentAccount(
        id: '2',
        name: 'B',
        type: PaymentType.alipay,
      );

      expect(bank.typeName, '银行卡');
      expect(alipay.typeName, '支付宝');
    });

    test('toCreateMap uses backend snake_case fields', () {
      final account = PaymentAccount.create(
        name: '主收款账户',
        type: PaymentType.wechat,
        accountNumber: 'wechat://pay-code',
        qrCodeUrl: 'https://example.com/qr.png',
        isDefault: true,
      );

      expect(account.toCreateMap(), {
        'name': '主收款账户',
        'type': 'wechat',
        'account_number': 'wechat://pay-code',
        'bank_name': null,
        'qr_code_url': 'https://example.com/qr.png',
        'is_active': true,
        'is_default': true,
      });
    });

    test('fromMap parses backend payload shape', () {
      final account = PaymentAccount.fromMap({
        'id': 'acc_001',
        'user_id': 'user_001',
        'name': '公司账户',
        'account_number': '6222',
        'bank_name': 'ICBC',
        'type': 'bank',
        'qr_code_url': null,
        'is_active': true,
        'is_default': true,
        'created_at': '2026-03-18T12:00:00Z',
        'updated_at': '2026-03-18T12:30:00Z',
      });

      expect(account.id, 'acc_001');
      expect(account.userId, 'user_001');
      expect(account.type, PaymentType.bank);
      expect(account.isDefault, isTrue);
      expect(account.createdAt?.toUtc().toIso8601String(),
          '2026-03-18T12:00:00.000Z');
      expect(account.updatedAt?.toUtc().toIso8601String(),
          '2026-03-18T12:30:00.000Z');
    });

    test('copyWith can clear nullable fields', () {
      const original = PaymentAccount(
        id: '1',
        name: '原账户',
        type: PaymentType.bank,
        accountNumber: '6222',
        bankName: 'ABC',
      );

      final updated = original.copyWith(
        accountNumber: null,
        bankName: null,
        isActive: false,
      );

      expect(updated.accountNumber, isNull);
      expect(updated.bankName, isNull);
      expect(updated.isActive, isFalse);
      expect(original.accountNumber, '6222');
      expect(original.bankName, 'ABC');
    });

    test('toJson and fromJson preserve round-trip fields', () {
      const account = PaymentAccount(
        id: '1',
        userId: 'user_001',
        name: '测试账户',
        type: PaymentType.cash,
        isActive: false,
        isDefault: true,
      );

      final restored = PaymentAccount.fromJson(account.toJson());

      expect(restored.id, account.id);
      expect(restored.userId, account.userId);
      expect(restored.type, account.type);
      expect(restored.isActive, account.isActive);
      expect(restored.isDefault, account.isDefault);
    });
  });
}
