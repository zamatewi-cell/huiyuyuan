"""
文件上传路由 + OSS STS
安全修复: OSS 未配置时返回 501 而非假凭据
"""

import os
import uuid
from datetime import datetime, timedelta

from fastapi import APIRouter, HTTPException, UploadFile, File, Form

from schemas.common import OssStsResponse
from security import require_user
from config import UPLOAD_DIR, OSS_AVAILABLE

router = APIRouter(tags=["上传"])


@router.post("/api/upload/image")
async def upload_image(
    file: UploadFile = File(...),
    folder: str = Form("images"),
):
    """上传图片"""
    allowed_types = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="不支持的图片格式")

    ext = file.filename.split(".")[-1] if file.filename else "jpg"
    filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}.{ext}"

    folder_path = os.path.join(UPLOAD_DIR, folder)
    os.makedirs(folder_path, exist_ok=True)

    file_path = os.path.join(folder_path, filename)
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)

    url = f"/uploads/{folder}/{filename}"
    return {
        "success": True,
        "url": url,
        "object_key": f"{folder}/{filename}",
        "filename": filename,
    }


@router.get("/api/oss/sts-token", response_model=OssStsResponse)
async def get_oss_sts_token(authorization: str = None):
    """获取OSS STS临时凭证
    安全修复: 未配置时返回 501 (Not Implemented)，不再返回假凭据
    """
    require_user(authorization)

    if not OSS_AVAILABLE:
        raise HTTPException(
            status_code=501,
            detail="OSS 未配置，请在服务器设置 OSS_ACCESS_KEY_ID 和 OSS_ACCESS_KEY_SECRET",
        )

    # TODO: 调用阿里云 STS AssumeRole 获取真实临时凭证
    # 参考: https://help.aliyun.com/document_detail/100624.html
    raise HTTPException(
        status_code=501,
        detail="OSS STS 接口待实现，请使用本地上传接口 /api/upload/image",
    )
