import os
import re
import codecs

def get_dart_files(dirs):
    for d in dirs:
        for r, ds, fs in os.walk(d):
            for f in fs:
                if f.endswith('.dart'):
                    yield os.path.join(r, f)

def fix_build_signatures():
    # Find all ConsumerState build methods and ensure they are exactly `Widget build(BuildContext context)`
    for filepath in get_dart_files(['lib/screens', 'lib/widgets', 'lib/app']):
        with codecs.open(filepath, 'r', 'utf-8') as fh:
            content = fh.read()
            orig = content
            
        # We need to find `class X extends ConsumerState<Y> { ... Widget build(BuildContext context, WidgetRef ref)`
        # A simpler approach: a ConsumerState class's build MUST NOT take WidgetRef ref.
        # But a ConsumerWidget class's build MUST take WidgetRef ref.
        # So instead of regexing classes, let's just find lines that say `Widget build(BuildContext context, WidgetRef ref)` 
        # inside ConsumerState by chunking the file by `class` declarations.
        
        chunks = re.split(r'(class\s+[A-Za-z0-9_]+\s+extends\s+[A-Za-z0-9_<>]+)', content)
        new_chunks = []
        if len(chunks) > 0:
            new_chunks.append(chunks[0])
            for i in range(1, len(chunks), 2):
                class_decl = chunks[i]
                class_body = chunks[i+1]
                
                # if it's a ConsumerState, remove WidgetRef ref from build
                if 'extends ConsumerState' in class_decl or 'extends State' in class_decl:
                    class_body = re.sub(
                        r'Widget\s+build\(\s*BuildContext\s+([^,)]+)\s*,\s*WidgetRef\s+ref\s*\)',
                        r'Widget build(BuildContext \1)',
                        class_body
                    )
                new_chunks.append(class_decl)
                new_chunks.append(class_body)
                
        content = "".join(new_chunks)
        
        # Also remove multiline const
        # const Text(
        #    ... ref.tr
        # This is harder to do safely with simple regex. 
        # We can look for `const\s+[A-Za-z0-9_]+\(` and if within its parentheses we find `ref.tr`, remove `const `
        # Actually doing a naive global replace: `\bconst\s+([A-Z][A-Za-z0-9_]*)` -> `$1` if `ref.tr` is nearby is hard.
        # Let's just remove ALL `const ` prefixing `Text(`, `Padding(`, `Icon(`, `Container(` in the file if it contains `ref.tr`!
        # Because we can afford a performance hit of dropping consts.
        if 'ref.tr(' in content:
            content = re.sub(r'\bconst\s+(Text|Padding|SizedBox|Row|Column|Container|Center|Icon|Expanded|Flexible|EdgeInsets|BorderRadius|BoxDecoration|SnackBar|AlertDialog|BottomNavigationBarItem|Tab)\b', r'\1', content)
            # Remove isolated const in arrays: `children: const [` -> `children: [`
            content = re.sub(r'\bconst\s+\[', '[', content)
            # Remove isolated const inside arrays
            content = re.sub(r'\[\s*const\s+', '[', content)
            content = re.sub(r',\s*const\s+', ',', content)
            # return const
            content = re.sub(r'return\s+const\s+', 'return ', content)
            # child: const
            content = re.sub(r'child:\s*const\s+', 'child: ', content)
            
        if content != orig:
            with codecs.open(filepath, 'w', 'utf-8') as fh:
                fh.write(content)
                
if __name__ == '__main__':
    fix_build_signatures()
    print("Fixes applied.")
