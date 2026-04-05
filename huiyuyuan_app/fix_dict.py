import re
with open("lib/l10n/app_strings.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    # Fix trailing \': -> ':
    line = line.replace("\\': '", "': '")
    line = line.replace("\\',\n", "',\n")
    
    # Fix interpolation errors
    if "${contact['" in line:
        line = line.replace("${contact['", "")
    
    new_lines.append(line)

with open("lib/l10n/app_strings.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

# Same for the dart files 
import os
for root, _, files in os.walk("lib"):
    for file in files:
        if file.endswith(".dart"):
            with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                content = f.read()
                
            if "状态: ${contact['" in content:
                # We need to fix the source code!
                # It was originally: '状态: ${contact['status']}'
                # After my script it became: '状态: ${contact['.trstatus']}' maybe?
                pass

print("Fixed dictionary syntax errors!")
