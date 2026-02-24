/// 汇玉源 - 商品评价服务
///
/// 功能:
/// - 评价CRUD
/// - 评价统计
/// - 本地缓存 + 远程同步
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review_model.dart';

/// 评价服务类
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  static const String _storageKey = 'product_reviews';
  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ 评价 CRUD ============

  /// 获取商品的所有评价
  Future<List<ReviewModel>> getProductReviews(
    String productId, {
    ReviewFilter filter = ReviewFilter.all,
    int page = 1,
    int pageSize = 10,
  }) async {
    final allReviews = await _getAllReviews();
    var filtered = allReviews.where((r) => r.productId == productId).toList();

    // 应用筛选
    switch (filter) {
      case ReviewFilter.withImages:
        filtered = filtered.where((r) => r.hasImages).toList();
        break;
      case ReviewFilter.withVideo:
        filtered = filtered.where((r) => r.hasVideo).toList();
        break;
      case ReviewFilter.positive:
        filtered = filtered.where((r) => r.rating >= 4).toList();
        break;
      case ReviewFilter.negative:
        filtered = filtered.where((r) => r.rating <= 2).toList();
        break;
      case ReviewFilter.additional:
        filtered = filtered.where((r) => r.hasAdditional).toList();
        break;
      case ReviewFilter.all:
        break;
    }

    // 按时间排序（最新的在前）
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 分页
    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    if (start >= filtered.length) return [];

    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  /// 获取评价统计
  Future<ReviewStats> getProductReviewStats(String productId) async {
    final reviews = await _getAllReviews();
    final productReviews =
        reviews.where((r) => r.productId == productId).toList();

    if (productReviews.isEmpty) {
      return ReviewStats(productId: productId);
    }

    final totalRating = productReviews.fold<int>(0, (sum, r) => sum + r.rating);

    return ReviewStats(
      productId: productId,
      totalCount: productReviews.length,
      averageRating: totalRating / productReviews.length,
      fiveStarCount: productReviews.where((r) => r.rating == 5).length,
      fourStarCount: productReviews.where((r) => r.rating == 4).length,
      threeStarCount: productReviews.where((r) => r.rating == 3).length,
      twoStarCount: productReviews.where((r) => r.rating == 2).length,
      oneStarCount: productReviews.where((r) => r.rating == 1).length,
      withImagesCount: productReviews.where((r) => r.hasImages).length,
      withVideoCount: productReviews.where((r) => r.hasVideo).length,
      additionalCount: productReviews.where((r) => r.hasAdditional).length,
      hotTags: _extractHotTags(productReviews),
    );
  }

  /// 添加评价
  Future<ReviewModel> addReview({
    required String productId,
    required String userId,
    required String userName,
    String? userAvatar,
    required int rating,
    required String content,
    List<String> images = const [],
    String? videoUrl,
    bool isAnonymous = false,
    String? specInfo,
  }) async {
    final reviews = await _getAllReviews();

    // 检查是否已评价
    final existing = reviews
        .where((r) =>
            r.productId == productId && r.userId == userId && !r.hasAdditional)
        .toList();

    if (existing.isNotEmpty) {
      throw Exception('您已经评价过该商品');
    }

    final newId = 'REVIEW-${DateTime.now().millisecondsSinceEpoch}';
    final review = ReviewModel(
      id: newId,
      productId: productId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      rating: rating,
      content: content,
      images: images,
      videoUrl: videoUrl,
      isAnonymous: isAnonymous,
      specInfo: specInfo,
      createdAt: DateTime.now(),
    );

    reviews.add(review);
    await _saveReviews(reviews);

    return review;
  }

  /// 添加追评
  Future<void> addAdditionalReview(String reviewId, String content) async {
    final reviews = await _getAllReviews();
    final index = reviews.indexWhere((r) => r.id == reviewId);

    if (index < 0) {
      throw Exception('评价不存在');
    }

    if (reviews[index].hasAdditional) {
      throw Exception('已经追评过了');
    }

    reviews[index] = ReviewModel(
      id: reviews[index].id,
      productId: reviews[index].productId,
      userId: reviews[index].userId,
      userName: reviews[index].userName,
      userAvatar: reviews[index].userAvatar,
      rating: reviews[index].rating,
      content: reviews[index].content,
      images: reviews[index].images,
      videoUrl: reviews[index].videoUrl,
      isAnonymous: reviews[index].isAnonymous,
      specInfo: reviews[index].specInfo,
      createdAt: reviews[index].createdAt,
      replyContent: reviews[index].replyContent,
      replyAt: reviews[index].replyAt,
      additionalContent: content,
      additionalAt: DateTime.now(),
      likeCount: reviews[index].likeCount,
      isVerified: reviews[index].isVerified,
    );

    await _saveReviews(reviews);
  }

  /// 点赞评价
  Future<void> likeReview(String reviewId) async {
    final reviews = await _getAllReviews();
    final index = reviews.indexWhere((r) => r.id == reviewId);

    if (index >= 0) {
      reviews[index] = ReviewModel(
        id: reviews[index].id,
        productId: reviews[index].productId,
        userId: reviews[index].userId,
        userName: reviews[index].userName,
        userAvatar: reviews[index].userAvatar,
        rating: reviews[index].rating,
        content: reviews[index].content,
        images: reviews[index].images,
        videoUrl: reviews[index].videoUrl,
        isAnonymous: reviews[index].isAnonymous,
        specInfo: reviews[index].specInfo,
        createdAt: reviews[index].createdAt,
        replyContent: reviews[index].replyContent,
        replyAt: reviews[index].replyAt,
        additionalContent: reviews[index].additionalContent,
        additionalAt: reviews[index].additionalAt,
        likeCount: reviews[index].likeCount + 1,
        isVerified: reviews[index].isVerified,
      );
      await _saveReviews(reviews);
    }
  }

  /// 删除评价（仅限自己的）
  Future<void> deleteReview(String reviewId, String userId) async {
    final reviews = await _getAllReviews();
    final index = reviews.indexWhere((r) => r.id == reviewId);

    if (index < 0) return;

    if (reviews[index].userId != userId) {
      throw Exception('无权删除他人评价');
    }

    reviews.removeAt(index);
    await _saveReviews(reviews);
  }

  // ============ 私有方法 ============

  /// 获取所有评价
  Future<List<ReviewModel>> _getAllReviews() async {
    final prefs = await _storage;
    final data = prefs.getString(_storageKey);
    if (data == null) return _getMockReviews();

    try {
      final list = jsonDecode(data) as List;
      return list.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      return _getMockReviews();
    }
  }

  /// 保存评价
  Future<void> _saveReviews(List<ReviewModel> reviews) async {
    final prefs = await _storage;
    final data = reviews.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// 提取热门标签
  List<String> _extractHotTags(List<ReviewModel> reviews) {
    final tagCounts = <String, int>{};
    final keywords = [
      '质量好',
      '发货快',
      '包装好',
      '性价比高',
      '做工精细',
      '温润细腻',
      '颜色正',
      '物超所值',
      '送礼佳品',
      '必回购'
    ];

    for (final review in reviews) {
      for (final keyword in keywords) {
        if (review.content.contains(keyword)) {
          tagCounts[keyword] = (tagCounts[keyword] ?? 0) + 1;
        }
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.take(5).map((e) => e.key).toList();
  }

  /// 模拟评价数据（演示用）
  List<ReviewModel> _getMockReviews() {
    return [
      ReviewModel(
        id: 'REVIEW-MOCK-001',
        productId: 'HYY-HT001',
        userId: 'USER001',
        userName: '玉石爱好者',
        rating: 5,
        content: '非常满意！和田玉籽料质地温润细腻，油性很好，确实是天然A货。'
            '包装也很精美，送给妈妈很开心。客服态度超好，有问必答。',
        images: [
          'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=400',
        ],
        specInfo: '规格: 10mm圆珠',
        createdAt: DateTime(2026, 2, 1),
        replyContent: '感谢您的支持与认可！祝您佩戴愉快~',
        replyAt: DateTime(2026, 2, 2),
        likeCount: 23,
        isVerified: true,
      ),
      ReviewModel(
        id: 'REVIEW-MOCK-002',
        productId: 'HYY-HT001',
        userId: 'USER002',
        userName: '小红',
        rating: 5,
        content: '199买到这个品质真的太值了！之前在商场看过类似的要上千，这个性价比绝了。',
        isAnonymous: false,
        createdAt: DateTime(2026, 1, 28),
        additionalContent: '戴了一周，越来越油润了，盘玩效果很好！',
        additionalAt: DateTime(2026, 2, 4),
        likeCount: 15,
        isVerified: true,
      ),
      ReviewModel(
        id: 'REVIEW-MOCK-003',
        productId: 'HYY-FC001',
        userId: 'USER003',
        userName: '翡翠收藏家',
        rating: 5,
        content: '冰种质地，透明度很高，飘花灵动自然。18K金镶嵌工艺精细，确实是缅甸A货。'
            '附带的证书也查验过了，正规机构出具。物超所值！',
        images: [
          'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400',
          'https://images.unsplash.com/photo-1506630448388-4e683c67ddb0?w=400',
        ],
        specInfo: '规格: 平安扣30mm',
        createdAt: DateTime(2026, 1, 25),
        replyContent: '感谢您对汇玉源的信任！翡翠A货品质保证，假一赔十~',
        replyAt: DateTime(2026, 1, 26),
        likeCount: 45,
        isVerified: true,
      ),
      ReviewModel(
        id: 'REVIEW-MOCK-004',
        productId: 'HYY-NH001',
        userId: 'USER004',
        userName: '***',
        rating: 4,
        content: '南红颜色很正，转运珠设计挺好看的。就是感觉珠子有点小，日常戴着不太显眼。',
        isAnonymous: true,
        createdAt: DateTime(2026, 1, 20),
        likeCount: 8,
        isVerified: true,
      ),
      ReviewModel(
        id: 'REVIEW-MOCK-005',
        productId: 'HYY-HJ001',
        userId: 'USER005',
        userName: '金饰控',
        rating: 5,
        content: '古法黄金的质感真的不一样，哑光磨砂效果很有复古感。'
            '足金999，含金量高，重量也够。送给老婆的结婚纪念日礼物，她超喜欢！',
        images: [
          'https://images.unsplash.com/photo-1603561596112-0a132b757442?w=400',
        ],
        specInfo: '规格: 20g足金手镯',
        createdAt: DateTime(2026, 1, 15),
        likeCount: 67,
        isVerified: true,
      ),
    ];
  }
}
