import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/json_parsing.dart';
import '../../models/order_model.dart';
import '../../themes/colors.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

/// 物流追踪时间线页面
class LogisticsScreen extends StatefulWidget {
  final OrderModel order;

  const LogisticsScreen({super.key, required this.order});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  List<LogisticsEntry>? _apiEntries;

  @override
  void initState() {
    super.initState();
    _fetchLogisticsFromApi();
  }

  /// 尝试从后端 API 获取真实物流信息
  Future<void> _fetchLogisticsFromApi() async {
    try {
      final api = ApiService();
      final result = await api.get<dynamic>(
        '${ApiConfig.orderDetail(widget.order.id)}/logistics',
      );
      if (result.success && result.data != null) {
        final data = result.data;
        List<dynamic> items;
        if (data is Map && data['entries'] != null) {
          items = data['entries'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        } else {
          return;
        }
        if (mounted) {
          setState(() {
            _apiEntries = items
                .map((j) => LogisticsEntry.fromJson(jsonAsMap(j)))
                .toList();
          });
        }
      }
    } catch (_) {
      // API 失败时，默认回退使用订单状态时间线
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? JewelryColors.darkBackground : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6B7280);

    final entries = _buildEntries();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('logistics_title'.tr),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tracking info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: JewelryColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.order.logisticsCompany ??
                            'logistics_company_fallback'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.order.status.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.order.status.localizedLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.order.status.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.order.trackingNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'logistics_tracking_number'.trArgs({
                          'number': widget.order.trackingNumber!,
                        }),
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                            ClipboardData(text: widget.order.trackingNumber!),
                          );
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text('logistics_copy_success'.tr)),
                          );
                        },
                        child: const Icon(Icons.copy,
                            size: 14, color: JewelryColors.primaryGreen),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A3A)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.order.productImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.order.productImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.diamond_outlined,
                                size: 28,
                                color: JewelryColors.primaryGreen),
                          ),
                        )
                      : const Icon(Icons.diamond_outlined,
                          size: 28, color: JewelryColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.localizedProductName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'x${widget.order.quantity}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Timeline
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.hourglass_empty,
                              size: 40, color: textSecondary.withAlpha(100)),
                          const SizedBox(height: 8),
                          Text(
                            'logistics_no_info'.tr,
                            style:
                                TextStyle(color: textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(entries.length, (index) {
                      final entry = entries[index];
                      final isFirst = index == 0;
                      final isLast = index == entries.length - 1;

                      return _buildTimelineItem(
                        entry: entry,
                        isFirst: isFirst,
                        isLast: isLast,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build timeline entries - prefer API data, fallback to order status events
  List<LogisticsEntry> _buildEntries() {
    final entries = <LogisticsEntry>[];

    // 优先使用 API 返回的真实物流数据
    if (_apiEntries != null && _apiEntries!.isNotEmpty) {
      entries.addAll(_apiEntries!);
    }

    // Add real logistics entries from order model
    if (widget.order.logisticsEntries != null) {
      entries.addAll(widget.order.logisticsEntries!);
    }

    // Add status-based entries (only when no API data available)
    if (_apiEntries == null || _apiEntries!.isEmpty) {
      if (widget.order.completedAt != null) {
        entries.add(LogisticsEntry(
          description: 'logistics_order_completed'.tr,
          time: widget.order.completedAt!,
        ));
      }
      if (widget.order.deliveredAt != null) {
        entries.add(LogisticsEntry(
          description: 'logistics_signed_by_name'.trArgs({
            'name': widget.order.recipientName ?? 'logistics_self_signed'.tr,
          }),
          time: widget.order.deliveredAt!,
          location: widget.order.shippingAddress,
        ));
      }
      if (widget.order.shippedAt != null) {
        entries.add(LogisticsEntry(
          description: 'logistics_in_transit_company'.trArgs({
            'company': widget.order.logisticsCompany ??
                'logistics_company_fallback'.tr,
          }),
          time: widget.order.shippedAt!,
        ));
      }
      if (widget.order.paidAt != null) {
        entries.add(LogisticsEntry(
          description: 'logistics_order_paid_wait_ship'.tr,
          time: widget.order.paidAt!,
        ));
      }
    }

    entries.add(LogisticsEntry(
      description: 'logistics_order_created'.tr,
      time: widget.order.createdAt,
    ));

    // Sort by time descending (newest first)
    entries.sort((a, b) => b.time.compareTo(a.time));

    // Deduplicate by description
    final seen = <String>{};
    return entries.where((e) => seen.add(e.description)).toList();
  }

  Widget _buildTimelineItem({
    required LogisticsEntry entry,
    required bool isFirst,
    required bool isLast,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final dotColor =
        isFirst ? JewelryColors.primaryGreen : textSecondary.withAlpha(100);
    final lineColor =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: isFirst ? 12 : 8,
                  height: isFirst ? 12 : 8,
                  margin: EdgeInsets.only(top: isFirst ? 4 : 6),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isFirst
                        ? Border.all(
                            color: JewelryColors.primaryGreen.withAlpha(80),
                            width: 3,
                          )
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: TextStyle(
                      fontSize: isFirst ? 14 : 13,
                      fontWeight: isFirst ? FontWeight.w500 : FontWeight.w400,
                      color: isFirst ? textPrimary : textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(entry.time),
                    style: TextStyle(
                        fontSize: 12, color: textSecondary.withAlpha(180)),
                  ),
                  if (entry.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.location!,
                      style: TextStyle(
                          fontSize: 12, color: textSecondary.withAlpha(150)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
