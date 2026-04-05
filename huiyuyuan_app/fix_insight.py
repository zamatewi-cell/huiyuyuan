import re

with open('lib/services/ai_insight_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('\u3000', ' ')
content = content.replace('urgentWords = [', 'final urgentWords = [')

# Also fix the `static _sensitiveWords = [` which might have lost its `const` or type, no wait:
content = content.replace('static _sensitiveWords = [', 'static final List<String> _sensitiveWords = [')

with open('lib/services/ai_insight_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed ai_insight_service.dart!")
