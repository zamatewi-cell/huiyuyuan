import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/payment_account.dart';
import '../services/api_service.dart';

enum PaymentLoadingState { initial, loading, loaded, error }

class PaymentAccountsState {
  final List<PaymentAccount> accounts;
  final PaymentLoadingState state;
  final String? errorMessage;

  PaymentAccountsState({
    this.accounts = const [],
    this.state = PaymentLoadingState.initial,
    this.errorMessage,
  });

  PaymentAccountsState copyWith({
    List<PaymentAccount>? accounts,
    PaymentLoadingState? state,
    String? errorMessage,
  }) {
    return PaymentAccountsState(
      accounts: accounts ?? this.accounts,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PaymentAccountNotifier extends StateNotifier<PaymentAccountsState> {
  final ApiService _apiService;

  PaymentAccountNotifier(this._apiService)
      : super(PaymentAccountsState()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    state = state.copyWith(state: PaymentLoadingState.loading);

    final result = await _apiService.get<List<dynamic>>(
      ApiConfig.paymentAccounts,
    );

    if (result.success && result.data != null) {
      final accounts = result.data!
          .map((json) => PaymentAccount.fromMap(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        accounts: accounts,
        state: PaymentLoadingState.loaded,
      );
    } else {
      state = state.copyWith(
        state: PaymentLoadingState.error,
        errorMessage: result.message ?? '加载失败',
      );
    }
  }

  Future<bool> addAccount(PaymentAccount account) async {
    final result = await _apiService.post<Map<String, dynamic>>(
      ApiConfig.paymentAccounts,
      data: account.toCreateMap(),
    );

    if (result.success && result.data != null) {
      final newAccount = PaymentAccount.fromMap(result.data!);
      state = state.copyWith(
        accounts: [...state.accounts, newAccount],
      );
      return true;
    }
    return false;
  }

  Future<bool> updateAccount(PaymentAccount account) async {
    final result = await _apiService.put<Map<String, dynamic>>(
      ApiConfig.paymentAccountDetail(account.id),
      data: account.toCreateMap(),
    );

    if (result.success && result.data != null) {
      final updatedAccount = PaymentAccount.fromMap(result.data!);
      state = state.copyWith(
        accounts: [
          for (final existing in state.accounts)
            if (existing.id == account.id) updatedAccount else existing,
        ],
      );
      return true;
    }
    return false;
  }

  Future<bool> deleteAccount(String id) async {
    final result = await _apiService.delete<Map<String, dynamic>>(
      ApiConfig.paymentAccountDetail(id),
    );

    if (result.success) {
      state = state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> toggleActive(String id) async {
    final account = state.accounts.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Account not found'),
    );

    final updated = account.copyWith(isActive: !account.isActive);
    return updateAccount(updated);
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final paymentAccountsProvider =
    StateNotifierProvider<PaymentAccountNotifier, PaymentAccountsState>(
  (ref) {
    final apiService = ref.watch(apiServiceProvider);
    return PaymentAccountNotifier(apiService);
  },
);
