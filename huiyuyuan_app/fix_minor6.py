import os
import codecs

def fix_file_simple(filepath, replacements):
    with codecs.open(filepath, 'r', 'utf-8') as f:
        content = f.read()
    orig = content
    for old, new in replacements:
        content = content.replace(old, new)
    if orig != content:
        with codecs.open(filepath, 'w', 'utf-8') as f:
            f.write(content)

fix_file_simple('lib/screens/admin/admin_dashboard.dart', [
    ("String _activityFilter = ref.tr('order_all');", "String _activityFilter = 'order_all';"),
])

fix_file_simple('lib/screens/admin/inventory_screen.dart', [
    ("String _filterCategory = ref.tr('order_all');", "String _filterCategory = 'order_all';"),
])

fix_file_simple('lib/screens/shop/shop_radar.dart', [
    ("String _selectedPlatform = ref.tr('order_all');", "String _selectedPlatform = 'order_all';"),
])

fix_file_simple('lib/widgets/image/image_picker_widget.dart', [
    ("this.initialImages = [],", "this.initialImages = const [],"),
])

fix_file_simple('lib/screens/profile/profile_screen.dart', [
    ("Widget _buildUserCard(BuildContext context, String username, bool isAdmin)", "Widget _buildUserCard(BuildContext context, WidgetRef ref, String username, bool isAdmin)"),
    ("_buildUserCard(context, username, isAdmin)", "_buildUserCard(context, ref, username, isAdmin)"),
    ("Widget _buildMenuItem({", "Widget _buildMenuItem(WidgetRef ref, {"),
    ("_buildMenuItem(", "_buildMenuItem(ref, "),
    ("Widget _buildOrderSection(BuildContext context)", "Widget _buildOrderSection(BuildContext context, WidgetRef ref)"),
    ("_buildOrderSection(context)", "_buildOrderSection(context, ref)"),
    ("Widget _buildToolsSection(BuildContext context)", "Widget _buildToolsSection(BuildContext context, WidgetRef ref)"),
    ("_buildToolsSection(context)", "_buildToolsSection(context, ref)"),
])

print("Fixed final issues.")
