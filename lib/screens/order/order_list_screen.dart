/// 汇玉源 - 订单列表页面
///
/// 功能:
/// - 订单分类展示 (待付款/待发货/待收货/已完成)
/// - 订单详情查看
/// - 订单操作 (取消/确认收货等)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../models/user_model.dart';
import '../../services/order_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/glassmorphic_card.dart';
import 'order_detail_screen.dart';
import 'publish_review_screen.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const OrderListScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _tabs = [
    {'label': '全部', 'status': null},
    {'label': '待付款', 'status': OrderStatus.pending},
    {'label': '待发货', 'status': OrderStatus.paid},
    {'label': '待收货', 'status': OrderStatus.shipped},
    {'label': '已完成', 'status': OrderStatus.completed},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
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
      backgroundColor: context.adaptiveBackground,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                return _OrderTabContent(status: tab['status']);
              }).toList(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.primary.withOpacity(0.9),
                  JewelryColors.primaryDark.withOpacity(0.9),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 标题栏
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            '我的订单',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // Tab 栏
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: _tabs.map((tab) => Tab(text: tab['label'])).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => const OrderCardSkeleton(),
    );
  }
}

/// 订单Tab内容
class _OrderTabContent extends ConsumerWidget {
  final OrderStatus? status;

  const _OrderTabContent({this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrders = ref.watch(orderProvider);
    final orders = status == null
        ? allOrders
        : allOrders.where((o) => o.status == status).toList();

    if (orders.isEmpty) {
      return EmptyStateWidget(
        type: EmptyType.order,
        onAction: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(orderProvider.notifier).refresh();
      },
      color: JewelryColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => _OrderCard(order: orders[index]),
      ),
    );
  }
}

/// 订单卡片
class _OrderCard extends ConsumerWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      borderRadius: 20,
      backgroundColor: context.adaptiveSurface,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Column(
        children: [
          // 订单头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.adaptiveBackground.withOpacity(0.5),
              border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '订单号: ${order.id}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.adaptiveTextSecondary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: order.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: order.status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 商品信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品图片
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: JewelryColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.diamond_outlined,
                    size: 40,
                    color: JewelryColors.primary.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 12),

                // 商品详情
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.adaptiveTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '数量: x${order.quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.adaptiveTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '¥${order.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: JewelryColors.price,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.adaptiveTextHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 操作按钮
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];

    switch (order.status) {
      case OrderStatus.pending:
        buttons.add(_buildOutlineButton('取消订单', () {
          ref.read(orderProvider.notifier).cancelOrder(order.id);
        }, context));
        buttons.add(const SizedBox(width: 12));
        buttons.add(_buildPrimaryButton('立即付款', () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('支付功能开发中...')),
          );
        }));
        break;
      case OrderStatus.paid:
        // Admin or Operator can ship
        buttons.add(_buildPrimaryButton('去发货 (模拟)', () {
          ref.read(orderProvider.notifier).updateOrderStatus(
                order.id,
                OrderStatus.shipped,
              );
        }));
        break;
      case OrderStatus.shipped:
        buttons.add(_buildOutlineButton('查看物流', () {}, context));
        buttons.add(const SizedBox(width: 12));
        buttons.add(_buildPrimaryButton('确认收货', () {
          ref.read(orderProvider.notifier).updateOrderStatus(
                order.id,
                OrderStatus.completed,
              );
        }));
        break;
      case OrderStatus.completed:
      case OrderStatus.delivered:
        buttons.add(_buildOutlineButton('发起退货', () {}, context));
        buttons.add(const SizedBox(width: 12));
        buttons.add(_buildPrimaryButton('评价晒单', () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PublishReviewScreen(order: order)),
          );
          if (result == true) {
            // Callback log
            debugPrint('评价成功!');
          }
        }));
        break;
      case OrderStatus.cancelled:
        buttons.add(_buildOutlineButton('删除订单', () {}, context));
        break;
      default:
        buttons.add(_buildOutlineButton('查看详情', () {}, context));
    }

    return buttons;
  }

  Widget _buildOutlineButton(
      String text, VoidCallback onPressed, BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.adaptiveTextSecondary,
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: JewelryColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JewelryColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
