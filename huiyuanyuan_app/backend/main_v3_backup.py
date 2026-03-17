"""
姹囩帀婧愬悗绔疉PI - 澧炲己鐗?
鏀寔瀹屾暣鐨凜RUD鎿嶄綔銆佹枃浠朵笂浼犮€佹帹閫侀€氱煡绛夊姛鑳?
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

# --- 鐜鍙橀噺 ---
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# --- 鏁版嵁搴?(SQLAlchemy) ---
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
    """FastAPI 渚濊禆锛氳幏鍙栨暟鎹簱浼氳瘽锛屼笉鍙敤鏃惰繑鍥?None"""
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
    """鐢熸垚 JWT Token锛岄檷绾ф椂杩斿洖 UUID"""
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

# --- 闃块噷浜戠煭淇?SDK锛堝彲閫夛紝AccessKey 鏈厤缃椂璺宠繃锛?--
ALIYUN_AK_ID     = os.getenv("ALIYUN_ACCESS_KEY_ID", "")
ALIYUN_AK_SECRET = os.getenv("ALIYUN_ACCESS_KEY_SECRET", "")
SMS_SIGN_NAME    = os.getenv("SMS_SIGN_NAME", "姹囩帀婧?)
SMS_TEMPLATE     = os.getenv("SMS_TEMPLATE_CODE", "")
SMS_REAL_MODE    = bool(ALIYUN_AK_ID and ALIYUN_AK_SECRET and SMS_TEMPLATE)

def _send_aliyun_sms(phone: str, code: str) -> dict:
    """璋冪敤闃块噷浜戠煭淇″彂閫佹帴鍙ｏ紝杩斿洖 {success, biz_id, message}"""
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
    title="姹囩帀婧愬悗绔?API",
    version="3.0.0",
    description="姹囩帀婧愮彔瀹濇櫤鑳戒氦鏄撳钩鍙板悗绔湇鍔?
)

# 閰嶇疆 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 鍒涘缓涓婁紶鐩綍
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# 鎸傝浇闈欐€佹枃浠舵湇鍔?
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ============ 鏁版嵁妯″瀷 ============

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
    material_verify: str = "澶╃劧A璐?

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

# ============ 妯℃嫙鏁版嵁搴?============

# 鐢ㄦ埛鏁版嵁
USERS_DB: Dict[str, Dict] = {
    "admin_001": {
        "id": "admin_001",
        "username": "瓒呯骇绠＄悊鍛?,
        "phone": "18937766669",
        "password": "admin123",
        "is_admin": True,
        "balance": 999999.0,
        "points": 99999,
        "avatar": None,
        "user_type": "admin",
    }
}

# 鎿嶄綔鍛樻暟鎹?
for i in range(1, 11):
    USERS_DB[f"operator_{i}"] = {
        "id": f"operator_{i}",
        "username": f"鎿嶄綔鍛榹i}",
        "phone": f"1380000000{i}",
        "password": "op123456",
        "is_admin": False,
        "balance": 0.0,
        "points": 100,
        "avatar": None,
        "operator_number": i,
        "user_type": "operator",
    }

# 鍟嗗搧鏁版嵁
PRODUCTS_DB: Dict[str, Product] = {}

# 鍒濆鍟嗗搧鏁版嵁锛堜笌鍓嶇 product_data.dart 鍚屾锛?
INITIAL_PRODUCTS = [
    # ============ 鍜岀敯鐜夌郴鍒?============
    {
        "id": "HYY-HT001",
        "name": "鏂扮枂鍜岀敯鐜夌苯鏂欑杩愭墜閾?,
        "description": "绮鹃€夋柊鐤嗗拰鐢扮帀绫芥枡锛岀帀璐ㄦ俯娑︾粏鑵伙紝娌规€у崄瓒炽€傞噰鐢ㄤ紶缁熸墜宸ョ紪缁囧伐鑹猴紝閰嶄互閲戝垰缁撹璁★紝瀵撴剰绂忚繍缁戝畾銆佸ソ杩愯繛杩炪€?,
        "price": 299.0,
        "original_price": 599.0,
        "category": "鎵嬮摼",
        "material": "鍜岀敯鐜?,
        "images": ["https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=800&h=800&fit=crop"],
        "stock": 156,
        "rating": 4.9,
        "sales_count": 2341,
        "is_hot": True,
        "is_new": False,
        "origin": "鏂扮枂鍜岀敯",
        "certificate": "GTC-2026-HT001",
        "is_welfare": True,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-HT002",
        "name": "鍜岀敯鐜夐潚鐧界帀骞冲畨鎵ｆ墜涓?,
        "description": "鐢勯€夊拰鐢伴潚鐧界帀锛岃壊娉芥贰闆咃紝璐ㄥ湴鍧囧寑銆傚钩瀹夋墸閫犲瀷缁忓吀锛屽瘬鎰忓钩瀹夊仴搴枫€佷竾浜嬪鎰忋€?,
        "price": 399.0,
        "original_price": 798.0,
        "category": "鎵嬩覆",
        "material": "鍜岀敯鐜?,
        "images": ["https://images.unsplash.com/photo-1596944924616-7b38e7cfac36?w=800&h=800&fit=crop"],
        "stock": 89,
        "rating": 4.8,
        "sales_count": 1567,
        "is_hot": True,
        "is_new": True,
        "origin": "鏂扮枂鍜岀敯",
        "certificate": "GTC-2026-HT002",
        "is_welfare": True,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-HT003",
        "name": "缇婅剛鐧界帀璨旇矃鎵嬮摼",
        "description": "椤剁骇缇婅剛鐧界帀锛岀櫧搴﹂珮銆佹补娑︾粏鑵汇€傜簿闆曡矓璨呭悐鍧狅紝鎷涜储绾崇锛岃緹閭繚骞冲畨銆傞檺閲忔寮忥紝鏋佸叿鏀惰棌浠峰€笺€?,
        "price": 1280.0,
        "original_price": 2560.0,
        "category": "鎵嬮摼",
        "material": "鍜岀敯鐜?,
        "images": ["https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800&h=800&fit=crop"],
        "stock": 35,
        "rating": 5.0,
        "sales_count": 521,
        "is_hot": True,
        "is_new": True,
        "origin": "鏂扮枂鍜岀敯",
        "certificate": "GTC-2026-HT003",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    # ============ 缂呯敻缈＄繝绯诲垪 ============
    {
        "id": "HYY-FC001",
        "name": "缂呯敻缈＄繝骞冲畨鎵ｅ悐鍧?,
        "description": "缂呯敻A璐х俊缈狅紝鍐扮璐ㄥ湴锛岄€忔槑搴﹂珮銆傞鑺辫嚜鐒剁伒鍔紝閲囩敤18K閲戦暥宓岋紝楂樿吹鍏搁泤銆?,
        "price": 1580.0,
        "original_price": 3160.0,
        "category": "鍚婂潬",
        "material": "缂呯敻缈＄繝",
        "images": ["https://images.unsplash.com/photo-1588444837495-c6cfeb53f32d?w=800&h=800&fit=crop"],
        "stock": 45,
        "rating": 4.9,
        "sales_count": 876,
        "is_hot": True,
        "is_new": False,
        "origin": "缂呯敻",
        "certificate": "GIA-2026-FC001",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-FC002",
        "name": "婊＄豢缈＄繝鍦嗙彔鎵嬮摼",
        "description": "澶╃劧缂呯敻缈＄繝锛屾弧缁胯壊娉斤紝棰滆壊鍧囧寑銆傚渾鐝犵洿寰?mm锛岀彔鐝犻ケ婊℃鼎娉姐€傜粡鍥藉鏉冨▉鏈烘瀯閴村畾銆?,
        "price": 2380.0,
        "original_price": 4760.0,
        "category": "鎵嬮摼",
        "material": "缂呯敻缈＄繝",
        "images": ["https://images.unsplash.com/photo-1603561591411-07134e71a2a9?w=800&h=800&fit=crop"],
        "stock": 28,
        "rating": 4.8,
        "sales_count": 432,
        "is_hot": False,
        "is_new": True,
        "origin": "缂呯敻",
        "certificate": "GIA-2026-FC002",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-FC003",
        "name": "绯啺缈＄繝钁姦鑰崇幆",
        "description": "绯啺绉嶇俊缈狅紝璐ㄥ湴缁嗚吇娓╂鼎銆傝懌鑺﹂€犲瀷锛屽瘬鎰忕绂勫弻鍏ㄣ€?25閾堕暥宓岋紝闃茶繃鏁忔潗璐ㄣ€?,
        "price": 599.0,
        "original_price": 1198.0,
        "category": "鑰抽グ",
        "material": "缂呯敻缈＄繝",
        "images": ["https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=800&h=800&fit=crop"],
        "stock": 67,
        "rating": 4.7,
        "sales_count": 789,
        "is_hot": False,
        "is_new": False,
        "origin": "缂呯敻",
        "certificate": "GIA-2026-FC003",
        "is_welfare": True,
        "material_verify": "澶╃劧A璐?,
    },
    # ============ 鍗楃孩鐜涚憴绯诲垪 ============
    {
        "id": "HYY-NH001",
        "name": "鍑夊北鍗楃孩鐜涚憴杞繍鐝犳墜閾?,
        "description": "鍥涘窛鍑夊北鍗楃孩锛岃壊娉芥祿閮併€佽川鍦版俯娑︺€傝浆杩愮彔璁捐锛屽瘬鎰忔椂鏉ヨ繍杞€傜函鎵嬪伐鎵撶（鎶涘厜銆?,
        "price": 199.0,
        "original_price": 398.0,
        "category": "鎵嬮摼",
        "material": "鍗楃孩鐜涚憴",
        "images": ["https://images.unsplash.com/photo-1602751584552-8ba73aad10e1?w=800&h=800&fit=crop"],
        "stock": 234,
        "rating": 4.8,
        "sales_count": 3456,
        "is_hot": True,
        "is_new": False,
        "origin": "鍥涘窛鍑夊北",
        "certificate": "NGTC-2026-NH001",
        "is_welfare": True,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-NH002",
        "name": "鏌垮瓙绾㈠崡绾㈢帥鐟欏渾鐝犻」閾?,
        "description": "椤剁骇鏌垮瓙绾㈠崡绾紝棰滆壊楗辨弧鑹充附銆傚渾鐝犲潎鍖€锛岀洿寰?mm锛屾€婚暱45cm銆?,
        "price": 1680.0,
        "original_price": 3360.0,
        "category": "椤归摼",
        "material": "鍗楃孩鐜涚憴",
        "images": ["https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800&h=800&fit=crop"],
        "stock": 42,
        "rating": 4.9,
        "sales_count": 234,
        "is_hot": False,
        "is_new": True,
        "origin": "鍥涘窛鍑夊北",
        "certificate": "NGTC-2026-NH002",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    # ============ 绱按鏅剁郴鍒?============
    {
        "id": "HYY-ZS001",
        "name": "涔屾媺鍦传姘存櫠璨旇矃鎵嬩覆",
        "description": "涔屾媺鍦《绾х传姘存櫠锛岃壊娉芥繁閭冩祿閮併€傜簿闆曡矓璨呭悐鍧狅紝鎷涜储杈熼偑銆傛按鏅剁彔瀛愰€氶€忥紝鍏夋劅鏋佷匠銆?,
        "price": 299.0,
        "original_price": 598.0,
        "category": "鎵嬩覆",
        "material": "绱按鏅?,
        "images": ["https://images.unsplash.com/photo-1629224316810-9d8805b95e76?w=800&h=800&fit=crop"],
        "stock": 123,
        "rating": 4.7,
        "sales_count": 1234,
        "is_hot": False,
        "is_new": False,
        "origin": "涔屾媺鍦?,
        "certificate": "IGI-2026-ZS001",
        "is_welfare": True,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-ZS002",
        "name": "绱櫠娲炴憜浠?灏忓彿)",
        "description": "宸磋タ绱櫠娲烇紝鏅朵綋楗辨弧锛岄鑹茬传鑹炽€傚ぉ鐒跺舰鎴愶紝姣忎欢褰㈡€佺嫭鐗广€傞€傚悎鏀剧疆瀹朵腑鎴栧姙鍏銆?,
        "price": 880.0,
        "original_price": 1760.0,
        "category": "鎽嗕欢",
        "material": "绱按鏅?,
        "images": ["https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=800&h=800&fit=crop"],
        "stock": 56,
        "rating": 4.8,
        "sales_count": 567,
        "is_hot": False,
        "is_new": True,
        "origin": "宸磋タ",
        "certificate": "IGI-2026-ZS002",
        "is_welfare": False,
        "material_verify": "澶╃劧",
    },
    # ============ 榛勯噾绯诲垪 ============
    {
        "id": "HYY-HJ001",
        "name": "鍙ゆ硶榛勯噾浼犳壙鎵嬮暞",
        "description": "閲囩敤鍙ゆ硶榛勯噾宸ヨ壓锛屽搼鍏夌（鐮傝川鎰熴€傜瀛楃ゥ浜戠汗楗帮紝瓒抽噾999锛岀害20鍏嬮噸銆?,
        "price": 15600.0,
        "original_price": 16800.0,
        "category": "鎵嬮暞",
        "material": "榛勯噾",
        "images": ["https://images.unsplash.com/photo-1619119069152-a2b331eb392a?w=800&h=800&fit=crop"],
        "stock": 20,
        "rating": 4.9,
        "sales_count": 899,
        "is_hot": False,
        "is_new": False,
        "origin": "涓浗",
        "certificate": "NGTC-2026-HJ001",
        "is_welfare": False,
        "material_verify": "瓒抽噾999",
    },
    {
        "id": "HYY-HJ002",
        "name": "3D纭噾杞繍鐝犲悐鍧?,
        "description": "3D纭噾宸ヨ壓锛岃交渚夸笉鍙樺舰銆傝浆杩愮彔閫犲瀷锛岀簿宸х幉鐝戙€傜害1鍏嬮噸锛屽惈绮剧編閾炬潯銆?,
        "price": 580.0,
        "original_price": 780.0,
        "category": "鍚婂潬",
        "material": "榛勯噾",
        "images": ["https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=800&h=800&fit=crop"],
        "stock": 88,
        "rating": 4.8,
        "sales_count": 1567,
        "is_hot": False,
        "is_new": False,
        "origin": "涓浗",
        "certificate": "NGTC-2026-HJ002",
        "is_welfare": True,
        "material_verify": "瓒抽噾999",
    },
    {
        "id": "HYY-HJ003",
        "name": "瓒抽噾999鑾茶姳鍚婂潬",
        "description": "绮鹃洉鑾茶姳閫犲瀷锛屽瘬鎰忓嚭娣ゆ偿鑰屼笉鏌撱€傝冻閲?99锛岀害3鍏嬮噸銆?D纭噾宸ヨ壓锛岀珛浣撻ケ婊°€?,
        "price": 1880.0,
        "original_price": 2380.0,
        "category": "鍚婂潬",
        "material": "榛勯噾",
        "images": ["https://images.unsplash.com/photo-1543294001-f7cd5d7fb516?w=800&h=800&fit=crop"],
        "stock": 50,
        "rating": 4.9,
        "sales_count": 678,
        "is_hot": True,
        "is_new": True,
        "origin": "涓浗",
        "certificate": "NGTC-2026-HJ003",
        "is_welfare": False,
        "material_verify": "瓒抽噾999",
    },
    # ============ 绾㈠疂鐭崇郴鍒?============
    {
        "id": "HYY-HB001",
        "name": "18K閲戦暥宓岀紖鐢哥孩瀹濈煶鎴掓寚",
        "description": "缂呯敻澶╃劧绾㈠疂鐭筹紝楦借绾㈣壊娉姐€?8K鐜懓閲戦暥宓岋紝缇ら暥灏忛捇鐐圭紑銆傚浗闄匞RS璇佷功璁よ瘉銆?,
        "price": 3580.0,
        "original_price": 6880.0,
        "category": "鎴掓寚",
        "material": "绾㈠疂鐭?,
        "images": ["https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800&h=800&fit=crop"],
        "stock": 15,
        "rating": 5.0,
        "sales_count": 321,
        "is_hot": True,
        "is_new": True,
        "origin": "缂呯敻",
        "certificate": "GRS-2026-HB001",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    # ============ 钃濆疂鐭崇郴鍒?============
    {
        "id": "HYY-LB001",
        "name": "鏂噷鍏板崱钃濆疂鐭冲悐鍧?,
        "description": "鏂噷鍏板崱澶╃劧钃濆疂鐭筹紝鐭㈣溅鑿婅摑銆?8K鐧介噾闀跺祵锛岀畝绾﹀ぇ姘斻€傞噸绾?.2鍏嬫媺锛岄檮GRS璇佷功銆?,
        "price": 8880.0,
        "original_price": 12800.0,
        "category": "鍚婂潬",
        "material": "钃濆疂鐭?,
        "images": ["https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop"],
        "stock": 8,
        "rating": 5.0,
        "sales_count": 89,
        "is_hot": False,
        "is_new": True,
        "origin": "鏂噷鍏板崱",
        "certificate": "GRS-2026-LB001",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    # ============ 铚滆湣绯诲垪 ============
    {
        "id": "HYY-ML001",
        "name": "娉㈢綏鐨勬捣楦℃补榛勮湝铚℃墜涓?,
        "description": "绾ぉ鐒舵尝缃楃殑娴疯湝铚★紝楦℃补榛勮壊銆傚渾鐝犵洿寰?0mm锛岄鑹插潎鍖€銆傝湣璐ㄦ祿閮侊紝鐩樼帺鏁堟灉浣炽€?,
        "price": 499.0,
        "original_price": 998.0,
        "category": "鎵嬩覆",
        "material": "铚滆湣",
        "images": ["https://images.unsplash.com/photo-1608042314453-ae338d80c427?w=800&h=800&fit=crop"],
        "stock": 78,
        "rating": 4.8,
        "sales_count": 876,
        "is_hot": False,
        "is_new": False,
        "origin": "娉㈢綏鐨勬捣",
        "certificate": "NGTC-2026-ML001",
        "is_welfare": True,
        "material_verify": "澶╃劧A璐?,
    },
    # ============ 纰х帀绯诲垪 ============
    {
        "id": "HYY-BY001",
        "name": "淇勭綏鏂ⅶ鐜夎彔鑿滅豢鎵嬮暞",
        "description": "淇勭綏鏂ⅶ鐜夛紝鑿犺彍缁胯壊锛岃川鍦扮粏鑵汇€傚渾鏉℃寮忥紝鍐呭緞56-60mm鍙€夈€傜粡鍏镐紶鎵挎銆?,
        "price": 2680.0,
        "original_price": 5360.0,
        "category": "鎵嬮暞",
        "material": "纰х帀",
        "images": ["https://images.unsplash.com/photo-1610375461246-83df859d849d?w=800&h=800&fit=crop"],
        "stock": 32,
        "rating": 4.7,
        "sales_count": 234,
        "is_hot": False,
        "is_new": False,
        "origin": "淇勭綏鏂?,
        "certificate": "NGTC-2026-BY001",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    # ============ 鏂板鍟嗗搧 ============
    {
        "id": "HYY-HT004",
        "name": "鍜岀敯鐜夊ⅷ鐜夐緳鍑ゆ墜闀?,
        "description": "鏂扮枂鍜岀敯澧ㄧ帀锛岃壊濡傛祿澧紝璐ㄦ劅娌夌ǔ銆傞緳鍑ら洉绾癸紝瀵撴剰榫欏嚖鍛堢ゥ銆傚渾鏉℃寮忥紝閫傚悎濠氬珌銆?,
        "price": 3980.0,
        "original_price": 6800.0,
        "category": "鎵嬮暞",
        "material": "鍜岀敯鐜?,
        "images": ["https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?w=800&h=800&fit=crop"],
        "stock": 18,
        "rating": 4.9,
        "sales_count": 156,
        "is_hot": False,
        "is_new": True,
        "origin": "鏂扮枂鍜岀敯",
        "certificate": "NGTC-2026-HT004",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-FC004",
        "name": "鍐扮朝绉嶇俊缈犺闊冲悐鍧?,
        "description": "缂呯敻鍐扮朝绉嶇俊缈狅紝娓╂鼎閫忎寒銆傝闊虫硶鐩稿簞涓ワ紝淇濅綉骞冲畨銆?8K鐧介噾闀跺祵銆?,
        "price": 2280.0,
        "original_price": 4560.0,
        "category": "鍚婂潬",
        "material": "缂呯敻缈＄繝",
        "images": ["https://images.unsplash.com/photo-1600721391776-b5cd0e0048f9?w=800&h=800&fit=crop"],
        "stock": 25,
        "rating": 4.8,
        "sales_count": 345,
        "is_hot": True,
        "is_new": False,
        "origin": "缂呯敻",
        "certificate": "GTC-2026-FC004",
        "is_welfare": False,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-ZJ001",
        "name": "18K鐜懓閲戦捇鐭抽」閾?,
        "description": "18K鐜懓閲戦摼鏉★紝鍏夋辰鏌旂編銆備富閽?.3鍏嬫媺锛孲I鍑€搴︼紝H鑹茬骇銆傞攣楠ㄩ摼璁捐銆?,
        "price": 4680.0,
        "original_price": 6800.0,
        "category": "椤归摼",
        "material": "閽荤煶",
        "images": ["https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800&h=800&fit=crop"],
        "stock": 12,
        "rating": 5.0,
        "sales_count": 189,
        "is_hot": True,
        "is_new": True,
        "origin": "鍗楅潪",
        "certificate": "GIA-2026-ZJ001",
        "is_welfare": False,
        "material_verify": "澶╃劧閽荤煶",
    },
    {
        "id": "HYY-NH003",
        "name": "淇濆北鍗楃孩鐜涚憴濡傛剰閿佸悐鍧?,
        "description": "浜戝崡淇濆北鍗楃孩锛屾熆瀛愮孩婊¤壊銆傚鎰忛攣閫犲瀷锛屽瘬鎰忓悏绁ュ鎰忋€傜函閾堕暥宓岋紝璧犻€侀」閾俱€?,
        "price": 458.0,
        "original_price": 916.0,
        "category": "鍚婂潬",
        "material": "鍗楃孩鐜涚憴",
        "images": ["https://images.unsplash.com/photo-1583484963886-cfe2bff2945f?w=800&h=800&fit=crop"],
        "stock": 98,
        "rating": 4.7,
        "sales_count": 567,
        "is_hot": False,
        "is_new": False,
        "origin": "浜戝崡淇濆北",
        "certificate": "NGTC-2026-NH003",
        "is_welfare": True,
        "material_verify": "澶╃劧A璐?,
    },
    {
        "id": "HYY-PT001",
        "name": "澶╃劧鐝嶇彔浼橀泤椤归摼濂楄",
        "description": "澶╃劧娣℃按鐝嶇彔锛屽渾娑﹀厜娉姐€?-8mm鐝嶇彔锛屾惌閰嶈€抽グ濂楄銆?25閾舵墸锛岄槻杩囨晱鏉愯川銆?,
        "price": 368.0,
        "original_price": 736.0,
        "category": "椤归摼",
        "material": "鐝嶇彔",
        "images": ["https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop&q=80"],
        "stock": 120,
        "rating": 4.6,
        "sales_count": 2345,
        "is_hot": True,
        "is_new": False,
        "origin": "涓浗娴欐睙",
        "certificate": "NGTC-2026-PT001",
        "is_welfare": True,
        "material_verify": "澶╃劧鐝嶇彔",
    },
    {
        "id": "HYY-HJ004",
        "name": "榛勯噾杞繍鐝犵孩缁虫墜閾?,
        "description": "瓒抽噾999杞繍鐝狅紝绾?.5鍏嬨€傛墜缂栫孩缁筹紝瀵撴剰绾㈢孩鐏伀銆傜敺濂抽€氱敤锛屽昂瀵稿彲璋冦€?,
        "price": 289.0,
        "original_price": 399.0,
        "category": "鎵嬮摼",
        "material": "榛勯噾",
        "images": ["https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=800&h=800&fit=crop"],
        "stock": 200,
        "rating": 4.8,
        "sales_count": 4567,
        "is_hot": True,
        "is_new": False,
        "origin": "涓浗",
        "certificate": "NGTC-2026-HJ004",
        "is_welfare": True,
        "material_verify": "瓒抽噾999",
    },
]

for p in INITIAL_PRODUCTS:
    p["blockchain_hash"] = f"0x{uuid.uuid4().hex[:40]}"
    PRODUCTS_DB[p["id"]] = Product(**p)

# 搴楅摵鏁版嵁
SHOPS_DB: Dict[str, Shop] = {}

# 鍦板潃鏁版嵁
ADDRESSES_DB: Dict[str, Address] = {}

# 璁㈠崟鏁版嵁
ORDERS_DB: Dict[str, Order] = {}

# 璐墿杞︽暟鎹?
CARTS_DB: Dict[str, List[CartItem]] = {}

# 鏀惰棌鏁版嵁
FAVORITES_DB: Dict[str, List[str]] = {}

# 璇勪环鏁版嵁
REVIEWS_DB: Dict[str, Review] = {}

# Token鏄犲皠
TOKENS_DB: Dict[str, str] = {}  # token -> user_id

# 璁惧Token
DEVICES_DB: Dict[str, Dict] = {}  # device_token -> device_info

# ============ 杈呭姪鍑芥暟 ============

def generate_token() -> str:
    return f"token_{uuid.uuid4().hex}"

def get_current_user_id(token: str) -> Optional[str]:
    """浠嶵oken鑾峰彇鐢ㄦ埛ID"""
    # 绠€鍖栫殑Token楠岃瘉
    if token.startswith("Bearer "):
        token = token[7:]
    return TOKENS_DB.get(token)

def verify_token(authorization: str = None) -> str:
    """楠岃瘉Token骞惰繑鍥炵敤鎴稩D"""
    if not authorization:
        raise HTTPException(status_code=401, detail="鏈彁渚涜璇乀oken")
    
    user_id = get_current_user_id(authorization)
    if not user_id:
        raise HTTPException(status_code=401, detail="Token鏃犳晥鎴栧凡杩囨湡")
    
    return user_id

# ============ API璺敱 ============

# --- 鍋ュ悍妫€鏌?---

@app.get("/")
async def root():
    return {"message": "姹囩帀婧怉PI鏈嶅姟杩愯涓?, "version": "3.0.0", "status": "healthy"}

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "3.0.0"
    }

# --- 璁よ瘉 ---

@app.post("/api/auth/login")
async def login(request: LoginRequest):
    """鐢ㄦ埛鐧诲綍"""
    if request.type == "admin":
        # 绠＄悊鍛樼櫥褰?
        if request.username == "18937766669" and request.password == "admin123":
            if request.captcha and request.captcha != "8888":
                raise HTTPException(status_code=400, detail="楠岃瘉鐮侀敊璇?)
            
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
        # 鎿嶄綔鍛樼櫥褰?
        operator_id = None
        try:
            op_num = int(request.username) if request.username else 0
            if 1 <= op_num <= 10:
                operator_id = f"operator_{op_num}"
        except (ValueError, TypeError):
            # 灏濊瘯鎸夌敤鎴峰悕鏌ユ壘
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
            raise HTTPException(status_code=400, detail="鎵嬫満鍙峰拰楠岃瘉鐮佷笉鑳戒负绌?)
        
        # 楠岃瘉鐮侀€昏緫锛?888 鎴栫瓑浜庢墜鏈哄彿鍚?浣?
        expected_code = request.phone[-4:] if len(request.phone) >= 4 else request.phone
        if request.code != '8888' and request.code != expected_code:
            raise HTTPException(status_code=400, detail="楠岃瘉鐮侀敊璇?)
            
        user_id = None
        for uid, user in USERS_DB.items():
            if user.get("phone") == request.phone:
                user_id = uid
                break
                
        if not user_id:
            user_id = f"customer_{int(datetime.now().timestamp() * 1000)}"
            USERS_DB[user_id] = {
                "id": user_id,
                "username": f"鐢ㄦ埛_{expected_code}",
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
    
    raise HTTPException(status_code=401, detail="鐢ㄦ埛鍚嶆垨瀵嗙爜閿欒")

# ============================================================
# SMS 璁よ瘉璺敱锛堜换鍔锛?
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
def _sms_cool_key(phone: str)  -> str: return f"sms:cool:{phone}"   # 60s 鍐峰嵈
def _sms_day_key(phone: str)   -> str: return f"sms:day:{phone}:{datetime.utcnow().strftime('%Y%m%d')}"
def _sms_err_key(phone: str)   -> str: return f"sms:err:{phone}"    # 杩炵画閿欒璁℃暟


@app.post("/api/auth/send-sms")
async def send_sms_code(body: SmsCodeRequest, request: Request):
    """鍙戦€佺煭淇￠獙璇佺爜锛堝惈 Redis 闄愭祦锛?""
    import re
    if not re.match(r"^1[3-9]\d{9}$", body.phone):
        raise HTTPException(status_code=400, detail="鎵嬫満鍙锋牸寮忛敊璇?)

    code = str(random.randint(100000, 999999))

    if REDIS_AVAILABLE:
        # 60 绉掑喎鍗?
        if redis_client.exists(_sms_cool_key(body.phone)):
            ttl = redis_client.ttl(_sms_cool_key(body.phone))
            raise HTTPException(status_code=429, detail=f"鍙戦€佸お棰戠箒锛岃 {ttl} 绉掑悗閲嶈瘯")
        # 姣忔棩涓婇檺 10 娆?
        day_count = int(redis_client.get(_sms_day_key(body.phone)) or 0)
        if day_count >= 10:
            raise HTTPException(status_code=429, detail="浠婃棩鍙戦€佹鏁板凡杈句笂闄愶紙10娆★級")
        # 瀛樺偍楠岃瘉鐮?5 鍒嗛挓鏈夋晥
        redis_client.setex(_sms_code_key(body.phone), 300, code)
        redis_client.setex(_sms_cool_key(body.phone), 60, "1")
        redis_client.incr(_sms_day_key(body.phone))
        redis_client.expire(_sms_day_key(body.phone), 86400)
        redis_client.delete(_sms_err_key(body.phone))  # 鏂板彂閫侀噸缃敊璇鏁?
    else:
        code = "8888"  # Redis 涓嶅彲鐢ㄦ椂鐢ㄥ浐瀹氭祴璇曠爜

    # 璁板綍鍙戦€佹棩蹇?
    biz_id = ""
    if SMS_REAL_MODE:
        result = _send_aliyun_sms(body.phone, code)
        biz_id = result.get("biz_id", "")
        if not result["success"]:
            logging.error(f"SMS send failed for {body.phone}: {result['message']}")
            raise HTTPException(status_code=502, detail="鐭俊鍙戦€佸け璐ワ紝璇风◢鍚庨噸璇?)

    # 鍐欏叆鏁版嵁搴撴棩蹇楋紙鍙€夛級
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
        return {"success": True, "message": "楠岃瘉鐮佸凡鍙戦€侊紝5鍒嗛挓鍐呮湁鏁?}
    else:
        return {"success": True, "message": f"锛堟祴璇曟ā寮忥級楠岃瘉鐮侊細{code}"}


@app.post("/api/auth/verify-sms")
async def verify_sms_code(body: SmsVerifyRequest, db: Optional[Session] = Depends(get_db)):
    """鏍￠獙鐭俊楠岃瘉鐮侊紝鑷姩娉ㄥ唽鏂扮敤鎴峰苟杩斿洖 JWT"""
    import re
    if not re.match(r"^1[3-9]\d{9}$", body.phone):
        raise HTTPException(status_code=400, detail="鎵嬫満鍙锋牸寮忛敊璇?)

    # ---- 楠岃瘉鐮佹牎楠?----
    if REDIS_AVAILABLE:
        err_count = int(redis_client.get(_sms_err_key(body.phone)) or 0)
        if err_count >= 5:
            raise HTTPException(status_code=429, detail="閿欒娆℃暟杩囧锛岃閲嶆柊鑾峰彇楠岃瘉鐮?)

        stored = redis_client.get(_sms_code_key(body.phone))
        if not stored:
            raise HTTPException(status_code=400, detail="楠岃瘉鐮佸凡杩囨湡鎴栨湭鍙戦€?)
        if stored != body.code:
            redis_client.incr(_sms_err_key(body.phone))
            redis_client.expire(_sms_err_key(body.phone), 1800)
            raise HTTPException(status_code=400, detail="楠岃瘉鐮侀敊璇?)
        # 楠岃瘉鎴愬姛锛氬垹闄ら獙璇佺爜锛堜竴娆℃€э級
        redis_client.delete(_sms_code_key(body.phone))
        redis_client.delete(_sms_err_key(body.phone))
    else:
        # Redis 涓嶅彲鐢細鎺ュ彈 8888 鎴栨墜鏈哄悗4浣?
        expected = body.phone[-4:]
        if body.code not in ("8888", expected):
            raise HTTPException(status_code=400, detail="楠岃瘉鐮侀敊璇?)

    # ---- 鏌ユ壘鎴栧垱寤虹敤鎴?----
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
                uname   = f"鐢ㄦ埛{body.phone[-4:]}"
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

    # ---- 闄嶇骇锛氬唴瀛樻暟鎹簱 ----
    if user_data is None:
        for uid, u in USERS_DB.items():
            if u.get("phone") == body.phone:
                user_id   = uid
                user_data = {**u, "avatar": u.get("avatar")}
                break
        if not user_data:
            user_id = f"customer_{int(datetime.now().timestamp()*1000)}"
            user_data = {"id": user_id, "phone": body.phone,
                         "username": f"鐢ㄦ埛{body.phone[-4:]}",
                         "user_type": "customer", "balance": 0.0,
                         "points": 0, "avatar": None, "is_admin": False}
            USERS_DB[user_id] = {**user_data, "password": ""}

    # ---- 鐢熸垚 Token ----
    token         = create_jwt_token(user_id, {"phone": body.phone})
    refresh_token = create_jwt_token(user_id, {"phone": body.phone, "refresh": True,
                                               "exp": datetime.utcnow() + timedelta(days=30)})
    # 鍚屾椂鍐欏唴瀛?TOKENS_DB锛岃鏃ф帴鍙ｅ吋瀹?
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
    """鐢ㄦ埛鐧诲嚭"""
    if authorization:
        token = authorization.replace("Bearer ", "")
        TOKENS_DB.pop(token, None)
    return {"success": True, "message": "宸查€€鍑虹櫥褰?}

@app.post("/api/auth/refresh")
async def refresh_token(authorization: str = None):
    """鍒锋柊Token"""
    user_id = get_current_user_id(authorization or "")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token鏃犳晥")
    
    # 鐢熸垚鏂癟oken
    new_token = generate_token()
    TOKENS_DB[new_token] = user_id
    
    # 绉婚櫎鏃oken
    old_token = (authorization or "").replace("Bearer ", "")
    TOKENS_DB.pop(old_token, None)
    
    return {
        "token": new_token,
        "refresh_token": f"refresh_{new_token}",
        "expires_in": 3600
    }

# --- 鍟嗗搧 ---

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
    """鑾峰彇鍟嗗搧鍒楄〃"""
    products = list(PRODUCTS_DB.values())
    
    # 绛涢€?
    if category and category != "鍏ㄩ儴":
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
    
    # 鎺掑簭
    if sort_by == "price_asc":
        products.sort(key=lambda x: x.price)
    elif sort_by == "price_desc":
        products.sort(key=lambda x: x.price, reverse=True)
    elif sort_by == "sales":
        products.sort(key=lambda x: x.sales_count, reverse=True)
    elif sort_by == "rating":
        products.sort(key=lambda x: x.rating, reverse=True)
    
    # 鍒嗛〉
    start = (page - 1) * page_size
    end = start + page_size
    
    return products[start:end]

@app.get("/api/products/{product_id}", response_model=Product)
async def get_product_detail(product_id: str):
    """鑾峰彇鍟嗗搧璇︽儏"""
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="鍟嗗搧涓嶅瓨鍦?)
    return PRODUCTS_DB[product_id]

@app.post("/api/products", response_model=Product)
async def create_product(product: ProductCreate, authorization: str = None):
    """鍒涘缓鍟嗗搧锛堢鐞嗗憳锛?""
    user_id = verify_token(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    
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
    """鏇存柊鍟嗗搧锛堢鐞嗗憳锛?""
    user_id = verify_token(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="鍟嗗搧涓嶅瓨鍦?)
    
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
    """鍒犻櫎鍟嗗搧锛堢鐞嗗憳锛?""
    user_id = verify_token(authorization)
    if not USERS_DB.get(user_id, {}).get("is_admin"):
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="鍟嗗搧涓嶅瓨鍦?)
    
    del PRODUCTS_DB[product_id]
    return {"success": True, "message": "鍟嗗搧宸插垹闄?}

# --- 搴楅摵 ---

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
    """鑾峰彇搴楅摵鍒楄〃"""
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
    
    # 鎸堿I浼樺厛绾ф帓搴?
    shops.sort(key=lambda x: x.ai_priority or 0, reverse=True)
    
    start = (page - 1) * page_size
    end = start + page_size
    
    return shops[start:end]

@app.get("/api/shops/{shop_id}", response_model=Shop)
async def get_shop_detail(shop_id: str):
    """鑾峰彇搴楅摵璇︽儏"""
    if shop_id not in SHOPS_DB:
        raise HTTPException(status_code=404, detail="搴楅摵涓嶅瓨鍦?)
    return SHOPS_DB[shop_id]

# --- 鍦板潃 ---

@app.get("/api/users/addresses", response_model=List[Address])
async def get_addresses(authorization: str = None):
    """鑾峰彇鐢ㄦ埛鍦板潃鍒楄〃"""
    user_id = verify_token(authorization)
    addresses = [a for a in ADDRESSES_DB.values() if a.user_id == user_id]
    # 榛樿鍦板潃鎺掑墠闈?
    addresses.sort(key=lambda x: x.is_default, reverse=True)
    return addresses

@app.post("/api/users/addresses", response_model=Address)
async def create_address(address: AddressCreate, authorization: str = None):
    """鍒涘缓鍦板潃"""
    user_id = verify_token(authorization)
    
    address_id = f"addr_{uuid.uuid4().hex[:8]}"
    
    # 濡傛灉璁句负榛樿锛屽彇娑堝叾浠栭粯璁?
    if address.is_default:
        for addr in ADDRESSES_DB.values():
            if addr.user_id == user_id:
                addr.is_default = False
    
    new_address = Address(id=address_id, user_id=user_id, **address.dict())
    ADDRESSES_DB[address_id] = new_address
    return new_address

@app.put("/api/users/addresses/{address_id}", response_model=Address)
async def update_address(address_id: str, address: AddressCreate, authorization: str = None):
    """鏇存柊鍦板潃"""
    user_id = verify_token(authorization)
    
    if address_id not in ADDRESSES_DB:
        raise HTTPException(status_code=404, detail="鍦板潃涓嶅瓨鍦?)
    
    existing = ADDRESSES_DB[address_id]
    if existing.user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    
    # 濡傛灉璁句负榛樿锛屽彇娑堝叾浠栭粯璁?
    if address.is_default:
        for addr in ADDRESSES_DB.values():
            if addr.user_id == user_id and addr.id != address_id:
                addr.is_default = False
    
    updated = Address(id=address_id, user_id=user_id, **address.dict())
    ADDRESSES_DB[address_id] = updated
    return updated

@app.delete("/api/users/addresses/{address_id}")
async def delete_address(address_id: str, authorization: str = None):
    """鍒犻櫎鍦板潃"""
    user_id = verify_token(authorization)
    
    if address_id not in ADDRESSES_DB:
        raise HTTPException(status_code=404, detail="鍦板潃涓嶅瓨鍦?)
    
    if ADDRESSES_DB[address_id].user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    
    del ADDRESSES_DB[address_id]
    return {"success": True, "message": "鍦板潃宸插垹闄?}

# --- 璐墿杞?---

@app.get("/api/cart")
async def get_cart(authorization: str = None):
    """鑾峰彇璐墿杞?""
    user_id = verify_token(authorization)
    cart = CARTS_DB.get(user_id, [])
    
    # 闄勫甫鍟嗗搧淇℃伅
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
    """娣诲姞鍒拌喘鐗╄溅"""
    user_id = verify_token(authorization)
    
    if item.product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="鍟嗗搧涓嶅瓨鍦?)
    
    if user_id not in CARTS_DB:
        CARTS_DB[user_id] = []
    
    # 妫€鏌ユ槸鍚﹀凡瀛樺湪
    for existing in CARTS_DB[user_id]:
        if existing.product_id == item.product_id:
            existing.quantity += item.quantity
            return {"success": True, "message": "宸叉洿鏂版暟閲?}
    
    CARTS_DB[user_id].append(item)
    return {"success": True, "message": "宸叉坊鍔犲埌璐墿杞?}

@app.put("/api/cart/{product_id}")
async def update_cart_item(product_id: str, quantity: int, authorization: str = None):
    """鏇存柊璐墿杞﹀晢鍝佹暟閲?""
    user_id = verify_token(authorization)
    
    if user_id not in CARTS_DB:
        raise HTTPException(status_code=404, detail="璐墿杞︿负绌?)
    
    for item in CARTS_DB[user_id]:
        if item.product_id == product_id:
            if quantity <= 0:
                CARTS_DB[user_id].remove(item)
            else:
                item.quantity = quantity
            return {"success": True}
    
    raise HTTPException(status_code=404, detail="鍟嗗搧涓嶅湪璐墿杞︿腑")

@app.delete("/api/cart/{product_id}")
async def remove_from_cart(product_id: str, authorization: str = None):
    """浠庤喘鐗╄溅绉婚櫎"""
    user_id = verify_token(authorization)
    
    if user_id in CARTS_DB:
        CARTS_DB[user_id] = [i for i in CARTS_DB[user_id] if i.product_id != product_id]
    
    return {"success": True, "message": "宸蹭粠璐墿杞︾Щ闄?}

@app.delete("/api/cart")
async def clear_cart(authorization: str = None):
    """娓呯┖璐墿杞?""
    user_id = verify_token(authorization)
    CARTS_DB[user_id] = []
    return {"success": True, "message": "璐墿杞﹀凡娓呯┖"}

# --- 璁㈠崟 ---

@app.get("/api/orders", response_model=List[Order])
async def get_orders(
    status: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    authorization: str = None
):
    """鑾峰彇璁㈠崟鍒楄〃"""
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
    """鑾峰彇璁㈠崟璇︽儏"""
    user_id = verify_token(authorization)
    
    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="璁㈠崟涓嶅瓨鍦?)
    
    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    
    return order

@app.post("/api/orders", response_model=Order)
async def create_order(order: OrderCreate, authorization: str = None):
    """鍒涘缓璁㈠崟"""
    user_id = verify_token(authorization)
    
    # 楠岃瘉鍦板潃
    if order.address_id not in ADDRESSES_DB:
        raise HTTPException(status_code=400, detail="鍦板潃涓嶅瓨鍦?)
    
    address = ADDRESSES_DB[order.address_id]
    if address.user_id != user_id:
        raise HTTPException(status_code=403, detail="鍦板潃涓嶅睘浜庡綋鍓嶇敤鎴?)
    
    # 璁＄畻鎬婚噾棰?
    total = 0.0
    items = []
    for item in order.items:
        if item["product_id"] not in PRODUCTS_DB:
            raise HTTPException(status_code=400, detail=f"鍟嗗搧 {item['product_id']} 涓嶅瓨鍦?)
        
        product = PRODUCTS_DB[item["product_id"]]
        quantity = item.get("quantity", 1)

        # 搴撳瓨鏍￠獙 + 鍘熷瓙鎵ｅ噺
        if product.stock < quantity:
            raise HTTPException(
                status_code=400,
                detail=f"鍟嗗搧 {product.name} 搴撳瓨涓嶈冻 (鍓╀綑{product.stock}浠?"
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
    
    # 娓呯┖璐墿杞︿腑宸蹭笅鍗曠殑鍟嗗搧
    if user_id in CARTS_DB:
        ordered_ids = {i["product_id"] for i in order.items}
        CARTS_DB[user_id] = [i for i in CARTS_DB[user_id] if i.product_id not in ordered_ids]
    
    return new_order

@app.post("/api/orders/checkout")
async def checkout(data: dict, authorization: str = None):
    """缁撶畻锛堟ā鎷熸敮浠橈級"""
    # 绠€鍖栫増缁撶畻锛屽疄闄呴渶瑕佸鎺ユ敮浠樼綉鍏?
    return {
        "success": True,
        "order_id": data.get("order_id"),
        "payment_url": f"https://pay.example.com/{data.get('order_id')}",
        "message": "璇峰畬鎴愭敮浠?
    }


# --- 鏀粯缃戝叧(妯℃嫙) ---

# 鍐呭瓨鏀粯璁板綍
PAYMENTS_DB: Dict[str, Dict] = {}

@app.post("/api/orders/{order_id}/pay")
async def pay_order(order_id: str, data: dict = None, authorization: str = None):
    """鍙戣捣鏀粯 鈥?鍒涘缓鏀粯璁板綍锛?绉掑悗鑷姩妯℃嫙鍥炶皟鎴愬姛"""
    user_id = verify_token(authorization)
    data = data or {}

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="璁㈠崟涓嶅瓨鍦?)

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    if order.status != "pending":
        raise HTTPException(status_code=400, detail=f"璁㈠崟鐘舵€佷负{order.status}锛屾棤娉曟敮浠?)

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

    # 鏍囪璁㈠崟鐨?payment_id
    ORDERS_DB[order_id] = Order(**{**order.dict(), "payment_id": payment_id})

    return {
        "success": True,
        "payment_id": payment_id,
        "amount": order.total_amount,
        "method": method,
        "status": "pending",
        "message": "鏀粯宸插垱寤猴紝璇风瓑寰呯‘璁?,
    }


@app.get("/api/orders/{order_id}/pay-status")
async def get_pay_status(order_id: str, authorization: str = None):
    """杞鏀粯鐘舵€?鈥?鑷姩鍦ㄥ垱寤?绉掑悗鏍囪涓烘垚鍔?""
    user_id = verify_token(authorization)

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="璁㈠崟涓嶅瓨鍦?)

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")

    pid = order.payment_id
    if not pid or pid not in PAYMENTS_DB:
        return {"status": "no_payment", "message": "鏈壘鍒版敮浠樿褰?}

    pay = PAYMENTS_DB[pid]

    # 鑷姩鍥炶皟閫昏緫: 鍒涘缓瓒呰繃3绉掑嵆瑙嗕负鎴愬姛
    if pay["status"] == "pending":
        created = datetime.fromisoformat(pay["created_at"])
        if (datetime.now() - created).total_seconds() >= 3:
            pay["status"] = "success"
            pay["paid_at"] = datetime.now().isoformat()
            PAYMENTS_DB[pid] = pay

            # 鍚屾鏇存柊璁㈠崟鐘舵€?
            now_str = datetime.now().isoformat()
            ORDERS_DB[order_id] = Order(**{
                **order.dict(),
                "status": "paid",
                "paid_at": now_str,
                "logistics_entries": [{
                    "time": now_str,
                    "status": "鏀粯鎴愬姛",
                    "description": f"璁㈠崟宸叉敮浠?楼{order.total_amount:.2f} ({pay['method']})",
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
    """鍙栨秷璁㈠崟 + 鎭㈠搴撳瓨"""
    user_id = verify_token(authorization)
    data = data or {}

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="璁㈠崟涓嶅瓨鍦?)

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    if order.status not in ("pending", "paid"):
        raise HTTPException(status_code=400, detail=f"璁㈠崟鐘舵€佷负{order.status}锛屾棤娉曞彇娑?)

    # 鎭㈠搴撳瓨
    for item in order.items:
        pid = item.get("product_id")
        qty = item.get("quantity", 1)
        if pid and pid in PRODUCTS_DB:
            p = PRODUCTS_DB[pid]
            PRODUCTS_DB[pid] = Product(**{**p.dict(), "stock": p.stock + qty,
                                          "sales_count": max(0, p.sales_count - qty)})

    now_str = datetime.now().isoformat()
    reason = data.get("reason", "鐢ㄦ埛涓诲姩鍙栨秷")
    ORDERS_DB[order_id] = Order(**{
        **order.dict(),
        "status": "cancelled",
        "cancelled_at": now_str,
        "cancel_reason": reason,
        "logistics_entries": [{
            "time": now_str,
            "status": "璁㈠崟宸插彇娑?,
            "description": reason,
        }] + order.logistics_entries,
    })

    return {"success": True, "message": "璁㈠崟宸插彇娑堬紝搴撳瓨宸叉仮澶?}


@app.post("/api/admin/orders/{order_id}/ship")
async def ship_order(order_id: str, data: dict, authorization: str = None):
    """绠＄悊鍛?鍟嗗鍙戣揣"""
    user_id = verify_token(authorization)

    # 绠€鍗曟潈闄愭鏌? 绠＄悊鍛?
    user = USERS_DB.get(user_id, {})
    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="闇€瑕佺鐞嗗憳鏉冮檺")

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="璁㈠崟涓嶅瓨鍦?)

    order = ORDERS_DB[order_id]
    if order.status != "paid":
        raise HTTPException(status_code=400, detail=f"璁㈠崟鐘舵€佷负{order.status}锛屾棤娉曞彂璐?)

    carrier = data.get("carrier", "椤轰赴閫熻繍")
    tracking = data.get("tracking_number", f"SF{random.randint(10**11, 10**12-1)}")
    now_str = datetime.now().isoformat()

    entries = [
        {"time": now_str, "status": "宸插彂璐?,
         "description": f"鍟嗗宸插彂璐э紝{carrier} 杩愬崟鍙?{tracking}"},
        {"time": now_str, "status": "鎻芥敹",
         "description": f"蹇欢宸茶{carrier}鎻芥敹"},
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
    """纭鏀惰揣"""
    user_id = verify_token(authorization)

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="璁㈠崟涓嶅瓨鍦?)

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    if order.status != "shipped":
        raise HTTPException(status_code=400, detail=f"璁㈠崟鐘舵€佷负{order.status}锛屾棤娉曠‘璁ゆ敹璐?)

    now_str = datetime.now().isoformat()
    ORDERS_DB[order_id] = Order(**{
        **order.dict(),
        "status": "completed",
        "delivered_at": now_str,
        "completed_at": now_str,
        "logistics_entries": [{
            "time": now_str,
            "status": "宸茬鏀?,
            "description": "涔板宸茬‘璁ゆ敹璐э紝浜ゆ槗瀹屾垚",
        }] + order.logistics_entries,
    })

    return {"success": True, "message": "宸茬‘璁ゆ敹璐?}


@app.post("/api/orders/{order_id}/refund")
async def request_refund(order_id: str, data: dict = None, authorization: str = None):
    """鐢宠閫€娆?""
    user_id = verify_token(authorization)
    data = data or {}

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="璁㈠崟涓嶅瓨鍦?)

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")
    if order.status not in ("paid", "shipped", "completed"):
        raise HTTPException(status_code=400, detail=f"璁㈠崟鐘舵€佷负{order.status}锛屾棤娉曢€€娆?)

    reason = data.get("reason", "涔板鐢宠閫€娆?)
    now_str = datetime.now().isoformat()

    ORDERS_DB[order_id] = Order(**{
        **order.dict(),
        "status": "refunding",
        "refund_reason": reason,
        "refund_amount": order.total_amount,
        "logistics_entries": [{
            "time": now_str,
            "status": "閫€娆剧敵璇?,
            "description": f"涔板鐢宠閫€娆? {reason}",
        }] + order.logistics_entries,
    })

    return {"success": True, "message": "閫€娆剧敵璇峰凡鎻愪氦", "refund_amount": order.total_amount}


@app.get("/api/orders/{order_id}/logistics")
async def get_order_logistics(order_id: str, authorization: str = None):
    """鑾峰彇鐗╂祦杞ㄨ抗"""
    user_id = verify_token(authorization)

    if order_id not in ORDERS_DB:
        raise HTTPException(status_code=404, detail="璁㈠崟涓嶅瓨鍦?)

    order = ORDERS_DB[order_id]
    if order.user_id != user_id:
        # 绠＄悊鍛樹篃鍙互鏌ョ湅
        user = USERS_DB.get(user_id, {})
        if not user.get("is_admin"):
            raise HTTPException(status_code=403, detail="娌℃湁鏉冮檺")

    return {
        "order_id": order_id,
        "carrier": order.logistics_company,
        "tracking_number": order.tracking_number,
        "status": order.status,
        "entries": order.logistics_entries,
    }


@app.get("/api/orders/stats")
async def get_order_stats(authorization: str = None):
    """鑾峰彇褰撳墠鐢ㄦ埛鐨勮鍗曠粺璁?""
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
    """绠＄悊绔粺璁￠潰鏉?""
    user_id = verify_token(authorization)
    user = USERS_DB.get(user_id, {})
    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="闇€瑕佺鐞嗗憳鏉冮檺")

    all_orders = list(ORDERS_DB.values())
    today = datetime.now().date()
    today_orders = [o for o in all_orders
                    if datetime.fromisoformat(o.created_at).date() == today]

    total_revenue = sum(o.total_amount for o in all_orders if o.status in ("paid", "shipped", "completed"))
    today_revenue = sum(o.total_amount for o in today_orders if o.status in ("paid", "shipped", "completed"))

    # 寰呭鐞嗘眹鎬?
    pending_ship = sum(1 for o in all_orders if o.status == "paid")
    pending_refund = sum(1 for o in all_orders if o.status == "refunding")

    # 鎿嶄綔鍛樻暟閲?
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
    """鏈€杩戞搷浣滃姩鎬?鈥?浠庣湡瀹炶鍗曠敓鎴?""
    user_id = verify_token(authorization)
    user = USERS_DB.get(user_id, {})
    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="闇€瑕佺鐞嗗憳鏉冮檺")

    activities = []

    # 浠庤鍗曠敓鎴愭椿鍔?
    recent_orders = sorted(ORDERS_DB.values(),
                           key=lambda o: o.created_at, reverse=True)[:limit]
    for o in recent_orders:
        item_name = o.items[0].get("product_name", "鍟嗗搧") if o.items else "鍟嗗搧"
        qty = sum(i.get("quantity", 1) for i in o.items)

        if o.status == "pending":
            activities.append({
                "tag": "璁㈠崟", "title": f"鏂拌鍗? {item_name} x{qty}",
                "subtitle": f"楼{o.total_amount:.0f}",
                "time": o.created_at, "type": "order_new",
            })
        elif o.status == "paid":
            activities.append({
                "tag": "鏀粯", "title": f"鏀粯瀹屾垚: {item_name}",
                "subtitle": f"楼{o.total_amount:.0f}",
                "time": o.paid_at or o.created_at, "type": "order_paid",
            })
        elif o.status == "shipped":
            activities.append({
                "tag": "鐗╂祦", "title": f"宸插彂璐? {o.tracking_number or ''}",
                "subtitle": f"{o.logistics_company or ''} 路 {item_name}",
                "time": o.shipped_at or o.created_at, "type": "order_shipped",
            })
        elif o.status == "completed":
            activities.append({
                "tag": "瀹屾垚", "title": f"浜ゆ槗瀹屾垚: {item_name}",
                "subtitle": f"楼{o.total_amount:.0f}",
                "time": o.completed_at or o.created_at, "type": "order_completed",
            })
        elif o.status == "refunding":
            activities.append({
                "tag": "閫€娆?, "title": f"閫€娆剧敵璇? {item_name}",
                "subtitle": o.refund_reason or "",
                "time": o.created_at, "type": "order_refund",
            })

    # 浣庡簱瀛橀璀?
    for p in PRODUCTS_DB.values():
        if p.stock <= 5:
            activities.append({
                "tag": "搴撳瓨", "title": f"搴撳瓨棰勮: {p.name}",
                "subtitle": f"褰撳墠搴撳瓨 {p.stock} 浠?,
                "time": datetime.now().isoformat(), "type": "stock_warning",
            })

    # 鎸夋椂闂存帓搴?
    activities.sort(key=lambda a: a.get("time", ""), reverse=True)
    return {"items": activities[:limit], "total": len(activities)}


# --- 鏀惰棌 ---

@app.get("/api/favorites")
async def get_favorites(authorization: str = None):
    """鑾峰彇鏀惰棌鍒楄〃"""
    user_id = verify_token(authorization)
    
    favorite_ids = FAVORITES_DB.get(user_id, [])
    products = [PRODUCTS_DB[pid] for pid in favorite_ids if pid in PRODUCTS_DB]
    
    return {"items": [p.dict() for p in products], "total": len(products)}

@app.post("/api/favorites/{product_id}")
async def add_favorite(product_id: str, authorization: str = None):
    """娣诲姞鏀惰棌"""
    user_id = verify_token(authorization)
    
    if product_id not in PRODUCTS_DB:
        raise HTTPException(status_code=404, detail="鍟嗗搧涓嶅瓨鍦?)
    
    if user_id not in FAVORITES_DB:
        FAVORITES_DB[user_id] = []
    
    if product_id not in FAVORITES_DB[user_id]:
        FAVORITES_DB[user_id].append(product_id)
    
    return {"success": True, "message": "宸叉坊鍔犳敹钘?}

@app.delete("/api/favorites/{product_id}")
async def remove_favorite(product_id: str, authorization: str = None):
    """鍙栨秷鏀惰棌"""
    user_id = verify_token(authorization)
    
    if user_id in FAVORITES_DB and product_id in FAVORITES_DB[user_id]:
        FAVORITES_DB[user_id].remove(product_id)
    
    return {"success": True, "message": "宸插彇娑堟敹钘?}

# --- 璇勪环 ---

@app.get("/api/products/{product_id}/reviews", response_model=List[Review])
async def get_product_reviews(
    product_id: str,
    page: int = 1,
    page_size: int = 20
):
    """鑾峰彇鍟嗗搧璇勪环"""
    reviews = [r for r in REVIEWS_DB.values() if r.product_id == product_id]
    reviews.sort(key=lambda x: x.created_at, reverse=True)
    
    start = (page - 1) * page_size
    end = start + page_size
    
    return reviews[start:end]

@app.post("/api/reviews", response_model=Review)
async def create_review(review: ReviewCreate, authorization: str = None):
    """鍒涘缓璇勪环"""
    user_id = verify_token(authorization)
    user = USERS_DB.get(user_id, {})
    
    review_id = f"rev_{uuid.uuid4().hex[:8]}"
    
    new_review = Review(
        id=review_id,
        product_id=review.product_id,
        user_id=user_id,
        user_name=user.get("username", "鐢ㄦ埛") if not review.is_anonymous else "鍖垮悕鐢ㄦ埛",
        user_avatar=user.get("avatar"),
        rating=review.rating,
        content=review.content,
        images=review.images,
        created_at=datetime.now().isoformat(),
        is_anonymous=review.is_anonymous
    )
    
    REVIEWS_DB[review_id] = new_review
    
    # 鏇存柊鍟嗗搧璇勫垎
    if review.product_id in PRODUCTS_DB:
        product = PRODUCTS_DB[review.product_id]
        product_reviews = [r for r in REVIEWS_DB.values() if r.product_id == review.product_id]
        if product_reviews:
            avg_rating = sum(r.rating for r in product_reviews) / len(product_reviews)
            # 鏇存柊璇勫垎锛堣繖閲岄渶瑕佸垱寤烘柊瀵硅薄锛屽洜涓篜ydantic妯″瀷鏄笉鍙彉鐨勶級
            PRODUCTS_DB[review.product_id] = Product(
                **{**product.dict(), "rating": round(avg_rating, 1)}
            )
    
    return new_review

# --- 鏂囦欢涓婁紶 ---

@app.post("/api/upload/image")
async def upload_image(
    file: UploadFile = File(...),
    folder: str = Form("images")
):
    """涓婁紶鍥剧墖"""
    # 楠岃瘉鏂囦欢绫诲瀷
    allowed_types = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="涓嶆敮鎸佺殑鍥剧墖鏍煎紡")
    
    # 鐢熸垚鏂囦欢鍚?
    ext = file.filename.split(".")[-1] if file.filename else "jpg"
    filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}.{ext}"
    
    # 淇濆瓨鏂囦欢
    folder_path = os.path.join(UPLOAD_DIR, folder)
    os.makedirs(folder_path, exist_ok=True)
    
    file_path = os.path.join(folder_path, filename)
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
    
    # 杩斿洖URL
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
    """鑾峰彇OSS STS涓存椂鍑瘉"""
    verify_token(authorization)
    
    # 杩欓噷杩斿洖妯℃嫙鏁版嵁锛屽疄闄呴渶瑕佽皟鐢ㄩ樋閲屼簯STS鏈嶅姟
    # 鍙傝€? https://help.aliyun.com/document_detail/100624.html
    
    expiration = (datetime.now() + timedelta(hours=1)).isoformat() + "Z"
    
    return OssStsResponse(
        access_key_id="MOCK_ACCESS_KEY_ID",
        access_key_secret="MOCK_ACCESS_KEY_SECRET",
        security_token="MOCK_SECURITY_TOKEN",
        expiration=expiration
    )

# --- 鎺ㄩ€侀€氱煡 ---

@app.post("/api/notifications/register")
async def register_device(data: NotificationRegister, authorization: str = None):
    """娉ㄥ唽璁惧Token"""
    user_id = verify_token(authorization)
    
    DEVICES_DB[data.device_token] = {
        "user_id": user_id,
        "platform": data.platform,
        "settings": data.settings or {},
        "registered_at": datetime.now().isoformat()
    }
    
    return {"success": True, "message": "璁惧宸叉敞鍐?}

@app.get("/api/notifications")
async def get_notifications(
    page: int = 1,
    page_size: int = 20,
    authorization: str = None
):
    """鑾峰彇閫氱煡鍒楄〃"""
    verify_token(authorization)
    
    # 妯℃嫙閫氱煡鏁版嵁
    notifications = [
        {
            "id": "n001",
            "title": "璁㈠崟鍙戣揣閫氱煡",
            "body": "鎮ㄧ殑璁㈠崟宸插彂璐э紝璇锋敞鎰忔煡鏀?,
            "type": "logistics",
            "created_at": datetime.now().isoformat(),
            "is_read": False
        },
        {
            "id": "n002",
            "title": "鏂板搧涓婃灦",
            "body": "鍜岀敯鐜夋柊鍝佸凡涓婃灦锛屽揩鏉ョ湅鐪嬪惂",
            "type": "promotion",
            "created_at": (datetime.now() - timedelta(hours=2)).isoformat(),
            "is_read": True
        }
    ]
    
    return {"items": notifications, "total": len(notifications), "unread": 1}

# --- 鐢ㄦ埛淇℃伅 ---

@app.get("/api/users/profile")
async def get_profile(authorization: str = None):
    """鑾峰彇鐢ㄦ埛淇℃伅"""
    user_id = verify_token(authorization)
    
    if user_id not in USERS_DB:
        raise HTTPException(status_code=404, detail="鐢ㄦ埛涓嶅瓨鍦?)
    
    user = USERS_DB[user_id]
    return UserResponse(**user).dict()

@app.put("/api/users/profile")
async def update_profile(data: dict, authorization: str = None):
    """鏇存柊鐢ㄦ埛淇℃伅"""
    user_id = verify_token(authorization)
    
    if user_id not in USERS_DB:
        raise HTTPException(status_code=404, detail="鐢ㄦ埛涓嶅瓨鍦?)
    
    # 鍙厑璁告洿鏂扮壒瀹氬瓧娈?
    allowed_fields = {"username", "avatar"}
    for key, value in data.items():
        if key in allowed_fields:
            USERS_DB[user_id][key] = value
    
    return {"success": True, "user": UserResponse(**USERS_DB[user_id]).dict()}

# --- AI 鍥剧墖鍒嗘瀽浠ｇ悊 ---

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")

@app.post("/api/ai/analyze-image")
async def analyze_image(file: UploadFile = File(...)):
    """AI鍥剧墖鍒嗘瀽锛堟湇鍔＄浠ｇ悊锛岃В鍐冲浗鍐呮棤娉曠洿杩濭emini鐨勯棶棰橈級
    
    浼樺厛浣跨敤 OpenRouter Qwen-VL锛屽洖閫€鍒?OpenRouter 鏂囨湰鎻忚堪锛堝崰浣嶏級銆?
    """
    import httpx, base64

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="鍥剧墖涓嶈兘瓒呰繃10MB")

    b64 = base64.b64encode(image_bytes).decode()
    mime = file.content_type or "image/jpeg"
    data_uri = f"data:{mime};base64,{b64}"

    prompt = (
        "璇峰垎鏋愯繖寮犵彔瀹濆浘鐗囷紝杩斿洖涓ユ牸JSON锛歕n"
        '{"description":"璇︾粏鎻忚堪","material":"鏉愯川","category":"鍒嗙被(鎵嬮摼/鍚婂潬/鎴掓寚/鎵嬮暞/椤归摼/鑰抽グ)","tags":["鏍囩"],"quality_score":0.8,"suggestion":"寤鸿"}'
    )

    # ---- 鏂规1: OpenRouter Qwen-VL ----
    if OPENROUTER_API_KEY:
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                resp = await client.post(
                    "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "nvidia/nemotron-nano-12b-v2-vl:free",
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
                    # 灏濊瘯瑙ｆ瀽JSON
                    import re as _re
                    j = _re.search(r'\{[\s\S]*\}', text)
                    if j:
                        return {"success": True, "analysis": json.loads(j.group(0)), "raw": text}
                    return {"success": True, "analysis": {"description": text}, "raw": text}
                else:
                    logging.warning(f"OpenRouter error: {resp.status_code} {resp.text[:200]}")
        except Exception as e:
            logging.warning(f"OpenRouter failed: {e}")

    # ---- 鏂规2: OpenRouter 鏂囧瓧鎻忚堪 (鏃犺瑙夎兘鍔涳紝閫€鍖? ----
    if OPENROUTER_API_KEY:
        return {
            "success": True,
            "analysis": {
                "description": "鍥剧墖宸蹭笂浼狅紝浣嗗綋鍓岮I瑙嗚妯″瀷鏈厤缃€傝鍦ㄦ湇鍔″櫒璁剧疆 OPENROUTER_API_KEY 鐜鍙橀噺浠ュ惎鐢ㄩ€氫箟鍗冮棶鍥剧墖鍒嗘瀽銆?,
                "material": "寰呴厤缃?,
                "category": "寰呴厤缃?,
            },
            "raw": "AI瑙嗚妯″瀷鏈厤缃?,
        }

    raise HTTPException(status_code=503, detail="AI鍒嗘瀽鏈嶅姟鏈厤缃紝璇疯缃?OPENROUTER_API_KEY")


# ============ 鍚姩 ============

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
