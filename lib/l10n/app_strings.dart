/// 汇玉源 - 多语言文本资源
///
/// 功能:
/// - 提供中文简体、英文、中文繁体三种语言的 UI 文本
/// - 通过 AppLanguage 枚举获取对应文本
/// - 仅翻译固定 UI 文本，动态数据（商品名、描述等）不翻译
library;

import '../providers/app_settings_provider.dart';

/// 多语言文本管理器
class AppStrings {
  AppStrings._();

  /// 获取当前语言对应的文本集合
  static Map<String, String> of(AppLanguage language) {
    switch (language) {
      case AppLanguage.zhCN:
        return _zhCN;
      case AppLanguage.en:
        return _en;
      case AppLanguage.zhTW:
        return _zhTW;
    }
  }

  /// 简便获取文本方法
  static String get(AppLanguage language, String key) {
    return of(language)[key] ?? of(AppLanguage.zhCN)[key] ?? key;
  }

  // ============ 简体中文 ============
  static const Map<String, String> _zhCN = {
    // 导航栏
    'nav_home': '首页',
    'nav_products': '商城',
    'nav_ai': 'AI助手',
    'nav_profile': '我的',
    'nav_admin': '管理',
    'nav_shops': '店铺',

    // 首页
    'home_title': '汇玉源',
    'home_search': '搜索珠宝玉石...',
    'home_hot': '热销推荐',
    'home_new': '新品上架',
    'home_categories': '分类浏览',

    // 商品
    'product_list': '商品列表',
    'product_detail': '商品详情',
    'product_price': '价格',
    'product_material': '材质',
    'product_origin': '产地',
    'product_category': '分类',
    'product_stock': '库存',
    'product_description': '商品描述',
    'product_certificate': '鉴定证书',
    'product_add_cart': '加入购物车',
    'product_buy_now': '立即购买',
    'product_sold_out': '已售罄',
    'product_specifications': '商品规格',
    'product_all': '全部商品',
    'product_filter': '筛选',
    'product_sort': '排序',
    'product_sort_price_asc': '价格从低到高',
    'product_sort_price_desc': '价格从高到低',
    'product_sort_popularity': '热门优先',
    'product_sort_newest': '最新上架',

    // 商品分类
    'cat_all': '全部',
    'cat_bracelet': '手链',
    'cat_pendant': '吊坠',
    'cat_ring': '戒指',
    'cat_bangle': '手镯',
    'cat_necklace': '项链',
    'cat_beads': '手串',
    'cat_earring': '耳饰',

    // 购物车
    'cart_title': '购物车',
    'cart_empty': '购物车空空如也',
    'cart_total': '合计',
    'cart_checkout': '结算',
    'cart_select_all': '全选',

    // 订单
    'order_title': '我的订单',
    'order_all': '全部',
    'order_pending_payment': '待付款',
    'order_pending_shipment': '待发货',
    'order_pending_receipt': '待收货',
    'order_pending_review': '待评价',
    'order_completed': '已完成',
    'order_cancelled': '已取消',
    'order_detail': '订单详情',
    'order_number': '订单号',
    'order_time': '下单时间',
    'order_total': '订单总额',
    'order_pay': '去支付',
    'order_cancel': '取消订单',
    'order_confirm': '确认收货',

    // 个人中心
    'profile_title': '个人中心',
    'profile_favorites': '我的收藏',
    'profile_favorites_desc': '查看收藏的商品',
    'profile_address': '收货地址',
    'profile_address_desc': '管理收货地址',
    'profile_history': '浏览记录',
    'profile_history_desc': '查看浏览过的商品',
    'profile_payment': '收款账户',
    'profile_payment_desc': '管理支付宝/微信/银行卡',
    'profile_reminder': '提醒设置',
    'profile_reminder_desc': '设置提醒事项和自定义铃声',
    'profile_today_orders': '今日订单',
    'profile_monthly_sales': '本月业绩',
    'profile_pending': '待处理',
    'profile_account_mgmt': '账户管理',
    'profile_function_settings': '功能设置',
    'profile_about': '关于',

    // 设置
    'settings_language': '语言设置',
    'settings_theme': '主题设置',
    'settings_dark_mode': '深色模式',
    'settings_cache': '缓存管理',
    'settings_clear_cache': '清除缓存',
    'settings_cache_desc': '包含图片缓存、网络缓存等',
    'settings_cache_warning': '清除后可能需要重新加载部分内容',
    'settings_privacy': '隐私政策',
    'settings_agreement': '用户协议',
    'settings_about': '关于我们',

    // 枚举值翻译
    'theme_dark': '深色模式',
    'theme_light': '浅色模式',
    'theme_system': '跟随系统',
    'lang_zh': '简体中文',
    'lang_en': 'English',
    'lang_tw': '繁体中文',

    // AI 助手
    'ai_title': '汇玉源智能助手',
    'ai_clear': '清空对话',
    'ai_clear_confirm': '确定要清空所有对话记录吗？',
    'ai_input_hint': '输入您的问题...',
    'ai_thinking': '正在思考',
    'ai_copied': '已复制到剪贴板',
    'ai_copy': '复制',
    'ai_offline': '网络连接不稳定，已切换到离线模式',
    'ai_welcome':
        '您好！我是汇玉源智能助手 🌟\n\n我可以帮您：\n• 推荐适合您的珠宝款式\n• 解答玉石鉴别相关问题\n• 分析珠宝市场行情趋势\n• 查询订单和物流信息\n\nPlease ask me anything!',
    'ai_quick_1': '和田玉怎么鉴别真假？',
    'ai_quick_2': '翡翠保养注意什么？',
    'ai_quick_3': '500元预算推荐什么？',
    'ai_quick_4': '最近玉石行情如何？',
    'ai_quick_5': '南红和玛瑙有什么区别？',
    'ai_quick_6': '你们有哪些热门手链？',
    'ai_quick_7': '黄金首饰怎么选？',
    'ai_quick_8': '珠宝送礼怎么挑？',

    // 管理后台
    'admin_title': '管理后台',
    'admin_dashboard': '仪表盘',
    'admin_products': '商品管理',
    'admin_orders': '订单管理',
    'admin_users': '用户管理',
    'admin_operators': '操作员',
    'admin_add_product': '添加商品',
    'admin_edit_product': '编辑商品',
    'admin_delete_product': '删除商品',
    'admin_quick_actions': '快捷操作',
    'admin_system_status': '系统状态',
    'admin_audit_log': '审计日志',
    'admin_account_settings': '账户设置',
    'admin_blockchain_verify': '区块链查证',

    // 操作员工作台
    'work_today_stats': '今日数据',
    'work_todo_list': '待办任务',
    'work_quick_features': '快捷功能',
    'work_recent_contacts': '最近联系',
    'work_contact_shop': '联系店铺',
    'work_interest': '成交意向',
    'work_cooperation': '成功合作',
    'work_ai_usage': 'AI使用',
    'work_order_amount': '订单金额',
    'work_new_customer': '新增客户',
    'work_online': '在线',
    'work_working': '工作中',
    'work_ai_client': 'AI获客',
    'work_ai_script': 'AI话术',
    'work_ar_tryon': 'AR试戴',
    'work_traceability': '溯源查证',
    'work_img_analysis': '图片分析',
    'work_import_chat': '导入聊天',

    // 通用
    'confirm': '确认',
    'cancel': '取消',
    'save': '保存',
    'delete': '删除',
    'edit': '编辑',
    'close': '关闭',
    'loading': '加载中...',
    'error': '出错了',
    'retry': '重试',
    'success': '成功',
    'logout': '退出登录',
    'logout_confirm': '确认退出',
    'logout_message': '确定要退出当前账号吗？',
    'logout_button': '确认退出',
    'search': '搜索',
    'no_data': '暂无数据',
    'view_all': '查看全部',
    'switched_to': '已切换为',
    'cache_cleared': '已清除',
    'cache_unit': 'MB 缓存',
    'reminder_saved': '提醒设置已保存',

    // 合规
    'compliance_cert': '等保三级认证 · 数据加密存储',
    'compliance_copyright': '© 2026 汇玉源 · 中国境内合规运营',
    'app_description': '珠宝玉石全产业链 AI 平台',
    'app_features': '区块链溯源 · AI智能鉴定 · 全链路服务',

    // 角色
    'role_admin': '超级管理员',
    'role_operator': '操作员',
  };

