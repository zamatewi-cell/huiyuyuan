"""
汇玉源后端API - 增强版
支持完整的CRUD操作、文件上传、推送通知等功能
"""

from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import random
import uuid
import os
from datetime import datetime, timedelta
import json
import logging

# --- 环境变量 ---
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# --- 数据库 (SQLAlchemy) ---
try:
    from sqlalchemy import create_engine, text
    from sqlalchemy.orm import sessionmaker, Session
    _DB_URL = os.getenv("DATABASE_URL", "")
    if _DB_URL:
        _engine = create_engine(_DB_URL, pool_pre_ping=True, pool_size=5, max_overflow=10)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_engine)
        DB_AVAILABLE = True
    else:
        DB_AVAILABLE = False
except Exception as _e:
    DB_AVAILABLE = False
    logging.warning(f"Database unavailable: {_e}")

def get_db():
    """FastAPI 依赖：获取数据库会话，不可用时返回 None"""
    if not DB_AVAILABLE:
        yield None
        return
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- Redis ---
try:
    import redis as _redis_lib
    _REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    redis_client = _redis_lib.from_url(_REDIS_URL, decode_responses=True, socket_connect_timeout=2)
    redis_client.ping()
    REDIS_AVAILABLE = True
except Exception as _e:
    redis_client = None
    REDIS_AVAILABLE = False
    logging.warning(f"Redis unavailable: {_e}")

# --- JWT ---
try:
    from jose import jwt as _jose_jwt
    JWT_SECRET = os.getenv("JWT_SECRET_KEY", "dev_secret_change_in_production")
    JWT_ALGORITHM = "HS256"
    JWT_EXPIRE_SECONDS = 3600
    JWT_AVAILABLE = True
except ImportError:
    JWT_AVAILABLE = False

def create_jwt_token(user_id: str, extra: dict = None) -> str:
    """生成 JWT Token，降级时返回 UUID"""
    if not JWT_AVAILABLE:
        return str(uuid.uuid4())
    payload = {
        "sub": user_id,
        "exp": datetime.utcnow() + timedelta(seconds=JWT_EXPIRE_SECONDS),
        "iat": datetime.utcnow(),
    }
    if extra:
        payload.update(extra)
    return _jose_jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

# --- 阿里云短信 SDK（可选，AccessKey 未配置时跳过）---
ALIYUN_AK_ID     = os.getenv("ALIYUN_ACCESS_KEY_ID", "")
ALIYUN_AK_SECRET = os.getenv("ALIYUN_ACCESS_KEY_SECRET", "")
SMS_SIGN_NAME    = os.getenv("SMS_SIGN_NAME", "汇玉源")
SMS_TEMPLATE     = os.getenv("SMS_TEMPLATE_CODE", "")
SMS_REAL_MODE    = bool(ALIYUN_AK_ID and ALIYUN_AK_SECRET and SMS_TEMPLATE)

def _send_aliyun_sms(phone: str, code: str) -> dict:
    """调用阿里云短信发送接口，返回 {success, biz_id, message}"""
    try:
        from aliyunsdkcore.client import AcsClient
        from aliyunsdkcore.request import CommonRequest
        client = AcsClient(ALIYUN_AK_ID, ALIYUN_AK_SECRET, "cn-hangzhou")
        req = CommonRequest()
        req.set_accept_format("json")
        req.set_domain("dysmsapi.aliyuncs.com")
        req.set_method("POST")
        req.set_protocol_type("https")
        req.set_version("2017-05-25")
        req.set_action_name("SendSms")
        req.add_query_param("RegionId", "cn-hangzhou")
        req.add_query_param("PhoneNumbers", phone)
        req.add_query_param("SignName", SMS_SIGN_NAME)
        req.add_query_param("TemplateCode", SMS_TEMPLATE)
        req.add_query_param("TemplateParam", json.dumps({"code": code}))
        resp = json.loads(client.do_action_with_exception(req))
        ok = resp.get("Code") == "OK"
        return {"success": ok, "biz_id": resp.get("BizId", ""), "message": resp.get("Message", "")}
    except Exception as e:
        return {"success": False, "biz_id": "", "message": str(e)}

app = FastAPI(
    title="汇玉源后端 API",
    version="3.0.0",
    description="汇玉源珠宝智能交易平台后端服务"
)

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 创建上传目录
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# 挂载静态文件服务
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ============ 数据模型 ============

class LoginRequest(BaseModel):
    username: Optional[str] = None
    password: Optional[str] = None
    type: str = "operator"
    captcha: Optional[str] = None
    phone: Optional[str] = None
    code: Optional[str] = None
    login_type: Optional[str] = None

class TokenResponse(BaseModel):
    token: str
    refresh_token: str
    expires_in: int = 3600

class UserResponse(BaseModel):
    id: str
    username: str
    phone: Optional[str] = None
    is_admin: bool = False
    balance: float = 0.0
    points: int = 0
    avatar: Optional[str] = None
    operator_number: Optional[int] = None
    user_type: str = "operator"

class Product(BaseModel):
    id: str
    name: str
    description: str
    price: float
    original_price: Optional[float] = None
    category: str
    material: str
    images: List[str]
    stock: int
    rating: float = 5.0
    sales_count: int = 0
    is_hot: bool = False
    is_new: bool = False
    origin: Optional[str] = None
    certificate: Optional[str] = None
    blockchain_hash: Optional[str] = None
    is_welfare: bool = False
    material_verify: str = "天然A货"

class ProductCreate(BaseModel):
    name: str
    description: str
    price: float
    original_price: Optional[float] = None
    category: str
    material: str
    images: List[str] = []
    stock: int = 0
    is_hot: bool = False
    is_new: bool = False
    origin: Optional[str] = None
    is_welfare: bool = False

class Shop(BaseModel):
    id: str
    name: str
    platform: str
    rating: float
    conversion_rate: float
    followers: int
    category: str
    contact_status: str = "pending"
    shop_url: Optional[str] = None
    monthly_sales: Optional[int] = None
    negative_rate: Optional[float] = None
    is_influencer: bool = False
    operator_id: Optional[str] = None
    ai_priority: Optional[int] = None

class Address(BaseModel):
    id: str
    user_id: str
    recipient_name: str
    phone_number: str
    province: str
    city: str
    district: str
    detail_address: str
    is_default: bool = False
    postal_code: Optional[str] = None
    tag: Optional[str] = None

class AddressCreate(BaseModel):
    recipient_name: str
    phone_number: str
    province: str
    city: str
    district: str
    detail_address: str
    is_default: bool = False
    postal_code: Optional[str] = None
    tag: Optional[str] = None

class Order(BaseModel):
    id: str
    user_id: str
    items: List[Dict[str, Any]]
    total_amount: float
    status: str = "pending"
    address: Optional[Dict[str, Any]] = None
    created_at: str
    payment_method: Optional[str] = None
    paid_at: Optional[str] = None
    shipped_at: Optional[str] = None
    delivered_at: Optional[str] = None
    completed_at: Optional[str] = None
    cancelled_at: Optional[str] = None
    cancel_reason: Optional[str] = None
    tracking_number: Optional[str] = None
    logistics_company: Optional[str] = None
    refund_reason: Optional[str] = None
    refund_amount: Optional[float] = None
    logistics_entries: List[Dict[str, Any]] = []
    payment_id: Optional[str] = None

class OrderCreate(BaseModel):
    items: List[Dict[str, Any]]
    address_id: str
    payment_method: str = "wechat"
    remark: Optional[str] = None

class CartItem(BaseModel):
    product_id: str
    quantity: int
    selected: bool = True

class Review(BaseModel):
    id: str
    product_id: str
    user_id: str
    user_name: str
    user_avatar: Optional[str] = None
    rating: int
    content: str
    images: List[str] = []
    video_url: Optional[str] = None
    is_anonymous: bool = False
    created_at: str
    like_count: int = 0
    is_verified: bool = True

class ReviewCreate(BaseModel):
    product_id: str
    order_id: str
    rating: int = Field(..., ge=1, le=5)
    content: str
    images: List[str] = []
    is_anonymous: bool = False

class NotificationRegister(BaseModel):
    device_token: str
    platform: str
    settings: Optional[Dict[str, Any]] = None

class OssStsResponse(BaseModel):
    access_key_id: str
    access_key_secret: str
    security_token: str
    expiration: str

# ============ 模拟数据库 ============

# 用户数据
USERS_DB: Dict[str, Dict] = {
    "admin_001": {
        "id": "admin_001",
        "username": "超级管理员",
        "phone": "18937766669",
        "password": "admin123",
        "is_admin": True,
        "balance": 999999.0,
        "points": 99999,
        "avatar": None,
        "user_type": "admin",
    }
}

