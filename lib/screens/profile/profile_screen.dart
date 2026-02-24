/// 汇玉源 - 个人中心
///
/// 功能:
/// - 用户信息展示
/// - 订单管理入口
/// - 收藏管理入口
/// - 收款账户管理
/// - 提醒设置
/// - 系统设置
/// - 退出登录
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../l10n/l10n_provider.dart';
import '../payment_management_screen.dart';
import '../order/order_list_screen.dart';
import 'favorite_list_screen.dart';
import 'browse_history_screen.dart';
import 'address_list_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/user_agreement_screen.dart';

/// 个人中心页面
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 用户信息卡片
              _buildUserCard(context, user?.username ?? '用户', isAdmin),

              // 资产卡片
              _buildAssetsCard(context),

              // 订单入口
              _buildOrderSection(context),

              // 快捷菜单
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(ref.tr('profile_account_mgmt')),
                    _buildMenuItem(
                      icon: Icons.favorite,
                      title: ref.tr('profile_favorites'),
                      subtitle: ref.tr('profile_favorites_desc'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoriteListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.location_on,
                      title: ref.tr('profile_address'),
                      subtitle: ref.tr('profile_address_desc'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddressListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.history,
                      title: ref.tr('profile_history'),
                      subtitle: ref.tr('profile_history_desc'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BrowseHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet,
                      title: ref.tr('profile_payment'),
                      subtitle: ref.tr('profile_payment_desc'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PaymentManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      title: ref.tr('profile_reminder'),
                      subtitle: ref.tr('profile_reminder_desc'),
                      onTap: () => _showReminderSettings(context),
                    ),

                    const SizedBox(height: 20),
                    _buildSectionTitle(ref.tr('profile_function_settings')),

                    _buildMenuItem(
                      icon: Icons.language,
                      title: ref.tr('settings_language'),
                      trailing: _getLanguageLabel(
                          ref, ref.watch(appSettingsProvider).language),
                      onTap: () => _showLanguageDialog(context, ref),
                    ),
                    _buildMenuItem(
                      icon: Icons.dark_mode,
                      title: ref.tr('settings_dark_mode'),
                      trailing: _getThemeModeLabel(
                          ref, ref.watch(appSettingsProvider).themeMode),
                      onTap: () => _showDarkModeDialog(context, ref),
                    ),
                    _buildMenuItem(
                      icon: Icons.storage,
                      title: ref.tr('settings_cache'),
                      trailing:
                          '${ref.watch(appSettingsProvider).cacheSize.toStringAsFixed(1)} MB',
                      onTap: () => _showClearCacheDialog(context, ref),
                    ),

                    const SizedBox(height: 20),
                    _buildSectionTitle(ref.tr('profile_about')),

                    _buildMenuItem(
                      icon: Icons.privacy_tip,
                      title: ref.tr('settings_privacy'),
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.description,
                      title: ref.tr('settings_agreement'),
                      onTap: () => _showUserAgreement(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.info,
                      title: ref.tr('settings_about'),
                      trailing: 'v3.0.0',
                      onTap: () => _showAboutDialog(context),
                    ),

                    const SizedBox(height: 30),

                    // 退出登录按钮
                    _buildLogoutButton(context, ref),

                    const SizedBox(height: 30),

                    // 合规信息
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield,
                                size: 14,
                                color: (isDark ? Colors.white : Colors.black)
                                    .withOpacity(0.3),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '等保三级认证 · 数据加密存储',
                                style: TextStyle(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withOpacity(0.3),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2026 汇玉源 · 中国境内合规运营',
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.25),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String username, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.primary.withOpacity(0.3),
            JewelryColors.gold.withOpacity(0.2),
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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: isAdmin
                  ? JewelryColors.primaryGradient
                  : JewelryColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isAdmin ? JewelryColors.primary : JewelryColors.gold)
                      .withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: isAdmin ? Colors.white : Colors.black87,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        (isAdmin ? JewelryColors.primary : JewelryColors.gold)
                            .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAdmin ? '超级管理员' : '操作员',
                    style: TextStyle(
                      color:
                          isAdmin ? JewelryColors.primary : JewelryColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
              child: const Icon(Icons.edit, color: Colors.white70, size: 18),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAssetItem('今日订单', '12', Icons.shopping_bag),
          _buildDivider(),
          _buildAssetItem('本月业绩', '¥8.5万', Icons.trending_up),
          _buildDivider(),
          _buildAssetItem('待处理', '3', Icons.pending_actions),
        ],
      ),
    );
  }

  Widget _buildAssetItem(String label, String value, IconData icon) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        children: [
          Icon(icon, color: JewelryColors.gold, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : JewelryColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDivider() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: 1,
        height: 50,
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
      );
    });
  }

  Widget _buildOrderSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '我的订单',
                style: TextStyle(
                  color: isDark ? Colors.white : JewelryColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      '全部订单',
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.5),
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderItem(context, Icons.payment, '待付款', 0),
              _buildOrderItem(context, Icons.local_shipping_outlined, '待发货', 1),
              _buildOrderItem(context, Icons.inventory_2_outlined, '待收货', 2),
              _buildOrderItem(context, Icons.rate_review_outlined, '待评价', 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
      BuildContext context, IconData icon, String label, int tabIndex) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderListScreen(initialTab: tabIndex + 1),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JewelryColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: JewelryColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  .withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      );
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1)),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JewelryColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: JewelryColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color:
                            isDark ? Colors.white : JewelryColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: TextStyle(
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                size: 14,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: JewelryColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: JewelryColors.error.withOpacity(0.3),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: JewelryColors.error, size: 20),
            SizedBox(width: 10),
            Text(
              '退出登录',
              style: TextStyle(
                color: JewelryColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '确认退出',
          style: TextStyle(
              color: isDark ? Colors.white : JewelryColors.textPrimary),
        ),
        content: Text(
          '确定要退出当前账号吗？',
          style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );
  }

  // ============ 设置功能对话框 ============

  void _showReminderSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderSettingsSheet(),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(appSettingsProvider).language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.language,
                    color: JewelryColors.primary, size: 22),
                const SizedBox(width: 10),
                Text('语言设置',
                    style: TextStyle(
                        color:
                            isDark ? Colors.white : JewelryColors.textPrimary)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppLanguage.values.map((lang) {
                final isSelected = currentLang == lang;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? JewelryColors.primary.withOpacity(0.15)
                        : (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: JewelryColors.primary.withOpacity(0.5))
                        : null,
                  ),
                  child: ListTile(
                    title: Text(_getLanguageLabel(ref, lang),
                        style: TextStyle(
                            color: isSelected
                                ? (isDark
                                    ? Colors.white
                                    : JewelryColors.textPrimary)
                                : (isDark
                                    ? Colors.white70
                                    : JewelryColors.textSecondary))),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: JewelryColors.primary)
                        : Icon(Icons.circle_outlined,
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.2)),
                    onTap: () {
                      ref.read(appSettingsProvider.notifier).setLanguage(lang);
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '✅ ${ref.tr('switched_to')} ${_getLanguageLabel(ref, lang)}'),
                          backgroundColor: JewelryColors.primary,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showDarkModeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(appSettingsProvider).themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icons = {
      AppThemeMode.dark: Icons.dark_mode,
      AppThemeMode.light: Icons.light_mode,
      AppThemeMode.system: Icons.settings_brightness,
    };
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.palette, color: JewelryColors.gold, size: 22),
                const SizedBox(width: 10),
                Text('主题设置',
                    style: TextStyle(
                        color:
                            isDark ? Colors.white : JewelryColors.textPrimary)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppThemeMode.values.map((mode) {
                final isSelected = currentMode == mode;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? JewelryColors.gold.withOpacity(0.15)
                        : (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: JewelryColors.gold.withOpacity(0.5))
                        : null,
                  ),
                  child: ListTile(
                    leading: Icon(icons[mode],
                        color: isSelected
                            ? JewelryColors.gold
                            : (isDark ? Colors.white54 : Colors.black45)),
                    title: Text(_getThemeModeLabel(ref, mode),
                        style: TextStyle(
                            color: isSelected
                                ? (isDark
                                    ? Colors.white
                                    : JewelryColors.textPrimary)
                                : (isDark
                                    ? Colors.white70
                                    : JewelryColors.textSecondary))),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: JewelryColors.gold)
                        : Icon(Icons.circle_outlined,
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.2)),
                    onTap: () {
                      ref.read(appSettingsProvider.notifier).setThemeMode(mode);
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '✅ ${ref.tr('switched_to')} ${_getThemeModeLabel(ref, mode)}'),
                          backgroundColor: JewelryColors.primary,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    final cacheSize = ref.read(appSettingsProvider).cacheSize;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cleaning_services,
                color: JewelryColors.info, size: 22),
            const SizedBox(width: 10),
            Text('清除缓存',
                style: TextStyle(
                    color: isDark ? Colors.white : JewelryColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.storage,
                      color: JewelryColors.info.withOpacity(0.7), size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cacheSize.toStringAsFixed(1)} MB',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : JewelryColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '包含图片缓存、网络缓存等',
                        style: TextStyle(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.5),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '清除后可能需要重新加载部分内容',
              style: TextStyle(
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                  fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('取消',
                style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.5))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).clearCache();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ 已清除 ${cacheSize.toStringAsFixed(1)} MB 缓存'),
                  backgroundColor: JewelryColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.primary),
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _showUserAgreement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserAgreementScreen()),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: JewelryColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.diamond, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                '汇玉源',
                style: TextStyle(
                    color: isDark ? Colors.white : JewelryColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'v3.0.0 · Build 202602',
                style: TextStyle(
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                    fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '珠宝玉石全产业链 AI 平台',
                      style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.8),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '区块链溯源 · AI智能鉴定 · 全链路服务',
                      style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.5),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAboutStat('合作店铺', '5,000+'),
                        _buildAboutStat('鉴定证书', '100万+'),
                        _buildAboutStat('用户数', '50万+'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2026 汇玉源科技有限公司',
                style: TextStyle(
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                    fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭',
                  style: TextStyle(color: JewelryColors.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutStat(String label, String value) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: JewelryColors.gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
              fontSize: 10,
            ),
          ),
        ],
      );
    });
  }

  // ============ 辅助方法 ============

  String _getLanguageLabel(WidgetRef ref, AppLanguage language) {
    switch (language) {
      case AppLanguage.zhCN:
        return ref.tr('lang_zh');
      case AppLanguage.en:
        return ref.tr('lang_en');
      case AppLanguage.zhTW:
        return ref.tr('lang_tw');
    }
  }

  String _getThemeModeLabel(WidgetRef ref, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return ref.tr('theme_dark');
      case AppThemeMode.light:
        return ref.tr('theme_light');
      case AppThemeMode.system:
        return ref.tr('theme_system');
    }
  }
}

/// 提醒设置弹窗
class _ReminderSettingsSheet extends StatefulWidget {
  @override
  State<_ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<_ReminderSettingsSheet> {
  bool _customerReminder = true;
  bool _orderReminder = true;
  bool _dailyReport = false;
  bool _aiReminder = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: JewelryColors.gold),
              const SizedBox(width: 10),
              Text('提醒设置',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : JewelryColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 20),
          _buildSwitch('客户跟进提醒', '到期自动提醒跟进客户', _customerReminder, (v) {
            setState(() => _customerReminder = v);
          }),
          _buildSwitch('订单状态提醒', '订单状态变更时通知', _orderReminder, (v) {
            setState(() => _orderReminder = v);
          }),
          _buildSwitch('每日工作简报', '每天18:00自动生成', _dailyReport, (v) {
            setState(() => _dailyReport = v);
          }),
          _buildSwitch('AI智能提醒', 'AI分析后推荐跟进客户', _aiReminder, (v) {
            setState(() => _aiReminder = v);
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 提醒设置已保存'),
                    backgroundColor: JewelryColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存设置'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSwitch(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color:
                            isDark ? Colors.white : JewelryColors.textPrimary,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.4),
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: JewelryColors.primary,
          ),
        ],
      ),
    );
  }
}
