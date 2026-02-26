/// 汇玉源 - 操作员工作台
///
/// 功能:
/// - 个人工作数据
/// - 今日任务
/// - 客户跟进
/// - 快捷操作（接入实际页面）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/colors.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/l10n_provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../chat/ai_assistant_screen.dart';
import '../payment_management_screen.dart';

/// 操作员工作台
class OperatorHome extends ConsumerStatefulWidget {
  const OperatorHome({super.key});

  @override
  ConsumerState<OperatorHome> createState() => _OperatorHomeState();
}

class _OperatorHomeState extends ConsumerState<OperatorHome> {
  // 待办任务完成状态
  final Map<int, bool> _todoCompleted = {};

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部欢迎
              _buildHeader(user?.username ?? '操作员'),
              const SizedBox(height: 24),

              // 今日数据
              _buildTodayStats(),
              const SizedBox(height: 24),

              // 待办任务
              _buildTodoList(),
              const SizedBox(height: 24),

              // 快捷功能
              _buildQuickFeatures(),
              const SizedBox(height: 24),

              // 最近联系
              _buildRecentContacts(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String username) {
    final hour = DateTime.now().hour;
    String greeting = '早上好';
    if (hour >= 12 && hour < 18) {
      greeting = '下午好';
    } else if (hour >= 18) {
      greeting = '晚上好';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.primary.withOpacity(0.2),
            JewelryColors.gold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: JewelryColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: JewelryColors.goldGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: JewelryColors.gold.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.black87,
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
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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
                  borderRadius: BorderRadius.circular(10),
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
                  color: Colors.white.withOpacity(0.5),
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
    final totalAmount = stats['totalAmount'] as double? ?? 0.0;
    final amountStr = totalAmount >= 10000
        ? '\u00A5${(totalAmount / 10000).toStringAsFixed(1)}\u4E07'
        : '\u00A5${totalAmount.toStringAsFixed(0)}';
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
            Icon(Icons.bar_chart, color: JewelryColors.gold, size: 20),
            SizedBox(width: 8),
            Text(
              ref.tr('work_today_stats'),
              style: const TextStyle(
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
              child: _buildStatItem(
                icon: Icons.receipt_long,
                value: '$total',
                label: ref.tr('work_contact_shop'),
                color: JewelryColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.pending_actions,
                value: '$pending',
                label: ref.tr('work_interest'),
                color: JewelryColors.gold,
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
                color: const Color(0xFF667eea),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.shopping_bag,
                value: amountStr,
                label: ref.tr('work_order_amount'),
                color: const Color(0xFF11998e),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: Icons.people,
                value: '${pending + paid}',
                label: ref.tr('work_new_customer'),
                color: const Color(0xFFf093fb),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
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
          'title': '\u50AC\u4ED8: \u8BA2\u5355 #${order.id.substring(0, 8)}',
          'time': '${DateTime.now().hour}:00',
          'priority': 'high',
        });
      } else if (order.status == OrderStatus.paid) {
        todos.add({
          'title': '\u5F85\u53D1\u8D27: \u8BA2\u5355 #${order.id.substring(0, 8)}',
          'time': '${DateTime.now().hour}:30',
          'priority': 'high',
        });
      } else if (order.status == OrderStatus.shipped) {
        todos.add({
          'title': '\u8DDF\u8E2A\u7269\u6D41: \u8BA2\u5355 #${order.id.substring(0, 8)}',
          'time': '${DateTime.now().hour + 1}:00',
          'priority': 'medium',
        });
      }
    }

    // Add a default daily todo if no order todos
    if (todos.isEmpty) {
      todos.add({
        'title': '\u6574\u7406\u4ECA\u65E5\u5DE5\u4F5C\u7B80\u62A5',
        'time': '18:00',
        'priority': 'normal',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist, color: JewelryColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              ref.tr('work_todo_list'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: JewelryColors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${todos.where((t) => !(_todoCompleted[todos.indexOf(t)] ?? false)).length}项待办',
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
        priorityColor = JewelryColors.gold;
        break;
      default:
        priorityColor = JewelryColors.textHint;
    }

    return AnimatedOpacity(
      opacity: isCompleted ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.white24 : priorityColor,
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
                      color: Colors.white,
                      fontSize: 14,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.white.withOpacity(0.4),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        todo['time']!,
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
            GestureDetector(
              onTap: () {
                setState(() {
                  _todoCompleted[index] = !isCompleted;
                });
                if (!isCompleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ "${todo['title']}" 已完成'),
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
                      : JewelryColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.check,
                  color: isCompleted
                      ? JewelryColors.success
                      : JewelryColors.primary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.apps, color: JewelryColors.gold, size: 20),
            SizedBox(width: 8),
            Text(
              ref.tr('work_quick_features'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
            _buildFeatureButton(
                Icons.radar, ref.tr('work_ai_client'), JewelryColors.primary,
                onTap: () {
              _showFeatureToast(ref.tr('work_ai_client'), '正在扫描附近优质店铺...');
            }),
            _buildFeatureButton(Icons.message, ref.tr('work_ai_script'),
                const Color(0xFF667eea), onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIAssistantScreen(),
                  ));
            }),
            _buildFeatureButton(
                Icons.camera_alt, ref.tr('work_ar_tryon'), JewelryColors.gold,
                onTap: () {
              _showFeatureToast(ref.tr('work_ar_tryon'), 'AR 试戴模块加载中...');
            }),
            _buildFeatureButton(Icons.qr_code_scanner,
                ref.tr('work_traceability'), JewelryColors.success, onTap: () {
              _showTraceabilityDialog();
            }),
            _buildFeatureButton(Icons.image_search, ref.tr('work_img_analysis'),
                const Color(0xFFf093fb), onTap: () {
              _showFeatureToast(ref.tr('work_img_analysis'), 'AI 图片鉴定功能开发中...');
            }),
            _buildFeatureButton(Icons.chat_bubble, ref.tr('work_import_chat'),
                const Color(0xFF11998e), onTap: () {
              _showFeatureToast(
                  ref.tr('work_import_chat'), '导入微信/抖音聊天记录开发中...');
            }),
            _buildFeatureButton(
                Icons.notifications,
                ref.tr('settings_notifications'),
                const Color(0xFFff6b6b), onTap: () {
              _showReminderSettings();
            }),
            _buildFeatureButton(Icons.account_balance_wallet,
                ref.tr('profile_account'), const Color(0xFFffc107), onTap: () {
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
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContacts() {
    final contacts = [
      {'name': '翡翠世家', 'status': '有意向', 'time': '2小时前', 'color': 'gold'},
      {'name': '玉缘珠宝', 'status': '洽谈中', 'time': '3小时前', 'color': 'primary'},
      {'name': '南红之家', 'status': '已合作', 'time': '昨天', 'color': 'success'},
      {'name': '黄金时代珠宝', 'status': '待联系', 'time': '昨天', 'color': 'hint'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: JewelryColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              ref.tr('work_recent_contacts'),
              style: const TextStyle(
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
        ...contacts.map((contact) => _buildContactItem(contact)),
      ],
    );
  }

  Widget _buildContactItem(Map<String, String> contact) {
    Color statusColor;
    switch (contact['color']) {
      case 'gold':
        statusColor = JewelryColors.gold;
        break;
      case 'primary':
        statusColor = JewelryColors.primary;
        break;
      case 'success':
        statusColor = JewelryColors.success;
        break;
      default:
        statusColor = JewelryColors.textHint;
    }

    return GestureDetector(
      onTap: () {
        _showContactDetail(contact);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: JewelryColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  contact['name']!.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact['time']!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                contact['status']!,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 功能对话框 ============

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

  void _showTraceabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: JewelryColors.success),
            SizedBox(width: 10),
            Text('区块链溯源查证',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: JewelryColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified,
                      color: JewelryColors.success, size: 48),
                  const SizedBox(height: 12),
                  const Text('扫描商品二维码',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '验证区块链上的鉴定证书信息',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showFeatureToast('溯源查证', '正在启动相机扫描...');
            },
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('开始扫描'),
            style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.success),
          ),
        ],
      ),
    );
  }

  void _showReminderSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: JewelryColors.gold),
                SizedBox(width: 10),
                Text('提醒设置',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            _buildReminderSwitch('客户跟进提醒', '到期自动提醒跟进客户', true),
            _buildReminderSwitch('订单状态提醒', '订单状态变更时通知', true),
            _buildReminderSwitch('每日工作简报', '每天18:00自动生成', false),
            _buildReminderSwitch('AI智能提醒', 'AI分析后推荐跟进客户', true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('保存设置'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
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
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) => setSwState(() => isOn = v),
                activeColor: JewelryColors.primary,
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
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 客户头像和名称
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: JewelryColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  contact['name']!.substring(0, 1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(contact['name']!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('状态: ${contact['status']}  |  最后联系: ${contact['time']}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 24),
            // 操作按钮
            Row(
              children: [
                Expanded(
                    child: _buildContactAction(
                        Icons.phone, '打电话', JewelryColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildContactAction(
                        Icons.message, '发消息', const Color(0xFF667eea))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildContactAction(
                        Icons.smart_toy, 'AI话术', JewelryColors.gold)),
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
        _showFeatureToast(label, '$label 功能开发中...');
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
