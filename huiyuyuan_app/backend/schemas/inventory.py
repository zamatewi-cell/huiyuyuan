"""Inventory schemas shared by the admin inventory APIs."""

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field


InventoryTxType = Literal["stockIn", "stockOut", "adjustment", "returnIn"]


class InventoryItemResponse(BaseModel):
    product_id: str
    product_name: str
    category: str
    image_url: Optional[str] = None
    current_stock: int = Field(ge=0)
    min_stock: int = Field(default=10, ge=0)
    cost_price: float = Field(ge=0)
    selling_price: float = Field(ge=0)
    last_updated: datetime


class InventoryStockUpdate(BaseModel):
    current_stock: int = Field(ge=0)
    min_stock: Optional[int] = Field(default=None, ge=0)
    cost_price: Optional[float] = Field(default=None, ge=0)


class InventoryTransactionRecord(BaseModel):
    id: str
    product_id: str
    product_name: str
    type: InventoryTxType
    quantity: int = Field(gt=0)
    stock_before: int = Field(ge=0)
    stock_after: int = Field(ge=0)
    note: Optional[str] = None
    operator_name: Optional[str] = None
    created_at: datetime


class InventoryTransactionCreate(InventoryTransactionRecord):
    pass
