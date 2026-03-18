/// 汇玉源 - 管理员仪表盘
///
/// 功能:
/// - 全局数据概览
/// - 商品管理（添加/编辑/删除）
/// - 操作员管理
/// - 审计日志查看
/// - 系统设置
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../themes/colors.dart';
import '../../l10n/l10n_provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/common/error_handler.dart';
import 'inventory_screen.dart';

/// 管理员仪表盘
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedOperator = 0;
  late TabController _tabController;

  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  DashboardStats? _stats;
  List<RestockSuggestion> _restockSuggestions = [];
  List<ActivityItem> _activities = [];
  List<ProductModel> _products = [];
  String _activityFilter = '全部';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _adminService.initialize();
      final futures = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getRestockSuggestions(),
        _adminService.getRecentActivities(),
        _adminService.getProducts(),
      ]);

      if (mounted) {
        setState(() {
          _stats = futures[0] as DashboardStats?;
          _restockSuggestions = futures[1] as List<RestockSuggestion>;
          _activities = futures[2] as List<ActivityItem>;
          _products = futures[3] as List<ProductModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showError(e);
      }
    }
  }

  Future<void> _refreshActivities() async {
    final activities = await _adminService.getRecentActivities(filter: _activityFilter);
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
            // 顶部固定区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildHeader(),
            ),
            // Tab栏
            _buildTabBar(),
            // Tab内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
                Icon(Icons.dashboard_rounded, size: 15),
                SizedBox(width: 5),
                Text(ref.tr('admin_dashboard')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_rounded, size: 15),
                SizedBox(width: 5),
                Text(ref.tr('admin_products')),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_rounded, size: 15),
                SizedBox(width: 5),
                Text('库存'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_rounded, size: 15),
                SizedBox(width: 5),
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
    String greeting = '早上好';
    if (hour >= 12 && hour < 18) {
      greeting = '下午好';
    } else if (hour >= 18) {
      greeting = '晚上好';
    }

    final user = ref.watch(authProvider).valueOrNull;
    final displayName = user?.username ?? '管理员';
    final displayPhone = user?.phone ?? '';
    final roleLabel = user?.isSuperAdmin == true
        ? '超级管理员'
        : '管理员';

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
          child:
              const Icon(Icons.diamond_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting，$roleLabel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayPhone.isNotEmpty
                    ? '$displayName ($displayPhone)'
                    : displayName,
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
          onTap: () {},
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Colors.white70, size: 20),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════ 数据看板 Tab (Image-2 风格) ═══════════════════════════

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

  // ─── 门店信息卡片 ───
  Widget _buildStoreInfoCard() {
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
            child: const Icon(Icons.store_rounded,
                color: Color(0xFF06B6D4), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('汇玉源珠宝总店',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  '商品 ${_stats?.totalProducts ?? _products.length} 件 · 运营正常',
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF10B981), size: 6),
                SizedBox(width: 5),
                Text('在线',
                    style: TextStyle(
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

  // ─── 2x2 玻璃态统计卡片 ───
  Widget _buildGlassStatsGrid() {
    final totalOrders = _stats?.totalOrders ?? 0;
    final totalAmount = _stats?.totalAmount ?? 0.0;
    final pendingCount = _stats?.pendingOrders ?? 0;
    final shippedCount = _stats?.shippedOrders ?? 0;
    final totalProducts = _stats?.totalProducts ?? _products.length;

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
          title: '订单总额',
          value: formatAmount(totalAmount),
          prefix: '¥',
          subtitle: '共 $totalOrders 单',
          icon: Icons.trending_up_rounded,
          accentColor: const Color(0xFF06B6D4),
        ),
        _buildGlassStatCard(
          title: '商品总数',
          value: '$totalProducts',
          subtitle: '全部上架中',
          icon: Icons.diamond_rounded,
          accentColor: const Color(0xFF10B981),
        ),
        _buildGlassStatCard(
          title: '待发货',
          value: '$pendingCount',
          subtitle: '已发货 $shippedCount 单',
          icon: Icons.local_shipping_rounded,
          accentColor: const Color(0xFFF59E0B),
        ),
        _buildGlassStatCard(
          title: '商品种类',
          value: '$totalProducts',
          subtitle: '珠宝首饰',
          icon: Icons.auto_awesome_rounded,
          accentColor: const Color(0xFF8B5CF6),
        ),
      ],
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

  // ─── 智能补货建议 ───
  Widget _buildRestockSuggestions() {
    if (_restockSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 8),
            const Text(
              '智能补货建议',
              style: TextStyle(
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
                '${_restockSuggestions.length}件待补',
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

        // 补货卡片列表
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
                '查看全部 ${_restockSuggestions.length} 件 →',
                style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRestockCardFromApi(RestockSuggestion suggestion) {
    final urgency = suggestion.urgency;
    final Color urgencyColor;
    final String urgencyLabel;
    final IconData urgencyIcon;

    switch (urgency) {
      case 'critical':
        urgencyColor = const Color(0xFFEF4444);
        urgencyLabel = '断货';
        urgencyIcon = Icons.error_outline;
        break;
      case 'high':
        urgencyColor = const Color(0xFFF97316);
        urgencyLabel = '紧急';
        urgencyIcon = Icons.warning_amber_rounded;
        break;
      default:
        urgencyColor = const Color(0xFFF59E0B);
        urgencyLabel = '建议';
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
                  suggestion.productName,
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
                          horizontal: 6, vertical: 1),
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
                      '库存: ${suggestion.currentStock}',
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
                '建议补 ${suggestion.suggestedQuantity}',
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

  // ─── 实时动态（新闻流） ───
  Widget _buildActivitySection() {
    final filtered = _activityFilter == '全部'
        ? _activities
        : _activities.where((a) => a.tag == _activityFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 20),
            const SizedBox(width: 8),
            const Text('实时动态',
                style: TextStyle(
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
              child: Text('每30分钟自动更新',
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
            children: ['全部', '订单', '库存', '系统', 'AI'].map((tag) {
              final selected = _activityFilter == tag;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activityFilter = tag);
                    _refreshActivities();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      tag,
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
        ...filtered
            .take(5)
            .map((a) => _buildActivityItemFromApi(a))
            .toList(),
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
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(activity.tag,
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
                Text(activity.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(activity.subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 快捷操作（卡片式） ───
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on_rounded,
                color: const Color(0xFFFBBF24), size: 20),
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
                    _showAddProductDialog();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                label: '库存管理',
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

  // ─── 系统状态面板 ───
  Widget _buildSystemPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.monitor_heart_rounded,
                color: Color(0xFF10B981), size: 20),
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
                  'API 服务', '正常运行', '32ms', const Color(0xFF10B981), true),
              _buildStatusDivider(),
              _buildStatusItem('AI 引擎', 'OpenRouter 在线', '可用',
                  const Color(0xFF10B981), true),
              _buildStatusDivider(),
              _buildStatusItem(
                  '区块链节点', '已连接', '同步中', const Color(0xFF10B981), true),
              _buildStatusDivider(),
              _buildStatusItem(
                  '数据备份', '3小时前', '2.3GB', const Color(0xFF06B6D4), true),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_rounded,
                        color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '等保三级认证 · 数据加密传输 · 可用率 99.9%',
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

  // ============ 商品管理 Tab ============
  Widget _buildProductManagementTab() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '搜索商品',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.white.withOpacity(0.4), size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showAddProductDialog,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: JewelryColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: JewelryColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(ref.tr('admin_add_product'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '共 ${_products.length} 件商品',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '热门: ${_products.where((p) => p.isHot).length}  新品: ${_products.where((p) => p.isNew).length}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: JewelryColors.primary),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16)
                          .copyWith(bottom: 80),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductItem(_products[index]);
                      },
                    ),
            ),
          ],
        ),
        // 悬浮添加按钮 (FAB)
        Positioned(
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onTap: _showAddProductDialog,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // 商品缩略图
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: JewelryColors.getMaterialColor(product.material)
                  .withOpacity(0.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: product.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              JewelryColors.getMaterialColor(product.material),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.diamond,
                        color: JewelryColors.getMaterialColor(product.material),
                        size: 28,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.diamond,
                      color: JewelryColors.getMaterialColor(product.material),
                      size: 28,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
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
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: JewelryColors.getMaterialColor(product.material)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.material,
                        style: TextStyle(
                          color:
                              JewelryColors.getMaterialColor(product.material),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 10),
                      ),
                    ),
                    if (product.isHot) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: JewelryColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOT',
                          style: TextStyle(
                              color: JewelryColors.error, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '¥${product.price.toInt()}',
                      style: const TextStyle(
                        color: JewelryColors.price,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '库存 ${product.stock}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '已售 ${product.salesCount}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 操作按钮
          Column(
            children: [
              GestureDetector(
                onTap: () => _showEditProductDialog(product),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JewelryColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit,
                      color: JewelryColors.primary, size: 16),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showDeleteConfirm(product),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JewelryColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: JewelryColors.error, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ 操作员管理 Tab ============
  Widget _buildOperatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOperatorReports(),
        ],
      ),
    );
  }

  Widget _buildOperatorReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assessment, color: JewelryColors.gold, size: 20),
            const SizedBox(width: 8),
            const Text(
              '操作员简报',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                '查看全部',
                style: TextStyle(
                  color: JewelryColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 操作员选择
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, index) {
              final isSelected = _selectedOperator == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedOperator = index),
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? JewelryColors.primaryGradient : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // 详细报告
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildReportRow('联系店铺', '23 家', JewelryColors.primary),
              _buildReportRow('成交意向', '8 笔', JewelryColors.gold),
              _buildReportRow('成功合作', '3 家', JewelryColors.success),
              _buildReportRow('AI使用次数', '156 次', const Color(0xFF667eea)),
              _buildReportRow('订单金额', '¥8,560', JewelryColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============ 对话框 ============

  /// 显示添加商品对话框
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final originalPriceController = TextEditingController();
    final descController = TextEditingController();
    final stockController = TextEditingController(text: '100');
    final imageUrlController = TextEditingController();
    String selectedCategory = '手链';
    String selectedMaterial = '和田玉';
    // 保存父级 context
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setDialogState) {
          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // 头部
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_box, color: JewelryColors.primary),
                      const SizedBox(width: 10),
                      const Text(
                        '添加新商品',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Icon(Icons.close,
                            color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
                // 表单
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogInput('商品名称 *', nameController,
                            hint: '例: 新疆和田玉手链'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildDialogInput(
                                    '售价 *', priceController,
                                    hint: '299',
                                    keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildDialogInput(
                                    '原价', originalPriceController,
                                    hint: '599',
                                    keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 分类选择
                        _buildDialogLabel('商品分类'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            '手链',
                            '吊坠',
                            '戒指',
                            '手镯',
                            '项链',
                            '手串',
                            '耳饰',
                            '摆件'
                          ].map((cat) {
                            final isSelected = selectedCategory == cat;
                            return GestureDetector(
                              onTap: () =>
                                  setDialogState(() => selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? JewelryColors.primaryGradient
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // 材质选择
                        _buildDialogLabel('材质类型'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            '和田玉',
                            '缅甸翡翠',
                            '南红玛瑙',
                            '紫水晶',
                            '黄金',
                            '红宝石',
                            '蓝宝石',
                            '碧玉',
                            '蜜蜡',
                            '钻石',
                            '珍珠'
                          ].map((mat) {
                            final isSelected = selectedMaterial == mat;
                            return GestureDetector(
                              onTap: () =>
                                  setDialogState(() => selectedMaterial = mat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? JewelryColors.goldGradient
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  mat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildDialogInput('库存数量', stockController,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildDialogInput('商品描述', descController,
                            hint: '详细描述商品特点...', maxLines: 3),
                        const SizedBox(height: 16),
                        // 图片选择区域
                        _buildDialogLabel('商品图片'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // 本地选图按钮 - 从相册
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1920,
                                  maxHeight: 1920,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setDialogState(() {
                                    imageUrlController.text = image.path;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: JewelryColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_library,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text('相册选择',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 本地选图按钮 - 拍照
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(
                                  source: ImageSource.camera,
                                  maxWidth: 1920,
                                  maxHeight: 1920,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setDialogState(() {
                                    imageUrlController.text = image.path;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.2)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt,
                                        color: Colors.white70, size: 18),
                                    SizedBox(width: 6),
                                    Text('拍照',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 图片预览 / URL 输入
                        if (imageUrlController.text.isNotEmpty) ...[
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      JewelryColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle,
                                    color: JewelryColors.success, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    imageUrlController.text.length > 40
                                        ? '...${imageUrlController.text.substring(imageUrlController.text.length - 40)}'
                                        : imageUrlController.text,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 18),
                                  onPressed: () => setDialogState(
                                      () => imageUrlController.clear()),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          _buildDialogInput('或输入图片URL', imageUrlController,
                              hint: 'https://...（留空则自动生成）'),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // 底部按钮
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('取消',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () async {
                            if (nameController.text.trim().isEmpty ||
                                priceController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                    content: Text('请填写商品名称和价格'),
                                    backgroundColor: JewelryColors.error),
                              );
                              return;
                            }

                            final imgUrl = imageUrlController.text
                                    .trim()
                                    .isNotEmpty
                                ? imageUrlController.text.trim()
                                : 'https://picsum.photos/400/400';

                            final productData = {
                              'name': nameController.text.trim(),
                              'description': descController.text.trim().isEmpty
                                  ? '优质$selectedMaterial$selectedCategory，品质保证。'
                                  : descController.text.trim(),
                              'price': double.tryParse(priceController.text) ?? 0,
                              'original_price': double.tryParse(originalPriceController.text),
                              'category': selectedCategory,
                              'material': selectedMaterial,
                              'images': [imgUrl],
                              'stock': int.tryParse(stockController.text) ?? 100,
                              'is_new': true,
                              'certificate': 'NGTC-${DateTime.now().year}-NEW',
                            };

                            Navigator.pop(sheetContext);

                            final createdProduct = await _adminService.createProduct(productData);
                            if (createdProduct != null && mounted) {
                              setState(() {
                                _products.insert(0, createdProduct);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ 商品 "${createdProduct.name}" 已成功添加'),
                                  backgroundColor: JewelryColors.success,
                                ),
                              );
                            } else if (mounted) {
                              context.showError('添加商品失败，请重试');
                            }
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: JewelryColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '确认添加',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDialogInput(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDialogLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  /// 编辑商品对话框
  void _showEditProductDialog(ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final priceController =
        TextEditingController(text: product.price.toStringAsFixed(0));
    final originalPriceController = TextEditingController(
        text: product.originalPrice?.toStringAsFixed(0) ?? '');
    final stockController =
        TextEditingController(text: product.stock.toString());
    final descController = TextEditingController(text: product.description);
    String selectedCategory = product.category;
    String selectedMaterial = product.material;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setDialogState) {
          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: JewelryColors.gold),
                      const SizedBox(width: 10),
                      const Text('编辑商品',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Icon(Icons.close,
                            color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogInput('商品名称', nameController),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildDialogInput('售价', priceController,
                                    keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildDialogInput(
                                    '原价', originalPriceController,
                                    keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDialogLabel('分类'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            '手链',
                            '吊坠',
                            '戒指',
                            '手镯',
                            '项链',
                            '手串',
                            '耳饰',
                            '摆件'
                          ].map((cat) {
                            final isS = selectedCategory == cat;
                            return GestureDetector(
                              onTap: () =>
                                  setDialogState(() => selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isS
                                      ? JewelryColors.primaryGradient
                                      : null,
                                  color: isS
                                      ? null
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(cat,
                                    style: TextStyle(
                                        color:
                                            isS ? Colors.white : Colors.white60,
                                        fontSize: 13)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildDialogLabel('材质'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            '和田玉',
                            '缅甸翡翠',
                            '南红玛瑙',
                            '紫水晶',
                            '黄金',
                            '红宝石',
                            '蓝宝石',
                            '碧玉',
                            '蜜蜡',
                            '钻石',
                            '珍珠'
                          ].map((mat) {
                            final isS = selectedMaterial == mat;
                            return GestureDetector(
                              onTap: () =>
                                  setDialogState(() => selectedMaterial = mat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient:
                                      isS ? JewelryColors.goldGradient : null,
                                  color: isS
                                      ? null
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(mat,
                                    style: TextStyle(
                                        color: isS
                                            ? Colors.black87
                                            : Colors.white60,
                                        fontSize: 13)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildDialogInput('库存', stockController,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildDialogInput('描述', descController, maxLines: 3),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Center(
                                child: Text('取消',
                                    style: TextStyle(color: Colors.white70))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () async {
                            final productData = {
                              'name': nameController.text.trim(),
                              'description': descController.text.trim(),
                              'price': double.tryParse(priceController.text) ?? product.price,
                              'original_price': double.tryParse(originalPriceController.text),
                              'category': selectedCategory,
                              'material': selectedMaterial,
                              'stock': int.tryParse(stockController.text) ?? product.stock,
                            };

                            Navigator.pop(sheetContext);

                            final updatedProduct = await _adminService.updateProduct(product.id, productData);
                            if (updatedProduct != null && mounted) {
                              final idx = _products.indexWhere((p) => p.id == product.id);
                              if (idx >= 0) {
                                setState(() {
                                  _products[idx] = updatedProduct;
                                });
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ 商品 "${updatedProduct.name}" 已更新'),
                                  backgroundColor: JewelryColors.success,
                                ),
                              );
                            } else if (mounted) {
                              context.showError('更新商品失败，请重试');
                            }
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                                gradient: JewelryColors.goldGradient,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Center(
                                child: Text('保存修改',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 删除确认对话框
  void _showDeleteConfirm(ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除商品 "${product.name}" 吗？\n此操作不可恢复。',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('取消',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await _adminService.deleteProduct(product.id);
              if (success && mounted) {
                setState(() {
                  _products.removeWhere((p) => p.id == product.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('商品 "${product.name}" 已删除'),
                    backgroundColor: JewelryColors.error,
                  ),
                );
              } else if (mounted) {
                context.showError('删除商品失败，请重试');
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: JewelryColors.error),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}
