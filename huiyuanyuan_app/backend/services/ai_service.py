"""
AI 服务 — OpenRouter 多模态图片分析
"""

import json
import logging
import base64
import re

from fastapi import HTTPException, UploadFile

from config import (
    OPENROUTER_API_KEY,
    OPENROUTER_MODEL,
    OPENROUTER_SITE_URL,
    OPENROUTER_APP_NAME,
)

logger = logging.getLogger(__name__)


async def analyze_image(file: UploadFile) -> dict:
    """AI 图片分析：使用 OpenRouter 免费多模态模型。"""
    import httpx

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="图片不能超过10MB")

    b64 = base64.b64encode(image_bytes).decode()
    mime = file.content_type or "image/jpeg"
    data_uri = f"data:{mime};base64,{b64}"

    prompt = (
        "请分析这张珠宝图片，返回严格JSON：\n"
        '{"description":"详细描述","material":"材质","category":"分类(手链/吊坠/戒指/手镯/项链/耳饰)",'
        '"tags":["标签"],"quality_score":0.8,"suggestion":"建议"}'
    )

    if not OPENROUTER_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="AI分析服务未配置，请设置 OPENROUTER_API_KEY",
        )

    try:
        async with httpx.AsyncClient(timeout=60) as client:
            resp = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": OPENROUTER_SITE_URL,
                    "X-Title": OPENROUTER_APP_NAME,
                },
                json={
                    "model": OPENROUTER_MODEL,
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": prompt},
                                {"type": "image_url", "image_url": {"url": data_uri}},
                            ],
                        }
                    ],
                    "max_tokens": 1200,
                    "reasoning": {"exclude": True},
                },
            )

        if resp.status_code != 200:
            logger.warning(
                "OpenRouter error: %s %s",
                resp.status_code,
                resp.text[:300],
            )
            raise HTTPException(status_code=503, detail="AI图片分析暂不可用")

        data = resp.json()
        message = data["choices"][0]["message"]
        content = message.get("content")
        if isinstance(content, list):
            text = "".join(
                item.get("text", "")
                for item in content
                if isinstance(item, dict)
            )
        else:
            text = content or ""

        if not text:
            raise HTTPException(status_code=503, detail="AI图片分析未返回有效内容")

        j = re.search(r"\{[\s\S]*\}", text)
        if j:
            return {
                "success": True,
                "analysis": json.loads(j.group(0)),
                "raw": text,
            }
        return {
            "success": True,
            "analysis": {"description": text},
            "raw": text,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.warning(f"OpenRouter analyze_image failed: {e}")
        raise HTTPException(status_code=503, detail="AI图片分析暂不可用")
