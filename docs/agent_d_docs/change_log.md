# Agent D — DevOps 变更日志

> 按时间倒序记录所有 DevOps 基础设施变更

---
## [2026-02-27] Session 5 — Alembic 迁移 + Nginx 缓存 + 部署链路完善

### 新增
- **Alembic 数据库迁移框架**
  - `backend/alembic.ini`: 配置文件，日志级别/模板/格式
  - `backend/migrations/env.py`: 迁移环境，从 `config.py` 读取 DATABASE_URL，支持 online/offline 两种模式
  - `backend/migrations/script.py.mako`: 迁移文件模板
  - `backend/migrations/versions/20260227_0001_baseline_from_init_db_sql_v4_1.py`: 基线迁移 (stamp 现有 schema)
  - 使用方式: 已有数据库执行 `alembic stamp 0001`; 新增迁移用 `alembic revision -m "desc"`; 应用用 `alembic upgrade head`

### 修改
- **`backend/deploy.sh`**:
  - 快照范围扩大: 新增 `logging_config.py`、`alembic.ini`、`migrations/` 到快照列表
  - 部署流程新增步骤 2.5: `alembic upgrade head` (DB 不可用时自动跳过)
- **`scripts/deploy.ps1`**: `BACKEND_SYNC_ITEMS` 添加 `alembic.ini`、`migrations`
- **`.github/workflows/ci.yml`**: deploy-backend SCP source 添加 `alembic.ini`、`migrations/`
- **`backend/nginx_production.conf`**: 缓存策略增强
  - 新增 `/assets/` 和 `/canvaskit/` 专用 location (365d 缓存 + `access_log off`)
  - Flutter hash 文件获得 1 年缓存 (CDN/浏览器), 显著减少带宽

### 验证
- `alembic history` → 正确发现基线迁移 `<base> -> 0001 (head)`
- `alembic upgrade head --sql` → 离线模式正确生成 SQL
- 后端 78/78 passed, Flutter 25/25 screens passed

---

## [2026-02-27] Session 4 — 后端测试覆盖率 + 安全加固

### 新增测试 (4 个文件, +21 tests, 总计 78/78 passed)
- **`backend/tests/test_shops.py`** (5 tests): 店铺列表/详情/过滤/404
- **`backend/tests/test_notifications.py`** (6 tests): 设备注册/通知列表/标记已读/全部已读/401 鉴权
- **`backend/tests/test_admin.py`** (6 tests): 发货成功/订单不存在/状态错误/权限禁止/活动列表含订单/401
- **`backend/tests/test_upload.py`** (4 tests): 图片上传 jpg/png/非法格式拒绝/OSS STS 501

### 新增脚本
- **`backend/scripts/security_harden.sh`**: 服务器安全加固一键脚本
  - fail2ban (SSH 3 次 + Nginx rate-limit 保护)
  - unattended-upgrades (自动安全补丁)
  - SSH 加固 (禁用 root 密码登录, 10 分钟超时, MaxAuthTries 4)
  - sysctl 网络加固 (SYN cookies, ICMP redirect 禁用, martian 日志)
  - `--check-only` 审计模式 (只检查不修改)

### 修复
- **`backend/security.py`**: `datetime.utcnow()` (Python 3.12 DeprecationWarning) → `datetime.now(timezone.utc)`
  - 影响: `create_jwt_token()` + `create_refresh_token()` 共 4 处
  - 结果: 78 passed, 0 warnings (之前 224 warnings)

### 验证
- 后端 10 个测试文件, 78/78 全部通过, 0 warnings
- 覆盖率: 13 个 router 中 10 个有测试 (auth/cart/products/orders/health + shops/notifications/admin/upload + misc 中的 favorites/reviews/profile/address)
- 仅 AI (需外部 API) 和 WS (需 WebSocket client) 暂无测试

---

## [2025-07-15] Session 3 — 结构化日志 + Cron 安装器 + 测试修复

### 新增
- **`backend/logging_config.py`**: 生产 JSON / 开发彩色文本 双模式结构化日志
  - `JSONFormatter`: ts/level/logger/msg + extra fields (request_id, user_id, method, path, status_code, duration_ms, client_ip)
  - `DevFormatter`: 带颜色的 `HH:MM:SS [LEVEL] logger: msg` 格式
  - `RequestLoggingMiddleware`: HTTP 请求日志 (method/path/status/duration_ms/client_ip)，跳过 `/api/health`、`/favicon.ico`、`/robots.txt`
  - `setup_logging()`: 根据 `APP_ENV` 自动选择 JSON 或文本格式
- **`backend/scripts/install_cron.sh`**: Crontab 一键安装器
  - 自动安装: 健康监控 (每 5 分钟) + 数据库备份 (每日 02:30)
  - 支持 `--remove` 卸载
  - 自动创建 logrotate 配置 (14 天轮转)
  - 幂等设计: 重复执行安全，用 `# huiyuanyuan-managed` 标签管理条目

