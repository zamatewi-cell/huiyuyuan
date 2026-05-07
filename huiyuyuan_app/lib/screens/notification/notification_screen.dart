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
import '../../l10n/translator_global.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_models.dart';
import '../../providers/notification_provider.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';

class _NotificationBackdrop extends StatelessWidget {
  const _NotificationBackdrop();

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
            child: _NotificationGlowOrb(
              size: 330,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            top: 340,
            child: _NotificationGlowOrb(
              size: 290,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _NotificationTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationGlowOrb extends StatelessWidget {
  const _NotificationGlowOrb({
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

class _NotificationTracePainter extends CustomPainter {
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
  bool shouldRepaint(covariant _NotificationTracePainter oldDelegate) => false;
}

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
        TranslatorGlobal.instance.translate('order_all'),
        TranslatorGlobal.instance.translate('notification_tab_orders'),
        TranslatorGlobal.instance.translate('notification_tab_promotions'),
        TranslatorGlobal.instance.translate('notification_tab_system'),
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
    final notifications = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.84),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: JewelryColors.jadeMist,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
            TranslatorGlobal.instance.translate('notification_title'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0.4,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (notifier.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: Text(
                  TranslatorGlobal.instance
                      .translate('notification_mark_all_read'),
                  style: const TextStyle(
                      color: JewelryColors.emeraldGlow,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: JewelryColors.emeraldGlow,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: JewelryColors.emeraldGlow,
          unselectedLabelColor: JewelryColors.jadeMist.withOpacity(0.5),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: _tabs
              .map((t) => Tab(
                    child: _buildTabLabel(t, notifications),
                  ))
              .toList(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _NotificationBackdrop()),
          TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (i) {
              final items = _filterList(notifications, i);
              if (items.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                color: JewelryColors.emeraldGlow,
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
                        _showNotificationDetail(context, item);
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String label, List<NotificationItem> all) {
    int count = 0;
    if (label == TranslatorGlobal.instance.translate('order_all')) {
      count = all.where((n) => !n.isRead).length;
    } else if (label ==
        TranslatorGlobal.instance.translate('notification_tab_orders')) {
      count = all
          .where((n) => !n.isRead && n.type == NotificationType.order)
          .length;
    } else if (label ==
        TranslatorGlobal.instance.translate('notification_tab_promotions')) {
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

  Widget _buildEmptyState() {
    return Center(
      child: GlassmorphicCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        borderRadius: 26,
        blur: 16,
        opacity: 0.18,
        borderColor: JewelryColors.champagneGold.withOpacity(0.14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: JewelryColors.jadeMist.withOpacity(0.32),
            ),
            const SizedBox(height: 16),
            Text(
              TranslatorGlobal.instance.translate('notification_empty_title'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              TranslatorGlobal.instance
                  .translate('notification_empty_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.54),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetail(BuildContext context, NotificationItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JewelryColors.deepJade.withOpacity(0.98),
                JewelryColors.jadeSurface.withOpacity(0.94),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.16),
              ),
            ),
          ),
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
                    color: JewelryColors.jadeMist.withOpacity(0.22),
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: JewelryColors.jadeMist,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.localizedBody,
                style: TextStyle(
                  fontSize: 14,
                  color: JewelryColors.jadeMist.withOpacity(0.68),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(_formatTime(item.time),
                  style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.42),
                    fontSize: 12,
                  )),
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
            color: JewelryColors.emeraldGlow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: JewelryColors.emeraldGlow.withOpacity(0.14),
            ),
          ),
          child: const Icon(Icons.local_shipping_outlined,
              color: JewelryColors.emeraldGlow, size: 20),
        );
      case NotificationType.promotion:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.16),
            ),
          ),
          child: const Icon(Icons.campaign_outlined,
              color: JewelryColors.champagneGold, size: 20),
        );
      case NotificationType.system:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JewelryColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: JewelryColors.info.withOpacity(0.14),
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              JewelryColors.deepJade.withOpacity(item.isRead ? 0.52 : 0.7),
              JewelryColors.jadeSurface.withOpacity(item.isRead ? 0.34 : 0.48),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isRead
                ? JewelryColors.champagneGold.withOpacity(0.1)
                : JewelryColors.emeraldGlow.withOpacity(0.24),
            width: item.isRead ? 1 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 18,
              offset: const Offset(0, 9),
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
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                              color: JewelryColors.jadeMist,
                            )),
                      ),
                      Text(_formatTime(item.time),
                          style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.42),
                            fontSize: 11,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.localizedBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: JewelryColors.jadeMist.withOpacity(0.62),
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
            color: JewelryColors.emeraldGlow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: JewelryColors.emeraldGlow.withOpacity(0.14),
            ),
          ),
          child: const Icon(Icons.local_shipping_outlined,
              color: JewelryColors.emeraldGlow, size: 18),
        );
      case NotificationType.promotion:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.16),
            ),
          ),
          child: const Icon(Icons.campaign_outlined,
              color: JewelryColors.champagneGold, size: 18),
        );
      case NotificationType.system:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JewelryColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: JewelryColors.info.withOpacity(0.14),
            ),
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
  if (diff.inMinutes < 1)
    return TranslatorGlobal.instance.translate('notification_time_just_now');
  if (diff.inMinutes < 60) {
    return TranslatorGlobal.instance.translate('notification_time_minutes_ago',
        params: {'count': diff.inMinutes});
  }
  if (diff.inHours < 24) {
    return TranslatorGlobal.instance.translate('notification_time_hours_ago',
        params: {'count': diff.inHours});
  }
  if (diff.inDays < 7) {
    return TranslatorGlobal.instance.translate('notification_time_days_ago',
        params: {'count': diff.inDays});
  }
  return '${time.month}/${time.day}';
}
