import re

files_to_fix = [
    'lib/screens/payment_management_screen.dart'
]

targets = ['EdgeInsets', 'SizedBox', 'Text', 'Widget', 'Icon', 'Row', 'Column', 'Center', 'Padding', 'Align', 'BoxDecoration', 'BorderRadius', 'Color', 'BoxShadow', 'Stack', 'Positioned', 'Expanded', 'Flexible', 'TabBarView', 'TabBar']

for fpath in files_to_fix:
    with open(fpath, 'r', encoding='utf-8') as f:
        src = f.read()
        
    for t in targets:
        src = re.sub(r'\bconst\s+' + t + r'\b', t, src)
        
    src = src.replace('const [', '[')
    src = src.replace('const {', '{')
    src = src.replace('const <', '<')

    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(src)

print("Stripped payment_management_screen.dart consts.")
