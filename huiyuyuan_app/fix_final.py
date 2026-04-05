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

# 1. admin_dashboard.dart
fix_file('lib/screens/admin/admin_dashboard.dart', [
    (r'final\s+List<Tab>\s+_tabs\s*=\s*\[', r'List<Tab> get _tabs => [')
])

# 2. inventory_screen.dart
fix_file('lib/screens/admin/inventory_screen.dart', [
    (r'final\s+List<Tab>\s+_tabs\s*=\s*\[', r'List<Tab> get _tabs => [')
])

# 3. notification_screen.dart
fix_file('lib/screens/notification/notification_screen.dart', [
    (r'final\s+List<Tab>\s+_tabs\s*=\s*\[', r'List<Tab> get _tabs => ['),
    (r'_tabs\s*=\s*\[', r'List<Tab> get _tabs => [') # line 81: "info - The private field _tabs could be 'final'", var missing
])

# 4. order_list_screen.dart
fix_file('lib/screens/order/order_list_screen.dart', [
    (r'final\s+List<Tab>\s+_tabs\s*=\s*\[', r'List<Tab> get _tabs => [')
])

# 5. order_detail_screen.dart (remove const before list and maps)
fix_file('lib/screens/order/order_detail_screen.dart', [
    (r'const\s+\[', r'['),
    (r'const\s+\{', r'{'),
    # for line 644: const_eval_method_invocation
    (r'const\s+(Text|Padding|SizedBox|Row|Column|Container|Center|Icon|Expanded|Flexible|EdgeInsets|BorderRadius|BoxDecoration|SnackBar|AlertDialog|BottomNavigationBarItem|Tab)\b', r'\1')
])

# 6. product_translator.dart
fix_file('lib/l10n/product_translator.dart', [
    (r'(import \'package:flutter/material\.dart\';)', r"\1\nimport 'package:characters/characters.dart';")
])

print("Target fixes applied")
