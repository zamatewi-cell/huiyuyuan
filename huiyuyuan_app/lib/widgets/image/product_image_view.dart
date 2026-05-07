library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../data/product_data.dart';
import '../../l10n/product_translator.dart';
import '../../models/product_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../animations/custom_shimmer.dart';

class ProductImageView extends ConsumerStatefulWidget {
  const ProductImageView({
    super.key,
    required this.product,
    this.imageUrl,
    this.width,
    this.height,
    this.memCacheWidth,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final ProductModel product;
  final String? imageUrl;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  ConsumerState<ProductImageView> createState() => _ProductImageViewState();
}

class _ProductImageViewState extends ConsumerState<ProductImageView> {
  static const Set<String> _knownBrokenUnsplashIds = {
    '1661645464570-9a4f3d4dd061',
    '1681276170092-446cd1b5b32d',
    '1661645473770-90d750452fa0',
    '1726743629168-77847c4cbb6a',
    '1678749105251-b15e8fd164bf',
    '1724088684005-4f9f2e1ec43c',
    '1739899051444-fcbdb848db5d',
    '1674255466849-b23fc5f5d3eb',
    '1674255466836-f38d1cc6fd0d',
    '1736818881523-87556344c1a2',
    '1681276170281-cf50a487a1b7',
    '1674157905253-1f5dc638a588',
    '1664202526641-4203eaa33844',
    '1681276169919-d89839416ef7',
    '1674748385691-a185ad303097',
    '1667206795522-430ed80bd9d8',
    '1728216320421-acadfa847591',
    '1673284258408-3341659fbc87',
    '1734315041597-a561152a875b',
    '1671209796002-5da9a14106de',
    '1670728016218-3a3ceec0a483',
    '1661811815190-b99942bf3b74',
  };

  late List<String> _candidateUrls;
  var _candidateIndex = 0;
  var _switchQueued = false;

  @override
  void initState() {
    super.initState();
    _rebuildCandidates();
  }

  @override
  void didUpdateWidget(covariant ProductImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final imageChanged = oldWidget.imageUrl != widget.imageUrl;
    final productChanged = oldWidget.product.id != widget.product.id ||
        oldWidget.product.images.length != widget.product.images.length ||
        oldWidget.product.material != widget.product.material;
    if (imageChanged || productChanged) {
      _rebuildCandidates();
    }
  }

  void _rebuildCandidates() {
    _candidateUrls = _buildCandidateUrls();
    _candidateIndex = 0;
    _switchQueued = false;
  }

  @override
  Widget build(BuildContext context) {
    final child = _candidateUrls.isEmpty
        ? _buildLocalFallback(context)
        : _buildNetworkImage(context, _candidateUrls[_candidateIndex]);

    if (widget.borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: child,
    );
  }

  Widget _buildNetworkImage(BuildContext context, String imageUrl) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildLocalFallback(context),
          CachedNetworkImage(
            imageUrl: imageUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            memCacheWidth: widget.memCacheWidth,
            placeholder: (context, url) => _buildLoadingState(context),
            errorWidget: (context, url, error) {
              _queueNextCandidate();
              return _candidateIndex + 1 < _candidateUrls.length
                  ? _buildLoadingState(context)
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              context.isDark ? Colors.black.withOpacity(0.06) : Colors.white24,
        ),
        child: CustomShimmer.adaptive(
          context,
          child: Container(
            color: context.isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.32),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalFallback(BuildContext context) {
    final canonicalMaterial =
        ProductTranslator.canonicalMaterial(widget.product.material);
    final accent = JewelryColors.getMaterialColor(canonicalMaterial);
    final isCompact =
        (widget.width ?? 0) <= 110 || (widget.height ?? 0) <= 110;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(context.isDark ? 0.28 : 0.16),
            context.adaptiveSurface,
            context.adaptiveCard,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -24,
            right: -16,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -24,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.05),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.diamond_rounded,
              size: isCompact ? 32 : 78,
              color: accent.withOpacity(0.92),
            ),
          ),
          if (!isCompact)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge(
                      context,
                      widget.product.localizedCategoryFor(
                          ref.watch(appSettingsProvider).language),
                      accent,
                    ),
                    _buildBadge(
                      context,
                      widget.product.localizedMaterialFor(
                          ref.watch(appSettingsProvider).language),
                      accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(context.isDark ? 0.22 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withOpacity(0.28),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.adaptiveTextPrimary,
        ),
      ),
    );
  }

  void _queueNextCandidate() {
    if (_switchQueued || _candidateIndex + 1 >= _candidateUrls.length) {
      return;
    }

    _switchQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _candidateIndex += 1;
        _switchQueued = false;
      });
    });
  }

  List<String> _buildCandidateUrls() {
    final urls = <String>[];

    void addUrl(String? rawUrl) {
      final normalized = _normalizeUrl(rawUrl);
      if (normalized == null ||
          normalized.isEmpty ||
          _isKnownBrokenUrl(normalized) ||
          urls.contains(normalized)) {
        return;
      }
      urls.add(normalized);
    }

    addUrl(widget.imageUrl);
    for (final image in widget.product.images) {
      addUrl(image);
    }

    addUrl(
      getDefaultImageForMaterial(
        ProductTranslator.canonicalMaterial(widget.product.material),
      ),
    );

    return urls;
  }

  String? _normalizeUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    final baseUrl = ApiConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      return trimmed.startsWith('/') ? trimmed : '/$trimmed';
    }

    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }

    return '$baseUrl/$trimmed';
  }

  bool _isKnownBrokenUrl(String normalizedUrl) {
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || !uri.host.contains('images.unsplash.com')) {
      return false;
    }

    final path = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    return _knownBrokenUnsplashIds.contains(path);
  }
}
