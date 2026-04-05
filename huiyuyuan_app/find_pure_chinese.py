import os
import re

def process_dart_files(directory):
    # Match strings that consist entirely of Chinese characters (or basic punctuation)
    # Exclude strings with $, {, }, or english letters.
    pure_chinese_pattern = re.compile(r'^[\u4e00-\u9fa5，。！？：、]+$')
    # Matches '...' or "..." 
    string_pattern = re.compile(r'([\'"])(.*?)\1')
    
    results = {}
    for root, _, files in os.walk(directory):
        for file in files:
            if not file.endswith('.dart'): continue
            if 'l10n' in root or 'app_strings.dart' in file: continue
            
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                
            file_results = []
            for i, line in enumerate(lines):
                if line.strip().startswith('//') or line.strip().startswith('///'): continue
                if 'print(' in line or 'log(' in line: continue
                
                # find strings
                matches = string_pattern.findall(line)
                for quote, text in matches:
                    if pure_chinese_pattern.match(text):
                        file_results.append((i+1, text, line.strip()))
            
            if file_results:
                results[filepath] = file_results
                
    return results

res = process_dart_files('lib')
total = 0
for file, lines in res.items():
    total += len(lines)
    print(f"\n--- {file} ---")
    for lineno, text, full_line in lines:
        print(f"L{lineno}: '{text}'")

print(f"\nTotal pure Chinese strings: {total}")
