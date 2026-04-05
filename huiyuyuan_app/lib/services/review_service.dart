library;

import 'dart:convert';

import 'package:huiyuyuan/l10n/string_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/json_parsing.dart';
import '../models/review_model.dart';
import 'api_service.dart';
import 'review_tag_matchers.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() => _instance;

  ReviewService._internal();

  static const String _storageKey = 'product_reviews';

  final ApiService _api = ApiService();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<ReviewModel>> getProductReviews(
    String productId, {
    ReviewFilter filter = ReviewFilter.all,
    int page = 1,
    int pageSize = 10,
  }) async {
    var filtered = await _loadProductReviews(productId);

    switch (filter) {
      case ReviewFilter.withImages:
        filtered = filtered.where((review) => review.hasImages).toList();
        break;
      case ReviewFilter.withVideo:
        filtered = filtered.where((review) => review.hasVideo).toList();
        break;
      case ReviewFilter.positive:
        filtered = filtered.where((review) => review.rating >= 4).toList();
        break;
      case ReviewFilter.negative:
        filtered = filtered.where((review) => review.rating <= 2).toList();
        break;
      case ReviewFilter.additional:
        filtered = filtered.where((review) => review.hasAdditional).toList();
        break;
      case ReviewFilter.all:
        break;
    }

    filtered.sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    if (start >= filtered.length) {
      return [];
    }

    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  Future<ReviewStats> getProductReviewStats(String productId) async {
    final productReviews = await _loadProductReviews(productId);
    if (productReviews.isEmpty) {
      return ReviewStats(productId: productId);
    }

    final totalRating =
        productReviews.fold<int>(0, (sum, review) => sum + review.rating);

    return ReviewStats(
      productId: productId,
      totalCount: productReviews.length,
      averageRating: totalRating / productReviews.length,
      fiveStarCount:
          productReviews.where((review) => review.rating == 5).length,
      fourStarCount:
          productReviews.where((review) => review.rating == 4).length,
      threeStarCount:
          productReviews.where((review) => review.rating == 3).length,
      twoStarCount: productReviews.where((review) => review.rating == 2).length,
      oneStarCount: productReviews.where((review) => review.rating == 1).length,
      withImagesCount:
          productReviews.where((review) => review.hasImages).length,
      withVideoCount: productReviews.where((review) => review.hasVideo).length,
      additionalCount:
          productReviews.where((review) => review.hasAdditional).length,
      hotTags: _extractHotTags(productReviews),
    );
  }

  Future<ReviewModel> addReview({
    required String productId,
    required String orderId,
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
    final reviews = await _collectMergedReviews(productId);
    final hasReviewedOrder = reviews.any(
      (review) =>
          review.productId == productId &&
          review.userId == userId &&
          review.orderId == orderId &&
          !review.hasAdditional,
    );

    if (hasReviewedOrder) {
      throw Exception('review_error_already_submitted'.tr);
    }

    final response = await _api.post<ReviewModel>(
      ApiConfig.reviews,
      data: {
        'product_id': productId,
        'order_id': orderId,
        'rating': rating,
        'content': content,
        'images': images,
        'is_anonymous': isAnonymous,
      },
      fromJson: (json) => ReviewModel.fromJson(jsonAsMap(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'review_error_submit_failed'.tr);
    }

    final remoteReview = response.data!;
    final review = ReviewModel(
      id: remoteReview.id,
      productId: remoteReview.productId.isNotEmpty
          ? remoteReview.productId
          : productId,
      orderId: remoteReview.orderId ?? orderId,
      userId: remoteReview.userId.isNotEmpty ? remoteReview.userId : userId,
      userName:
          remoteReview.userName.isNotEmpty ? remoteReview.userName : userName,
      userAvatar: remoteReview.userAvatar ?? userAvatar,
      rating: remoteReview.rating,
      content: remoteReview.content,
      images: remoteReview.images.isNotEmpty ? remoteReview.images : images,
      videoUrl: remoteReview.videoUrl ?? videoUrl,
      isAnonymous: remoteReview.isAnonymous,
      specInfo: specInfo ?? remoteReview.specInfo,
      createdAt: remoteReview.createdAt,
      likeCount: remoteReview.likeCount,
      isVerified: remoteReview.isVerified,
    );

    await _upsertReview(review, reviews);
    return review;
  }

  Future<void> addAdditionalReview(String reviewId, String content) async {
    final reviews = await _getAllReviews();
    final index = reviews.indexWhere((review) => review.id == reviewId);

    if (index < 0) {
      throw Exception('review_error_not_found'.tr);
    }

    if (reviews[index].hasAdditional) {
      throw Exception('review_error_already_appended'.tr);
    }

    reviews[index] = ReviewModel(
      id: reviews[index].id,
      productId: reviews[index].productId,
      orderId: reviews[index].orderId,
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

  Future<void> likeReview(String reviewId) async {
    final reviews = await _getAllReviews();
    final index = reviews.indexWhere((review) => review.id == reviewId);

    if (index < 0) {
      return;
    }

    reviews[index] = ReviewModel(
      id: reviews[index].id,
      productId: reviews[index].productId,
      orderId: reviews[index].orderId,
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

  Future<void> deleteReview(String reviewId, String userId) async {
    final reviews = await _getAllReviews();
    final index = reviews.indexWhere((review) => review.id == reviewId);

    if (index < 0) {
      return;
    }

    if (reviews[index].userId != userId) {
      throw Exception('review_error_delete_forbidden'.tr);
    }

    reviews.removeAt(index);
    await _saveReviews(reviews);
  }

  Future<List<ReviewModel>> _collectMergedReviews(String productId) async {
    final remoteReviews = await _loadProductReviews(productId);
    final cachedReviews = await _getAllReviews();
    final reviewsById = <String, ReviewModel>{
      for (final review in remoteReviews) review.id: review,
      for (final review in cachedReviews) review.id: review,
    };
    return reviewsById.values.toList();
  }

  Future<List<ReviewModel>> _loadProductReviews(String productId) async {
    try {
      final response = await _api.get(
        ApiConfig.productReviews(productId),
        params: {
          'page': 1,
          'page_size': 200,
        },
      );

      if (response.success && response.data is List) {
        final remoteReviews = (response.data as List)
            .map((json) => ReviewModel.fromJson(jsonAsMap(json)))
            .toList();
        await _mergeProductReviewsIntoCache(productId, remoteReviews);
        return remoteReviews;
      }
    } catch (_) {}

    final allReviews = await _getAllReviews();
    return allReviews.where((review) => review.productId == productId).toList();
  }

  Future<void> _mergeProductReviewsIntoCache(
    String productId,
    List<ReviewModel> remoteReviews,
  ) async {
    final cachedReviews = await _getAllReviews();
    final merged = <String, ReviewModel>{
      for (final review in remoteReviews) review.id: review,
      for (final review in cachedReviews.where(
        (item) => item.productId == productId,
      ))
        review.id: review,
    };

    final nextCache = [
      ...cachedReviews.where((item) => item.productId != productId),
      ...merged.values,
    ];
    await _saveReviewsLocal(nextCache);
  }

  Future<List<ReviewModel>> _getAllReviews() async {
    final prefs = await _storage;
    final data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        return list
            .map((json) => ReviewModel.fromJson(jsonAsMap(json)))
            .toList();
      } catch (_) {}
    }

    return [];
  }

  Future<void> _saveReviewsLocal(List<ReviewModel> reviews) async {
    final prefs = await _storage;
    final data = reviews.map((review) => review.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> _saveReviews(List<ReviewModel> reviews) async {
    await _saveReviewsLocal(reviews);
  }

  Future<void> _upsertReview(
    ReviewModel review,
    List<ReviewModel> existingReviews,
  ) async {
    existingReviews.removeWhere((item) => item.id == review.id);
    existingReviews.add(review);
    await _saveReviews(existingReviews);
  }

  List<String> _extractHotTags(List<ReviewModel> reviews) {
    final tagCounts = <String, int>{};
    final reviewContents = reviews
        .map((review) => review.content.toLowerCase())
        .toList(growable: false);

    for (final descriptor in reviewHotTagDescriptors) {
      final hitCount = reviewContents.where((content) {
        return descriptor.matchTerms.any(
          (term) => content.contains(term.toLowerCase()),
        );
      }).length;
      if (hitCount > 0) {
        tagCounts[descriptor.labelKey] = hitCount;
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    return sortedTags.take(5).map((entry) => entry.key).toList(growable: false);
  }
}