# 操作员数据
for i in range(1, 11):
    USERS_DB[f"operator_{i}"] = {
        "id": f"operator_{i}",
        "username": f"操作员{i}",
        "phone": f"1380000000{i}",
        "password": "op123456",
        "is_admin": False,
        "balance": 0.0,
        "points": 100,
        "avatar": None,
        "operator_number": i,
        "user_type": "operator",
    }

# 商品数据
PRODUCTS_DB: Dict[str, Product] = {}

# 初始商品数据（与前端 product_data.dart 同步）
INITIAL_PRODUCTS = [
    # ============ 和田玉系列 ============
    {
        "id": "HYY-HT001",
        "name": "新疆和田玉籽料福运手链",
        "description": "精选新疆和田玉籽料，玉质温润细腻，油性十足。采用传统手工编织工艺，配以金刚结设计，寓意福运绑定、好运连连。",
        "price": 299.0,
        "original_price": 599.0,
        "category": "手链",
        "material": "和田玉",
        "images": ["https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=800&h=800&fit=crop"],
        "stock": 156,
        "rating": 4.9,
        "sales_count": 2341,
        "is_hot": True,
        "is_new": False,
        "origin": "新疆和田",
        "certificate": "GTC-2026-HT001",
        "is_welfare": True,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-HT002",
        "name": "和田玉青白玉平安扣手串",
        "description": "甄选和田青白玉，色泽淡雅，质地均匀。平安扣造型经典，寓意平安健康、万事如意。",
        "price": 399.0,
        "original_price": 798.0,
        "category": "手串",
        "material": "和田玉",
        "images": ["https://images.unsplash.com/photo-1596944924616-7b38e7cfac36?w=800&h=800&fit=crop"],
        "stock": 89,
        "rating": 4.8,
        "sales_count": 1567,
        "is_hot": True,
        "is_new": True,
        "origin": "新疆和田",
        "certificate": "GTC-2026-HT002",
        "is_welfare": True,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-HT003",
        "name": "羊脂白玉貔貅手链",
        "description": "顶级羊脂白玉，白度高、油润细腻。精雕貔貅吊坠，招财纳福，辟邪保平安。限量款式，极具收藏价值。",
        "price": 1280.0,
        "original_price": 2560.0,
        "category": "手链",
        "material": "和田玉",
        "images": ["https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800&h=800&fit=crop"],
        "stock": 35,
        "rating": 5.0,
        "sales_count": 521,
        "is_hot": True,
        "is_new": True,
        "origin": "新疆和田",
        "certificate": "GTC-2026-HT003",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    # ============ 缅甸翡翠系列 ============
    {
        "id": "HYY-FC001",
        "name": "缅甸翡翠平安扣吊坠",
        "description": "缅甸A货翡翠，冰种质地，透明度高。飘花自然灵动，采用18K金镶嵌，高贵典雅。",
        "price": 1580.0,
        "original_price": 3160.0,
        "category": "吊坠",
        "material": "缅甸翡翠",
        "images": ["https://images.unsplash.com/photo-1588444837495-c6cfeb53f32d?w=800&h=800&fit=crop"],
        "stock": 45,
        "rating": 4.9,
        "sales_count": 876,
        "is_hot": True,
        "is_new": False,
        "origin": "缅甸",
        "certificate": "GIA-2026-FC001",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-FC002",
        "name": "满绿翡翠圆珠手链",
        "description": "天然缅甸翡翠，满绿色泽，颜色均匀。圆珠直径8mm，珠珠饱满润泽。经国家权威机构鉴定。",
        "price": 2380.0,
        "original_price": 4760.0,
        "category": "手链",
        "material": "缅甸翡翠",
        "images": ["https://images.unsplash.com/photo-1603561591411-07134e71a2a9?w=800&h=800&fit=crop"],
        "stock": 28,
        "rating": 4.8,
        "sales_count": 432,
        "is_hot": False,
        "is_new": True,
        "origin": "缅甸",
        "certificate": "GIA-2026-FC002",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-FC003",
        "name": "糯冰翡翠葫芦耳环",
        "description": "糯冰种翡翠，质地细腻温润。葫芦造型，寓意福禄双全。925银镶嵌，防过敏材质。",
        "price": 599.0,
        "original_price": 1198.0,
        "category": "耳饰",
        "material": "缅甸翡翠",
        "images": ["https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=800&h=800&fit=crop"],
        "stock": 67,
        "rating": 4.7,
        "sales_count": 789,
        "is_hot": False,
        "is_new": False,
        "origin": "缅甸",
        "certificate": "GIA-2026-FC003",
        "is_welfare": True,
        "material_verify": "天然A货",
    },
    # ============ 南红玛瑙系列 ============
    {
        "id": "HYY-NH001",
        "name": "凉山南红玛瑙转运珠手链",
        "description": "四川凉山南红，色泽浓郁、质地温润。转运珠设计，寓意时来运转。纯手工打磨抛光。",
        "price": 199.0,
        "original_price": 398.0,
        "category": "手链",
        "material": "南红玛瑙",
        "images": ["https://images.unsplash.com/photo-1602751584552-8ba73aad10e1?w=800&h=800&fit=crop"],
        "stock": 234,
        "rating": 4.8,
        "sales_count": 3456,
        "is_hot": True,
        "is_new": False,
        "origin": "四川凉山",
        "certificate": "NGTC-2026-NH001",
        "is_welfare": True,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-NH002",
        "name": "柿子红南红玛瑙圆珠项链",
        "description": "顶级柿子红南红，颜色饱满艳丽。圆珠均匀，直径6mm，总长45cm。",
        "price": 1680.0,
        "original_price": 3360.0,
        "category": "项链",
        "material": "南红玛瑙",
        "images": ["https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800&h=800&fit=crop"],
        "stock": 42,
        "rating": 4.9,
        "sales_count": 234,
        "is_hot": False,
        "is_new": True,
        "origin": "四川凉山",
        "certificate": "NGTC-2026-NH002",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    # ============ 紫水晶系列 ============
    {
        "id": "HYY-ZS001",
        "name": "乌拉圭紫水晶貔貅手串",
        "description": "乌拉圭顶级紫水晶，色泽深邃浓郁。精雕貔貅吊坠，招财辟邪。水晶珠子通透，光感极佳。",
        "price": 299.0,
        "original_price": 598.0,
        "category": "手串",
        "material": "紫水晶",
        "images": ["https://images.unsplash.com/photo-1629224316810-9d8805b95e76?w=800&h=800&fit=crop"],
        "stock": 123,
        "rating": 4.7,
        "sales_count": 1234,
        "is_hot": False,
        "is_new": False,
        "origin": "乌拉圭",
        "certificate": "IGI-2026-ZS001",
        "is_welfare": True,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-ZS002",
        "name": "紫晶洞摆件(小号)",
        "description": "巴西紫晶洞，晶体饱满，颜色紫艳。天然形成，每件形态独特。适合放置家中或办公桌。",
        "price": 880.0,
        "original_price": 1760.0,
        "category": "摆件",
        "material": "紫水晶",
        "images": ["https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=800&h=800&fit=crop"],
        "stock": 56,
        "rating": 4.8,
        "sales_count": 567,
        "is_hot": False,
        "is_new": True,
        "origin": "巴西",
        "certificate": "IGI-2026-ZS002",
        "is_welfare": False,
        "material_verify": "天然",
    },
    # ============ 黄金系列 ============
    {
        "id": "HYY-HJ001",
        "name": "古法黄金传承手镯",
        "description": "采用古法黄金工艺，哑光磨砂质感。福字祥云纹饰，足金999，约20克重。",
        "price": 15600.0,
        "original_price": 16800.0,
        "category": "手镯",
        "material": "黄金",
        "images": ["https://images.unsplash.com/photo-1619119069152-a2b331eb392a?w=800&h=800&fit=crop"],
        "stock": 20,
        "rating": 4.9,
        "sales_count": 899,
        "is_hot": False,
        "is_new": False,
        "origin": "中国",
        "certificate": "NGTC-2026-HJ001",
        "is_welfare": False,
        "material_verify": "足金999",
    },
    {
        "id": "HYY-HJ002",
        "name": "3D硬金转运珠吊坠",
        "description": "3D硬金工艺，轻便不变形。转运珠造型，精巧玲珑。约1克重，含精美链条。",
        "price": 580.0,
        "original_price": 780.0,
        "category": "吊坠",
        "material": "黄金",
        "images": ["https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=800&h=800&fit=crop"],
        "stock": 88,
        "rating": 4.8,
        "sales_count": 1567,
        "is_hot": False,
        "is_new": False,
        "origin": "中国",
        "certificate": "NGTC-2026-HJ002",
        "is_welfare": True,
        "material_verify": "足金999",
    },
    {
        "id": "HYY-HJ003",
        "name": "足金999莲花吊坠",
        "description": "精雕莲花造型，寓意出淤泥而不染。足金999，约3克重。3D硬金工艺，立体饱满。",
        "price": 1880.0,
        "original_price": 2380.0,
        "category": "吊坠",
        "material": "黄金",
        "images": ["https://images.unsplash.com/photo-1543294001-f7cd5d7fb516?w=800&h=800&fit=crop"],
        "stock": 50,
        "rating": 4.9,
        "sales_count": 678,
        "is_hot": True,
        "is_new": True,
        "origin": "中国",
        "certificate": "NGTC-2026-HJ003",
        "is_welfare": False,
        "material_verify": "足金999",
    },
    # ============ 红宝石系列 ============
    {
        "id": "HYY-HB001",
        "name": "18K金镶嵌缅甸红宝石戒指",
        "description": "缅甸天然红宝石，鸽血红色泽。18K玫瑰金镶嵌，群镶小钻点缀。国际GRS证书认证。",
        "price": 3580.0,
        "original_price": 6880.0,
        "category": "戒指",
        "material": "红宝石",
        "images": ["https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800&h=800&fit=crop"],
        "stock": 15,
        "rating": 5.0,
        "sales_count": 321,
        "is_hot": True,
        "is_new": True,
        "origin": "缅甸",
        "certificate": "GRS-2026-HB001",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    # ============ 蓝宝石系列 ============
    {
        "id": "HYY-LB001",
        "name": "斯里兰卡蓝宝石吊坠",
        "description": "斯里兰卡天然蓝宝石，矢车菊蓝。18K白金镶嵌，简约大气。重约1.2克拉，附GRS证书。",
        "price": 8880.0,
        "original_price": 12800.0,
        "category": "吊坠",
        "material": "蓝宝石",
        "images": ["https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop"],
        "stock": 8,
        "rating": 5.0,
        "sales_count": 89,
        "is_hot": False,
        "is_new": True,
        "origin": "斯里兰卡",
        "certificate": "GRS-2026-LB001",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    # ============ 蜜蜡系列 ============
    {
        "id": "HYY-ML001",
        "name": "波罗的海鸡油黄蜜蜡手串",
        "description": "纯天然波罗的海蜜蜡，鸡油黄色。圆珠直径10mm，颜色均匀。蜡质浓郁，盘玩效果佳。",
        "price": 499.0,
        "original_price": 998.0,
        "category": "手串",
        "material": "蜜蜡",
        "images": ["https://images.unsplash.com/photo-1608042314453-ae338d80c427?w=800&h=800&fit=crop"],
        "stock": 78,
        "rating": 4.8,
        "sales_count": 876,
        "is_hot": False,
        "is_new": False,
        "origin": "波罗的海",
        "certificate": "NGTC-2026-ML001",
        "is_welfare": True,
        "material_verify": "天然A货",
    },
    # ============ 碧玉系列 ============
    {
        "id": "HYY-BY001",
        "name": "俄罗斯碧玉菠菜绿手镯",
        "description": "俄罗斯碧玉，菠菜绿色，质地细腻。圆条款式，内径56-60mm可选。经典传承款。",
        "price": 2680.0,
        "original_price": 5360.0,
        "category": "手镯",
        "material": "碧玉",
        "images": ["https://images.unsplash.com/photo-1610375461246-83df859d849d?w=800&h=800&fit=crop"],
        "stock": 32,
        "rating": 4.7,
        "sales_count": 234,
        "is_hot": False,
        "is_new": False,
        "origin": "俄罗斯",
        "certificate": "NGTC-2026-BY001",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    # ============ 新增商品 ============
    {
        "id": "HYY-HT004",
        "name": "和田玉墨玉龙凤手镯",
        "description": "新疆和田墨玉，色如浓墨，质感沉稳。龙凤雕纹，寓意龙凤呈祥。圆条款式，适合婚嫁。",
        "price": 3980.0,
        "original_price": 6800.0,
        "category": "手镯",
        "material": "和田玉",
        "images": ["https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?w=800&h=800&fit=crop"],
        "stock": 18,
        "rating": 4.9,
        "sales_count": 156,
        "is_hot": False,
        "is_new": True,
        "origin": "新疆和田",
        "certificate": "NGTC-2026-HT004",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-FC004",
        "name": "冰糯种翡翠观音吊坠",
        "description": "缅甸冰糯种翡翠，温润透亮。观音法相庄严，保佑平安。18K白金镶嵌。",
        "price": 2280.0,
        "original_price": 4560.0,
        "category": "吊坠",
        "material": "缅甸翡翠",
        "images": ["https://images.unsplash.com/photo-1600721391776-b5cd0e0048f9?w=800&h=800&fit=crop"],
        "stock": 25,
        "rating": 4.8,
        "sales_count": 345,
        "is_hot": True,
        "is_new": False,
        "origin": "缅甸",
        "certificate": "GTC-2026-FC004",
        "is_welfare": False,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-ZJ001",
        "name": "18K玫瑰金钻石项链",
        "description": "18K玫瑰金链条，光泽柔美。主钻0.3克拉，SI净度，H色级。锁骨链设计。",
        "price": 4680.0,
        "original_price": 6800.0,
        "category": "项链",
        "material": "钻石",
        "images": ["https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800&h=800&fit=crop"],
        "stock": 12,
        "rating": 5.0,
        "sales_count": 189,
        "is_hot": True,
        "is_new": True,
        "origin": "南非",
        "certificate": "GIA-2026-ZJ001",
        "is_welfare": False,
        "material_verify": "天然钻石",
    },
    {
        "id": "HYY-NH003",
        "name": "保山南红玛瑙如意锁吊坠",
        "description": "云南保山南红，柿子红满色。如意锁造型，寓意吉祥如意。纯银镶嵌，赠送项链。",
        "price": 458.0,
        "original_price": 916.0,
        "category": "吊坠",
        "material": "南红玛瑙",
        "images": ["https://images.unsplash.com/photo-1583484963886-cfe2bff2945f?w=800&h=800&fit=crop"],
        "stock": 98,
        "rating": 4.7,
        "sales_count": 567,
        "is_hot": False,
        "is_new": False,
        "origin": "云南保山",
        "certificate": "NGTC-2026-NH003",
        "is_welfare": True,
        "material_verify": "天然A货",
    },
    {
        "id": "HYY-PT001",
        "name": "天然珍珠优雅项链套装",
        "description": "天然淡水珍珠，圆润光泽。7-8mm珍珠，搭配耳饰套装。925银扣，防过敏材质。",
        "price": 368.0,
        "original_price": 736.0,
        "category": "项链",
        "material": "珍珠",
        "images": ["https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop&q=80"],
        "stock": 120,
        "rating": 4.6,
        "sales_count": 2345,
        "is_hot": True,
        "is_new": False,
        "origin": "中国浙江",
        "certificate": "NGTC-2026-PT001",
        "is_welfare": True,
        "material_verify": "天然珍珠",
    },
    {
        "id": "HYY-HJ004",
        "name": "黄金转运珠红绳手链",
        "description": "足金999转运珠，约0.5克。手编红绳，寓意红红火火。男女通用，尺寸可调。",
        "price": 289.0,
        "original_price": 399.0,
        "category": "手链",
        "material": "黄金",
        "images": ["https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=800&h=800&fit=crop"],
        "stock": 200,
        "rating": 4.8,
        "sales_count": 4567,
        "is_hot": True,
        "is_new": False,
        "origin": "中国",
        "certificate": "NGTC-2026-HJ004",
        "is_welfare": True,
        "material_verify": "足金999",
    },
]

for p in INITIAL_PRODUCTS:
    p["blockchain_hash"] = f"0x{uuid.uuid4().hex[:40]}"
    PRODUCTS_DB[p["id"]] = Product(**p)

# 店铺数据
SHOPS_DB: Dict[str, Shop] = {}

# 地址数据
ADDRESSES_DB: Dict[str, Address] = {}

# 订单数据
ORDERS_DB: Dict[str, Order] = {}

# 购物车数据
CARTS_DB: Dict[str, List[CartItem]] = {}

# 收藏数据
FAVORITES_DB: Dict[str, List[str]] = {}

# 评价数据
REVIEWS_DB: Dict[str, Review] = {}

# Token映射
TOKENS_DB: Dict[str, str] = {}  # token -> user_id

# 设备Token
DEVICES_DB: Dict[str, Dict] = {}  # device_token -> device_info

# ============ 辅助函数 ============

def generate_token() -> str:
    return f"token_{uuid.uuid4().hex}"

def get_current_user_id(token: str) -> Optional[str]:
    """从Token获取用户ID"""
    # 简化的Token验证
    if token.startswith("Bearer "):
        token = token[7:]
    return TOKENS_DB.get(token)

def verify_token(authorization: str = None) -> str:
    """验证Token并返回用户ID"""
    if not authorization:
        raise HTTPException(status_code=401, detail="未提供认证Token")
    
    user_id = get_current_user_id(authorization)
    if not user_id:
        raise HTTPException(status_code=401, detail="Token无效或已过期")
    
    return user_id

# ============ API路由 ============

# --- 健康检查 ---

@app.get("/")
async def root():
    return {"message": "汇玉源API服务运行中", "version": "3.0.0", "status": "healthy"}

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "3.0.0"
    }

# --- 认证 ---

@app.post("/api/auth/login")
async def login(request: LoginRequest):
    """用户登录"""
    if request.type == "admin":
        # 管理员登录
        if request.username == "18937766669" and request.password == "admin123":
            if request.captcha and request.captcha != "8888":
                raise HTTPException(status_code=400, detail="验证码错误")
            
            token = generate_token()
            TOKENS_DB[token] = "admin_001"
            
            user = USERS_DB["admin_001"]
            return {
                "success": True,
                "token": token,
                "refresh_token": f"refresh_{token}",
                "expires_in": 3600,
                "user": UserResponse(**user).dict()
            }
    elif request.type == "operator" and getattr(request, 'login_type', None) != 'customer_sms':
        # 操作员登录
        operator_id = None
        try:
            op_num = int(request.username) if request.username else 0
            if 1 <= op_num <= 10:
                operator_id = f"operator_{op_num}"
        except (ValueError, TypeError):
            # 尝试按用户名查找
            for uid, user in USERS_DB.items():
                if user.get("username") == request.username:
                    operator_id = uid
                    break
        
        if operator_id and operator_id in USERS_DB:
            user = USERS_DB[operator_id]
            if user["password"] == request.password:
                token = generate_token()
                TOKENS_DB[token] = operator_id
                
                return {
                    "success": True,
                    "token": token,
                    "refresh_token": f"refresh_{token}",
                    "expires_in": 3600,
                    "user": UserResponse(**user).dict()
                }

    if getattr(request, 'login_type', None) == 'customer_sms' or request.type == 'customer_sms':
        if not request.phone or not request.code:
            raise HTTPException(status_code=400, detail="手机号和验证码不能为空")
        
        # 验证码逻辑：8888 或等于手机号后4位
        expected_code = request.phone[-4:] if len(request.phone) >= 4 else request.phone
        if request.code != '8888' and request.code != expected_code:
            raise HTTPException(status_code=400, detail="验证码错误")
            
        user_id = None
        for uid, user in USERS_DB.items():
            if user.get("phone") == request.phone:
                user_id = uid
                break
                
        if not user_id:
            user_id = f"customer_{int(datetime.now().timestamp() * 1000)}"
            USERS_DB[user_id] = {
                "id": user_id,
                "username": f"用户_{expected_code}",
                "phone": request.phone,
                "password": "",
                "is_admin": False,
                "balance": 0.0,
                "points": 0,
                "avatar": None,
                "user_type": "customer"
            }
            
        token = generate_token()
        TOKENS_DB[token] = user_id
        
        user = USERS_DB[user_id]
        return {
            "success": True,
            "token": token,
            "refresh_token": f"refresh_{token}",
            "expires_in": 3600,
            "user": UserResponse(**user).dict()
        }
    
    raise HTTPException(status_code=401, detail="用户名或密码错误")

# ============================================================
# SMS 认证路由（任务A）
# ============================================================

class SmsCodeRequest(BaseModel):
    phone: str
    action: str = "login"  # login / register

class SmsVerifyRequest(BaseModel):
    phone: str
    code: str
    action: str = "login"

# Redis key helpers
def _sms_code_key(phone: str)  -> str: return f"sms:code:{phone}"
def _sms_cool_key(phone: str)  -> str: return f"sms:cool:{phone}"   # 60s 冷却
def _sms_day_key(phone: str)   -> str: return f"sms:day:{phone}:{datetime.utcnow().strftime('%Y%m%d')}"
def _sms_err_key(phone: str)   -> str: return f"sms:err:{phone}"    # 连续错误计数


@app.post("/api/auth/send-sms")
async def send_sms_code(body: SmsCodeRequest, request: Request):
    """发送短信验证码（含 Redis 限流）"""
    import re
    if not re.match(r"^1[3-9]\d{9}$", body.phone):
        raise HTTPException(status_code=400, detail="手机号格式错误")

    code = str(random.randint(100000, 999999))

    if REDIS_AVAILABLE:
        # 60 秒冷却
        if redis_client.exists(_sms_cool_key(body.phone)):
            ttl = redis_client.ttl(_sms_cool_key(body.phone))
            raise HTTPException(status_code=429, detail=f"发送太频繁，请 {ttl} 秒后重试")
        # 每日上限 10 次
        day_count = int(redis_client.get(_sms_day_key(body.phone)) or 0)
        if day_count >= 10:
            raise HTTPException(status_code=429, detail="今日发送次数已达上限（10次）")
        # 存储验证码 5 分钟有效
        redis_client.setex(_sms_code_key(body.phone), 300, code)
        redis_client.setex(_sms_cool_key(body.phone), 60, "1")
        redis_client.incr(_sms_day_key(body.phone))
        redis_client.expire(_sms_day_key(body.phone), 86400)
        redis_client.delete(_sms_err_key(body.phone))  # 新发送重置错误计数
    else:
        code = "8888"  # Redis 不可用时用固定测试码

    # 记录发送日志
    biz_id = ""
    if SMS_REAL_MODE:
        result = _send_aliyun_sms(body.phone, code)
        biz_id = result.get("biz_id", "")
        if not result["success"]:
            logging.error(f"SMS send failed for {body.phone}: {result['message']}")
            raise HTTPException(status_code=502, detail="短信发送失败，请稍后重试")

    # 写入数据库日志（可选）
    if DB_AVAILABLE:
        try:
            db: Session = SessionLocal()
            ip_addr = request.client.host if request.client else None
            db.execute(
                text("INSERT INTO sms_logs(phone, action, biz_id, ip_addr) VALUES(:phone, :action, :biz_id, :ip)"),
                {"phone": body.phone, "action": body.action, "biz_id": biz_id, "ip": ip_addr}
            )
            db.commit()
            db.close()
        except Exception as e:
            logging.warning(f"SMS log write failed: {e}")

    if SMS_REAL_MODE:
        return {"success": True, "message": "验证码已发送，5分钟内有效"}
    else:
        return {"success": True, "message": f"（测试模式）验证码：{code}"}


@app.post("/api/auth/verify-sms")
async def verify_sms_code(body: SmsVerifyRequest, db: Optional[Session] = Depends(get_db)):
    """校验短信验证码，自动注册新用户并返回 JWT"""
    import re
    if not re.match(r"^1[3-9]\d{9}$", body.phone):
        raise HTTPException(status_code=400, detail="手机号格式错误")

    # ---- 验证码校验 ----
    if REDIS_AVAILABLE:
        err_count = int(redis_client.get(_sms_err_key(body.phone)) or 0)
        if err_count >= 5:
            raise HTTPException(status_code=429, detail="错误次数过多，请重新获取验证码")

        stored = redis_client.get(_sms_code_key(body.phone))
        if not stored:
            raise HTTPException(status_code=400, detail="验证码已过期或未发送")
        if stored != body.code:
            redis_client.incr(_sms_err_key(body.phone))
            redis_client.expire(_sms_err_key(body.phone), 1800)
            raise HTTPException(status_code=400, detail="验证码错误")
        # 验证成功：删除验证码（一次性）
        redis_client.delete(_sms_code_key(body.phone))
        redis_client.delete(_sms_err_key(body.phone))
    else:
        # Redis 不可用：接受 8888 或手机后4位
        expected = body.phone[-4:]
        if body.code not in ("8888", expected):
            raise HTTPException(status_code=400, detail="验证码错误")

    # ---- 查找或创建用户 ----
    user_id   = None
    user_data = None

    if db is not None:
        try:
            row = db.execute(
                text("SELECT id, phone, username, user_type, balance, points, avatar_url FROM users WHERE phone = :phone"),
                {"phone": body.phone}
            ).fetchone()
            if row:
                user_id   = row[0]
                user_data = {"id": row[0], "phone": row[1], "username": row[2],
                             "user_type": row[3], "balance": float(row[4]),
                             "points": row[5], "avatar": row[6], "is_admin": False}
            else:
                user_id = f"u_{uuid.uuid4().hex[:16]}"
                uname   = f"用户{body.phone[-4:]}"
                db.execute(
                    text("INSERT INTO users(id, phone, username, user_type) VALUES(:id, :phone, :username, 'customer')"),
                    {"id": user_id, "phone": body.phone, "username": uname}
                )
                db.commit()
                user_data = {"id": user_id, "phone": body.phone, "username": uname,
                             "user_type": "customer", "balance": 0.0, "points": 0,
                             "avatar": None, "is_admin": False}
        except Exception as e:
            logging.error(f"DB error in verify_sms: {e}")
            db.rollback()

    # ---- 降级：内存数据库 ----
    if user_data is None:
        for uid, u in USERS_DB.items():
            if u.get("phone") == body.phone:
                user_id   = uid
                user_data = {**u, "avatar": u.get("avatar")}
                break
        if not user_data:
            user_id = f"customer_{int(datetime.now().timestamp()*1000)}"
            user_data = {"id": user_id, "phone": body.phone,
                         "username": f"用户{body.phone[-4:]}",
                         "user_type": "customer", "balance": 0.0,
                         "points": 0, "avatar": None, "is_admin": False}
            USERS_DB[user_id] = {**user_data, "password": ""}

    # ---- 生成 Token ----
    token         = create_jwt_token(user_id, {"phone": body.phone})
    refresh_token = create_jwt_token(user_id, {"phone": body.phone, "refresh": True,
                                               "exp": datetime.utcnow() + timedelta(days=30)})
    # 同时写内存 TOKENS_DB，让旧接口兼容
    TOKENS_DB[token] = user_id

    return {
        "success":       True,
        "token":         token,
        "refresh_token": refresh_token,
        "expires_in":    JWT_EXPIRE_SECONDS if JWT_AVAILABLE else 3600,
        "user":          UserResponse(**user_data).model_dump()
    }


@app.post("/api/auth/logout")
async def logout(authorization: str = None):
    """用户登出"""
    if authorization:
        token = authorization.replace("Bearer ", "")
        TOKENS_DB.pop(token, None)
    return {"success": True, "message": "已退出登录"}

@app.post("/api/auth/refresh")
async def refresh_token(authorization: str = None):
    """刷新Token"""
    user_id = get_current_user_id(authorization or "")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token无效")
    
    # 生成新Token
    new_token = generate_token()
    TOKENS_DB[new_token] = user_id
    
    # 移除旧Token
    old_token = (authorization or "").replace("Bearer ", "")
    TOKENS_DB.pop(old_token, None)
    
    return {
        "token": new_token,
        "refresh_token": f"refresh_{new_token}",
        "expires_in": 3600
    }

# --- 商品 ---

@app.get("/api/products", response_model=List[Product])
async def get_products(
    category: Optional[str] = None,
    material: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    is_hot: Optional[bool] = None,
    is_new: Optional[bool] = None,
    is_welfare: Optional[bool] = None,
    search: Optional[str] = None,
    sort_by: Optional[str] = None,
    page: int = 1,
    page_size: int = 20
):
    """获取商品列表"""
    products = list(PRODUCTS_DB.values())
    
    # 筛选
    if category and category != "全部":
        products = [p for p in products if p.category == category]
    if material:
        products = [p for p in products if p.material == material]
    if min_price is not None:
        products = [p for p in products if p.price >= min_price]
    if max_price is not None:
        products = [p for p in products if p.price <= max_price]
    if is_hot is not None:
        products = [p for p in products if p.is_hot == is_hot]
    if is_new is not None:
        products = [p for p in products if p.is_new == is_new]
    if is_welfare is not None:
        products = [p for p in products if p.is_welfare == is_welfare]
    if search:
        products = [p for p in products if search.lower() in p.name.lower() or search.lower() in p.description.lower()]
    
    # 排序
    if sort_by == "price_asc":
        products.sort(key=lambda x: x.price)
    elif sort_by == "price_desc":
        products.sort(key=lambda x: x.price, reverse=True)
    elif sort_by == "sales":
        products.sort(key=lambda x: x.sales_count, reverse=True)
    elif sort_by == "rating":
        products.sort(key=lambda x: x.rating, reverse=True)
    
    # 分页
    start = (page - 1) * page_size
    end = start + page_size
    
    return products[start:end]

@app.get("/api/products/{product_id}", response_model=Product)
async def get_product_detail(product_id: str):
    """获取商品详情"""
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    return PRODUCTS_DB[product_id]

@app.post("/api/products", response_model=Product)
async def create_product(product: ProductCreate, authorization: str = None):
    """创建商品（管理员）"""
    user_id = verify_token(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="没有权限")
    
    product_id = f"HYY-{uuid.uuid4().hex[:6].upper()}"
    new_product = Product(
        id=product_id,
        blockchain_hash=f"0x{uuid.uuid4().hex[:40]}",
        certificate=f"GTC-2026-{product_id[-6:]}",
        **product.dict()
    )
    PRODUCTS_DB[product_id] = new_product
    return new_product

@app.put("/api/products/{product_id}", response_model=Product)
async def update_product(product_id: str, product: ProductCreate, authorization: str = None):
    """更新商品（管理员）"""
    user_id = verify_token(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="没有权限")
    
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    
    existing = PRODUCTS_DB[product_id]
    updated = Product(
        id=product_id,
        blockchain_hash=existing.blockchain_hash,
        certificate=existing.certificate,
        rating=existing.rating,
        sales_count=existing.sales_count,
        **product.dict()
    )
    PRODUCTS_DB[product_id] = updated
    return updated

@app.delete("/api/products/{product_id}")
async def delete_product(product_id: str, authorization: str = None):
    """删除商品（管理员）"""
    user_id = verify_token(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="没有权限")
    
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    
    del PRODUCTS_DB[product_id]
    return {"success": True, "message": "商品已删除"}

# --- 店铺 ---

@app.get("/api/shops", response_model=List[Shop])
async def get_shops(
    platform: Optional[str] = None,
    category: Optional[str] = None,
    contact_status: Optional[str] = None,
    is_influencer: Optional[bool] = None,
    operator_id: Optional[str] = None,
    page: int = 1,
    page_size: int = 20
):
    """获取店铺列表"""
    shops = list(SHOPS_DB.values())
    
    if platform:
        shops = [s for s in shops if s.platform == platform]
    if category:
        shops = [s for s in shops if s.category == category]
    if contact_status:
        shops = [s for s in shops if s.contact_status == contact_status]
    if is_influencer is not None:
        shops = [s for s in shops if s.is_influencer == is_influencer]
    if operator_id:
        shops = [s for s in shops if s.operator_id == operator_id]
    
    # 按AI优先级排序
    shops.sort(key=lambda x: x.ai_priority or 0, reverse=True)
    
    start = (page - 1) * page_size
    end = start + page_size
    
    return shops[start:end]

@app.get("/api/shops/{shop_id}", response_model=Shop)
async def get_shop_detail(shop_id: str):
    """获取店铺详情"""
    if shop_id not in SHOPS_DB:
        raise HTTPException(status_code=404, detail="店铺不存在")
    return SHOPS_DB[shop_id]

# --- 地址 ---

@app.get("/api/users/addresses", response_model=List[Address])
async def get_addresses(authorization: str = None):
    """获取用户地址列表"""
    user_id = verify_token(authorization)
    addresses = [a for a in ADDRESSES_DB.values() if a.user_id == user_id]
    # 默认地址排前面
    addresses.sort(key=lambda x: x.is_default, reverse=True)
    return addresses

@app.post("/api/users/addresses", response_model=Address)
async def create_address(address: AddressCreate, authorization: str = None):
    """创建地址"""
    user_id = verify_token(authorization)
    
    address_id = f"addr_{uuid.uuid4().hex[:8]}"
    
    # 如果设为默认，取消其他默认
    if address.is_default:
        for addr in ADDRESSES_DB.values():
            if addr.user_id == user_id:
                addr.is_default = False
    
    new_address = Address(id=address_id, user_id=user_id, **address.dict())
    ADDRESSES_DB[address_id] = new_address
    return new_address

@app.put("/api/users/addresses/{address_id}", response_model=Address)
async def update_address(address_id: str, address: AddressCreate, authorization: str = None):
    """更新地址"""
    user_id = verify_token(authorization)
    
    if address_id not in ADDRESSES_DB:
        raise HTTPException(status_code=404, detail="地址不存在")
    
    existing = ADDRESSES_DB[address_id]
    if existing.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    
    # 如果设为默认，取消其他默认
    if address.is_default:
        for addr in ADDRESSES_DB.values():
            if addr.user_id == user_id and addr.id != address_id:
                addr.is_default = False
    
    updated = Address(id=address_id, user_id=user_id, **address.dict())
    ADDRESSES_DB[address_id] = updated
    return updated

@app.delete("/api/users/addresses/{address_id}")
async def delete_address(address_id: str, authorization: str = None):
    """删除地址"""
    user_id = verify_token(authorization)
    
    if address_id not in ADDRESSES_DB:
        raise HTTPException(status_code=404, detail="地址不存在")
    
    if ADDRESSES_DB[address_id].user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    
    del ADDRESSES_DB[address_id]
    return {"success": True, "message": "地址已删除"}

# --- 购物车 ---

@app.get("/api/cart")
async def get_cart(authorization: str = None):
    """获取购物车"""
    user_id = verify_token(authorization)
    cart = CARTS_DB.get(user_id, [])
    
    # 附带商品信息
    items = []
    for item in cart:
        if item.product_id in PRODUCTS_DB:
            product = PRODUCTS_DB[item.product_id]
            items.append({
                "product_id": item.product_id,
                "quantity": item.quantity,
                "selected": item.selected,
                "product": product.dict()
            })
    
    return {"items": items, "total": len(items)}

@app.post("/api/cart")
async def add_to_cart(item: CartItem, authorization: str = None):
    """添加到购物车"""
    user_id = verify_token(authorization)
    
    if item.product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    
    if user_id not in CARTS_DB:
        CARTS_DB[user_id] = []
    
    # 检查是否已存在
    for existing in CARTS_DB[user_id]:
        if existing.product_id == item.product_id:
            existing.quantity += item.quantity
            return {"success": True, "message": "已更新数量"}
    
    CARTS_DB[user_id].append(item)
    return {"success": True, "message": "已添加到购物车"}

@app.put("/api/cart/{product_id}")
async def update_cart_item(product_id: str, quantity: int, authorization: str = None):
    """更新购物车商品数量"""
    user_id = verify_token(authorization)
    
    if user_id not in CARTS_DB:
        raise HTTPException(status_code=404, detail="购物车为空")
    
    for item in CARTS_DB[user_id]:
        if item.product_id == product_id:
            if quantity <= 0:
                CARTS_DB[user_id].remove(item)
            else:
                item.quantity = quantity
            return {"success": True}
    
    raise HTTPException(status_code=404, detail="商品不在购物车中")

@app.delete("/api/cart/{product_id}")
async def remove_from_cart(product_id: str, authorization: str = None):
    """从购物车移除"""
    user_id = verify_token(authorization)
    
    if user_id in CARTS_DB:
        CARTS_DB[user_id] = [i for i in CARTS_DB[user_id] if i.product_id != product_id]
    
    return {"success": True, "message": "已从购物车移除"}

@app.delete("/api/cart")
async def clear_cart(authorization: str = None):
    """清空购物车"""
    user_id = verify_token(authorization)
    CARTS_DB[user_id] = []
    return {"success": True, "message": "购物车已清空"}

# --- 订单 ---

@app.get("/api/orders", response_model=List[Order])
async def get_orders(
    status: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    authorization: str = None
):
    """获取订单列表"""
    user_id = verify_token(authorization)
    
    orders = [o for o in ORDERS_DB.values() if o.user_id == user_id]
    
    if status:
        orders = [o for o in orders if o.status == status]
    
    orders.sort(key=lambda x: x.created_at, reverse=True)
    
    start = (page - 1) * page_size
    end = start + page_size
    
    return orders[start:end]

@app.get("/api/orders/{order_id}", response_model=Order)
async def get_order_detail(order_id: str, authorization: str = None):
    """获取订单详情"""
    user_id = verify_token(authorization)
    
    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")
    
    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    
    return order

@app.post("/api/orders", response_model=Order)
async def create_order(order: OrderCreate, authorization: str = None):
    """创建订单"""
    user_id = verify_token(authorization)
    
    # 验证地址
    if order.address_id not in ADDRESSES_DB:
        raise HTTPException(status_code=400, detail="地址不存在")
    
    address = ADDRESSES_DB[order.address_id]
    if address.user_id != user_id:
        raise HTTPException(status_code=403, detail="地址不属于当前用户")
    
    # 计算总金额
    total = 0.0
    items = []
    for item in order.items:
        if item["product_id"] not in PRODUCTS_DB:
            raise HTTPException(status_code=400, detail=f"商品 {item['product_id']} 不存在")
        
        product = PRODUCTS_DB[item["product_id"]]
        quantity = item.get("quantity", 1)

        # 库存校验 + 原子扣减
        if product.stock < quantity:
            raise HTTPException(
                status_code=400,
                detail=f"商品 {product.name} 库存不足 (剩余{product.stock}件)"
            )
        PRODUCTS_DB[item["product_id"]] = Product(
            **{**product.dict(), "stock": product.stock - quantity,
               "sales_count": product.sales_count + quantity}
        )

        total += product.price * quantity
        items.append({
            "product_id": item["product_id"],
            "product_name": product.name,
            "price": product.price,
            "quantity": quantity,
            "image": product.images[0] if product.images else None
        })
    
    order_id = f"ORD{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(1000, 9999)}"
    
    new_order = Order(
        id=order_id,
        user_id=user_id,
        items=items,
        total_amount=total,
        status="pending",
        address=address.dict(),
        created_at=datetime.now().isoformat(),
        payment_method=order.payment_method
    )
    
    ORDERS_DB[order_id] = new_order
    
    # 清空购物车中已下单的商品
    if user_id in CARTS_DB:
        ordered_ids = {i["product_id"] for i in order.items}
        CARTS_DB[user_id] = [i for i in CARTS_DB[user_id] if i.product_id not in ordered_ids]
    
    return new_order

@app.post("/api/orders/checkout")
async def checkout(data: dict, authorization: str = None):
    """结算（模拟支付）"""
    # 简化版结算，实际需要对接支付网关
    return {
        "success": True,
        "order_id": data.get("order_id"),
        "payment_url": f"https://pay.example.com/{data.get('order_id')}",
        "message": "请完成支付"
    }


# --- 支付网关(模拟) ---

# 内存支付记录
PAYMENTS_DB: Dict[str, Dict] = {}

@app.post("/api/orders/{order_id}/pay")
async def pay_order(order_id: str, data: dict = None, authorization: str = None):
    """发起支付 — 创建支付记录，3秒后自动模拟回调成功"""
    user_id = verify_token(authorization)
    data = data or {}

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    if order.status != "pending":
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法支付")

    payment_id = f"PAY{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(1000,9999)}"
    method = data.get("method", order.payment_method or "wechat")

    PAYMENTS_DB[payment_id] = {
        "id": payment_id,
        "order_id": order_id,
        "amount": order.total_amount,
        "method": method,
        "status": "pending",
        "created_at": datetime.now().isoformat(),
    }

    # 标记订单的 payment_id
    ORDERS_DB[order_id] = Order(**{**order.dict(), "payment_id": payment_id})

    return {
        "success": True,
        "payment_id": payment_id,
        "amount": order.total_amount,
        "method": method,
        "status": "pending",
        "message": "支付已创建，请等待确认",
    }


@app.get("/api/orders/{order_id}/pay-status")
async def get_pay_status(order_id: str, authorization: str = None):
    """轮询支付状态 — 自动在创建3秒后标记为成功"""
    user_id = verify_token(authorization)

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")

    pid = order.payment_id
    if not pid or pid not in PAYMENTS_DB:
        return {"status": "no_payment", "message": "未找到支付记录"}

    pay = PAYMENTS_DB[pid]

    # 自动回调逻辑: 创建超过3秒即视为成功
    if pay["status"] == "pending":
        created = datetime.fromisoformat(pay["created_at"])
        if (datetime.now() - created).total_seconds() >= 3:
            pay["status"] = "success"
            pay["paid_at"] = datetime.now().isoformat()
            PAYMENTS_DB[pid] = pay

            # 同步更新订单状态
            now_str = datetime.now().isoformat()
            ORDERS_DB[order_id] = Order(**{
                **order.dict(),
                "status": "paid",
                "paid_at": now_str,
                "logistics_entries": [{
                    "time": now_str,
                    "status": "支付成功",
                    "description": f"订单已支付 ¥{order.total_amount:.2f} ({pay['method']})",
                }] + order.logistics_entries,
            })

    return {
        "payment_id": pid,
        "status": pay["status"],
        "amount": pay["amount"],
        "method": pay["method"],
        "paid_at": pay.get("paid_at"),
    }


@app.post("/api/orders/{order_id}/cancel")
async def cancel_order(order_id: str, data: dict = None, authorization: str = None):
    """取消订单 + 恢复库存"""
    user_id = verify_token(authorization)
    data = data or {}

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    if order.status not in ("pending", "paid"):
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法取消")

    # 恢复库存
    for item in order.items:
        pid = item.get("product_id")
        qty = item.get("quantity", 1)
        if pid and pid in PRODUCTS_DB:
            p = PRODUCTS_DB[pid]
            PRODUCTS_DB[pid] = Product(**{**p.dict(), "stock": p.stock + qty,
                                          "sales_count": max(0, p.sales_count - qty)})

    now_str = datetime.now().isoformat()
    reason = data.get("reason", "用户主动取消")
    ORDERS_DB[order_id] = Order(**{
        **order.dict(),
        "status": "cancelled",
        "cancelled_at": now_str,
        "cancel_reason": reason,
        "logistics_entries": [{
            "time": now_str,
            "status": "订单已取消",
            "description": reason,
        }] + order.logistics_entries,
    })

    return {"success": True, "message": "订单已取消，库存已恢复"}


@app.post("/api/admin/orders/{order_id}/ship")
async def ship_order(order_id: str, data: dict, authorization: str = None):
    """管理员/商家发货"""
    user_id = verify_token(authorization)

    # 简单权限检查: 管理员
    user = USERS_DB.get(user_id, {})
    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="需要管理员权限")

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")

    order = ORDERS_DB[order_id]
    if order.status != "paid":
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法发货")

    carrier = data.get("carrier", "顺丰速运")
    tracking = data.get("tracking_number", f"SF{random.randint(10**11, 10**12-1)}")
    now_str = datetime.now().isoformat()

    entries = [
        {"time": now_str, "status": "已发货",
         "description": f"商家已发货，{carrier} 运单号 {tracking}"},
        {"time": now_str, "status": "揽收",
         "description": f"快件已被{carrier}揽收"},
    ]

    ORDERS_DB[order_id] = Order(**{
        **order.dict(),
        "status": "shipped",
        "shipped_at": now_str,
        "logistics_company": carrier,
        "tracking_number": tracking,
        "logistics_entries": entries + order.logistics_entries,
    })

    return {"success": True, "tracking_number": tracking, "carrier": carrier}


@app.post("/api/orders/{order_id}/confirm-receipt")
async def confirm_receipt(order_id: str, authorization: str = None):
    """确认收货"""
    user_id = verify_token(authorization)

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    if order.status != "shipped":
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法确认收货")

    now_str = datetime.now().isoformat()
    ORDERS_DB[order_id] = Order(**{
        **order.dict(),
        "status": "completed",
        "delivered_at": now_str,
        "completed_at": now_str,
        "logistics_entries": [{
            "time": now_str,
            "status": "已签收",
            "description": "买家已确认收货，交易完成",
        }] + order.logistics_entries,
    })

    return {"success": True, "message": "已确认收货"}


@app.post("/api/orders/{order_id}/refund")
async def request_refund(order_id: str, data: dict = None, authorization: str = None):
    """申请退款"""
    user_id = verify_token(authorization)
    data = data or {}

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="没有权限")
    if order.status not in ("paid", "shipped", "completed"):
        raise HTTPException(status_code=400, detail=f"订单状态为{order.status}，无法退款")

    reason = data.get("reason", "买家申请退款")
    now_str = datetime.now().isoformat()

    ORDERS_DB[order_id] = Order(**{
        **order.dict(),
        "status": "refunding",
        "refund_reason": reason,
        "refund_amount": order.total_amount,
        "logistics_entries": [{
            "time": now_str,
            "status": "退款申请",
            "description": f"买家申请退款: {reason}",
        }] + order.logistics_entries,
    })

    return {"success": True, "message": "退款申请已提交", "refund_amount": order.total_amount}


@app.get("/api/orders/{order_id}/logistics")
async def get_order_logistics(order_id: str, authorization: str = None):
    """获取物流轨迹"""
    user_id = verify_token(authorization)

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="订单不存在")

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        # 管理员也可以查看
        user = USERS_DB.get(user_id, {})
        if not user.get("is_admin"):
            raise HTTPException(status_code=403, detail="没有权限")

    return {
        "order_id": order_id,
        "carrier": order.logistics_company,
        "tracking_number": order.tracking_number,
        "status": order.status,
        "entries": order.logistics_entries,
    }


@app.get("/api/orders/stats")
async def get_order_stats(authorization: str = None):
    """获取当前用户的订单统计"""
    user_id = verify_token(authorization)

    my_orders = [o for o in ORDERS_DB.values() if o.user_id == user_id]
    total_amount = sum(o.total_amount for o in my_orders if o.status in ("paid", "shipped", "completed"))
    status_counts = {}
    for o in my_orders:
        status_counts[o.status] = status_counts.get(o.status, 0) + 1

    return {
        "total": len(my_orders),
        "total_amount": round(total_amount, 2),
        "pending": status_counts.get("pending", 0),
        "paid": status_counts.get("paid", 0),
        "shipped": status_counts.get("shipped", 0),
        "completed": status_counts.get("completed", 0),
        "cancelled": status_counts.get("cancelled", 0),
        "refunding": status_counts.get("refunding", 0),
    }


@app.get("/api/admin/dashboard")
async def get_admin_dashboard(authorization: str = None):
    """管理端统计面板"""
    user_id = verify_token(authorization)
    user = USERS_DB.get(user_id, {})
    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="需要管理员权限")

    all_orders = list(ORDERS_DB.values())
    today = datetime.now().date()
    today_orders = [o for o in all_orders
                    if datetime.fromisoformat(o.created_at).date() == today]

    total_revenue = sum(o.total_amount for o in all_orders if o.status in ("paid", "shipped", "completed"))
    today_revenue = sum(o.total_amount for o in today_orders if o.status in ("paid", "shipped", "completed"))

    # 待处理汇总
    pending_ship = sum(1 for o in all_orders if o.status == "paid")
    pending_refund = sum(1 for o in all_orders if o.status == "refunding")

    # 操作员数量
    operators = [u for u in USERS_DB.values() if u.get("user_type") == "operator"]

    return {
        "total_orders": len(all_orders),
        "today_orders": len(today_orders),
        "total_revenue": round(total_revenue, 2),
        "today_revenue": round(today_revenue, 2),
        "total_products": len(PRODUCTS_DB),
        "pending_ship": pending_ship,
        "pending_refund": pending_refund,
        "operator_count": len(operators),
        "low_stock_items": sum(1 for p in PRODUCTS_DB.values() if p.stock <= 5),
    }


