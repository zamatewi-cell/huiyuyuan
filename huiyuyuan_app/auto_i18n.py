import os
import re
import json
import time
from deep_translator import GoogleTranslator

DART_DIR = "lib"

# Load the dictionary first
dict_file = "lib/l10n/app_strings.dart"
with open(dict_file, "r", encoding="utf-8") as f:
    app_strings_content = f.read()

# Only extract Chinese strings in widgets, screens, and services
skip_dirs = ['config', 'providers', 'utils', 'app', 'l10n', 'themes', 'models']

all_files = []
for root, _, files in os.walk(DART_DIR):
    if any(skip in root.replace('\\', '/') for skip in skip_dirs):
        continue
    for f in files:
        if f.endswith(".dart"):
            all_files.append(os.path.join(root, f))

chinese_re = re.compile(r"('([^']*[\u4e00-\u9fa5]+[^']*)')|(\"([^\"]*[\u4e00-\u9fa5]+[^\"]*)\")")
log_re = re.compile(r'(debugPrint|print|log|assert|Exception|throw)\(')

collected_texts = set()

print("Scanning files...")
for file in all_files:
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    new_lines = []
    file_changed = False
    for i, line in enumerate(lines):
        if log_re.search(line) or line.strip().startswith('//'):
            new_lines.append(line)
            continue
            
        matches = chinese_re.findall(line)
        if matches:
            replaced_line = line
            for m in matches:
                full_match = m[0] or m[2]
                text_content = m[1] or m[3]
                collected_texts.add(text_content)
                
                # IMPORTANT: Replace with .tr 
                replaced_line = replaced_line.replace(full_match, f"{full_match}.tr")
            
            replaced_line = replaced_line.replace('const Text(', 'Text(')
            replaced_line = replaced_line.replace('const Padding(', 'Padding(')
            replaced_line = replaced_line.replace('const Center(', 'Center(')
            replaced_line = replaced_line.replace('const Align(', 'Align(')
            replaced_line = replaced_line.replace('const Row(', 'Row(')
            replaced_line = replaced_line.replace('const Column(', 'Column(')
            replaced_line = replaced_line.replace('const SizedBox(', 'SizedBox(')
            replaced_line = replaced_line.replace('const EdgeInsets.', 'EdgeInsets.')
            replaced_line = replaced_line.replace('const [', '[')

            new_lines.append(replaced_line)
            file_changed = True
        else:
            new_lines.append(line)
            
    if file_changed:
        content = "".join(new_lines)
        if "string_extension.dart" not in content and "TranslatorGlobal" not in content:
            insertion_idx = 0
            for idx, ln in enumerate(new_lines):
                if ln.startswith("import '"):
                    insertion_idx = idx + 1
            new_lines.insert(insertion_idx, "import 'package:huiyuyuan/l10n/string_extension.dart';\n")
            
        with open(file, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"Patched {file}")

print(f"Found {len(collected_texts)} unique Chinese strings.")

text_list = list(collected_texts)
all_translations = {}

print("Translating via deep-translator...")
translator_en = GoogleTranslator(source='zh-CN', target='en')
translator_tw = GoogleTranslator(source='zh-CN', target='zh-TW')

def safe_translate(texts):
    res = {}
    try:
        # Avoid heavy batch timeout
        for t in texts:
            en_text = translator_en.translate(t)
            tw_text = translator_tw.translate(t)
            res[t] = {
                'en': en_text,
                'zhTW': tw_text
            }
            time.sleep(0.1) # tiny delay
    except Exception as e:
        print(f"Error: {e}")
        pass
    return res

chunk_size = 50
chunks = [text_list[i:i + chunk_size] for i in range(0, len(text_list), chunk_size)]

for i, chunk in enumerate(chunks):
    res = safe_translate(chunk)
    all_translations.update(res)

print(f"Translated {len(all_translations)} strings.")

print("Updating app_strings.dart...")

zhCN_append = ""
zhTW_append = ""
en_append = ""

for zh_text, trans_map in all_translations.items():
    safe_key = zh_text.replace("'", "\\'").replace("\n", "\\n")
    en_text = trans_map.get('en', zh_text)
    if not en_text: en_text = zh_text
    en_text = en_text.replace("'", "\\'").replace("\n", "\\n")
    
    tw_text = trans_map.get('zhTW', zh_text)
    if not tw_text: tw_text = zh_text
    tw_text = tw_text.replace("'", "\\'").replace("\n", "\\n")
    
    zhCN_append += f"    '{safe_key}': '{safe_key}',\n"
    en_append += f"    '{safe_key}': '{en_text}',\n"
    zhTW_append += f"    '{safe_key}': '{tw_text}',\n"

with open(dict_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

def insert_dict(dict_name, content_append):
    for i, line in enumerate(lines):
        if line.strip() == f"static const Map<String, String> {dict_name} = {{":
            for j in range(i+1, len(lines)):
                if lines[j].strip() == "};":
                    lines.insert(j, content_append)
                    return True
    return False

insert_dict("_zhCN", zhCN_append)
insert_dict("_en", en_append)
insert_dict("_zhTW", zhTW_append)

with open(dict_file, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Systematic AI localization patching complete!")
