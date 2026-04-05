files = [
    'lib/services/ai_insight_service.dart',
    'lib/services/ai_prompt_service.dart'
]
for fpath in files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('\ufeff', '')
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)
print("Stripped BOMs")
