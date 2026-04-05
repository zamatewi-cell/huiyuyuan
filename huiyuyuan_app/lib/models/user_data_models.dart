library;

import 'json_parsing.dart';
import 'product_model.dart';

class BrowseHistoryItem {
  final ProductModel product;
  final DateTime? viewedAt;

  const BrowseHistoryItem({
    required this.product,
    this.viewedAt,
  });

  String get id => product.id;

  factory BrowseHistoryItem.fromJson(Map<String, dynamic> json) {
    return BrowseHistoryItem(
      product: ProductModel.fromJson(normalizeProductSummaryJson(json)),
      viewedAt: jsonAsNullableDateTime(json['viewed_at'] ?? json['viewedAt']),
    );
  }
}

Map<String, dynamic> normalizeProductSummaryJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  final images = normalized['images'];

  if (images is String) {
    normalized['images'] = <String>[images];
  } else if (images is! Iterable) {
    final image = jsonAsNullableString(normalized['image']);
    normalized['images'] = image == null ? const <String>[] : <String>[image];
  }

  return normalized;
}

List<dynamic> extractEnvelopeItems(dynamic payload) {
  if (payload is Iterable) {
    return payload.toList(growable: false);
  }

  final map = jsonAsMap(payload);
  final candidates = <dynamic>[map['items'], map['data'], map['results']];

  for (final candidate in candidates) {
    if (candidate is Iterable) {
      return candidate.toList(growable: false);
    }
  }

  return const [];
}

List<ProductModel> parseProductSummaries(dynamic payload) {
  return extractEnvelopeItems(payload)
      .map((item) =>
          ProductModel.fromJson(normalizeProductSummaryJson(jsonAsMap(item))))
      .toList(growable: false);
}

List<BrowseHistoryItem> parseBrowseHistoryItems(dynamic payload) {
  return extractEnvelopeItems(payload)
      .map((item) => BrowseHistoryItem.fromJson(jsonAsMap(item)))
      .toList(growable: false);
}