@app.get("/api/admin/activities")
async def get_admin_activities(limit: int = 10, authorization: str = None):
    """最近操作动态 — 从真实订单生成"""
    user_id = verify_token(authorization)
    user = USERS_DB.get(user_id, {})
    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="需要管理员权限")

    activities = []

    # 从订单生成活动
    recent_orders = sorted(ORDERS_DB.values(),
                           key=lambda o: o.created_at, reverse=True)[:limit]
    for o in recent_orders:
        item_name = o.items[0].get("product_name", "商品") if o.items else "商品"
        qty = sum(i.get("quantity", 1) for i in o.items)

        if o.status == "pending":
            activities.append({
                "tag": "订单", "title": f"新订单: {item_name} x{qty}",
                "subtitle": f"¥{o.total_amount:.0f}",
                "time": o.created_at, "type": "order_new",
            })
        elif o.status == "paid":
            activities.append({
                "tag": "支付", "title": f"支付完成: {item_name}",
                "subtitle": f"¥{o.total_amount:.0f}",
                "time": o.paid_at or o.created_at, "type": "order_paid",
            })
        elif o.status == "shipped":
            activities.append({
                "tag": "物流", "title": f"已发货: {o.tracking_number or ''}",
                "subtitle": f"{o.logistics_company or ''} · {item_name}",
                "time": o.shipped_at or o.created_at, "type": "order_shipped",
            })
        elif o.status == "completed":
            activities.append({
                "tag": "完成", "title": f"交易完成: {item_name}",
                "subtitle": f"¥{o.total_amount:.0f}",
                "time": o.completed_at or o.created_at, "type": "order_completed",
            })
        elif o.status == "refunding":
            activities.append({
                "tag": "退款", "title": f"退款申请: {item_name}",
                "subtitle": o.refund_reason or "",
                "time": o.created_at, "type": "order_refund",
            })

    # 低库存预警
    for p in PRODUCTS_DB.values():
        if p.stock <= 5:
            activities.append({
                "tag": "库存", "title": f"库存预警: {p.name}",
                "subtitle": f"当前库存 {p.stock} 件",
                "time": datetime.now().isoformat(), "type": "stock_warning",
            })

    # 按时间排序
    activities.sort(key=lambda a: a.get("time", ""), reverse=True)
    return {"items": activities[:limit], "total": len(activities)}


