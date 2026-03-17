"""
数据库连接管理 — SQLAlchemy + PostgreSQL
DB_AVAILABLE=False 时自动降级到内存存储
"""

import logging
from typing import Optional, Generator

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session

from config import DATABASE_URL

logger = logging.getLogger(__name__)

# ---- 初始化引擎 ----
DB_AVAILABLE = False
_engine = None
SessionLocal = None

if DATABASE_URL:
    try:
        _engine = create_engine(
            DATABASE_URL,
            pool_pre_ping=True,
            pool_size=5,
            max_overflow=10,
            pool_recycle=1800,
        )
        # 验证连接
        with _engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_engine)
        DB_AVAILABLE = True
        logger.info("? PostgreSQL 连接成功")
    except Exception as e:
        logger.warning(f"??  PostgreSQL 不可用: {e}，将使用内存存储")
else:
    logger.info("DATABASE_URL 未配置，使用内存存储")


# ---- Redis ----
redis_client = None
REDIS_AVAILABLE = False

try:
    import redis as _redis_lib
    from config import REDIS_URL
    redis_client = _redis_lib.from_url(
        REDIS_URL, decode_responses=True, socket_connect_timeout=2
    )
    redis_client.ping()
    REDIS_AVAILABLE = True
    logger.info("? Redis 连接成功")
except Exception as e:
    logger.warning(f"??  Redis 不可用: {e}")


# ---- FastAPI 依赖 ----
def get_db() -> Generator[Optional[Session], None, None]:
    """获取数据库会话，DB不可用时 yield None"""
    if not DB_AVAILABLE or SessionLocal is None:
        yield None
        return
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
