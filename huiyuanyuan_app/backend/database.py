"""
数据库连接管理 — SQLAlchemy + PostgreSQL
生产环境必须连接数据库；仅开发环境允许降级到内存存储。
"""

import logging
from typing import Optional, Generator

from fastapi import HTTPException
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session

from config import DATABASE_URL, IS_PRODUCTION

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
        if IS_PRODUCTION:
            raise RuntimeError(f"PostgreSQL 连接失败，生产环境不能降级到内存存储: {e}") from e
        logger.warning(f"??  PostgreSQL 不可用: {e}，将使用内存存储")
else:
    if IS_PRODUCTION:
        raise RuntimeError("DATABASE_URL 未配置，生产环境必须连接 PostgreSQL。")
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


def require_database(db: Optional[Session], operation: str = "当前操作") -> Optional[Session]:
    """生产环境缺少数据库时直接拒绝回退到内存。"""
    if db is None and IS_PRODUCTION:
        raise HTTPException(status_code=503, detail=f"{operation}依赖数据库服务")
    return db


def handle_database_error(
    db: Optional[Session],
    operation: str,
    exc: Exception,
) -> None:
    """记录数据库异常；生产环境直接返回 503。"""
    if db is not None:
        try:
            db.rollback()
        except Exception:
            logger.exception("DB rollback failed during %s", operation)

    logger.error("DB %s: %s", operation, exc)

    if IS_PRODUCTION:
        raise HTTPException(status_code=503, detail=f"{operation}失败，请稍后重试")
