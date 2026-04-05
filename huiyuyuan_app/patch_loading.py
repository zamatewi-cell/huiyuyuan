import re
import os

files = {
    "lib/widgets/image/image_picker_widget.dart": "AI正在分析图片...",
    "lib/services/order_service.dart": "商家正在处理您的订单",
    "lib/screens/shop/shop_radar.dart": "AI正在生成话术...",
    "lib/screens/payment/payment_screen.dart": "正在跳转订单页...",
    "lib/screens/order/order_detail_screen.dart": "商家正在准备发货，请耐心等待",
    "lib/screens/chat/ai_assistant_screen.dart": "正在加载推荐商品..."
}

keys = {
    "AI正在分析图片...": "ai_analyzing_image",
    "商家正在处理您的订单": "merchant_processing_order",
    "AI正在生成话术...": "ai_generating_script",
    "正在跳转订单页...": "redirecting_to_order",
    "商家正在准备发货，请耐心等待": "merchant_preparing_shipment",
    "正在加载推荐商品...": "loading_recommended_products"
}

def do_patch():
    for filepath, original_text in files.items():
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Determine the correct translation accessor
        if "ref.tr" in content or "WidgetRef" in content or "Consumer" in content:
            if "TranslatorGlobal.instance" not in content and filepath == "lib/services/order_service.dart":
                # order_service won't have ref!
                content = "import 'package:huiyuyuan_app/l10n/translator_global.dart';\n" + content
                replacement = f"TranslatorGlobal.instance.translate('{keys[original_text]}')"
            else:
                # Use ref.tr if possible, or TranslatorGlobal
                if "dart:ui" not in content and "TranslatorGlobal" not in content and "ref." not in content:
                     replacement = f"TranslatorGlobal.instance.translate('{keys[original_text]}')"
                     content = "import 'package:huiyuyuan_app/l10n/translator_global.dart';\n" + content
                else:
                    if 'ref.' in content:
                        replacement = f"ref.tr('{keys[original_text]}')"
                    else:
                        replacement = f"TranslatorGlobal.instance.translate('{keys[original_text]}')"
                        if 'TranslatorGlobal' not in content:
                             content = "import 'package:huiyuyuan_app/l10n/translator_global.dart';\n" + content
        else:
            replacement = f"TranslatorGlobal.instance.translate('{keys[original_text]}')"
            if 'TranslatorGlobal' not in content:
                 content = "import 'package:huiyuyuan_app/l10n/translator_global.dart';\n" + content
        
        # Replace keeping the quotes out
        content = content.replace(f"'{original_text}'", replacement)
        content = content.replace(f'"{original_text}"', replacement)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

do_patch()
print("6 files patched!")
