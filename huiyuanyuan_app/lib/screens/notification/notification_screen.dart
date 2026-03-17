/// 汇玉源 - 消息通知中心
///
/// 功能:
/// - 三个分类标签: 全部 / 订单 / 系统
/// - 未读标记 + 一键已读
/// - 通知卡片（图标、标题、内容、时间）
/// - 空状态占位
/// - 下拉刷新
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../services/notification_service.dart';

// ─── Provider (API 优先，失败返回空列表) ───
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super([]) {
    _loadFromApi();
  }

  final NotificationApiService _service = NotificationApiService();

  /// 从后端加载通知（失败时保持空列表）
  Future<void> _loadFromApi() async {
    final items = await _service.fetchNotifications();
    if (mounted) {
      state = items;
    }
  }

  /// 下拉刷新
  Future<void> refresh() async {
    await _loadFromApi();
  }

  void markAsRead(String id) {
    _service.markAsRead(id); // 异步通知后端，不阻塞 UI
    state = [
      for (final n in state)
        if (n.id == id) (n..isRead = true) else n
    ];
  }

  void markAllAsRead() {
    _service.markAllAsRead();
    state = [for (final n in state) n..isRead = true];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

// ─── 通知页面 ───
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['全部', '订单', '活动', '系统'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NotificationItem> _filterList(
      List<NotificationItem> all, int tabIndex) {
    if (tabIndex == 0) return all;
    final typeMap = {
      1: NotificationType.order,
      2: NotificationType.promotion,
      3: NotificationType.system,
    };
    return all.where((n) => n.type == typeMap[tabIndex]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final notifications = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? JewelryColors.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.adaptiveTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('消息通知',
            style: TextStyle(
              color: context.adaptiveTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            )),
        centerTitle: true,
        actions: [
          if (notifier.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: Text('全部已读',
                  style: TextStyle(
                      color: JewelryColors.primary, fontSize: 13)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: JewelryColors.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: JewelryColors.primary,
          unselectedLabelColor: context.adaptiveTextSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
          tabs: _tabs
              .map((t) => Tab(
                    child: _buildTabLabel(t, notifications),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (i) {
          final items = _filterList(notifications, i);
          if (items.isEmpty) {
            return _buildEmptyState(isDark);
          }
          return RefreshIndicator(
            color: JewelryColors.primary,
            onRefresh: () async {
              await ref.read(notificationProvider.notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, idx) {
                final item = items[idx];
                return _NotificationCard(
                  item: item,
                  onTap: () {
                    notifier.markAsRead(item.id);
                    _showNotificationDetail(context, item, isDark);
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabLabel(String label, List<NotificationItem> all) {
    int count = 0;
    if (label == '全部') {
      count = all.where((n) => !n.isRead).length;
    } else if (label == '订单') {
      count = all
          .where(
              (n) => !n.isRead && n.type == NotificationType.order)
          .length;
    } else if (label == '活动') {
      count = all
          .where(
              (n) => !n.isRead && n.type == NotificationType.promotion)
          .length;
    } else {
      count = all
          .where(
              (n) => !n.isRead && n.type == NotificationType.system)
          .length;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: JewelryColors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, height: 1.4)),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('暂无消息',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('新消息会在这里显示',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  void _showNotificationDetail(
      BuildContext context, NotificationItem item, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? JewelryColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖拽条
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _iconForType(item.type),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.adaptiveTextPrimary,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.body,
                style: TextStyle(
                  fontSize: 14,
                  color: context.adaptiveTextSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(_formatTime(item.time),
                  style: TextStyle(
                      color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JewelryColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_shipping_outlined,
              color: JewelryColors.primary, size: 20),
        );
      case NotificationType.promotion:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.campaign_outlined,
              color: Color(0xFFFFB800), size: 20),
        );
      case NotificationType.system:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JewelryColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.info_outline_rounded,
              color: JewelryColors.info, size: 20),
        );
    }
  }
}

// ─── 通知卡片 ───
class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? JewelryColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: !item.isRead
              ? Border.all(
                  color: JewelryColors.primary.withOpacity(0.3), width: 0.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.12 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!item.isRead)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: JewelryColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: context.adaptiveTextPrimary,
                            )),
                      ),
                      Text(_formatTime(item.time),
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.adaptiveTextSecondary,
                        height: 1.4,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (item.type) {
      case NotificationType.order:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JewelryColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_shipping_outlined,
              color: JewelryColors.primary, size: 18),
        );
      case NotificationType.promotion:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.campaign_outlined,
              color: Color(0xFFFFB800), size: 18),
        );
      case NotificationType.system:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JewelryColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.info_outline_rounded,
              color: JewelryColors.info, size: 18),
        );
    }
  }
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
  if (diff.inHours < 24) return '${diff.inHours}小时前';
  if (diff.inDays < 7) return '${diff.inDays}天前';
  return '${time.month}/${time.day}';
}
