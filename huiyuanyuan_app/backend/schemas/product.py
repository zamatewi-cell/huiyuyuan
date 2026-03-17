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
