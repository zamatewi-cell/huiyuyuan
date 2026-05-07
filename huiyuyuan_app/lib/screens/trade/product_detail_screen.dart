import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import '../../themes/colors.dart';
import '../../widgets/image/product_image_view.dart';
import '../../widgets/product_reviews_widget.dart';
import '../chat/ai_assistant_screen.dart';
import 'checkout_screen.dart';

class _ProductDetailBackdrop extends StatelessWidget {
  const _ProductDetailBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            right: -130,
            child: _DetailGlowOrb(
              size: 340,
              color: JewelryColors.primary.withOpacity(0.18),
            ),
          ),
          Positioned(
            left: -120,
            top: 360,
            child: _DetailGlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.11),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DetailBackdropPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGlowOrb extends StatelessWidget {
  const _DetailGlowOrb({
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
            spreadRadius: 34,
          ),
        ],
      ),
    );
  }
}

class _DetailBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.8
      ..color = JewelryColors.champagneGold.withOpacity(0.03);

    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.1 + i * 0.11);
      final path = Path()..moveTo(-24, y);
      for (var x = -24.0; x < size.width + 24; x += 42) {
        path.lineTo(x, y + ((x / size.width) - 0.5) * (i.isEven ? 12 : -12));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DetailBackdropPainter oldDelegate) => false;
}

