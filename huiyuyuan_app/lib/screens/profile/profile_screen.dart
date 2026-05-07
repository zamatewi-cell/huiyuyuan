/// HuiYuYuan profile hub.
///
/// This screen groups the primary account entry points:
/// - account summary
/// - orders and favorites
/// - payment account management
/// - reminders and app settings
/// - logout and account deactivation
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/l10n_provider.dart';
import '../../models/app_update_download_state.dart';
import '../../models/user_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/app_update_service.dart';
import '../../services/order_service.dart';
import '../../themes/colors.dart';
import '../../widgets/common/notification_badge_icon.dart';
import 'device_management_screen.dart';
import '../../widgets/app_update_dialog.dart';
import 'address_list_screen.dart';
import 'browse_history_screen.dart';
import 'favorite_list_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/user_agreement_screen.dart';
import '../notification/notification_screen.dart';
import '../order/order_list_screen.dart';
import '../payment_management_screen.dart';

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: _ProfileGlowOrb(
              size: 320,
              color: JewelryColors.emeraldGlow.withOpacity(0.12),
            ),
          ),
          Positioned(
            top: 220,
            left: -130,
            child: _ProfileGlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ProfileLatticePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileGlowOrb extends StatelessWidget {
  const _ProfileGlowOrb({
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
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

class _ProfileLatticePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.08 + i * 0.115);
      final path = Path()..moveTo(-20, y);
      path.quadraticBezierTo(
        size.width * 0.34,
        y + (i.isEven ? 18 : -18),
        size.width + 20,
        y + (i.isEven ? -10 : 10),
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileLatticePainter oldDelegate) => false;
}

/// Profile screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final unreadNotifications = ref.watch(notificationUnreadCountProvider);

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      body: Stack(
        children: [
          const Positioned.fill(child: _ProfileBackdrop()),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Account summary card.
                  _buildUserCard(
                    context,
                    ref,
                    _resolveDisplayName(ref, user, isAdmin),
                    user,
                    isAdmin,
                  ),

                  // Account stats card.
                  _buildAssetsCard(context, ref),

                  // Quick order entry points.
                  _buildOrderSection(context, ref),

                  // Shortcut menu.
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(ref.tr('profile_account_mgmt')),
                        _buildMenuItem(
                          ref,
                          icon: Icons.favorite,
                          title: ref.tr('profile_favorites'),
                          subtitle: ref.tr('profile_favorites_desc'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FavoriteListScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          ref,
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
                          ref,
                          icon: Icons.history,
                          title: ref.tr('profile_history'),
                          subtitle: ref.tr('profile_history_desc'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BrowseHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          ref,
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
                          ref,
                          icon: Icons.lock_reset,
                          title:
                              _ProfileAccountCopy.changePasswordTitle(context),
                          subtitle: _ProfileAccountCopy.changePasswordSubtitle(
                              context),
                          onTap: () => _showChangePasswordDialog(context, ref),
                        ),
                        _buildMenuItem(
                          ref,
                          icon: Icons.devices,
                          title: ref.tr('security_device_manage'),
                          subtitle: ref.tr('security_device_list'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeviceManagementScreen(),
                            ),
                          ),
                        ),
                        _buildMenuItem(
                          ref,
                          icon: Icons.notifications,
                          title: ref.tr('profile_reminder'),
                          subtitle: ref.tr('profile_reminder_desc'),
                          iconWidget: NotificationBadgeIcon(
                            icon: Icons.notifications,
                            count: unreadNotifications,
                            color: JewelryColors.champagneGold,
                            size: 20,
                          ),
                          onTap: () => _showReminderSettings(context),
                        ),

                        const SizedBox(height: 20),
                        _buildSectionTitle(ref.tr('profile_function_settings')),

                        _buildMenuItem(
                          ref,
                          icon: Icons.language,
                          title: ref.tr('settings_language'),
                          trailing: _getLanguageLabel(
                              ref, ref.watch(appSettingsProvider).language),
                          onTap: () => _showLanguageDialog(context, ref),
                        ),
                        _buildMenuItem(
                          ref,
                          icon: Icons.dark_mode,
                          title: ref.tr('settings_dark_mode'),
                          trailing: _getThemeModeLabel(
                              ref, ref.watch(appSettingsProvider).themeMode),
                          onTap: () => _showDarkModeDialog(context, ref),
                        ),
                        _buildMenuItem(
                          ref,
                          icon: Icons.storage,
                          title: ref.tr('settings_cache'),
                          trailing:
                              '${ref.watch(appSettingsProvider).cacheSize.toStringAsFixed(1)} MB',
                          onTap: () => _showClearCacheDialog(context, ref),
                        ),
                        _buildMenuItem(
                          ref,
                          icon: Icons.system_update_alt,
                          title: _ProfileAccountCopy.updateTitle(context),
                          subtitle: _ProfileAccountCopy.updateSubtitle(context),
                          trailing: 'v${AppConfig.appVersion}',
                          onTap: () => _checkForUpdatesManually(context),
                        ),

                        const SizedBox(height: 20),
                        _buildSectionTitle(ref.tr('profile_about')),

                        _buildMenuItem(
                          ref,
                          icon: Icons.privacy_tip,
                          title: ref.tr('settings_privacy'),
                          onTap: () => _showPrivacyPolicy(context, ref),
                        ),
                        _buildMenuItem(
                          ref,
                          icon: Icons.description,
                          title: ref.tr('settings_agreement'),
                          onTap: () => _showUserAgreement(context, ref),
                        ),
                        _buildMenuItem(
                          ref,
                          icon: Icons.info,
                          title: ref.tr('settings_about'),
                          trailing: 'v${AppConfig.appVersion}',
                          onTap: () => _showAboutDialog(context, ref),
                        ),

                        const SizedBox(height: 30),

                        // Sign-out actions.
                        _buildLogoutButton(context, ref),
                        if (user?.isCustomer ?? false) ...[
                          const SizedBox(height: 12),
                          _buildDeactivateButton(context, ref),
                        ],

                        const SizedBox(height: 30),

                        // Compliance footer.
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield,
                                    size: 14,
                                    color: JewelryColors.jadeMist
                                        .withOpacity(0.28),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ref.tr('compliance_cert'),
                                    style: TextStyle(
                                      color: JewelryColors.jadeMist
                                          .withOpacity(0.28),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ref.tr('compliance_copyright'),
                                style: TextStyle(
                                  color:
                                      JewelryColors.jadeMist.withOpacity(0.22),
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
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    WidgetRef ref,
    String username,
    UserModel? user,
    bool isAdmin,
  ) {
    final roleLabel = isAdmin
        ? ref.tr('role_admin')
        : user?.userType == UserType.operator
            ? ref.tr('role_operator')
            : ref.tr('role_customer');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.jadeSurface.withOpacity(0.82),
            JewelryColors.deepJade.withOpacity(0.94),
            JewelryColors.jadeBlack.withOpacity(0.96),
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
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -34,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: JewelryColors.champagneGold.withOpacity(0.12),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: isAdmin
                      ? JewelryColors.emeraldLusterGradient
                      : JewelryColors.champagneGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isAdmin
                      ? JewelryShadows.emeraldHalo
                      : [
                          BoxShadow(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: JewelryColors.jadeBlack,
                  size: 34,
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
                        color: JewelryColors.jadeMist,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      user?.phone ?? roleLabel,
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (isAdmin
                                ? JewelryColors.emeraldGlow
                                : JewelryColors.champagneGold)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: (isAdmin
                                  ? JewelryColors.emeraldGlow
                                  : JewelryColors.champagneGold)
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          color: isAdmin
                              ? JewelryColors.emeraldGlow
                              : JewelryColors.champagneGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
                    color: JewelryColors.deepJade.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: JewelryColors.champagneGold.withOpacity(0.14),
                    ),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: JewelryColors.jadeMist.withOpacity(0.72),
                    size: 18,
                  ),
                ),
                onPressed: () => _showEditProfileSheet(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _profileGlassDecoration({
    double radius = 22,
    double borderOpacity = 0.13,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          JewelryColors.deepJade.withOpacity(0.76),
          JewelryColors.jadeSurface.withOpacity(0.48),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: JewelryColors.champagneGold.withOpacity(borderOpacity),
      ),
      boxShadow: JewelryShadows.liquidGlass,
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: JewelryColors.jadeDepthGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: JewelryColors.champagneGold.withOpacity(0.36),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(ref.tr('profile_edit_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: JewelryColors.jadeMist,
                )),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: JewelryColors.jadeMist),
              decoration: InputDecoration(
                labelText: ref.tr('profile_nickname'),
                labelStyle: TextStyle(
                  color: JewelryColors.jadeMist.withOpacity(0.56),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: JewelryColors.champagneGold.withOpacity(0.16),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: JewelryColors.emeraldGlow,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ref.tr('profile_updated')),
                      backgroundColor: JewelryColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.emeraldLuster,
                  foregroundColor: JewelryColors.jadeBlack,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(ref.tr('save')),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsCard(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(orderStatsProvider);
    final isLoaded = ref.watch(orderLoadedProvider);
    if (!isLoaded) {
      return _buildAssetsLoadingCard(context, ref);
    }
    final total = stats['total'] as int? ?? 0;
    final totalAmount = stats['totalAmount'] as double? ?? 0.0;
    final pending = stats['pending'] as int? ?? 0;
    final paid = stats['paid'] as int? ?? 0;
    final pendingWork = pending + paid;
    final amountStr = _formatSalesAmount(ref, totalAmount);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _profileGlassDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAssetItem(
            ref.tr('profile_total_orders'),
            '$total',
            Icons.shopping_bag,
          ),
          _buildDivider(),
          _buildAssetItem(
            ref.tr('profile_total_sales'),
            amountStr,
            Icons.trending_up,
          ),
          _buildDivider(),
          _buildAssetItem(
              ref.tr('profile_pending'), '$pendingWork', Icons.pending_actions),
        ],
      ),
    );
  }

  Widget _buildAssetsLoadingCard(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _profileGlassDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLoadingAssetItem(
            ref.tr('profile_total_orders'),
            Icons.shopping_bag,
          ),
          _buildDivider(),
          _buildLoadingAssetItem(
            ref.tr('profile_total_sales'),
            Icons.trending_up,
          ),
          _buildDivider(),
          _buildLoadingAssetItem(
            ref.tr('profile_pending'),
            Icons.pending_actions,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAssetItem(String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: JewelryColors.champagneGold, size: 24),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 18,
          decoration: BoxDecoration(
            color: JewelryColors.jadeMist.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: JewelryColors.jadeMist.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JewelryColors.champagneGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: JewelryColors.champagneGold, size: 22),
        ),
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
            color: JewelryColors.jadeMist.withOpacity(0.52),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: JewelryColors.champagneGold.withOpacity(0.1),
    );
  }

  Widget _buildOrderSection(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: _profileGlassDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ref.tr('order_list_title'),
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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
                      ref.tr('view_all_orders'),
                      style: TextStyle(
                        color: JewelryColors.champagneGold.withOpacity(0.76),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: JewelryColors.champagneGold.withOpacity(0.76),
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
              _buildOrderItem(
                  context, Icons.payment, ref.tr('order_pending_payment'), 0),
              _buildOrderItem(context, Icons.local_shipping_outlined,
                  ref.tr('order_pending_shipment'), 1),
              _buildOrderItem(context, Icons.inventory_2_outlined,
                  ref.tr('order_pending_receipt'), 2),
              _buildOrderItem(context, Icons.rate_review_outlined,
                  ref.tr('order_pending_review'), 3),
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
              gradient: JewelryColors.emeraldLusterGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: JewelryShadows.emeraldHalo,
            ),
            child: Icon(icon, color: JewelryColors.jadeBlack, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.68),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 2,
            decoration: BoxDecoration(
              color: JewelryColors.emeraldGlow.withOpacity(0.7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.56),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    WidgetRef ref, {
    required IconData icon,
    Widget? iconWidget,
    required String title,
    String? subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Builder(builder: (context) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _profileGlassDecoration(radius: 18, borderOpacity: 0.1),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JewelryColors.emeraldGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: JewelryColors.emeraldGlow.withOpacity(0.12),
                  ),
                ),
                child: iconWidget ??
                    Icon(icon, color: JewelryColors.emeraldGlow, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: JewelryColors.jadeMist.withOpacity(0.42),
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
                    color: JewelryColors.champagneGold.withOpacity(0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: JewelryColors.jadeMist.withOpacity(0.28),
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
          color: JewelryColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: JewelryColors.error.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: JewelryColors.error.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: JewelryColors.error, size: 20),
            const SizedBox(width: 10),
            Text(
              ref.tr('logout'),
              style: const TextStyle(
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

  Widget _buildDeactivateButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDeactivateAccountDialog(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: JewelryColors.deepJade.withOpacity(0.42),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: JewelryColors.error.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_remove_alt_1,
                color: JewelryColors.error, size: 18),
            const SizedBox(width: 10),
            Text(
              _ProfileAccountCopy.deactivateTitle(context),
              style: const TextStyle(
                color: JewelryColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          ref.tr('logout_button'),
          style: const TextStyle(color: JewelryColors.jadeMist),
        ),
        content: Text(
          ref.tr('logout_message'),
          style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              ref.tr('cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(ref.tr('logout_button')),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdatesManually(BuildContext context) async {
    if (kIsWeb) {
      _showAccountMessage(
        context,
        _ProfileAccountCopy.updateUpToDate(context),
      );
      return;
    }

    final service = AppUpdateService();
    final info = await service.fetchLatestUpdate();
    if (!context.mounted) {
      return;
    }

    if (info == null) {
      _showAccountMessage(
        context,
        _ProfileAccountCopy.updateFailed(context),
        isError: true,
      );
      return;
    }

    final needsPrompt =
        info.requiresImmediateUpdate(AppConfig.appBuildNumber) ||
            info.hasNewerBuildThan(AppConfig.appBuildNumber);
    if (!needsPrompt) {
      _showAccountMessage(
        context,
        _ProfileAccountCopy.updateUpToDate(context),
      );
      return;
    }

    final action = await showDialog<AppUpdateAction>(
      context: context,
      barrierDismissible:
          !info.requiresImmediateUpdate(AppConfig.appBuildNumber),
      builder: (_) => AppUpdateDialog(info: info),
    );
    if (!context.mounted || action == null) {
      return;
    }

    if (action == AppUpdateAction.later) {
      await service.rememberSkippedBuild(info);
      if (context.mounted) {
        _showAccountMessage(
          context,
          _ProfileAccountCopy.updateDeferred(context),
        );
      }
      return;
    }

    await service.clearSkippedBuild();
    final state = await service.startUpdate(info);
    if (!context.mounted) {
      return;
    }
    _showUpdateActionMessage(context, state);
  }

  void _showUpdateActionMessage(
    BuildContext context,
    AppUpdateDownloadState state,
  ) {
    switch (state.status) {
      case AppUpdateDownloadStatus.external:
        return;
      case AppUpdateDownloadStatus.queued:
      case AppUpdateDownloadStatus.running:
      case AppUpdateDownloadStatus.paused:
        _showAccountMessage(
          context,
          _ProfileAccountCopy.updateDownloadStarted(context),
        );
        return;
      case AppUpdateDownloadStatus.installing:
        _showAccountMessage(
          context,
          _ProfileAccountCopy.updateInstallStarted(context),
        );
        return;
      case AppUpdateDownloadStatus.permissionRequired:
        _showAccountMessage(
          context,
          _ProfileAccountCopy.updateInstallPermissionRequired(context),
        );
        return;
      case AppUpdateDownloadStatus.unavailable:
        _showAccountMessage(
          context,
          _ProfileAccountCopy.updateLinkUnavailable(context),
          isError: true,
        );
        return;
      case AppUpdateDownloadStatus.failed:
        _showAccountMessage(
          context,
          _ProfileAccountCopy.updateDownloadFailed(context),
          isError: true,
        );
        return;
      case AppUpdateDownloadStatus.successful:
      case AppUpdateDownloadStatus.idle:
        return;
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool obscureCurrent = true;
    bool obscureNext = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _ProfileAccountCopy.changePasswordTitle(context),
            style: TextStyle(
              color: isDark ? Colors.white : JewelryColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ProfileAccountCopy.changePasswordHint(context),
                  style: TextStyle(
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText:
                        _ProfileAccountCopy.currentPasswordLabel(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureCurrent = !obscureCurrent);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNext,
                  decoration: InputDecoration(
                    labelText: _ProfileAccountCopy.newPasswordLabel(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNext
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureNext = !obscureNext);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureNext,
                  decoration: InputDecoration(
                    labelText:
                        _ProfileAccountCopy.confirmPasswordLabel(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: Text(ref.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final success = await ref
                          .read(authProvider.notifier)
                          .changeCurrentUserPassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                            confirmPasswordController.text,
                          );
                      if (!dialogContext.mounted) {
                        return;
                      }
                      setDialogState(() => isSubmitting = false);
                      if (success) {
                        Navigator.pop(dialogContext);
                        _showAccountMessage(
                          context,
                          _ProfileAccountCopy.changePasswordSuccess(context),
                        );
                        return;
                      }
                      _showAccountMessage(
                        context,
                        ref.read(authProvider.notifier).lastLoginError ??
                            _ProfileAccountCopy.changePasswordFailed(context),
                        isError: true,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_ProfileAccountCopy.changePasswordAction(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeactivateAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool obscurePassword = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _ProfileAccountCopy.deactivateDialogTitle(context),
            style: TextStyle(
              color: isDark ? Colors.white : JewelryColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ProfileAccountCopy.deactivateDialogHint(context),
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.65),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _ProfileAccountCopy.deactivateImpact(context),
                  style: TextStyle(
                    color: JewelryColors.error.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText:
                        _ProfileAccountCopy.currentPasswordLabel(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(
                            () => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    labelText:
                        _ProfileAccountCopy.deactivateConfirmLabel(context),
                    hintText:
                        _ProfileAccountCopy.deactivateConfirmWord(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: Text(ref.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final confirmWord =
                          _ProfileAccountCopy.deactivateConfirmWord(context);
                      if (confirmController.text.trim() != confirmWord) {
                        _showAccountMessage(
                          context,
                          _ProfileAccountCopy.deactivateConfirmMismatch(
                              context),
                          isError: true,
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      final success = await ref
                          .read(authProvider.notifier)
                          .deactivateCurrentAccount(passwordController.text);
                      if (!dialogContext.mounted) {
                        return;
                      }
                      setDialogState(() => isSubmitting = false);
                      if (success) {
                        Navigator.pop(dialogContext);
                        _showAccountMessage(
                          context,
                          _ProfileAccountCopy.deactivateSuccess(context),
                        );
                        return;
                      }
                      _showAccountMessage(
                        context,
                        ref.read(authProvider.notifier).lastLoginError ??
                            _ProfileAccountCopy.deactivateFailed(context),
                        isError: true,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.error,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_ProfileAccountCopy.deactivateAction(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? JewelryColors.error : JewelryColors.success,
      ),
    );
  }

  // Settings dialogs.

  void _showReminderSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderSettingsSheet(parentContext: context),
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
                Text(ref.tr('settings_language'),
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
                            '${ref.tr('switched_to')} ${_getLanguageLabel(ref, lang)}',
                          ),
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
                Text(ref.tr('theme_settings'),
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
                            '${ref.tr('switched_to')} ${_getThemeModeLabel(ref, mode)}',
                          ),
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
            Text(ref.tr('settings_cache_clear'),
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
                        ref.tr('settings_cache_desc'),
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
              ref.tr('settings_cache_hint'),
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
            child: Text(ref.tr('cancel'),
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
                  content: Text(
                    '${ref.tr('cache_cleared')} ${cacheSize.toStringAsFixed(1)} ${ref.tr('cache_unit')}',
                  ),
                  backgroundColor: JewelryColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.primary),
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: Text(ref.tr('confirm_clear')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _showUserAgreement(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserAgreementScreen()),
    );
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
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
                ref.tr('app_name'),
                style: TextStyle(
                    color: isDark ? Colors.white : JewelryColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'v${AppConfig.appVersion} - Build ${AppConfig.appBuildNumber}',
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
                      ref.tr('app_slogan'),
                      style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.8),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ref.tr('app_features'),
                      style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.5),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAboutStat(ref.tr('about_partner'), '5,000+'),
                        _buildAboutStat(
                          ref.tr('about_cert'),
                          ref.tr('about_cert_value'),
                        ),
                        _buildAboutStat(
                          ref.tr('about_users'),
                          ref.tr('about_users_value'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ref.tr('about_copyright'),
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
              child: Text(ref.tr('close'),
                  style: const TextStyle(color: JewelryColors.primary)),
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

  // Helper methods.

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

  String _resolveDisplayName(WidgetRef ref, UserModel? user, bool isAdmin) {
    if (isAdmin) {
      return ref.tr('role_admin');
    }

    final username = user?.username.trim();
    if (username == null || username.isEmpty) {
      return ref.tr('profile_default_username');
    }

    if (user?.isCustomer ?? false) {
      final generatedNameMatch = RegExp(
        r'^(?:\u7528\u6237|\u7528\u6236|User)\s?(\d{3,})$',
      ).firstMatch(username);
      if (generatedNameMatch != null) {
        final suffix = generatedNameMatch.group(1)!;
        final localizedBase = ref.tr('profile_default_username');
        final useSpace =
            ref.watch(appSettingsProvider).language == AppLanguage.en;
        return useSpace ? '$localizedBase $suffix' : '$localizedBase$suffix';
      }
    }

    return username;
  }

  String _formatSalesAmount(WidgetRef ref, double amount) {
    final language = ref.watch(appSettingsProvider).language;
    if (amount >= 10000) {
      if (language == AppLanguage.en) {
        return '\u00A5${(amount / 1000).toStringAsFixed(0)}K';
      }
      if (language == AppLanguage.zhTW) {
        return '\u00A5${(amount / 10000).toStringAsFixed(1)}\u842c';
      }
      return '\u00A5${(amount / 10000).toStringAsFixed(1)}\u4e07';
    }
    return '\u00A5${amount.toStringAsFixed(0)}';
  }
}

/// Reminder settings sheet backed by local persistence.
class _ReminderSettingsSheet extends ConsumerStatefulWidget {
  const _ReminderSettingsSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  ConsumerState<_ReminderSettingsSheet> createState() =>
      _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState
    extends ConsumerState<_ReminderSettingsSheet> {
  bool _customerReminder = true;
  bool _orderReminder = true;
  bool _dailyReport = false;
  bool _aiReminder = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _customerReminder = prefs.getBool('reminder_customer') ?? true;
        _orderReminder = prefs.getBool('reminder_order') ?? true;
        _dailyReport = prefs.getBool('reminder_daily') ?? false;
        _aiReminder = prefs.getBool('reminder_ai') ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_customer', _customerReminder);
    await prefs.setBool('reminder_order', _orderReminder);
    await prefs.setBool('reminder_daily', _dailyReport);
    await prefs.setBool('reminder_ai', _aiReminder);
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifications = ref.watch(notificationUnreadCountProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: JewelryColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    ref.tr('reminder_settings'),
                    style: const TextStyle(
                      color: JewelryColors.jadeMist,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (unreadNotifications > 0) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: JewelryColors.emeraldGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: JewelryColors.emeraldGlow.withOpacity(0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      NotificationBadgeIcon(
                        icon: Icons.notifications_active,
                        count: unreadNotifications,
                        color: JewelryColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ref.tr('notification_unread_summary', params: {
                            'count': unreadNotifications,
                          }),
                          style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.86),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _openNotificationCenter,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: JewelryColors.champagneGold,
                          side: BorderSide(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        child: Text(ref.tr('notification_view_center')),
                      ),
                    ],
                  ),
                ),
              ],
              _buildSwitch(
                ref.tr('reminder_customer'),
                ref.tr('reminder_customer_desc'),
                _customerReminder,
                (v) {
                  setState(() => _customerReminder = v);
                },
              ),
              _buildSwitch(
                ref.tr('reminder_order'),
                ref.tr('reminder_order_desc'),
                _orderReminder,
                (v) {
                  setState(() => _orderReminder = v);
                },
              ),
              _buildSwitch(
                ref.tr('reminder_daily'),
                ref.tr('reminder_daily_desc'),
                _dailyReport,
                (v) {
                  setState(() => _dailyReport = v);
                },
              ),
              _buildSwitch(
                ref.tr('reminder_ai'),
                ref.tr('reminder_ai_desc'),
                _aiReminder,
                (v) {
                  setState(() => _aiReminder = v);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveSettings();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ref.tr('reminder_saved')),
                          backgroundColor: JewelryColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JewelryColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(ref.tr('save_settings')),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotificationCenter() {
    final parentContext = widget.parentContext;
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!parentContext.mounted) {
        return;
      }
      Navigator.of(parentContext).push(
        MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ),
      );
    });
  }

  Widget _buildSwitch(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JewelryColors.deepJade.withOpacity(0.56),
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
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: JewelryColors.emeraldGlow,
          ),
        ],
      ),
    );
  }
}

class _ProfileAccountCopy {
  _ProfileAccountCopy._();

  static String changePasswordTitle(BuildContext context) =>
      _fromKey(context, 'profile_change_password_title');

  static String changePasswordSubtitle(BuildContext context) =>
      _fromKey(context, 'profile_change_password_subtitle');

  static String changePasswordHint(BuildContext context) =>
      _fromKey(context, 'profile_change_password_hint');

  static String currentPasswordLabel(BuildContext context) =>
      _fromKey(context, 'profile_current_password');

  static String newPasswordLabel(BuildContext context) =>
      _fromKey(context, 'profile_new_password');

  static String confirmPasswordLabel(BuildContext context) =>
      _fromKey(context, 'profile_confirm_new_password');

  static String changePasswordAction(BuildContext context) =>
      _fromKey(context, 'profile_change_password_action');

  static String changePasswordSuccess(BuildContext context) =>
      _fromKey(context, 'profile_change_password_success');

  static String changePasswordFailed(BuildContext context) =>
      _fromKey(context, 'profile_change_password_failed');

  static String updateTitle(BuildContext context) =>
      _fromKey(context, 'profile_check_updates');

  static String updateSubtitle(BuildContext context) =>
      _fromKey(context, 'profile_check_updates_subtitle');

  static String updateFailed(BuildContext context) =>
      _fromKey(context, 'profile_update_failed');

  static String updateUpToDate(BuildContext context) =>
      _fromKey(context, 'profile_up_to_date');

  static String updateDeferred(BuildContext context) =>
      _fromKey(context, 'profile_update_deferred');

  static String updateLinkUnavailable(BuildContext context) =>
      _fromKey(context, 'profile_update_link_unavailable');

  static String updateDownloadStarted(BuildContext context) =>
      _fromKey(context, 'app_update_download_started');

  static String updateDownloadFailed(BuildContext context) =>
      _fromKey(context, 'app_update_download_failed');

  static String updateInstallStarted(BuildContext context) =>
      _fromKey(context, 'app_update_install_started');

  static String updateInstallPermissionRequired(BuildContext context) =>
      _fromKey(context, 'app_update_install_permission_required');

  static String deactivateTitle(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_title');

  static String deactivateDialogTitle(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_dialog_title');

  static String deactivateDialogHint(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_dialog_hint');

  static String deactivateImpact(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_impact');

  static String deactivateConfirmLabel(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_confirm_label');

  static String deactivateConfirmWord(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_confirm_word');

  static String deactivateConfirmMismatch(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_confirm_mismatch');

  static String deactivateAction(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_action');

  static String deactivateSuccess(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_success');

  static String deactivateFailed(BuildContext context) =>
      _fromKey(context, 'profile_deactivate_failed');

  static String _fromKey(BuildContext context, String key) {
    final locale = Localizations.localeOf(context);
    final country = locale.countryCode?.toUpperCase();
    final script = locale.scriptCode?.toUpperCase();
    final language = locale.languageCode == 'en'
        ? AppLanguage.en
        : locale.languageCode == 'zh' &&
                (country == 'TW' ||
                    country == 'HK' ||
                    country == 'MO' ||
                    script == 'HANT')
            ? AppLanguage.zhTW
            : AppLanguage.zhCN;
    return AppStrings.get(language, key);
  }
}