  // ============ English ============
  static const Map<String, String> _en = {
    // Navigation
    'nav_home': 'Home',
    'nav_products': 'Shop',
    'nav_ai': 'AI Assistant',
    'nav_profile': 'Profile',
    'nav_admin': 'Admin',
    'nav_shops': 'Shops',

    // Home
    'home_title': 'Hui Yu Yuan',
    'home_search': 'Search jewelry...',
    'home_hot': 'Hot Picks',
    'home_new': 'New Arrivals',
    'home_categories': 'Categories',

    // Products
    'product_list': 'Products',
    'product_detail': 'Product Details',
    'product_price': 'Price',
    'product_material': 'Material',
    'product_origin': 'Origin',
    'product_category': 'Category',
    'product_stock': 'Stock',
    'product_description': 'Description',
    'product_certificate': 'Certificate',
    'product_add_cart': 'Add to Cart',
    'product_buy_now': 'Buy Now',
    'product_sold_out': 'Sold Out',
    'product_specifications': 'Specifications',
    'product_all': 'All Products',
    'product_filter': 'Filter',
    'product_sort': 'Sort',
    'product_sort_price_asc': 'Price: Low to High',
    'product_sort_price_desc': 'Price: High to Low',
    'product_sort_popularity': 'Popularity',
    'product_sort_newest': 'Newest',

    // Categories
    'cat_all': 'All',
    'cat_bracelet': 'Bracelet',
    'cat_pendant': 'Pendant',
    'cat_ring': 'Ring',
    'cat_bangle': 'Bangle',
    'cat_necklace': 'Necklace',
    'cat_beads': 'Beads',
    'cat_earring': 'Earring',

    // Cart
    'cart_title': 'Cart',
    'cart_empty': 'Your cart is empty',
    'cart_total': 'Total',
    'cart_checkout': 'Checkout',
    'cart_select_all': 'Select All',

    // Orders
    'order_title': 'My Orders',
    'order_all': 'All',
    'order_pending_payment': 'Pending Payment',
    'order_pending_shipment': 'Pending Shipment',
    'order_pending_receipt': 'Pending Receipt',
    'order_pending_review': 'Pending Review',
    'order_completed': 'Completed',
    'order_cancelled': 'Cancelled',
    'order_detail': 'Order Details',
    'order_number': 'Order No.',
    'order_time': 'Order Time',
    'order_total': 'Order Total',
    'order_pay': 'Pay Now',
    'order_cancel': 'Cancel Order',
    'order_confirm': 'Confirm Receipt',

    // Profile
    'profile_title': 'Profile',
    'profile_favorites': 'Favorites',
    'profile_favorites_desc': 'View your saved items',
    'profile_address': 'Addresses',
    'profile_address_desc': 'Manage shipping addresses',
    'profile_history': 'Browsing History',
    'profile_history_desc': 'View recently browsed items',
    'profile_payment': 'Payment Accounts',
    'profile_payment_desc': 'Manage Alipay/WeChat/Bank cards',
    'profile_reminder': 'Reminders',
    'profile_reminder_desc': 'Set reminders and custom alerts',
    'profile_today_orders': 'Today\'s Orders',
    'profile_monthly_sales': 'Monthly Sales',
    'profile_pending': 'Pending',
    'profile_account_mgmt': 'Account',
    'profile_function_settings': 'Settings',
    'profile_about': 'About',

    // Settings
    'settings_language': 'Language',
    'settings_theme': 'Theme',
    'settings_dark_mode': 'Dark Mode',
    'settings_cache': 'Cache',
    'settings_clear_cache': 'Clear Cache',
    'settings_cache_desc': 'Includes image and network cache',
    'settings_cache_warning': 'Some content may need to reload after clearing',
    'settings_privacy': 'Privacy Policy',
    'settings_agreement': 'Terms of Service',
    'settings_about': 'About Us',

    // Enum Values
    'theme_dark': 'Dark Mode',
    'theme_light': 'Light Mode',
    'theme_system': 'System Default',
    'lang_zh': 'Simplified Chinese',
    'lang_en': 'English',
    'lang_tw': 'Traditional Chinese',

    // AI Assistant
    'ai_title': 'AI Assistant',
    'ai_clear': 'Clear Chat',
    'ai_clear_confirm': 'Clear all chat history?',
    'ai_input_hint': 'Ask a question...',
    'ai_thinking': 'Thinking',
    'ai_copied': 'Copied to clipboard',
    'ai_copy': 'Copy',
    'ai_offline': 'Connection unstable, switched to offline mode',
    'ai_welcome':
        'Hello! I am Hui Yu Yuan AI Assistant 🌟\n\nI can help you with:\n• Recommending jewelry styles\n• Answering jade authentication questions\n• Analyzing market trends\n• Checking orders and logistics\n\nHow can I help you today?',
    'ai_quick_1': 'How to identify authentic Hetian jade?',
    'ai_quick_2': 'Tips for maintaining jadeite?',
    'ai_quick_3': 'Recommendations under ¥500?',
    'ai_quick_4': 'How is the jade market recently?',
    'ai_quick_5': 'Diff between Southern Red & Agate?',
    'ai_quick_6': 'What are your popular bracelets?',
    'ai_quick_7': 'How to choose gold jewelry?',
    'ai_quick_8': 'Tips for picking jewelry gifts?',

    // Admin
    'admin_title': 'Admin Panel',
    'admin_dashboard': 'Dashboard',
    'admin_products': 'Products',
    'admin_orders': 'Orders',
    'admin_users': 'Users',
    'admin_operators': 'Operators',
    'admin_add_product': 'Add Product',
    'admin_edit_product': 'Edit Product',
    'admin_delete_product': 'Delete Product',
    'admin_quick_actions': 'Quick Actions',
    'admin_system_status': 'System Status',
    'admin_audit_log': 'Audit Log',
    'admin_account_settings': 'Account Settings',
    'admin_blockchain_verify': 'Blockchain Verify',

    // Operator Workbench
    'work_today_stats': "Today's Stats",
    'work_todo_list': 'To-Do List',
    'work_quick_features': 'Quick Features',
    'work_recent_contacts': 'Recent Contacts',
    'work_contact_shop': 'Contacted Shops',
    'work_interest': 'Intended Deals',
    'work_cooperation': 'Cooperation',
    'work_ai_usage': 'AI Usage',
    'work_order_amount': 'Order Amount',
    'work_new_customer': 'New Customers',
    'work_online': 'Online',
    'work_working': 'Working',
    'work_ai_client': 'AI Client Lead',
    'work_ai_script': 'AI Scripts',
    'work_ar_tryon': 'AR Try-on',
    'work_traceability': 'Traceability',
    'work_img_analysis': 'Img Analysis',
    'work_import_chat': 'Import Chat',

    // General
    'confirm': 'Confirm',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'close': 'Close',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'success': 'Success',
    'logout': 'Logout',
    'logout_confirm': 'Confirm Logout',
    'logout_message': 'Are you sure you want to logout?',
    'logout_button': 'Logout',
    'search': 'Search',
    'no_data': 'No data available',
    'view_all': 'View All',
    'switched_to': 'Switched to',
    'cache_cleared': 'Cleared',
    'cache_unit': 'MB cache',
    'reminder_saved': 'Reminder settings saved',

    // Compliance
    'compliance_cert': 'Level 3 Security · Encrypted Storage',
    'compliance_copyright': '© 2026 Hui Yu Yuan · China Operations',
    'app_description': 'AI-Powered Jewelry Platform',
    'app_features': 'Blockchain Tracing · AI Authentication · Full Service',

    // Roles
    'role_admin': 'Super Admin',
    'role_operator': 'Operator',
  };

