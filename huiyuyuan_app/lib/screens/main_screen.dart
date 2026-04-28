/// Main navigation shell for customer, operator, and admin roles.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../themes/colors.dart';
import '../widgets/common/notification_badge_icon.dart';
import 'admin/admin_dashboard.dart';
import 'chat/ai_assistant_screen.dart';
import 'operator/operator_home.dart';
import 'order/order_list_screen.dart';
import 'profile/profile_screen.dart';
import 'shop/shop_radar.dart';
import 'trade/product_list_screen.dart';

typedef MainScreenPageBuilder = List<Widget> Function(UserType role);

final mainScreenPageBuilderProvider = Provider<MainScreenPageBuilder>((ref) {
  return (role) {
    switch (role) {
      case UserType.admin:
        return const [
          AdminDashboard(),
          ProductListScreen(),
          ShopRadar(),
          AIAssistantScreen(),
          ProfileScreen(),
        ];
      case UserType.operator:
        return const [
          OperatorHome(),
          ProductListScreen(),
          ShopRadar(),
          AIAssistantScreen(),
          ProfileScreen(),
        ];
      case UserType.customer:
        return const [
          ProductListScreen(),
          OrderListScreen(),
          ShopRadar(),
          AIAssistantScreen(),
          ProfileScreen(),
        ];
    }
  };
});

/// Main application shell.
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
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(userRoleProvider);
    final unreadNotifications = ref.watch(notificationUnreadCountProvider);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _getPages(role),
      ),
      bottomNavigationBar: _buildBottomNavBar(
        role,
        unreadNotifications,
        user: user,
      ),
      floatingActionButton: _buildFAB(user: user),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Returns the page stack for the active role.
  List<Widget> _getPages(UserType role) {
    return ref.read(mainScreenPageBuilderProvider)(role);
  }

  /// Builds the bottom navigation shell.
  Widget _buildBottomNavBar(
    UserType role,
    int unreadNotifications, {
    required UserModel? user,
  }) {
    final aiLocked = _isFeatureLocked(user, 'ai_assistant');
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.deepJade.withOpacity(0.9),
                  JewelryColors.jadeBlack.withOpacity(0.96),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: JewelryShadows.liquidGlass,
              border: Border.all(
                color: JewelryColors.champagneGold.withOpacity(0.13),
                width: 1,
              ),
            ),
            child: SafeArea(
              top: false,
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
                              ? ref.tr('nav_workbench')
                              : ref.tr('nav_products'),
                      user: user,
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
                          ? ref.tr('order_list_title')
                          : ref.tr('nav_products'),
                      user: user,
                    ),
                    const SizedBox(width: 60),
                    _buildNavItem(
                      index: 3,
                      icon: aiLocked
                          ? Icons.lock_outline_rounded
                          : Icons.smart_toy_outlined,
                      activeIcon:
                          aiLocked ? Icons.lock_rounded : Icons.smart_toy,
                      label: ref.tr('nav_ai'),
                      user: user,
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: ref.tr('nav_profile'),
                      badgeCount: unreadNotifications,
                      user: user,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single bottom navigation item.
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required UserModel? user,
    int badgeCount = 0,
  }) {
    final isActive = _currentIndex == index;
    final inactiveColor = JewelryColors.jadeMist.withOpacity(0.46);
    const activeColor = JewelryColors.champagneGold;

    return GestureDetector(
      onTap: () => _onNavTap(index, user: user),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? JewelryColors.champagneGold.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? JewelryColors.champagneGold.withOpacity(0.16)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: isActive ? 22 : 4,
              height: 3,
              decoration: BoxDecoration(
                color:
                    isActive ? JewelryColors.emeraldGlow : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 5),
            NotificationBadgeIcon(
              icon: isActive ? activeIcon : icon,
              count: badgeCount,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? JewelryColors.jadeMist
                    : JewelryColors.jadeMist.withOpacity(0.48),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the center radar shortcut button.
  Widget _buildFAB({required UserModel? user}) {
    final isRadar = _currentIndex == 2;
    final radarLocked = _isFeatureLocked(user, 'shop_radar');
    final gradient = radarLocked
        ? const LinearGradient(
            colors: [Color(0xFF5B6578), Color(0xFF3C475B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (isRadar
            ? JewelryColors.champagneGradient
            : JewelryColors.emeraldLusterGradient);
    final glowColor = radarLocked
        ? const Color(0xFF5B6578)
        : (isRadar ? JewelryColors.champagneGold : JewelryColors.emeraldGlow);

    return GestureDetector(
      onTap: () => _onNavTap(2, user: user),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          border: Border.all(
            color: Colors.white.withOpacity(radarLocked ? 0.12 : 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(radarLocked ? 0.22 : 0.38),
              blurRadius: isRadar ? 24 : 18,
              spreadRadius: isRadar ? 2 : 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          radarLocked ? Icons.lock_outline_rounded : Icons.radar,
          color: radarLocked ? Colors.white70 : JewelryColors.jadeBlack,
          size: 28,
        ),
      ),
    );
  }

  /// Handles bottom navigation taps.
  void _onNavTap(int index, {required UserModel? user}) {
    if (_currentIndex == index) return;
    if (_isLockedIndex(index, user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.tr('operator_permission_denied')),
          backgroundColor: JewelryColors.deepJade,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  bool _isLockedIndex(int index, UserModel? user) {
    return switch (index) {
      2 => _isFeatureLocked(user, 'shop_radar'),
      3 => _isFeatureLocked(user, 'ai_assistant'),
      _ => false,
    };
  }

  bool _isFeatureLocked(UserModel? user, String permission) {
    if (user == null || user.userType != UserType.operator) {
      return false;
    }
    return !user.hasPermission(permission);
  }
}
