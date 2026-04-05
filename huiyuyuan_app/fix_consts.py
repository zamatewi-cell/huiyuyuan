import re
from collections import defaultdict

lines = open('build_log4.txt', 'r', encoding='utf-8', errors='ignore').read().splitlines()

files_to_fix = defaultdict(set)

current_file = None
current_line = None
for i, line in enumerate(lines):
    if 'Constant evaluation error' in line or 'Not a constant expression' in line:
        # scan backwards
        for j in range(i, max(0, i-5), -1):
            match = re.search(r'(lib/[^:]+\.dart):(\d+):', lines[j])
            if match:
                fpath = match.group(1)
                l = int(match.group(2))
                files_to_fix[fpath].add(l)
                break

for fpath, lns in files_to_fix.items():
    with open(fpath, 'r', encoding='utf-8') as f:
        src = f.read().split('\n')
        
    for l in lns:
        idx = l - 1
        # scan upwards up to 5 lines to find 'const ' and remove it
        for j in range(idx, max(-1, idx-10), -1):
            if 'const ' in src[j]:
                src[j] = src[j].replace('const ', '', 1)
                print(f"Fixed const in {fpath}:{j+1}")
                break

    with open(fpath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(src))

print("Done fixing consts.")
