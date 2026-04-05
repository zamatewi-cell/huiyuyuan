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

fix_file('lib/screens/profile/profile_screen.dart', [
    (r'_buildUserCard\(context, username, isAdmin\)', r'_buildUserCard(context, ref, username, isAdmin)'),
    (r'Widget\s+_buildUserCard\(BuildContext\s+context,\s*String\s+username,\s*bool\s+isAdmin\)', r'Widget _buildUserCard(BuildContext context, WidgetRef ref, String username, bool isAdmin)'),
    
    (r'_buildMenuItem\(', r'_buildMenuItem(ref, '),
    (r'Widget\s+_buildMenuItem\(\{', r'Widget _buildMenuItem(WidgetRef ref, {'),

    (r'_buildOrderSection\(context\)', r'_buildOrderSection(context, ref)'),
    (r'Widget\s+_buildOrderSection\(BuildContext\s+context\)', r'Widget _buildOrderSection(BuildContext context, WidgetRef ref)'),
    
    (r'_buildToolsSection\(context\)', r'_buildToolsSection(context, ref)'),
    (r'Widget\s+_buildToolsSection\(BuildContext\s+context\)', r'Widget _buildToolsSection(BuildContext context, WidgetRef ref)'),
])

fix_file('lib/widgets/common/empty_state.dart', [
    (r'Widget\s+_buildTitle\(\)', r'Widget _buildTitle(WidgetRef ref)'),
    (r'_buildTitle\(\)', r'_buildTitle(ref)'),
    
    (r'Widget\s+_buildSubtitle\(\)', r'Widget _buildSubtitle(WidgetRef ref)'),
    (r'_buildSubtitle\(\)', r'_buildSubtitle(ref)'),
    
    (r'Widget\s+_buildAction\(\)', r'Widget _buildAction(WidgetRef ref)'),
    (r'_buildAction\(\)', r'_buildAction(ref)'),
])

print("Fixed ref passing in profile and empty_state.")
