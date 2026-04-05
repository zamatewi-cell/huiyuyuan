import os
import codecs
import re

def update_app_strings():
    p = 'lib/l10n/app_strings.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()
    
    # Dicts of new keys
    zh_cn = """
    // Admin Dashboard
    'greeting_morning': '早上好',
    'greeting_afternoon': '下午好',
    'greeting_evening': '晚上好',
    'admin_default_name': '管理员',
    'shop_main_name': '汇玉源珠宝总店',
    'shop_status_desc': '商品 {count} 件 · 运营正常',
    'admin_total_orders': '共 {count} 单',
    'admin_product_count': '商品总数',
    'admin_all_on_sale': '全部上架中',
    'admin_shipped_orders_count': '已发货 {count} 单',
    'admin_product_categories': '商品种类',
    'admin_jewelry_desc': '珠宝首饰',
    'admin_restock_suggestion': '智能补货建议',
    'admin_items_to_restock': '{count}件待补',
    'admin_view_all_items': '查看全部 {count} 件 →',
    'admin_urgency_out_of_stock': '断货',
    'admin_urgency_critical': '紧急',
    'admin_urgency_suggested': '建议',
    'admin_stock_count': '库存: {count}',
    'admin_suggested_restock': '建议补 {count}',
    'admin_realtime_news': '实时动态',
    'admin_auto_update_desc': '每30分钟自动更新',
    'admin_tag_orders': '订单',
    'admin_tag_system': '系统',
    'admin_tag_ai': 'AI',
    'admin_inventory_mgmt': '库存管理',
    'admin_api_service': 'API 服务',
    'admin_running_normal': '正常运行',
    'admin_ai_engine': 'AI 引擎',
    'admin_dashscope_online': 'DashScope 在线',
    'admin_available': '可用',
    'admin_blockchain_node': '区块链节点',
    'admin_connected': '已连接',
    'admin_syncing': '同步中',
    'admin_data_backup': '数据备份',
    'admin_3hours_ago': '3小时前',
    'admin_compliance_footer': '等保三级认证 · 数据加密传输 · 可用率 99.9%',

    // Promotional Banner
    'promo_banner_welfare': '福利款手链专场',
    'promo_banner_welfare_desc': '天然材质 · 199元起',
    'promo_banner_jade': '极品翡翠鉴赏',
    'promo_banner_jade_desc': '传承东方美学',
    'promo_banner_diamond': '婚戒定制服务',
    'promo_banner_diamond_desc': '见证永恒誓言',

    // Shop Categories & UI
    'shop_hot_picks': '热销推荐',
    'shop_view_all': '查看全部 >',
    """
    
    en = """
    // Admin Dashboard
    'greeting_morning': 'Good morning',
    'greeting_afternoon': 'Good afternoon',
    'greeting_evening': 'Good evening',
    'admin_default_name': 'Admin',
    'shop_main_name': 'Huiyuyuan Main Store',
    'shop_status_desc': '{count} Products · Running',
    'admin_total_orders': '{count} Total Orders',
    'admin_product_count': 'Total Products',
    'admin_all_on_sale': 'All On Sale',
    'admin_shipped_orders_count': '{count} Shipped Orders',
    'admin_product_categories': 'Product Categories',
    'admin_jewelry_desc': 'Jewelry & Accessories',
    'admin_restock_suggestion': 'Restock Suggestions',
    'admin_items_to_restock': '{count} Items Pending',
    'admin_view_all_items': 'View all {count} items →',
    'admin_urgency_out_of_stock': 'OOS',
    'admin_urgency_critical': 'Critical',
    'admin_urgency_suggested': 'Suggest',
    'admin_stock_count': 'Stock: {count}',
    'admin_suggested_restock': 'Suggest: {count}',
    'admin_realtime_news': 'Realtime News',
    'admin_auto_update_desc': 'Auto-updated every 30m',
    'admin_tag_orders': 'Orders',
    'admin_tag_system': 'System',
    'admin_tag_ai': 'AI',
    'admin_inventory_mgmt': 'Inventory Mgmt',
    'admin_api_service': 'API Service',
    'admin_running_normal': 'Running',
    'admin_ai_engine': 'AI Engine',
    'admin_dashscope_online': 'DashScope Online',
    'admin_available': 'Available',
    'admin_blockchain_node': 'Blockchain Node',
    'admin_connected': 'Connected',
    'admin_syncing': 'Syncing',
    'admin_data_backup': 'Data Backup',
    'admin_3hours_ago': '3 hours ago',
    'admin_compliance_footer': 'Level 3 Security · Encrypted · 99.9% Uptime',

    // Promotional Banner
    'promo_banner_welfare': 'Special Bracelet Sale',
    'promo_banner_welfare_desc': 'Natural materials · From 199',
    'promo_banner_jade': 'Premium Jade Collection',
    'promo_banner_jade_desc': 'Oriental Aesthetics',
    'promo_banner_diamond': 'Wedding Ring Customization',
    'promo_banner_diamond_desc': 'Witness Eternal Vows',

    // Shop Categories & UI
    'shop_hot_picks': 'Hot Picks',
    'shop_view_all': 'View All >',
    """

    zh_tw = zh_cn.replace('简体中文', '簡體中文').replace('商品总数', '商品總數').replace('商品种类', '商品種類')
    zh_tw = zh_tw.replace('实时动态', '實時動態').replace('每30分钟自动更新', '每30分鐘自動更新')
    zh_tw = zh_tw.replace('订单', '訂單').replace('系统', '系統').replace('库存管理', '庫存管理')
    zh_tw = zh_tw.replace('正常运行', '正常運行').replace('可用', '可用').replace('区块链节点', '區塊鏈節點')
    zh_tw = zh_tw.replace('已连接', '已連接').replace('同步中', '同步中').replace('数据备份', '數據備份')
    zh_tw = zh_tw.replace('等保三级认证 · 数据加密传输 · 可用率 99.9%', '等保三級認證 · 數據加密傳輸 · 可用率 99.9%')
    
    # Insert new keys into maps
    c = c.replace("static const Map<String, String> _zhCN = {", "static const Map<String, String> _zhCN = {" + zh_cn)
    c = c.replace("static const Map<String, String> _en = {", "static const Map<String, String> _en = {" + en)
    c = c.replace("static const Map<String, String> _zhTW = {", "static const Map<String, String> _zhTW = {" + zh_tw)
    
    with codecs.open(p, 'w', 'utf-8') as f:
        f.write(c)


