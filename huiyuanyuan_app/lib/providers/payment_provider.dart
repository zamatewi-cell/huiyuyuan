import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_account.dart';
import '../repositories/payment_account_repository.dart';
import '../services/api_service.dart';

enum PaymentLoadingState { initial, loading, loaded, error }

const Object _paymentErrorUnchanged = Object();

class PaymentAccountsState {
  final List<PaymentAccount> accounts;
  final PaymentLoadingState state;
  final String? errorMessage;

  const PaymentAccountsState({
    this.accounts = const [],
    this.state = PaymentLoadingState.initial,
    this.errorMessage,
  });

  PaymentAccountsState copyWith({
    List<PaymentAccount>? accounts,
    PaymentLoadingState? state,
    Object? errorMessage = _paymentErrorUnchanged,
  }) {
    return PaymentAccountsState(
      accounts: accounts ?? this.accounts,
      state: state ?? this.state,
      errorMessage: identical(errorMessage, _paymentErrorUnchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class PaymentAccountNotifier extends StateNotifier<PaymentAccountsState> {
  final PaymentAccountRepository _repository;

  PaymentAccountNotifier(ApiService apiService)
      : this.withRepository(PaymentAccountRepository(apiService: apiService));

  PaymentAccountNotifier.withRepository(this._repository)
      : super(const PaymentAccountsState()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    state = state.copyWith(
      state: PaymentLoadingState.loading,
      errorMessage: null,
    );

    final result = await _repository.fetchAccounts();
    if (!result.success || result.data == null) {
      state = state.copyWith(
        state: PaymentLoadingState.error,
        errorMessage: result.message ?? '加载支付账户失败',
      );
      return;
    }

    _setAccounts(result.data!);
  }

  Future<bool> addAccount(PaymentAccount account) async {
    state = state.copyWith(errorMessage: null);

    final result = await _repository.createAccount(account);
    if (result.success && result.data != null) {
      _setAccounts(_upsertAccount(result.data!));
      return true;
    }

    _setMutationError(result.message ?? '创建支付账户失败');
    return false;
  }

  Future<bool> updateAccount(PaymentAccount account) async {
    state = state.copyWith(errorMessage: null);

    final result = await _repository.updateAccount(account);
    if (result.success && result.data != null) {
      _setAccounts(_upsertAccount(result.data!));
      return true;
    }

    _setMutationError(result.message ?? '更新支付账户失败');
    return false;
  }

  Future<bool> deleteAccount(String id) async {
    state = state.copyWith(errorMessage: null);

    final result = await _repository.deleteAccount(id);
    if (result.success) {
      _setAccounts(
        state.accounts.where((account) => account.id != id).toList(),
      );
      return true;
    }

    _setMutationError(result.message ?? '删除支付账户失败');
    return false;
  }

  Future<bool> toggleActive(String id) async {
    final account = _findAccount(id);
    if (account == null) {
      _setMutationError('未找到支付账户');
      return false;
    }

    final updated = account.copyWith(isActive: !account.isActive);
    return updateAccount(updated);
  }

  PaymentAccount? _findAccount(String id) {
    for (final account in state.accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return null;
  }

  List<PaymentAccount> _upsertAccount(PaymentAccount incoming) {
    var replaced = false;
    final updatedAccounts = <PaymentAccount>[];

    for (final account in state.accounts) {
      if (account.id == incoming.id) {
        updatedAccounts.add(incoming);
        replaced = true;
      } else if (incoming.isDefault && account.isDefault) {
        updatedAccounts.add(account.copyWith(isDefault: false));
      } else {
        updatedAccounts.add(account);
      }
    }

    if (!replaced) {
      if (incoming.isDefault) {
        for (var index = 0; index < updatedAccounts.length; index++) {
          final account = updatedAccounts[index];
          if (account.isDefault) {
            updatedAccounts[index] = account.copyWith(isDefault: false);
          }
        }
      }
      updatedAccounts.add(incoming);
    }

    return updatedAccounts;
  }

  void _setAccounts(List<PaymentAccount> accounts) {
    state = state.copyWith(
      accounts: _sortAccounts(accounts),
      state: PaymentLoadingState.loaded,
      errorMessage: null,
    );
  }

  void _setMutationError(String message) {
    state = state.copyWith(
      state:
          state.accounts.isEmpty && state.state == PaymentLoadingState.initial
              ? PaymentLoadingState.initial
              : PaymentLoadingState.loaded,
      errorMessage: message,
    );
  }

  List<PaymentAccount> _sortAccounts(List<PaymentAccount> accounts) {
    final sorted = List<PaymentAccount>.from(accounts);
    sorted.sort((left, right) {
      if (left.isDefault != right.isDefault) {
        return left.isDefault ? -1 : 1;
      }

      final rightUpdated = right.updatedAt ?? right.createdAt;
      final leftUpdated = left.updatedAt ?? left.createdAt;
      if (leftUpdated != null && rightUpdated != null) {
        return rightUpdated.compareTo(leftUpdated);
      }
      if (leftUpdated != null) {
        return -1;
      }
      if (rightUpdated != null) {
        return 1;
      }
      return left.name.compareTo(right.name);
    });
    return sorted;
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final paymentAccountRepositoryProvider = Provider<PaymentAccountRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentAccountRepository(apiService: apiService);
});

final paymentAccountsProvider =
    StateNotifierProvider<PaymentAccountNotifier, PaymentAccountsState>((ref) {
  final repository = ref.watch(paymentAccountRepositoryProvider);
  return PaymentAccountNotifier.withRepository(repository);
});
