import os

files = [
    "lib/widgets/image/image_picker_widget.dart",
    "lib/services/order_service.dart",
    "lib/screens/shop/shop_radar.dart",
    "lib/screens/payment/payment_screen.dart",
    "lib/screens/order/order_detail_screen.dart",
    "lib/screens/chat/ai_assistant_screen.dart"
]

bad_import = "package:huiyuyuan_app/l10n/translator_global.dart"
good_import = "package:huiyuyuan/l10n/translator_global.dart"

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace(bad_import, good_import)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

print("Fixed package name errors!")
