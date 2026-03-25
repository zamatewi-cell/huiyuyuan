// 汇玉源 - 商品评价组件
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

// 评价列表组件（用于商品详情页）
class ProductReviewsWidget extends StatefulWidget {
  final String productId;
  final bool showAll; // 是否显示全部，false则只显示前3条

  const ProductReviewsWidget({
    super.key,
    required this.productId,
    this.showAll = false,
  });

  @override
  State<ProductReviewsWidget> createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  final ReviewService _reviewService = ReviewService();
  List<ReviewModel> _reviews = [];
  ReviewStats? _stats;
  bool _isLoading = true;
  ReviewFilter _currentFilter = ReviewFilter.all;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    await _reviewService.init();
    final reviews = await _reviewService.getProductReviews(
      widget.productId,
      filter: _currentFilter,
      pageSize: widget.showAll ? 50 : 3,
    );
    final stats = await _reviewService.getProductReviewStats(widget.productId);

    if (mounted) {
      setState(() {
        _reviews = reviews;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 评价统计卡片
        if (_stats != null && _stats!.totalCount > 0) _buildStatsCard(),

        // 筛选标签
        if (widget.showAll) _buildFilterTabs(),

        // 评价列表
        if (_reviews.isEmpty)
          _buildEmptyState()
        else
          ..._reviews.map((review) => _buildReviewCard(review)),

        // 查看更多按钮
        if (!widget.showAll && _stats != null && _stats!.totalCount > 3)
          _buildViewMoreButton(),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 评分
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _stats!.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB800),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          '/ 5.0',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < _stats!.averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: const Color(0xFFFFB800),
                        size: 16,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // 评价统计
              Expanded(
                child: Column(
                  children: [
                    _buildProgressBar('好评', _stats!.positiveRate, Colors.green),
                    const SizedBox(height: 4),
                    _buildProgressBar('中评', _stats!.neutralRate, Colors.orange),
                    const SizedBox(height: 4),
                    _buildProgressBar('差评', _stats!.negativeRate, Colors.red),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 热门标签
          if (_stats!.hotTags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _stats!.hotTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E8B57),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percent, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${percent.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ReviewFilter.values.map((filter) {
          final isSelected = filter == _currentFilter;
          String label = filter.label;

          // 添加数量
          if (_stats != null) {
            switch (filter) {
              case ReviewFilter.all:
                label = '全部(${_stats!.totalCount})';
                break;
              case ReviewFilter.withImages:
                label = '有图(${_stats!.withImagesCount})';
                break;
              case ReviewFilter.withVideo:
                label = '有视频(${_stats!.withVideoCount})';
                break;
              case ReviewFilter.positive:
                label = '好评(${_stats!.fiveStarCount + _stats!.fourStarCount})';
                break;
              case ReviewFilter.negative:
                label = '差评(${_stats!.oneStarCount + _stats!.twoStarCount})';
                break;
              case ReviewFilter.additional:
                label = '追评(${_stats!.additionalCount})';
                break;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _currentFilter = filter);
                  _loadReviews();
                }
              },
              selectedColor: const Color(0xFF2E8B57).withOpacity(0.2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                child: review.userAvatar != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: review.userAvatar!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        review.displayName[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        if (review.isVerified)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              '已购买',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFB800),
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 规格信息
          if (review.specInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                review.specInfo!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),

          // 评价内容
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              review.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),

          // 评价图片
          if (review.hasImages)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: review.images.map((url) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
            ),

          // 追评
          if (review.hasAdditional)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.add_comment,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '追评 ${_formatDate(review.additionalAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.additionalContent!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

          // 商家回复
          if (review.hasReply)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2E8B57).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B57),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '店铺回复',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(review.replyAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.replyContent!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

          // 底部操作栏
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _likeReview(review.id),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        review.likeCount > 0 ? '${review.likeCount}' : '有用',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '暂无评价',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '购买后可以发表评价',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const Text('全部评价'),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                body: SingleChildScrollView(
                  child: ProductReviewsWidget(
                    productId: widget.productId,
                    showAll: true,
                  ),
                ),
              ),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '查看全部 ${_stats!.totalCount} 条评价',
              style: const TextStyle(color: Color(0xFF2E8B57)),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF2E8B57)),
          ],
        ),
      ),
    );
  }

  Future<void> _likeReview(String reviewId) async {
    await _reviewService.likeReview(reviewId);
    _loadReviews();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}
