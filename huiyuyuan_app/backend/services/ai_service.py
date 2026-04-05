"""AI image analysis via DashScope/Qwen VL."""

import base64
import json
import logging
import re

from fastapi import HTTPException, UploadFile

from config import (
    DASHSCOPE_API_KEY,
    DASHSCOPE_API_KEY_ISSUE,
    DASHSCOPE_BASE_URL,
    DASHSCOPE_VISION_MODEL,
)

logger = logging.getLogger(__name__)


async def analyze_image(file: UploadFile) -> dict:
    """Analyze an uploaded image with a Qwen VL model."""
    import httpx

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="图片不能超过10MB")

    if not DASHSCOPE_API_KEY:
        issue = DASHSCOPE_API_KEY_ISSUE or "Set DASHSCOPE_API_KEY."
        raise HTTPException(
            status_code=503,
            detail=f"AI analysis is not configured. {issue}",
        )

    b64 = base64.b64encode(image_bytes).decode()
    mime = file.content_type or "image/jpeg"
    data_uri = f"data:{mime};base64,{b64}"

    prompt = (
        "请分析这张珠宝图片，并严格返回 JSON：\n"
        '{"description":"详细描述","material":"材质","category":"分类(手链/吊坠/戒指/手镯/项链/耳饰)",'
        '"tags":["标签"],"quality_score":0.8,"suggestion":"建议"}'
    )

    try:
        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(
                f"{DASHSCOPE_BASE_URL.rstrip('/')}/chat/completions",
                headers={
                    "Authorization": f"Bearer {DASHSCOPE_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": DASHSCOPE_VISION_MODEL,
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
                },
            )

        if response.status_code != 200:
            logger.warning(
                "DashScope error: %s %s",
                response.status_code,
                response.text[:300],
            )
            raise HTTPException(
                status_code=503,
                detail="AI image analysis is unavailable.",
            )

        payload = response.json()
        choices = payload.get("choices") or []
        if not choices:
            raise HTTPException(
                status_code=503,
                detail="AI image analysis did not return usable content.",
            )

        message = choices[0].get("message") or {}
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
            raise HTTPException(
                status_code=503,
                detail="AI image analysis did not return usable content.",
            )

        match = re.search(r"\{[\s\S]*\}", text)
        if match:
            return {
                "success": True,
                "analysis": json.loads(match.group(0)),
                "raw": text,
            }

        return {
            "success": True,
            "analysis": {"description": text},
            "raw": text,
        }
    except HTTPException:
        raise
    except Exception as error:
        logger.warning("DashScope analyze_image failed: %s", error)
        raise HTTPException(status_code=503, detail="AI image analysis is unavailable.")
