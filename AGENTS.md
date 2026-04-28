# AGENTS.md

本文件为 AI 编码助手在此仓库中工作时的权威参考指南。

> 最后更新：2026-04-08

---

## 汇玉源（HuiYuYuan）- 项目概述

**汇玉源** 是一个**全栈跨平台珠宝智能交易平台**，具备 AI 多模态能力，技术栈如下：

- **后端**：Python FastAPI + PostgreSQL + Redis（模块化架构）
- **前端**：Flutter（Dart），Riverpod 状态管理
- **AI 集成**：阿里云 DashScope（千问/Qwen 系列）— 文本对话 `qwen-plus`，图片识别 `qwen-vl-plus-latest`
- **设计系统**：Liquid Glass（玻璃态/Glassmorphism）+ 深色主题 + 翠绿品牌色 + 金色点缀

---

## 项目目录结构

```
D:/huiyuyuan_project/
├── docs/                               # 文档中心
│   ├── planning/                       # 项目规划（v4.0 总体计划、任务清单）
│   ├── guides/                         # 开发与部署指南
│   ├── design/                         # 设计系统文档
│   ├── agent_*_docs/                   # 多 Agent 协作文档
│   └── reference/                      # 历史归档（勿作为当前权威参考）
├── scripts/                            # 部署脚本
│   ├── deploy.ps1                      # PowerShell 一键部署到生产（权威发版入口）
│   ├── verify_public_ingress.ps1       # 公网入口验证脚本
│   └── migrate_server.ps1              # 服务器迁移脚本
├── .github/
│   └── workflows/ci.yml                # GitHub Actions CI/CD
├── .agent/
│   ├── skills/                         # Codex/Agent 技能包
│   └── workflows/                      # Agent 工作流模板
└── huiyuyuan_app/                    # 主应用目录
    ├── backend/                        # FastAPI 后端（v4.0 模块化）
    │   ├── main.py                     # 应用入口（约100行）
    │   ├── config.py                   # 从环境变量 / .env 读取配置
    │   ├── database.py                 # SQLAlchemy + PostgreSQL 连接管理
    │   ├── security.py                 # JWT + bcrypt 认证
    │   ├── requirements.txt            # Python 依赖
    │   ├── routers/                    # 模块化 API 路由
    │   ├── services/                   # 业务逻辑服务（含 ai_service.py）
    │   ├── schemas/                    # Pydantic 数据模型
    │   ├── tests/                      # pytest 安全 / 单元测试
    │   └── migrations/                 # Alembic 数据库迁移
    └── lib/                            # Flutter 前端
        ├── main.dart                   # App 入口
        ├── config/                     # 应用配置（app_config.dart / api_config.dart / secrets.dart）
        ├── models/                     # 数据模型
        ├── providers/                  # Riverpod 状态管理
        ├── screens/                    # UI 页面（23+ 屏幕）
        ├── services/                   # 前端服务层（含 ai_service.dart）
        ├── themes/                     # Liquid Glass 主题定义
        └── widgets/                    # 可复用组件
```

---

## 关键路径（绝对路径）

| 目录 | 本地路径 |
|------|----------|
| 项目根目录 | `D:/huiyuyuan_project/` |
| 后端源码 | `D:/huiyuyuan_project/huiyuyuan_app/backend/` |
| 前端源码 | `D:/huiyuyuan_project/huiyuyuan_app/lib/` |
| 文档中心 | `D:/huiyuyuan_project/docs/` |
| 部署脚本 | `D:/huiyuyuan_project/scripts/` |
| 后端测试 | `D:/huiyuyuan_project/huiyuyuan_app/backend/tests/` |
| 前端测试 | `D:/huiyuyuan_project/huiyuyuan_app/test/` |

---

## 架构模式

### 后端架构（v4.0 模块化）

- **整洁分层**：`main.py → routers → services → database`
- **依赖注入**：FastAPI 内置依赖注入
- **优雅降级**：生产环境需 PostgreSQL / Redis / JWT / bcrypt；开发环境可回退到内存存储 / UUID / 明文（仅限调试）
- **12-Factor 风格**：所有配置通过环境变量注入
- **安全优先**：JWT 认证、bcrypt 密码哈希、CORS 白名单

### 前端架构