def translate_admin_dashboard():
    p = 'lib/screens/admin/admin_dashboard.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()

    replacements = {
        "'早上好'": "ref.tr('greeting_morning')",
        "'下午好'": "ref.tr('greeting_afternoon')",
        "'晚上好'": "ref.tr('greeting_evening')",
        "'管理员'": "ref.tr('admin_default_name')",
        "'汇玉源珠宝总店'": "ref.tr('shop_main_name')",
        "'商品 ${_stats?.totalProducts ?? catalogProductCount} 件 · 运营正常'": "ref.tr('shop_status_desc').replaceFirst('{count}', '${_stats?.totalProducts ?? catalogProductCount}')",
        "'共 $totalOrders 单'": "ref.tr('admin_total_orders').replaceFirst('{count}', '$totalOrders')",
        "'商品总数'": "ref.tr('admin_product_count')",
        "'全部上架中'": "ref.tr('admin_all_on_sale')",
        "'已发货 $shippedCount 单'": "ref.tr('admin_shipped_orders_count').replaceFirst('{count}', '$shippedCount')",
        "'商品种类'": "ref.tr('admin_product_categories')",
        "'珠宝首饰'": "ref.tr('admin_jewelry_desc')",
        "'智能补货建议'": "ref.tr('admin_restock_suggestion')",
        "'${_restockSuggestions.length}件待补'": "ref.tr('admin_items_to_restock').replaceFirst('{count}', '${_restockSuggestions.length}')",
        "'查看全部 ${_restockSuggestions.length} 件 →'": "ref.tr('admin_view_all_items').replaceFirst('{count}', '${_restockSuggestions.length}')",
        "'断货'": "ref.tr('admin_urgency_out_of_stock')",
        "'紧急'": "ref.tr('admin_urgency_critical')",
        "'建议'": "ref.tr('admin_urgency_suggested')",
        "'库存: ${suggestion.currentStock}'": "ref.tr('admin_stock_count').replaceFirst('{count}', '${suggestion.currentStock}')",
        "'建议补 ${suggestion.suggestedQuantity}'": "ref.tr('admin_suggested_restock').replaceFirst('{count}', '${suggestion.suggestedQuantity}')",
        "'实时动态'": "ref.tr('admin_realtime_news')",
        "'每30分钟自动更新'": "ref.tr('admin_auto_update_desc')",
        "'订单'": "ref.tr('admin_tag_orders')",
        "'系统'": "ref.tr('admin_tag_system')",
        "'AI'": "ref.tr('admin_tag_ai')",
        "'库存管理'": "ref.tr('admin_inventory_mgmt')",
        "'API 服务'": "ref.tr('admin_api_service')",
        "'正常运行'": "ref.tr('admin_running_normal')",
        "'AI 引擎'": "ref.tr('admin_ai_engine')",
        "'DashScope 在线'": "ref.tr('admin_dashscope_online')",
        "'可用'": "ref.tr('admin_available')",
        "'区块链节点'": "ref.tr('admin_blockchain_node')",
        "'已连接'": "ref.tr('admin_connected')",
        "'同步中'": "ref.tr('admin_syncing')",
        "'数据备份'": "ref.tr('admin_data_backup')",
        "'3小时前'": "ref.tr('admin_3hours_ago')",
        "'等保三级认证 · 数据加密传输 · 可用率 99.9%'": "ref.tr('admin_compliance_footer')",
    }

    for old, new in replacements.items():
        c = c.replace(old, new)
        
    with codecs.open(p, 'w', 'utf-8') as f:
        f.write(c)