  // ============ 繁體中文 ============
  static const Map<String, String> _zhTW = {
    // 導航欄
    'nav_home': '首頁',
    'nav_products': '商城',
    'nav_ai': 'AI助手',
    'nav_profile': '我的',
    'nav_admin': '管理',
    'nav_shops': '店鋪',

    // 首頁
    'home_title': '匯玉源',
    'home_search': '搜索珠寶玉石...',
    'home_hot': '熱銷推薦',
    'home_new': '新品上架',
    'home_categories': '分類瀏覽',

    // 商品
    'product_list': '商品列表',
    'product_detail': '商品詳情',
    'product_price': '價格',
    'product_material': '材質',
    'product_origin': '產地',
    'product_category': '分類',
    'product_stock': '庫存',
    'product_description': '商品描述',
    'product_certificate': '鑒定證書',
    'product_add_cart': '加入購物車',
    'product_buy_now': '立即購買',
    'product_sold_out': '已售罄',
    'product_specifications': '商品規格',
    'product_all': '全部商品',
    'product_filter': '篩選',
    'product_sort': '排序',
    'product_sort_price_asc': '價格從低到高',
    'product_sort_price_desc': '價格從高到低',
    'product_sort_popularity': '熱門優先',
    'product_sort_newest': '最新上架',

    // 商品分類
    'cat_all': '全部',
    'cat_bracelet': '手鍊',
    'cat_pendant': '吊墜',
    'cat_ring': '戒指',
    'cat_bangle': '手鐲',
    'cat_necklace': '項鍊',
    'cat_beads': '手串',
    'cat_earring': '耳飾',

    // 購物車
    'cart_title': '購物車',
    'cart_empty': '購物車空空如也',
    'cart_total': '合計',
    'cart_checkout': '結算',
    'cart_select_all': '全選',

    // 訂單
    'order_title': '我的訂單',
    'order_all': '全部',
    'order_pending_payment': '待付款',
    'order_pending_shipment': '待發貨',
    'order_pending_receipt': '待收貨',
    'order_pending_review': '待評價',
    'order_completed': '已完成',
    'order_cancelled': '已取消',
    'order_detail': '訂單詳情',
    'order_number': '訂單號',
    'order_time': '下單時間',
    'order_total': '訂單總額',
    'order_pay': '去支付',
    'order_cancel': '取消訂單',
    'order_confirm': '確認收貨',

    // 個人中心
    'profile_title': '個人中心',
    'profile_favorites': '我的收藏',
    'profile_favorites_desc': '查看收藏的商品',
    'profile_address': '收貨地址',
    'profile_address_desc': '管理收貨地址',
    'profile_history': '瀏覽記錄',
    'profile_history_desc': '查看瀏覽過的商品',
    'profile_payment': '收款賬戶',
    'profile_payment_desc': '管理支付寶/微信/銀行卡',
    'profile_reminder': '提醒設置',
    'profile_reminder_desc': '設置提醒事項和自定義鈴聲',
    'profile_today_orders': '今日訂單',
    'profile_monthly_sales': '本月業績',
    'profile_pending': '待處理',
    'profile_account_mgmt': '賬戶管理',
    'profile_function_settings': '功能設置',
    'profile_about': '關於',

    // 設置
    'settings_language': '語言設置',
    'settings_theme': '主題設置',
    'settings_dark_mode': '深色模式',
    'settings_cache': '緩存管理',
    'settings_clear_cache': '清除緩存',
    'settings_cache_desc': '包含圖片緩存、網絡緩存等',
    'settings_cache_warning': '清除後可能需要重新加載部分內容',
    'settings_privacy': '隱私政策',
    'settings_agreement': '用戶協議',
    'settings_about': '關於我們',

    // 枚舉值翻譯
    'theme_dark': '深色模式',
    'theme_light': '淺色模式',
    'theme_system': '跟隨系統',
    'lang_zh': '簡體中文',
    'lang_en': 'English',
    'lang_tw': '繁體中文',

    // AI 助手
    'ai_title': '匯玉源智能助手',
    'ai_clear': '清空對話',
    'ai_clear_confirm': '確定要清空所有對話記錄嗎？',
    'ai_input_hint': '輸入您的問題...',
    'ai_thinking': '正在思考',
    'ai_copied': '已複製到剪貼簿',
    'ai_copy': '複製',
    'ai_offline': '網絡連接不穩定，已切換到離線模式',
    'ai_welcome':
        '您好！我是匯玉源智能助手 🌟\n\n我可以幫您：\n• 推薦適合您的珠寶款式\n• 解答玉石鑒別相關問題\n• 分析珠寶市場行情趨勢\n• 查詢訂單和物流信息\n\n請問有什麼可以幫您？',
    'ai_quick_1': '和田玉怎麼鑒別真假？',
    'ai_quick_2': '翡翠保養注意什麼？',
    'ai_quick_3': '500元預算推薦什麼？',
    'ai_quick_4': '最近玉石行情如何？',
    'ai_quick_5': '南紅和瑪瑙有什麼區別？',
    'ai_quick_6': '你們有哪些熱門手鏈？',
    'ai_quick_7': '黃金首飾怎麼選？',
    'ai_quick_8': '珠寶送禮怎麼挑？',

    // 管理後台
    'admin_title': '管理後台',
    'admin_dashboard': '儀表盤',
    'admin_products': '商品管理',
    'admin_orders': '訂單管理',
    'admin_users': '用戶管理',
    'admin_operators': '操作員',
    'admin_add_product': '添加商品',
    'admin_edit_product': '編輯商品',
    'admin_delete_product': '刪除商品',
    'admin_quick_actions': '快捷操作',
    'admin_system_status': '系統狀態',
    'admin_audit_log': '審計日誌',
    'admin_account_settings': '賬戶設置',
    'admin_blockchain_verify': '區塊鏈查證',

    // 操作員工作台
    'work_today_stats': '今日數據',
    'work_todo_list': '待辦任務',
    'work_quick_features': '快捷功能',
    'work_recent_contacts': '最近聯繫',
    'work_contact_shop': '聯繫店鋪',
    'work_interest': '成交意向',
    'work_cooperation': '成功合作',
    'work_ai_usage': 'AI使用',
    'work_order_amount': '訂單金額',
    'work_new_customer': '新增客戶',
    'work_online': '在線',
    'work_working': '工作中',
    'work_ai_client': 'AI獲客',
    'work_ai_script': 'AI話術',
    'work_ar_tryon': 'AR試戴',
    'work_traceability': '溯源查證',
    'work_img_analysis': '圖片分析',
    'work_import_chat': '導入聊天',

    // 通用
    'confirm': '確認',
    'cancel': '取消',
    'save': '儲存',
    'delete': '刪除',
    'edit': '編輯',
    'close': '關閉',
    'loading': '載入中...',
    'error': '出錯了',
    'retry': '重試',
    'success': '成功',
    'logout': '退出登錄',
    'logout_confirm': '確認退出',
    'logout_message': '確定要退出當前賬號嗎？',
    'logout_button': '確認退出',
    'search': '搜索',
    'no_data': '暫無數據',
    'view_all': '查看全部',
    'switched_to': '已切換為',
    'cache_cleared': '已清除',
    'cache_unit': 'MB 緩存',
    'reminder_saved': '提醒設置已保存',

    // 合規
    'compliance_cert': '等保三級認證 · 數據加密存儲',
    'compliance_copyright': '© 2026 匯玉源 · 中國境內合規運營',
    'app_description': '珠寶玉石全產業鏈 AI 平台',
    'app_features': '區塊鏈溯源 · AI智能鑒定 · 全鏈路服務',

    // 角色
    'role_admin': '超級管理員',
    'role_operator': '操作員',
  };
}
