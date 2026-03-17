# -*- coding: utf-8 -*-
"""
Structured JSON logging for HuiYuYuan backend.

- Development: colored text output (easy to read)
- Production/Testing: JSON format (grep / jq / log system friendly)

Usage in main.py:
    from logging_config import setup_logging, RequestLoggingMiddleware
    setup_logging()
    app.add_middleware(RequestLoggingMiddleware)
"""

import json
import logging
import sys
import time
from datetime import datetime, timezone
from typing import Optional

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from config import APP_ENV, DEBUG


class JSONFormatter(logging.Formatter):
    """Production JSON log formatter."""

    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
        }

        if record.exc_info and record.exc_info[0] is not None:
            log_entry["exception"] = self.formatException(record.exc_info)

        # Attach extra fields (request_id, user_id, etc.)
        for key in ("request_id", "user_id", "method", "path",
                     "status_code", "duration_ms", "client_ip"):
            val = getattr(record, key, None)
            if val is not None:
                log_entry[key] = val

        return json.dumps(log_entry, ensure_ascii=False)


class DevFormatter(logging.Formatter):
    """Development colored text formatter."""

    COLORS = {
        "DEBUG": "\033[36m",     # cyan
        "INFO": "\033[32m",      # green
        "WARNING": "\033[33m",   # yellow
        "ERROR": "\033[31m",     # red
        "CRITICAL": "\033[41m",  # red bg
    }
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        color = self.COLORS.get(record.levelname, "")
        ts = datetime.now().strftime("%H:%M:%S")
        msg = record.getMessage()
        base = f"{color}{ts} [{record.levelname:>7}]{self.RESET} {record.name}: {msg}"
        if record.exc_info and record.exc_info[0] is not None:
            base += "\n" + self.formatException(record.exc_info)
        return base


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    HTTP request/response structured logging middleware.

    Logs: method, path, status, duration_ms, client_ip
    Skips: /api/health, /favicon.ico (avoids cron log spam)
    """

    SKIP_PATHS = {"/api/health", "/favicon.ico", "/robots.txt"}

    def __init__(self, app, logger_name: str = "http"):
        super().__init__(app)
        self.logger = logging.getLogger(logger_name)

    async def dispatch(self, request: Request, call_next) -> Response:
        if request.url.path in self.SKIP_PATHS:
            return await call_next(request)

        start = time.monotonic()
        client_ip = request.client.host if request.client else "-"

        try:
            response = await call_next(request)
        except Exception:
            duration = round((time.monotonic() - start) * 1000, 1)
            self.logger.error(
                f"{request.method} {request.url.path} 500 {duration}ms",
                extra={
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": 500,
                    "duration_ms": duration,
                    "client_ip": client_ip,
                },
            )
            raise

        duration = round((time.monotonic() - start) * 1000, 1)
        log_level = logging.WARNING if response.status_code >= 400 else logging.INFO
        self.logger.log(
            log_level,
            f"{request.method} {request.url.path} {response.status_code} {duration}ms",
            extra={
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration,
                "client_ip": client_ip,
            },
        )
        return response


def setup_logging(level: Optional[int] = None):
    """
    Initialize application logging.

    - production / testing -> JSON format
    - development -> colored text
    """
    if level is None:
        level = logging.DEBUG if DEBUG else logging.INFO

    root = logging.getLogger()
    root.setLevel(level)

    # Clear existing handlers (avoid duplicate config)
    root.handlers.clear()

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(level)

    if APP_ENV in ("production", "testing"):
        handler.setFormatter(JSONFormatter())
    else:
        handler.setFormatter(DevFormatter())

    root.addHandler(handler)

    # Quiet noisy third-party loggers
    for noisy in ("uvicorn.access", "sqlalchemy.engine", "httpx", "httpcore"):
        logging.getLogger(noisy).setLevel(logging.WARNING)

    logging.getLogger(__name__).info(
        f"Logging initialized: env={APP_ENV}, level={logging.getLevelName(level)}, "
        f"format={'JSON' if APP_ENV in ('production', 'testing') else 'text'}"
    )
