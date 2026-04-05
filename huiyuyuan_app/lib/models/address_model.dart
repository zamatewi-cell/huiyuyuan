library;

import 'json_parsing.dart';

class AddressModel {
  final String id;
  final String recipientName;
  final String phoneNumber;
  final String province;
  final String city;
  final String district;
  final String detailAddress;
  final String? postalCode;
  final bool isDefault;
  final String? tag;
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

  String get fullAddress => '$province$city$district$detailAddress';

  String get shortAddress => '$city$district';

  String get maskedPhone {
    if (phoneNumber.length >= 11) {
      return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(7)}';
    }
    return phoneNumber;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: jsonAsString(json['id']),
      recipientName: jsonAsString(json['recipient_name']),
      phoneNumber: jsonAsString(json['phone_number']),
      province: jsonAsString(json['province']),
      city: jsonAsString(json['city']),
      district: jsonAsString(json['district']),
      detailAddress: jsonAsString(json['detail_address']),
      postalCode: jsonAsNullableString(json['postal_code']),
      isDefault: jsonAsBool(json['is_default']),
      tag: jsonAsNullableString(json['tag']),
      createdAt: jsonAsDateTime(json['created_at']),
      updatedAt: jsonAsNullableDateTime(json['updated_at']),
    );
  }

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

  bool get isValid {
    return recipientName.isNotEmpty &&
        phoneNumber.length >= 11 &&
        province.isNotEmpty &&
        city.isNotEmpty &&
        district.isNotEmpty &&
        detailAddress.length >= 5;
  }
}

enum AddressTag {
  home('address_tag_home', '🏠'),
  company('address_tag_company', '🏢'),
  school('address_tag_school', '🏫'),
  other('address_tag_other', '📍');

  final String label;
  final String emoji;

  const AddressTag(this.label, this.emoji);
}
