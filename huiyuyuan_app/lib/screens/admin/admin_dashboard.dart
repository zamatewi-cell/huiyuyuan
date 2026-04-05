/// HuiYuYuan admin dashboard.
///
/// Features:
/// - global metrics overview
/// - product management
/// - operator management
/// - audit log access
/// - system settings
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/colors.dart';
import '../../l10n/l10n_provider.dart';
import '../../l10n/product_translator.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_catalog_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin/admin_product_management_tab.dart';
import '../../widgets/admin/admin_operator_tab.dart';
import '../../widgets/common/error_handler.dart';
import '../../widgets/common/notification_badge_icon.dart';
import 'inventory_screen.dart';
import 'admin_order_workbench_screen.dart';
import '../notification/notification_screen.dart';
import '../payment_management_screen.dart';

/// Admin dashboard screen.
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({
    super.key,
    this.pageOverrides,
    this.skipInitialLoad = false,
  }) : assert(pageOverrides == null || pageOverrides.length == 4);

  final List<Widget>? pageOverrides;
  final bool skipInitialLoad;

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final AdminService _adminService = AdminService();
  final GlobalKey<AdminProductManagementTabState> _productManagementTabKey =
      GlobalKey<AdminProductManagementTabState>();

  DashboardStats? _stats;
  List<RestockSuggestion> _restockSuggestions = [];
  List<ActivityItem> _activities = [];
  String _activityFilter = AdminActivityTags.all;
  bool _isDashboardLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (!widget.skipInitialLoad) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isDashboardLoading = true);
    }
    try {
      await _adminService.initialize();
      final futures = await Future.wait<Object?>([
        _adminService.getDashboardStats(),
        _adminService.getRestockSuggestions(),
        _adminService.getRecentActivities(),
        ref.read(productCatalogProvider.notifier).refresh(forceRefresh: false),
      ]);

      if (mounted) {
        setState(() {
          _stats = futures[0] as DashboardStats?;
          _restockSuggestions = futures[1] as List<RestockSuggestion>;
          _activities = futures[2] as List<ActivityItem>;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isDashboardLoading = false);
      }
    }
  }

  Future<void> _refreshActivities() async {
    final activities = await _adminService.getRecentActivities(
      filter: _activityFilter,
    );
    if (mounted) {
      setState(() => _activities = activities);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky top section.
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildHeader(),
            ),
            // Tab bar.
            _buildTabBar(),
            // Tab content.
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.pageOverrides ??
                    [
                      _buildDashboardTab(),
                      _buildProductManagementTab(),
                      const InventoryScreen(),
                      _buildOperatorTab(),
                    ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: JewelryColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dashboard_rounded, size: 15),
                const SizedBox(width: 5),
                Text(ref.tr('admin_dashboard')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_rounded, size: 15),
                const SizedBox(width: 5),
                Text(ref.tr('admin_products')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_rounded, size: 15),
                const SizedBox(width: 5),
                Text(ref.tr('product_stock')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_rounded, size: 15),
                const SizedBox(width: 5),
                Text(ref.tr('admin_operators')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = ref.tr('greeting_morning');
    if (hour >= 12 && hour < 18) {
      greeting = ref.tr('greeting_afternoon');
    } else if (hour >= 18) {
      greeting = ref.tr('greeting_evening');
    }

    final user = ref.watch(currentUserProvider);
    final displayPhone = user?.phone ?? '';
    final roleLabel = user?.isSuperAdmin == true
        ? ref.tr('role_admin')
        : ref.tr('admin_default_name');
    final secondaryLabel =
        displayPhone.isNotEmpty ? '$roleLabel ($displayPhone)' : roleLabel;
    final unreadNotifications = ref.watch(notificationUnreadCountProvider);

    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.diamond_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $roleLabel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                secondaryLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationScreen(),
            ),
          ),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: NotificationBadgeIcon(
              icon: Icons.notifications_none_rounded,
              count: unreadNotifications,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Dashboard tab.

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreInfoCard(),
          const SizedBox(height: 20),
          _buildGlassStatsGrid(),
          const SizedBox(height: 24),
          _buildRestockSuggestions(),
          const SizedBox(height: 24),
          _buildActivitySection(),
          const SizedBox(height: 24),
          _buildQuickActionsSection(),
          const SizedBox(height: 24),
          _buildSystemPanel(),
        ],
      ),
    );
  }

  // Store information card.
  Widget _buildStoreInfoCard() {
    final catalogProductCount =
        ref.watch(productCatalogProductsProvider).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Color(0xFF06B6D4),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref.tr('shop_main_name'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  ref.tr('shop_status_desc').replaceFirst('{count}',
                      '${_stats?.totalProducts ?? catalogProductCount}'),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Color(0xFF10B981), size: 6),
                const SizedBox(width: 5),
                Text(ref.tr('work_online'),
                    style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2x2 glass stat cards.
  Widget _buildGlassStatsGrid() {
    final catalogProductCount =
        ref.watch(productCatalogProductsProvider).length;

    if (_isDashboardLoading && _stats == null) {
      return _buildStatsLoadingGrid();
    }

    final totalOrders = _stats?.totalOrders ?? 0;
    final totalAmount = _stats?.totalAmount ?? 0.0;
    final pendingCount = _stats?.pendingOrders ?? 0;
    final shippedCount = _stats?.shippedOrders ?? 0;
    final totalProducts = _stats?.totalProducts ?? catalogProductCount;

    String formatAmount(double amount) {
      if (amount >= 10000) {
        return '${(amount / 10000).toStringAsFixed(1)}w';
      }
      return amount.toStringAsFixed(0);
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildGlassStatCard(
          title: ref.tr('order_total'),
          value: formatAmount(totalAmount),
          prefix: '¥',
          subtitle: ref
              .tr('admin_total_orders')
              .replaceFirst('{count}', '$totalOrders'),
          icon: Icons.trending_up_rounded,
          accentColor: const Color(0xFF06B6D4),
        ),
        _buildGlassStatCard(
          title: ref.tr('admin_product_count'),
          value: '$totalProducts',
          subtitle: ref.tr('admin_all_on_sale'),
          icon: Icons.diamond_rounded,
          accentColor: const Color(0xFF10B981),
        ),
        _buildGlassStatCard(
          title: ref.tr('order_pending_shipment'),
          value: '$pendingCount',
          subtitle: ref
              .tr('admin_shipped_orders_count')
              .replaceFirst('{count}', '$shippedCount'),
          icon: Icons.local_shipping_rounded,
          accentColor: const Color(0xFFF59E0B),
        ),
        _buildGlassStatCard(
          title: ref.tr('admin_product_categories'),
          value: '$totalProducts',
          subtitle: ref.tr('admin_jewelry_desc'),
          icon: Icons.auto_awesome_rounded,
          accentColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildStatsLoadingGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: List.generate(4, (_) => _buildGlassStatLoadingCard()),
    );
  }

  Widget _buildGlassStatCard({
    required String title,
    required String value,
    String? prefix,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: accentColor.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor.withOpacity(0.6), size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(children: [
                  if (prefix != null)
                    TextSpan(
                      text: prefix,
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStatLoadingCard() {
    Widget loadingLine({
      required double width,
      required double height,
      double opacity = 0.12,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              loadingLine(width: 86, height: 12),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              loadingLine(width: 72, height: 28, opacity: 0.18),
              const SizedBox(height: 8),
              loadingLine(width: 118, height: 11),
            ],
          ),
        ],
      ),
    );
  }

  // Restock suggestions.
  Widget _buildRestockSuggestions() {
    if (_restockSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              ref.tr('admin_restock_suggestion'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ref
                    .tr('admin_items_to_restock')
                    .replaceFirst('{count}', '${_restockSuggestions.length}'),
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Restock card list.
        ..._restockSuggestions.take(5).map((s) => _buildRestockCardFromApi(s)),

        if (_restockSuggestions.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
              child: Text(
                ref
                    .tr('admin_view_all_items')
                    .replaceFirst('{count}', '${_restockSuggestions.length}'),
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRestockCardFromApi(RestockSuggestion suggestion) {
    final language = ref.watch(appSettingsProvider).language;
    final urgency = suggestion.urgency;
    final Color urgencyColor;
    final String urgencyLabel;
    final IconData urgencyIcon;

    switch (urgency) {
      case 'critical':
        urgencyColor = const Color(0xFFEF4444);
        urgencyLabel = ref.tr('admin_urgency_out_of_stock');
        urgencyIcon = Icons.error_outline;
        break;
      case 'high':
        urgencyColor = const Color(0xFFF97316);
        urgencyLabel = ref.tr('admin_urgency_critical');
        urgencyIcon = Icons.warning_amber_rounded;
        break;
      default:
        urgencyColor = const Color(0xFFF59E0B);
        urgencyLabel = ref.tr('admin_urgency_suggested');
        urgencyIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgencyColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(urgencyIcon, color: urgencyColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ProductTranslator.translateName(
                      language, suggestion.productName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        urgencyLabel,
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ref.tr('admin_stock_count').replaceFirst(
                          '{count}', '${suggestion.currentStock}'),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ref
                    .tr('admin_suggested_restock')
                    .replaceFirst('{count}', '${suggestion.suggestedQuantity}'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '≈ ¥${(suggestion.price * suggestion.suggestedQuantity).toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Live activity feed.
  Widget _buildActivitySection() {
    const activityFilters = [
      AdminActivityTags.all,
      AdminActivityTags.orders,
      AdminActivityTags.stock,
      AdminActivityTags.system,
      AdminActivityTags.ai,
    ];

    final filtered = _activityFilter == AdminActivityTags.all
        ? _activities
        : _activities
            .where((a) => a.resolvedTagKey == _activityFilter)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 20),
            const SizedBox(width: 8),
            Text(ref.tr('admin_realtime_news'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(ref.tr('admin_auto_update_desc'),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: activityFilters.map((tagKey) {
              final selected = _activityFilter == tagKey;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activityFilter = tagKey);
                    _refreshActivities();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF06B6D4).withOpacity(0.15)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF06B6D4).withOpacity(0.4)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      ref.tr(tagKey),
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF06B6D4)
                            : Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        ...filtered.take(5).map((a) => _buildActivityItemFromApi(a)),
      ],
    );
  }

  Widget _buildActivityItemFromApi(ActivityItem activity) {
    Color color;
    try {
      color = Color(
        int.parse(activity.color.replaceFirst('#', '0xFF')),
      );
    } catch (_) {
      color = const Color(0xFF06B6D4);
    }

    IconData icon;
    switch (activity.icon) {
      case 'shopping_bag':
        icon = Icons.shopping_bag_rounded;
        break;
      case 'payment':
        icon = Icons.payment_rounded;
        break;
      case 'local_shipping':
        icon = Icons.local_shipping_rounded;
        break;
      case 'check_circle':
        icon = Icons.check_circle_rounded;
        break;
      case 'warning':
        icon = Icons.warning_amber_rounded;
        break;
      case 'monitor_heart':
        icon = Icons.monitor_heart_rounded;
        break;
      default:
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_activityTagLabel(activity),
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text(activity.time,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                    _activityText(
                        fallback: activity.title,
                        key: activity.titleKey,
                        args: activity.titleArgs),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(
                    _activityText(
                        fallback: activity.subtitle,
                        key: activity.subtitleKey,
                        args: activity.subtitleArgs),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _activityTagLabel(ActivityItem activity) {
    if (AdminActivityTags.localizedKeys.contains(activity.resolvedTagKey)) {
      return ref.tr(activity.resolvedTagKey);
    }
    return activity.tag;
  }

  String _activityText({
    required String fallback,
    String? key,
    Map<String, Object?>? args,
  }) {
    if (key == null || key.isEmpty) {
      return fallback;
    }
    return ref.tr(key, params: args ?? const {});
  }

  // Card-style quick actions.
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flash_on_rounded,
              color: Color(0xFFFBBF24),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              ref.tr('admin_quick_actions'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row 1
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                label: ref.tr('admin_add_product'),
                icon: Icons.add_circle_rounded,
                color: const Color(0xFF6366F1),
                onTap: () {
                  _tabController.animateTo(1);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _productManagementTabKey.currentState
                        ?.openAddProductDialog();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                label: ref.tr('admin_inventory_mgmt'),
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF06B6D4),
                onTap: () => _tabController.animateTo(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                label: ref.tr('admin_audit_log'),
                icon: Icons.history_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                label: ref.tr('admin_blockchain_verify'),
                icon: Icons.verified_user_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                label: ref.tr('admin_orders'),
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFFEC4899),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminOrderWorkbenchScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                label: ref.tr('payment_management_title'),
                icon: Icons.qr_code_2_rounded,
                color: const Color(0xFF14B8A6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentManagementScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.2), size: 18),
          ],
        ),
      ),
    );
  }

  // System status panel.
  Widget _buildSystemPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.monitor_heart_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              ref.tr('admin_system_status'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              _buildStatusItem(
                  ref.tr('admin_api_service'),
                  ref.tr('admin_running_normal'),
                  '32ms',
                  const Color(0xFF10B981),
                  true),
              _buildStatusDivider(),
              _buildStatusItem(
                  ref.tr('admin_ai_engine'),
                  ref.tr('admin_dashscope_online'),
                  ref.tr('admin_available'),
                  const Color(0xFF10B981),
                  true),
              _buildStatusDivider(),
              _buildStatusItem(
                  ref.tr('admin_blockchain_node'),
                  ref.tr('admin_connected'),
                  ref.tr('admin_syncing'),
                  const Color(0xFF10B981),
                  true),
              _buildStatusDivider(),
              _buildStatusItem(
                ref.tr('admin_data_backup'),
                ref.tr('admin_3hours_ago'),
                '2.3GB',
                const Color(0xFF06B6D4),
                true,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ref.tr('admin_compliance_footer'),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(
      String label, String status, String detail, Color color, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 13)),
          ),
          Text(status,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(detail, style: TextStyle(color: color, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDivider() {
    return Divider(
        color: Colors.white.withOpacity(0.04), height: 1, thickness: 1);
  }

  // Product management tab.
  Widget _buildProductManagementTab() {
    return AdminProductManagementTab(key: _productManagementTabKey);
  }

  // Operator management tab.
  Widget _buildOperatorTab() {
    return const AdminOperatorTab();
  }
}