# --- 收藏 ---

@app.get("/api/favorites")
async def get_favorites(authorization: str = None):
    """获取收藏列表"""
    user_id = verify_token(authorization)
    
    favorite_ids = FAVORITES_DB.get(user_id, [])
    products = [PRODUCTS_DB[pid] for pid in favorite_ids if pid in PRODUCTS_DB]
    
    return {"items": [p.dict() for p in products], "total": len(products)}

@app.post("/api/favorites/{product_id}")
async def add_favorite(product_id: str, authorization: str = None):
    """添加收藏"""
    user_id = verify_token(authorization)
    
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="商品不存在")
    
    if user_id not in FAVORITES_DB:
        FAVORITES_DB[user_id] = []
    
    if product_id not in FAVORITES_DB[user_id]:
        FAVORITES_DB[user_id].append(product_id)
    
    return {"success": True, "message": "已添加收藏"}

@app.delete("/api/favorites/{product_id}")
async def remove_favorite(product_id: str, authorization: str = None):
    """取消收藏"""
    user_id = verify_token(authorization)
    
    if user_id in FAVORITES_DB and product_id in FAVORITES_DB[user_id]:
        FAVORITES_DB[user_id].remove(product_id)
    
    return {"success": True, "message": "已取消收藏"}

# --- 评价 ---

