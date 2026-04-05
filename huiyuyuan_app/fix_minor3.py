import os
import re
import codecs

def fix_file(filepath, replacements):
    with codecs.open(filepath, 'r', 'utf-8') as f:
        content = f.read()
    orig = content
    for pattern, repl in replacements:
        content = re.sub(pattern, repl, content)
    if orig != content:
        with codecs.open(filepath, 'w', 'utf-8') as f:
            f.write(content)

fix_file('lib/screens/order/order_list_screen.dart', [
    (r'final\s+List<_OrderTabItem>\s+_tabs\s*=\s*\[', r'List<_OrderTabItem> get _tabs => ['),
    (r'const\s+InputDecoration', r'InputDecoration'),
    (r'const\s+OutlineInputBorder', r'OutlineInputBorder')
])

fix_file('lib/screens/product/search_screen.dart', [
    (r'const\s+InputDecoration', r'InputDecoration'),
    (r'const\s+OutlineInputBorder', r'OutlineInputBorder'),
    (r'const\s+Icon', r'Icon')
])

print("Fixed List and consts.")
