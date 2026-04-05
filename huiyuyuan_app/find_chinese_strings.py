import os
import re

def process_dart_files(directory):
    chinese_pattern = re.compile(r'[\u4e00-\u9fa5]+')
    string_pattern = re.compile(r'(["\'])(.*?)\1')
    
    results = {}
    for root, _, files in os.walk(directory):
        for file in files:
            if not file.endswith('.dart'): continue
            if 'l10n' in root or 'app_strings.dart' in file: continue
            if 'admin' in root or 'web_artifacts' in root: continue
            
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                
            file_results = []
            for i, line in enumerate(lines):
                if line.strip().startswith('//') or line.strip().startswith('///'): continue
                if 'print(' in line or 'log(' in line: continue
                
                # find strings with chinese
                matches = string_pattern.findall(line)
                for quote, text in matches:
                    if chinese_pattern.search(text):
                        file_results.append((i+1, text, line.strip()))
            
            if file_results:
                results[filepath] = file_results
                
    return results

res = process_dart_files('lib/screens')
res.update(process_dart_files('lib/widgets'))
for file, lines in res.items():
    print(f"\n--- {file} ---")
    for lineno, text, full_line in lines[:5]:
        print(f"L{lineno}: '{text}' -> {full_line}")
    if len(lines) > 5: print(f"... and {len(lines)-5} more")

