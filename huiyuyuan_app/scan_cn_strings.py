#!/usr/bin/env python3
"""全面扫描项目中所有 Dart UI 文件中的硬编码中文字符串"""
import re
import os

# 要扫描的目录
scan_dirs = [
    'lib/screens/',
    'lib/widgets/',
]

# 匹配包含中文字符的字符串字面量（单引号或双引号）
cn_pattern = re.compile(r"""(?:['"])([^'"]*[\u4e00-\u9fff]+[^'"]*?)(?:['"])""")

# 排除项（注释、import、纯注释行等）
skip_patterns = [
    r'^\s*//',      # 注释行
    r'^\s*\*',      # 多行注释
    r'^import ',    # import
    r'^library',    # library
    r'^\s*///\s',   # 文档注释
]

results = {}
total_count = 0

for scan_dir in scan_dirs:
    for root, dirs, files in os.walk(scan_dir):
        for f in files:
            if not f.endswith('.dart'):
                continue
            filepath = os.path.join(root, f)
            file_results = []
            with open(filepath, 'r', encoding='utf-8') as fh:
                for line_no, line in enumerate(fh, 1):
                    # 跳过注释和 import
                    skip = False
                    stripped = line.strip()
                    for sp in skip_patterns:
                        if re.match(sp, stripped):
                            skip = True
                            break
                    if skip:
                        continue
                    
                    # 如果已经用了 ref.tr()，跳过
                    if 'ref.tr(' in line or 'localizedName' in line or 'localizedDescription' in line:
                        continue
                    
                    # 查找中文字符串
                    matches = cn_pattern.findall(line)
                    for m in matches:
                        # 排除枚举定义（如 MaterialType 中的 label）
                        if "enum " in line or "const MaterialType" in line:
                            continue
                        file_results.append((line_no, m.strip(), stripped[:100]))
                        total_count += 1
            
            if file_results:
                results[filepath] = file_results

# 按文件分组输出
print(f"=== 硬编码中文字符串扫描结果：共 {total_count} 处 ===\n")
for filepath, items in sorted(results.items()):
    print(f"\n📄 {filepath} ({len(items)} 处)")
    print("-" * 70)
    for line_no, cn_text, context in items:
        print(f"  L{line_no:4d}: {cn_text}")