@app.get("/api/products/{product_id}/reviews", response_model=List[Review])
async def get_product_reviews(
    product_id: str,
    page: int = 1,
    page_size: int = 20
):
    """获取商品评价"""
    reviews = [r for r in REVIEWS_DB.values() if r.product_id == product_id]
    reviews.sort(key=lambda x: x.created_at, reverse=True)
    
    start = (page - 1) * page_size
    end = start + page_size
    
    return reviews[start:end]

@app.post("/api/reviews", response_model=Review)
async def create_review(review: ReviewCreate, authorization: str = None):
    """创建评价"""
    user_id = verify_token(authorization)
    user = USERS_DB.get(user_id, {})
    
    review_id = f"rev_{uuid.uuid4().hex[:8]}"
    
    new_review = Review(
        id=review_id,
        product_id=review.product_id,
        user_id=user_id,
        user_name=user.get("username", "用户") if not review.is_anonymous else "匿名用户",
        user_avatar=user.get("avatar"),
        rating=review.rating,
        content=review.content,
        images=review.images,
        created_at=datetime.now().isoformat(),
        is_anonymous=review.is_anonymous
    )
    
    REVIEWS_DB[review_id] = new_review
    
    # 更新商品评分
    if review.product_id in PRODUCTS_DB:
        product = PRODUCTS_DB[review.product_id]
        product_reviews = [r for r in REVIEWS_DB.values() if r.product_id == review.product_id]
        if product_reviews:
            avg_rating = sum(r.rating for r in product_reviews) / len(product_reviews)
            # 更新评分（这里需要创建新对象，因为Pydantic模型是不可变的）
            PRODUCTS_DB[review.product_id] = Product(
                **{**product.dict(), "rating": round(avg_rating, 1)}
            )
    
    return new_review

