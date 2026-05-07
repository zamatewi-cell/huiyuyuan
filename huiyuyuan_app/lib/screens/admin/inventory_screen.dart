/// HuiYuYuan internal inventory management screen.
library;

import 'package:flutter/material.dart';
import '../../l10n/translator_global.dart';
import '../../l10n/l10n_provider.dart';
import '../../l10n/product_translator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/inventory_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../themes/colors.dart';

/// Formats an amount for compact display.
String _fmtMoney(AppLanguage language, double v) {
  if (v >= 10000) {
    switch (language) {
      case AppLanguage.en:
        if (v >= 1000000) {
          return '¥${(v / 1000000).toStringAsFixed(1)}M';
        }
        return '¥${(v / 1000).toStringAsFixed(1)}K';
      case AppLanguage.zhTW:
        return '¥${(v / 10000).toStringAsFixed(1)}萬';
      case AppLanguage.zhCN:
        return '¥${(v / 10000).toStringAsFixed(1)}万';
    }
  }
  return '¥${v.toStringAsFixed(0)}';
}

/// Inventory management screen.
String _inventoryProductNameL10n(AppLanguage language, String productName) {
  return ProductTranslator.translateName(language, productName);
}

String _inventoryCategoryL10n(AppLanguage language, String category) {
  final canonical = ProductTranslator.canonicalCategory(category);
  return ProductTranslator.translateCategory(language, canonical);
}

