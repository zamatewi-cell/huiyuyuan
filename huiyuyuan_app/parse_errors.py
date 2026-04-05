import re
lines = open('build_log10.txt', 'r', encoding='utf-8', errors='ignore').read().replace('\r', '\n').split('\n')
with open('true_errors.txt', 'w', encoding='utf-8') as f:
    for i, line in enumerate(lines):
        if 'Error: ' in line and 'Failed to compile' not in line and 'ProcessException' not in line:
            f.write(lines[i-1].strip() + '\n')
            f.write(lines[i].strip() + '\n')
