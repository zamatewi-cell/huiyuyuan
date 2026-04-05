/// 设备管理页面
///
/// 展示当前用户的所有登录设备，支持移除指定设备和退出其他设备。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/string_extension.dart';
import '../../providers/auth_provider.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';

class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends ConsumerState<DeviceManagementScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final devices = await ref.read(authProvider.notifier).getDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _removeDevice(String fingerprint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JewelryColors.darkBackground,
        title: Text('security_remove_device_confirm'.tr),
        content: Text('security_remove_device_desc'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common_confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(authProvider.notifier).removeDevice(fingerprint);
      if (success && mounted) {
        await _loadDevices();
      }
    }
  }

  Future<void> _logoutOthers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JewelryColors.darkBackground,
        title: Text('security_logout_others_confirm'.tr),
        content: Text('security_logout_others_desc'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common_confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logoutOtherDevices();
      await _loadDevices();
    }
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    if (ts is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  IconData _deviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'mobile':
        return Icons.smartphone;
      case 'desktop':
        return Icons.computer;
      case 'tablet':
        return Icons.tablet;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JewelryColors.darkBackground,
      appBar: AppBar(
        title: Text('security_device_manage'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: JewelryColors.gold,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'common_refresh'.tr,
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices_other,
                          size: 64, color: JewelryColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'security_no_devices'.tr,
                        style: const TextStyle(
                            color: JewelryColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._devices.map((device) {
                      final isCurrent = device['is_current'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassmorphicCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrent
                                  ? JewelryColors.primary.withOpacity(0.2)
                                  : JewelryColors.darkSurface,
                              child: Icon(
                                _deviceIcon(device['device_type']?.toString() ?? ''),
                                color: isCurrent
                                    ? JewelryColors.primary
                                    : JewelryColors.textSecondary,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    device['device_type'] == 'mobile'
                                        ? 'security_device_mobile'.tr
                                        : device['device_type'] == 'desktop'
                                            ? 'security_device_desktop'.tr
                                            : 'security_device_unknown'.tr,
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          JewelryColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'security_device_current'.tr,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: JewelryColors.primary,
                                      ),
                                    ),
                                  ),
                                if (device['is_new_device'] == true)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          JewelryColors.warning.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'security_new_device'.tr,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: JewelryColors.warning,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (device['ip'] != null &&
                                    device['ip'].toString().isNotEmpty)
                                  Text(
                                    'security_device_ip'.trArgs({'ip': device['ip']}),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: JewelryColors.textSecondary),
                                  ),
                                if (device['last_login'] != null)
                                  Text(
                                    'security_device_last_login'.trArgs({
                                      'time': _formatTime(
                                          device['last_login_ts']),
                                    }),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: JewelryColors.textSecondary),
                                  ),
                              ],
                            ),
                            trailing: isCurrent
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: JewelryColors.error),
                                    onPressed: () =>
                                        _removeDevice(device['fingerprint']?.toString() ?? ''),
                                    tooltip: 'security_remove_device'.tr,
                                  ),
                          ),
                        ),
                      );
                    }).toList(),
                    if (_devices.length > 1) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logoutOthers,
                          icon: const Icon(Icons.logout),
                          label: Text('security_logout_others'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: JewelryColors.warning,
                            side: const BorderSide(color: JewelryColors.warning),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
