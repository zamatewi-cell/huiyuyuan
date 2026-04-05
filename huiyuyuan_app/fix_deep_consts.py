import re
from collections import defaultdict

lines = open('build_log6.txt', 'r', encoding='utf-8', errors='ignore').read().replace('\r', '\n').split('\n')

files_to_fix = defaultdict(set)
for i, line in enumerate(lines):
    if 'Error: Constant evaluation' in line or 'Not a constant expression.' in line:
        for j in range(i, max(0, i-5), -1):
            if '.dart:' in lines[j] and 'lib/' in lines[j]:
                match = re.search(r'(lib/[^:]+\.dart):(\d+):', lines[j])
                if match:
                    files_to_fix[match.group(1)].add(int(match.group(2)))
                    break

for fpath, lns in files_to_fix.items():
    with open(fpath, 'r', encoding='utf-8') as f:
        src = f.read().split('\n')
        
    for l in lns:
        idx = l - 1
        # scan upwards to find the nearest 'const ' and selectively remove it
        # We will stop at ';', '}', '{' to avoid destroying other blocks, but since Flutter widgets are deep trees, '{' or ',' is common.
        for j in range(idx, max(-1, idx-100), -1):
            if 'const ' in src[j]:
                src[j] = src[j].replace('const ', '', 1)
                print(f"Removed const in {fpath}:{j+1}")
                break

    with open(fpath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(src))

print("Fixed deep const issues.")
