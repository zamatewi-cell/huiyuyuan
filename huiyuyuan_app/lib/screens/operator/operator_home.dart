/// HuiYuYuan operator workspace.
///
/// Features:
/// - personal work metrics
/// - today's tasks
/// - customer follow-ups
/// - quick actions wired to real pages
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/colors.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/notification_provider.dart';
import '../../l10n/l10n_provider.dart';
import '../../services/order_service.dart';
import '../../services/contact_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/notification_badge_icon.dart';
import '../admin/admin_order_workbench_screen.dart';
import '../admin/inventory_screen.dart';
import '../admin/payment_reconciliation_workbench_screen.dart';
import '../chat/ai_assistant_screen.dart';
import '../notification/notification_screen.dart';
import '../payment_management_screen.dart';
import '../shop/shop_radar.dart';

String _formatCompactAmount(AppLanguage language, double totalAmount) {
  if (totalAmount < 10000) {
    return '\u00A5${totalAmount.toStringAsFixed(0)}';
  }

  switch (language) {
    case AppLanguage.en:
      return '\u00A5${(totalAmount / 1000).toStringAsFixed(1)}K';
    case AppLanguage.zhTW:
      return '\u00A5${(totalAmount / 10000).toStringAsFixed(1)}\u842c';
    case AppLanguage.zhCN:
      return '\u00A5${(totalAmount / 10000).toStringAsFixed(1)}\u4e07';
  }
}

class _OperatorBackdrop extends StatelessWidget {
  const _OperatorBackdrop();

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
            right: -130,
            child: _OperatorGlowOrb(
              size: 350,
              color: JewelryColors.emeraldGlow.withOpacity(0.11),
            ),
          ),
          Positioned(
            left: -150,
            top: 380,
            child: _OperatorGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _OperatorTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorGlowOrb extends StatelessWidget {
  const _OperatorGlowOrb({
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
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 32,
          ),
        ],
      ),
    );
  }
}

class _OperatorTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.08 + i * 0.12);
      final path = Path()..moveTo(-24, y);
      path.cubicTo(
        size.width * 0.2,
        y - 28,
        size.width * 0.72,
        y + 36,
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OperatorTracePainter oldDelegate) => false;
}

/// Operator home screen.
class OperatorHome extends ConsumerStatefulWidget {
  const OperatorHome({super.key});

  @override
  ConsumerState<OperatorHome> createState() => _OperatorHomeState();
}