# --- 文件上传 ---

@app.post("/api/upload/image")
async def upload_image(
    file: UploadFile = File(...),
    folder: str = Form("images")
):
    """上传图片"""
    # 验证文件类型
    allowed_types = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="不支持的图片格式")
    
    # 生成文件名
    ext = file.filename.split(".")[-1] if file.filename else "jpg"
    filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}.{ext}"
    
    # 保存文件
    folder_path = os.path.join(UPLOAD_DIR, folder)
    os.makedirs(folder_path, exist_ok=True)
    
    file_path = os.path.join(folder_path, filename)
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
    
    # 返回URL
    url = f"/uploads/{folder}/{filename}"
    
    return {
        "success": True,
        "url": url,
        "object_key": f"{folder}/{filename}",
        "filename": filename
    }

# --- OSS STS ---

@app.get("/api/oss/sts-token", response_model=OssStsResponse)
async def get_oss_sts_token(authorization: str = None):
    """获取OSS STS临时凭证"""
    verify_token(authorization)
    
    # 这里返回模拟数据，实际需要调用阿里云STS服务
    # 参考: https://help.aliyun.com/document_detail/100624.html
    
    expiration = (datetime.now() + timedelta(hours=1)).isoformat() + "Z"
    
    return OssStsResponse(
        access_key_id="MOCK_ACCESS_KEY_ID",
        access_key_secret="MOCK_ACCESS_KEY_SECRET",
        security_token="MOCK_SECURITY_TOKEN",
        expiration=expiration
    )

