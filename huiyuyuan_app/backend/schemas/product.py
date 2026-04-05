"""商品相关 Pydantic 模型"""

from pydantic import BaseModel
from typing import List, Optional


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

    # ---- 多语言翻译字段 ----
    name_en: Optional[str] = None
    description_en: Optional[str] = None
    category_en: Optional[str] = None
    material_en: Optional[str] = None
    origin_en: Optional[str] = None
    material_verify_en: Optional[str] = None

    name_zh_tw: Optional[str] = None
    description_zh_tw: Optional[str] = None
    category_zh_tw: Optional[str] = None
    material_zh_tw: Optional[str] = None
    origin_zh_tw: Optional[str] = None
    material_verify_zh_tw: Optional[str] = None


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
