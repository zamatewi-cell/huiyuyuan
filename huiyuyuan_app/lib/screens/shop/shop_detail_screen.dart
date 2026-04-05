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
      backgroundColor: const Color(0xFF0D1B2A),
      body: CustomScrollView(
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
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.primary.withOpacity(0.9),
                  JewelryColors.primaryDark.withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.shop.name,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildShopHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.primary.withOpacity(0.2),
            JewelryColors.gold.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: JewelryColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 店铺头像
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: JewelryColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.store, color: Colors.white, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.shop.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.shop.platformColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.shop.platform,
                            style: TextStyle(
                              color: widget.shop.platformColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.shop.category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: JewelryColors.gold, size: 16),
                        SizedBox(width: 4),
                        Text(
                          widget.shop.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.shop.contactStatus.color
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ref.tr(widget.shop.contactStatus.labelKey),
                            style: TextStyle(
                              color: widget.shop.contactStatus.color,
                              fontSize: 11,
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
          SizedBox(height: 16),
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
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
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
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: JewelryColors.primary,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 评估卡片
          _buildEvaluationCard(),
          SizedBox(height: 16),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JewelryColors.gold.withOpacity(0.15),
            JewelryColors.gold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JewelryColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: JewelryColors.gold),
              SizedBox(width: 8),
              Text(
                ref.tr('shop_detail_ai_report'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_isEvaluating)
            Center(
              child: CircularProgressIndicator(color: JewelryColors.gold),
            )
          else if (_evaluation != null) ...[
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: JewelryColors.gold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_evaluation!['score']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jsonAsString(_evaluation!['decision']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        jsonAsString(_evaluation!['suggestedAction']),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_evaluation!['reasons'] as List<dynamic>? ?? [])
                  .map((reason) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          reason.toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: JewelryColors.primary, size: 20),
          SizedBox(width: 12),
          Text(
            label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    if (_isLoadingContacts) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
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
      margin: EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.add),
        label: Text(ref.tr('shop_detail_add_contact_record')),
        style: ElevatedButton.styleFrom(
          backgroundColor: JewelryColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContactRecordCard(Map<String, String> record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record['action'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                record['date'] ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: JewelryColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              record['result'] ?? '',
              style: const TextStyle(
                color: JewelryColors.primary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            record['note'] ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 话术生成
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: JewelryColors.gold),
                    SizedBox(width: 8),
                    Text(
                      ref.tr('shop_detail_ai_dialogue_title'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (_generatedDialogue != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JewelryColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _generatedDialogue!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateDialogue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JewelryColors.gold,
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isGenerating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
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
          SizedBox(height: 16),
          // 快捷操作
          Text(
            ref.tr('admin_quick_actions'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  Icons.copy,
                  ref.tr('shop_detail_copy_dialogue'),
                  () {
                    if (_generatedDialogue != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ref.tr('shop_detail_dialogue_copied')),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(width: 12),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: JewelryColors.primary),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