# --- 推送通知 ---

@app.post("/api/notifications/register")
async def register_device(data: NotificationRegister, authorization: str = None):
    """注册设备Token"""
    user_id = verify_token(authorization)
    
    DEVICES_DB[data.device_token] = {
        "user_id": user_id,
        "platform": data.platform,
        "settings": data.settings or {},
        "registered_at": datetime.now().isoformat()
    }
    
    return {"success": True, "message": "设备已注册"}

@app.get("/api/notifications")
async def get_notifications(
    page: int = 1,
    page_size: int = 20,
    authorization: str = None
):
    """获取通知列表"""
    verify_token(authorization)
    
    # 模拟通知数据
    notifications = [
        {
            "id": "n001",
            "title": "订单发货通知",
            "body": "您的订单已发货，请注意查收",
            "type": "logistics",
            "created_at": datetime.now().isoformat(),
            "is_read": False
        },
        {
            "id": "n002",
            "title": "新品上架",
            "body": "和田玉新品已上架，快来看看吧",
            "type": "promotion",
            "created_at": (datetime.now() - timedelta(hours=2)).isoformat(),
            "is_read": True
        }
    ]
    
    return {"items": notifications, "total": len(notifications), "unread": 1}

# --- 用户信息 ---

@app.get("/api/users/profile")
async def get_profile(authorization: str = None):
    """获取用户信息"""
    user_id = verify_token(authorization)
    
    if user_id not in USERS_DB:
        raise HTTPException(status_code=404, detail="用户不存在")
    
    user = USERS_DB[user_id]
    return UserResponse(**user).dict()