class _DetailGlassPanel extends StatelessWidget {
  const _DetailGlassPanel({
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          margin: margin,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: JewelryColors.liquidGlassGradient,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.14),
            ),
            boxShadow: JewelryShadows.liquidGlass,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: JewelryColors.champagneGold),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// Product detail screen.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with TickerProviderStateMixin {
  final _storage = StorageService();
  final _aiService = AIService();
  final _pageController = PageController();
  bool _isFavorite = false;
  bool _isGeneratingDesc = false;
  String? _aiDescription;
  int _currentImagePage = 0;
  int _quantity = 1;

  // Entry animations.
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkFavorite();

    // Initialize entry animations.
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start the entry animations after the first frame settles.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  Future<void> _checkFavorite() async {
    final isFav = await _storage.isFavorite(widget.product.id);
    setState(() => _isFavorite = isFav);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(appSettingsProvider).language;
    final localizedTitle = widget.product.localizedTitleFor(currentLanguage);
    final localizedDescription =
        widget.product.localizedDescriptionFor(currentLanguage);
    final localizedMaterial =
        widget.product.localizedMaterialFor(currentLanguage);
    final localizedCategory =
        widget.product.localizedCategoryFor(currentLanguage);
    final localizedOrigin = widget.product.localizedOriginFor(currentLanguage);
    final appraisalNote =
        widget.product.localizedAppraisalNoteFor(currentLanguage)?.trim();
    final craftHighlightItems =
        widget.product.localizedCraftHighlightsFor(currentLanguage);
    final audienceTags = widget.product.localizedAudienceTagsFor(
      currentLanguage,
    );
    final originStory =
        widget.product.localizedOriginStoryFor(currentLanguage)?.trim();
    final flawNotes = widget.product.localizedFlawNotesFor(currentLanguage);
    final certificateAuthority = widget.product
        .localizedCertificateAuthorityFor(currentLanguage)
        ?.trim();
    final certificateImageUrl = widget.product.certificateImageUrl?.trim();
    final certificateVerifyUrl = widget.product.certificateVerifyUrl?.trim();
    final galleryDetail = _cleanDossierItems(widget.product.galleryDetail);
    final galleryHand = _cleanDossierItems(widget.product.galleryHand);

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      body: Stack(
        children: [
          const _ProductDetailBackdrop(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero image gallery.
              SliverAppBar(
                expandedHeight: 430,
                pinned: true,
                stretch: true,
                foregroundColor: JewelryColors.jadeMist,
                backgroundColor: JewelryColors.deepJade.withOpacity(0.82),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'product_image_${widget.product.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.product.images.isNotEmpty
                            ? PageView.builder(
                                controller: _pageController,
                                itemCount: widget.product.images.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImagePage = index);
                                },
                                itemBuilder: (context, index) {
                                  return ProductImageView(
                                    product: widget.product,
                                    imageUrl: widget.product.images[index],
                                    memCacheWidth: 900,
                                  );
                                },
                              )
                            : ProductImageView(
                                product: widget.product,
                                memCacheWidth: 900,
                              ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.transparent,
                                JewelryColors.jadeBlack.withOpacity(0.86),
                              ],
                              stops: const [0.0, 0.46, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 26,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: JewelryColors.deepJade.withOpacity(
                                    0.68,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: JewelryColors.champagneGold
                                        .withOpacity(0.18),
                                  ),
                                ),
                                child: Text(
                                  localizedMaterial,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: JewelryColors.champagneGold
                                        .withOpacity(0.92),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              if (widget.product.images.length > 1) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: List.generate(
                                    widget.product.images.length,
                                    (index) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.only(right: 6),
                                      width:
                                          _currentImagePage == index ? 26 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: _currentImagePage == index
                                            ? JewelryColors.champagneGold
                                            : Colors.white.withOpacity(0.42),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  _buildTopGlassButton(
                    icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite
                        ? JewelryColors.nanHong
                        : JewelryColors.jadeMist,
                    onTap: _toggleFavorite,
                  ),
                  const SizedBox(width: 8),
                  _buildTopGlassButton(
                    icon: Icons.ios_share,
                    color: JewelryColors.jadeMist,
                    onTap: () => _showShareSheet(),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price and badges.
                          _DetailGlassPanel(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '¥${widget.product.price.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        color: JewelryColors.champagneGold,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (widget.product.originalPrice != null)
                                      Text(
                                        '¥${widget.product.originalPrice!.toInt()}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: JewelryColors.jadeMist
                                              .withOpacity(0.36),
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: JewelryColors.primary
                                            .withOpacity(0.14),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: JewelryColors.emeraldGlow
                                              .withOpacity(0.18),
                                        ),
                                      ),
                                      child: Text(
                                        ref.tr(
                                          'admin_sold_inline',
                                          params: {
                                            'count': widget.product.salesCount
                                                .toString(),
                                          },
                                        ),
                                        style: const TextStyle(
                                          color: JewelryColors.emeraldGlow,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  localizedTitle,
                                  style: const TextStyle(
                                    color: JewelryColors.jadeMist,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (widget.product.isHot)
                                      _buildTag(
                                        ref.tr('product_hot'),
                                        JewelryColors.nanHong,
                                      ),
                                    if (widget.product.isNew)
                                      _buildTag(
                                        ref.tr('product_new'),
                                        JewelryColors.champagneGold,
                                      ),
                                    _buildTag(
                                      localizedCategory,
                                      JewelryColors.emeraldGlow,
                                    ),
                                    _buildTag(
                                      localizedMaterial,
                                      JewelryColors.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Product information.
                          _DetailGlassPanel(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailSectionTitle(
                                  icon: Icons.verified_user_outlined,
                                  text: ref.tr('product_info'),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                    ref.tr('product_origin'),
                                    localizedOrigin.isNotEmpty
                                        ? localizedOrigin
                                        : ref.tr('product_unknown')),
                                _buildInfoRow(ref.tr('product_material'),
                                    localizedMaterial),
                                _buildInfoRow(
                                    ref.tr('product_stock'),
                                    ref.tr(
                                      'product_stock_value',
                                      params: {'count': widget.product.stock},
                                    )),
                                _buildInfoRow(
                                  ref.tr('product_rating'),
                                  ref.tr(
                                    'product_rating_value',
                                    params: {
                                      'score': widget.product.rating
                                          .toStringAsFixed(1),
                                    },
                                  ),
                                ),
                                if (widget.product.certificate != null)
                                  _buildInfoRow(ref.tr('product_cert_no'),
                                      widget.product.certificate!),
                                if (widget.product.weightG != null)
                                  _buildInfoRow(
                                    ref.tr('product_weight'),
                                    ref.tr(
                                      'product_weight_value',
                                      params: {
                                        'weight': widget.product.weightG!
                                            .toStringAsFixed(
                                                widget.product.weightG! ==
                                                        widget.product.weightG!
                                                            .roundToDouble()
                                                    ? 0
                                                    : 1),
                                      },
                                    ),
                                  ),
                                if (widget.product.dimensions != null &&
                                    widget.product.dimensions!.isNotEmpty)
                                  _buildInfoRow(
                                    ref.tr('product_dimensions'),
                                    widget.product.dimensions!,
                                  ),
                              ],
                            ),
                          ),

                          // Appraisal note (only when the field is populated).
                          if (_hasDossierText(appraisalNote))
                            _DetailGlassPanel(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailSectionTitle(
                                    icon: Icons.verified_outlined,
                                    text: ref.tr('product_appraisal_note'),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    appraisalNote!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.65,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Craft highlights (only when populated).
                          if (craftHighlightItems.isNotEmpty)
                            _DetailGlassPanel(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailSectionTitle(
                                    icon: Icons.auto_fix_high_outlined,
                                    text: ref.tr('product_craft_highlights'),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    children: craftHighlightItems
                                        .map(_buildBulletItem)
                                        .toList(growable: false),
                                  ),
                                ],
                              ),
                            ),

                          if (audienceTags.isNotEmpty)
                            _DetailGlassPanel(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailSectionTitle(
                                    icon: Icons.person_search_outlined,
                                    text: ref.tr('product_audience_tags'),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: audienceTags
                                        .map((tag) => _buildTag(
                                              tag,
                                              JewelryColors.champagneGold,
                                            ))
                                        .toList(growable: false),
                                  ),
                                ],
                              ),
                            ),

                          if (_hasDossierText(originStory))
                            _DetailGlassPanel(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailSectionTitle(
                                    icon: Icons.terrain_outlined,
                                    text: ref.tr('product_origin_story'),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    originStory!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.65,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (flawNotes.isNotEmpty)
                            _DetailGlassPanel(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailSectionTitle(
                                    icon: Icons.visibility_outlined,
                                    text: ref.tr('product_flaw_notes'),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    children: flawNotes
                                        .map(_buildBulletItem)
                                        .toList(growable: false),
                                  ),
                                ],
                              ),
                            ),

                          if (_hasDossierText(certificateAuthority) ||
                              _hasDossierText(certificateImageUrl) ||
                              _hasDossierText(certificateVerifyUrl))
                            _DetailGlassPanel(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailSectionTitle(
                                    icon: Icons.fact_check_outlined,
                                    text:
                                        ref.tr('product_certificate_evidence'),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_hasDossierText(certificateAuthority))
                                    _buildInfoRow(
                                      ref.tr('product_certificate_authority'),
                                      certificateAuthority!,
                                    ),
                                  if (_hasDossierText(certificateImageUrl)) ...[
                                    const SizedBox(height: 12),
                                    ProductImageView(
                                      product: widget.product,
                                      imageUrl: certificateImageUrl,
                                      height: 160,
                                      width: double.infinity,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ],
                                  if (_hasDossierText(
                                      certificateVerifyUrl)) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              JewelryColors.emeraldGlow,
                                        ),
                                        onPressed: () =>
                                            _openCertificateVerifyUrl(
                                          certificateVerifyUrl!,
                                        ),
                                        icon: const Icon(
                                          Icons.open_in_new,
                                          size: 18,
                                        ),
                                        label: Text(
                                          ref.tr(
                                            'product_certificate_verify',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          if (galleryDetail.isNotEmpty ||
                              galleryHand.isNotEmpty)
                            _DetailGlassPanel(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailSectionTitle(
                                    icon: Icons.collections_outlined,
                                    text: ref.tr('product_gallery'),
                                  ),
                                  if (galleryDetail.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    _buildGalleryStrip(
                                      label: ref.tr('product_gallery_detail'),
                                      images: galleryDetail,
                                    ),
                                  ],
                                  if (galleryHand.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    _buildGalleryStrip(
                                      label: ref.tr('product_gallery_hand'),
                                      images: galleryHand,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          // Product description.
                          _DetailGlassPanel(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _DetailSectionTitle(
                                      icon: Icons.auto_awesome_outlined,
                                      text: ref.tr('product_description'),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: _isGeneratingDesc
                                          ? null
                                          : _generateAIDescription,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: _isGeneratingDesc
                                              ? null
                                              : JewelryColors
                                                  .emeraldLusterGradient,
                                          color: _isGeneratingDesc
                                              ? JewelryColors.darkDivider
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: _isGeneratingDesc
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: JewelryColors.primary
                                                        .withOpacity(0.18),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_isGeneratingDesc)
                                              const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: JewelryColors
                                                            .jadeBlack),
                                              )
                                            else
                                              const Icon(Icons.auto_awesome,
                                                  size: 14,
                                                  color:
                                                      JewelryColors.jadeBlack),
                                            const SizedBox(width: 4),
                                            Text(
                                              _isGeneratingDesc
                                                  ? ref.tr(
                                                      'product_ai_generating')
                                                  : ref.tr(
                                                      'product_ai_optimize'),
                                              style: const TextStyle(
                                                  color:
                                                      JewelryColors.jadeBlack,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _aiDescription ?? localizedDescription,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        JewelryColors.jadeMist.withOpacity(0.7),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Service guarantees.
                          _DetailGlassPanel(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailSectionTitle(
                                  icon: Icons.workspace_premium_outlined,
                                  text: ref.tr('product_service_guarantee'),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    _buildServiceItem(Icons.verified,
                                        ref.tr('product_service_authentic')),
                                    _buildServiceItem(Icons.local_shipping,
                                        ref.tr('product_service_shipping')),
                                    _buildServiceItem(Icons.refresh,
                                        ref.tr('product_service_return')),
                                    _buildServiceItem(Icons.security,
                                        ref.tr('product_service_compensation')),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Review section.
                          _DetailGlassPanel(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: _DetailSectionTitle(
                                    icon: Icons.rate_review_outlined,
                                    text: ref.tr('product_reviews'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ProductReviewsWidget(
                                    productId: widget.product.id),
                              ],
                            ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 16,
            ),
            decoration: BoxDecoration(
              color: JewelryColors.deepJade.withOpacity(0.9),
              border: Border(
                top: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.16),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.34),
                  blurRadius: 34,
                  offset: const Offset(0, -16),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity selector.
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.055),
                    border: Border.all(
                      color: JewelryColors.champagneGold.withOpacity(0.12),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          color: JewelryColors.jadeMist,
                        ),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        iconSize: 20,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          color: JewelryColors.champagneGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: JewelryColors.jadeMist,
                        ),
                        onPressed: () => setState(() => _quantity++),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // AI Consult shortcut.
                GestureDetector(
                  onTap: () {
                    final lang = ref.read(appSettingsProvider).language;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AIAssistantScreen(
                          productId: widget.product.id,
                          productName: widget.product.localizedTitleFor(lang),
                          initialContext: 'product_ai_consult_context',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: JewelryColors.emeraldShadow,
                      border: Border.all(
                        color: JewelryColors.emeraldGlow.withOpacity(0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: JewelryColors.emeraldLuster.withOpacity(0.18),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: JewelryColors.emeraldGlow,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Add to cart.
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: JewelryColors.emeraldGlow,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _addToCart,
                    child: Text(
                      ref.tr('product_add_to_cart'),
                      style: const TextStyle(
                        color: JewelryColors.emeraldGlow,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Buy now.
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: JewelryColors.emeraldLusterGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: JewelryShadows.emeraldHalo,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _buyNow,
                      child: Text(
                        ref.tr('product_buy_now'),
                        style: const TextStyle(
                          color: JewelryColors.jadeBlack,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopGlassButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: JewelryColors.deepJade.withOpacity(0.56),
              shape: BoxShape.circle,
              border: Border.all(
                color: JewelryColors.champagneGold.withOpacity(0.16),
              ),
              boxShadow: JewelryShadows.liquidGlass,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == JewelryColors.champagneGold
              ? JewelryColors.champagneGold
              : color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: JewelryColors.champagneGold.withOpacity(0.62),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.78),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: JewelryColors.primary.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: JewelryColors.emeraldGlow.withOpacity(0.16),
              ),
            ),
            child: Icon(icon, color: JewelryColors.emeraldGlow, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: JewelryColors.jadeMist.withOpacity(0.62),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _hasDossierText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  List<String> _cleanDossierItems(List<String>? values) {
    if (values == null) return const [];
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JewelryColors.champagneGold.withOpacity(0.84),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryStrip({
    required String label,
    required List<String> images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: JewelryColors.champagneGold.withOpacity(0.72),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return ProductImageView(
                product: widget.product,
                imageUrl: images[index],
                width: 132,
                height: 132,
                borderRadius: BorderRadius.circular(18),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite() async {
    await _storage.toggleFavorite(widget.product.id);
    // Check mounted after await to avoid using context after disposal.
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite
            ? ref.tr('product_added_favorite')
            : ref.tr('product_removed_favorite')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _generateAIDescription() async {
    final currentLanguage = ref.read(appSettingsProvider).language;
    final localizedTitle = widget.product.localizedTitleFor(currentLanguage);
    final localizedMaterial =
        widget.product.localizedMaterialFor(currentLanguage);
    final localizedOrigin = widget.product.localizedOriginFor(currentLanguage);

    setState(() => _isGeneratingDesc = true);

    final desc = await _aiService.generateProductDescription(
      productName: localizedTitle,
      material: localizedMaterial,
      price: widget.product.price,
      features: ref.tr(
        'product_ai_origin_feature',
        params: {
          'origin': localizedOrigin.isNotEmpty
              ? localizedOrigin
              : ref.tr('product_unknown'),
        },
      ),
    );

    setState(() {
      _isGeneratingDesc = false;
      _aiDescription = desc;
    });
  }

  Future<void> _addToCart() async {
    await ref.read(cartProvider.notifier).addItem(
          widget.product,
          quantity: _quantity,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.tr('product_added_cart')),
          backgroundColor: const Color(0xFF2E8B57),
        ),
      );
    }
  }

  void _buyNow() {
    final cartItem = CartItemModel(
      product: widget.product,
      quantity: _quantity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(items: [cartItem]),
      ),
    );
  }

  Future<void> _openCertificateVerifyUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.tr('product_certificate_open_failed')),
        ),
      );
    }
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: JewelryColors.deepJade.withOpacity(0.92),
              border: Border(
                top: BorderSide(
                  color: JewelryColors.champagneGold.withOpacity(0.16),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ref.tr('product_share'),
                  style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareItem(
                        Icons.chat, ref.tr('share_wechat'), Colors.green),
                    _buildShareItem(
                        Icons.group, ref.tr('share_moments'), Colors.green),
                    _buildShareItem(
                        Icons.qr_code, ref.tr('share_qq'), Colors.blue),
                    _buildShareItem(
                      Icons.link,
                      ref.tr('share_link'),
                      JewelryColors.champagneGold,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.tr('share_success', params: {'label': label}),
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color.withOpacity(0.24)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
