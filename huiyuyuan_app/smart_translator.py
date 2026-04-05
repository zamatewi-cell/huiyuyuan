import os
import re
import codecs
import json

def get_base_import_path(file_path):
    rel_path = os.path.relpath(file_path, 'lib')
    depth = len(rel_path.split(os.sep)) - 1
    prefix = '../' * depth if depth > 0 else './'
    return f"import '{prefix}l10n/l10n_provider.dart';"

def process_file(filepath, keys, zh_to_key):
    with codecs.open(filepath, 'r', 'utf-8') as fh:
        content = fh.read()
            
    orig_content = content
        
    for zh in keys:
        if zh in content:
            key = zh_to_key[zh]
            content = content.replace(f"'{zh}'", f"ref.tr('{key}')")
            content = content.replace(f'"{zh}"', f"ref.tr('{key}')")
        
    if content == orig_content:
        return False
        
    print(f"Modifying {filepath}...")
    
    # Process line-by-line for const removal
    lines = content.split('\n')
    for i in range(len(lines)):
        if 'ref.tr(' in lines[i]:
            # Remove isolated const before method calls or arrays
            lines[i] = lines[i].replace('const ', '')
            
    content = '\n'.join(lines)
    
    # Regex conversions carefully structured
    # 1. StatelessWidget -> ConsumerWidget
    def replace_stateless(match):
        cls_content = match.group(0)
        # also need to replace its build method
        cls_content = re.sub(
            r'Widget\s+build\(\s*BuildContext\s+([A-Za-z0-9_]+)\s*\)',
            r'Widget build(BuildContext \1, WidgetRef ref)',
            cls_content
        )
        return cls_content.replace('extends StatelessWidget', 'extends ConsumerWidget')

    content = re.sub(r'class\s+[A-Za-z0-9_]+\s+extends\s+StatelessWidget.*?}', replace_stateless, content, flags=re.DOTALL)
    
    # In case the regex didn't catch the build method (e.g. beyond closing brace), we can do it more modularly
    if 'extends StatelessWidget' in content:
        content = content.replace('extends StatelessWidget', 'extends ConsumerWidget')
        # Very dangerously replace Widget build inside this file IF it has ConsumerWidget now
        # Actually, let's just do a simpler replacement of 'extends ConsumerWidget' and then replace 'build(BuildContext context)' with 'build(BuildContext context, WidgetRef ref)' for the whole file
    if 'extends ConsumerWidget' in content:
         content = re.sub(r'Widget\s+build\(\s*BuildContext\s+([^,)]+)\s*\)', r'Widget build(BuildContext \1, WidgetRef ref)', content)

    # 2. StatefulWidget -> ConsumerStatefulWidget
    content = re.sub(r'\bextends\s+StatefulWidget\b', 'extends ConsumerStatefulWidget', content)
    content = re.sub(r'\bState<([A-Za-z0-9_]+)>\s+createState', r'ConsumerState<\1> createState', content)
    
    # 3. State<T> -> ConsumerState<T>
    # Avoid ConsumerConsumerState
    content = re.sub(r'\bextends\s+State<([A-Za-z0-9_]+)>', r'extends ConsumerState<\1>', content)
    
    # 4. Imports
    if 'package:flutter_riverpod/flutter_riverpod.dart' not in content:
        content = re.sub(
            r'(import \'package:flutter/material\.dart\';)',
            r"\1\nimport 'package:flutter_riverpod/flutter_riverpod.dart';",
            content
        )
        
    if 'l10n_provider.dart' not in content:
        l10n_import = get_base_import_path(filepath)
        content = re.sub(
            r'(import \'package:flutter/material\.dart\';)',
            r"\1\n" + l10n_import,
            content
        )
        
    with codecs.open(filepath, 'w', 'utf-8') as fh:
        fh.write(content)
    return True


def main():
    with codecs.open('zh_to_key.json', 'r', 'utf-8') as f:
        zh_to_key = json.load(f)

    keys = sorted(zh_to_key.keys(), key=len, reverse=True)
    scan_dirs = ['lib/screens', 'lib/widgets', 'lib/app']
    changed_files = 0
    
    for r, dirs, files in os.walk('lib'):
        # Only process inside scan_dirs
        if not any(r.replace('\\', '/').startswith(d) for d in scan_dirs):
            continue
            
        for f in files:
            if not f.endswith('.dart'): continue
            if 'app_strings' in f or 'product_translator' in f: continue
            if process_file(os.path.join(r, f), keys, zh_to_key):
                changed_files += 1

    print(f"Done. Changed {changed_files} files.")

if __name__ == '__main__':
    main()
