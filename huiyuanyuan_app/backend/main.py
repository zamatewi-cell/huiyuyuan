"""
HuiYuYuan Backend API v4.0 - Modular Architecture Entry Point
Architecture: main.py -> routers/ -> services/ -> database/store
"""

import os
import logging
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import ALLOWED_ORIGINS, UPLOAD_DIR, APP_ENV
from database import DB_AVAILABLE, REDIS_AVAILABLE
from store import init_store
from logging_config import setup_logging, RequestLoggingMiddleware

# ---- Logging ----
setup_logging()
logger = logging.getLogger(__name__)

# ============ App ============
app = FastAPI(
    title="HuiYuYuan API",
    version="4.0.0",
    description="HuiYuYuan Jewelry Trading Platform Backend",
)

# ---- CORS ----
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---- Request Logging (JSON in production) ----
app.add_middleware(RequestLoggingMiddleware)

# ---- Static uploads ----
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ============ Register Routers ============
from routers import (
    auth,
    products,
    shops,
    cart,
    users,
    orders,
    admin,
    favorites,
    reviews,
    upload,
    ai,
    notifications,
    ws,
)

app.include_router(auth.router)
app.include_router(products.router)
app.include_router(shops.router)
app.include_router(cart.router)
app.include_router(users.router)
app.include_router(orders.router)
app.include_router(admin.router)
app.include_router(favorites.router)
app.include_router(reviews.router)
app.include_router(upload.router)
app.include_router(ai.router)
app.include_router(notifications.router)
app.include_router(ws.router)


# ============ Health Check ============
@app.get("/")
async def root():
    return {
        "message": "HuiYuYuan API Running",
        "version": "4.0.0",
        "status": "healthy",
    }


@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "4.0.0",
        "env": APP_ENV,
        "db": DB_AVAILABLE,
        "redis": REDIS_AVAILABLE,
    }


# ============ Startup ============
init_store()
logger.info(
    f"HuiYuYuan API v4.0 started | env={APP_ENV} | db={DB_AVAILABLE} | redis={REDIS_AVAILABLE}"
)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
