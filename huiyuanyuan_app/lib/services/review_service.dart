/// 汇玉源 - 商品评价服务
///
/// 功能:
/// - 评价CRUD
/// - 评价统计
/// - API 同步 + 本地缓存 fallback
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review_model.dart';
import 'api_service.dart';
import '../config/api_config.dart';

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

    // 同步到后端
    try {
      await _api.post(ApiConfig.reviews, data: review.toJson());
    } catch (_) {}

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

  final _api = ApiService();

  /// 获取所有评价（API → 本地缓存 → 空列表）
  Future<List<ReviewModel>> _getAllReviews() async {
    // 1. 尝试后端 API
    try {
      final res = await _api.get(ApiConfig.reviews);
      if (res.success && res.data is List) {
        final reviews = (res.data as List)
            .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
            .toList();
        // 回写本地缓存
        _saveReviewsLocal(reviews);
        return reviews;
      }
    } catch (_) {}

    // 2. 本地缓存
    final prefs = await _storage;
    final data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        return list.map((json) => ReviewModel.fromJson(json)).toList();
      } catch (_) {}
    }

    // 3. 无数据
    return [];
  }

  /// 保存评价到本地缓存
  Future<void> _saveReviewsLocal(List<ReviewModel> reviews) async {
    final prefs = await _storage;
    final data = reviews.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// 保存评价（本地 + API 同步）
  Future<void> _saveReviews(List<ReviewModel> reviews) async {
    await _saveReviewsLocal(reviews);
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

}
