/// 汇玉源 - 店铺详情页面
///
/// 功能:
/// - 店铺信息展示
/// - 联系记录管理
/// - AI 话术生成
/// - 店铺评估结果
library;

import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../themes/colors.dart';
import '../../models/json_parsing.dart';
import '../../models/user_model.dart';
import '../../services/ai_service.dart';
import '../../services/contact_service.dart';
import '../../widgets/common/glassmorphic_card.dart';

class _ShopDetailBackdrop extends StatelessWidget {
  const _ShopDetailBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          const BoxDecoration(gradient: JewelryColors.jadeDepthGradient),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _ShopDetailGlowOrb(
              size: 340,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            bottom: 120,
            child: _ShopDetailGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.08),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _ShopDetailTracePainter()),
          ),
        ],
      ),
    );
  }
}

class _ShopDetailGlowOrb extends StatelessWidget {
  const _ShopDetailGlowOrb({
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
          BoxShadow(color: color, blurRadius: 100, spreadRadius: 30),
        ],
      ),
    );
  }
}

class _ShopDetailTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.1 + i * 0.13);
      final path = Path()..moveTo(-24, y);
      path.cubicTo(
        size.width * 0.2,
        y - 30,
        size.width * 0.72,
        y + 34,
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShopDetailTracePainter oldDelegate) => false;
}

class ShopDetailScreen extends ConsumerStatefulWidget {
  final ShopModel shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _evaluation;
  bool _isEvaluating = false;
  String? _generatedDialogue;
  bool _isGenerating = false;

