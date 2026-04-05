import re
import codecs

with codecs.open("lib/l10n/app_strings.dart", "r", "utf-8") as f:
    text = f.read()

zh_block_match = re.search(r'static const Map<String, String> _zhCN = \{(.*?)\};', text, re.DOTALL)
if zh_block_match:
    zh_block = zh_block_match.group(1)
    # Parse keys and values
    items = re.findall(r"'([^']+)':\s*'([^']*)'", zh_block)
    # create reverse mapping
    print("Found", len(items), "items")
    # write to a file
    with codecs.open("zh_to_key.json", "w", "utf-8") as out:
        import json
        out.write(json.dumps({v: k for k, v in items if v}, ensure_ascii=False, indent=2))
