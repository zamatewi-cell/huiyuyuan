library;

import 'package:flutter/material.dart';
import '../../l10n/translator_global.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/payment_models.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_reconciliation_provider.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';

class _PaymentReconciliationBackdrop extends StatelessWidget {
  const _PaymentReconciliationBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: _PaymentReconciliationGlowOrb(
              size: 330,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            top: 320,
            child: _PaymentReconciliationGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _PaymentReconciliationTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentReconciliationGlowOrb extends StatelessWidget {
  const _PaymentReconciliationGlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 96, spreadRadius: 30),
        ],
      ),
    );
  }
}

class _PaymentReconciliationTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.1 + i * 0.13);
      final path = Path()..moveTo(-24, y);
      path.cubicTo(
        size.width * 0.2,
        y + 30,
        size.width * 0.72,
        y - 34,
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(
          covariant _PaymentReconciliationTracePainter oldDelegate) =>
      false;
}

enum _PaymentReconciliationFilter {
  all,
  awaiting,
  disputed,
  confirmed,
}

class PaymentReconciliationWorkbenchScreen extends ConsumerStatefulWidget {
  const PaymentReconciliationWorkbenchScreen({super.key});

  @override
  ConsumerState<PaymentReconciliationWorkbenchScreen> createState() =>
      _PaymentReconciliationWorkbenchScreenState();
}

