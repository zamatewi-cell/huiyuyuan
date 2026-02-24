import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
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
  final _contentController = TextEditingController();

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写点评价内容吧~')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reviewService.init();
      if (mounted) {
        if (widget.order.productId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('订单异常：无商品')),
          );
          return;
        }
      }

      await _reviewService.addReview(
        productId: widget.order.productId,
        userId: widget.order.operatorId ?? 'UNKNOWN_USER',
        userName: '汇玉源用户',
        rating: _rating,
        content: content,
        isAnonymous: _isAnonymous,
        specInfo: widget.order.productName,
      );

      if (mounted) {
        // 这里理应修改订单状态为已评价或部分评价，这需要扩展 OrderService
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('感谢您的评价！'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order.productId.isEmpty) {
      return const Scaffold(body: Center(child: Text('订单异常：无商品')));
    }

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: AppBar(
        title:
            Text('发表评价', style: TextStyle(color: context.adaptiveTextPrimary)),
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
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('发布',
                    style: TextStyle(
                        color: JewelryColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品简要信息卡片
            PremiumCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              backgroundColor: context.adaptiveSurface,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.shopping_bag, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.productName,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.adaptiveTextPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '规格: 默认',
                          style: TextStyle(
                              fontSize: 12,
                              color: context.adaptiveTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 评分区
            Text('描述相符',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.adaptiveTextPrimary)),
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
                    setState(() {
                      _rating = index + 1;
                    });
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
                    fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),

            // 评价输入框
            PremiumCard(
              borderRadius: 16,
              backgroundColor: context.adaptiveSurface,
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: '宝贝满足你的期待吗？说说它的优点和美中不足的地方吧',
                  hintStyle: TextStyle(color: context.adaptiveTextSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 匿名开关
            SwitchListTile(
              title: const Text('匿名评价'),
              subtitle: const Text('你的评价将以匿名形式展现'),
              value: _isAnonymous,
              activeColor: JewelryColors.primary,
              onChanged: (val) {
                setState(() => _isAnonymous = val);
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
        return '非常满意，极力推荐';
      case 4:
        return '满意，符合预期';
      case 3:
        return '一般，感觉凑合';
      case 2:
        return '较差，有待改进';
      case 1:
        return '非常差，极度不满';
      default:
        return '';
    }
  }
}
