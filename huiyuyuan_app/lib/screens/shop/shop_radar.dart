/// HuiYuYuan shop radar for automated lead discovery.
///
/// Features:
/// - automated platform scouting
/// - smart shop and creator filtering
/// - AI scoring and prioritization
/// - automated outreach workflows
/// - reputation and conversion analysis
library;

import 'package:huiyuyuan/l10n/translator_global.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/ai_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../themes/colors.dart';

/// Shop radar screen.
class ShopRadar extends ConsumerStatefulWidget {
  const ShopRadar({super.key});

  @override
  ConsumerState<ShopRadar> createState() => _ShopRadarState();
}

class _ShopRadarState extends ConsumerState<ShopRadar>
    with SingleTickerProviderStateMixin {
  static const String _allPlatformValue = '__all__';

  bool _isScanning = false;
  int _scannedCount = 0;
  int _qualifiedCount = 0;
  List<ShopModel> _shops = [];
  String _selectedPlatform = _allPlatformValue;

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _loadShops();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  /// Loads shop data from the backend and falls back to an empty list.
  Future<void> _loadShops() async {
    try {
      final api = ApiService();
      final result = await api.get<dynamic>(ApiConfig.shops);
      if (result.success && result.data != null) {
        final data = result.data;
        List<dynamic> items;
        if (data is Map && data['items'] != null) {
          items = data['items'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        } else {
          return;
        }
        if (mounted) {
          setState(() {
            _shops = items
                .map((json) => ShopModel.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[ShopRadar] API 加载店铺失败: $e');
    }
    // Keep the list empty and show the empty state when the API is unavailable.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar.
            _buildHeader(),

            // Radar scan hero.
            _buildRadarSection(),

            // Filter controls.
            _buildFilterBar(),

            // Shop list.
            Expanded(
              child: _buildShopList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.radar, color: JewelryColors.gold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.tr('shop_radar_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ref.tr('shop_radar_subtitle'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Scan action button.
          GestureDetector(
            onTap: _toggleScan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: _isScanning ? null : JewelryColors.primaryGradient,
                color: _isScanning ? Colors.red.withOpacity(0.8) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isScanning ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isScanning
                        ? ref.tr('shop_radar_stop_scan')
                        : ref.tr('shop_radar_start_scan'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildRadarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.primary.withOpacity(0.15),
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
          // Radar animation.
          _buildRadarAnimation(),
          const SizedBox(width: 20),
          // Summary stats.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  ref.tr('shop_radar_scanned'),
                  '$_scannedCount',
                  ref.tr('shop_radar_shops_unit'),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  ref.tr('shop_radar_qualified'),
                  '$_qualifiedCount',
                  ref.tr('shop_radar_shops_unit'),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                    ref.tr('shop_radar_pending_contact'),
                    '${_shops.where((s) => s.contactStatus == ContactStatus.pending).length}',
                    ref.tr('shop_radar_shops_unit')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background rings.
          ...List.generate(
              3,
              (i) => Container(
                    width: 100 - i * 30.0,
                    height: 100 - i * 30.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: JewelryColors.primary.withOpacity(0.3 - i * 0.1),
                      ),
                    ),
                  )),
          // Scanning line.
          if (_isScanning)
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _radarController.value * 6.28,
                  child: Container(
                    width: 50,
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          JewelryColors.primary,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          // Center marker.
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isScanning ? JewelryColors.primary : Colors.grey,
              boxShadow: _isScanning
                  ? [
                      BoxShadow(
                        color: JewelryColors.primary.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String unit) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: JewelryColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final platforms = <String>[
      _allPlatformValue,
      '淘宝',
      '抖音',
      '小红书',
      '快手',
      '京东',
      '拼多多',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: platforms.length,
        itemBuilder: (context, index) {
          final platform = platforms[index];
          final isSelected = _selectedPlatform == platform;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedPlatform = platform);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isSelected ? JewelryColors.primaryGradient : null,
                color: isSelected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              alignment: Alignment.center,
              child: Text(
                _platformLabel(platform),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopList() {
    final filteredShops = _selectedPlatform == _allPlatformValue
        ? _shops
        : _shops.where((s) => s.platform == _selectedPlatform).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredShops.length,
      itemBuilder: (context, index) {
        return _buildShopCard(filteredShops[index]);
      },
    );
  }

  Widget _buildShopCard(ShopModel shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: shop.isQualified
              ? JewelryColors.primary.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row.
          Row(
            children: [
              // Platform badge.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: shop.platformColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _platformLabel(shop.platform),
                  style: TextStyle(
                    color: shop.platformColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (shop.isInfluencer) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: JewelryColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.live_tv, color: JewelryColors.gold, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        ref.tr('shop_radar_influencer'),
                        style: const TextStyle(
                          color: JewelryColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // AI score.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: shop.aiPriority! >= 80
                      ? JewelryColors.primaryGradient
                      : null,
                  color: shop.aiPriority! >= 80
                      ? null
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatAiScore(shop.aiPriority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shop name.
          Text(
            shop.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _shopMainBusinessLabel(shop.category),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Metrics.
          Row(
            children: [
              _buildMetric(ref.tr('shop_radar_rating'), shop.rating.toString()),
              _buildMetric(
                ref.tr('shop_radar_conversion_rate'),
                '${shop.conversionRate}%',
              ),
              _buildMetric(
                ref.tr('shop_radar_followers'),
                _formatNumber(shop.followers),
              ),
              if (shop.monthlySales != null)
                _buildMetric(
                  ref.tr('shop_radar_monthly_sales'),
                  _formatMonthlySales(shop.monthlySales),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Status and actions.
          Row(
            children: [
              // Status chip.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: shop.contactStatus.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _contactStatusLabel(shop.contactStatus),
                  style: TextStyle(
                    color: shop.contactStatus.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Action buttons.
              if (shop.contactStatus == ContactStatus.pending)
                GestureDetector(
                  onTap: () => _contactShop(shop),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: JewelryColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          ref.tr('work_ai_script'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (shop.contactStatus != ContactStatus.pending)
                GestureDetector(
                  onTap: () => _viewShopDetail(shop),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ref.tr('order_view_detail'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static const Map<String, String> _shopCategoryKeyMap = {
    '翡翠玉石': 'shop_category_jadeite_and_jade',
    '和田玉': 'shop_category_hetian_jade',
    '综合珠宝': 'shop_category_multi_category_jewelry',
    '玉石翡翠': 'shop_category_jade_and_jadeite',
    '珠宝鉴定': 'shop_category_jewelry_authentication',
    '翡翠直播': 'shop_category_jadeite_live',
    '珠宝穿搭': 'shop_category_jewelry_styling',
    '玉石分享': 'shop_category_jade_sharing',
    '品牌珠宝': 'shop_category_branded_jewelry',
    '平价玉石': 'shop_category_affordable_jade',
  };

  String _shopMainBusinessLabel(String category) {
    return ref.tr(
      'shop_main_business',
      params: {'category': _shopCategoryLabel(category)},
    );
  }

  String _shopCategoryLabel(String value) {
    final key = _shopCategoryKeyMap[value.trim()];
    if (key == null) {
      return value;
    }
    return ref.tr(key);
  }

  String _contactStatusLabel(ContactStatus status) {
    return ref.tr(status.labelKey);
  }

  String _formatAiScore(int? score) {
    return ref.tr('shop_radar_ai_score', params: {'score': score ?? 0});
  }

  String _formatMonthlySales(int? count) {
    return ref
        .tr('shop_radar_monthly_sales_value', params: {'count': count ?? 0});
  }

  String _platformLabel(String value) {
    switch (value) {
      case _allPlatformValue:
        return ref.tr('platform_all');
      case '淘宝':
        return ref.tr('platform_taobao');
      case '抖音':
        return ref.tr('platform_douyin');
      case '小红书':
        return ref.tr('platform_xiaohongshu');
      case '快手':
        return ref.tr('platform_kuaishou');
      case '京东':
        return ref.tr('platform_jd');
      case '拼多多':
        return ref.tr('platform_pinduoduo');
      default:
        return value;
    }
  }

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 10000) {
      final languageCode = Localizations.localeOf(context).languageCode;
      if (languageCode == 'en') {
        return '${(num / 1000).toStringAsFixed(0)}K';
      }
      if (languageCode == 'zh' &&
          Localizations.localeOf(context).toLanguageTag().contains('TW')) {
        return '${(num / 10000).toStringAsFixed(1)}萬';
      }
      return '${(num / 10000).toStringAsFixed(1)}万';
    }
    return num.toString();
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _radarController.repeat();
        _simulateScan();
      } else {
        _radarController.stop();
      }
    });
  }

  void _simulateScan() async {
    for (int i = 0; i < 10 && _isScanning; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _isScanning) {
        setState(() {
          _scannedCount += 5 + (i % 3);
          if (i % 2 == 0) _qualifiedCount++;
        });
      }
    }
  }

  void _contactShop(ShopModel shop) async {
    showDialog(
      context: context,
      builder: (context) => _AIDialogueDialog(shop: shop),
    );
  }

  void _viewShopDetail(ShopModel shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag handle.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Shop name and platform.
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: JewelryColors.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.store, color: Colors.black87, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: JewelryColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_platformLabel(shop.platform),
                                style: const TextStyle(
                                    color: JewelryColors.primary,
                                    fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: JewelryColors.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_shopCategoryLabel(shop.category),
                                style: const TextStyle(
                                    color: JewelryColors.gold, fontSize: 12)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 20),
              // Key metrics.
              Row(
                children: [
                  _buildDetailStat(
                      ref.tr('shop_radar_rating'),
                      shop.rating.toStringAsFixed(1),
                      Icons.star,
                      JewelryColors.gold),
                  _buildDetailStat(ref.tr('shop_radar_followers'),
                      '${shop.followers}', Icons.people, JewelryColors.primary),
                  _buildDetailStat(
                      ref.tr('shop_radar_conversion_rate'),
                      '${(shop.conversionRate * 100).toStringAsFixed(1)}%',
                      Icons.trending_up,
                      JewelryColors.success),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetailStat(
                      ref.tr('shop_radar_monthly_sales'),
                      _formatMonthlySales(shop.monthlySales),
                      Icons.shopping_cart,
                      const Color(0xFF667eea)),
                  _buildDetailStat(
                      ref.tr('shop_radar_negative_rate'),
                      '${((shop.negativeRate ?? 0) * 100).toStringAsFixed(1)}%',
                      Icons.thumb_down,
                      JewelryColors.error),
                  _buildDetailStat(
                      ref.tr('shop_radar_ai_priority'),
                      '${shop.aiPriority ?? 0}',
                      Icons.auto_awesome,
                      const Color(0xFF8B5CF6)),
                ],
              ),
              const SizedBox(height: 24),
              // Contact status.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref.tr('shop_radar_contact_status'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text(
                      _contactStatusLabel(shop.contactStatus),
                      style: TextStyle(
                        color: shop.contactStatus.name == 'cooperated'
                            ? JewelryColors.success
                            : JewelryColors.gold,
                        fontSize: 14,
                      ),
                    ),
                    if (shop.lastContactAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        ref.tr(
                          'shop_radar_last_contact',
                          params: {
                            'date':
                                shop.lastContactAt!.toString().substring(0, 16),
                          },
                        ),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => _AIDialogueDialog(shop: shop),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(ref.tr('shop_radar_generate_script')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JewelryColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(ref.tr('close')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// AI outreach copy dialog.
class _AIDialogueDialog extends ConsumerStatefulWidget {
  final ShopModel shop;

  const _AIDialogueDialog({required this.shop});

  @override
  ConsumerState<_AIDialogueDialog> createState() => _AIDialogueDialogState();
}

class _AIDialogueDialogState extends ConsumerState<_AIDialogueDialog> {
  final _aiService = AIService();
  String _dialogue = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateDialogue();
  }

  Future<void> _generateDialogue() async {
    final result = await _aiService.generateBusinessDialogue(
      shopName: widget.shop.name,
      category: widget.shop.category,
      rating: widget.shop.rating,
      platform: widget.shop.platform,
      followers: widget.shop.followers,
    );

    if (mounted) {
      setState(() {
        _dialogue = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: JewelryColors.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: JewelryColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ref.tr('shop_radar_ai_dialog_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ref.tr(
                'shop_radar_target_shop',
                params: {'name': widget.shop.name},
              ),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: JewelryColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            TranslatorGlobal.instance
                                .translate('ai_generating_script'),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      _dialogue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (!_isLoading)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateDialogue,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(ref.tr('shop_radar_regenerate')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: JewelryColors.primary,
                        side: const BorderSide(color: JewelryColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: copy and send.
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(ref.tr('shop_radar_copy_and_send')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JewelryColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
