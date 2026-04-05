import os
import re

with open("auto_i18n.py", "r", encoding="utf-8") as f:
    code = f.read()

# Make the prompt more strict to avoid JSON parse errors
strict_prompt = """
    prompt = "You are a professional Flutter UI translator. Translate the given JSON mapping of Chinese texts into English and Traditional Chinese.\\n"
    prompt += "Input Format: {\\\"index\\\": \\\"Chinese text\\\"}\\n"
    prompt += "Output Format: STRICTLY a JSON object without markdown formatting, matching exactly this structure:\\n"
    prompt += "{\\\"index\\\": {\\\"en\\\": \\\"English text\\\", \\\"zhTW\\\": \\\"繁體中文 text\\\"}}\\n\\n"
    prompt += "Texts to translate:\\n"
    
    input_dict = {str(i): t for i, t in enumerate(texts)}
    prompt += json.dumps(input_dict, ensure_ascii=False)
"""

# Replace the old prompt generation
old_prompt = """
    prompt = "You are a professional Flutter UI translator. Translate the following Chinese UI texts into English and Traditional Chinese.\\n"
    prompt += "Return the result STRICTLY as a valid JSON object. DO NOT wrap JSON in markdown blocks (` ```json `). Output pure JSON string.\\n"
    prompt += "Format:\\n{\\\"Original Phrase\\\": {\\\"en\\\": \\\"English Text\\\", \\\"zhTW\\\": \\\"繁體中文\\\"}}\\n\\nTexts to translate:\\n"
    for t in texts:
        prompt += f'- "{t}"\\n'
"""

code = code.replace(old_prompt.strip(), strict_prompt.strip())

# The translate_chunk function needs to return original text too
new_return = """
            res = json.loads(response.read().decode('utf-8'))
            text = res['output']['text']
            # Clean md chars
            if text.startswith('```json'): text = text[7:]
            if text.startswith('```'): text = text[3:]
            if text.endswith('```'): text = text[:-3]
            parsed = json.loads(text.strip())
            
            # Map back to texts
            result = {}
            for k, vals in parsed.items():
                orig_text = input_dict[k]
                result[orig_text] = vals
            return result
"""

old_return = """
            res = json.loads(response.read().decode('utf-8'))
            text = res['output']['text']
            if text.startswith("```json"): text = text[7:]
            if text.startswith("```"): text = text[3:]
            if text.endswith("```"): text = text[:-3]
            return json.loads(text.strip())
"""

code = code.replace(old_return.strip(), new_return.strip())

with open("auto_i18n.py", "w", encoding="utf-8") as f:
    f.write(code)

print("auto_i18n.py hardened against LLM parsing errors!")
