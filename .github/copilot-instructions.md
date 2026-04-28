# GitHub Copilot 自定义指令 — 汇玉源项目

> 最后更新：2026-03-25

## 项目概述

**汇玉源（HuiYuYuan）** 是全栈跨平台珠宝智能交易平台 v4.0。

- **前端**：Flutter (Dart)，Riverpod 状态管理，跨平台（Android / iOS / Windows / Web）
- **后端**：Python FastAPI（模块化架构）+ PostgreSQL + Redis，部署于阿里云 ECS `47.112.98.191`
- **AI 服务**：阿里云 DashScope（千问 `qwen-plus` 文本对话，`qwen-vl-plus-latest` 图片识别）
- **设计系统**：Liquid Glass 毛玻璃风格，主色翡翠绿 `#2E8B57`，点缀金色 `#D4AF37`，背景深色 `#0D1B2A`

---

## 数据流与组件交互

```
用户操作
  → Screen（ConsumerWidget，通过 ref.watch/read 消费 Provider）
    → Provider（Riverpod AsyncNotifier/Notifier，管理业务状态）
      → Service（单例，封装 HTTP / AI / 存储逻辑）
        → ApiService → Nginx (/api/*) → FastAPI（modular routers）
        → AIDashScopeService → DashScope API / 离线回答（fallback）
        → StorageService → SharedPreferences + FlutterSecureStorage
```

**关键交互链路**：
- **认证**：`LoginScreen` → `ref.read(authProvider.notifier).loginAdmin()` → `StorageService.saveUser()` → `MainScreen` 按 `isAdminProvider` 切换角色
- **AI 对话**：`AIAssistantScreen` → `AIDashScopeService.chatStream()` → DashScope（流式SSE）→ 失败时返回离线预设答案
- **商品数据**：`BackendService.getProducts()` 请求后端 → 失败时 `product_data.dart` 静态数据降级
- **配置流**：`secrets.dart`(Key) → `app_config.dart`(常量) → `api_config.dart`(URL路由) → 各 Service 消费

**角色差异化**：`MainScreen._getPages(isAdmin)` — 管理员看 `AdminDashboard`，操作员看 `OperatorHome`

---

## 目录结构

### 前端 (`huiyuyuan_app/lib/`)

```
config/          # api_config.dart (路由+超时), app_config.dart (常量), secrets.dart (API Key，Git忽略)
data/            # 静态商品/店铺数据，后端不可用时本地降级
models/          # Dart 数据模型 (UserModel, ProductModel 等)
providers/       # Riverpod：auth_provider, app_settings_provider, inventory_provider
screens/         # 按功能分目录：admin/, operator/, chat/, trade/, shop/, order/, product/, profile/
services/        # 单例服务层 (factory 构造 + _instance 模式)
themes/          # colors.dart (JewelryColors), jewelry_theme.dart (亮/暗主题)
l10n/            # 自定义 i18n：app_strings.dart (Map<String,String>), l10n_provider.dart
widgets/         # 通用 UI 组件
```

### 后端 (`huiyuyuan_app/backend/`)

- **模块化 FastAPI**：`main.py`（约100行入口）→ `routers/`（13个路由模块）→ `services/`（业务逻辑）→ `database.py`
- **AI 服务**：`services/ai_service.py` — DashScope 文本对话 + 图片识别代理
- **可选依赖降级**：PostgreSQL / Redis / JWT 不可用时自动 fallback 到内存存储
- **Nginx 反代**：`/api/` → `127.0.0.1:8000`，前端静态文件 → `/var/www/huiyuyuan/`
- **环境变量**：参见 `backend/.env.example`（`DATABASE_URL`, `REDIS_URL`, `JWT_SECRET_KEY`, `DASHSCOPE_API_KEY` 等）

---

## 核心模式（必须遵循）

### 1. 服务层单例模式

```dart
class XxxService {
  static final XxxService _instance = XxxService._internal();
  factory XxxService() => _instance;
  XxxService._internal();
}
```

### 2. AI 服务（当前权威配置）

> ⚠️ 历史文档中的 DeepSeek / Gemini / OpenRouter 均属历史材料，当前使用 DashScope。