- **状态管理**：Flutter Riverpod（函数式响应式编程）
- **服务层模式**：单例服务层管理 API / 外部集成
- **按功能组织**：屏幕按角色分类（admin、operator、order 等）
- **多角色支持**：客户（Customer）/ 操作员（Operator）/ 管理员（Admin）三种工作流
- **跨平台**：支持编译到 Android、iOS、Windows、Web、Linux、macOS

---

## AI 服务架构（当前权威）

> ⚠️ 项目内历史文档（archive/、旧规划）中仍保留 DeepSeek / Gemini / OpenRouter 记录，均属历史材料，不代表当前运行配置。

### 当前 AI 技术栈

| 功能 | 提供方 | 模型 | 调用方式 |
|------|--------|------|----------|
| 文本对话 | 阿里云 DashScope | `qwen-plus` | Flutter 客户端直连 `AIDashScopeService` |
| 图片识别 | 阿里云 DashScope | `qwen-vl-plus-latest` | 后端代理 `/api/ai/analyze-image` |
| 兜底策略 | 本地离线 | — | DashScope 不可用时自动切换，无错误弹窗 |

- **DashScope 接入点**：`https://dashscope.aliyuncs.com/compatible-mode/v1`
- **AI 服务入口**（前端）：`lib/services/ai_service.dart`
- **AI 服务入口**（后端）：`backend/services/ai_service.py`
- **图片识别兼容层**：`lib/services/gemini_image_service.dart`（类名保留，实现已切换为后端代理）

### AI Key 注入方式

**本地开发**（`.env.json` 注入）：
```json
{
  "DASHSCOPE_API_KEY": "sk-xxxxxxxx"
}
```

**APK / 生产构建**（`--dart-define` 注入）：
```bash
flutter build apk --release \
  --dart-define=DASHSCOPE_API_KEY=sk-your-dashscope-key
```

**后端**（服务器 `/srv/huiyuyuan/backend/.env`）：
```env
DASHSCOPE_API_KEY=sk-xxxxxxxx
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
DASHSCOPE_VISION_MODEL=qwen-vl-plus-latest
```

---

## 先决条件

### 后端

- Python 3.8+（生产推荐 3.11）
- PostgreSQL 15+（生产必需；开发可选）
- Redis 6+（开发可选，生产推荐）

### 前端

- Flutter SDK 3.27+
- Dart 3.6+
- Android Studio / VS Code + Flutter 插件

---

## 常用命令

### 安装依赖

**后端：**
```bash
cd D:/huiyuyuan_project/huiyuyuan_app/backend
pip install -r requirements.txt
cp .env.example .env
# 编辑 .env，填入你的配置
```

**前端：**
```bash
cd D:/huiyuyuan_project/huiyuyuan_app
flutter pub get
```

### 启动开发环境

**启动后端：**
```bash
cd D:/huiyuyuan_project/huiyuyuan_app/backend
python main.py
# 后端运行于 http://localhost:8000
# 健康检查：http://localhost:8000/api/health
```

**启动前端（多种方式）：**
```bash
cd D:/huiyuyuan_project/huiyuyuan_app

# 方式1：Windows 桌面端（推荐，启动最快，约30秒）
flutter run -d windows

# 方式2：Chrome 浏览器（无需 Windows 工具链）
flutter run -d chrome

# 方式3：Android 真机 / 模拟器
flutter run
```

### 运行测试

**后端（pytest）：**
```bash
cd D:/huiyuyuan_project/huiyuyuan_app/backend
python -m pytest
python -m pytest -v                        # 详细输出
python -m pytest tests/test_auth.py -v    # 指定测试文件
```

**前端（Flutter）：**
```bash
cd D:/huiyuyuan_project/huiyuyuan_app
flutter test
flutter test test/providers/auth_provider_test.dart   # 指定文件
flutter analyze                                        # 静态分析
```

### 构建命令

**构建 Android APK（Release）：**
```bash
cd D:/huiyuyuan_project/huiyuyuan_app
flutter clean && flutter pub get
flutter build apk --release \
  --dart-define=DASHSCOPE_API_KEY=sk-your-key
# 输出：build/app/outputs/flutter-apk/app-release.apk
```

**构建 Web（Release）：**
```bash
flutter build web --release
# 输出：build/web/（可直接部署）
```

**构建 Windows（Release）：**
```bash
flutter build windows --release
# 输出：build/windows/runner/Release/
```

### 部署到生产

