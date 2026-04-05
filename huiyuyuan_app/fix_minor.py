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

# 1. product_translator.dart - Use runes instead of characters to avoid package dependency, although characters is better.
# Wait, string.characters requires `import 'package:characters/characters.dart';`
# I already imported it, maybe it needs `import 'package:flutter/widgets.dart'` which exports it.
# Actually, just use `.runes` instead of `.characters`.
fix_file('lib/l10n/product_translator.dart', [
    (r'\.characters\.', r'.runes.')
])

# 2. notification_screen.dart
fix_file('lib/screens/notification/notification_screen.dart', [
    (r'List<Tab>\s+get\s+_tabs\s*=>\s*\[', r'List<Tab> get _tabs => ['), # just in case
    (r'_tabs\s*=>\s*\[', r'List<Tab> get _tabs => ['), 
    (r'final\s+_tabs\s*=\s*\[', r'List<Tab> get _tabs => [')
])

# 3. order_list_screen.dart: lines 53-57 are multiple sub-lists?
# `final List<Tab> _allTabs = [`, `final List<Tab> _unpaidTabs = [`
fix_file('lib/screens/order/order_list_screen.dart', [
    (r'List<Tab>\s+get\s+([A-Za-z0-9_]+)\s*=>\s*\[', r'List<Tab> get \1 => ['),
    (r'final\s+List<Tab>\s+([A-Za-z0-9_]+)\s*=\s*\[', r'List<Tab> get \1 => ['),
    (r'(?<!final\s)List<Tab>\s+([A-Za-z0-9_]+)\s*=\s*\[', r'List<Tab> get \1 => ['),
    (r'final\s+([A-Za-z0-9_]+)\s*=\s*\[', r'List<Tab> get \1 => [')
])

# 4. admin_product_management_tab.dart
fix_file('lib/widgets/admin/admin_product_management_tab.dart', [
    (r'const\s+List<Tab>\s+_tabs\s*=\s*\[', r'List<Tab> get _tabs => [')
])

# 5. image_picker_widget.dart line 87 - "The default value of an optional parameter must be constant"
# string containing ref.tr
fix_file('lib/widgets/image/image_picker_widget.dart', [
    (r'String\s+title\s*=\s*ref\.tr\([^)]+\)', r'String? title'),
    # Also I need to revert standard const defaults that got broken e.g. title = 'xxx'
])

# 6. profile_screen.dart lines 287, 377, 487, 528...
# These are likely `ref` inside model classes or functions without ref argument, 
# or just missing ref.tr inside methods. 
# It is better to just strip ref.tr from profile_screen where ref doesn't exist, but I'll manually replace ref.tr with fixed strings for these.
# A simpler regex to remove ref.tr if it's causing trouble is hard.
# Let's fix missing `ref` inside class methods that are not build
# For profile_screen.dart, it could be `List<_MenuItem> get menus => ...` where ref is not available if not passing it.
# Wait, inside `ConsumerState`, `ref` is accessible anywhere, but inside a simple `class _MenuItem` it is not.
fix_file('lib/screens/profile/profile_screen.dart', [
    (r'ref\.tr\(([^)]+)\)', r'ref.tr(\1)')
])

# 7. shop_radar.dart line 34
fix_file('lib/screens/shop/shop_radar.dart', [
    (r'final\s+List<Tab>\s+_tabs\s*=\s*\[', r'List<Tab> get _tabs => [')
])

# 8. promotional_banner.dart line 46
fix_file('lib/widgets/promotional_banner.dart', [
    (r'const\s+List<String>\s+_defaultMessages\s*=\s*\[', r'List<String> get _defaultMessages => [')
])

# 9. empty_state.dart
fix_file('lib/widgets/common/empty_state.dart', [
    (r'ref\.tr\(([^)]+)\)', r'ref.tr(\1)')
])

print("Fixes applied.")
