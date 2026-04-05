import sys
files = [
    "lib/screens/chat/ai_assistant_screen.dart",
    "lib/screens/order/order_detail_screen.dart",
    "lib/screens/payment/payment_screen.dart",
    "lib/screens/payment_management_screen.dart",
    "lib/screens/profile/profile_screen.dart",
    "lib/screens/shop/shop_radar.dart",
    "lib/services/order_service.dart",
    "lib/widgets/image/image_picker_widget.dart"
]

for fpath in files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    line_to_add = "import 'package:huiyuyuan/l10n/string_extension.dart';"
    
    if line_to_add in content:
        continue
        
    # insert after library; or just at top
    if 'library;' in content:
        content = content.replace('library;', f'library;\n\n{line_to_add}')
    else:
        # insert after first block of comments or package imports
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('import '):
                lines.insert(i, line_to_add)
                content = '\n'.join(lines)
                break
        
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)
        
print("Done fixing imports")
