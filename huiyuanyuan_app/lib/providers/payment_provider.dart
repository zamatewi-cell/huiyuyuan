import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_account.dart';

const String kPaymentAccountsKey = 'payment_accounts_v1';

class PaymentAccountNotifier extends StateNotifier<List<PaymentAccount>> {
  PaymentAccountNotifier() : super([]) {
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accountsJson = prefs.getString(kPaymentAccountsKey);
      if (accountsJson != null) {
        final List<dynamic> decoded = json.decode(accountsJson);
        state = decoded.map((e) => PaymentAccount.fromMap(e)).toList();
      } else {
        // Init with some default mockup data if empty
        state = [
          PaymentAccount(
            id: const Uuid().v4(),
            name: '公司主账户',
            type: PaymentType.bank,
            bankName: '招商银行',
            accountNumber: '6225 **** **** 8888',
          ),
          PaymentAccount(
            id: const Uuid().v4(),
            name: '门店收款码',
            type: PaymentType.wechat,
          ),
        ];
        _saveAccounts();
      }
    } catch (e) {
      // Handle error quietly or log
      // print('Error loading payment accounts: $e');
    }
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(state.map((e) => e.toMap()).toList());
    await prefs.setString(kPaymentAccountsKey, encoded);
  }

  Future<void> addAccount(PaymentAccount account) async {
    state = [...state, account];
    await _saveAccounts();
  }

  Future<void> updateAccount(PaymentAccount account) async {
    state = [
      for (final acc in state)
        if (acc.id == account.id) account else acc
    ];
    await _saveAccounts();
  }

  Future<void> deleteAccount(String id) async {
    state = state.where((acc) => acc.id != id).toList();
    await _saveAccounts();
  }

  Future<void> toggleActive(String id) async {
    state = [
      for (final acc in state)
        if (acc.id == id) acc.copyWith(isActive: !acc.isActive) else acc
    ];
    await _saveAccounts();
  }
}

final paymentAccountsProvider =
    StateNotifierProvider<PaymentAccountNotifier, List<PaymentAccount>>((ref) {
  return PaymentAccountNotifier();
});
