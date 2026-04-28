import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/json_parsing.dart';
import '../../models/order_model.dart';
import '../../themes/colors.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/common/resilient_network_image.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

class _LogisticsBackdrop extends StatelessWidget {
  const _LogisticsBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -120,
            child: _LogisticsGlowOrb(
              size: 320,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            bottom: 130,
            child: _LogisticsGlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _LogisticsTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogisticsGlowOrb extends StatelessWidget {
  const _LogisticsGlowOrb({
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
            blurRadius: 96,
            spreadRadius: 28,
          ),
        ],
      ),
    );
  }
}

class _LogisticsTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = JewelryColors.champagneGold.withOpacity(0.04);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.12 + i * 0.13);
      final path = Path()..moveTo(-24, y);
      path.quadraticBezierTo(
        size.width * 0.52,
        y + (i.isEven ? 34 : -30),
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogisticsTracePainter oldDelegate) => false;
}

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
    const textPrimary = JewelryColors.jadeMist;
    final textSecondary = JewelryColors.jadeMist.withOpacity(0.62);

    final entries = _buildEntries();

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: AppBar(
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
            'logistics_title'.tr,
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.84),
        foregroundColor: JewelryColors.jadeMist,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _LogisticsBackdrop()),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tracking info card
              GlassmorphicCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 24,
                blur: 16,
                opacity: 0.18,
                borderColor: JewelryColors.champagneGold.withOpacity(0.14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          color: JewelryColors.emeraldGlow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.logisticsCompany ??
                                'logistics_company_fallback'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.order.status.color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color:
                                  widget.order.status.color.withOpacity(0.22),
                            ),
                          ),
                          child: Text(
                            widget.order.status.localizedLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.order.status.color,
                              fontWeight: FontWeight.w800,
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
                            style:
                                TextStyle(fontSize: 13, color: textSecondary),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(
                                ClipboardData(
                                    text: widget.order.trackingNumber!),
                              );
                              if (!mounted) {
                                return;
                              }
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text('logistics_copy_success'.tr)),
                              );
                            },
                            child: const Icon(
                              Icons.copy,
                              size: 14,
                              color: JewelryColors.emeraldGlow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Product info card
              GlassmorphicCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 24,
                blur: 16,
                opacity: 0.18,
                borderColor: JewelryColors.champagneGold.withOpacity(0.14),
                child: Row(
                  children: [
                    // Product image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: JewelryColors.deepJade.withOpacity(0.58),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: JewelryColors.champagneGold.withOpacity(0.12),
                        ),
                      ),
                      child: widget.order.productImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ResilientNetworkImage(
                                imageUrl: _resolveImageUrl(
                                  widget.order.productImage!,
                                ),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorWidget: const Icon(
                                  Icons.diamond_outlined,
                                  size: 28,
                                  color: JewelryColors.emeraldGlow,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.diamond_outlined,
                              size: 28,
                              color: JewelryColors.emeraldGlow,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.order.localizedProductName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'x${widget.order.quantity}',
                            style:
                                TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Timeline
              GlassmorphicCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 24,
                blur: 16,
                opacity: 0.18,
                borderColor: JewelryColors.champagneGold.withOpacity(0.14),
                child: entries.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.hourglass_empty,
                                  size: 40,
                                  color:
                                      JewelryColors.jadeMist.withOpacity(0.28)),
                              const SizedBox(height: 8),
                              Text(
                                'logistics_no_info'.tr,
                                style: TextStyle(
                                    color: textSecondary, fontSize: 14),
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
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          );
                        }),
                      ),
              ),
            ],
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
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final dotColor =
        isFirst ? JewelryColors.emeraldGlow : JewelryColors.champagneGold;
    final lineColor = JewelryColors.champagneGold.withOpacity(0.14);

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
                            color: JewelryColors.emeraldGlow.withOpacity(0.26),
                            width: 3,
                          )
                        : null,
                    boxShadow: isFirst
                        ? [
                            BoxShadow(
                              color:
                                  JewelryColors.emeraldGlow.withOpacity(0.24),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ]
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
                      fontWeight: isFirst ? FontWeight.w900 : FontWeight.w600,
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

String _resolveImageUrl(String rawUrl) {
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  if (rawUrl.startsWith('/')) {
    return '${ApiConfig.apiUrl}$rawUrl';
  }
  return rawUrl;
}
