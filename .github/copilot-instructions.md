# GitHub Copilot Custom Instructions - HuiYuYuan Project

> Last updated: 2026-03-25

## Project Overview

**HuiYuYuan** is a full-stack cross-platform jewelry AI trading platform:
- **Frontend**: Flutter/Dart, Riverpod, Android/iOS/Windows/Web
- **Backend**: Python FastAPI (modular) + PostgreSQL + Redis on Alibaba Cloud ECS 47.112.98.191
- **AI**: Alibaba Cloud DashScope (qwen-plus text, qwen-vl-plus-latest vision)
- **Design**: Liquid Glass glassmorphism, jade green #2E8B57, gold #D4AF37, dark #0D1B2A

## Architecture

```
Screen (ConsumerWidget)
  -> Provider (Riverpod AsyncNotifier)
    -> Service (singleton factory)
      -> ApiService -> Nginx /api/* -> FastAPI routers
      -> AIDashScopeService -> DashScope API (fallback: offline response)
      -> StorageService -> SharedPreferences + FlutterSecureStorage
```

## Frontend Key Paths (huiyuanyuan_app/lib/)

```
config/      # api_config.dart, app_config.dart, secrets.dart (gitignored)
data/        # product_data.dart, shop_data.dart (local fallback)
models/      # UserModel, ProductModel, OrderModel, CartItemModel, etc.
providers/   # auth_provider, app_settings_provider, inventory_provider
screens/     # admin/, operator/, chat/, trade/, shop/, order/, product/, profile/
services/    # ApiService, AIDashScopeService, ReviewService, PushService, etc.
themes/      # colors.dart (JewelryColors), jewelry_theme.dart
l10n/        # app_strings.dart, l10n_provider.dart
```

## Backend Key Paths (huiyuanyuan_app/backend/)

```
main.py           # FastAPI entry (~100 lines)
config.py         # Pydantic Settings from env vars
database.py       # SQLAlchemy engine + SessionLocal + Redis client
security.py       # JWT create/validate, bcrypt, require_user
store.py          # In-memory fallback storage + init_store()
routers/          # 13 routers: auth, products, orders, cart, users, admin, ...
services/         # ai_service.py, sms_service.py, oss_service.py
schemas/          # Pydantic v2 request/response models
tests/            # pytest: 78 tests all passing
```

## Core Patterns

### Service Singleton
```dart
class XxxService {
  static final XxxService _instance = XxxService._internal();
  factory XxxService() => _instance;
  XxxService._internal();
}
```

### AI Service (Current)
| Function | Provider | Model |
|---|---|---|
| Text Chat | DashScope | qwen-plus |
| Image Analysis | DashScope via backend proxy | qwen-vl-plus-latest |
| Fallback | Local offline presets | - |

> Note: Historical docs may mention DeepSeek/Gemini/OpenRouter - those are obsolete.

### State Management
- Auth: `authProvider` (AsyncNotifierProvider)
- Settings: `appSettingsProvider` (NotifierProvider)
- i18n: `ref.watch(tProvider)('key')` or `ref.tr('key')`
- Do NOT introduce other state management solutions

### i18n
Custom solution (not ARB). Add translations in `l10n/app_strings.dart`:
`Map<AppLanguage, Map<String, String>>` - always add zh_CN, en, zh_TW keys together.

## Production Server

| Item | Value |
|---|---|
| IP | 47.112.98.191 |
| Domain | https://xn--lsws2cdzg.top |
| SSH | root@47.112.98.191 |
| Backend path | /srv/huiyuanyuan/backend/ |
| Env file | /srv/huiyuanyuan/.env |
| systemd | huiyuanyuan-backend |
| Frontend | /var/www/huiyuanyuan/ |
| Nginx conf | /etc/nginx/conf.d/huiyuanyuan.conf |
| Health check | curl https://xn--lsws2cdzg.top/api/health |

## CI/CD (GitHub Actions)

File: `.github/workflows/ci.yml`, Flutter 3.32.0 + Java 17

| Trigger | Job | Action |
|---|---|---|
| push/PR to main/dev | flutter-build | pub get, analyze --fatal-infos, test --coverage |
| push to main (passing) | deploy-backend | SCP, pip install, systemctl restart, health check |
| push to main (passing) | deploy-web | flutter build web, SCP, nginx reload |

Required secrets: `SERVER_HOST`, `SERVER_USER`, `SERVER_SSH_KEY`, `DASHSCOPE_API_KEY`

## Deploy Commands

| Action | Command |
|---|---|
| Full deploy | `scripts/deploy.ps1` or VSCode Ctrl+Shift+B |
| Frontend only | `scripts/deploy.ps1 -Target web` |
| Backend only | `scripts/deploy.ps1 -Target backend` |
| Skip analyze | `scripts/deploy.ps1 -SkipAnalyze` |
| Dry run | `scripts/deploy.ps1 -DryRun` |
| View logs | `ssh root@47.112.98.191 "journalctl -u huiyuanyuan-backend -n 50"` |

## Coding Standards

- **Dart**: follow `analysis_options.yaml`, no deprecated_member_use
- **Python**: PEP8, Pydantic v2 models, async/await
- **Colors**: use `JewelryColors` constants, never hardcode hex
- **API Keys**: in `config/secrets.dart` (gitignored); local dev uses `.env.json`

## Test Accounts

| Role | Account | Password | SMS Code |
|---|---|---|---|
| Admin | 18937766669 | admin123 | 8888 |
| Operator | 1-10 (any) | op123456 | - |
| Customer | any phone | - | 8888 (dev universal) |
