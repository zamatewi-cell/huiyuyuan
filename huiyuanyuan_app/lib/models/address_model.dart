/// 汇玉源 - 收货地址模型
///
/// 功能:
/// - 收货地址CRUD
/// - 默认地址管理
/// - 地址校验
library;

/// 收货地址模型
class AddressModel {
  final String id;
  final String recipientName; // 收件人姓名
  final String phoneNumber; // 联系电话
  final String province; // 省份
  final String city; // 城市
  final String district; // 区/县
  final String detailAddress; // 详细地址
  final String? postalCode; // 邮政编码
  final bool isDefault; // 是否默认地址
  final String? tag; // 标签 (家/公司/学校)
  final DateTime createdAt;
  final DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.recipientName,
    required this.phoneNumber,
    required this.province,
    required this.city,
    required this.district,
    required this.detailAddress,
    this.postalCode,
    this.isDefault = false,
    this.tag,
    required this.createdAt,
    this.updatedAt,
  });

  /// 完整地址字符串
  String get fullAddress => '$province$city$district$detailAddress';

  /// 简短地址（用于列表显示）
  String get shortAddress => '$city$district';

  /// 脱敏手机号
  String get maskedPhone {
    if (phoneNumber.length >= 11) {
      return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(7)}';
    }
    return phoneNumber;
  }

  /// 从 JSON 创建
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      detailAddress: json['detail_address'] ?? '',
      postalCode: json['postal_code'],
      isDefault: json['is_default'] ?? false,
      tag: json['tag'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_name': recipientName,
      'phone_number': phoneNumber,
      'province': province,
      'city': city,
      'district': district,
      'detail_address': detailAddress,
      'postal_code': postalCode,
      'is_default': isDefault,
      'tag': tag,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 复制并修改
  AddressModel copyWith({
    String? id,
    String? recipientName,
    String? phoneNumber,
    String? province,
    String? city,
    String? district,
    String? detailAddress,
    String? postalCode,
    bool? isDefault,
    String? tag,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      detailAddress: detailAddress ?? this.detailAddress,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 校验地址是否完整
  bool get isValid {
    return recipientName.isNotEmpty &&
        phoneNumber.length >= 11 &&
        province.isNotEmpty &&
        city.isNotEmpty &&
        district.isNotEmpty &&
        detailAddress.length >= 5;
  }
}

/// 地址标签枚举
enum AddressTag {
  home('家', '🏠'),
  company('公司', '🏢'),
  school('学校', '🎓'),
  other('其他', '📍');

  final String label;
  final String emoji;
  const AddressTag(this.label, this.emoji);
}
