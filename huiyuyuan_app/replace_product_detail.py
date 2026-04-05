import codecs

with codecs.open('lib/screens/trade/product_detail_screen.dart', 'r', 'utf-8') as f:
    text = f.read()

reps = {
    "'已售 ${widget.product.salesCount}'": "ref.tr('search_sales_count').replaceAll('{n}', widget.product.salesCount.toString())",
    "'热销'": "ref.tr('product_hot')",
    "'新品'": "ref.tr('product_new')",
    "'产品信息'": "ref.tr('product_info')",
    "'证书编号'": "ref.tr('product_cert_no')",
    "'产品描述'": "ref.tr('product_description')",
    "'生成中...'": "ref.tr('product_ai_generating')",
    "'AI优化'": "ref.tr('product_ai_optimize')",
    "'服务保障'": "ref.tr('product_service_guarantee')",
    "'正品保证'": "ref.tr('product_service_authentic')",
    "'包邮'": "ref.tr('product_service_shipping')",
    "'7天无理由'": "ref.tr('product_service_return')",
    "'假一赔十'": "ref.tr('product_service_compensation')",
    "'商品评价'": "ref.tr('product_reviews')",
    "'加入购物车'": "ref.tr('product_add_to_cart')",
    "'立即购买'": "ref.tr('product_buy_now')",
    "'已加入收藏'": "ref.tr('product_added_favorite')",
    "'已取消收藏'": "ref.tr('product_removed_favorite')",
    "'已加入购物车'": "ref.tr('product_added_cart')",
    "'分享商品'": "ref.tr('product_share')",
    "'微信'": "ref.tr('share_wechat')",
    "'朋友圈'": "ref.tr('share_moments')",
    "'QQ'": "ref.tr('share_qq')",
    "'复制链接'": "ref.tr('share_link')",
    "'分享到$label'": "ref.tr('share_success_tpl').replaceAll('{label}', label)",
    "import '../../themes/colors.dart';": "import '../../themes/colors.dart';\nimport '../../providers/app_settings_provider.dart';",
}

for k, v in reps.items():
    text = text.replace(k, v)

with codecs.open('lib/screens/trade/product_detail_screen.dart', 'w', 'utf-8') as f:
    f.write(text)

print("done")
