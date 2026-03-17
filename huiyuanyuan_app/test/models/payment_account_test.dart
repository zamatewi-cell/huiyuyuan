import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuanyuan/models/payment_account.dart';

void main() {
  group('PaymentAccount', () {
    test('supports value comparisons', () {
      final account1 = PaymentAccount(
        id: '1',
        name: 'Account 1',
        type: PaymentType.bank,
        accountNumber: '123',
        bankName: 'Bank A',
      );
      
      // Since specific equality operator isn't overridden in the model we created, 
      // we check field equality or we can assume Equatable isn't used yet.
      // Based on the code I wrote, it doesn't use Equatable.
      // So we test fields.
      
      expect(account1.id, '1');
      expect(account1.name, 'Account 1');
      expect(account1.type, PaymentType.bank);
    });

    test('typeName returns correct string', () {
      final bank = PaymentAccount(id: '1', name: 'A', type: PaymentType.bank);
      final alipay = PaymentAccount(id: '2', name: 'B', type: PaymentType.alipay);
      
      expect(bank.typeName, '银行卡');
      expect(alipay.typeName, '支付宝');
    });

    test('toJson and fromJson work correctly', () {
      final account = PaymentAccount(
        id: '1',
        name: 'Test Account',
        type: PaymentType.wechat,
        accountNumber: 'test_id',
        isActive: false,
      );

      final jsonStr = account.toJson();
      final newAccount = PaymentAccount.fromJson(jsonStr);

      expect(newAccount.id, account.id);
      expect(newAccount.name, account.name);
      expect(newAccount.type, account.type);
      expect(newAccount.isActive, account.isActive);
    });

    test('copyWith works correctly', () {
      final account = PaymentAccount(
        id: '1',
        name: 'Original',
        type: PaymentType.cash,
      );

      final updated = account.copyWith(name: 'Updated', isActive: false);

      expect(updated.id, '1');
      expect(updated.name, 'Updated');
      expect(updated.isActive, false);
      // Original should be unchanged
      expect(account.name, 'Original'); 
    });
  });
}
