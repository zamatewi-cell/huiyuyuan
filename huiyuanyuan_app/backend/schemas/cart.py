"""购物车 Pydantic 模型"""

from pydantic import BaseModel


class CartItem(BaseModel):
    product_id: str
    quantity: int
    selected: bool = True
