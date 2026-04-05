import os

files = [
    "lib/screens/chat/ai_assistant_screen.dart",
    "lib/screens/shop/shop_radar.dart",
    "lib/screens/order/order_detail_screen.dart",
    "lib/screens/payment/payment_screen.dart"
]

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "translator_global.dart" not in content:
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith("import "):
                lines.insert(i, "import 'package:huiyuyuan/l10n/translator_global.dart';")
                break
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))

print("Forced imports added!")
