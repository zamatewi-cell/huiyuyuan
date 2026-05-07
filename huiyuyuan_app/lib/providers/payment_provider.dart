import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/payment_account.dart';
import '../providers/app_settings_provider.dart';
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
  final AppLanguage Function() _languageReader;

  PaymentAccountNotifier(
    ApiService apiService, {
    AppLanguage Function()? languageReader,
  }) : this.withRepository(
          PaymentAccountRepository(apiService: apiService),
          languageReader: languageReader,
        );

  PaymentAccountNotifier.withRepository(
    this._repository, {
    AppLanguage Function()? languageReader,
  })  : _languageReader = languageReader ?? (() => AppLanguage.zhCN),
        super(const PaymentAccountsState()) {
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
        errorMessage: result.message ?? _t('payment_operation_retry'),
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

    _setMutationError(result.message ?? _t('payment_operation_retry'));
    return false;
  }

  Future<bool> updateAccount(PaymentAccount account) async {
    state = state.copyWith(errorMessage: null);

    final result = await _repository.updateAccount(account);
    if (result.success && result.data != null) {
      _setAccounts(_upsertAccount(result.data!));
      return true;
    }

    _setMutationError(result.message ?? _t('payment_operation_retry'));
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

    _setMutationError(result.message ?? _t('payment_operation_retry'));
    return false;
  }

  Future<bool> toggleActive(String id) async {
    final account = _findAccount(id);
    if (account == null) {
      _setMutationError(_t('payment_operation_retry'));
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

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return AppStrings.get(_languageReader(), key, params: params);
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

final paymentAccountRepositoryProvider =
    Provider<PaymentAccountRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentAccountRepository(apiService: apiService);
});

final paymentAccountsProvider =
    StateNotifierProvider<PaymentAccountNotifier, PaymentAccountsState>((ref) {
  final repository = ref.watch(paymentAccountRepositoryProvider);
  return PaymentAccountNotifier.withRepository(
    repository,
    languageReader: () => ref.read(appSettingsProvider).language,
  );
});
