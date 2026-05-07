library;

import 'package:flutter/material.dart';
import '../../l10n/translator_global.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../models/payment_models.dart' as pay;
import '../../models/user_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../order/logistics_screen.dart';
import '../order/order_detail_screen.dart';
import '../order/shipping_dialog.dart';

enum _AdminOrderFilter {
  all,
  toConfirm,
  toShip,
  inTransit,
  completed,
}

class _AdminOrderBackdrop extends StatelessWidget {
  const _AdminOrderBackdrop();

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
            child: _AdminOrderGlowOrb(
              size: 330,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            top: 340,
            child: _AdminOrderGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _AdminOrderTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOrderGlowOrb extends StatelessWidget {
  const _AdminOrderGlowOrb({required this.size, required this.color});

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

class _AdminOrderTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.1 + i * 0.13);
      final path = Path()..moveTo(-24, y);
      path.quadraticBezierTo(
        size.width * 0.52,
        y + (i.isEven ? 32 : -30),
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdminOrderTracePainter oldDelegate) => false;
}

class _OrderWorkbenchSummary {
  final int total;
  final int toConfirm;
  final int toShip;
  final int inTransit;
  final int completed;

  const _OrderWorkbenchSummary({
    required this.total,
    required this.toConfirm,
    required this.toShip,
    required this.inTransit,
    required this.completed,
  });

  factory _OrderWorkbenchSummary.fromOrders(List<OrderModel> orders) {
    var toConfirm = 0;
    var toShip = 0;
    var inTransit = 0;
    var completed = 0;

    for (final order in orders) {
      if (_needsPaymentConfirm(order)) {
        toConfirm += 1;
        continue;
      }
      if (order.status == OrderStatus.paid) {
        toShip += 1;
        continue;
      }
      if (_isInTransit(order)) {
        inTransit += 1;
        continue;
      }
      if (_isCompleted(order)) {
        completed += 1;
      }
    }

    return _OrderWorkbenchSummary(
      total: orders.length,
      toConfirm: toConfirm,
      toShip: toShip,
      inTransit: inTransit,
      completed: completed,
    );
  }
}

bool _needsPaymentConfirm(OrderModel order) {
  return order.status == OrderStatus.pending &&
      (order.paymentId?.trim().isNotEmpty ?? false);
}

bool _isInTransit(OrderModel order) => order.status == OrderStatus.shipped;

bool _isCompleted(OrderModel order) =>
    order.status == OrderStatus.completed ||
    order.status == OrderStatus.delivered;

class AdminOrderWorkbenchScreen extends ConsumerStatefulWidget {
  const AdminOrderWorkbenchScreen({super.key});

