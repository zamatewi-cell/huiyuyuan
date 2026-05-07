"""商品相关 Pydantic 模型"""

import json

from pydantic import BaseModel, field_validator
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

    # ---- 一物一档：鉴定说明（三语）----
    appraisal_note: Optional[str] = None
    appraisal_note_en: Optional[str] = None
    appraisal_note_zh_tw: Optional[str] = None

    # ---- 一物一档：工艺亮点（三语）----
    craft_highlights: Optional[List[str]] = None
    craft_highlights_en: Optional[List[str]] = None
    craft_highlights_zh_tw: Optional[List[str]] = None

    # ---- 物理规格（无语言差异）----
    weight_g: Optional[float] = None
    dimensions: Optional[str] = None

    # ---- one product, one dossier: audience fit (trilingual tags) ----
    audience_tags: Optional[List[str]] = None
    audience_tags_en: Optional[List[str]] = None
    audience_tags_zh_tw: Optional[List[str]] = None

    # ---- one product, one dossier: origin story (trilingual text) ----
    origin_story: Optional[str] = None
    origin_story_en: Optional[str] = None
    origin_story_zh_tw: Optional[str] = None

    # ---- one product, one dossier: visible flaws / caveats (trilingual tags) ----
    flaw_notes: Optional[List[str]] = None
    flaw_notes_en: Optional[List[str]] = None
    flaw_notes_zh_tw: Optional[List[str]] = None

    # ---- one product, one dossier: certificate evidence ----
    certificate_authority: Optional[str] = None
    certificate_authority_en: Optional[str] = None
    certificate_authority_zh_tw: Optional[str] = None
    certificate_image_url: Optional[str] = None
    certificate_verify_url: Optional[str] = None

    # ---- one product, one dossier: supplementary gallery ----
    gallery_detail: Optional[List[str]] = None
    gallery_hand: Optional[List[str]] = None

    @field_validator(
        "craft_highlights",
        "craft_highlights_en",
        "craft_highlights_zh_tw",
        "audience_tags",
        "audience_tags_en",
        "audience_tags_zh_tw",
        "flaw_notes",
        "flaw_notes_en",
        "flaw_notes_zh_tw",
        "gallery_detail",
        "gallery_hand",
        mode="before",
    )
    @classmethod
    def _coerce_string_list(cls, value):
        if value is None:
            return None
        if isinstance(value, list):
            items = [str(item).strip() for item in value if str(item).strip()]
            return items or None
        if isinstance(value, str):
            stripped = value.strip()
            if not stripped:
                return None
            try:
                parsed = json.loads(stripped)
            except Exception:
                parsed = None
            if isinstance(parsed, list):
                items = [str(item).strip() for item in parsed if str(item).strip()]
                return items or None
            lines = [
                line.strip().lstrip("•-*· ").strip()
                for line in stripped.splitlines()
                if line.strip()
            ]
            return lines or [stripped]
        return value


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
    appraisal_note: Optional[str] = None
    appraisal_note_en: Optional[str] = None
    appraisal_note_zh_tw: Optional[str] = None
    craft_highlights: Optional[List[str]] = None
    craft_highlights_en: Optional[List[str]] = None
    craft_highlights_zh_tw: Optional[List[str]] = None
    weight_g: Optional[float] = None
    dimensions: Optional[str] = None
    audience_tags: Optional[List[str]] = None
    audience_tags_en: Optional[List[str]] = None
    audience_tags_zh_tw: Optional[List[str]] = None
    origin_story: Optional[str] = None
    origin_story_en: Optional[str] = None
    origin_story_zh_tw: Optional[str] = None
    flaw_notes: Optional[List[str]] = None
    flaw_notes_en: Optional[List[str]] = None
    flaw_notes_zh_tw: Optional[List[str]] = None
    certificate_authority: Optional[str] = None
    certificate_authority_en: Optional[str] = None
    certificate_authority_zh_tw: Optional[str] = None
    certificate_image_url: Optional[str] = None
    certificate_verify_url: Optional[str] = None
    gallery_detail: Optional[List[str]] = None
    gallery_hand: Optional[List[str]] = None

    @field_validator(
        "craft_highlights",
        "craft_highlights_en",
        "craft_highlights_zh_tw",
        "audience_tags",
        "audience_tags_en",
        "audience_tags_zh_tw",
        "flaw_notes",
        "flaw_notes_en",
        "flaw_notes_zh_tw",
        "gallery_detail",
        "gallery_hand",
        mode="before",
    )
    @classmethod
    def _coerce_string_list(cls, value):
        return Product._coerce_string_list(value)