class _PaymentReconciliationWorkbenchScreenState
    extends ConsumerState<PaymentReconciliationWorkbenchScreen> {
  _PaymentReconciliationFilter _selectedFilter =
      _PaymentReconciliationFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canRead = _canReadPayments(user);
    final canReconcile = _canReconcilePayments(user);
    final canMarkException = _canMarkPaymentException(user);
    final state = ref.watch(paymentReconciliationProvider);
    final records = _filteredRecords(state.records);
    final summary = _PaymentReconciliationSummary.fromRecords(state.records);

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.84),
        foregroundColor: JewelryColors.jadeMist,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: JewelryColors.deepJade.withOpacity(0.62),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.14),
            ),
          ),
          child: Text(
            TranslatorGlobal.instance.translate('payment_reconciliation_title'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(paymentReconciliationProvider.notifier).loadRecords(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: TranslatorGlobal.instance.translate('refresh'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _PaymentReconciliationBackdrop()),
          !canRead
              ? _buildPermissionDeniedState()
              : RefreshIndicator(
                  color: JewelryColors.emeraldGlow,
                  onRefresh: () => ref
                      .read(paymentReconciliationProvider.notifier)
                      .loadRecords(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildHero(summary),
                      const SizedBox(height: 18),
                      _buildSummaryGrid(summary),
                      const SizedBox(height: 18),
                      _buildFilterBar(summary),
                      const SizedBox(height: 14),
                      if (state.state ==
                              PaymentReconciliationLoadingState.loading &&
                          state.records.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: JewelryColors.emeraldGlow,
                            ),
                          ),
                        )
                      else if (state.state ==
                              PaymentReconciliationLoadingState.error &&
                          state.records.isEmpty)
                        _buildEmptyCard(
                          icon: Icons.error_outline_rounded,
                          title: TranslatorGlobal.instance.translate('error'),
                          subtitle: state.errorMessage ??
                              TranslatorGlobal.instance.translate(
                                  'payment_reconciliation_load_failed'),
                        )
                      else if (records.isEmpty)
                        _buildEmptyCard(
                          icon: Icons.fact_check_outlined,
                          title: TranslatorGlobal.instance
                              .translate('payment_reconciliation_empty_title'),
                          subtitle: TranslatorGlobal.instance.translate(
                              'payment_reconciliation_empty_subtitle'),
                        )
                      else
                        ...records.map(
                          (record) => _buildPaymentCard(
                            record,
                            canReconcile: canReconcile,
                            canMarkException: canMarkException,
                          ),
                        ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  bool _canReadPayments(UserModel? user) {
    if (user == null || user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('payment_reconcile') ||
        user.hasPermission('payment_exception_mark');
  }

  bool _canReconcilePayments(UserModel? user) {
    if (user == null || user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('payment_reconcile');
  }

  bool _canMarkPaymentException(UserModel? user) {
    if (user == null || user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('payment_exception_mark');
  }

  List<AdminPaymentRecord> _filteredRecords(List<AdminPaymentRecord> records) {
    switch (_selectedFilter) {
      case _PaymentReconciliationFilter.all:
        return records;
      case _PaymentReconciliationFilter.awaiting:
        return records
            .where(
              (record) =>
                  record.status == PaymentStatus.awaitingConfirmation ||
                  record.status == PaymentStatus.pending,
            )
            .toList(growable: false);
      case _PaymentReconciliationFilter.disputed:
        return records
            .where((record) => record.status == PaymentStatus.disputed)
            .toList(growable: false);
      case _PaymentReconciliationFilter.confirmed:
        return records
            .where((record) => record.status == PaymentStatus.confirmed)
            .toList(growable: false);
    }
  }

  Widget _buildHero(_PaymentReconciliationSummary summary) {
    return GlassmorphicCard(
      borderRadius: 22,
      blur: 18,
      opacity: 0.18,
      borderColor: JewelryColors.champagneGold.withOpacity(0.14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: JewelryColors.emeraldLusterGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: JewelryColors.emeraldGlow.withOpacity(0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: JewelryColors.jadeBlack,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslatorGlobal.instance
                      .translate('payment_reconciliation_title'),
                  style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  TranslatorGlobal.instance
                      .translate('payment_reconciliation_subtitle'),
                  style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.66),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HeroAmount(amount: summary.awaitingAmount),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(_PaymentReconciliationSummary summary) {
    final items = [
      (
        label:
            TranslatorGlobal.instance.translate('payment_reconciliation_total'),
        count: summary.total,
        icon: Icons.receipt_long_rounded,
        color: JewelryColors.emeraldGlow,
        filter: _PaymentReconciliationFilter.all,
      ),
      (
        label: TranslatorGlobal.instance
            .translate('payment_reconciliation_pending'),
        count: summary.awaiting,
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFF59E0B),
        filter: _PaymentReconciliationFilter.awaiting,
      ),
      (
        label: TranslatorGlobal.instance
            .translate('payment_reconciliation_exception'),
        count: summary.disputed,
        icon: Icons.report_gmailerrorred_rounded,
        color: const Color(0xFFEF4444),
        filter: _PaymentReconciliationFilter.disputed,
      ),
      (
        label: TranslatorGlobal.instance
            .translate('payment_reconciliation_confirmed'),
        count: summary.confirmed,
        icon: Icons.verified_rounded,
        color: JewelryColors.emeraldLuster,
        filter: _PaymentReconciliationFilter.confirmed,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = item.filter),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.deepJade.withOpacity(0.58),
                  item.color.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.color.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(item.icon, color: item.color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${item.count}',
                        style: const TextStyle(
                          color: JewelryColors.jadeMist,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: JewelryColors.jadeMist.withOpacity(0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(_PaymentReconciliationSummary summary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _PaymentReconciliationFilter.values) ...[
            _FilterChip(
              label: _filterLabel(summary, filter),
              selected: _selectedFilter == filter,
              color: _filterColor(filter),
              onTap: () => setState(() => _selectedFilter = filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    AdminPaymentRecord record, {
    required bool canReconcile,
    required bool canMarkException,
  }) {
    final statusColor = _statusColor(record.status);

    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 20,
      blur: 16,
      opacity: 0.18,
      borderColor: statusColor.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${TranslatorGlobal.instance.translate('payment_record_number')}: ${record.paymentId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(
                label: record.status.label,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.receipt_long_rounded,
                text:
                    '${TranslatorGlobal.instance.translate('order_number')}: ${record.orderId}',
              ),
              _MetaChip(
                icon: Icons.payments_outlined,
                text: _formatCurrency(record.amount),
                color: JewelryColors.champagneGold,
              ),
              _MetaChip(
                icon: Icons.wallet_rounded,
                text:
                    '${TranslatorGlobal.instance.translate('payment_method_title')}: ${record.method.label}',
              ),
              _MetaChip(
                icon: Icons.schedule_rounded,
                text:
                    '${TranslatorGlobal.instance.translate('order_time')}: ${_formatDateTime(record.createdAt)}',
              ),
              if (record.voucherUrl?.trim().isNotEmpty ?? false)
                _MetaChip(
                  icon: Icons.image_outlined,
                  text: TranslatorGlobal.instance
                      .translate('payment_reconciliation_has_voucher'),
                  color: JewelryColors.emeraldGlow,
                ),
              if (record.adminNote?.trim().isNotEmpty ?? false)
                _MetaChip(
                  icon: Icons.sticky_note_2_outlined,
                  text:
                      '${TranslatorGlobal.instance.translate('payment_admin_note_label')}: ${record.adminNote}',
                  color: const Color(0xFFEF4444),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (canReconcile && record.canConfirm)
                FilledButton.icon(
                  onPressed: () => _confirmPayment(record),
                  icon: const Icon(Icons.verified_rounded, size: 16),
                  label: Text(TranslatorGlobal.instance
                      .translate('order_confirm_payment')),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: JewelryColors.jadeBlack,
                  ),
                ),
              if (canMarkException && record.canMarkException)
                OutlinedButton.icon(
                  onPressed: () => _markPaymentException(record),
                  icon:
                      const Icon(Icons.report_gmailerrorred_rounded, size: 16),
                  label: Text(TranslatorGlobal.instance
                      .translate('payment_mark_exception')),
                ),
              if (!canReconcile && !canMarkException)
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.lock_outline_rounded, size: 16),
                  label: Text(TranslatorGlobal.instance
                      .translate('operator_permission_denied')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GlassmorphicCard(
      borderRadius: 20,
      blur: 16,
      opacity: 0.18,
      borderColor: JewelryColors.champagneGold.withOpacity(0.14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 42, color: JewelryColors.emeraldGlow),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.62),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: JewelryColors.champagneGold,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              TranslatorGlobal.instance.translate('operator_permission_denied'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              TranslatorGlobal.instance
                  .translate('payment_reconciliation_permission_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.65),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(
    _PaymentReconciliationSummary summary,
    _PaymentReconciliationFilter filter,
  ) {
    switch (filter) {
      case _PaymentReconciliationFilter.all:
        return '${TranslatorGlobal.instance.translate('order_all')} ${summary.total}';
      case _PaymentReconciliationFilter.awaiting:
        return '${TranslatorGlobal.instance.translate('payment_reconciliation_pending')} ${summary.awaiting}';
      case _PaymentReconciliationFilter.disputed:
        return '${TranslatorGlobal.instance.translate('payment_reconciliation_exception')} ${summary.disputed}';
      case _PaymentReconciliationFilter.confirmed:
        return '${TranslatorGlobal.instance.translate('payment_reconciliation_confirmed')} ${summary.confirmed}';
    }
  }

  Color _filterColor(_PaymentReconciliationFilter filter) {
    switch (filter) {
      case _PaymentReconciliationFilter.all:
        return JewelryColors.emeraldGlow;
      case _PaymentReconciliationFilter.awaiting:
        return const Color(0xFFF59E0B);
      case _PaymentReconciliationFilter.disputed:
        return const Color(0xFFEF4444);
      case _PaymentReconciliationFilter.confirmed:
        return JewelryColors.emeraldLuster;
    }
  }

  Color _statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
      case PaymentStatus.awaitingConfirmation:
        return const Color(0xFFF59E0B);
      case PaymentStatus.confirmed:
        return JewelryColors.emeraldLuster;
      case PaymentStatus.disputed:
        return const Color(0xFFEF4444);
      case PaymentStatus.cancelled:
      case PaymentStatus.timeout:
      case PaymentStatus.refunded:
        return JewelryColors.jadeMist.withOpacity(0.54);
    }
  }

  Future<void> _confirmPayment(AdminPaymentRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          TranslatorGlobal.instance.translate('order_confirm_payment'),
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          TranslatorGlobal.instance.translate('order_confirm_payment_hint'),
          style: TextStyle(
            color: JewelryColors.jadeMist.withOpacity(0.66),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              TranslatorGlobal.instance.translate('cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.58)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: JewelryColors.emeraldLuster,
              foregroundColor: JewelryColors.jadeBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(TranslatorGlobal.instance.translate('confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final ok = await ref
        .read(paymentReconciliationProvider.notifier)
        .confirmPayment(record.paymentId);
    if (!mounted) {
      return;
    }
    _showSnackBar(
      ok
          ? TranslatorGlobal.instance.translate('order_confirm_payment_success')
          : TranslatorGlobal.instance.translate('please_retry_later'),
    );
  }

  Future<void> _markPaymentException(AdminPaymentRecord record) async {
    final controller = TextEditingController(text: record.adminNote ?? '');
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          TranslatorGlobal.instance.translate('payment_mark_exception'),
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: JewelryColors.jadeMist),
          decoration: InputDecoration(
            labelText:
                TranslatorGlobal.instance.translate('payment_admin_note_label'),
            hintText: TranslatorGlobal.instance
                .translate('payment_mark_exception_prompt'),
            labelStyle: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.62),
            ),
            hintStyle: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.36),
            ),
            filled: true,
            fillColor: JewelryColors.jadeBlack.withOpacity(0.28),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.14),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: JewelryColors.emeraldGlow.withOpacity(0.5),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              TranslatorGlobal.instance.translate('cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.58)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: JewelryColors.emeraldLuster,
              foregroundColor: JewelryColors.jadeBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(TranslatorGlobal.instance.translate('confirm')),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (reason == null || !mounted) {
      return;
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      _showSnackBar(TranslatorGlobal.instance
          .translate('payment_mark_exception_reason_required'));
      return;
    }

    final ok =
        await ref.read(paymentReconciliationProvider.notifier).markException(
              paymentId: record.paymentId,
              reason: trimmedReason,
            );
    if (!mounted) {
      return;
    }
    _showSnackBar(
      ok
          ? TranslatorGlobal.instance
              .translate('payment_mark_exception_success')
          : TranslatorGlobal.instance.translate('please_retry_later'),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatCurrency(double value) {
    return '¥${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
  }

  String _formatDateTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.year}-$month-$day $hour:$minute';
  }
}

class _PaymentReconciliationSummary {
  const _PaymentReconciliationSummary({
    required this.total,
    required this.awaiting,
    required this.disputed,
    required this.confirmed,
    required this.awaitingAmount,
  });

  final int total;
  final int awaiting;
  final int disputed;
  final int confirmed;
  final double awaitingAmount;

  factory _PaymentReconciliationSummary.fromRecords(
    List<AdminPaymentRecord> records,
  ) {
    var awaiting = 0;
    var disputed = 0;
    var confirmed = 0;
    var awaitingAmount = 0.0;

    for (final record in records) {
      if (record.status == PaymentStatus.pending ||
          record.status == PaymentStatus.awaitingConfirmation) {
        awaiting += 1;
        awaitingAmount += record.amount;
      } else if (record.status == PaymentStatus.disputed) {
        disputed += 1;
      } else if (record.status == PaymentStatus.confirmed) {
        confirmed += 1;
      }
    }

    return _PaymentReconciliationSummary(
      total: records.length,
      awaiting: awaiting,
      disputed: disputed,
      confirmed: confirmed,
      awaitingAmount: awaitingAmount,
    );
  }
}

class _HeroAmount extends StatelessWidget {
  const _HeroAmount({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: JewelryColors.champagneGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: JewelryColors.champagneGold.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '¥${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: JewelryColors.champagneGold,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            TranslatorGlobal.instance
                .translate('payment_reconciliation_pending_amount'),
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.55),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : JewelryColors.deepJade.withOpacity(0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(selected ? 1 : 0.28)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? JewelryColors.jadeBlack : JewelryColors.jadeMist,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? JewelryColors.jadeMist.withOpacity(0.7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: resolvedColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: resolvedColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: resolvedColor),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: resolvedColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
