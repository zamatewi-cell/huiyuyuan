import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../widgets/common/glassmorphic_card.dart';

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
        backgroundColor: isError ? Colors.red : Colors.green,
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
    if (widget.order.productId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(ref.tr('review_publish_no_product')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: AppBar(
        title: Text(
          ref.tr('review_publish_title'),
          style: TextStyle(color: context.adaptiveTextPrimary),
        ),
        backgroundColor: context.adaptiveSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.adaptiveTextPrimary),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitReview,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    ref.tr('review_publish_submit'),
                    style: const TextStyle(
                      color: JewelryColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              backgroundColor: context.adaptiveSurface,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: widget.order.productImage != null &&
                              widget.order.productImage!.isNotEmpty
                          ? Image.network(
                              widget.order.productImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.shopping_bag,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.localizedProductName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.adaptiveTextPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ref.tr('review_publish_spec_default'),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.adaptiveTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              ref.tr('review_publish_match_desc'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color:
                        index < _rating ? JewelryColors.gold : Colors.grey[400],
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getRatingText(),
                style: TextStyle(
                  color: _rating >= 4 ? Colors.orange : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            PremiumCard(
              borderRadius: 16,
              backgroundColor: context.adaptiveSurface,
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: ref.tr('review_publish_placeholder'),
                  hintStyle: TextStyle(color: context.adaptiveTextSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(ref.tr('review_publish_anonymous')),
              subtitle: Text(ref.tr('review_publish_anonymous_hint')),
              value: _isAnonymous,
              activeColor: JewelryColors.primary,
              onChanged: (value) {
                setState(() => _isAnonymous = value);
              },
            ),
          ],
        ),
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