| 功能 | 提供方 | 模型 | 调用方式 |
|------|--------|------|----------|
| 文本对话 | 阿里云 DashScope | `qwen-plus` | Flutter 客户端直连 `AIDashScopeService` |
| 图片识别 | 阿里云 DashScope | `qwen-vl-plus-latest` | 后端代理 `/api/ai/analyze-image` |
| 兜底策略 | 本地离线 | — | DashScope 不可用时自动切换，无错误弹窗 |

### 3. API URL 平台感知

`api_config.dart` 中 `baseUrl` 根据 `kIsWeb` 返回空字符串（走 Nginx 同源代理）或服务器 IP，修改 API 配置时注意 Web/Native 差异。

### 4. Riverpod 状态管理

- 认证：`authProvider`（`AsyncNotifierProvider<AuthNotifier, UserModel?>`）
- 设置：`appSettingsProvider`（`NotifierProvider`）
- 多语言：`ref.watch(tProvider)('key')` 或 `ref.tr('key')`
- **不引入** Provider/Bloc 等其他状态管理方案

### 5. 多语言（自定义方案，非 ARB）

在 `l10n/app_strings.dart` 维护翻译。新增 UI 文字时须同时添加 zh_CN、en、zh_TW 三个语言键。

---

## 生产服务器信息

| 项目 | 值 |
|------|-----|
| 服务器 IP | `47.112.98.191` |
| 主域名 | `https://汇玉源.top`（`https://xn--lsws2cdzg.top`） |
| SSH 用户 | `root@47.112.98.191` |
| 后端源码 | `/srv/huiyuyuan/backend/` |
| systemd 服务 | `huiyuyuan-backend` |
| Web 静态文件 | `/var/www/huiyuyuan/` |
| Nginx 配置 | `/etc/nginx/conf.d/huiyuyuan.conf` |

---

## CI/CD（GitHub Actions）

工作流：`.github/workflows/ci.yml`，Flutter 3.32.0 + Java 17。

| 触发条件 | Jobs |
|---|---|
| push/PR → `main`/`dev` | flutter-build：pub get → analyze --fatal-infos → test --coverage → APK/AAB |
| push → `main` 且 build 通过 | deploy-backend：SCP → pip install → systemctl restart → 健康检查（5次重试） |
| push → `main` 且 build 通过 | deploy-web：flutter build web → SCP → nginx reload |

**必需 Secrets**：`SERVER_HOST`, `SERVER_USER`, `SERVER_SSH_KEY`, `DASHSCOPE_API_KEY`

---

## 常用命令

| 操作 | 命令 |
|---|---|
| 全量部署 | `scripts/deploy.ps1`（或 VSCode `Ctrl+Shift+B`） |
| 快速部署（跳过分析） | `scripts/deploy.ps1 -SkipAnalyze` |
| 仅部署前端 | `scripts/deploy.ps1 -Target web` |
| 仅部署后端 | `scripts/deploy.ps1 -Target backend` |
| 本地静态分析 | `cd huiyuyuan_app && dart analyze lib/` |
| 运行测试 | `cd huiyuyuan_app && flutter test` |
| 服务器日志 | `ssh root@47.112.98.191 "journalctl -u huiyuyuan-backend -n 50"` |
| 健康检查 | `curl https://xn--lsws2cdzg.top/api/health` |

---

## 编码规范

- **Dart**：遵循 `analysis_options.yaml`（flutter_lints + strict rules），`deprecated_member_use` 已 ignore
- **Python**：PEP8，async/await，Pydantic v2 模型
- **提交消息**：中文，格式 `类型: 描述`（如 `修复: AI对话流式输出断行问题`）
- **密钥管理**：API Key 放 `config/secrets.dart`（已 gitignore）；本地开发用 `.env.json`
- **设计风格**：Liquid Glass，使用 `JewelryColors` 和 `JewelryTheme` 常量

---

## 测试账号

| 角色 | 账号 | 密码 | 验证码 |
|---|---|---|---|
| 管理员 | 18925816362 | admin123 | 8888 |
| 操作员 | 1-10（任意） | op123456 | — |
| 普通用户 | 任意手机号 | — | 8888（开发万能码） |
