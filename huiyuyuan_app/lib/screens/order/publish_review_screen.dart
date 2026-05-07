import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../l10n/l10n_provider.dart';
import '../../models/order_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/common/resilient_network_image.dart';

class _ReviewBackdrop extends StatelessWidget {
  const _ReviewBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -120,
            child: _ReviewGlowOrb(
              size: 330,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -140,
            top: 250,
            child: _ReviewGlowOrb(
              size: 290,
              color: JewelryColors.champagneGold.withOpacity(0.11),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ReviewTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewGlowOrb extends StatelessWidget {
  const _ReviewGlowOrb({
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
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

class _ReviewTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = JewelryColors.champagneGold.withOpacity(0.04);

    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.14 + i * 0.14);
      final path = Path()..moveTo(-24, y);
      path.cubicTo(
        size.width * 0.18,
        y + 34,
        size.width * 0.7,
        y - 34,
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReviewTracePainter oldDelegate) => false;
}

class PublishReviewScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const PublishReviewScreen({super.key, required this.order});

  @override
  ConsumerState<PublishReviewScreen> createState() =>
      _PublishReviewScreenState();
}

class _PublishReviewScreenState extends ConsumerState<PublishReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _contentController = TextEditingController();

  int _rating = 5;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showMessage(ref.tr('review_publish_empty_content'));
      return;
    }

    if (widget.order.productId.isEmpty) {
      _showMessage(ref.tr('review_publish_no_product'), isError: true);
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showMessage(ref.tr('review_publish_login_required'), isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reviewService.init();
      await _reviewService.addReview(
        productId: widget.order.productId,
        orderId: widget.order.id,
        userId: currentUser.id,
        userName: currentUser.username,
        rating: _rating,
        content: content,
        isAnonymous: _isAnonymous,
        specInfo: widget.order.productName,
      );

      if (!mounted) {
        return;
      }

      _showMessage(ref.tr('review_publish_thanks'));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_normalizeError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? JewelryColors.error : JewelryColors.emeraldShadow,
      ),
    );
  }

  String _normalizeError(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appSettingsProvider).language;

    if (widget.order.productId.isEmpty) {
      return Scaffold(
        backgroundColor: JewelryColors.jadeBlack,
        body: Stack(
          children: [
            const Positioned.fill(child: _ReviewBackdrop()),
            Center(
              child: GlassmorphicCard(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                blur: 16,
                opacity: 0.18,
                borderColor: JewelryColors.champagneGold.withOpacity(0.14),
                child: Text(
                  ref.tr('review_publish_no_product'),
                  style: const TextStyle(
                    color: JewelryColors.jadeMist,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
            ref.tr('review_publish_title'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.84),
        elevation: 0,
        iconTheme: const IconThemeData(color: JewelryColors.jadeMist),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitReview,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: JewelryColors.emeraldGlow,
                    ),
                  )
                : Text(
                    ref.tr('review_publish_submit'),
                    style: const TextStyle(
                      color: JewelryColors.emeraldGlow,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _ReviewBackdrop()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassmorphicCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 24,
                  blur: 16,
                  opacity: 0.18,
                  borderColor: JewelryColors.champagneGold.withOpacity(0.14),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: JewelryColors.deepJade.withOpacity(0.58),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.12),
                          ),
                        ),
                        child: widget.order.productImage != null &&
                                widget.order.productImage!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ResilientNetworkImage(
                                  imageUrl: _resolveImageUrl(
                                    widget.order.productImage!,
                                  ),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(
                                    Icons.shopping_bag,
                                    color: JewelryColors.emeraldGlow,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.shopping_bag,
                                color: JewelryColors.emeraldGlow,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.order.localizedProductNameFor(language),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: JewelryColors.jadeMist,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ref.tr('review_publish_spec_default'),
                              style: TextStyle(
                                fontSize: 12,
                                color: JewelryColors.jadeMist.withOpacity(0.58),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassmorphicCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  borderRadius: 24,
                  blur: 16,
                  opacity: 0.18,
                  borderColor: JewelryColors.champagneGold.withOpacity(0.14),
                  child: Column(
                    children: [
                      Text(
                        ref.tr('review_publish_match_desc'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: JewelryColors.jadeMist,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final isActive = index < _rating;
                          return IconButton(
                            icon: Icon(
                              isActive
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: isActive
                                  ? JewelryColors.champagneGold
                                  : JewelryColors.jadeMist.withOpacity(0.28),
                              size: 38,
                            ),
                            onPressed: () {
                              setState(() => _rating = index + 1);
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: JewelryColors.champagneGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          _getRatingText(),
                          style: const TextStyle(
                            color: JewelryColors.champagneGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassmorphicCard(
                  borderRadius: 24,
                  blur: 16,
                  opacity: 0.18,
                  borderColor: JewelryColors.champagneGold.withOpacity(0.14),
                  child: TextField(
                    controller: _contentController,
                    maxLines: 6,
                    maxLength: 500,
                    style: const TextStyle(
                      color: JewelryColors.jadeMist,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: ref.tr('review_publish_placeholder'),
                      hintStyle: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.42),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.46),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GlassmorphicCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 24,
                  blur: 16,
                  opacity: 0.18,
                  borderColor: JewelryColors.champagneGold.withOpacity(0.14),
                  child: SwitchListTile(
                    title: Text(
                      ref.tr('review_publish_anonymous'),
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      ref.tr('review_publish_anonymous_hint'),
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.54),
                      ),
                    ),
                    value: _isAnonymous,
                    activeColor: JewelryColors.emeraldGlow,
                    activeTrackColor:
                        JewelryColors.emeraldGlow.withOpacity(0.3),
                    onChanged: (value) {
                      setState(() => _isAnonymous = value);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 5:
        return ref.tr('review_rating_excellent');
      case 4:
        return ref.tr('review_rating_good');
      case 3:
        return ref.tr('review_rating_average');
      case 2:
        return ref.tr('review_rating_poor');
      case 1:
        return ref.tr('review_rating_terrible');
      default:
        return '';
    }
  }
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
