import os
import re

files = [
    "lib/widgets/image/image_picker_widget.dart",
    "lib/services/order_service.dart",
    "lib/screens/shop/shop_radar.dart",
    "lib/screens/payment/payment_screen.dart",
    "lib/screens/order/order_detail_screen.dart",
    "lib/screens/chat/ai_assistant_screen.dart"
]

import_str = "import 'package:huiyuyuan_app/l10n/translator_global.dart';"

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Strip it from the absolute top
    if content.startswith(import_str + "\n"):
        content = content.replace(import_str + "\n", "", 1)
        
        # Insert it after library; or other imports
        lines = content.split('\n')
        insert_idx = 0
        for i, line in enumerate(lines):
            if "library;" in line or line.startswith("import "):
                insert_idx = i + 1
                
        lines.insert(insert_idx, import_str)
        content = '\n'.join(lines)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

print("Fixed imports order!")
