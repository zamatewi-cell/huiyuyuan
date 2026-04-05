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

fix_file('lib/widgets/promotional_banner.dart', [
    (r'const\s+List<_BannerData>\s+_banners\s*=\s*\[', r'List<_BannerData> get _banners => ['),
])

print("Fixed promotional banner list constant.")
