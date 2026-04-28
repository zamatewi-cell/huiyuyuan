"""
图形验证码服务 — 生成验证码图片并存储到 Redis
"""

import base64
import io
import logging
import random
import string
from typing import Optional, Tuple

from PIL import Image, ImageDraw, ImageFont
from fastapi import HTTPException

from config import APP_ENV
from database import REDIS_AVAILABLE, redis_client

logger = logging.getLogger(__name__)

# 验证码配置
CAPTCHA_LENGTH = 4
CAPTCHA_WIDTH = 160
CAPTCHA_HEIGHT = 60
CAPTCHA_TTL = 300  # 5 分钟有效
CAPTCHA_REDIS_PREFIX = "captcha:image:"


def _generate_code(length: int = CAPTCHA_LENGTH) -> str:
    """生成随机验证码（大写字母+数字，排除易混淆字符）"""
    charset = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
    return "".join(random.choices(charset, k=length))


def _create_captcha_image(code: str) -> Tuple[bytes, str]:
    """创建验证码图片，返回 (PNG bytes, MIME type)"""
    img = Image.new("RGB", (CAPTCHA_WIDTH, CAPTCHA_HEIGHT), "#1a1a2e")
    draw = ImageDraw.Draw(img)

    # 尝试使用系统字体
    font_size = 32
    font_names = [
        "arial.ttf",
        "DejaVuSans.ttf",
        "LiberationMono-Regular.ttf",
    ]
    font = None
    for name in font_names:
        try:
            font = ImageFont.truetype(name, font_size)
            break
        except (IOError, OSError):
            continue

    if font is None:
        font = ImageFont.load_default()

    # 绘制干扰线
    for _ in range(5):
        x1 = random.randint(0, CAPTCHA_WIDTH)
        y1 = random.randint(0, CAPTCHA_HEIGHT)
        x2 = random.randint(0, CAPTCHA_WIDTH)
        y2 = random.randint(0, CAPTCHA_HEIGHT)
        color = (
            random.randint(50, 150),
            random.randint(50, 150),
            random.randint(50, 150),
        )
        draw.line([(x1, y1), (x2, y2)], fill=color, width=1)

    # 绘制干扰点
    for _ in range(30):
        x = random.randint(0, CAPTCHA_WIDTH)
        y = random.randint(0, CAPTCHA_HEIGHT)
        color = (
            random.randint(100, 200),
            random.randint(100, 200),
            random.randint(100, 200),
        )
        draw.point((x, y), fill=color)

    # 绘制验证码文字
    char_spacing = CAPTCHA_WIDTH // (CAPTCHA_LENGTH + 1)
    colors = [
        (255, 255, 255),
        (255, 200, 100),
        (100, 255, 200),
        (200, 150, 255),
        (255, 150, 150),
    ]
    for i, char in enumerate(code):
        x = char_spacing * (i + 1) + random.randint(-5, 5)
        y = (CAPTCHA_HEIGHT - font_size) // 2 + random.randint(-3, 3)
        angle = random.randint(-15, 15)
        color = colors[i % len(colors)]

        # 创建旋转的文字图像
        txt_img = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
        txt_draw = ImageDraw.Draw(txt_img)
        txt_draw.text((0, 0), char, font=font, fill=color)
        txt_img = txt_img.rotate(angle, expand=True)

        img.paste(txt_img, (x, y), txt_img)

    # 转换为 PNG bytes
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return buffer.getvalue(), "image/png"


def generate_captcha(session_id: str) -> dict:
    """生成验证码并存储，返回 base64 图片数据
    
    Args:
        session_id: 会话标识（通常用 IP + 时间戳的哈希）
    
    Returns:
        {
            "image": "data:image/png;base64,...",
            "session_id": "xxx"
        }
    """
    code = _generate_code()
    png_bytes, mime_type = _create_captcha_image(code)
    b64_data = base64.b64encode(png_bytes).decode("ascii")

    # 存储验证码答案
    storage_key = f"{CAPTCHA_REDIS_PREFIX}{session_id}"
    if REDIS_AVAILABLE and redis_client:
        redis_client.setex(storage_key, CAPTCHA_TTL, code.upper())
    else:
        if APP_ENV == "production":
            raise HTTPException(
                status_code=503,
                detail="验证码服务暂不可用，请稍后重试",
            )
        # 开发环境使用内存存储
        from services.captcha_service import _memory_captcha
        _memory_captcha[session_id] = code.upper()

    return {
        "image": f"data:{mime_type};base64,{b64_data}",
        "session_id": session_id,
    }


def verify_captcha(session_id: str, user_input: str) -> bool:
    """验证用户输入的验证码是否正确
    
    Args:
        session_id: 会话标识
        user_input: 用户输入的验证码
    
    Returns:
        True 如果验证成功，False 如果失败
    """
    if not session_id or not user_input:
        return False

    storage_key = f"{CAPTCHA_REDIS_PREFIX}{session_id}"
    
    if REDIS_AVAILABLE and redis_client:
        stored_code = redis_client.get(storage_key)
        if stored_code is None:
            return False
        
        # 验证成功后删除，防止重放攻击
        redis_client.delete(storage_key)
        stored_str = stored_code.decode("utf-8") if isinstance(stored_code, bytes) else str(stored_code)
        return stored_str.upper() == user_input.strip().upper()
    else:
        from services.captcha_service import _memory_captcha
        stored_code = _memory_captcha.pop(session_id, None)
        if stored_code is None:
            return False
        return stored_code == user_input.strip().upper()


# 开发环境内存存储
_memory_captcha: dict[str, str] = {}