**一键部署（Windows → 阿里云 ECS）：**
```powershell
# 在 PowerShell 中执行（以管理员身份）
cd D:\huiyuyuan_project

# 全量部署：后端 + Alembic + Nginx + 前端
.\scripts\deploy.ps1

# 仅部署后端（含 Alembic 迁移）
.\scripts\deploy.ps1 -Target backend

# 仅部署前端静态文件
.\scripts\deploy.ps1 -Target web

# 仅下发 Nginx 配置
.\scripts\deploy.ps1 -Target nginx

# 新环境初始化数据库
.\scripts\deploy.ps1 -Target db-init

# 本地预演（不实际执行）
.\scripts\deploy.ps1 -DryRun

# 跳过静态分析，快速部署
.\scripts\deploy.ps1 -SkipAnalyze

# 验证公网入口
.\scripts\verify_public_ingress.ps1
```

**数据库迁移（Alembic）：**
```bash
cd D:/huiyuyuan_project/huiyuyuan_app/backend
alembic upgrade head
```

---

## 生产服务器信息

| 项目 | 值 |
|------|-----|
| 云服务商 | 阿里云 ECS |
| 服务器 IP | `47.112.98.191` |
| 主域名 | `https://汇玉源.top` / `https://xn--lsws2cdzg.top` |
| SSH 用户 | `root@47.112.98.191` |
| 后端源码路径 | `/srv/huiyuyuan/backend/` |
| Python 虚拟环境 | `/srv/huiyuyuan/backend/venv/` |
| 生产环境变量 | `/srv/huiyuyuan/backend/.env` |
| 上传文件目录 | `/srv/huiyuyuan/backend/uploads/` |
| Web 静态文件 | `/var/www/huiyuyuan/` |
| Nginx 配置 | `/etc/nginx/conf.d/huiyuyuan.conf` |
| systemd 服务 | `huiyuyuan-backend` |
| 回滚快照目录 | `/opt/huiyuyuan/snapshots/` |

**服务器常用命令：**
```bash
# 后端健康检查（本机）
curl http://127.0.0.1:8000/api/health

# 公网 HTTPS 健康检查
curl -I https://xn--lsws2cdzg.top/api/health

# 后端服务状态
systemctl status huiyuyuan-backend

# 后端日志（最新50行）
journalctl -u huiyuyuan-backend -n 50 --no-pager

# Nginx 配置测试
nginx -t

# Nginx 日志
tail -n 50 /var/log/nginx/huiyuyuan_access.log
tail -n 50 /var/log/nginx/huiyuyuan_error.log
```

---

## 配置说明

### 后端环境变量

将 `.env.example` 复制为 `.env` 并填入：

| 变量 | 说明 | 是否必填 |
|------|------|----------|
| `DATABASE_URL` | PostgreSQL 连接字符串 | 是（生产） |
| `REDIS_URL` | Redis 连接 URL | 否（开发）/ 是（生产） |
| `JWT_SECRET_KEY` | JWT 签名密钥（64位随机字符串） | 是 |
| `ALLOWED_ORIGINS` | CORS 允许来源（逗号分隔） | 是 |
| `APP_ENV` | `production` 或 `development` | 是 |
| `DASHSCOPE_API_KEY` | 阿里云 DashScope API Key（`sk-` 开头） | AI 功能需要 |
| `DASHSCOPE_BASE_URL` | DashScope 接入点 URL | 否（有默认值） |
| `DASHSCOPE_VISION_MODEL` | 图片识别模型名 | 否（有默认值） |

生成 JWT 密钥：
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

### 前端配置

- 主配置入口：`D:/huiyuyuan_project/huiyuyuan_app/lib/config/app_config.dart`
- API 地址配置：`D:/huiyuyuan_project/huiyuyuan_app/lib/config/api_config.dart`
- 密钥注入：`D:/huiyuyuan_project/huiyuyuan_app/lib/config/secrets.dart`（通过 `--dart-define` 读取）
- 本地开发密钥：`D:/huiyuyuan_project/huiyuyuan_app/.env.json`（勿提交 Git）

> **注意**：`api_config.dart` 中的 `useMockApi` 控制前端是否对接真实后端。生产构建必须为 `false`。

---

## 默认测试账号

| 角色 | 手机号 / 账号 | 密码 | 验证码 |
|------|--------------|------|--------|
| **管理员** | `18925816362` | `admin123` | `8888` |
| **操作员** | `1`~`10`（任意编号） | `op123456` | — |
| **普通用户** | 任意手机号 | — | `8888`（开发模式万能码） |

