library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuxuryRedesignPreviewScreen extends StatelessWidget {
  const LuxuryRedesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LuxuryPalette.midnight,
      body: Stack(
        children: [
          const _LuxuryBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _PreviewHero(),
                  SizedBox(height: 28),
                  _SectionHeader(
                    eyebrow: 'Component Language',
                    title: 'Premium Jewelry UI System',
                    description:
                        'Hand-drawn Flutter preview boards for the dark emerald '
                        'and champagne gold visual system. This is the manual '
                        'reference we can use before replacing production pages.',
                  ),
                  SizedBox(height: 18),
                  _ComponentBoard(),
                  SizedBox(height: 34),
                  _SectionHeader(
                    eyebrow: 'Screen 01',
                    title: 'Login / Welcome',
                    description:
                        'Luxury onboarding instead of a generic sign-in flow. '
                        'The page needs to feel curated, intimate, and expert.',
                  ),
                  SizedBox(height: 18),
                  _LoginFrames(),
                  SizedBox(height: 34),
                  _SectionHeader(
                    eyebrow: 'Screen 02',
                    title: 'Product Detail',
                    description:
                        'Immersive jewelry storytelling with AI companionship, '
                        'glass content blocks, and high-trust decision support.',
                  ),
                  SizedBox(height: 18),
                  _ProductDetailFrame(),
                  SizedBox(height: 34),
                  _SectionHeader(
                    eyebrow: 'Screen 03',
                    title: 'Admin / Dashboard',
                    description:
                        'A branded jewelry operations workbench, not a template BI panel.',
                  ),
                  SizedBox(height: 18),
                  _AdminFrame(),
                  SizedBox(height: 28),
                  _ImplementationNotes(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero();

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(26),
      radius: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final content = <Widget>[
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PillLabel(
                    label: 'HuiYuYuan / Luxury Jewelry × AI Commerce',
                    tone: _PillTone.neutral,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '汇玉源',
                    style: GoogleFonts.notoSerifSc(
                      fontSize: 58,
                      height: 0.95,
                      fontWeight: FontWeight.w700,
                      color: _LuxuryPalette.ivory,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Luxury Jewelry Redesign',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 42,
                      height: 1.02,
                      fontWeight: FontWeight.w600,
                      color: _LuxuryPalette.champagne,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(
                      '这是一块手工绘制的品牌设计板。重点不是做普通电商模板，'
                      '而是把珠宝顾问、深色电影感和液态玻璃的品牌语言收成一套'
                      '可以直接落 Flutter 的最终视觉基准。',
                      style: _LuxuryType.body.copyWith(
                        color: _LuxuryPalette.mist,
                        height: 1.75,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _PillLabel(
                          label: 'Jade commerce', tone: _PillTone.emerald),
                      _PillLabel(
                          label: 'Liquid glass', tone: _PillTone.neutral),
                      _PillLabel(label: 'AI concierge', tone: _PillTone.gold),
                      _PillLabel(
                          label: 'Dark editorial', tone: _PillTone.neutral),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24, height: 24),
            Expanded(
              flex: 5,
              child: _DarkGlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设计方向',
                      style: _LuxuryType.cardTitle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '1. 背景始终保持深黑绿到深蓝黑的电影感，不走蓝紫 AI 风。\n'
                      '2. 玻璃卡片一律偏深色半透明，不出现白玻璃卡。\n'
                      '3. 珠宝电商不是“卖货热闹”，而是“顾问式成交”。\n'
                      '4. 后台也保留品牌语气，但结构感更克制更专业。',
                      style: _LuxuryType.body.copyWith(
                        color: _LuxuryPalette.mist,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: _LuxuryPalette.strokeSoft),
                    const SizedBox(height: 18),
                    Text(
                      '交付内容',
                      style: _LuxuryType.label.copyWith(
                        color: _LuxuryPalette.champagne,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Components / Login / Product Detail / Admin Dashboard',
                      style: _LuxuryType.body
                          .copyWith(color: _LuxuryPalette.softWhite),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: Row(
                        children: const [
                          Expanded(
                            child: _MiniDirectionCard(
                              index: '01',
                              title: 'Branded onboarding',
                              body: '让登录页像珠宝品牌迎宾，而不是后台门禁。',
                              accent: _LuxuryPalette.emerald,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _MiniDirectionCard(
                              index: '02',
                              title: 'AI concierge',
                              body: '把 AI 做成顾问陪伴，而不是冰冷工具箱。',
                              accent: _LuxuryPalette.goldMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content);
        },
      ),
    );
  }
}

class _ComponentBoard extends StatelessWidget {
  const _ComponentBoard();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: const [
        _BoardTile(
          width: 380,
          child: _ActionComponentPanel(),
        ),
        _BoardTile(
          width: 380,
          child: _FieldComponentPanel(),
        ),
        _BoardTile(
          width: 460,
          child: _CardComponentPanel(),
        ),
      ],
    );
  }
}

class _LoginFrames extends StatelessWidget {
  const _LoginFrames();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FrameWrapper(
            title: 'Mobile / 390 × 844',
            child: _LoginMobileArtboard(),
          ),
          SizedBox(width: 18),
          _FrameWrapper(
            title: 'Desktop / 1440 × 960',
            child: _LoginDesktopArtboard(),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailFrame extends StatelessWidget {
  const _ProductDetailFrame();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: const Row(
        children: [
          _FrameWrapper(
            title: 'Mobile / 390 × 1200',
            child: _ProductDetailArtboard(),
          ),
        ],
      ),
    );
  }
}

class _AdminFrame extends StatelessWidget {
  const _AdminFrame();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: const Row(
        children: [
          _FrameWrapper(
            title: 'Desktop / 1440 × 1024',
            child: _AdminDashboardArtboard(),
          ),
        ],
      ),
    );
  }
}

class _ImplementationNotes extends StatelessWidget {
  const _ImplementationNotes();

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Implementation Notes',
            style: _LuxuryType.heading.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 14),
          Text(
            '这版预览页的目的，是先把视觉语言、材质、组件关系和页面结构定稳。'
            '等你拍板后，我们再把登录页、商品详情页和后台工作台逐步替换成正式 Flutter 代码，'
            '并把这里用到的深色玻璃、金绿按钮、AI 顾问卡和 KPI 模块抽成真正的生产组件。',
            style: _LuxuryType.body.copyWith(
              color: _LuxuryPalette.mist,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: _LuxuryType.label.copyWith(
            color: _LuxuryPalette.emeraldBright,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: _LuxuryType.heading.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            description,
            style: _LuxuryType.body.copyWith(
              color: _LuxuryPalette.mist,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({
    required this.child,
    this.width,
  });

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _DarkGlassCard(
        padding: const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class _ActionComponentPanel extends StatelessWidget {
  const _ActionComponentPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _PanelTitle(title: 'Actions', subtitle: 'Primary / Secondary / Icon'),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _LuxuryButton(
                label: '获取验证码',
                tone: _ButtonTone.emerald,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _LuxuryButton(
                label: '立即购买',
                tone: _ButtonTone.gold,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _LuxuryOutlineButton(label: '密码登录'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _LuxuryOutlineButton(label: '先逛逛'),
            ),
          ],
        ),
        SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _IconCircleButton(icon: Icons.arrow_back_rounded),
            _IconCircleButton(icon: Icons.favorite_border_rounded),
            _IconCircleButton(icon: Icons.share_outlined),
          ],
        ),
      ],
    );
  }
}

class _FieldComponentPanel extends StatelessWidget {
  const _FieldComponentPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _PanelTitle(
            title: 'Fields & Chips',
            subtitle: 'Deep glass inputs with refined tags'),
        SizedBox(height: 18),
        _LuxuryField(
          label: '手机号',
          value: '138 8888 8888',
          trailing: Icons.phone_iphone_rounded,
        ),
        SizedBox(height: 14),
        _LuxuryField(
          label: '验证码',
          value: '2 6 8 8',
          trailing: Icons.shield_outlined,
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PillLabel(label: '和田玉', tone: _PillTone.neutral),
            _PillLabel(label: '收藏推荐', tone: _PillTone.gold),
            _PillLabel(label: 'AI顾问', tone: _PillTone.emerald),
            _PillLabel(label: '现货可发', tone: _PillTone.neutral),
          ],
        ),
      ],
    );
  }
}

class _CardComponentPanel extends StatelessWidget {
  const _CardComponentPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _PanelTitle(
            title: 'Information Cards',
            subtitle: 'AI concierge, KPI, and operational modules'),
        SizedBox(height: 18),
        _AIAssistantMiniCard(),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricMiniCard(
                title: '今日成交额',
                value: '¥268,400',
                accent: _LuxuryPalette.goldMuted,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricMiniCard(
                title: 'AI咨询转化',
                value: '37.8%',
                accent: _LuxuryPalette.emeraldBright,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        _WorkbenchMiniCard(),
      ],
    );
  }
}

class _FrameWrapper extends StatelessWidget {
  const _FrameWrapper({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _LuxuryType.label.copyWith(
            color: _LuxuryPalette.champagne,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _LoginMobileArtboard extends StatelessWidget {
  const _LoginMobileArtboard();

  @override
  Widget build(BuildContext context) {
    return _Artboard(
      width: 390,
      height: 844,
      child: Stack(
        children: [
          const _PageGlow(
            emeraldCenter: Alignment(-0.35, -0.78),
            goldCenter: Alignment(0.9, 0.88),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PillLabel(
                  label: 'HuiYuYuan / Jewelry Concierge',
                  tone: _PillTone.neutral,
                ),
                const SizedBox(height: 28),
                const _AbstractGemCluster(size: 184),
                const SizedBox(height: 28),
                Text(
                  '汇玉源',
                  style: GoogleFonts.notoSerifSc(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: _LuxuryPalette.ivory,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI 珠宝顾问与交易平台',
                  style: _LuxuryType.heading.copyWith(
                    fontSize: 18,
                    color: _LuxuryPalette.champagne,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '甄选、咨询、交易，一处完成',
                  style: _LuxuryType.body.copyWith(
                    color: _LuxuryPalette.mist,
                    height: 1.65,
                  ),
                ),
                const Spacer(),
                _DarkGlassCard(
                  radius: 28,
                  blur: 22,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LuxuryField(
                        label: '手机号',
                        value: '请输入手机号',
                        trailing: Icons.phone_iphone_rounded,
                      ),
                      SizedBox(height: 12),
                      _LuxuryField(
                        label: '验证码',
                        value: '输入 4 位验证码',
                        trailing: Icons.lock_outline_rounded,
                      ),
                      SizedBox(height: 16),
                      _LuxuryButton(
                        label: '获取验证码 / 登录',
                        tone: _ButtonTone.gold,
                        fullWidth: true,
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _LuxuryOutlineButton(label: '密码登录')),
                          SizedBox(width: 10),
                          Expanded(child: _LuxuryOutlineButton(label: '先逛逛')),
                        ],
                      ),
                      SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TrustNote(label: '12家合作店铺'),
                          _TrustNote(label: 'AI智能挑选'),
                          _TrustNote(label: '交易更安心'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginDesktopArtboard extends StatelessWidget {
  const _LoginDesktopArtboard();

  @override
  Widget build(BuildContext context) {
    return _Artboard(
      width: 1440,
      height: 960,
      child: Stack(
        children: [
          const _PageGlow(
            emeraldCenter: Alignment(-0.65, -0.4),
            goldCenter: Alignment(0.82, 0.72),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 40, 44, 40),
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PillLabel(
                        label: 'HuiYuYuan / Luxury Jewelry × AI Concierge',
                        tone: _PillTone.neutral,
                      ),
                      const SizedBox(height: 38),
                      const _AbstractGemCluster(size: 260),
                      const SizedBox(height: 32),
                      Text(
                        '汇玉源',
                        style: GoogleFonts.notoSerifSc(
                          fontSize: 76,
                          height: 0.95,
                          fontWeight: FontWeight.w700,
                          color: _LuxuryPalette.ivory,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'AI 珠宝顾问与交易平台',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: _LuxuryPalette.champagne,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Text(
                          '甄选、咨询、交易，一处完成。'
                          '让初见像品牌迎宾，让决策像一场被认真对待的珠宝咨询。',
                          style: _LuxuryType.body.copyWith(
                            fontSize: 17,
                            color: _LuxuryPalette.mist,
                            height: 1.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  flex: 7,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 470),
                      child: _DarkGlassCard(
                        radius: 34,
                        blur: 24,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _PanelTitle(
                              title: 'Welcome back',
                              subtitle:
                                  'Luxury brand onboarding, not a cold dashboard login.',
                            ),
                            SizedBox(height: 24),
                            _LuxuryField(
                              label: '手机号',
                              value: '请输入手机号',
                              trailing: Icons.phone_iphone_rounded,
                            ),
                            SizedBox(height: 14),
                            _LuxuryField(
                              label: '验证码',
                              value: '输入 4 位验证码',
                              trailing: Icons.lock_outline_rounded,
                            ),
                            SizedBox(height: 18),
                            _LuxuryButton(
                              label: '获取验证码 / 登录',
                              tone: _ButtonTone.gold,
                              fullWidth: true,
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                    child: _LuxuryOutlineButton(label: '密码登录')),
                                SizedBox(width: 12),
                                Expanded(
                                    child: _LuxuryOutlineButton(label: '先逛逛')),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _TrustNote(label: '12家合作店铺')),
                                SizedBox(width: 10),
                                Expanded(child: _TrustNote(label: 'AI智能挑选')),
                                SizedBox(width: 10),
                                Expanded(child: _TrustNote(label: '交易更安心')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailArtboard extends StatelessWidget {
  const _ProductDetailArtboard();

  @override
  Widget build(BuildContext context) {
    return _Artboard(
      width: 390,
      height: 1200,
      child: Stack(
        children: [
          const _PageGlow(
            emeraldCenter: Alignment(-0.55, -0.68),
            goldCenter: Alignment(0.86, 0.45),
          ),
          Column(
            children: [
              SizedBox(
                height: 376,
                child: Stack(
                  children: [
                    const _JewelryHeroShot(),
                    Positioned(
                      top: 18,
                      left: 18,
                      right: 18,
                      child: Row(
                        children: const [
                          _IconCircleButton(icon: Icons.arrow_back_rounded),
                          Spacer(),
                          _IconCircleButton(
                              icon: Icons.favorite_border_rounded),
                          SizedBox(width: 10),
                          _IconCircleButton(icon: Icons.share_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 106),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '凝翠和田玉平安扣项链',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: _LuxuryPalette.softWhite,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PillLabel(label: '和田玉', tone: _PillTone.neutral),
                          _PillLabel(label: '送礼推荐', tone: _PillTone.gold),
                          _PillLabel(label: '现货可发', tone: _PillTone.emerald),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '¥12,800',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: _LuxuryPalette.champagne,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '18K 金扣 · 约 46cm',
                            style: _LuxuryType.body.copyWith(
                              color: _LuxuryPalette.mist,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '库存充足 · 证书齐全 · 支持顾问咨询',
                        style: _LuxuryType.label.copyWith(
                          color: _LuxuryPalette.emeraldBright,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _AIDetailCard(),
                      const SizedBox(height: 16),
                      const _ContentGlassSection(
                        title: '材质与工艺',
                        body: '细腻温润的和田玉料搭配低调 18K 金扣，保留玉石本身的柔和光泽与细密质感。',
                      ),
                      const SizedBox(height: 12),
                      const _ContentGlassSection(
                        title: '寓意与送礼场景',
                        body: '平安扣寓意圆满守护，适合送长辈、伴侣或重要客户，气质端正但不张扬。',
                      ),
                      const SizedBox(height: 12),
                      const _ContentGlassSection(
                        title: '尺寸 / 证书 / 售后',
                        body: '附权威鉴定证书，支持尺寸确认、佩戴建议与售后保养顾问服务。',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '搭配推荐',
                        style: _LuxuryType.cardTitle.copyWith(fontSize: 19),
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(
                        height: 158,
                        child: Row(
                          children: [
                            Expanded(
                              child: _RecommendationMiniCard(
                                title: '羊脂白玉耳钉',
                                price: '¥6,900',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _RecommendationMiniCard(
                                title: '青玉手镯',
                                price: '¥9,600',
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
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: _DarkGlassCard(
              radius: 24,
              blur: 20,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: const [
                  Expanded(
                    child: _LuxuryOutlineButton(
                      label: '收藏',
                      compact: true,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _LuxuryButton(
                      label: '咨询顾问',
                      tone: _ButtonTone.emerald,
                      compact: true,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _LuxuryButton(
                      label: '立即购买',
                      tone: _ButtonTone.gold,
                      compact: true,
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
}

class _AdminDashboardArtboard extends StatelessWidget {
  const _AdminDashboardArtboard();

  @override
  Widget build(BuildContext context) {
    return _Artboard(
      width: 1440,
      height: 1024,
      child: Stack(
        children: [
          const _PageGlow(
            emeraldCenter: Alignment(-0.7, -0.85),
            goldCenter: Alignment(0.88, 0.86),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Row(
              children: [
                const SizedBox(
                  width: 218,
                  child: _AdminSidebar(),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      const _AdminTopBar(),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Expanded(
                            child: _MetricPanel(
                              title: '今日成交额',
                              value: '¥268,400',
                              note: '较昨日 +12.4%',
                              accent: _LuxuryPalette.goldMuted,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _MetricPanel(
                              title: '待确认付款',
                              value: '18',
                              note: '8 单需 2h 内处理',
                              accent: _LuxuryPalette.emeraldBright,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _MetricPanel(
                              title: '待发货订单',
                              value: '26',
                              note: '4 单贵重件优先',
                              accent: _LuxuryPalette.softWhite,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _MetricPanel(
                              title: 'AI咨询转化',
                              value: '37.8%',
                              note: '翡翠类咨询热度上升',
                              accent: _LuxuryPalette.emeraldBright,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Expanded(
                        flex: 10,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _WorkbenchColumn(
                                title: '待处理订单',
                                accent: _LuxuryPalette.emeraldBright,
                                items: [
                                  '高净值客单 ¥18,600 / 和田玉吊坠',
                                  '定制询价待确认 / 翡翠手镯 57 圈口',
                                  '贵重件改址审核 / 珍珠套链礼盒',
                                ],
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: _WorkbenchColumn(
                                title: '付款审核 / 异常提醒',
                                accent: _LuxuryPalette.goldMuted,
                                items: [
                                  '2 笔线下转账需人工复核',
                                  '1 笔争议付款已冻结确认',
                                  '短信通道额度不足预警',
                                ],
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: _WorkbenchColumn(
                                title: '店铺表现 / 低库存预警',
                                accent: _LuxuryPalette.softWhite,
                                items: [
                                  '杭州门店客单价本周第一',
                                  '南红系列浏览转化提升 18%',
                                  '碧玉平安扣库存低于 5 件',
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            Expanded(child: _ActivityTimelineCard()),
                            SizedBox(width: 14),
                            Expanded(child: _InventoryInsightCard()),
                          ],
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
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      radius: 28,
      blur: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PillLabel(label: 'Admin Console', tone: _PillTone.neutral),
          SizedBox(height: 20),
          _SidebarBrand(),
          SizedBox(height: 24),
          _SidebarItem(
              label: '总览', icon: Icons.dashboard_outlined, active: true),
          _SidebarItem(label: '订单工作台', icon: Icons.receipt_long_outlined),
          _SidebarItem(label: '商品与库存', icon: Icons.inventory_2_outlined),
          _SidebarItem(label: '付款审核', icon: Icons.verified_outlined),
          _SidebarItem(label: '店铺表现', icon: Icons.storefront_outlined),
          _SidebarItem(label: 'AI线索', icon: Icons.auto_awesome_outlined),
          Spacer(),
          _DarkGlassCard(
            padding: EdgeInsets.all(14),
            radius: 22,
            blur: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today focus',
                  style: _LuxuryType.label,
                ),
                SizedBox(height: 8),
                Text(
                  '高净值定制单跟进',
                  style: _LuxuryType.cardTitle,
                ),
                SizedBox(height: 6),
                Text(
                  '优先处理两笔线下转账复核与一单贵重件改址审核。',
                  style: _LuxuryType.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DarkGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            radius: 22,
            blur: 16,
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: _LuxuryPalette.mist, size: 18),
                const SizedBox(width: 10),
                Text(
                  '搜索订单、材质、店铺或线索',
                  style: _LuxuryType.body.copyWith(color: _LuxuryPalette.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        const _TopBarCapsule(label: '近 7 日'),
        const SizedBox(width: 10),
        const _TopBarCapsule(label: '通知 12'),
        const SizedBox(width: 10),
        const _AdminAvatar(),
      ],
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.title,
    required this.value,
    required this.note,
    required this.accent,
  });

  final String title;
  final String value;
  final String note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _LuxuryType.label.copyWith(color: _LuxuryPalette.mist),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: _LuxuryType.caption.copyWith(color: _LuxuryPalette.muted),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchColumn extends StatelessWidget {
  const _WorkbenchColumn({
    required this.title,
    required this.accent,
    required this.items,
  });

  final String title;
  final Color accent;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.28),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: _LuxuryType.cardTitle.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items) ...[
            _ListItem(text: item),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ActivityTimelineCard extends StatelessWidget {
  const _ActivityTimelineCard();

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PanelTitle(
            title: '最近交易动态',
            subtitle: '时间轴保留品牌秩序感，而不是普通日志表。',
          ),
          SizedBox(height: 18),
          _TimelineEvent(
              time: '09:20', title: '杭州门店成交和田玉套链', detail: '客单价 ¥28,600'),
          SizedBox(height: 14),
          _TimelineEvent(
              time: '10:05', title: 'AI 顾问推荐转化成功', detail: '翡翠手镯咨询转单'),
          SizedBox(height: 14),
          _TimelineEvent(time: '11:40', title: '高净值客户预约线下看货', detail: '珍珠礼盒系列'),
        ],
      ),
    );
  }
}

class _InventoryInsightCard extends StatelessWidget {
  const _InventoryInsightCard();

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            title: '库存与热销材质',
            subtitle: '小型排行卡与柔性图表，不做喧闹的数据墙。',
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: _MaterialBar(label: '和田玉', value: 0.88),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MaterialBar(label: '翡翠', value: 0.76),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _MaterialBar(label: '南红', value: 0.62),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MaterialBar(label: '珍珠', value: 0.58),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: _LuxuryPalette.strokeSoft),
          const SizedBox(height: 14),
          const _ListItem(text: '低库存预警：碧玉平安扣剩余 4 件'),
          const SizedBox(height: 10),
          const _ListItem(text: '热销材质：翡翠类 7 日成交额上升 21%'),
          const SizedBox(height: 10),
          const _ListItem(text: '礼赠场景：珍珠类咨询在节庆档显著提升'),
        ],
      ),
    );
  }
}

class _AIDetailCard extends StatelessWidget {
  const _AIDetailCard();

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      blur: 22,
      glowColor: _LuxuryPalette.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PanelTitle(
            title: 'AI 顾问',
            subtitle: '问问这件珠宝适合谁，像私人顾问而不是客服机器人。',
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillLabel(label: '适合送长辈吗', tone: _PillTone.neutral),
              _PillLabel(label: '日常佩戴会不会夸张', tone: _PillTone.neutral),
              _PillLabel(label: '同价位还有什么推荐', tone: _PillTone.gold),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentGlassSection extends StatelessWidget {
  const _ContentGlassSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      blur: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _LuxuryType.cardTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: _LuxuryType.body.copyWith(
              color: _LuxuryPalette.mist,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationMiniCard extends StatelessWidget {
  const _RecommendationMiniCard({
    required this.title,
    required this.price,
  });

  final String title;
  final String price;

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      radius: 22,
      blur: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF17242E), Color(0xFF0E151E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.diamond_outlined,
                  color: _LuxuryPalette.champagne,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: _LuxuryType.cardTitle.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: _LuxuryType.label.copyWith(
              color: _LuxuryPalette.champagne,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _LuxuryType.cardTitle,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: _LuxuryType.caption.copyWith(color: _LuxuryPalette.muted),
        ),
      ],
    );
  }
}

class _Artboard extends StatelessWidget {
  const _Artboard({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: _LuxuryPalette.stroke, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 50,
            offset: const Offset(0, 28),
          ),
          BoxShadow(
            color: _LuxuryPalette.emerald.withOpacity(0.1),
            blurRadius: 80,
            offset: const Offset(-18, -12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0B111A),
                    Color(0xFF091319),
                    Color(0xFF0D1420),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              painter: _GrainPainter(),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _DarkGlassCard extends StatelessWidget {
  const _DarkGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.blur = 20,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final glow = glowColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [
                _LuxuryPalette.cardTop.withOpacity(0.92),
                _LuxuryPalette.cardBottom.withOpacity(0.84),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _LuxuryPalette.stroke,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.26),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
              if (glow != null)
                BoxShadow(
                  color: glow.withOpacity(0.14),
                  blurRadius: 26,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.055),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LuxuryButton extends StatelessWidget {
  const _LuxuryButton({
    required this.label,
    required this.tone,
    this.fullWidth = false,
    this.compact = false,
  });

  final String label;
  final _ButtonTone tone;
  final bool fullWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gradient = tone == _ButtonTone.emerald
        ? const LinearGradient(
            colors: [Color(0xFF255A49), Color(0xFF2E8B57), Color(0xFF61B984)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFA57D42), Color(0xFFC8A96B), Color(0xFFE3C992)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final textColor = tone == _ButtonTone.emerald
        ? _LuxuryPalette.softWhite
        : _LuxuryPalette.ink;

    final child = Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 20,
        vertical: compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        boxShadow: [
          BoxShadow(
            color: (tone == _ButtonTone.emerald
                    ? _LuxuryPalette.emerald
                    : _LuxuryPalette.goldMuted)
                .withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: _LuxuryType.button.copyWith(color: textColor),
      ),
    );

    return child;
  }
}

class _LuxuryOutlineButton extends StatelessWidget {
  const _LuxuryOutlineButton({
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 18,
        vertical: compact ? 14 : 15,
      ),
      decoration: BoxDecoration(
        color: _LuxuryPalette.cardMuted,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: _LuxuryPalette.strokeSoft),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: _LuxuryType.button.copyWith(color: _LuxuryPalette.softWhite),
      ),
    );
  }
}

class _LuxuryField extends StatelessWidget {
  const _LuxuryField({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final String value;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: _LuxuryPalette.cardMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LuxuryPalette.strokeSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _LuxuryType.caption.copyWith(
                    color: _LuxuryPalette.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: _LuxuryType.body.copyWith(
                    color: _LuxuryPalette.softWhite,
                  ),
                ),
              ],
            ),
          ),
          Icon(trailing, size: 18, color: _LuxuryPalette.mist),
        ],
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _LuxuryPalette.cardMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LuxuryPalette.strokeSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _LuxuryPalette.emeraldBright,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style:
                _LuxuryType.caption.copyWith(color: _LuxuryPalette.softWhite),
          ),
        ],
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({
    required this.label,
    required this.tone,
  });

  final String label;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final Color edge;
    final Color fill;
    final Color text;
    switch (tone) {
      case _PillTone.emerald:
        edge = _LuxuryPalette.emerald.withOpacity(0.34);
        fill = _LuxuryPalette.emerald.withOpacity(0.12);
        text = _LuxuryPalette.emeraldBright;
        break;
      case _PillTone.gold:
        edge = _LuxuryPalette.goldMuted.withOpacity(0.34);
        fill = _LuxuryPalette.goldMuted.withOpacity(0.12);
        text = _LuxuryPalette.champagne;
        break;
      case _PillTone.neutral:
        edge = _LuxuryPalette.strokeSoft;
        fill = _LuxuryPalette.cardMuted;
        text = _LuxuryPalette.softWhite;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: edge),
      ),
      child: Text(
        label,
        style: _LuxuryType.caption.copyWith(color: text),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(10),
      radius: 999,
      blur: 18,
      child: Icon(
        icon,
        size: 18,
        color: _LuxuryPalette.softWhite,
      ),
    );
  }
}

class _AIAssistantMiniCard extends StatelessWidget {
  const _AIAssistantMiniCard();

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      blur: 22,
      glowColor: _LuxuryPalette.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PanelTitle(
            title: 'AI 顾问卡',
            subtitle: '以顾问语气进入，而不是工具型聊天入口。',
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillLabel(label: '适合送长辈吗', tone: _PillTone.neutral),
              _PillLabel(label: '会不会夸张', tone: _PillTone.neutral),
              _PillLabel(label: '同价位推荐', tone: _PillTone.gold),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  const _MetricMiniCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _LuxuryType.caption.copyWith(color: _LuxuryPalette.muted),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchMiniCard extends StatelessWidget {
  const _WorkbenchMiniCard();

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PanelTitle(
            title: 'Jewelry workbench',
            subtitle: 'Not a table-first admin module.',
          ),
          SizedBox(height: 12),
          _ListItem(text: '待处理订单'),
          SizedBox(height: 10),
          _ListItem(text: '付款审核 / 异常提醒'),
          SizedBox(height: 10),
          _ListItem(text: '低库存预警'),
        ],
      ),
    );
  }
}

class _MiniDirectionCard extends StatelessWidget {
  const _MiniDirectionCard({
    required this.index,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String index;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      blur: 18,
      glowColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: _LuxuryType.cardTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: _LuxuryType.body.copyWith(
              color: _LuxuryPalette.mist,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '汇玉源',
          style: GoogleFonts.notoSerifSc(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _LuxuryPalette.ivory,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Jewelry Operations',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _LuxuryPalette.champagne,
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? _LuxuryPalette.cardMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? _LuxuryPalette.goldMuted.withOpacity(0.45)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? _LuxuryPalette.champagne : _LuxuryPalette.mist,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: _LuxuryType.body.copyWith(
              color: active ? _LuxuryPalette.softWhite : _LuxuryPalette.mist,
            ),
          ),
          if (active) ...[
            const Spacer(),
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: _LuxuryPalette.emeraldBright,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBarCapsule extends StatelessWidget {
  const _TopBarCapsule({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _LuxuryPalette.cardMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _LuxuryPalette.strokeSoft),
      ),
      child: Text(
        label,
        style: _LuxuryType.body.copyWith(color: _LuxuryPalette.softWhite),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF14352B), Color(0xFF1F5B45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _LuxuryPalette.stroke),
      ),
      child: const Icon(
        Icons.admin_panel_settings_outlined,
        color: _LuxuryPalette.softWhite,
        size: 22,
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({
    required this.time,
    required this.title,
    required this.detail,
  });

  final String time;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: _LuxuryPalette.champagne,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 1,
              height: 42,
              color: _LuxuryPalette.strokeSoft,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style:
                    _LuxuryType.label.copyWith(color: _LuxuryPalette.champagne),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: _LuxuryType.cardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style:
                    _LuxuryType.caption.copyWith(color: _LuxuryPalette.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaterialBar extends StatelessWidget {
  const _MaterialBar({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return _DarkGlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _LuxuryType.body.copyWith(color: _LuxuryPalette.softWhite),
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _LuxuryPalette.cardMuted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF28664E),
                      Color(0xFF2E8B57),
                      Color(0xFFC8A96B)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(value * 100).toInt()}%',
            style: _LuxuryType.caption.copyWith(color: _LuxuryPalette.mist),
          ),
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: _LuxuryPalette.emeraldBright,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: _LuxuryType.body.copyWith(
              color: _LuxuryPalette.mist,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _JewelryHeroShot extends StatelessWidget {
  const _JewelryHeroShot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color(0xFF1A352B),
            Color(0xFF101A23),
            Color(0xFF081018),
          ],
          radius: 1.15,
          center: Alignment(-0.12, -0.12),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 68,
            left: 54,
            right: 54,
            bottom: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(120),
                gradient: const RadialGradient(
                  colors: [
                    Color(0x449DFFC8),
                    Color(0x1447A978),
                    Colors.transparent,
                  ],
                  radius: 0.9,
                  center: Alignment.center,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 188,
                    height: 188,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFE8F0E1),
                          Color(0xFF9DBBA6),
                          Color(0xFF1E4137),
                        ],
                        stops: [0.05, 0.35, 1],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _LuxuryPalette.emerald.withOpacity(0.18),
                          blurRadius: 50,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _LuxuryPalette.midnight,
                      border: Border.all(
                        color: _LuxuryPalette.champagne.withOpacity(0.56),
                        width: 2.5,
                      ),
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
}

class _AbstractGemCluster extends StatelessWidget {
  const _AbstractGemCluster({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _LuxuryPalette.emerald.withOpacity(0.34),
                  _LuxuryPalette.emerald.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.24,
            child: Container(
              width: size * 0.64,
              height: size * 0.64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.18),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE8E2D0),
                    Color(0xFFB8C9BB),
                    Color(0xFF29443A)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.26),
                  width: 1.3,
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.52,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE7D4AF), Color(0xFFA67C43)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageGlow extends StatelessWidget {
  const _PageGlow({
    required this.emeraldCenter,
    required this.goldCenter,
  });

  final Alignment emeraldCenter;
  final Alignment goldCenter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _GlowBlob(
          alignment: emeraldCenter,
          color: _LuxuryPalette.emerald,
          size: 360,
        ),
        _GlowBlob(
          alignment: goldCenter,
          color: _LuxuryPalette.goldMuted,
          size: 320,
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.18),
              color.withOpacity(0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryBackdrop extends StatelessWidget {
  const _LuxuryBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF071016),
                Color(0xFF09131D),
                Color(0xFF0B111A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        _GlowBlob(
          alignment: Alignment(-0.88, -0.92),
          color: _LuxuryPalette.emerald,
          size: 520,
        ),
        _GlowBlob(
          alignment: Alignment(0.92, 0.76),
          color: _LuxuryPalette.goldMuted,
          size: 460,
        ),
        _GlowBlob(
          alignment: Alignment(0.16, -0.72),
          color: _LuxuryPalette.emeraldBright,
          size: 300,
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 14) {
      for (double x = 0; x < size.width; x += 14) {
        final seed = math.sin((x + 3) * 12.9898 + (y + 11) * 78.233);
        final opacity = (seed.abs() * 0.035).clamp(0.0, 0.03);
        paint.color = Colors.white.withOpacity(opacity);
        canvas.drawRect(Rect.fromLTWH(x, y, 1.1, 1.1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _ButtonTone { emerald, gold }

enum _PillTone { emerald, gold, neutral }

class _LuxuryPalette {
  static const Color midnight = Color(0xFF090F16);
  static const Color ink = Color(0xFF11151A);
  static const Color softWhite = Color(0xFFF3F0E6);
  static const Color ivory = Color(0xFFF5EFD9);
  static const Color mist = Color(0xFFC2C5C9);
  static const Color muted = Color(0xFF8A9098);
  static const Color emerald = Color(0xFF2E8B57);
  static const Color emeraldBright = Color(0xFF6BCB94);
  static const Color champagne = Color(0xFFE0C68E);
  static const Color goldMuted = Color(0xFFC8A96B);
  static const Color cardTop = Color(0xFF1C2230);
  static const Color cardBottom = Color(0xFF141A24);
  static const Color cardMuted = Color(0xFF151B24);
  static const Color stroke = Color(0x33F1F4FF);
  static const Color strokeSoft = Color(0x22F1F4FF);
}

class _LuxuryType {
  static TextStyle get heading => GoogleFonts.cormorantGaramond(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: _LuxuryPalette.softWhite,
        height: 1.08,
      );

  static TextStyle get cardTitle => GoogleFonts.montserrat(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _LuxuryPalette.softWhite,
        letterSpacing: 0.2,
      );

  static TextStyle get body => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _LuxuryPalette.softWhite,
      );

  static TextStyle get caption => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _LuxuryPalette.muted,
      );

  static TextStyle get label => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _LuxuryPalette.mist,
        letterSpacing: 1.2,
      );

  static TextStyle get button => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );
}
