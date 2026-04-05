#!/usr/bin/env python3
"""
批量翻译脚本 — 将 products 表中所有商品翻译为英文和繁体中文

使用方式（在服务器上执行）：
    cd /srv/huiyuyuan/backend
    python scripts/batch_translate_products.py

依赖：
    - 数据库连接可用
    - DASHSCOPE_API_KEY 已配置
    - httpx 已安装
"""

import asyncio
import json
import logging
import os
import sys
import time

# 添加项目根目录到 path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)


async def main():
    from config import DASHSCOPE_API_KEY
    from database import SessionLocal, DB_AVAILABLE
    from sqlalchemy import text

    if not DB_AVAILABLE or SessionLocal is None:
        logger.error("❌ 数据库不可用")
        return

    if not DASHSCOPE_API_KEY:
        logger.error("❌ DASHSCOPE_API_KEY 未配置")
        return

    from services.translation_service import translate_product_fields

    db = SessionLocal()
    try:
        # 查找所有未翻译的商品（name_en IS NULL）
        rows = db.execute(text(
            "SELECT id, name, description, category, material, origin, material_verify "
            "FROM products WHERE is_active = true AND name_en IS NULL "
            "ORDER BY id"
        )).fetchall()

        total = len(rows)
        logger.info("📦 找到 %d 个待翻译商品", total)

        if total == 0:
            logger.info("✅ 所有商品已翻译完毕")
            return

        success = 0
        failed = 0

        for i, row in enumerate(rows):
            mapping = row._mapping
            product_id = mapping["id"]
            name = mapping["name"]
            category = mapping["category"] or ""
            material = mapping["material"] or ""
            origin = mapping.get("origin")
            material_verify = mapping.get("material_verify", "天然A货")
            description = mapping["description"] or ""

            logger.info("[%d/%d] 翻译: %s - %s", i + 1, total, product_id, name)

            try:
                translations = await translate_product_fields(
                    name=name,
                    description=description,
                    category=category,
                    material=material,
                    origin=origin,
                    material_verify=material_verify,
                )

                set_clauses = []
                params = {"id": product_id}
                for field, value in translations.items():
                    if value is not None:
                        set_clauses.append(f"{field} = :{field}")
                        params[field] = value

                if set_clauses:
                    sql = f"UPDATE products SET {', '.join(set_clauses)} WHERE id = :id"
                    db.execute(text(sql), params)
                    db.commit()
                    success += 1
                    logger.info("  ✅ EN: %s", translations.get("name_en", "N/A")[:60])
                    logger.info("  ✅ TW: %s", translations.get("name_zh_tw", "N/A")[:60])
                else:
                    logger.warning("  ⚠️ 翻译结果为空")
                    failed += 1

            except Exception as e:
                logger.error("  ❌ 翻译失败: %s", e)
                failed += 1
                db.rollback()

            # 限流：每个商品间隔 1 秒，避免 API 限流
            if i < total - 1:
                await asyncio.sleep(1.0)

        logger.info("")
        logger.info("=" * 50)
        logger.info("翻译完成：✅ 成功 %d / ❌ 失败 %d / 共 %d", success, failed, total)
        logger.info("=" * 50)

    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(main())
