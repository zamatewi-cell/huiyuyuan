import os

files = [
    "lib/widgets/image/image_picker_widget.dart",
    "lib/services/order_service.dart",
    "lib/screens/shop/shop_radar.dart",
    "lib/screens/payment/payment_screen.dart",
    "lib/screens/order/order_detail_screen.dart",
    "lib/screens/chat/ai_assistant_screen.dart"
]

import re

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # We replace ANY ref.tr('ai_analyzing_image') etc that was put there incorrectly
    keys = ['ai_analyzing_image', 'merchant_processing_order', 'ai_generating_script', 'redirecting_to_order', 'merchant_preparing_shipment', 'loading_recommended_products']
    for k in keys:
        content = content.replace(f"ref.tr('{k}')", f"TranslatorGlobal.instance.translate('{k}')")
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

print("Fixed ref.tr bugs!")