  List<Map<String, String>> _contactRecords = [];
  bool _isLoadingContacts = true;
  final ContactService _contactService = ContactService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvaluation();
    _loadContacts();
  }

  /// 从 ContactService 加载联系记录
  Future<void> _loadContacts() async {
    final records = await _contactService.getShopContacts(widget.shop.id);
    if (mounted) {
      setState(() {
        _contactRecords = records
            .map((r) => {
                  'date': r.date,
                  'action': r.action,
                  'result': r.result,
                  'note': r.note ?? '',
                })
            .toList();
        _isLoadingContacts = false;
      });
    }
  }

  Future<void> _loadEvaluation() async {
    setState(() => _isEvaluating = true);

    final aiService = AIService();
    final result = await aiService.evaluateShop(
      shopName: widget.shop.name,
      rating: widget.shop.rating,
      conversionRate: 5.0, // 模拟转化率
      followers: 50000, // 模拟粉丝数
      negativeRate: 0.015,
    );

    if (mounted) {
      setState(() {
        _evaluation = result;
        _isEvaluating = false;
      });
    }
  }

  Future<void> _generateDialogue() async {
    setState(() => _isGenerating = true);

    final aiService = AIService();
    final dialogue = await aiService.generateBusinessDialogue(
      shopName: widget.shop.name,
      category: widget.shop.category,
      rating: widget.shop.rating,
    );

    if (mounted) {
      setState(() {
        _generatedDialogue = dialogue;
        _isGenerating = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      body: Stack(
        children: [
          const Positioned.fill(child: _ShopDetailBackdrop()),
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildShopHeader()),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(),
                    _buildContactTab(),
                    _buildAITab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle get _titleStyle => const TextStyle(
        color: JewelryColors.jadeMist,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      );

  TextStyle get _bodyStyle => TextStyle(
        color: JewelryColors.jadeMist.withOpacity(0.66),
        fontSize: 13,
        height: 1.45,
      );

  Widget _pill({
    required Widget child,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: child,
    );
  }

  Widget _glassSection({required Widget child}) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      blur: 16,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.12),
      child: child,
    );
  }

  Widget _glassDivider() {
    return Divider(
      height: 1,
      color: JewelryColors.champagneGold.withOpacity(0.1),
    );
  }

  void _showStyledSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: JewelryColors.emeraldShadow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: JewelryColors.jadeBlack.withOpacity(0.88),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.jadeBlack.withOpacity(0.72),
                  JewelryColors.deepJade.withOpacity(0.72),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: JewelryColors.jadeMist),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: JewelryColors.deepJade.withOpacity(0.62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.14),
          ),
        ),
        child: Text(
          widget.shop.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: JewelryColors.jadeMist),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: JewelryColors.jadeMist),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildShopHeader() {
    return GlassmorphicCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      borderRadius: 28,
      blur: 18,
      opacity: 0.2,
      borderColor: JewelryColors.emeraldGlow.withOpacity(0.18),
      child: Column(
        children: [
          Row(
            children: [
              // 店铺头像
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: JewelryColors.champagneGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: JewelryColors.champagneGold.withOpacity(0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.store,
                  color: JewelryColors.jadeBlack,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.shop.name,
                          style: const TextStyle(
                            color: JewelryColors.jadeMist,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _pill(
                          color: widget.shop.platformColor,
                          child: Text(
                            widget.shop.platform,
                            style: TextStyle(
                              color: widget.shop.platformColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.shop.category,
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.62),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: JewelryColors.champagneGold,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.shop.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: JewelryColors.jadeMist,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _pill(
                          color: widget.shop.contactStatus.color,
                          child: Text(
                            ref.tr(widget.shop.contactStatus.labelKey),
                            style: TextStyle(
                              color: widget.shop.contactStatus.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 数据统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                ref.tr('shop_detail_month_sales'),
                '${(widget.shop.rating * 1000).toInt()}+',
              ),
              _buildDivider(),
              _buildStatItem(
                ref.tr('shop_detail_followers'),
                ref.tr('shop_detail_followers_value'),
              ),
              _buildDivider(),
              _buildStatItem(ref.tr('shop_detail_conversion_rate'), '5.3%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: JewelryColors.champagneGold,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: JewelryColors.champagneGold.withOpacity(0.12),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: JewelryColors.jadeBlack.withOpacity(0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.12),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: JewelryColors.emeraldGlow,
        indicatorWeight: 3,
        labelColor: JewelryColors.emeraldGlow,
        unselectedLabelColor: JewelryColors.jadeMist.withOpacity(0.52),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: ref.tr('shop_detail_info_tab')),
          Tab(text: ref.tr('shop_detail_contacts_tab')),
          Tab(text: ref.tr('nav_ai')),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 评估卡片
          _buildEvaluationCard(),
          const SizedBox(height: 16),
          // 基本信息
          _buildInfoSection(ref.tr('shop_detail_basic_info'), [
            _buildInfoRow(
              Icons.category,
              ref.tr('shop_detail_main_category'),
              widget.shop.category,
            ),
            _buildInfoRow(
              Icons.shopping_bag,
              ref.tr('shop_detail_platform'),
              widget.shop.platform,
            ),
            _buildInfoRow(
              Icons.star,
              ref.tr('shop_detail_rating'),
              widget.shop.rating.toStringAsFixed(1),
            ),
            _buildInfoRow(
              Icons.phone,
              ref.tr('shop_detail_phone'),
              ref.tr('shop_detail_unavailable'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      blur: 16,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: JewelryColors.champagneGold,
              ),
              const SizedBox(width: 8),
              Text(
                ref.tr('shop_detail_ai_report'),
                style: _titleStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEvaluating)
            const Center(
              child: CircularProgressIndicator(
                color: JewelryColors.champagneGold,
              ),
            )
          else if (_evaluation != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: JewelryColors.champagneGold.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: JewelryColors.champagneGold.withOpacity(0.24),
                    ),
                  ),
                  child: Text(
                    '${_evaluation!['score']}',
                    style: const TextStyle(
                      color: JewelryColors.champagneGold,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jsonAsString(_evaluation!['decision']),
                        style: const TextStyle(
                          color: JewelryColors.jadeMist,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jsonAsString(_evaluation!['suggestedAction']),
                        style: TextStyle(
                          color: JewelryColors.jadeMist.withOpacity(0.62),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_evaluation!['reasons'] as List<dynamic>? ?? [])
                  .map((reason) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: JewelryColors.jadeBlack.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          reason.toString(),
                          style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.78),
                            fontSize: 11,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return _glassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _titleStyle,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) _glassDivider(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: JewelryColors.emeraldGlow, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.62),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    if (_isLoadingContacts) {
      return const Center(
        child: CircularProgressIndicator(color: JewelryColors.emeraldGlow),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contactRecords.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAddRecordButton();
        }
        return _buildContactRecordCard(_contactRecords[index - 1]);
      },
    );
  }

  Widget _buildAddRecordButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: Text(ref.tr('shop_detail_add_contact_record')),
        style: ElevatedButton.styleFrom(
          backgroundColor: JewelryColors.emeraldLuster,
          foregroundColor: JewelryColors.jadeBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildContactRecordCard(Map<String, String> record) {
    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      blur: 16,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record['action'] ?? '',
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                record['date'] ?? '',
                style: TextStyle(
                  color: JewelryColors.jadeMist.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: JewelryColors.emeraldGlow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: JewelryColors.emeraldGlow.withOpacity(0.2),
              ),
            ),
            child: Text(
              record['result'] ?? '',
              style: const TextStyle(
                color: JewelryColors.emeraldGlow,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            record['note'] ?? '',
            style: _bodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildAITab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 话术生成
          _glassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: JewelryColors.champagneGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ref.tr('shop_detail_ai_dialogue_title'),
                      style: _titleStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_generatedDialogue != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JewelryColors.jadeBlack.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: JewelryColors.champagneGold.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      _generatedDialogue!,
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.86),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateDialogue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JewelryColors.champagneGold,
                      foregroundColor: JewelryColors.jadeBlack,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: JewelryColors.jadeBlack,
                            ),
                          )
                        : Text(
                            _generatedDialogue == null
                                ? ref.tr('shop_detail_generate_dialogue')
                                : ref.tr('shop_detail_regenerate_dialogue'),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 快捷操作
          Text(
            ref.tr('admin_quick_actions'),
            style: _titleStyle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  Icons.copy,
                  ref.tr('shop_detail_copy_dialogue'),
                  () {
                    if (_generatedDialogue != null) {
                      _showStyledSnackBar(
                        ref.tr('shop_detail_dialogue_copied'),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  Icons.share,
                  ref.tr('shop_detail_share_shop'),
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      blur: 14,
      opacity: 0.16,
      borderColor: JewelryColors.champagneGold.withOpacity(0.12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: JewelryColors.emeraldGlow),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.72),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
