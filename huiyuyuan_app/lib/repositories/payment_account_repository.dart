library;

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import '../models/payment_account.dart';
import '../services/api_service.dart';

class PaymentAccountRepositoryResult<T> {
  final bool success;
  final T? data;
  final String? message;

  const PaymentAccountRepositoryResult({
    required this.success,
    this.data,
    this.message,
  });
}

class PaymentAccountRepository {
  PaymentAccountRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaymentAccountRepositoryResult<List<PaymentAccount>>>
      fetchAccounts() async {
    final result = await _apiService.get<dynamic>(ApiConfig.paymentAccounts);
    if (!result.success || result.data == null) {
      return PaymentAccountRepositoryResult(
        success: false,
        message: result.message,
        data: const [],
      );
    }

    return PaymentAccountRepositoryResult(
      success: true,
      data: _parseAccounts(result.data),
      message: result.message,
    );
  }

  Future<PaymentAccountRepositoryResult<PaymentAccount>> createAccount(
    PaymentAccount account,
  ) async {
    final result = await _apiService.post<dynamic>(
      ApiConfig.paymentAccounts,
      data: account.toCreateMap(),
    );
    if (!result.success || result.data == null) {
      return PaymentAccountRepositoryResult(
        success: false,
        message: result.message,
      );
    }

    return PaymentAccountRepositoryResult(
      success: true,
      data: PaymentAccount.fromMap(jsonAsMap(result.data)),
      message: result.message,
    );
  }

  Future<PaymentAccountRepositoryResult<PaymentAccount>> updateAccount(
    PaymentAccount account,
  ) async {
    final result = await _apiService.put<dynamic>(
      ApiConfig.paymentAccountDetail(account.id),
      data: account.toCreateMap(),
    );
    if (!result.success || result.data == null) {
      return PaymentAccountRepositoryResult(
        success: false,
        message: result.message,
      );
    }

    return PaymentAccountRepositoryResult(
      success: true,
      data: PaymentAccount.fromMap(jsonAsMap(result.data)),
      message: result.message,
    );
  }

  Future<PaymentAccountRepositoryResult<void>> deleteAccount(String id) async {
    final result = await _apiService.delete<dynamic>(
      ApiConfig.paymentAccountDetail(id),
    );
    return PaymentAccountRepositoryResult(
      success: result.success,
      message: result.message,
    );
  }

  List<PaymentAccount> _parseAccounts(dynamic payload) {
    if (payload is Iterable) {
      return payload
          .map((item) => PaymentAccount.fromMap(jsonAsMap(item)))
          .toList(growable: false);
    }

    final map = jsonAsMap(payload);
    final candidates = <dynamic>[map['items'], map['data'], map['results']];
    for (final candidate in candidates) {
      if (candidate is Iterable) {
        return candidate
            .map((item) => PaymentAccount.fromMap(jsonAsMap(item)))
            .toList(growable: false);
      }
    }

    return const [];
  }
}
