import os
import re
import codecs

# Base strings dictionary matching app_strings.dart values to keys
# This dictionary also contains new keys to be added to app_strings.dart
translation_dict = {
    '确认订单': "ref.tr('checkout_title')",
    '请选择收货地址': "ref.tr('checkout_select_addr')",
    '商品明细': "ref.tr('checkout_items')",
    '等{}件商品': "ref.tr('checkout_multiple_items_tpl').replaceAll('{n}', '{}')",
    '支付方式': "ref.tr('checkout_payment')",
    '微信支付': "ref.tr('checkout_wechat')",
    '支付宝': "ref.tr('checkout_alipay')",
    '商品总额': "ref.tr('checkout_subtotal')",
    '运费': "ref.tr('checkout_shipping')",
    '活动优惠': "ref.tr('checkout_discount')",
    '合计': "ref.tr('checkout_total')",
    '支付并提交': "ref.tr('checkout_submit')",
    '请先选择收货地址': "ref.tr('checkout_no_addr')",
    '创建订单失败，请稍后重试': "ref.tr('checkout_fail')",
    '发现好物': "ref.tr('search_discover')",
    '热门搜索': "ref.tr('search_hot')",
    '清空': "ref.tr('search_clear')",
    '搜索历史': "ref.tr('search_history')",
    '搜索商品、材质、分类...': "ref.tr('search_hint')",
    '综合': "ref.tr('search_sort_default')",
    '价格↑': "ref.tr('search_sort_price_up')",
    '价格↓': "ref.tr('search_sort_price_down')",
    '销量': "ref.tr('search_sort_sales')",
    '我的订单': "ref.tr('order_list_title')",
    '全部': "ref.tr('order_all')",
    '待付款': "ref.tr('order_pending_payment')",
    '待发货': "ref.tr('order_pending_shipment')",
    '待收货': "ref.tr('order_pending_receipt')",
    '已完成': "ref.tr('order_completed')",
    '去发货': "ref.tr('order_ship')",
    '查看物流': "ref.tr('order_logistics')",
    '确认收货': "ref.tr('order_confirm_title')",
    '发起退货': "ref.tr('order_return')",
    '评价晒单': "ref.tr('order_review')",
    '删除订单': "ref.tr('order_delete')",
    '查看详情': "ref.tr('order_view_detail')",
    '取消订单': "ref.tr('order_cancel_title')",
    '立即付款': "ref.tr('order_pay_now')",
    '返回': "ref.tr('return')",
    '主页': "ref.tr('home')",
    '购物车': "ref.tr('cart')",
    '我的': "ref.tr('profile')",
    '首页': "ref.tr('home')",
    '商品分类': "ref.tr('category')",
    '没有更多了': "ref.tr('no_more_data')",
    '加载中...': "ref.tr('loading')",
    '出错了': "ref.tr('error')",
    
    # login_screen
    '手机号登录': "ref.tr('login_phone')",
    '管理员入口': "ref.tr('login_admin_btn')",
    '未注册手机号验证后自动创建账户': "ref.tr('login_auto_register')",
    '通过微信登录': "ref.tr('login_wechat')",
    
    # cart
    '去逛逛': "ref.tr('cart_go_shop')",
    '购物车空空如也': "ref.tr('empty_cart')",
    '快去挑选心仪的珠宝吧': "ref.tr('empty_cart_hint')",
    '清空购物车': "ref.tr('cart_clear_title')",
    '确定要清空购物车吗？': "ref.tr('cart_clear_confirm')",
    
    # admin/operator/payment etc...
    '管理后台': "ref.tr('admin_title')",
    '仪表盘': "ref.tr('admin_dashboard')",
    '商品管理': "ref.tr('admin_products')",
    '订单管理': "ref.tr('admin_orders')",
    '用户管理': "ref.tr('admin_users')",
    '操作员': "ref.tr('admin_operators')",
    '库存统计': "ref.tr('admin_inventory')",
}

def scan_and_replace():
    scan_dirs = ['lib/screens/', 'lib/widgets/']
    
    for r, dirs, files in os.walk('lib'):
        for f in files:
            if not f.endswith('.dart'): continue
            path = os.path.join(r, f)
            with codecs.open(path, 'r', 'utf-8') as fh:
                content = fh.read()
                
            orig_content = content
            for zh, replace_code in translation_dict.items():
                # naive replace for exact matches inside single or double quotes
                content = content.replace(f"'{zh}'", replace_code)
                content = content.replace(f'"{zh}"', replace_code)
                
            # Add implicit imports if needed
            if orig_content != content:
                # Need to verify if 'l10n_provider' or similar is imported
                if 'ref.tr(' in content and 'import \'../../l10n/l10n_provider.dart\'' not in content and 'import \'package:huiyuyuan_app/l10n/l10n_provider.dart\'' not in content:
                    # Very rough heuristic to add imports at top
                    pass # We will rely on existing imports or add manually if compile fails
                    
            with codecs.open(path, 'w', 'utf-8') as fh:
                fh.write(content)

if __name__ == '__main__':
    scan_and_replace()
    print("Replace done.")
