# -*- coding: utf-8 -*-
"""Shared product media helpers for API responses and seed imports."""

from __future__ import annotations

from typing import Iterable
from urllib.parse import urlparse

_KNOWN_BROKEN_UNSPLASH_IDS = {
    "1661645464570-9a4f3d4dd061",
    "1681276170092-446cd1b5b32d",
    "1661645473770-90d750452fa0",
    "1726743629168-77847c4cbb6a",
    "1678749105251-b15e8fd164bf",
    "1724088684005-4f9f2e1ec43c",
    "1739899051444-fcbdb848db5d",
    "1674255466849-b23fc5f5d3eb",
    "1674255466836-f38d1cc6fd0d",
    "1736818881523-87556344c1a2",
    "1681276170281-cf50a487a1b7",
    "1674157905253-1f5dc638a588",
    "1664202526641-4203eaa33844",
    "1681276169919-d89839416ef7",
    "1674748385691-a185ad303097",
    "1667206795522-430ed80bd9d8",
    "1728216320421-acadfa847591",
    "1673284258408-3341659fbc87",
    "1734315041597-a561152a875b",
    "1671209796002-5da9a14106de",
    "1670728016218-3a3ceec0a483",
    "1661811815190-b99942bf3b74",
}

_DEFAULT_IMAGE_IDS = {
    "和田玉": "photo-1611591437281-460bfbe1220a",
    "缅甸翡翠": "photo-1588444837495-c6cfeb53f32d",
    "南红玛瑙": "photo-1602751584552-8ba73aad10e1",
    "紫水晶": "photo-1629224316810-9d8805b95e76",
    "黄金": "photo-1619119069152-a2b331eb392a",
    "红宝石": "photo-1573408301185-9146fe634ad0",
    "蓝宝石": "photo-1515562141207-7a88fb7ce338",
    "碧玉": "photo-1610375461246-83df859d849d",
    "蜜蜡": "photo-1608042314453-ae338d80c427",
    "琥珀": "photo-1608042314453-ae338d80c427",
    "钻石": "photo-1605100804763-247f67b3557e",
    "珍珠": "photo-1739700285847-2f173370e8a7",
    "纯银": "photo-1605100804763-247f67b3557e",
    "绿松石": "photo-1515562141207-7a88fb7ce338",
    "玛瑙": "photo-1602751584552-8ba73aad10e1",
    "天珠": "photo-1602751584552-8ba73aad10e1",
    "红珊瑚": "photo-1573408301185-9146fe634ad0",
    "珊瑚": "photo-1573408301185-9146fe634ad0",
    "祖母绿": "photo-1610375461246-83df859d849d",
    "坦桑石": "photo-1515562141207-7a88fb7ce338",
    "粉水晶": "photo-1629224316810-9d8805b95e76",
    "黄水晶": "photo-1608042314453-ae338d80c427",
    "碧玺": "photo-1629224316810-9d8805b95e76",
    "沉香": "photo-1608042314453-ae338d80c427",
    "小叶紫檀": "photo-1608042314453-ae338d80c427",
    "黄花梨": "photo-1608042314453-ae338d80c427",
    "砗磲": "photo-1739700285847-2f173370e8a7",
    "天河石": "photo-1515562141207-7a88fb7ce338",
    "青金石": "photo-1515562141207-7a88fb7ce338",
    "月光石": "photo-1605100804763-247f67b3557e",
    "石榴石": "photo-1573408301185-9146fe634ad0",
    "拉长石": "photo-1515562141207-7a88fb7ce338",
    "草莓晶": "photo-1629224316810-9d8805b95e76",
    "发晶": "photo-1605100804763-247f67b3557e",
    "孔雀石": "photo-1610375461246-83df859d849d",
    "天然石": "photo-1602751584552-8ba73aad10e1",
    "苗银": "photo-1605100804763-247f67b3557e",
}


def get_default_image_for_material(material: str | None) -> str:
    photo_id = _DEFAULT_IMAGE_IDS.get(material or "", "photo-1611591437281-460bfbe1220a")
    return f"https://images.unsplash.com/{photo_id}?w=800&h=800&fit=crop"


def is_known_broken_image(image_url: str | None) -> bool:
    if not image_url:
        return False
    parsed = urlparse(image_url)
    if "images.unsplash.com" not in parsed.netloc:
        return False
    path = parsed.path.rsplit("/", 1)[-1]
    return path in _KNOWN_BROKEN_UNSPLASH_IDS


def sanitize_product_images(
    images: Iterable[str] | None,
    material: str | None,
) -> list[str]:
    valid_images: list[str] = []
    for raw_image in images or ():
        image = str(raw_image).strip()
        if not image or is_known_broken_image(image) or image in valid_images:
            continue
        valid_images.append(image)

    if valid_images:
        return valid_images

    return [get_default_image_for_material(material)]
