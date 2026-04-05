lines = open('build_log5.txt', 'r', encoding='utf-8', errors='ignore').read().replace('\r', '\n').split('\n')
for i, line in enumerate(lines):
    if 'Error: Expected' in line:
        print(lines[i-1].strip())
        print(lines[i].strip())
        print(lines[i+1].strip())
        print(lines[i+2].strip())
        print("-" * 40)
