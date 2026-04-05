"""
HuiYuYuan Backend API v4.0 - Modular Architecture Entry Point
Architecture: main.py -> routers/ -> services/ -> database/store
"""

import os
import logging
from datetime import datetime

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from starlette.middleware.trustedhost import TrustedHostMiddleware

from config import (
    ALLOWED_HOSTS,
    ALLOWED_ORIGINS,
    APP_ENV,
    IS_PRODUCTION,
    UPLOAD_DIR,
)
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

if ALLOWED_HOSTS != ["*"]:
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=ALLOWED_HOSTS)

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


@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
    response.headers.setdefault(
        "Permissions-Policy",
        "camera=(), microphone=(), geolocation=()",
    )

    if request.url.path.startswith("/api/auth/"):
        response.headers["Cache-Control"] = "no-store"
        response.headers["Pragma"] = "no-cache"

    if IS_PRODUCTION:
        response.headers.setdefault(
            "Strict-Transport-Security",
            "max-age=31536000; includeSubDomains",
        )

    return response

# ---- Static uploads ----
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ============ Register Routers ============
from routers import (
    auth,
    app_meta,
    products,
    shops,
    inventory,
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
    payments,
)

app.include_router(auth.router)
app.include_router(app_meta.router)
app.include_router(products.router)
app.include_router(shops.router)
app.include_router(inventory.router)
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
app.include_router(payments.router)


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
if not IS_PRODUCTION:
    init_store()
logger.info(
    f"HuiYuYuan API v4.0 started | env={APP_ENV} | db={DB_AVAILABLE} | redis={REDIS_AVAILABLE}"
)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