class _InventoryBackdrop extends StatelessWidget {
  const _InventoryBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _InventoryGlowOrb(
              size: 340,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            top: 360,
            child: _InventoryGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _InventoryTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryGlowOrb extends StatelessWidget {
  const _InventoryGlowOrb({required this.size, required this.color});

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

class _InventoryTracePainter extends CustomPainter {
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
        y - 30,
        size.width * 0.72,
        y + 34,
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InventoryTracePainter oldDelegate) => false;
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterCategory = 'order_all';

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
    final user = ref.watch(currentUserProvider);
    final canRead = _canReadInventory(user);
    final canWrite = _canWriteInventory(user);

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      body: Stack(
        children: [
          const Positioned.fill(child: _InventoryBackdrop()),
          SafeArea(
            child: canRead
                ? Column(
                    children: [
                      _buildHeader(),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildStockListTab(),
                            _buildTransactionTab(),
                          ],
                        ),
                      ),
                    ],
                  )
                : _buildPermissionDeniedState(),
          ),
        ],
      ),
      floatingActionButton: canRead && canWrite ? _buildFAB() : null,
    );
  }

  bool _canReadInventory(UserModel? user) {
    if (user == null) {
      return true;
    }
    if (user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('inventory_read') ||
        user.hasPermission('inventory_write');
  }

  bool _canWriteInventory(UserModel? user) {
    if (user == null) {
      return true;
    }
    if (user.isAdmin) {
      return true;
    }
    if (user.userType != UserType.operator) {
      return false;
    }
    return user.hasPermission('inventory_write');
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: JewelryColors.deepJade.withOpacity(0.58),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: JewelryColors.champagneGold.withOpacity(0.12),
                ),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: JewelryColors.champagneGold,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              TranslatorGlobal.instance.translate('operator_permission_denied'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── Header ───────────
  Widget _buildHeader() {
    final stats = ref.watch(inventoryStatsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: JewelryColors.emeraldLusterGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: JewelryColors.emeraldGlow.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: const Icon(Icons.warehouse_rounded,
                color: JewelryColors.jadeBlack, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    TranslatorGlobal.instance.translate('admin_inventory_mgmt'),
                    style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                Text(
                  ref.tr(
                    'inventory_header_summary',
                    params: {
                      'skuCount': stats.totalSkus,
                      'unitCount': stats.totalUnits,
                    },
                  ),
                  style: TextStyle(
                      color: JewelryColors.jadeMist.withOpacity(0.56),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          if (stats.lowStockCount > 0 || stats.outOfStockCount > 0)
            _buildAlertBadge(stats),
        ],
      ),
    );
  }

  Widget _buildAlertBadge(InventoryStats stats) {
    final total = stats.lowStockCount + stats.outOfStockCount;
    return GestureDetector(
      onTap: () => _tabController.animateTo(1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              color: JewelryColors.jadeMist,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
                TranslatorGlobal.instance.translate('inventory_alert_badge',
                    params: {'count': total}),
                style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ─────────── TabBar ───────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: JewelryColors.deepJade.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.12),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: JewelryColors.emeraldLusterGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        labelColor: JewelryColors.jadeBlack,
        unselectedLabelColor: JewelryColors.jadeMist.withOpacity(0.58),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_rounded, size: 15),
                const SizedBox(width: 5),
                Text(TranslatorGlobal.instance.translate('inventory_overview')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_rounded, size: 15),
                const SizedBox(width: 5),
                Text(TranslatorGlobal.instance.translate('product_stock')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 15),
                const SizedBox(width: 5),
                Text(TranslatorGlobal.instance
                    .translate('inventory_transactions')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── FAB ───────────
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF06B6D4),
      onPressed: _showStockOperationSheet,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
          TranslatorGlobal.instance.translate('inventory_stock_movement'),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // Overview tab.
  Widget _buildOverviewTab() {
    final stats = ref.watch(inventoryStatsProvider);
    final lowStockItems = ref.watch(lowStockItemsProvider);
    final language = ref.watch(appSettingsProvider).language;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(stats),
          const SizedBox(height: 20),
          _buildValueCards(stats, language),
          if (lowStockItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildLowStockWarning(lowStockItems),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(InventoryStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          TranslatorGlobal.instance.translate('inventory_stat_sku_types'),
          '${stats.totalSkus} SKU',
          TranslatorGlobal.instance.translate('inventory_stat_all_recorded'),
          Icons.category_rounded,
          const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)]),
        ),
        _buildStatCard(
          TranslatorGlobal.instance.translate('inventory_stat_total_stock'),
          TranslatorGlobal.instance.translate('inventory_units',
              params: {'count': stats.totalUnits}),
          TranslatorGlobal.instance.translate('inventory_stat_physical_stock'),
          Icons.inventory_2_rounded,
          JewelryColors.primaryGradient,
        ),
        _buildStatCard(
          TranslatorGlobal.instance.translate('inventory_stat_low_stock_alert'),
          TranslatorGlobal.instance.translate('inventory_item_types',
              params: {'count': stats.lowStockCount}),
          stats.lowStockCount > 0
              ? TranslatorGlobal.instance
                  .translate('inventory_low_stock_need_restock')
              : TranslatorGlobal.instance
                  .translate('inventory_low_stock_ready'),
          Icons.warning_amber_rounded,
          stats.lowStockCount > 0
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF97316)])
              : const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)]),
        ),
        _buildStatCard(
          TranslatorGlobal.instance
              .translate('inventory_stat_monthly_transactions'),
          TranslatorGlobal.instance.translate('inventory_record_count',
              params: {'count': stats.txCountThisMonth}),
          TranslatorGlobal.instance
              .translate('inventory_stat_stock_movement_records'),
          Icons.receipt_long_rounded,
          JewelryColors.goldGradient,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String sub, IconData icon,
      LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 12)),
              Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(sub,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueCards(InventoryStats stats, AppLanguage language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TranslatorGlobal.instance.translate('inventory_valuation_title'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: Row(
            children: [
              _buildValueItem(
                TranslatorGlobal.instance
                    .translate('inventory_total_cost_value'),
                _fmtMoney(language, stats.totalCostValue),
                const Color(0xFF94A3B8),
              ),
              _buildValueDivider(),
              _buildValueItem(
                TranslatorGlobal.instance
                    .translate('inventory_total_market_value'),
                _fmtMoney(language, stats.totalSellingValue),
                const Color(0xFF34D399),
              ),
              _buildValueDivider(),
              _buildValueItem(
                TranslatorGlobal.instance
                    .translate('inventory_margin_potential'),
                _fmtMoney(
                  language,
                  stats.totalSellingValue - stats.totalCostValue,
                ),
                const Color(0xFFFFD700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValueItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildValueDivider() {
    return Container(
        width: 1, height: 40, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildLowStockWarning(List<InventoryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_rounded,
                color: Color(0xFFF97316), size: 18),
            const SizedBox(width: 6),
            Text(TranslatorGlobal.instance.translate('inventory_alert_title'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
                TranslatorGlobal.instance.translate('inventory_item_count',
                    params: {'count': items.length}),
                style: const TextStyle(color: Color(0xFFF97316), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        ...items.take(5).map((item) => _buildWarningRow(item)),
        if (items.length > 5)
          TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: Text(
                TranslatorGlobal.instance.translate('inventory_view_all_alerts',
                    params: {'count': items.length}),
                style: const TextStyle(color: Color(0xFF06B6D4))),
          ),
      ],
    );
  }

  Widget _buildWarningRow(InventoryItem item) {
    final language = ref.watch(appSettingsProvider).language;
    final productName = _inventoryProductNameL10n(language, item.productName);
    final category = _inventoryCategoryL10n(language, item.category);
    final isOut = item.isOutOfStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOut
            ? const Color(0xFFEF4444).withOpacity(0.12)
            : const Color(0xFFF97316).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOut
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : const Color(0xFFF97316).withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOut ? const Color(0xFFEF4444) : const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOut
                  ? TranslatorGlobal.instance
                      .translate('inventory_status_sold_out')
                  : TranslatorGlobal.instance
                      .translate('inventory_status_low_stock'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(category,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TranslatorGlobal.instance.translate('inventory_units',
                    params: {'count': item.currentStock}),
                style: TextStyle(
                    color: isOut
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF97316),
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              Text(
                  TranslatorGlobal.instance.translate('inventory_safety_line',
                      params: {'count': item.minStock}),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // Stock list tab.
  Widget _buildStockListTab() {
    final items = ref.watch(inventoryProvider);
    final language = ref.watch(appSettingsProvider).language;

    // Category list.
    final categories = [
      TranslatorGlobal.instance.translate('order_all'),
      ...{...items.map((e) => _inventoryCategoryL10n(language, e.category))}
    ];
    final filtered = items.where((e) {
      final localizedName = _inventoryProductNameL10n(language, e.productName);
      final localizedCategory = _inventoryCategoryL10n(language, e.category);
      final matchCat =
          _filterCategory == TranslatorGlobal.instance.translate('order_all') ||
              localizedCategory == _filterCategory;
      final matchSearch = _searchQuery.isEmpty ||
          localizedName.contains(_searchQuery) ||
          e.productName.contains(_searchQuery) ||
          e.productId.contains(_searchQuery);
      return matchCat && matchSearch;
    }).toList();

    return Column(
      children: [
        // Search bar.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: TranslatorGlobal.instance
                          .translate('inventory_search_name_or_id'),
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withOpacity(0.4), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Category filters.
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = cat == _filterCategory;
              return GestureDetector(
                onTap: () => setState(() => _filterCategory = cat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)])
                        : null,
                    color: selected ? null : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(cat,
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.55),
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                ),
              );
            },
          ),
        ),
        // Inventory list.
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                      TranslatorGlobal.instance
                          .translate('inventory_empty_products'),
                      style: TextStyle(color: Colors.white.withOpacity(0.4))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildStockRow(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildStockRow(InventoryItem item) {
    final language = ref.watch(appSettingsProvider).language;
    final productName = _inventoryProductNameL10n(language, item.productName);
    final category = _inventoryCategoryL10n(language, item.category);
    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;

    Color stockColor = Colors.white;
    if (isOut) {
      stockColor = const Color(0xFFEF4444);
    } else if (isLow) {
      stockColor = const Color(0xFFF97316);
    } else {
      stockColor = const Color(0xFF34D399);
    }

    return GestureDetector(
      onTap: () => _showItemDetailSheet(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isOut || isLow)
                ? stockColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            // Product image.
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            const SizedBox(width: 12),
            // Product information.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _tag(category, const Color(0xFF6366F1)),
                      const SizedBox(width: 6),
                      Text(item.productId,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      ref.tr(
                        'inventory_cost_price_row',
                        params: {
                          'cost': item.costPrice.toStringAsFixed(0),
                          'price': item.sellingPrice.toStringAsFixed(0),
                        },
                      ),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45), fontSize: 11)),
                ],
              ),
            ),
            // Stock count.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.currentStock}',
                    style: TextStyle(
                        color: stockColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(
                    TranslatorGlobal.instance.translate('inventory_unit_piece'),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45), fontSize: 11)),
                if (isOut)
                  _tag(
                      TranslatorGlobal.instance
                          .translate('inventory_status_sold_out'),
                      const Color(0xFFEF4444))
                else if (isLow)
                  _tag(
                      TranslatorGlobal.instance
                          .translate('inventory_status_low_stock'),
                      const Color(0xFFF97316)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 54,
      height: 54,
      color: Colors.white.withOpacity(0.08),
      child: const Icon(Icons.diamond_rounded, color: Colors.white24, size: 24),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  // Transaction tab.
  Widget _buildTransactionTab() {
    final txs = ref.watch(inventoryTxProvider);
    return txs.isEmpty
        ? Center(
            child: Text(
                TranslatorGlobal.instance
                    .translate('inventory_empty_transactions'),
                style: TextStyle(color: Colors.white.withOpacity(0.4))))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            itemCount: txs.length,
            itemBuilder: (_, i) => _buildTxRow(txs[i]),
          );
  }

  Widget _buildTxRow(InventoryTransaction tx) {
    final language = ref.watch(appSettingsProvider).language;
    final productName = _inventoryProductNameL10n(language, tx.productName);
    final isPositive = tx.type.isPositive;
    final color =
        isPositive ? const Color(0xFF34D399) : const Color(0xFFEF4444);
    final sign = isPositive ? '+' : '-';
    final typeColors = {
      InventoryTxType.stockIn: const Color(0xFF34D399),
      InventoryTxType.stockOut: const Color(0xFFEF4444),
      InventoryTxType.adjustment: const Color(0xFF94A3B8),
      InventoryTxType.returnIn: const Color(0xFF06B6D4),
    };
    final bgColors = {
      InventoryTxType.stockIn: const Color(0xFF34D399),
      InventoryTxType.stockOut: const Color(0xFFEF4444),
      InventoryTxType.adjustment: const Color(0xFF64748B),
      InventoryTxType.returnIn: const Color(0xFF06B6D4),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          // Type icon.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColors[tx.type]!.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tx.type == InventoryTxType.stockIn
                  ? Icons.arrow_downward_rounded
                  : tx.type == InventoryTxType.stockOut
                      ? Icons.arrow_upward_rounded
                      : tx.type == InventoryTxType.returnIn
                          ? Icons.undo_rounded
                          : Icons.tune_rounded,
              color: typeColors[tx.type],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _tag(tx.type.label, typeColors[tx.type]!),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(productName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (tx.note != null)
                  Text(tx.note!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45), fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${tx.operatorName ?? TranslatorGlobal.instance.translate('product_unknown')} · ${DateFormat('MM-dd HH:mm').format(tx.createdAt)}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  TranslatorGlobal.instance.translate('inventory_tx_quantity',
                      params: {'sign': sign, 'count': tx.quantity}),
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${tx.stockBefore}→${tx.stockAfter}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // Bottom sheet for stock in/out actions.
  void _showStockOperationSheet() {
    if (!_canWriteInventory(ref.read(currentUserProvider))) {
      _showSnack(
          TranslatorGlobal.instance.translate('operator_permission_denied'),
          isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockOperationSheet(
        onConfirm: (productId, type, quantity, note, operator) {
          _doStockOperation(productId, type, quantity, note, operator);
        },
      ),
    );
  }

  void _doStockOperation(String productId, InventoryTxType type, int quantity,
      String? note, String? operatorName) {
    final notifier = ref.read(inventoryProvider.notifier);
    final txNotifier = ref.read(inventoryTxProvider.notifier);
    final language = ref.read(appSettingsProvider).language;
    final item = notifier.getItem(productId);
    if (item == null) {
      _showSnack(
          TranslatorGlobal.instance.translate('inventory_item_not_found'),
          isError: true);
      return;
    }

    final before = item.currentStock;
    final localizedProductName =
        _inventoryProductNameL10n(language, item.productName);
    bool success = false;

    switch (type) {
      case InventoryTxType.stockIn:
      case InventoryTxType.returnIn:
        success = notifier.stockIn(productId: productId, quantity: quantity);
        break;
      case InventoryTxType.stockOut:
        success = notifier.stockOut(productId: productId, quantity: quantity);
        break;
      case InventoryTxType.adjustment:
        success = notifier.adjust(productId: productId, newStock: quantity);
        break;
    }

    if (!success) {
      _showSnack(
        type == InventoryTxType.stockOut
            ? TranslatorGlobal.instance
                .translate('inventory_error_insufficient_stock')
            : TranslatorGlobal.instance
                .translate('inventory_error_operation_failed'),
        isError: true,
      );
      return;
    }

    final after = type == InventoryTxType.adjustment
        ? quantity
        : (type.isPositive ? before + quantity : before - quantity);

    txNotifier.addTransaction(InventoryTransaction(
      id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: localizedProductName,
      type: type,
      quantity: quantity,
      stockBefore: before,
      stockAfter: after,
      note: note,
      operatorName: operatorName ??
          TranslatorGlobal.instance.translate('inventory_operator_admin'),
      createdAt: DateTime.now(),
    ));

    _showSnack(TranslatorGlobal.instance
        .translate('inventory_operation_success', params: {
      'action': type.label,
      'productName': localizedProductName,
      'quantity': quantity,
    }));
  }

  // Bottom sheet for product inventory details.
  void _showItemDetailSheet(InventoryItem item) {
    final canWrite = _canWriteInventory(ref.read(currentUserProvider));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(
        item: item,
        readOnly: !canWrite,
        onStockIn: () {
          Navigator.pop(context);
          _showStockOperationSheetForProduct(
              item.productId, InventoryTxType.stockIn);
        },
        onStockOut: () {
          Navigator.pop(context);
          _showStockOperationSheetForProduct(
              item.productId, InventoryTxType.stockOut);
        },
        onAdjust: (newStock, note) {
          Navigator.pop(context);
          _doStockOperation(
              item.productId, InventoryTxType.adjustment, newStock, note, null);
        },
      ),
    );
  }

  void _showStockOperationSheetForProduct(
      String productId, InventoryTxType type) {
    if (!_canWriteInventory(ref.read(currentUserProvider))) {
      _showSnack(
          TranslatorGlobal.instance.translate('operator_permission_denied'),
          isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockOperationSheet(
        initialProductId: productId,
        initialType: type,
        onConfirm: (pid, t, q, note, op) =>
            _doStockOperation(pid, t, q, note, op),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Stock in/out action sheet.
class _StockOperationSheet extends ConsumerStatefulWidget {
  final String? initialProductId;
  final InventoryTxType initialType;
  final void Function(String productId, InventoryTxType type, int quantity,
      String? note, String? operator) onConfirm;

  const _StockOperationSheet({
    this.initialProductId,
    this.initialType = InventoryTxType.stockIn,
    required this.onConfirm,
  });

  @override
  ConsumerState<_StockOperationSheet> createState() =>
      _StockOperationSheetState();
}

class _StockOperationSheetState extends ConsumerState<_StockOperationSheet> {
  String? _selectedProductId;
  late InventoryTxType _type;
  final _qtyController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  final _opController = TextEditingController(
      text: TranslatorGlobal.instance.translate('inventory_operator_admin'));
  String _productSearch = '';

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    _opController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryProvider);
    final language = ref.watch(appSettingsProvider).language;
    final filtered = items
        .where((e) =>
            _productSearch.isEmpty ||
            _inventoryProductNameL10n(language, e.productName)
                .contains(_productSearch) ||
            e.productName.contains(_productSearch) ||
            e.productId.contains(_productSearch))
        .toList();
    final selectedItem = _selectedProductId != null
        ? items.where((e) => e.productId == _selectedProductId).firstOrNull
        : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2D3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Sheet handle and title.
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                    TranslatorGlobal.instance
                        .translate('inventory_operation_sheet_title'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Operation type.
                  _sectionLabel(TranslatorGlobal.instance
                      .translate('inventory_operation_type')),
                  const SizedBox(height: 8),
                  Row(
                    children: InventoryTxType.values.map((t) {
                      final selected = _type == t;
                      final color = t == InventoryTxType.stockIn
                          ? const Color(0xFF34D399)
                          : t == InventoryTxType.stockOut
                              ? const Color(0xFFEF4444)
                              : t == InventoryTxType.returnIn
                                  ? const Color(0xFF06B6D4)
                                  : const Color(0xFF94A3B8);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _type = t),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: selected
                                      ? color.withOpacity(0.6)
                                      : Colors.white.withOpacity(0.1)),
                            ),
                            child: Text(t.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: selected ? color : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  // Product selector.
                  _sectionLabel(TranslatorGlobal.instance
                      .translate('inventory_select_product')),
                  const SizedBox(height: 8),
                  _inputField(
                    hint: TranslatorGlobal.instance
                        .translate('inventory_search_product_name'),
                    onChanged: (v) => setState(() => _productSearch = v),
                  ),
                  const SizedBox(height: 8),
                  if (selectedItem != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF06B6D4).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF06B6D4), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _inventoryProductNameL10n(
                                      language,
                                      selectedItem.productName,
                                    ),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13)),
                                Text(
                                    ref.tr(
                                      'inventory_current_stock_label',
                                      params: {
                                        'count': selectedItem.currentStock,
                                      },
                                    ),
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.55),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedProductId = null;
                              _productSearch = '';
                            }),
                            child: Text(
                                TranslatorGlobal.instance
                                    .translate('inventory_switch_product'),
                                style: const TextStyle(
                                    color: Color(0xFF06B6D4), fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView(
                        shrinkWrap: true,
                        children: filtered.take(8).map((item) {
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedProductId = item.productId;
                              _productSearch = '';
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        _inventoryProductNameL10n(
                                          language,
                                          item.productName,
                                        ),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text(
                                      TranslatorGlobal.instance.translate(
                                          'inventory_short_units',
                                          params: {'count': item.currentStock}),
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 18),
                  // Quantity field.
                  _sectionLabel(_type == InventoryTxType.adjustment
                      ? TranslatorGlobal.instance
                          .translate('inventory_adjust_to_units')
                      : TranslatorGlobal.instance
                          .translate('inventory_quantity_units')),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _qtyController,
                    hint: TranslatorGlobal.instance
                        .translate('inventory_input_quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 18),
                  // Notes field.
                  _sectionLabel(TranslatorGlobal.instance
                      .translate('inventory_note_optional')),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _noteController,
                    hint: TranslatorGlobal.instance
                        .translate('inventory_note_placeholder'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  // Operator field.
                  _sectionLabel(TranslatorGlobal.instance
                      .translate('inventory_operator_label')),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _opController,
                    hint: TranslatorGlobal.instance
                        .translate('inventory_operator_name_hint'),
                  ),
                  const SizedBox(height: 28),
                  // Confirm button.
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _onConfirm,
                      child: Text(
                          TranslatorGlobal.instance
                              .translate('inventory_confirm_operation'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 13,
            fontWeight: FontWeight.w500));
  }

  Widget _inputField({
    TextEditingController? controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  void _onConfirm() {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(TranslatorGlobal.instance
              .translate('inventory_validation_select_product')),
          backgroundColor: const Color(0xFFEF4444)));
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(TranslatorGlobal.instance
              .translate('inventory_validation_quantity')),
          backgroundColor: const Color(0xFFEF4444)));
      return;
    }
    Navigator.pop(context);
    widget.onConfirm(
      _selectedProductId!,
      _type,
      qty,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      _opController.text.trim().isEmpty ? null : _opController.text.trim(),
    );
  }
}

// Product inventory detail sheet.
class _ItemDetailSheet extends ConsumerWidget {
  final InventoryItem item;
  final bool readOnly;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;
  final void Function(int newStock, String? note) onAdjust;

  const _ItemDetailSheet({
    required this.item,
    this.readOnly = false,
    required this.onStockIn,
    required this.onStockOut,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appSettingsProvider).language;
    final adjController = TextEditingController(text: '${item.currentStock}');
    final noteController = TextEditingController();
    final productName = _inventoryProductNameL10n(language, item.productName);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E2D3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          // Header.
          Text(productName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
              '${_inventoryCategoryL10n(language, item.category)} · ${item.productId}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 12)),
          const SizedBox(height: 16),
          // Data rows.
          Row(
            children: [
              _detailItem(
                  TranslatorGlobal.instance
                      .translate('inventory_detail_current_stock'),
                  TranslatorGlobal.instance.translate('inventory_units',
                      params: {'count': item.currentStock}),
                  item.isOutOfStock
                      ? const Color(0xFFEF4444)
                      : item.isLowStock
                          ? const Color(0xFFF97316)
                          : const Color(0xFF34D399)),
              _detailItem(
                  TranslatorGlobal.instance
                      .translate('inventory_detail_safety_stock'),
                  TranslatorGlobal.instance.translate('inventory_units',
                      params: {'count': item.minStock}),
                  Colors.white60),
              _detailItem(
                  TranslatorGlobal.instance
                      .translate('inventory_detail_cost_price'),
                  '¥${item.costPrice.toStringAsFixed(0)}',
                  Colors.white60),
              _detailItem(
                  TranslatorGlobal.instance
                      .translate('inventory_detail_selling_price'),
                  '¥${item.sellingPrice.toStringAsFixed(0)}',
                  Colors.white60),
            ],
          ),
          const SizedBox(height: 20),
          if (readOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                TranslatorGlobal.instance
                    .translate('operator_permission_denied'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 12,
                ),
              ),
            )
          else ...[
            // Quick actions.
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                      TranslatorGlobal.instance
                          .translate('inventory_action_stock_in'),
                      const Color(0xFF34D399),
                      onStockIn),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                      TranslatorGlobal.instance
                          .translate('inventory_action_stock_out'),
                      const Color(0xFFEF4444),
                      onStockOut),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Stock adjustment.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    TranslatorGlobal.instance
                        .translate('inventory_adjustment_direct'),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: adjController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: TranslatorGlobal.instance
                                .translate('inventory_target_stock_hint'),
                            hintStyle: const TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: noteController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: TranslatorGlobal.instance
                                .translate('inventory_adjust_reason_hint'),
                            hintStyle: const TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        final n = int.tryParse(adjController.text);
                        if (n != null && n >= 0) {
                          onAdjust(
                              n,
                              noteController.text.isEmpty
                                  ? null
                                  : noteController.text);
                        }
                      },
                      child: Text(
                          TranslatorGlobal.instance.translate('confirm'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(label,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
