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
  final String? appraisalNote;
  final String? appraisalNoteEn;
  final String? appraisalNoteZhTw;
  final List<String>? craftHighlights;
  final List<String>? craftHighlightsEn;
  final List<String>? craftHighlightsZhTw;
  final double? weightG;
  final String? dimensions;
  final List<String>? audienceTags;
  final List<String>? audienceTagsEn;
  final List<String>? audienceTagsZhTw;
  final String? originStory;
  final String? originStoryEn;
  final String? originStoryZhTw;
  final List<String>? flawNotes;
  final List<String>? flawNotesEn;
  final List<String>? flawNotesZhTw;
  final String? certificateAuthority;
  final String? certificateAuthorityEn;
  final String? certificateAuthorityZhTw;
  final String? certificateImageUrl;
  final String? certificateVerifyUrl;
  final List<String>? galleryDetail;
  final List<String>? galleryHand;

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
    this.appraisalNote,
    this.appraisalNoteEn,
    this.appraisalNoteZhTw,
    this.craftHighlights,
    this.craftHighlightsEn,
    this.craftHighlightsZhTw,
    this.weightG,
    this.dimensions,
    this.audienceTags,
    this.audienceTagsEn,
    this.audienceTagsZhTw,
    this.originStory,
    this.originStoryEn,
    this.originStoryZhTw,
    this.flawNotes,
    this.flawNotesEn,
    this.flawNotesZhTw,
    this.certificateAuthority,
    this.certificateAuthorityEn,
    this.certificateAuthorityZhTw,
    this.certificateImageUrl,
    this.certificateVerifyUrl,
    this.galleryDetail,
    this.galleryHand,
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
      if (appraisalNote != null) 'appraisal_note': appraisalNote,
      if (appraisalNoteEn != null) 'appraisal_note_en': appraisalNoteEn,
      if (appraisalNoteZhTw != null) 'appraisal_note_zh_tw': appraisalNoteZhTw,
      if (craftHighlights != null) 'craft_highlights': craftHighlights,
      if (craftHighlightsEn != null) 'craft_highlights_en': craftHighlightsEn,
      if (craftHighlightsZhTw != null)
        'craft_highlights_zh_tw': craftHighlightsZhTw,
      if (weightG != null) 'weight_g': weightG,
      if (dimensions != null) 'dimensions': dimensions,
      if (audienceTags != null) 'audience_tags': audienceTags,
      if (audienceTagsEn != null) 'audience_tags_en': audienceTagsEn,
      if (audienceTagsZhTw != null) 'audience_tags_zh_tw': audienceTagsZhTw,
      if (originStory != null) 'origin_story': originStory,
      if (originStoryEn != null) 'origin_story_en': originStoryEn,
      if (originStoryZhTw != null) 'origin_story_zh_tw': originStoryZhTw,
      if (flawNotes != null) 'flaw_notes': flawNotes,
      if (flawNotesEn != null) 'flaw_notes_en': flawNotesEn,
      if (flawNotesZhTw != null) 'flaw_notes_zh_tw': flawNotesZhTw,
      if (certificateAuthority != null)
        'certificate_authority': certificateAuthority,
      if (certificateAuthorityEn != null)
        'certificate_authority_en': certificateAuthorityEn,
      if (certificateAuthorityZhTw != null)
        'certificate_authority_zh_tw': certificateAuthorityZhTw,
      if (certificateImageUrl != null)
        'certificate_image_url': certificateImageUrl,
      if (certificateVerifyUrl != null)
        'certificate_verify_url': certificateVerifyUrl,
      if (galleryDetail != null) 'gallery_detail': galleryDetail,
      if (galleryHand != null) 'gallery_hand': galleryHand,
    };
  }
}
