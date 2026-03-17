import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../themes/colors.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

/// Logistics tracking timeline screen
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

  /// ���ԴӺ�� API ��ȡ��ʵ������Ϣ
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
                .map((j) => LogisticsEntry(
                      description: j['description'] ?? '',
                      time: DateTime.tryParse(j['time'] ?? '') ?? DateTime.now(),
                      location: j['location'],
                    ))
                .toList();
          });
        }
      }
    } catch (_) {
      // API ������ʱ��Ĭ������ʹ�ö��������״̬����
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? JewelryColors.darkBackground : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6B7280);

    final entries = _buildEntries();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('\u7269\u6D41\u8DDF\u8E2A'), // Logistics Tracking
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
                    Icon(
                      Icons.local_shipping_outlined,
                      color: JewelryColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.order.logisticsCompany ?? '\u5FEB\u9012\u516C\u53F8', // Carrier
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.order.status.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.order.status.label,
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
                        '\u5355\u53F7: ${widget.order.trackingNumber}', // Tracking #
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // Copy tracking number
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('\u5DF2\u590D\u5236\u5FEB\u9012\u5355\u53F7')), // Copied
                          );
                        },
                        child: Icon(Icons.copy, size: 14, color: JewelryColors.primaryGreen),
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
                    color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.order.productImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.order.productImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.diamond_outlined, size: 28, color: JewelryColors.primaryGreen),
                          ),
                        )
                      : const Icon(Icons.diamond_outlined, size: 28, color: JewelryColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.productName,
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
                        '\u00D7${widget.order.quantity}',
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
                          Icon(Icons.hourglass_empty, size: 40, color: textSecondary.withAlpha(100)),
                          const SizedBox(height: 8),
                          Text(
                            '\u6682\u65E0\u7269\u6D41\u4FE1\u606F', // No data
                            style: TextStyle(color: textSecondary, fontSize: 14),
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

  /// Build timeline entries �� prefer API data, fallback to order status events
  List<LogisticsEntry> _buildEntries() {
    final entries = <LogisticsEntry>[];

    // ����ʹ�� API ���ص���ʵ��������
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
          description: '\u8BA2\u5355\u5DF2\u5B8C\u6210\uFF0C\u611F\u8C22\u60A8\u7684\u8D2D\u4E70',
          time: widget.order.completedAt!,
        ));
      }
      if (widget.order.deliveredAt != null) {
        entries.add(LogisticsEntry(
          description: '\u5DF2\u7B7E\u6536\uFF0C\u7B7E\u6536\u4EBA: ${widget.order.recipientName ?? "\u672C\u4EBA"}',
          time: widget.order.deliveredAt!,
          location: widget.order.shippingAddress,
        ));
      }
      if (widget.order.shippedAt != null) {
        entries.add(LogisticsEntry(
          description: '\u5546\u5BB6\u5DF2\u53D1\u8D27\uFF0C${widget.order.logisticsCompany ?? "\u5FEB\u9012"}\u8FD0\u9001\u4E2D',
          time: widget.order.shippedAt!,
        ));
      }
      if (widget.order.paidAt != null) {
        entries.add(LogisticsEntry(
          description: '\u8BA2\u5355\u5DF2\u652F\u4ED8\uFF0C\u7B49\u5F85\u5546\u5BB6\u53D1\u8D27',
          time: widget.order.paidAt!,
        ));
      }
    }

    entries.add(LogisticsEntry(
      description: '\u8BA2\u5355\u5DF2\u521B\u5EFA',
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
    final dotColor = isFirst ? JewelryColors.primaryGreen : textSecondary.withAlpha(100);
    final lineColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB);

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
                    style: TextStyle(fontSize: 12, color: textSecondary.withAlpha(180)),
                  ),
                  if (entry.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.location!,
                      style: TextStyle(fontSize: 12, color: textSecondary.withAlpha(150)),
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
