/// 汇玉源 - 店铺雷达（自动获客系统）
///
/// 功能:
/// - 自动巡视电商平台
/// - 店铺/达人智能筛选
/// - AI评估与优先级排序
/// - 自动触达与沟通
/// - 口碑和成交率分析
library;

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/ai_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../themes/colors.dart';

/// 店铺雷达页面
class ShopRadar extends StatefulWidget {
  const ShopRadar({super.key});

  @override
  State<ShopRadar> createState() => _ShopRadarState();
}

class _ShopRadarState extends State<ShopRadar>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  int _scannedCount = 0;
  int _qualifiedCount = 0;
  List<ShopModel> _shops = [];
  String _selectedPlatform = '全部';

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

  /// 从后端加载店铺数据，失败时保持空列表
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
                .map((json) =>
                    ShopModel.fromJson(json as Map<String, dynamic>))
                .toList();
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[ShopRadar] API 加载店铺失败: $e');
    }
    // API 不可用时保持空列表，展示空状态
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏
            _buildHeader(),

            // 雷达扫描区
            _buildRadarSection(),

            // 筛选条件
            _buildFilterBar(),

            // 店铺列表
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
                const Text(
                  '店铺雷达',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '智能巡视 · 精准获客',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 扫描按钮
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
                    _isScanning ? '停止扫描' : '开始扫描',
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
          // 雷达动画
          _buildRadarAnimation(),
          const SizedBox(width: 20),
          // 统计数据
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('已扫描', '$_scannedCount', '家店铺'),
                const SizedBox(height: 12),
                _buildStatRow('符合条件', '$_qualifiedCount', '家店铺'),
                const SizedBox(height: 12),
                _buildStatRow(
                    '待联系',
                    '${_shops.where((s) => s.contactStatus == ContactStatus.pending).length}',
                    '家店铺'),
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
          // 背景圆环
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
          // 扫描线
          if (_isScanning)
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _radarController.value * 6.28,
                  child: Container(
                    width: 50,
                    height: 2,
                    decoration: BoxDecoration(
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
          // 中心点
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
    final platforms = ['全部', '淘宝', '抖音', '小红书', '快手'];

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
                platform,
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
    final filteredShops = _selectedPlatform == '全部'
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
          // 头部
          Row(
            children: [
              // 平台标识
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: shop.platformColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  shop.platform,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: JewelryColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.live_tv, color: JewelryColors.gold, size: 12),
                      SizedBox(width: 4),
                      Text(
                        '达人',
                        style: TextStyle(
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
              // AI评分
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  'AI ${shop.aiPriority}分',
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

          // 店铺名称
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
            '主营: ${shop.category}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // 数据指标
          Row(
            children: [
              _buildMetric('评分', shop.rating.toString()),
              _buildMetric('转化率', '${shop.conversionRate}%'),
              _buildMetric('粉丝', _formatNumber(shop.followers)),
              if (shop.monthlySales != null)
                _buildMetric('月销', '${shop.monthlySales}单'),
            ],
          ),
          const SizedBox(height: 16),

          // 状态和操作
          Row(
            children: [
              // 状态标签
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: shop.contactStatus.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  shop.contactStatus.label,
                  style: TextStyle(
                    color: shop.contactStatus.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // 操作按钮
              if (shop.contactStatus == ContactStatus.pending)
                GestureDetector(
                  onTap: () => _contactShop(shop),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: JewelryColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'AI话术',
                          style: TextStyle(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '查看详情',
                      style: TextStyle(
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
              // \u62D6\u62FD\u624B\u67C4
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // \u5E97\u94FA\u540D\u79F0 + \u5E73\u53F0
              Row(
                children: [
                  Container(
                    width: 56, height: 56,
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
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: JewelryColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(shop.platform,
                              style: const TextStyle(color: JewelryColors.primary, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: JewelryColors.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(shop.category,
                              style: const TextStyle(color: JewelryColors.gold, fontSize: 12)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // \u6838\u5FC3\u6307\u6807
              Row(
                children: [
                  _buildDetailStat('\u8BC4\u5206', shop.rating.toStringAsFixed(1), Icons.star, JewelryColors.gold),
                  _buildDetailStat('\u7C89\u4E1D', '${shop.followers}', Icons.people, JewelryColors.primary),
                  _buildDetailStat('\u8F6C\u5316\u7387', '${(shop.conversionRate * 100).toStringAsFixed(1)}%', Icons.trending_up, JewelryColors.success),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetailStat('\u6708\u9500', '${shop.monthlySales ?? 0}', Icons.shopping_cart, const Color(0xFF667eea)),
                  _buildDetailStat('\u5DEE\u8BC4\u7387', '${((shop.negativeRate ?? 0) * 100).toStringAsFixed(1)}%', Icons.thumb_down, JewelryColors.error),
                  _buildDetailStat('AI\u4F18\u5148\u7EA7', '${shop.aiPriority ?? 0}', Icons.auto_awesome, const Color(0xFF8B5CF6)),
                ],
              ),
              const SizedBox(height: 24),
              // \u8054\u7CFB\u72B6\u6001
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
                    const Text('\u8054\u7CFB\u72B6\u6001',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text(
                      shop.contactStatus.name == 'pending' ? '\u5F85\u8054\u7CFB'
                        : shop.contactStatus.name == 'contacted' ? '\u5DF2\u8054\u7CFB'
                        : shop.contactStatus.name == 'interested' ? '\u6709\u610F\u5411'
                        : shop.contactStatus.name == 'cooperating' ? '\u5408\u4F5C\u4E2D'
                        : '\u5DF2\u62D2\u7EDD',
                      style: TextStyle(
                        color: shop.contactStatus.name == 'cooperating' ? JewelryColors.success : JewelryColors.gold,
                        fontSize: 14,
                      ),
                    ),
                    if (shop.lastContactAt != null) ...[
                      const SizedBox(height: 6),
                      Text('\u4E0A\u6B21\u8054\u7CFB: ${shop.lastContactAt!.toString().substring(0, 16)}',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // \u64CD\u4F5C\u6309\u94AE
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
                      label: const Text('AI\u751F\u6210\u8BDD\u672F'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JewelryColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('\u5173\u95ED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildDetailStat(String label, String value, IconData icon, Color color) {
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
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// AI话术生成对话框
class _AIDialogueDialog extends StatefulWidget {
  final ShopModel shop;

  const _AIDialogueDialog({required this.shop});

  @override
  State<_AIDialogueDialog> createState() => _AIDialogueDialogState();
}

class _AIDialogueDialogState extends State<_AIDialogueDialog> {
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
                const Expanded(
                  child: Text(
                    'AI商务话术',
                    style: TextStyle(
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
              '目标店铺: ${widget.shop.name}',
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
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: JewelryColors.primary,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'AI正在生成话术...',
                            style: TextStyle(color: Colors.white54),
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
                      label: const Text('重新生成'),
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
                        // TODO: 复制并发送
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('复制发送'),
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