### 修改
- **`backend/main.py`**: `logging.basicConfig()` → `setup_logging()` + 添加 `RequestLoggingMiddleware` 中间件
- **`scripts/deploy.ps1`**: `BACKEND_SYNC_ITEMS` 添加 `logging_config.py`
- **`.github/workflows/ci.yml`**: deploy-backend SCP source 添加 `logging_config.py`

### 测试修复 (协助前端)
- **`checkout_screen.dart`**: 底栏 Row overflow 28px (320/375px 屏) → Flexible 包裹 + 按钮 padding 缩减 40→32 + SizedBox 间距
- **`order_list_screen.dart`** (Session 2): AppBar height 100→112 + `Future.delayed` → `Timer` + dispose cancel
- **`admin_dashboard.dart`** (Session 2): `_getMockActivities()` → `_buildActivityData()`
- 全部 25 个 screens 测试通过

### 验证
- `python -c "from main import app"` → app 正常加载，2 个 middleware (CORS + RequestLogging)
- 开发模式输出彩色日志格式，生产模式输出 JSON 格式

---

## [2025-07-14] Session 2 — 部署同步修复 + 文档体系建立

### 修复
- **deploy.sh 快照缺漏**: 增加 `schemas/`、`security.py`、`store.py`、`data/` 到快照列表，确保回滚覆盖所有模块
- **deploy.ps1 同步清单**: 添加 `pyproject.toml`、`tests/` 目录到 `BACKEND_SYNC_ITEMS`；移除不存在的 `middleware/`
- **deploy.ps1 快照命令**: 同步增加 `schemas`、`security.py`、`store.py`、`data` 到 SSH 快照命令
- **CI/CD 快照步骤**: `ci.yml` deploy-backend job 快照增加 `config.py`、`database.py`、`security.py`、`store.py`、`data`
- **CI/CD SCP 源列表**: `ci.yml` deploy-backend SCP source 添加 `pyproject.toml`、`tests/`；移除不存在的 `middleware/`

### 新增
- **docs/devops/ 文档文件夹**: 创建 `identity.md`、`change_log.md`、`roadmap.md` 三文件自描述体系

### 适配
- 确认后端已完成模块化拆分 (main.py 2246→108 行)，部署工具链同步适配新目录结构

---

## [2025-07-13] Session 1 — DevOps 基础设施全面建设

### 新建文件 (11 个)

| 文件 | 说明 |
|---|---|
| `backend/server_setup.sh` | 生产服务器初始化脚本 (PostgreSQL 15 + Redis + Python venv + systemd + UFW + logrotate) |
| `backend/nginx_production.conf` | 生产 Nginx 配置 (安全头 / WebSocket / 速率限制 / SSL-ready) |
| `backend/nginx_proxy_params.conf` | Nginx 代理参数片段 |
| `backend/scripts/db_backup.sh` | 自动备份 (pg_dump + gzip + 过期清理 + rsync + 钉钉/企微告警) |
| `backend/scripts/db_restore.sh` | 安全恢复 (恢复前自动快照 + 验证) |
| `backend/scripts/health_monitor.sh` | Cron 健康监控 (API / PG / Redis / Nginx / 磁盘 / 内存 + 自动重启) |
| `backend/scripts/ssl_setup.sh` | Let's Encrypt SSL 一键安装 + 自动续期 |
| `backend/scripts/server_diagnose.sh` | 一键全面服务器诊断 |
| `docs/devops/identity.md` | Agent D 身份与职责定义 |
| `docs/devops/change_log.md` | 本文件 |
| `docs/devops/roadmap.md` | DevOps 路线图 |

### 重大修改 (5 个)

| 文件 | 变更 |
|---|---|
| `backend/.env.example` | 新增 Redis 密码字段、AI Key、备份配置、监控 webhook；生产 CORS 禁用 `*` |
| `backend/deploy.sh` | v4 重写: 快照 → 依赖 → Nginx 配置同步 → 重启 → 健康检查 → 失败自动回滚 |
| `scripts/deploy.ps1` | v4 重写: 支持 `-Target all\|web\|backend\|nginx\|db-init`、`-Rollback`、整目录 rsync、自动快照/回滚 |
| `.github/workflows/ci.yml` | 新增 `backend-test` job (pytest + PG/Redis CI 容器) + `security-scan` job (凭据扫描 + 依赖审计) |
| `.vscode/tasks.json` | 新增 4 个任务: Nginx 更新、DB 初始化、全面诊断、手动备份 |

### 架构决策

| 决策 | 理由 |
|---|---|
| 使用 sync SQLAlchemy (非 asyncpg) | 后端已用 `create_engine` + `Session`，迁移到 async 成本高，当前流量无需 |
| CORS 生产白名单 | 禁止 `*`，仅允许 `https://xn--lsws2cdzg.top / https://www.xn--lsws2cdzg.top` |
| 快照保留 3 份 | 平衡磁盘占用和回滚需求 |
| Nginx 配置随代码同步 | 保证代码和反向代理配置版本一致 |
---
