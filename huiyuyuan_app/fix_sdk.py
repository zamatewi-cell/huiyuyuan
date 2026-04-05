import re

with open("auto_i18n.py", "r", encoding="utf-8") as f:
    code = f.read()

new_translate = """
def translate_chunk(texts):
    import dashscope
    import json
    dashscope.api_key = "sk-2ac0eccaa86dd495c8979c1ed86cbffe3"
    
    prompt = "You are a professional Flutter UI translator. Translate the given JSON mapping of Chinese texts into English and Traditional Chinese.\\n"
    prompt += "Input Format: {\\\"index\\\": \\\"Chinese text\\\"}\\n"
    prompt += "Output Format: STRICTLY a JSON object without markdown formatting, matching exactly this structure:\\n"
    prompt += "{\\\"index\\\": {\\\"en\\\": \\\"English text\\\", \\\"zhTW\\\": \\\"繁體中文 text\\\"}}\\n\\n"
    prompt += "Texts to translate:\\n"
    
    input_dict = {str(i): t for i, t in enumerate(texts)}
    prompt += json.dumps(input_dict, ensure_ascii=False)
    
    try:
        response = dashscope.Generation.call(
            model='qwen-max',
            messages=[{'role': 'user', 'content': prompt}],
            result_format='text'
        )
        if response.status_code == 200:
            text = response.output.text
            if text.startswith('```json'): text = text[7:]
            if text.startswith('```'): text = text[3:]
            if text.endswith('```'): text = text[:-3]
            parsed = json.loads(text.strip())
            
            result = {}
            for k, vals in parsed.items():
                orig_text = input_dict[k]
                result[orig_text] = vals
            return result
        else:
            print("API error:", response.message)
            return {}
    except Exception as e:
        print("Exception:", e)
        return {}
"""

code = re.sub(r'def translate_chunk\(texts\):.*?return result\n', new_translate, code, flags=re.DOTALL)

with open("auto_i18n.py", "w", encoding="utf-8") as f:
    f.write(code)

print("Swapped to official Dashscope SDK!")
