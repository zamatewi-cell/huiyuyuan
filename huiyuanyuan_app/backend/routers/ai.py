"""AI routes for image analysis."""

from fastapi import APIRouter, File, UploadFile

from services.ai_service import analyze_image as _analyze_image

router = APIRouter(prefix="/api/ai", tags=["AI"])


@router.post("/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """AI image analysis via DashScope/Qwen VL."""
    return await _analyze_image(file)