def translate_promotion_banner():
    p = 'lib/widgets/promotional_banner.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()

    replacements = {
        "'福利款手链专场'": "ref.tr('promo_banner_welfare')",
        "'天然材质 · 199元起'": "ref.tr('promo_banner_welfare_desc')",
        "'极品翡翠鉴赏'": "ref.tr('promo_banner_jade')",
        "'传承东方美学'": "ref.tr('promo_banner_jade_desc')",
        "'婚戒定制服务'": "ref.tr('promo_banner_diamond')",
        "'见证永恒誓言'": "ref.tr('promo_banner_diamond_desc')",
    }

    for old, new in replacements.items():
        c = c.replace(old, new)
        
    with codecs.open(p, 'w', 'utf-8') as f:
        f.write(c)

def fix_profile_keys():
    # Fix order_list_title in app_strings.dart
    p = 'lib/l10n/app_strings.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()
    c = c.replace("'order_title': '我的订单',", "'order_title': '我的订单',\n    'order_list_title': '我的订单',")
    c = c.replace("'order_title': 'My Orders',", "'order_title': 'My Orders',\n    'order_list_title': 'My Orders',")
    c = c.replace("'order_title': '我的訂單',", "'order_title': '我的訂單',\n    'order_list_title': '我的訂單',")
    with codecs.open(p, 'w', 'utf-8') as f:
        f.write(c)

if __name__ == '__main__':
    update_app_strings()
    translate_admin_dashboard()
    translate_promotion_banner()
    fix_profile_keys()
    print("Dashboard and Banner translation done.")
