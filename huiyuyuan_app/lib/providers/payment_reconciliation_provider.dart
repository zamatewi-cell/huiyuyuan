library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import '../models/payment_models.dart';
import '../services/api_service.dart';

enum PaymentReconciliationLoadingState { initial, loading, loaded, error }

const Object _paymentReconciliationErrorUnchanged = Object();

class PaymentReconciliationState {
  const PaymentReconciliationState({
    this.records = const <AdminPaymentRecord>[],
    this.state = PaymentReconciliationLoadingState.initial,
    this.errorMessage,
  });

  final List<AdminPaymentRecord> records;
  final PaymentReconciliationLoadingState state;
  final String? errorMessage;

  PaymentReconciliationState copyWith({
    List<AdminPaymentRecord>? records,
    PaymentReconciliationLoadingState? state,
    Object? errorMessage = _paymentReconciliationErrorUnchanged,
  }) {
    return PaymentReconciliationState(
      records: records ?? this.records,
      state: state ?? this.state,
      errorMessage: identical(
        errorMessage,
        _paymentReconciliationErrorUnchanged,
      )
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class PaymentReconciliationNotifier
    extends StateNotifier<PaymentReconciliationState> {
  PaymentReconciliationNotifier({ApiService? apiService})
      : _api = apiService ?? ApiService(),
        super(const PaymentReconciliationState()) {
    loadRecords();
  }

  final ApiService _api;

  Future<void> loadRecords({PaymentStatus? status}) async {
    state = state.copyWith(
      state: PaymentReconciliationLoadingState.loading,
      errorMessage: null,
    );

    if (ApiConfig.useMockApi) {
      state = state.copyWith(
        records: _sortRecords(_mockRecords),
        state: PaymentReconciliationLoadingState.loaded,
        errorMessage: null,
      );
      return;
    }

    try {
      final params = <String, dynamic>{
        if (status != null) 'status': _paymentStatusCode(status),
      };
      final result = await _api.get<dynamic>(
        ApiConfig.adminPaymentReconciliation,
        params: params,
      );
      if (!result.success || result.data == null) {
        state = state.copyWith(
          state: PaymentReconciliationLoadingState.error,
          errorMessage:
              result.message ?? 'payment_reconciliation_load_failed'.tr,
        );
        return;
      }

      final data = jsonAsMap(result.data);
      final payments = data['payments'];
      final records = payments is List
          ? payments
              .map(jsonAsMap)
              .map(AdminPaymentRecord.fromJson)
              .toList(growable: false)
          : const <AdminPaymentRecord>[];
      state = state.copyWith(
        records: _sortRecords(records),
        state: PaymentReconciliationLoadingState.loaded,
        errorMessage: null,
      );
    } catch (error) {
      debugPrint('[PaymentReconciliation] load failed: $error');
      state = state.copyWith(
        state: PaymentReconciliationLoadingState.error,
        errorMessage: 'payment_reconciliation_load_failed'.tr,
      );
    }
  }

  Future<bool> confirmPayment(String paymentId) async {
    if (!ApiConfig.useMockApi) {
      try {
        final result = await _api.post<dynamic>(
          ApiConfig.adminConfirmPaymentRecord(paymentId),
        );
        if (!result.success) {
          state = state.copyWith(
            errorMessage: result.message ?? 'please_retry_later'.tr,
          );
          return false;
        }
        await loadRecords();
        return true;
      } catch (error) {
        debugPrint('[PaymentReconciliation] confirm failed: $error');
        state = state.copyWith(errorMessage: 'please_retry_later'.tr);
        return false;
      }
    }

    final now = DateTime.now();
    return _mutateRecord(
      paymentId,
      (record) => record.copyWith(
        status: PaymentStatus.confirmed,
        confirmedBy: 'mock_admin',
        confirmedAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> markException({
    required String paymentId,
    required String reason,
  }) async {
    if (!ApiConfig.useMockApi) {
      try {
        final result = await _api.post<dynamic>(
          ApiConfig.adminDisputePayment(paymentId),
          params: {'reason': reason},
        );
        if (!result.success) {
          state = state.copyWith(
            errorMessage: result.message ?? 'please_retry_later'.tr,
          );
          return false;
        }
        await loadRecords();
        return true;
      } catch (error) {
        debugPrint('[PaymentReconciliation] dispute failed: $error');
        state = state.copyWith(errorMessage: 'please_retry_later'.tr);
        return false;
      }
    }

    return _mutateRecord(
      paymentId,
      (record) => record.copyWith(
        status: PaymentStatus.disputed,
        adminNote: reason,
        updatedAt: DateTime.now(),
      ),
    );
  }

  bool _mutateRecord(
    String paymentId,
    AdminPaymentRecord Function(AdminPaymentRecord record) update,
  ) {
    var changed = false;
    final records = [
      for (final record in state.records)
        if (record.paymentId == paymentId) update(record) else record,
    ];
    changed = state.records.any((record) => record.paymentId == paymentId);
    if (!changed) {
      return false;
    }
    state = state.copyWith(
      records: _sortRecords(records),
      state: PaymentReconciliationLoadingState.loaded,
      errorMessage: null,
    );
    return true;
  }

  List<AdminPaymentRecord> _sortRecords(List<AdminPaymentRecord> records) {
    final sorted = List<AdminPaymentRecord>.from(records);
    sorted.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return sorted;
  }

  String _paymentStatusCode(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.awaitingConfirmation:
        return 'awaiting_confirmation';
      case PaymentStatus.confirmed:
        return 'confirmed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.timeout:
        return 'timeout';
      case PaymentStatus.disputed:
        return 'disputed';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }
}

final paymentReconciliationProvider = StateNotifierProvider<
    PaymentReconciliationNotifier, PaymentReconciliationState>((ref) {
  return PaymentReconciliationNotifier();
});

final List<AdminPaymentRecord> _mockRecords = <AdminPaymentRecord>[
  AdminPaymentRecord(
    paymentId: 'pay_demo_001',
    orderId: 'ORD20260416001',
    userId: 'customer_demo_001',
    amount: 6890,
    method: PaymentMethod.wechat,
    status: PaymentStatus.awaitingConfirmation,
    paymentAccountId: 'acc_wechat',
    voucherUrl: 'https://example.com/voucher-001.png',
    createdAt: DateTime(2026, 4, 16, 10, 20),
  ),
  AdminPaymentRecord(
    paymentId: 'pay_demo_002',
    orderId: 'ORD20260416002',
    userId: 'customer_demo_002',
    amount: 12800,
    method: PaymentMethod.alipay,
    status: PaymentStatus.disputed,
    adminNote: '到账金额与订单金额不一致',
    createdAt: DateTime(2026, 4, 16, 9, 35),
  ),
  AdminPaymentRecord(
    paymentId: 'pay_demo_003',
    orderId: 'ORD20260415008',
    userId: 'customer_demo_003',
    amount: 3580,
    method: PaymentMethod.unionpay,
    status: PaymentStatus.confirmed,
    confirmedBy: 'admin',
    confirmedAt: DateTime(2026, 4, 15, 18, 12),
    createdAt: DateTime(2026, 4, 15, 18, 2),
  ),
];
