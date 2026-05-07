/// HuiYuYuan product review models.
///
/// Covers review content, media attachments, follow-up comments, and stats.
library;

import 'json_parsing.dart';
import '../l10n/translator_global.dart';

/// Review model.
class ReviewModel {
  final String id;
  final String productId;
  final String? orderId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating; // 1-5 star rating
  final String content; // Review content
  final List<String> images; // Review images
  final String? videoUrl; // Review video
  final bool isAnonymous; // Anonymous flag
  final String? specInfo; // Purchased spec information
  final DateTime createdAt;
  final String? replyContent; // Merchant reply
  final DateTime? replyAt; // Reply timestamp
  final String? additionalContent; // Follow-up review content
  final DateTime? additionalAt; // Follow-up timestamp
  final int likeCount; // Like count
  final bool isVerified; // Verified purchase flag

  ReviewModel({
    required this.id,
    required this.productId,
    this.orderId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.content,
    this.images = const [],
    this.videoUrl,
    this.isAnonymous = false,
    this.specInfo,
    required this.createdAt,
    this.replyContent,
    this.replyAt,
    this.additionalContent,
    this.additionalAt,
    this.likeCount = 0,
    this.isVerified = true,
  });

  /// Display name with anonymous masking applied.
  String get displayName {
    if (isAnonymous) {
      if (userName.length >= 2) {
        return '${userName[0]}***';
      }
      return TranslatorGlobal.instance.translate('review_anonymous_user');
    }
    return userName;
  }

  /// Whether the review has images.
  bool get hasImages => images.isNotEmpty;

  /// Whether the review has a video.
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Whether the review has media content.
  bool get hasMedia => hasImages || hasVideo;

  /// Whether the review has follow-up content.
  bool get hasAdditional =>
      additionalContent != null && additionalContent!.isNotEmpty;

  /// Whether the review has a merchant reply.
  bool get hasReply => replyContent != null && replyContent!.isNotEmpty;

  /// Localized text for the rating bucket.
  String get ratingText {
    switch (rating) {
      case 5:
        return TranslatorGlobal.instance.translate('review_rating_excellent');
      case 4:
        return TranslatorGlobal.instance.translate('review_rating_good');
      case 3:
        return TranslatorGlobal.instance.translate('review_rating_average');
      case 2:
        return TranslatorGlobal.instance.translate('review_rating_poor');
      case 1:
        return TranslatorGlobal.instance.translate('review_rating_terrible');
      default:
        return TranslatorGlobal.instance.translate('product_unknown');
    }
  }

  /// Creates a review from JSON.
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: jsonAsString(json['id']),
      productId: jsonAsString(json['product_id']),
      orderId: jsonAsNullableString(json['order_id']),
      userId: jsonAsString(json['user_id']),
      userName: jsonAsString(json['user_name']),
      userAvatar: jsonAsNullableString(json['user_avatar']),
      rating: jsonAsInt(json['rating'], fallback: 5),
      content: jsonAsString(json['content']),
      images: jsonAsStringList(json['images']),
      videoUrl: jsonAsNullableString(json['video_url']),
      isAnonymous: jsonAsBool(json['is_anonymous']),
      specInfo: jsonAsNullableString(json['spec_info']),
      createdAt: jsonAsDateTime(json['created_at']),
      replyContent: jsonAsNullableString(json['reply_content']),
      replyAt: jsonAsNullableDateTime(json['reply_at']),
      additionalContent: jsonAsNullableString(json['additional_content']),
      additionalAt: jsonAsNullableDateTime(json['additional_at']),
      likeCount: jsonAsInt(json['like_count']),
      isVerified: jsonAsBool(json['is_verified'], fallback: true),
    );
  }

  /// Converts the review to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'order_id': orderId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'content': content,
      'images': images,
      'video_url': videoUrl,
      'is_anonymous': isAnonymous,
      'spec_info': specInfo,
      'created_at': createdAt.toIso8601String(),
      'reply_content': replyContent,
      'reply_at': replyAt?.toIso8601String(),
      'additional_content': additionalContent,
      'additional_at': additionalAt?.toIso8601String(),
      'like_count': likeCount,
      'is_verified': isVerified,
    };
  }
}

/// Review statistics model.
class ReviewStats {
  final String productId;
  final int totalCount; // Total review count
  final double averageRating; // Average rating
  final int fiveStarCount; // 5-star count
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final int withImagesCount; // Review count with images
  final int withVideoCount; // Review count with videos
  final int additionalCount; // Follow-up review count
  final List<String> hotTags; // Popular tags

  ReviewStats({
    required this.productId,
    this.totalCount = 0,
    this.averageRating = 5.0,
    this.fiveStarCount = 0,
    this.fourStarCount = 0,
    this.threeStarCount = 0,
    this.twoStarCount = 0,
    this.oneStarCount = 0,
    this.withImagesCount = 0,
    this.withVideoCount = 0,
    this.additionalCount = 0,
    this.hotTags = const [],
  });

  /// Positive review rate (4-5 stars).
  double get positiveRate {
    if (totalCount == 0) return 100.0;
    return (fiveStarCount + fourStarCount) / totalCount * 100;
  }

  /// Neutral review rate (3 stars).
  double get neutralRate {
    if (totalCount == 0) return 0.0;
    return threeStarCount / totalCount * 100;
  }

  /// Negative review rate (1-2 stars).
  double get negativeRate {
    if (totalCount == 0) return 0.0;
    return (oneStarCount + twoStarCount) / totalCount * 100;
  }

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      productId: jsonAsString(json['product_id']),
      totalCount: jsonAsInt(json['total_count']),
      averageRating: jsonAsDouble(json['average_rating'], fallback: 5.0),
      fiveStarCount: jsonAsInt(json['five_star_count']),
      fourStarCount: jsonAsInt(json['four_star_count']),
      threeStarCount: jsonAsInt(json['three_star_count']),
      twoStarCount: jsonAsInt(json['two_star_count']),
      oneStarCount: jsonAsInt(json['one_star_count']),
      withImagesCount: jsonAsInt(json['with_images_count']),
      withVideoCount: jsonAsInt(json['with_video_count']),
      additionalCount: jsonAsInt(json['additional_count']),
      hotTags: jsonAsStringList(json['hot_tags']),
    );
  }
}

/// Review filter type.
enum ReviewFilter {
  all('review_filter_all'),
  withImages('review_filter_images'),
  withVideo('review_filter_videos'),
  positive('review_filter_positive'),
  negative('review_filter_negative'),
  additional('review_filter_additional');

  final String label;
  const ReviewFilter(this.label);
}
