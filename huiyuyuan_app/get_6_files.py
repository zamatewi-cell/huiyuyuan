import os

files = [
    "lib/widgets/image/image_picker_widget.dart",
    "lib/services/order_service.dart",
    "lib/screens/shop/shop_radar.dart",
    "lib/screens/payment/payment_screen.dart",
    "lib/screens/order/order_detail_screen.dart",
    "lib/screens/chat/ai_assistant_screen.dart"
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    print(f"--- {file} ---")
    for i, line in enumerate(lines):
        if "正在" in line:
            start = max(0, i-2)
            end = min(len(lines), i+3)
            print(f"  Line {i+1}:")
            for j in range(start, end):
                print(f"    {j+1}: {lines[j].strip()}")
            print("-" * 20)
