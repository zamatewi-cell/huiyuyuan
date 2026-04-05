import sys
lines = open('build_log11.txt', 'r', encoding='utf-8', errors='ignore').read().replace('\r', '\n').split('\n')
for i, line in enumerate(lines):
    if 'Error: ' in line and 'ProcessException' not in line and 'ailed to compile' not in line:
        print(lines[i-1].strip() if i > 0 else '')
        print(line.strip())
