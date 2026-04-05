import re

dict_file = "lib/l10n/app_strings.dart"

with open(dict_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

sc_idx = -1
tc_idx = -1
en_idx = -1

for i, line in enumerate(lines):
    if "'zh_CN': {" in line:
        sc_idx = i
    if "'zh_TW': {" in line:
        tc_idx = i
    if "'en_US': {" in line:
        en_idx = i

sc_adds = """
    'ai_analyzing_image': 'AI正在分析图片...',
    'merchant_processing_order': '商家正在处理您的订单',
    'ai_generating_script': 'AI正在生成话术...',
    'redirecting_to_order': '正在跳转订单页...',
    'merchant_preparing_shipment': '商家正在准备发货，请耐心等待',
    'loading_recommended_products': '正在加载推荐商品...',
"""

tc_adds = """
    'ai_analyzing_image': 'AI正在分析圖片...',
    'merchant_processing_order': '商家正在處理您的訂單',
    'ai_generating_script': 'AI正在生成話術...',
    'redirecting_to_order': '正在跳轉訂單頁...',
    'merchant_preparing_shipment': '商家正在準備發貨，請耐心等待',
    'loading_recommended_products': '正在加載推薦商品...',
"""

en_adds = """
    'ai_analyzing_image': 'AI is analyzing the image...',
    'merchant_processing_order': 'Merchant is processing your order',
    'ai_generating_script': 'AI is generating the script...',
    'redirecting_to_order': 'Redirecting to order page...',
    'merchant_preparing_shipment': 'Merchant is preparing shipment, please wait patiently',
    'loading_recommended_products': 'Loading recommended products...',
"""

# Insert backwards to avoid index shifting
lines.insert(en_idx + 1, en_adds)
lines.insert(tc_idx + 1, tc_adds)
lines.insert(sc_idx + 1, sc_adds)

with open(dict_file, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Dictionary updated!")
