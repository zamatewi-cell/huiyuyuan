"""Public app metadata endpoints."""

from fastapi import APIRouter, Query

from config import (
    APP_ANDROID_DOWNLOAD_URL,
    APP_FORCE_UPDATE,
    APP_IOS_DOWNLOAD_URL,
    APP_LATEST_BUILD_NUMBER,
    APP_LATEST_VERSION,
    APP_MIN_SUPPORTED_BUILD_NUMBER,
    APP_RELEASE_NOTES,
    APP_RELEASED_AT,
    APP_WEB_DOWNLOAD_URL,
)

router = APIRouter(prefix="/api/app", tags=["应用信息"])


@router.get("/version")
async def get_app_version(
    platform: str = Query(default="android", pattern="^(android|ios|web)$"),
):
    download_url = APP_ANDROID_DOWNLOAD_URL
    if platform == "ios":
        download_url = APP_IOS_DOWNLOAD_URL
    elif platform == "web":
        download_url = APP_WEB_DOWNLOAD_URL

    return {
        "success": True,
        "platform": platform,
        "latest_version": APP_LATEST_VERSION,
        "latest_build_number": APP_LATEST_BUILD_NUMBER,
        "min_supported_build_number": APP_MIN_SUPPORTED_BUILD_NUMBER,
        "force_update": APP_FORCE_UPDATE,
        "download_url": download_url,
        "release_notes": APP_RELEASE_NOTES,
        "published_at": APP_RELEASED_AT,
    }
