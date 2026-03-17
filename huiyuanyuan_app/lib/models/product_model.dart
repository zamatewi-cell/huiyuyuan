/// 汇玉源 - 商品模型
library;

import 'package:flutter/material.dart';

// ============ 商品模型 ============

/// 商品材质枚举
enum MaterialType {
  hetianYu('和田玉', Color(0xFFF5F5DC)),
  jadeite('缅甸翡翠', Color(0xFF32CD32)),
  nanHong('南红玛瑙', Color(0xFFFF6347)),
  amethyst('紫水晶', Color(0xFF9370DB)),
  biyu('碧玉', Color(0xFF228B22)),
  mila('蜜蜡', Color(0xFFFFD700)),
  gold('黄金', Color(0xFFDAA520)),
  ruby('红宝石', Color(0xFFDC143C)),
  sapphire('蓝宝石', Color(0xFF4169E1));

  final String label;
  final Color color;
  const MaterialType(this.label, this.color);
}

/// 商品分类枚举
enum ProductCategory {
  bracelet('手链'),
  pendant('吊坠'),
  ring('戒指'),
  bangle('手镯'),
  necklace('项链'),
  earring('耳饰');

  final String label;
  const ProductCategory(this.label);
}

/// 商品模型
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String material;
  final List<String> images;
  final int stock;
  final double rating;
  final int salesCount;
  final bool isHot;
  final bool isNew;
  final String? origin;

  /// 区块链证书编号
  final String? certificate;

  /// 区块链溯源哈希
  final String? blockchainHash;

  /// 是否为福利款
  final bool isWelfare;

  /// 材质验证状态（天然/处理）
  final String materialVerify;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.material,
    required this.images,
    required this.stock,
    this.rating = 5.0,
    this.salesCount = 0,
    this.isHot = false,
    this.isNew = false,
    this.origin,
    this.certificate,
    this.blockchainHash,
    this.isWelfare = false,
    this.materialVerify = '天然A货',
  });

  /// 折扣率
  double get discountRate {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  /// 是否为福利款（价格在199-599之间）
  bool get isWelfarePriceRange => price >= 199 && price <= 599;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      category: json['category'] ?? '',
      material: json['material'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      stock: json['stock'] ?? 0,
      rating: (json['rating'] ?? 5.0).toDouble(),
      salesCount: json['sales_count'] ?? 0,
      isHot: json['is_hot'] ?? false,
      isNew: json['is_new'] ?? false,
      origin: json['origin'],
      certificate: json['certificate'],
      blockchainHash: json['blockchain_hash'],
      isWelfare: json['is_welfare'] ?? false,
      materialVerify: json['material_verify'] ?? '天然A货',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'category': category,
      'material': material,
      'images': images,
      'stock': stock,
      'rating': rating,
      'sales_count': salesCount,
      'is_hot': isHot,
      'is_new': isNew,
      'origin': origin,
      'certificate': certificate,
      'blockchain_hash': blockchainHash,
      'is_welfare': isWelfare,
      'material_verify': materialVerify,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? material,
    List<String>? images,
    int? stock,
    double? rating,
    int? salesCount,
    bool? isHot,
    bool? isNew,
    String? origin,
    String? certificate,
    String? blockchainHash,
    bool? isWelfare,
    String? materialVerify,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      material: material ?? this.material,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      salesCount: salesCount ?? this.salesCount,
      isHot: isHot ?? this.isHot,
      isNew: isNew ?? this.isNew,
      origin: origin ?? this.origin,
      certificate: certificate ?? this.certificate,
      blockchainHash: blockchainHash ?? this.blockchainHash,
      isWelfare: isWelfare ?? this.isWelfare,
      materialVerify: materialVerify ?? this.materialVerify,
    );
  }
}
