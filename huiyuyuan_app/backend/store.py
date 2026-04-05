"""
内存存储 — DB 不可用时的降级方案
生产环境应使用 PostgreSQL，此模块作为开发/回退使用
"""

import logging
from typing import Dict, List

from schemas.product import Product
from schemas.cart import CartItem
from schemas.review import Review
from schemas.shop import Shop
from schemas.user import Address, PaymentAccountResponse
from schemas.order import Order
from services.product_seed_import_service import build_in_memory_seed_products

logger = logging.getLogger(__name__)

# ---- 用户 (dict 格式，含 password_hash) ----
USERS_DB: Dict[str, Dict] = {}

# ---- 商品 ----
PRODUCTS_DB: Dict[str, Product] = {}

# ---- 店铺 ----
SHOPS_DB: Dict[str, Shop] = {}

# ---- 地址 ----
ADDRESSES_DB: Dict[str, Address] = {}

# ---- 订单 ----
ORDERS_DB: Dict[str, Order] = {}

# ---- 购物车 ----
CARTS_DB: Dict[str, List[CartItem]] = {}

# ---- 收藏 ----
FAVORITES_DB: Dict[str, List[str]] = {}

# ---- 评价 ----
REVIEWS_DB: Dict[str, Review] = {}

# ---- Token 映射 (token → user_id) ----
TOKENS_DB: Dict[str, str] = {}

# ---- 设备 Token ----
DEVICES_DB: Dict[str, Dict] = {}

# ---- 支付记录 ----
PAYMENTS_DB: Dict[str, Dict] = {}

# ---- 收款账户 ----
PAYMENT_ACCOUNTS_DB: Dict[str, PaymentAccountResponse] = {}
INVENTORY_META_DB: Dict[str, Dict] = {}
INVENTORY_TRANSACTIONS_DB: List[Dict] = []


def init_default_users():
    """初始化默认用户（管理员 + 10个操作员）— 密码使用 bcrypt"""
    from security import hash_password

    if "admin_001" not in USERS_DB:
        USERS_DB["admin_001"] = {
            "id": "admin_001",
            "username": "超级管理员",
            "phone": "18937766669",
            "password_hash": hash_password("admin123"),
            "is_admin": True,
            "balance": 999999.0,
            "points": 99999,
            "avatar": None,
            "user_type": "admin",
        }

    for i in range(1, 11):
        uid = f"operator_{i}"
        if uid not in USERS_DB:
            USERS_DB[uid] = {
                "id": uid,
                "username": f"操作员{i}",
                "phone": f"1380000000{i}",
                "password_hash": hash_password("op123456"),
                "is_admin": False,
                "balance": 0.0,
                "points": 100,
                "avatar": None,
                "operator_number": i,
                "user_type": "operator",
            }


def init_products():
    """从种子数据初始化商品"""
    for product in build_in_memory_seed_products():
        if product.id not in PRODUCTS_DB:
            PRODUCTS_DB[product.id] = product


def init_store():
    """初始化所有内存数据"""
    init_default_users()
    init_products()
    logger.info(f"内存存储已初始化: {len(USERS_DB)} 用户, {len(PRODUCTS_DB)} 商品")
