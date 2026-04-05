import codecs

def update_empty_state():
    p = 'lib/widgets/common/empty_state.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()

    replacements = {
        "'暂无浏览记录'": "ref.tr('profile_history_empty_title')",
        "'您还没有浏览过任何商品'": "ref.tr('profile_history_empty_subtitle')",
        "'暂无店铺数据'": "ref.tr('shop_empty_title')",
        "'店铺信息正在加载中...'": "ref.tr('shop_loading_subtitle')",
        "'刷新'": "ref.tr('refresh')",
        "'网络连接失败'": "ref.tr('network_error_title')",
        "'请检查网络设置后重试'": "ref.tr('network_error_subtitle')",
        "'这里还没有任何内容'": "ref.tr('general_empty_subtitle')",
    }

    for old, new in replacements.items():
        c = c.replace(old, new)
        
    with codecs.open(p, 'w', 'utf-8') as f:
        f.write(c)

def add_new_keys_to_app_strings():
    p = 'lib/l10n/app_strings.dart'
    with codecs.open(p, 'r', 'utf-8') as f:
        c = f.read()
    
    zh_cn = """
    // Empty State
    'profile_history_empty_title': '暂无浏览记录',
    'profile_history_empty_subtitle': '您还没有浏览过任何商品',
    'shop_empty_title': '暂无店铺数据',
    'shop_loading_subtitle': '店铺信息正在加载中...',
    'refresh': '刷新',
    'network_error_title': '网络连接失败',
    'network_error_subtitle': '请检查网络设置后重试',
    'general_empty_subtitle': '这里还没有任何内容',
    """
    
    en = """
    // Empty State
    'profile_history_empty_title': 'No History',
    'profile_history_empty_subtitle': 'You haven\\'t browsed any products yet',
    'shop_empty_title': 'No Shop Data',
    'shop_loading_subtitle': 'Loading shop information...',
    'refresh': 'Refresh',
    'network_error_title': 'Network Error',
    'network_error_subtitle': 'Please check your connection and try again',
    'general_empty_subtitle': 'Nothing here yet',
    """

    zh_tw = """
    // Empty State
    'profile_history_empty_title': '暫無瀏覽記錄',
    'profile_history_empty_subtitle': '您還沒有瀏覽過任何商品',
    'shop_empty_title': '暫無店鋪數據',
    'shop_loading_subtitle': '店鋪信息正在加載中...',
    'refresh': '刷新',
    'network_error_title': '網絡連接失敗',
    'network_error_subtitle': '請檢查網絡設置後重試',
    'general_empty_subtitle': '這裡還沒有任何內容',
    """
    
    # Insert new keys into maps
    c = c.replace("static const Map<String, String> _zhCN = {", "static const Map<String, String> _zhCN = {" + zh_cn)
    c = c.replace("static const Map<String, String> _en = {", "static const Map<String, String> _en = {" + en)
    c = c.replace("static const Map<String, String> _zhTW = {", "static const Map<String, String> _zhTW = {" + zh_tw)
    
    with codecs.open(p, 'w', 'utf-8') as f:
        f.write(c)

if __name__ == '__main__':
    add_new_keys_to_app_strings()
    update_empty_state()
    print("Empty state translation done.")
