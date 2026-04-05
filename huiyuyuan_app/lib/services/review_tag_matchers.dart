/// Review hot-tag matcher definitions.
///
/// Match terms are business-side keywords and phrases used for aggregation.
/// The UI still renders the stable translation key stored in [labelKey].
library;

class ReviewHotTagDescriptor {
  final String labelKey;
  final List<String> matchTerms;

  const ReviewHotTagDescriptor(this.labelKey, this.matchTerms);
}

const List<ReviewHotTagDescriptor> reviewHotTagDescriptors = [
  ReviewHotTagDescriptor('review_tag_quality_good', [
    '质量好',
    '品质好',
    '做工好',
    'good quality',
  ]),
  ReviewHotTagDescriptor('review_tag_fast_shipping', [
    '发货快',
    '到货快',
    '物流快',
    'fast shipping',
  ]),
  ReviewHotTagDescriptor('review_tag_good_packaging', [
    '包装好',
    '包装精美',
    '包装严实',
    'good packaging',
  ]),
  ReviewHotTagDescriptor('review_tag_high_value', [
    '性价比高',
    '超值',
    '划算',
    'great value',
  ]),
  ReviewHotTagDescriptor('review_tag_fine_craftsmanship', [
    '做工精细',
    '工艺精细',
    '细节到位',
    'fine craftsmanship',
  ]),
  ReviewHotTagDescriptor('review_tag_smooth_texture', [
    '温润细腻',
    '手感温润',
    '质地细腻',
    'smooth texture',
  ]),
  ReviewHotTagDescriptor('review_tag_true_to_color', [
    '颜色正',
    '色泽好',
    '颜色漂亮',
    'true to color',
  ]),
  ReviewHotTagDescriptor('review_tag_worth_it', [
    '物超所值',
    '值这个价',
    '值得购买',
    'worth the price',
  ]),
  ReviewHotTagDescriptor('review_tag_great_gift', [
    '送礼佳品',
    '送礼合适',
    '适合送人',
    'great gift',
  ]),
  ReviewHotTagDescriptor('review_tag_rebuy', [
    '必回购',
    '还会再买',
    '回购',
    'would buy again',
  ]),
];