class _OperatorHomeState extends ConsumerState<OperatorHome> {
  // Completion state for local todo items.
  final Map<int, bool> _todoCompleted = {};
  // Recent contact records loaded from ContactService.
  List<ContactRecord> _recentContacts = [];
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadRecentContacts();
  }

  Future<void> _loadRecentContacts() async {
    final contacts = await ref.read(recentContactsLoaderProvider)(limit: 5);
    if (mounted) {
      setState(() {
        _recentContacts = contacts;
        _isLoadingContacts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final unreadNotifications = ref.watch(notificationUnreadCountProvider);

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      body: Stack(
        children: [
          const Positioned.fill(child: _OperatorBackdrop()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header.
                  _buildHeader(user?.username ?? ref.tr('role_operator')),
                  const SizedBox(height: 24),

                  // Today stats.
                  _buildTodayStats(),
                  const SizedBox(height: 24),

                  // Todo list.
                  _buildTodoList(),
                  const SizedBox(height: 24),

                  // Quick actions.
                  _buildQuickFeatures(unreadNotifications, user),
                  const SizedBox(height: 24),

                  // Recent contacts.
                  _buildRecentContacts(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String username) {
    final hour = DateTime.now().hour;
    String greeting = ref.tr('greeting_morning');
    if (hour >= 12 && hour < 18) {
      greeting = ref.tr('greeting_afternoon');
    } else if (hour >= 18) {
      greeting = ref.tr('greeting_evening');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.deepJade.withOpacity(0.82),
            JewelryColors.jadeSurface.withOpacity(0.54),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.16),
        ),
        boxShadow: JewelryShadows.liquidGlass,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: JewelryColors.emeraldLusterGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: JewelryColors.emeraldGlow.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: JewelryColors.jadeBlack,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.68),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: JewelryColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: JewelryColors.success.withOpacity(0.26),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      color: JewelryColors.success,
                      size: 8,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ref.tr('work_online'),
                      style: const TextStyle(
                        color: JewelryColors.success,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ref.tr('work_working'),
                style: TextStyle(
                  color: JewelryColors.jadeMist.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats() {
    final stats = ref.watch(orderStatsProvider);
    final language = ref.watch(appSettingsProvider).language;
    final totalAmount = stats['totalAmount'] as double? ?? 0.0;
    final amountStr = _formatCompactAmount(language, totalAmount);
    final pending = stats['pending'] as int? ?? 0;
    final paid = stats['paid'] as int? ?? 0;
    final shipped = stats['shipped'] as int? ?? 0;
    final completed = stats['completed'] as int? ?? 0;
    final total = stats['total'] as int? ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bar_chart,
              color: JewelryColors.champagneGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              ref.tr('work_today_stats'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.receipt_long,
                value: '$total',
                label: ref.tr('work_contact_shop'),
                color: JewelryColors.emeraldGlow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.pending_actions,
                value: '$pending',
                label: ref.tr('work_interest'),
                color: JewelryColors.champagneGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.local_shipping,
                value: '${paid + shipped}',
                label: ref.tr('work_cooperation'),
                color: JewelryColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.check_circle,
                value: '$completed',
                label: ref.tr('work_ai_usage'),
                color: JewelryColors.emeraldLuster,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.shopping_bag,
                value: amountStr,
                label: ref.tr('work_order_amount'),
                color: JewelryColors.champagneGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.people,
                value: '${pending + paid}',
                label: ref.tr('work_new_customer'),
                color: JewelryColors.emeraldGlow,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.deepJade.withOpacity(0.62),
            color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.56),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    final orders = ref.watch(orderProvider);
    final todos = <Map<String, String>>[];

    // Generate real todos from pending/paid orders
    for (final order in orders) {
      if (order.status == OrderStatus.pending) {
        todos.add({
          'title': ref.tr(
            'work_todo_remind_payment',
            params: {'id': order.id.substring(0, 8)},
          ),
          'time': '${DateTime.now().hour}:00',
          'priority': 'high',
        });
      } else if (order.status == OrderStatus.paid) {
        todos.add({
          'title': ref.tr(
            'work_todo_ready_ship',
            params: {'id': order.id.substring(0, 8)},
          ),
          'time': '${DateTime.now().hour}:30',
          'priority': 'high',
        });
      } else if (order.status == OrderStatus.shipped) {
        todos.add({
          'title': ref.tr(
            'work_todo_track_shipping',
            params: {'id': order.id.substring(0, 8)},
          ),
          'time': '${DateTime.now().hour + 1}:00',
          'priority': 'medium',
        });
      }
    }

    // Add a default daily todo if no order todos
    if (todos.isEmpty) {
      todos.add({
        'title': ref.tr('work_todo_daily_briefing'),
        'time': '18:00',
        'priority': 'normal',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.checklist,
              color: JewelryColors.emeraldGlow,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              ref.tr('work_todo_list'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: JewelryColors.error.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: JewelryColors.error.withOpacity(0.2),
                ),
              ),
              child: Text(
                ref.tr(
                  'work_pending_count',
                  params: {
                    'count': todos
                        .where(
                          (t) => !(_todoCompleted[todos.indexOf(t)] ?? false),
                        )
                        .length,
                  },
                ),
                style: const TextStyle(
                  color: JewelryColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...todos
            .asMap()
            .entries
            .map((entry) => _buildTodoItem(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildTodoItem(int index, Map<String, String> todo) {
    final isCompleted = _todoCompleted[index] ?? false;
    Color priorityColor;
    switch (todo['priority']) {
      case 'high':
        priorityColor = JewelryColors.error;
        break;
      case 'medium':
        priorityColor = JewelryColors.champagneGold;
        break;
      default:
        priorityColor = JewelryColors.jadeMist.withOpacity(0.46);
    }

    return AnimatedOpacity(
      opacity: isCompleted ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: JewelryColors.deepJade.withOpacity(0.46),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? JewelryColors.jadeMist.withOpacity(0.24)
                    : priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo['title']!,
                    style: TextStyle(
                      color: JewelryColors.jadeMist,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: JewelryColors.jadeMist.withOpacity(0.42),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        todo['time']!,
                        style: TextStyle(
                          color: JewelryColors.jadeMist.withOpacity(0.42),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _todoCompleted[index] = !isCompleted;
                });
                if (!isCompleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ref.tr(
                          'work_todo_completed_message',
                          params: {'title': todo['title']!},
                        ),
                      ),
                      backgroundColor: JewelryColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? JewelryColors.success.withOpacity(0.3)
                      : JewelryColors.emeraldGlow.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? JewelryColors.success.withOpacity(0.28)
                        : JewelryColors.emeraldGlow.withOpacity(0.22),
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.check,
                  color: isCompleted
                      ? JewelryColors.success
                      : JewelryColors.emeraldGlow,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFeatures(int unreadNotifications, UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.apps,
                color: JewelryColors.champagneGold, size: 20),
            const SizedBox(width: 8),
            Text(
              ref.tr('work_quick_features'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
          children: [
            _buildFeatureButton(Icons.radar, ref.tr('work_ai_client'),
                JewelryColors.emeraldGlow, onTap: () {
              _openShopRadar(user);
            }),
            _buildFeatureButton(Icons.message, ref.tr('work_ai_script'),
                JewelryColors.emeraldLuster, onTap: () {
              _openAIAssistant(user);
            }),
            _buildFeatureButton(Icons.receipt_long_rounded,
                ref.tr('admin_orders'), JewelryColors.champagneGold, onTap: () {
              _openOrderWorkbench(user);
            }),
            _buildFeatureButton(Icons.qr_code_scanner,
                ref.tr('work_traceability'), JewelryColors.success, onTap: () {
              _showTraceabilityDialog();
            }),
            _buildFeatureButton(Icons.inventory_2_rounded,
                ref.tr('product_stock'), JewelryColors.emeraldGlow, onTap: () {
              _openInventoryWorkbench(user);
            }),
            _buildFeatureButton(
                Icons.fact_check_rounded,
                ref.tr('payment_reconciliation_title'),
                JewelryColors.emeraldLuster, onTap: () {
              _openPaymentReconciliationWorkbench(user);
            }),
            _buildFeatureButton(Icons.chat_bubble, ref.tr('work_ai_reply_draft'),
                JewelryColors.emeraldGlow, onTap: () {
              _openAIDraftReply(user);
            }),
            _buildFeatureButton(
              Icons.notifications,
              ref.tr('settings_notifications'),
              JewelryColors.error,
              iconWidget: NotificationBadgeIcon(
                icon: Icons.notifications,
                count: unreadNotifications,
                color: JewelryColors.error,
                size: 24,
              ),
              onTap: () {
                _showReminderSettings();
              },
            ),
            _buildFeatureButton(
                Icons.account_balance_wallet,
                ref.tr('profile_account'),
                JewelryColors.champagneGold, onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentManagementScreen(),
                  ));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureButton(IconData icon, String label, Color color,
      {VoidCallback? onTap, Widget? iconWidget}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        decoration: BoxDecoration(
          color: JewelryColors.deepJade.withOpacity(0.46),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ?? Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.78),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history,
                color: JewelryColors.emeraldGlow, size: 20),
            const SizedBox(width: 8),
            Text(
              ref.tr('work_recent_contacts'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                ref.tr('view_all'),
                style: const TextStyle(
                  color: JewelryColors.emeraldGlow,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingContacts)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_recentContacts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: JewelryColors.deepJade.withOpacity(0.42),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: JewelryColors.champagneGold.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.contact_phone_outlined,
                    size: 40, color: JewelryColors.jadeMist.withOpacity(0.22)),
                const SizedBox(height: 8),
                Text(
                  ref.tr('work_recent_contacts_empty'),
                  style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.36),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ref.tr('work_recent_contacts_hint'),
                  style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.24),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ..._recentContacts.map((contact) => _buildContactItem({
                'name': contact.shopName,
                'status': contact.result,
                'time': contact.date,
                'color': contact.statusColor ?? 'hint',
              })),
      ],
    );
  }

  Widget _buildContactItem(Map<String, String> contact) {
    Color statusColor;
    switch (contact['color']) {
      case 'gold':
        statusColor = JewelryColors.champagneGold;
        break;
      case 'primary':
        statusColor = JewelryColors.emeraldGlow;
        break;
      case 'success':
        statusColor = JewelryColors.success;
        break;
      default:
        statusColor = JewelryColors.jadeMist.withOpacity(0.46);
    }

    return GestureDetector(
      onTap: () {
        _showContactDetail(contact);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: JewelryColors.deepJade.withOpacity(0.46),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: JewelryColors.emeraldLusterGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  contact['name']!.substring(0, 1),
                  style: const TextStyle(
                    color: JewelryColors.jadeBlack,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name']!,
                    style: const TextStyle(
                      color: JewelryColors.jadeMist,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact['time']!,
                    style: TextStyle(
                      color: JewelryColors.jadeMist.withOpacity(0.42),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withOpacity(0.18)),
              ),
              child: Text(
                contact['status']!,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog helpers.

  void _showFeatureToast(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: JewelryColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _hasAnyPermission(UserModel? user, List<String> permissions) {
    if (user == null) {
      return true;
    }
    return permissions.any(user.hasPermission);
  }

  void _openAIAssistant(UserModel? user) {
    if (!_hasAnyPermission(user, const ['ai_assistant'])) {
      _showFeatureToast(
        ref.tr('work_ai_script'),
        ref.tr('operator_permission_denied'),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
    );
  }

  /// Opens AI assistant pre-loaded with a customer-service drafting context.
  void _openAIDraftReply(UserModel? user) {
    if (!_hasAnyPermission(user, const ['ai_assistant'])) {
      _showFeatureToast(
        ref.tr('work_ai_reply_draft'),
        ref.tr('operator_permission_denied'),
      );
      return;
    }
    final lang = ref.read(appSettingsProvider).language;
    final draftPrompt = lang == AppLanguage.en
        ? 'Please help me draft a professional customer-service reply for a jewellery order inquiry. '
            'I\'ll paste the customer\'s message and you suggest a warm, accurate response.'
        : lang == AppLanguage.zhTW
            ? '請幫我為珠寶訂單諮詢起草一條專業客服回覆。我會貼上客戶的訊息，請給出溫暖、準確的回覆建議。'
            : '请帮我为珠宝订单咨询起草一条专业客服回复。我会粘贴客户的消息，请给出温暖、准确的回复建议。';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIAssistantScreen(
          initialContext: draftPrompt,
        ),
      ),
    );
  }

  void _openOrderWorkbench(UserModel? user) {
    if (!_hasAnyPermission(user, const [
      'orders',
      'order_manage',
      'payment_reconcile',
      'payment_exception_mark',
    ])) {
      _showFeatureToast(
        ref.tr('admin_orders'),
        ref.tr('operator_permission_denied'),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminOrderWorkbenchScreen()),
    );
  }

  void _openPaymentReconciliationWorkbench(UserModel? user) {
    if (!_hasAnyPermission(user, const [
      'payment_reconcile',
      'payment_exception_mark',
    ])) {
      _showFeatureToast(
        ref.tr('payment_reconciliation_title'),
        ref.tr('operator_permission_denied'),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentReconciliationWorkbenchScreen(),
      ),
    );
  }

  void _openInventoryWorkbench(UserModel? user) {
    if (!_hasAnyPermission(user, const ['inventory_read', 'inventory_write'])) {
      _showFeatureToast(
        ref.tr('product_stock'),
        ref.tr('operator_permission_denied'),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InventoryScreen()),
    );
  }

  void _openShopRadar(UserModel? user) {
    if (user != null && !user.hasPermission('shop_radar')) {
      _showFeatureToast(
        ref.tr('work_ai_client'),
        ref.tr('operator_permission_denied'),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopRadar()),
    );
  }

  void _showTraceabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: JewelryColors.success),
            const SizedBox(width: 10),
            Text(ref.tr('work_traceability'),
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: JewelryColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: JewelryColors.success.withOpacity(0.18),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified,
                      color: JewelryColors.success, size: 48),
                  const SizedBox(height: 12),
                  Text(ref.tr('work_traceability_scan_qr'),
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    ref.tr('work_traceability_verify_cert'),
                    style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.56),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('close'),
                style: TextStyle(
                  color: JewelryColors.jadeMist.withOpacity(0.58),
                )),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showFeatureToast(
                ref.tr('work_traceability'),
                ref.tr('work_traceability_camera_starting'),
              );
            },
            icon: const Icon(Icons.camera_alt, size: 16),
            label: Text(ref.tr('shop_radar_start_scan')),
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.emeraldLuster,
              foregroundColor: JewelryColors.jadeBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderSettings() {
    final unreadNotifications = ref.read(notificationUnreadCountProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              JewelryColors.deepJade.withOpacity(0.98),
              JewelryColors.jadeSurface.withOpacity(0.94),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: JewelryColors.champagneGold.withOpacity(0.16),
            ),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                NotificationBadgeIcon(
                  icon: Icons.notifications_active,
                  count: unreadNotifications,
                  color: JewelryColors.champagneGold,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(ref.tr('reminder_settings'),
                    style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 20),
            if (unreadNotifications > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: JewelryColors.emeraldGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: JewelryColors.emeraldGlow.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ref.tr(
                          'notification_unread_summary',
                          params: {'count': unreadNotifications},
                        ),
                        style: const TextStyle(
                          color: JewelryColors.jadeMist,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openNotificationCenter();
                      },
                      child: Text(
                        ref.tr('notification_title'),
                        style: const TextStyle(
                          color: JewelryColors.emeraldGlow,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildReminderSwitch(ref.tr('reminder_customer'),
                ref.tr('reminder_customer_desc'), true),
            _buildReminderSwitch(
                ref.tr('reminder_order'), ref.tr('reminder_order_desc'), true),
            _buildReminderSwitch(
                ref.tr('reminder_daily'), ref.tr('reminder_daily_desc'), false),
            _buildReminderSwitch(
                ref.tr('reminder_ai'), ref.tr('reminder_ai_desc'), true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.emeraldLuster,
                  foregroundColor: JewelryColors.jadeBlack,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(ref.tr('save_settings')),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _openNotificationCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationScreen(),
      ),
    );
  }

  Widget _buildReminderSwitch(
      String title, String subtitle, bool defaultValue) {
    bool isOn = defaultValue;
    return StatefulBuilder(
      builder: (context, setSwState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JewelryColors.deepJade.withOpacity(0.46),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: JewelryColors.jadeMist, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.42),
                            fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) => setSwState(() => isOn = v),
                activeColor: JewelryColors.emeraldGlow,
                activeTrackColor: JewelryColors.emeraldGlow.withOpacity(0.28),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactDetail(Map<String, String> contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              JewelryColors.deepJade.withOpacity(0.98),
              JewelryColors.jadeSurface.withOpacity(0.94),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: JewelryColors.champagneGold.withOpacity(0.16),
            ),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Customer avatar and name.
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: JewelryColors.emeraldLusterGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  contact['name']!.substring(0, 1),
                  style: const TextStyle(
                      color: JewelryColors.jadeBlack,
                      fontSize: 24,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(contact['name']!,
                style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
                ref.tr(
                  'work_contact_detail_summary',
                  params: {
                    'status': contact['status'] ?? '',
                    'time': contact['time'] ?? '',
                  },
                ),
                style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.56),
                    fontSize: 12)),
            const SizedBox(height: 24),
            // Action buttons.
            Row(
              children: [
                Expanded(
                    child: _buildContactAction(Icons.phone,
                        ref.tr('work_call_phone'), JewelryColors.emeraldGlow)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildContactAction(
                        Icons.message,
                        ref.tr('work_send_message'),
                        JewelryColors.emeraldLuster)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildContactAction(Icons.smart_toy,
                        ref.tr('work_ai_script'), JewelryColors.champagneGold)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAction(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showFeatureToast(
          label,
          ref.tr('work_feature_in_development', params: {'feature': label}),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
