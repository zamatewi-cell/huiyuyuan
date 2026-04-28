"""AI routes for image analysis and chat proxy."""

import logging

from fastapi import APIRouter, File, UploadFile
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from config import (
    DASHSCOPE_API_KEY,
    DASHSCOPE_API_KEY_ISSUE,
    DASHSCOPE_BASE_URL,
)
from security import AuthorizationDep, require_permission
from services.ai_service import analyze_image as _analyze_image

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/ai", tags=["AI"])


# ──── 聊天代理请求模型 ────
class ChatMessage(BaseModel):
    role: str
    content: str


class ChatProxyRequest(BaseModel):
    """前端发送的聊天代理请求"""
    model: str = "qwen-plus"
    messages: list[ChatMessage]
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(default=2000, ge=1, le=8000)
    stream: bool = False


# ──── 健康检查 ────
@router.get("/health")
async def ai_health():
    """检查 AI 服务可用性"""
    return {
        "available": bool(DASHSCOPE_API_KEY),
        "issue": DASHSCOPE_API_KEY_ISSUE,
    }


# ──── 图片分析 ────
@router.post("/analyze-image")
async def analyze_image(
    file: UploadFile = File(...),
    authorization: AuthorizationDep = None,
):
    """AI image analysis via DashScope/Qwen VL."""
    require_permission(authorization, "ai_assistant")
    return await _analyze_image(file)


# ──── 聊天代理（解决 Web 端 CORS 问题）────
@router.post("/chat")
async def chat_proxy(
    req: ChatProxyRequest,
    authorization: AuthorizationDep = None,
):
    """代理前端聊天请求到 DashScope API，解决浏览器 CORS 限制。"""
    import httpx

    require_permission(authorization, "ai_assistant")

    if not DASHSCOPE_API_KEY:
        issue = DASHSCOPE_API_KEY_ISSUE or "DASHSCOPE_API_KEY 未配置"
        return {"error": issue, "choices": []}

    url = f"{DASHSCOPE_BASE_URL.rstrip('/')}/chat/completions"
    headers = {
        "Authorization": f"Bearer {DASHSCOPE_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": req.model,
        "messages": [m.model_dump() for m in req.messages],
        "temperature": req.temperature,
        "max_tokens": req.max_tokens,
        "stream": req.stream,
    }

    try:
        if req.stream:
            return await _stream_chat(url, headers, payload)
        else:
            return await _non_stream_chat(url, headers, payload)
    except Exception as e:
        logger.warning("AI chat proxy error: %s", e)
        return {"error": f"AI 服务请求失败: {e}", "choices": []}


async def _non_stream_chat(url: str, headers: dict, payload: dict) -> dict:
    """非流式聊天请求"""
    import httpx

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(url, headers=headers, json=payload)

    if resp.status_code != 200:
        logger.warning("DashScope chat error: %s %s", resp.status_code, resp.text[:300])
        return {"error": f"DashScope 返回 HTTP {resp.status_code}", "choices": []}

    return resp.json()


async def _stream_chat(url: str, headers: dict, payload: dict):
    """流式聊天请求"""
    import httpx

    async def event_generator():
        async with httpx.AsyncClient(timeout=60) as client:
            async with client.stream(
                "POST", url, headers=headers, json=payload
            ) as resp:
                if resp.status_code != 200:
                    error_body = await resp.aread()
                    yield f"data: {{\"error\": \"HTTP {resp.status_code}\"}}\n\n"
                    return
                async for line in resp.aiter_lines():
                    if line.strip():
                        yield f"{line}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