@app.put("/api/users/profile")
async def update_profile(data: dict, authorization: str = None):
    """更新用户信息"""
    user_id = verify_token(authorization)
    
    if user_id not in USERS_DB:
        raise HTTPException(status_code=404, detail="用户不存在")
    
    # 只允许更新特定字段
    allowed_fields = {"username", "avatar"}
    for key, value in data.items():
        if key in allowed_fields:
            USERS_DB[user_id][key] = value
    
    return {"success": True, "user": UserResponse(**USERS_DB[user_id]).dict()}

# --- AI 图片分析代理 ---

DASHSCOPE_API_KEY = os.getenv("DASHSCOPE_API_KEY", "")
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")

@app.post("/api/ai/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """AI图片分析（服务端代理，解决国内无法直连Gemini的问题）
    
    优先使用 DashScope Qwen-VL，回退到 DeepSeek 文本描述（占位）。
    """
    import httpx, base64

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="图片不能超过10MB")

    b64 = base64.b64encode(image_bytes).decode()
    mime = file.content_type or "image/jpeg"
    data_uri = f"data:{mime};base64,{b64}"

    prompt = (
        "请分析这张珠宝图片，返回严格JSON：\n"
        '{"description":"详细描述","material":"材质","category":"分类(手链/吊坠/戒指/手镯/项链/耳饰)","tags":["标签"],"quality_score":0.8,"suggestion":"建议"}'
    )

    # ---- 方案1: DashScope Qwen-VL ----
    if DASHSCOPE_API_KEY:
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                resp = await client.post(
                    "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {DASHSCOPE_API_KEY}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "qwen-vl-max",
                        "messages": [
                            {
                                "role": "user",
                                "content": [
                                    {"type": "image_url", "image_url": {"url": data_uri}},
                                    {"type": "text", "text": prompt},
                                ],
                            }
                        ],
                        "max_tokens": 1024,
                    },
                )
                if resp.status_code == 200:
                    data = resp.json()
                    text = data["choices"][0]["message"]["content"]
                    # 尝试解析JSON
                    import re as _re
                    j = _re.search(r'\{[\s\S]*\}', text)
                    if j:
                        return {"success": True, "analysis": json.loads(j.group(0)), "raw": text}
                    return {"success": True, "analysis": {"description": text}, "raw": text}
                else:
                    logging.warning(f"DashScope error: {resp.status_code} {resp.text[:200]}")
        except Exception as e:
            logging.warning(f"DashScope failed: {e}")

    # ---- 方案2: DeepSeek 文字描述 (无视觉能力，退化) ----
    if DEEPSEEK_API_KEY:
        return {
            "success": True,
            "analysis": {
                "description": "图片已上传，但当前AI视觉模型未配置。请在服务器设置 DASHSCOPE_API_KEY 环境变量以启用通义千问图片分析。",
                "material": "待配置",
                "category": "待配置",
            },
            "raw": "AI视觉模型未配置",
        }

    raise HTTPException(status_code=503, detail="AI分析服务未配置，请设置 DASHSCOPE_API_KEY")


# ============ 启动 ============

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