> 生产环境应移除或禁用以上测试凭据。

---

## 文档索引

| 文档 | 路径 | 说明 |
|------|------|------|
| 项目主 README | `huiyuyuan_app/README.md` | 应用概述 |
| v4.0 总体规划 | `docs/planning/v4_master_plan.md` | 多 Agent 协同开发计划 |
| 任务清单 | `docs/planning/task.md` | 待办 / 进行中 / 已完成任务 |
| **快速启动指南** | `docs/guides/快速启动指南.md` | Windows / Chrome / APK 三种启动方式 |
| **生产部署指南** ⭐ | `docs/guides/deployment_guide_updated.md` | 当前权威部署文档 |
| **生产安全清单** ⭐ | `docs/guides/production_security_checklist_v2.md` | 当前权威安全基线 |
| **AI 服务指南** ⭐ | `docs/guides/ai_service_guide.md` | DashScope 配置与运行逻辑 |
| 真机测试指南 | `docs/guides/testing_guide.md` | 功能测试用例集 |
| 生产检查清单 | `docs/guides/production_checklist.md` | 上线前检查项 |
| 设计系统 | `docs/design/design_system.md` | Liquid Glass 设计规范 |

---

## 技术栈

### 后端

| 技术 | 版本 / 说明 |
|------|------------|
| FastAPI | 0.100+ |
| SQLAlchemy | 2.0+（AsyncIO 模式） |
| PostgreSQL | 15+（生产）/ 内存降级（开发） |
| Redis | 6+（SMS 限流 / 缓存） |
| Pydantic | v2 |
| Alembic | 数据库迁移 |
| pytest | 单元 / 集成测试 |
| bcrypt | 密码哈希 |
| httpx | HTTP 客户端（AI 代理） |

### 前端

| 技术 | 版本 / 说明 |
|------|------------|
| Flutter | 3.27+ |
| Dart | 3.6+ |
| flutter_riverpod | ^2.4.9 |
| dio | ^5.4.0（HTTP 客户端） |
| shared_preferences | 本地键值存储 |
| flutter_secure_storage | 加密 Token 存储 |
| cached_network_image | 图片缓存 |

---

## 项目状态

| 指标 | 当前值 |
|------|--------|
| 版本 | v4.0（模块化架构已完成） |
| 页面数量 | 23+ 屏幕 |
| 商品数量 | 130 款（15+ 材质分类） |
| 合作店铺 | 12 家 |
| AI 服务 | DashScope 千问（文本+图片识别）+ 离线兜底 |
| 测试就绪 APK | `huiyuyuan_app/汇玉源_v2.0.0_debug.apk`（148 MB） |
| 生产域名 | `https://汇玉源.top`（HTTPS 已启用） |
| 核心功能完成率 | ~99% |
| 上线就绪率 | ~88%（待支付接入 / 阿里云 SMS 资质 / Android 签名） |

## 最近修复（2026-04-08）

- **会话安全**：JWT 令牌已绑定 `sid` 会话，`logout`、`logout-others`、`refresh` 轮转、`reset-password`、`change-password` 都会让旧会话失效。
- **交易安全**：下单数量强制 `>= 1`，库存扣减改为条件更新；后台确认到账会校验支付状态，已取消/争议支付不能再误确认。
- **支付与设备**：设备记录不再使用 `eval` 反序列化；支付 DB 写路径显式 `commit()`，审计日志统一记到付款用户。
- **质量基线**：后端 `python -m pytest -q` 当前 `167 passed`；前端 `flutter test` 当前 `490 passed`；`dart analyze lib test tool --no-fatal-warnings` 为 `No issues found`。

### 待完成的关键事项（P0 / P1）

- [ ] 注册阿里云短信服务资质，配置真实 `ALIYUN_ACCESS_KEY_ID` / `SMS_TEMPLATE_CODE`
- [ ] 生成 Android 签名密钥（`huiyuyuan.jks`），配置 Release 签名
- [ ] 接入微信支付 / 支付宝真实支付链路
- [ ] 购物车 / 订单 / 收藏数据云端同步（替换本地 Mock）
- [ ] 隐私政策页面发布至可访问 HTTPS URL
- [ ] 接入 Firebase Crashlytics 监控
