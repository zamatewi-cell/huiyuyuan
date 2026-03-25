library;

class ProductUpsertRequest {
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String material;
  final List<String>? images;
  final int stock;
  final bool? isHot;
  final bool? isNew;
  final String? origin;
  final bool? isWelfare;
  final String? certificate;

  const ProductUpsertRequest({
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.material,
    this.images,
    required this.stock,
    this.isHot,
    this.isNew,
    this.origin,
    this.isWelfare,
    this.certificate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      if (originalPrice != null) 'original_price': originalPrice,
      'category': category,
      'material': material,
      if (images != null) 'images': images,
      'stock': stock,
      if (isHot != null) 'is_hot': isHot,
      if (isNew != null) 'is_new': isNew,
      if (origin != null) 'origin': origin,
      if (isWelfare != null) 'is_welfare': isWelfare,
      if (certificate != null) 'certificate': certificate,
    };
  }
}
