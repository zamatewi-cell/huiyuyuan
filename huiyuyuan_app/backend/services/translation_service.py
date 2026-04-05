"""
商品多语言翻译服务 — 调用 DashScope/Qwen API 自动翻译

功能：
- 创建/更新商品时自动翻译 name / description / category / material / origin
- 支持 en（英文）和 zh-TW（繁体中文）
- 翻译结果直接写入数据库对应字段
- 批量翻译接口用于一次性翻译所有现有商品
"""

import json
import logging
from typing import Optional

import httpx

from config import DASHSCOPE_API_KEY, DASHSCOPE_BASE_URL

logger = logging.getLogger(__name__)

# ==== 固定翻译词典（高频词，避免重复调 API 浪费 token）====

MATERIAL_EN = {
    "和田玉": "Hetian Jade", "缅甸翡翠": "Jadeite",
    "南红玛瑙": "Southern Red Agate", "紫水晶": "Amethyst",
    "碧玉": "Jasper", "蜜蜡": "Amber", "黄金": "Gold",
    "红宝石": "Ruby", "蓝宝石": "Sapphire", "钻石": "Diamond",
    "珍珠": "Pearl",
}
MATERIAL_TW = {
    "和田玉": "和田玉", "缅甸翡翠": "緬甸翡翠",
    "南红玛瑙": "南紅瑪瑙", "紫水晶": "紫水晶",
    "碧玉": "碧玉", "蜜蜡": "蜜蠟", "黄金": "黃金",
    "红宝石": "紅寶石", "蓝宝石": "藍寶石", "钻石": "鑽石",
    "珍珠": "珍珠",
}

CATEGORY_EN = {
    "手链": "Bracelet", "手串": "Beads Bracelet", "吊坠": "Pendant",
    "戒指": "Ring", "手镯": "Bangle", "项链": "Necklace",
    "耳饰": "Earring", "耳环": "Earring", "摆件": "Figurine",
    "套装": "Set",
}
CATEGORY_TW = {
    "手链": "手鏈", "手串": "手串", "吊坠": "吊墜",
    "戒指": "戒指", "手镯": "手鐲", "项链": "項鏈",
    "耳饰": "耳飾", "耳环": "耳環", "摆件": "擺件",
    "套装": "套裝",
}

ORIGIN_EN = {
    "新疆和田": "Xinjiang Hetian", "新疆": "Xinjiang",
    "缅甸": "Myanmar", "缅甸莫西沙": "Myanmar Moxisha",
    "缅甸木那": "Myanmar Muna", "云南": "Yunnan",
    "云南保山": "Yunnan Baoshan", "四川凉山": "Sichuan Liangshan",
    "巴西": "Brazil", "乌拉圭": "Uruguay", "俄罗斯": "Russia",
    "加拿大": "Canada", "波罗的海": "Baltic",
    "哥伦比亚": "Colombia", "斯里兰卡": "Sri Lanka",
    "南非": "South Africa", "澳大利亚": "Australia",
    "日本": "Japan", "中国广西": "Guangxi, China",
}

VERIFY_EN = {
    "天然A货": "Natural Grade A", "天然": "Natural",
    "优化处理": "Enhanced",
}
VERIFY_TW = {
    "天然A货": "天然A貨", "天然": "天然",
    "优化处理": "優化處理",
}


async def _call_qwen_translate(text: str, target_lang: str) -> Optional[str]:
    """调用 DashScope/Qwen 翻译文本"""
    if not DASHSCOPE_API_KEY or not text or not text.strip():
        return None

    lang_name = "English" if target_lang == "en" else "Traditional Chinese (繁體中文)"

    prompt = f"""You are a professional jewelry and gemstone translator.
Translate the following Chinese text into {lang_name}.
Keep brand-specific terms like "汇玉源" as "Hui Yu Yuan".
Keep gemstone names accurate (和田玉=Hetian Jade, 翡翠=Jadeite, etc).
Return ONLY the translated text, no explanations.

Text to translate:
{text}"""

    url = f"{DASHSCOPE_BASE_URL.rstrip('/')}/chat/completions"
    headers = {
        "Authorization": f"Bearer {DASHSCOPE_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "qwen-plus",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3,
        "max_tokens": 2000,
    }

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(url, headers=headers, json=payload)
        if resp.status_code != 200:
            logger.warning("Translation API error %s: %s", resp.status_code, resp.text[:200])
            return None
        data = resp.json()
        return data["choices"][0]["message"]["content"].strip()
    except Exception as e:
        logger.warning("Translation failed: %s", e)
        return None


async def translate_product_fields(
    name: str,
    description: str,
    category: str,
    material: str,
    origin: Optional[str],
    material_verify: str = "天然A货",
) -> dict:
    """
    翻译商品的所有文本字段，返回翻译结果字典。
    固定词使用词典，动态内容调用 AI 翻译。
    """
    result = {}

    # ---- 英文翻译 ----
    # 固定词直接从词典取
    result["category_en"] = CATEGORY_EN.get(category, category)
    result["material_en"] = MATERIAL_EN.get(material, material)
    result["origin_en"] = ORIGIN_EN.get(origin, origin) if origin else None
    result["material_verify_en"] = VERIFY_EN.get(material_verify, material_verify)

    # 名称和描述调用 AI
    result["name_en"] = await _call_qwen_translate(name, "en")
    result["description_en"] = await _call_qwen_translate(description, "en")

    # ---- 繁体中文翻译 ----
    result["category_zh_tw"] = CATEGORY_TW.get(category, category)
    result["material_zh_tw"] = MATERIAL_TW.get(material, material)
    result["material_verify_zh_tw"] = VERIFY_TW.get(material_verify, material_verify)

    # 繁体名称和描述也调用 AI
    result["name_zh_tw"] = await _call_qwen_translate(name, "zh-TW")
    result["description_zh_tw"] = await _call_qwen_translate(description, "zh-TW")

    # 产地用简转繁
    if origin:
        result["origin_zh_tw"] = await _call_qwen_translate(origin, "zh-TW")
    else:
        result["origin_zh_tw"] = None

    return result


def get_translated_field(row_mapping, field: str, lang: str) -> Optional[str]:
    """从数据库行映射中获取翻译后的字段值"""
    if lang == "zh-CN" or not lang:
        return row_mapping.get(field)
    
    lang_suffix = "_en" if lang == "en" else "_zh_tw"
    translated = row_mapping.get(f"{field}{lang_suffix}")
    
    # 如果翻译不存在，回退到中文
    if translated:
        return translated
    return row_mapping.get(field)