  @override
  ConsumerState<AdminOrderWorkbenchScreen> createState() =>
      _AdminOrderWorkbenchScreenState();
}

class _AdminOrderWorkbenchScreenState
    extends ConsumerState<AdminOrderWorkbenchScreen> {
  _AdminOrderFilter _selectedFilter = _AdminOrderFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canReadOrders = _canReadOrders(user);
    final canManageOrders = _canManageOrders(user);
    final canReconcilePayments = _canReconcilePayments(user);
    final canMarkPaymentException = _canMarkPaymentException(user);
    final orders = ref.watch(orderProvider);
    final isLoaded = ref.watch(orderLoadedProvider);
    final summary = _OrderWorkbenchSummary.fromOrders(orders);
    final filteredOrders = _sortOrders(_applyFilter(orders));
    final priorityOrders = _sortOrders(
      orders.where(
        (order) =>
            _needsPaymentConfirm(order) || order.status == OrderStatus.paid,
      ),
    );

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
            TranslatorGlobal.instance.translate('admin_orders'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(orderProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: TranslatorGlobal.instance.translate('refresh'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _AdminOrderBackdrop()),
          !canReadOrders
              ? _buildPermissionDeniedState()
              : !isLoaded && orders.isEmpty
                  ? _buildLoadingState()
                  : RefreshIndicator(
                      color: JewelryColors.emeraldGlow,
                      onRefresh: () =>
                          ref.read(orderProvider.notifier).refresh(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _buildHeroCard(summary),
                          const SizedBox(height: 18),
                          _buildSummaryGrid(summary),
                          const SizedBox(height: 22),
                          _buildPrioritySection(
                            priorityOrders,
                            canManageOrders: canManageOrders,
                            canReconcilePayments: canReconcilePayments,
                            canMarkPaymentException: canMarkPaymentException,
                          ),
                          const SizedBox(height: 22),
                          _buildFilterBar(summary),
                          const SizedBox(height: 14),
                          if (orders.isEmpty)
                            _buildEmptyCard(
                              title: TranslatorGlobal.instance
                                  .translate('order_empty_title'),
                              subtitle: TranslatorGlobal.instance
                                  .translate('order_empty_subtitle'),
                            )
                          else if (filteredOrders.isEmpty)
                            _buildEmptyCard(
                              title: TranslatorGlobal.instance
                                  .translate('no_data'),
                              subtitle: TranslatorGlobal.instance
                                  .translate('admin_order_no_action_needed'),
                              actionLabel: TranslatorGlobal.instance
                                  .translate('order_all'),
                              onAction: () {
                                setState(
                                  () => _selectedFilter = _AdminOrderFilter.all,
                                );
                              },
                            )
                          else
                            ...filteredOrders.map(
                              (order) => _buildOrderCard(
                                order,
                                canManageOrders: canManageOrders,
                                canReconcilePayments: canReconcilePayments,
                                canMarkPaymentException:
                                    canMarkPaymentException,
                              ),
                            ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  bool _canReadOrders(UserModel? user) {
    if (user == null) {
      return true;
    }
    if (user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('orders') ||
        user.hasPermission('order_manage') ||
        user.hasPermission('payment_reconcile') ||
        user.hasPermission('payment_exception_mark');
  }

  bool _canManageOrders(UserModel? user) {
    if (user == null) {
      return true;
    }
    if (user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('order_manage');
  }

  bool _canReconcilePayments(UserModel? user) {
    if (user == null) {
      return true;
    }
    if (user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('payment_reconcile');
  }

  bool _canMarkPaymentException(UserModel? user) {
    if (user == null) {
      return true;
    }
    if (user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('payment_exception_mark');
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white70,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              TranslatorGlobal.instance.translate('operator_permission_denied'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.adaptiveTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return PremiumCard(
          margin: const EdgeInsets.only(bottom: 14),
          backgroundColor: context.adaptiveSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLoadingLine(width: 120, height: 12),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: JewelryColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLoadingLine(width: double.infinity, height: 14),
                        const SizedBox(height: 10),
                        _buildLoadingLine(width: 110, height: 12),
                        const SizedBox(height: 10),
                        _buildLoadingLine(width: 80, height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(_OrderWorkbenchSummary summary) {
    return GlassmorphicCard(
      borderRadius: 24,
      blur: 18,
      opacity: 0.18,
      borderColor: JewelryColors.champagneGold.withOpacity(0.14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslatorGlobal.instance.translate('admin_orders'),
                  style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  TranslatorGlobal.instance
                      .translate('admin_order_workbench_subtitle'),
                  style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.68),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildHeroMetric(
                      TranslatorGlobal.instance
                          .translate('admin_order_to_confirm'),
                      summary.toConfirm,
                    ),
                    _buildHeroMetric(
                      TranslatorGlobal.instance
                          .translate('order_pending_shipment'),
                      summary.toShip,
                    ),
                    _buildHeroMetric(
                      TranslatorGlobal.instance
                          .translate('admin_order_in_transit'),
                      summary.inTransit,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: JewelryColors.emeraldLusterGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: JewelryColors.emeraldGlow.withOpacity(0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: JewelryColors.jadeBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: JewelryColors.champagneGold,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.76),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(_OrderWorkbenchSummary summary) {
    final items = [
      (
        label: TranslatorGlobal.instance.translate('admin_order_to_confirm'),
        count: summary.toConfirm,
        icon: Icons.verified_rounded,
        color: const Color(0xFFF59E0B),
        filter: _AdminOrderFilter.toConfirm,
      ),
      (
        label: TranslatorGlobal.instance.translate('order_pending_shipment'),
        count: summary.toShip,
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF0EA5E9),
        filter: _AdminOrderFilter.toShip,
      ),
      (
        label: TranslatorGlobal.instance.translate('admin_order_in_transit'),
        count: summary.inTransit,
        icon: Icons.route_rounded,
        color: const Color(0xFF8B5CF6),
        filter: _AdminOrderFilter.inTransit,
      ),
      (
        label: TranslatorGlobal.instance.translate('order_completed'),
        count: summary.completed,
        icon: Icons.task_alt_rounded,
        color: JewelryColors.emeraldLuster,
        filter: _AdminOrderFilter.completed,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = _selectedFilter == item.filter;
        return GlassmorphicCard(
          borderRadius: 22,
          blur: 16,
          opacity: 0.18,
          borderColor: item.color.withOpacity(selected ? 0.32 : 0.16),
          onTap: () {
            setState(() => _selectedFilter = item.filter);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(selected ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const Spacer(),
              Text(
                '${item.count}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: JewelryColors.jadeMist,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: JewelryColors.jadeMist,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selected
                    ? TranslatorGlobal.instance.translate('common_view_detail')
                    : TranslatorGlobal.instance.translate('profile_pending'),
                style: TextStyle(
                  fontSize: 11,
                  color: item.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrioritySection(
    List<OrderModel> priorityOrders, {
    required bool canManageOrders,
    required bool canReconcilePayments,
    required bool canMarkPaymentException,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: 20,
              color: JewelryColors.champagneGold,
            ),
            const SizedBox(width: 8),
            Text(
              TranslatorGlobal.instance.translate('profile_pending'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (priorityOrders.isEmpty)
          GlassmorphicCard(
            borderRadius: 20,
            blur: 16,
            opacity: 0.18,
            borderColor: JewelryColors.champagneGold.withOpacity(0.14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: JewelryColors.emeraldGlow.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: JewelryColors.emeraldGlow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    TranslatorGlobal.instance
                        .translate('admin_order_no_action_needed'),
                    style: const TextStyle(
                      color: JewelryColors.jadeMist,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...priorityOrders.take(3).map(
                (order) => _buildPriorityCard(
                  order,
                  canManageOrders: canManageOrders,
                  canReconcilePayments: canReconcilePayments,
                  canMarkPaymentException: canMarkPaymentException,
                ),
              ),
      ],
    );
  }

  Widget _buildPriorityCard(
    OrderModel order, {
    required bool canManageOrders,
    required bool canReconcilePayments,
    required bool canMarkPaymentException,
  }) {
    final accentColor = _effectiveStatusColor(order);
    final language = ref.watch(appSettingsProvider).language;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        backgroundColor: context.adaptiveSurface,
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 68,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.localizedProductNameFor(language),
                    style: TextStyle(
                      color: context.adaptiveTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${TranslatorGlobal.instance.translate('order_number')}: ${order.id}',
                    style: TextStyle(
                      color: context.adaptiveTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _prioritySubtitle(order),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildInlineActionButton(
              order,
              canManageOrders: canManageOrders,
              canReconcilePayments: canReconcilePayments,
              canMarkPaymentException: canMarkPaymentException,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(_OrderWorkbenchSummary summary) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _AdminOrderFilter.values.map((filter) {
        final selected = _selectedFilter == filter;
        final color = _filterColor(filter);
        return FilterChip(
          label:
              Text('${_filterLabel(filter)} ${_filterCount(summary, filter)}'),
          selected: selected,
          onSelected: (_) {
            setState(() => _selectedFilter = filter);
          },
          labelStyle: TextStyle(
            color: selected ? color : context.adaptiveTextSecondary,
            fontWeight: FontWeight.w600,
          ),
          showCheckmark: false,
          selectedColor: color.withOpacity(0.12),
          backgroundColor: context.adaptiveSurface,
          side: BorderSide(
            color: selected ? color : Colors.grey.withOpacity(0.18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildOrderCard(
    OrderModel order, {
    required bool canManageOrders,
    required bool canReconcilePayments,
    required bool canMarkPaymentException,
  }) {
    final language = ref.watch(appSettingsProvider).language;

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 14),
      backgroundColor: context.adaptiveSurface,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${TranslatorGlobal.instance.translate('order_number')}: ${order.id}',
                  style: TextStyle(
                    color: context.adaptiveTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStatusBadge(order),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(order),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.localizedProductNameFor(language),
                      style: TextStyle(
                        color: context.adaptiveTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${TranslatorGlobal.instance.translate('common_quantity')}: x${order.quantity}',
                      style: TextStyle(
                        color: context.adaptiveTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '¥${order.totalPaid.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: JewelryColors.price,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetaChip(
                Icons.person_outline_rounded,
                '${TranslatorGlobal.instance.translate('address_recipient_name')}: ${_recipientText(order)}',
              ),
              _buildMetaChip(
                Icons.schedule_rounded,
                '${TranslatorGlobal.instance.translate('order_time')}: ${_formatDateTime(order.createdAt)}',
              ),
              if (order.paymentMethod != null)
                _buildMetaChip(
                  Icons.wallet_rounded,
                  '${TranslatorGlobal.instance.translate('payment_method_title')}: ${_paymentMethodLabel(order)}',
                  color: order.paymentMethod!.color,
                ),
              if (order.paymentAccount?.name.trim().isNotEmpty ?? false)
                _buildMetaChip(
                  Icons.account_balance_rounded,
                  '${TranslatorGlobal.instance.translate('payment_account_name')}: ${order.paymentAccount!.name}',
                ),
              if (_needsPaymentConfirm(order) && order.paymentId != null)
                _buildMetaChip(
                  Icons.receipt_long_rounded,
                  '${TranslatorGlobal.instance.translate('payment_record_number')}: ${order.paymentId}',
                ),
              if (_isPaymentDisputed(order))
                _buildMetaChip(
                  Icons.warning_amber_rounded,
                  TranslatorGlobal.instance
                      .translate('payment_status_disputed'),
                  color: const Color(0xFFEF4444),
                ),
              if (order.paymentAdminNote?.trim().isNotEmpty ?? false)
                _buildMetaChip(
                  Icons.sticky_note_2_outlined,
                  '${TranslatorGlobal.instance.translate('payment_admin_note_label')}: ${order.paymentAdminNote!}',
                  color: const Color(0xFFF59E0B),
                ),
              if (order.paymentAccount?.accountNumber?.trim().isNotEmpty ??
                  false)
                _buildMetaChip(
                  Icons.qr_code_rounded,
                  '${TranslatorGlobal.instance.translate('payment_account_number')}: ${order.paymentAccount!.accountNumber}',
                ),
              if (order.status == OrderStatus.pending &&
                  !_needsPaymentConfirm(order))
                _buildMetaChip(
                  Icons.hourglass_bottom_rounded,
                  TranslatorGlobal.instance
                      .translate('admin_order_waiting_customer_payment'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: _buildActionButtons(
                order,
                canManageOrders: canManageOrders,
                canReconcilePayments: canReconcilePayments,
                canMarkPaymentException: canMarkPaymentException,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderModel order) {
    final color = _effectiveStatusColor(order);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _effectiveStatusLabel(order),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProductImage(OrderModel order) {
    final rawUrl = order.productImage?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      return _buildProductImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        _resolveImageUrl(rawUrl),
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildProductImagePlaceholder(),
      ),
    );
  }

  Widget _buildProductImagePlaceholder() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: JewelryColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        Icons.diamond_outlined,
        size: 38,
        color: JewelryColors.primary.withOpacity(0.45),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text, {Color? color}) {
    final resolvedColor = color ?? context.adaptiveTextSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: resolvedColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
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

  Widget _buildInlineActionButton(
    OrderModel order, {
    required bool canManageOrders,
    required bool canReconcilePayments,
    required bool canMarkPaymentException,
  }) {
    if (_needsPaymentConfirm(order) && canReconcilePayments) {
      return FilledButton(
        onPressed: () => _confirmPayment(order),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child:
            Text(TranslatorGlobal.instance.translate('order_confirm_payment')),
      );
    }

    if (_needsPaymentConfirm(order) &&
        !_isPaymentDisputed(order) &&
        canMarkPaymentException) {
      return OutlinedButton(
        onPressed: () => _markPaymentException(order),
        child:
            Text(TranslatorGlobal.instance.translate('payment_mark_exception')),
      );
    }

    if (!canManageOrders) {
      return OutlinedButton(
        onPressed: () => _openOrderDetail(order),
        child: Text(TranslatorGlobal.instance.translate('common_view_detail')),
      );
    }

    return FilledButton(
      onPressed: () => _shipOrder(order),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(TranslatorGlobal.instance.translate('order_ship')),
    );
  }

  List<Widget> _buildActionButtons(
    OrderModel order, {
    required bool canManageOrders,
    required bool canReconcilePayments,
    required bool canMarkPaymentException,
  }) {
    final buttons = <Widget>[
      OutlinedButton.icon(
        onPressed: () => _openOrderDetail(order),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: Text(TranslatorGlobal.instance.translate('common_view_detail')),
      ),
    ];

    if (!canManageOrders && !canReconcilePayments && !canMarkPaymentException) {
      if (_isInTransit(order) || _isCompleted(order)) {
        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _openLogistics(order),
            icon: const Icon(Icons.route_rounded, size: 16),
            label: Text(TranslatorGlobal.instance.translate('order_logistics')),
          ),
        );
      }
      return buttons;
    }

    if (_needsPaymentConfirm(order)) {
      if (canReconcilePayments) {
        buttons.add(
          FilledButton.icon(
            onPressed: () => _confirmPayment(order),
            icon: const Icon(Icons.verified_rounded, size: 16),
            label: Text(
                TranslatorGlobal.instance.translate('order_confirm_payment')),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
      if (!_isPaymentDisputed(order) && canMarkPaymentException) {
        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _markPaymentException(order),
            icon: const Icon(Icons.report_gmailerrorred_rounded, size: 16),
            label: Text(
                TranslatorGlobal.instance.translate('payment_mark_exception')),
          ),
        );
      }
      return buttons;
    }

    if (order.status == OrderStatus.paid && canManageOrders) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _shipOrder(order),
          icon: const Icon(Icons.local_shipping_rounded, size: 16),
          label: Text(TranslatorGlobal.instance.translate('order_ship')),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
          ),
        ),
      );
      return buttons;
    }

    if (_isInTransit(order) || _isCompleted(order)) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _openLogistics(order),
          icon: const Icon(Icons.route_rounded, size: 16),
          label: Text(TranslatorGlobal.instance.translate('order_logistics')),
        ),
      );
    }

    return buttons;
  }

  Widget _buildEmptyCard({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return PremiumCard(
      backgroundColor: context.adaptiveSurface,
      borderRadius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: JewelryColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: JewelryColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: context.adaptiveTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.adaptiveTextSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingLine({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Iterable<OrderModel> _applyFilter(List<OrderModel> orders) {
    switch (_selectedFilter) {
      case _AdminOrderFilter.all:
        return orders;
      case _AdminOrderFilter.toConfirm:
        return orders.where(_needsPaymentConfirm);
      case _AdminOrderFilter.toShip:
        return orders.where((order) => order.status == OrderStatus.paid);
      case _AdminOrderFilter.inTransit:
        return orders.where(_isInTransit);
      case _AdminOrderFilter.completed:
        return orders.where(_isCompleted);
    }
  }

  List<OrderModel> _sortOrders(Iterable<OrderModel> orders) {
    final sorted = [...orders];
    sorted.sort((left, right) {
      final priorityCompare =
          _sortPriority(left).compareTo(_sortPriority(right));
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return right.createdAt.compareTo(left.createdAt);
    });
    return sorted;
  }

  int _sortPriority(OrderModel order) {
    if (_needsPaymentConfirm(order)) {
      return 0;
    }
    if (order.status == OrderStatus.paid) {
      return 1;
    }
    if (_isInTransit(order)) {
      return 2;
    }
    if (order.status == OrderStatus.pending) {
      return 3;
    }
    if (_isCompleted(order)) {
      return 4;
    }
    return 5;
  }

  String _filterLabel(_AdminOrderFilter filter) {
    switch (filter) {
      case _AdminOrderFilter.all:
        return TranslatorGlobal.instance.translate('order_all');
      case _AdminOrderFilter.toConfirm:
        return TranslatorGlobal.instance.translate('admin_order_to_confirm');
      case _AdminOrderFilter.toShip:
        return TranslatorGlobal.instance.translate('order_pending_shipment');
      case _AdminOrderFilter.inTransit:
        return TranslatorGlobal.instance.translate('admin_order_in_transit');
      case _AdminOrderFilter.completed:
        return TranslatorGlobal.instance.translate('order_completed');
    }
  }

  int _filterCount(_OrderWorkbenchSummary summary, _AdminOrderFilter filter) {
    switch (filter) {
      case _AdminOrderFilter.all:
        return summary.total;
      case _AdminOrderFilter.toConfirm:
        return summary.toConfirm;
      case _AdminOrderFilter.toShip:
        return summary.toShip;
      case _AdminOrderFilter.inTransit:
        return summary.inTransit;
      case _AdminOrderFilter.completed:
        return summary.completed;
    }
  }

  Color _filterColor(_AdminOrderFilter filter) {
    switch (filter) {
      case _AdminOrderFilter.all:
        return JewelryColors.primary;
      case _AdminOrderFilter.toConfirm:
        return const Color(0xFFF59E0B);
      case _AdminOrderFilter.toShip:
        return const Color(0xFF0EA5E9);
      case _AdminOrderFilter.inTransit:
        return const Color(0xFF8B5CF6);
      case _AdminOrderFilter.completed:
        return const Color(0xFF10B981);
    }
  }

  String _effectiveStatusLabel(OrderModel order) {
    if (_isPaymentDisputed(order)) {
      return pay.paymentStatusFromValue(order.paymentRecordStatus).label;
    }
    if (_needsPaymentConfirm(order)) {
      return TranslatorGlobal.instance.translate('admin_order_to_confirm');
    }
    if (_isInTransit(order)) {
      return TranslatorGlobal.instance.translate('admin_order_in_transit');
    }
    return order.status.localizedLabel;
  }

  Color _effectiveStatusColor(OrderModel order) {
    if (_isPaymentDisputed(order)) {
      return const Color(0xFFEF4444);
    }
    if (_needsPaymentConfirm(order)) {
      return const Color(0xFFF59E0B);
    }
    if (_isInTransit(order)) {
      return const Color(0xFF8B5CF6);
    }
    return order.status.color;
  }

  String _prioritySubtitle(OrderModel order) {
    if (_isPaymentDisputed(order) &&
        order.paymentAdminNote?.trim().isNotEmpty == true) {
      return order.paymentAdminNote!.trim();
    }
    if (_needsPaymentConfirm(order)) {
      return '${TranslatorGlobal.instance.translate('payment_record_number')}: ${order.paymentId}';
    }
    return '${TranslatorGlobal.instance.translate('address_recipient_name')}: ${_recipientText(order)}';
  }

  bool _isPaymentDisputed(OrderModel order) {
    final status = order.paymentRecordStatus?.trim();
    return status != null &&
        status.isNotEmpty &&
        pay.paymentStatusFromValue(status) == pay.PaymentStatus.disputed;
  }

  String _recipientText(OrderModel order) {
    final name = order.recipientName?.trim() ?? '';
    final phone = order.recipientPhone?.trim() ?? '';
    if (name.isNotEmpty && phone.isNotEmpty) {
      return '$name · $phone';
    }
    if (name.isNotEmpty) {
      return name;
    }
    if (phone.isNotEmpty) {
      return phone;
    }
    return '--';
  }

  String _paymentMethodLabel(OrderModel order) {
    switch (order.paymentMethod) {
      case PaymentMethod.wechat:
        return TranslatorGlobal.instance.translate('payment_type_wechat');
      case PaymentMethod.alipay:
        return TranslatorGlobal.instance.translate('payment_type_alipay');
      case PaymentMethod.balance:
      case PaymentMethod.unionpay:
        return TranslatorGlobal.instance.translate('payment_bank_transfer');
      case null:
        return '--';
    }
  }

  String _formatDateTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.year}-$month-$day $hour:$minute';
  }

  Future<void> _confirmPayment(OrderModel order) async {
    if (!_canReconcilePayments(ref.read(currentUserProvider))) {
      _showSnackBar(
          TranslatorGlobal.instance.translate('operator_permission_denied'));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text(TranslatorGlobal.instance.translate('order_confirm_payment')),
        content: Text(
            TranslatorGlobal.instance.translate('order_confirm_payment_hint')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(TranslatorGlobal.instance.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(TranslatorGlobal.instance.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final ok = await ref.read(orderProvider.notifier).confirmPayment(order.id);
    if (!mounted) {
      return;
    }
    _showSnackBar(
      ok
          ? TranslatorGlobal.instance.translate('order_confirm_payment_success')
          : TranslatorGlobal.instance.translate('please_retry_later'),
    );
  }

  Future<void> _shipOrder(OrderModel order) async {
    if (!_canManageOrders(ref.read(currentUserProvider))) {
      _showSnackBar(
          TranslatorGlobal.instance.translate('operator_permission_denied'));
      return;
    }
    final result = await ShippingDialog.show(
      context,
      orderId: order.id,
      productName:
          order.localizedProductNameFor(ref.read(appSettingsProvider).language),
    );
    if (result == null || !mounted) {
      return;
    }

    final ok = await ref.read(orderProvider.notifier).shipOrder(
          order.id,
          carrier: result.carrier,
          trackingNumber: result.trackingNumber,
        );
    if (!mounted) {
      return;
    }
    _showSnackBar(
      ok
          ? TranslatorGlobal.instance.translate('order_ship_success')
          : TranslatorGlobal.instance.translate('please_retry_later'),
    );
  }

  Future<void> _markPaymentException(OrderModel order) async {
    if (!_canMarkPaymentException(ref.read(currentUserProvider))) {
      _showSnackBar(
          TranslatorGlobal.instance.translate('operator_permission_denied'));
      return;
    }
    if (order.paymentId == null || order.paymentId!.trim().isEmpty) {
      _showSnackBar(TranslatorGlobal.instance.translate('please_retry_later'));
      return;
    }

    final controller =
        TextEditingController(text: order.paymentAdminNote ?? '');
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text(TranslatorGlobal.instance.translate('payment_mark_exception')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText:
                TranslatorGlobal.instance.translate('payment_admin_note_label'),
            hintText: TranslatorGlobal.instance
                .translate('payment_mark_exception_prompt'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(TranslatorGlobal.instance.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
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

    final ok = await ref.read(orderProvider.notifier).markPaymentException(
          order.id,
          paymentId: order.paymentId!,
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

  void _openOrderDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );
  }

  void _openLogistics(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogisticsScreen(order: order),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _resolveImageUrl(String rawUrl) {
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  if (rawUrl.startsWith('/')) {
    return '${ApiConfig.apiUrl}$rawUrl';
  }
  return rawUrl;
}
