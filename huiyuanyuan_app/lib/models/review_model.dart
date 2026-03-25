/// 汇玉源 - 商品评价模型
///
/// 功能:
/// - 评价CRUD
/// - 星级评分
/// - 图片/视频评价
/// - 追评支持
library;

import 'json_parsing.dart';

/// 评价模型
class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating; // 1-5星评分
  final String content; // 评价内容
  final List<String> images; // 评价图片
  final String? videoUrl; // 评价视频
  final bool isAnonymous; // 是否匿名
  final String? specInfo; // 购买规格信息
  final DateTime createdAt;
  final String? replyContent; // 商家回复
  final DateTime? replyAt; // 回复时间
  final String? additionalContent; // 追评内容
  final DateTime? additionalAt; // 追评时间
  final int likeCount; // 点赞数
  final bool isVerified; // 是否已验证购买

  ReviewModel({
    required this.id,
    required this.productId,
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

  /// 显示名称（匿名处理）
  String get displayName {
    if (isAnonymous) {
      if (userName.length >= 2) {
        return '${userName[0]}***';
      }
      return '匿名用户';
    }
    return userName;
  }

  /// 是否有图片
  bool get hasImages => images.isNotEmpty;

  /// 是否有视频
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// 是否有媒体内容
  bool get hasMedia => hasImages || hasVideo;

  /// 是否有追评
  bool get hasAdditional =>
      additionalContent != null && additionalContent!.isNotEmpty;

  /// 是否有商家回复
  bool get hasReply => replyContent != null && replyContent!.isNotEmpty;

  /// 评分等级文字
  String get ratingText {
    switch (rating) {
      case 5:
        return '非常满意';
      case 4:
        return '满意';
      case 3:
        return '一般';
      case 2:
        return '不满意';
      case 1:
        return '非常不满意';
      default:
        return '未知';
    }
  }

  /// 从 JSON 创建
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: jsonAsString(json['id']),
      productId: jsonAsString(json['product_id']),
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

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
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

/// 评价统计模型
class ReviewStats {
  final String productId;
  final int totalCount; // 总评价数
  final double averageRating; // 平均评分
  final int fiveStarCount; // 5星数量
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final int withImagesCount; // 有图评价数
  final int withVideoCount; // 有视频评价数
  final int additionalCount; // 追评数
  final List<String> hotTags; // 热门标签

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

  /// 好评率 (4-5星)
  double get positiveRate {
    if (totalCount == 0) return 100.0;
    return (fiveStarCount + fourStarCount) / totalCount * 100;
  }

  /// 中评率 (3星)
  double get neutralRate {
    if (totalCount == 0) return 0.0;
    return threeStarCount / totalCount * 100;
  }

  /// 差评率 (1-2星)
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

/// 评价筛选类型
enum ReviewFilter {
  all('全部'),
  withImages('有图'),
  withVideo('有视频'),
  positive('好评'),
  negative('差评'),
  additional('追评');

  final String label;
  const ReviewFilter(this.label);
}
