/// 汇玉源 - 主界面
///
/// 功能:
/// - 底部导航管理
/// - 管理员/操作员差异化界面
/// - 页面切换动画
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'dart:ui';
import '../themes/colors.dart';
import '../l10n/l10n_provider.dart';

// 页面导入
import 'trade/product_list_screen.dart';
import 'chat/ai_assistant_screen.dart';
import 'profile/profile_screen.dart';
import 'admin/admin_dashboard.dart';
import 'operator/operator_home.dart';
import 'shop/shop_radar.dart';

import 'order/order_list_screen.dart';

/// 主界面
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _getPages(role),
      ),
      bottomNavigationBar: _buildBottomNavBar(role),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// 获取页面列表 - 根据角色区分
  List<Widget> _getPages(UserType role) {
    switch (role) {
      case UserType.admin:
        return const [
          AdminDashboard(),       // 仪表盘
          ProductListScreen(),    // 商城
          ShopRadar(),            // 店铺雷达
          AIAssistantScreen(),    // AI助手
          ProfileScreen(),        // 个人中心
        ];
      case UserType.operator:
        return const [
          OperatorHome(),         // 工作台
          ProductListScreen(),    // 商城
          ShopRadar(),            // 店铺雷达
          AIAssistantScreen(),    // AI助手
          ProfileScreen(),        // 个人中心
        ];
      case UserType.customer:
        return const [
          ProductListScreen(),    // 商城首页
          OrderListScreen(),      // 我的订单
          ShopRadar(),            // 店铺雷达
          AIAssistantScreen(),    // AI助手
          ProfileScreen(),        // 个人中心
        ];
    }
  }

  /// 底部导航栏
  Widget _buildBottomNavBar(UserType role) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: role == UserType.admin
                        ? Icons.dashboard_outlined
                        : role == UserType.operator
                            ? Icons.work_outline
                            : Icons.storefront_outlined,
                    activeIcon: role == UserType.admin
                        ? Icons.dashboard
                        : role == UserType.operator
                            ? Icons.work
                            : Icons.storefront,
                    label: role == UserType.admin
                        ? ref.tr('admin_dashboard')
                        : role == UserType.operator
                            ? '工作台'
                            : ref.tr('nav_products'),
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: role == UserType.customer
                        ? Icons.receipt_long_outlined
                        : Icons.storefront_outlined,
                    activeIcon: role == UserType.customer
                        ? Icons.receipt_long
                        : Icons.storefront,
                    label: role == UserType.customer
                        ? '我的订单'
                        : ref.tr('nav_products'),
                  ),
                  const SizedBox(width: 60), // FAB空间
                  _buildNavItem(
                    index: 3,
                    icon: Icons.smart_toy_outlined,
                    activeIcon: Icons.smart_toy,
                    label: ref.tr('nav_ai'),
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: ref.tr('nav_profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 导航项
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? const Color(0xFF666680) : JewelryColors.textHint;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? JewelryColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? JewelryColors.primary : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? JewelryColors.primary : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 中间浮动按钮
  Widget _buildFAB() {
    final isRadar = _currentIndex == 2;

    return GestureDetector(
      onTap: () => _onNavTap(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isRadar
              ? JewelryColors.goldGradient
              : JewelryColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: (isRadar ? JewelryColors.gold : JewelryColors.primary)
                  .withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.radar,
          color: isRadar ? Colors.black87 : Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// 导航点击
  void _onNavTap(int index) {
    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }
}
