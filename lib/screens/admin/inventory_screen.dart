/// 汇玉源 - 内部库存管理屏幕
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../../themes/colors.dart';

/// 格式化金额
String _fmtMoney(double v) {
  if (v >= 10000) {
    return '?${(v / 10000).toStringAsFixed(1)}万';
  }
  return '?${v.toStringAsFixed(0)}';
}

/// 库存管理主屏幕
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterCategory = '全部';

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
        ),
      ),
      floatingActionButton: _buildFAB(),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.warehouse_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('内部库存管理',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(
                  '共 ${stats.totalSkus} 种商品 · ${stats.totalUnits} 件在库',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55), fontSize: 12),
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
            const Icon(Icons.warning_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text('$total 预警',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)]),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics_rounded, size: 15),
                SizedBox(width: 5),
                Text('概览'),
              ],
            ),
          ),
          Tab(
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
                Icon(Icons.receipt_long_rounded, size: 15),
                SizedBox(width: 5),
                Text('流水'),
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
      label: const Text('入/出库',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // ═══════════════════════════ 概览 Tab ═══════════════════════════
  Widget _buildOverviewTab() {
    final stats = ref.watch(inventoryStatsProvider);
    final lowStockItems = ref.watch(lowStockItemsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(stats),
          const SizedBox(height: 20),
          _buildValueCards(stats),
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
          '商品种类',
          '${stats.totalSkus} SKU',
          '全部在档',
          Icons.category_rounded,
          const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)]),
        ),
        _buildStatCard(
          '总库存量',
          '${stats.totalUnits} 件',
          '实物存量',
          Icons.inventory_2_rounded,
          JewelryColors.primaryGradient,
        ),
        _buildStatCard(
          '低库存预警',
          '${stats.lowStockCount} 种',
          stats.lowStockCount > 0 ? '? 需补货' : '? 充足',
          Icons.warning_amber_rounded,
          stats.lowStockCount > 0
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF97316)])
              : const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)]),
        ),
        _buildStatCard(
          '本月流水',
          '${stats.txCountThisMonth} 笔',
          '入/出库记录',
          Icons.receipt_long_rounded,
          JewelryColors.goldGradient,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String sub,
      IconData icon, LinearGradient gradient) {
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

  Widget _buildValueCards(InventoryStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('库存估值',
            style: TextStyle(
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
                '成本总值',
                _fmtMoney(stats.totalCostValue),
                const Color(0xFF94A3B8),
              ),
              _buildValueDivider(),
              _buildValueItem(
                '市场售价总值',
                _fmtMoney(stats.totalSellingValue),
                const Color(0xFF34D399),
              ),
              _buildValueDivider(),
              _buildValueItem(
                '毛利空间',
                _fmtMoney(stats.totalSellingValue - stats.totalCostValue),
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
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 11),
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
            const Icon(Icons.warning_rounded, color: Color(0xFFF97316), size: 18),
            const SizedBox(width: 6),
            const Text('库存预警',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${items.length} 项',
                style: const TextStyle(color: Color(0xFFF97316), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        ...items.take(5).map((item) => _buildWarningRow(item)).toList(),
        if (items.length > 5)
          TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: Text('查看全部 ${items.length} 项预警',
                style: const TextStyle(color: Color(0xFF06B6D4))),
          ),
      ],
    );
  }

  Widget _buildWarningRow(InventoryItem item) {
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
              color: isOut
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF97316),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOut ? '售罄' : '低库存',
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
                Text(item.productName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(item.category,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.currentStock} 件',
                style: TextStyle(
                    color: isOut
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF97316),
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              Text('安全线: ${item.minStock}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════ 库存列表 Tab ═══════════════════════════
  Widget _buildStockListTab() {
    final items = ref.watch(inventoryProvider);

    // 分类列表
    final categories = ['全部', ...{... items.map((e) => e.category)}];
    final filtered = items.where((e) {
      final matchCat = _filterCategory == '全部' || e.category == _filterCategory;
      final matchSearch = _searchQuery.isEmpty ||
          e.productName.contains(_searchQuery) ||
          e.productId.contains(_searchQuery);
      return matchCat && matchSearch;
    }).toList();

    return Column(
      children: [
        // 搜索栏
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
                      hintText: '搜索商品名称 / 编号',
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
        // 分类筛选
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
        // 列表
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('没有找到商品',
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
            // 商品图片
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
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _tag(item.category, const Color(0xFF6366F1)),
                      const SizedBox(width: 6),
                      Text(item.productId,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('成本 ?${item.costPrice.toStringAsFixed(0)}  |  售价 ?${item.sellingPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45), fontSize: 11)),
                ],
              ),
            ),
            // 库存数
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.currentStock}',
                    style: TextStyle(
                        color: stockColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text('件',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45), fontSize: 11)),
                if (isOut)
                  _tag('售罄', const Color(0xFFEF4444))
                else if (isLow)
                  _tag('低库存', const Color(0xFFF97316)),
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

  // ═══════════════════════════ 流水记录 Tab ═══════════════════════════
  Widget _buildTransactionTab() {
    final txs = ref.watch(inventoryTxProvider);
    return txs.isEmpty
        ? Center(
            child: Text('暂无流水记录',
                style: TextStyle(color: Colors.white.withOpacity(0.4))))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            itemCount: txs.length,
            itemBuilder: (_, i) => _buildTxRow(txs[i]),
          );
  }

  Widget _buildTxRow(InventoryTransaction tx) {
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
          // 类型图标
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
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _tag(tx.type.label, typeColors[tx.type]!),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tx.productName,
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
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${tx.operatorName ?? '未知'} · ${DateFormat('MM-dd HH:mm').format(tx.createdAt)}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 数量
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$sign${tx.quantity}件',
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text('${tx.stockBefore}→${tx.stockAfter}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════ 底部弹窗：入/出库操作 ═══════════════════════════
  void _showStockOperationSheet() {
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
    final item = notifier.getItem(productId);
    if (item == null) {
      _showSnack('找不到该商品', isError: true);
      return;
    }

    final before = item.currentStock;
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
        type == InventoryTxType.stockOut ? '库存不足，无法出库' : '操作失败',
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
      productName: item.productName,
      type: type,
      quantity: quantity,
      stockBefore: before,
      stockAfter: after,
      note: note,
      operatorName: operatorName ?? '管理员',
      createdAt: DateTime.now(),
    ));

    _showSnack('${type.label}成功：${item.productName} ×$quantity');
  }

  // ═══════════════════════════ 商品详情底部弹窗 ═══════════════════════════
  void _showItemDetailSheet(InventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(
        item: item,
        onStockIn: () {
          Navigator.pop(context);
          _showStockOperationSheetForProduct(item.productId,
              InventoryTxType.stockIn);
        },
        onStockOut: () {
          Navigator.pop(context);
          _showStockOperationSheetForProduct(item.productId,
              InventoryTxType.stockOut);
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
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════ 入/出库操作弹窗 ═══════════════════════════
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
  final _opController = TextEditingController(text: '管理员');
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
    final filtered = items
        .where((e) =>
            _productSearch.isEmpty ||
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
          // Handle + 标题
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
                const Text('库存操作',
                    style: TextStyle(
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
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 操作类型
                  _sectionLabel('操作类型'),
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
                  // 选择商品
                  _sectionLabel('选择商品'),
                  const SizedBox(height: 8),
                  _inputField(
                    hint: '搜索商品名称...',
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
                            color:
                                const Color(0xFF06B6D4).withOpacity(0.4)),
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
                                Text(selectedItem.productName,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13)),
                                Text(
                                    '当前库存: ${selectedItem.currentStock} 件',
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
                            child: const Text('更换',
                                style: TextStyle(
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
                                    child: Text(item.productName,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text('${item.currentStock}件',
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.5),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 18),
                  // 数量
                  _sectionLabel(_type == InventoryTxType.adjustment ? '调整为（件数）' : '数量（件）'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _qtyController,
                    hint: '输入数量',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 18),
                  // 备注
                  _sectionLabel('备注（可选）'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _noteController,
                    hint: '如：供应商补货、客户订单号...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  // 经办人
                  _sectionLabel('经办人'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _opController,
                    hint: '经办人姓名',
                  ),
                  const SizedBox(height: 28),
                  // 确认按钮
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
                      child: const Text('确认操作',
                          style: TextStyle(
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请先选择商品'),
          backgroundColor: Color(0xFFEF4444)));
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请输入有效的数量'),
          backgroundColor: Color(0xFFEF4444)));
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

// ═══════════════════════════ 商品库存详情弹窗 ═══════════════════════════
class _ItemDetailSheet extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;
  final void Function(int newStock, String? note) onAdjust;

  const _ItemDetailSheet({
    required this.item,
    required this.onStockIn,
    required this.onStockOut,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final adjController =
        TextEditingController(text: '${item.currentStock}');
    final noteController = TextEditingController();

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
          // 标题
          Text(item.productName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${item.category} · ${item.productId}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 12)),
          const SizedBox(height: 16),
          // 数据行
          Row(
            children: [
              _detailItem('当前库存', '${item.currentStock} 件',
                  item.isOutOfStock
                      ? const Color(0xFFEF4444)
                      : item.isLowStock
                          ? const Color(0xFFF97316)
                          : const Color(0xFF34D399)),
              _detailItem('安全库存线', '${item.minStock} 件', Colors.white60),
              _detailItem(
                  '成本价', '?${item.costPrice.toStringAsFixed(0)}', Colors.white60),
              _detailItem('售价',
                  '?${item.sellingPrice.toStringAsFixed(0)}', Colors.white60),
            ],
          ),
          const SizedBox(height: 20),
          // 快捷操作
          Row(
            children: [
              Expanded(
                child: _actionBtn('? 入库', const Color(0xFF34D399), onStockIn),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn('? 出库', const Color(0xFFEF4444), onStockOut),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 盘点调整
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('盘点调整（直接设置数量）',
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
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '目标库存数',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
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
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '调整原因',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
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
                        onAdjust(n, noteController.text.isEmpty
                            ? null
                            : noteController.text);
                      }
                    },
                    child: const Text('确认',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
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
                  color: valueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10),
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
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
