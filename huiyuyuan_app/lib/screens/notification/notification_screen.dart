/// HuiYuYuan notification center.
///
/// Features:
/// - category tabs for all, orders, promotions, and system messages
/// - unread state with mark-all-as-read
/// - notification cards with icon, title, content, and timestamp
/// - empty-state placeholder
/// - pull-to-refresh
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/notification_models.dart';
import '../../providers/notification_provider.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';

// Notification screen.
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> get _tabs => [
        ref.tr('order_all'),
        ref.tr('notification_tab_orders'),
        ref.tr('notification_tab_promotions'),
        ref.tr('notification_tab_system'),
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<NotificationItem> _filterList(List<NotificationItem> all, int tabIndex) {
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
        title: Text(ref.tr('notification_title'),
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
              child: Text(ref.tr('notification_mark_all_read'),
                  style: const TextStyle(
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
    if (label == ref.tr('order_all')) {
      count = all.where((n) => !n.isRead).length;
    } else if (label == ref.tr('notification_tab_orders')) {
      count = all
          .where((n) => !n.isRead && n.type == NotificationType.order)
          .length;
    } else if (label == ref.tr('notification_tab_promotions')) {
      count = all
          .where((n) => !n.isRead && n.type == NotificationType.promotion)
          .length;
    } else {
      count = all
          .where((n) => !n.isRead && n.type == NotificationType.system)
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
          Text(ref.tr('notification_empty_title'),
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(ref.tr('notification_empty_subtitle'),
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
              // Drag handle.
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
                    child: Text(item.localizedTitle,
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
                item.localizedBody,
                style: TextStyle(
                  fontSize: 14,
                  color: context.adaptiveTextSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(_formatTime(item.time),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
          child: const Icon(Icons.info_outline_rounded,
              color: JewelryColors.info, size: 20),
        );
    }
  }
}

// Notification card.
class _NotificationCard extends ConsumerWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        child: Text(item.localizedTitle,
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
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.localizedBody,
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
          child: const Icon(Icons.info_outline_rounded,
              color: JewelryColors.info, size: 18),
        );
    }
  }
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'notification_time_just_now'.tr;
  if (diff.inMinutes < 60) {
    return 'notification_time_minutes_ago'.trArgs({'count': diff.inMinutes});
  }
  if (diff.inHours < 24) {
    return 'notification_time_hours_ago'.trArgs({'count': diff.inHours});
  }
  if (diff.inDays < 7) {
    return 'notification_time_days_ago'.trArgs({'count': diff.inDays});
  }
  return '${time.month}/${time.day}';
}
