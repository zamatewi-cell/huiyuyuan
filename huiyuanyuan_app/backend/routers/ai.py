"""
AI 路由 — 图片分析代理
"""

from fastapi import APIRouter, UploadFile, File

from services.ai_service import analyze_image as _analyze_image

router = APIRouter(prefix="/api/ai", tags=["AI"])


@router.post("/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """AI图片分析（OpenRouter 多模态模型）"""
    return await _analyze_image(file)
