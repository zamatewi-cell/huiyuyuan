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
import '../../data/product_data.dart';
import '../../models/user_model.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          Tab(text: '📊 ${ref.tr('admin_dashboard')}'),
          Tab(text: '🏪 ${ref.tr('admin_products')}'),
          Tab(text: '👥 ${ref.tr('admin_operators')}'),
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

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: JewelryColors.primaryGradient,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.admin_panel_settings, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting，超级管理员',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '账号: 18937766669',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddProductBanner(),
          const SizedBox(height: 16),
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildSystemStatus(),
        ],
      ),
    );
  }

  /// 添加商品醒目横幅按钮
  Widget _buildAddProductBanner() {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(1);
        Future.delayed(const Duration(milliseconds: 300), () {
          _showAddProductDialog();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_circle_outline,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '➕ ${ref.tr('admin_add_product')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '当前共 ${realProductData.length} 件商品 · 点击立即上架新商品',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '立即添加',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: '今日订单',
          value: '¥12,580',
          change: '+18.5%',
          icon: Icons.shopping_cart,
          gradient: JewelryColors.primaryGradient,
        ),
        _buildStatCard(
          title: '活跃操作员',
          value: '8/10',
          change: '在线',
          icon: Icons.people,
          gradient: JewelryColors.goldGradient,
        ),
        _buildStatCard(
          title: '商品总数',
          value: '${realProductData.length}',
          change: '上架中',
          icon: Icons.inventory_2,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        _buildStatCard(
          title: 'AI使用量',
          value: '1,280',
          change: '次对话',
          icon: Icons.smart_toy,
          gradient: const LinearGradient(
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                change,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: JewelryColors.gold, size: 20),
            SizedBox(width: 8),
            Text(
              ref.tr('admin_quick_actions'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildActionButton(
                    ref.tr('admin_add_product'), Icons.add_box, onTap: () {
              _tabController.animateTo(1);
              Future.delayed(const Duration(milliseconds: 300), () {
                _showAddProductDialog();
              });
            })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildActionButton(
                    ref.tr('admin_audit_log'), Icons.history)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildActionButton(ref.tr('admin_account_settings'),
                    Icons.account_balance_wallet)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildActionButton(
                    ref.tr('admin_blockchain_verify'), Icons.verified_user)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: JewelryColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.monitor_heart, color: JewelryColors.success, size: 20),
            SizedBox(width: 8),
            Text(
              ref.tr('admin_system_status'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _buildStatusRow('API服务', '正常运行', true),
              _buildStatusRow('AI引擎', 'DeepSeek 在线', true),
              _buildStatusRow('区块链节点', '已连接', true),
              _buildStatusRow('数据备份', '3小时前', true),
              const Divider(color: Colors.white12, height: 24),
              Row(
                children: [
                  const Icon(Icons.shield,
                      color: JewelryColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '等保三级认证 · 数据加密传输',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isHealthy ? JewelryColors.success : JewelryColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: isHealthy ? JewelryColors.success : JewelryColors.error,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============ 商品管理 Tab ============
  Widget _buildProductManagementTab() {
    return Stack(
      children: [
        Column(
          children: [
            // 操作栏
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
                          hintText: ref.tr('admin_products'), // 简单复用商品管理
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
            // 商品数量信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '共 ${realProductData.length} 件商品',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '热门: ${getHotProducts().length}  福利: ${getWelfareProducts().length}  新品: ${getNewProducts().length}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 商品列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(bottom: 80),
                itemCount: realProductData.length,
                itemBuilder: (context, index) {
                  return _buildProductItem(realProductData[index]);
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
                          onTap: () {
                            if (nameController.text.trim().isEmpty ||
                                priceController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                    content: Text('请填写商品名称和价格'),
                                    backgroundColor: JewelryColors.error),
                              );
                              return;
                            }

                            // 图片URL：用户填写的 或 自动生成的
                            final imgUrl = imageUrlController.text
                                    .trim()
                                    .isNotEmpty
                                ? imageUrlController.text.trim()
                                : getDefaultImageForMaterial(selectedMaterial);

                            final newProduct = ProductModel(
                              id: 'HYY-NEW${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text.trim(),
                              description: descController.text.trim().isEmpty
                                  ? '优质$selectedMaterial$selectedCategory，品质保证。'
                                  : descController.text.trim(),
                              price: double.tryParse(priceController.text) ?? 0,
                              originalPrice:
                                  double.tryParse(originalPriceController.text),
                              category: selectedCategory,
                              material: selectedMaterial,
                              images: [imgUrl],
                              stock: int.tryParse(stockController.text) ?? 100,
                              isNew: true,
                              certificate: 'NGTC-${DateTime.now().year}-NEW',
                              blockchainHash:
                                  '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
                            );

                            addProduct(newProduct);
                            Navigator.pop(sheetContext);
                            setState(() {});

                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content:
                                    Text('✅ 商品 "${newProduct.name}" 已成功添加'),
                                backgroundColor: JewelryColors.success,
                              ),
                            );
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
                          onTap: () {
                            // 找到商品在列表中的索引，用新对象替换
                            final idx = realProductData
                                .indexWhere((p) => p.id == product.id);
                            if (idx >= 0) {
                              realProductData[idx] = ProductModel(
                                id: product.id,
                                name: nameController.text.trim(),
                                description: descController.text.trim(),
                                price: double.tryParse(priceController.text) ??
                                    product.price,
                                originalPrice: double.tryParse(
                                    originalPriceController.text),
                                category: selectedCategory,
                                material: selectedMaterial,
                                images: product.images,
                                stock: int.tryParse(stockController.text) ??
                                    product.stock,
                                rating: product.rating,
                                salesCount: product.salesCount,
                                isHot: product.isHot,
                                isNew: product.isNew,
                                origin: product.origin,
                                certificate: product.certificate,
                                blockchainHash: product.blockchainHash,
                                isWelfare: product.isWelfare,
                                materialVerify: product.materialVerify,
                              );
                            }
                            Navigator.pop(sheetContext);
                            setState(() {});
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '✅ 商品 "${nameController.text.trim()}" 已更新'),
                                backgroundColor: JewelryColors.success,
                              ),
                            );
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除商品 "${product.name}" 吗？\n此操作不可恢复。',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              removeProduct(product.id);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('商品 "${product.name}" 已删除'),
                  backgroundColor: JewelryColors.error,
                ),
              );
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
