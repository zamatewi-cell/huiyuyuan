# 汇玉源珠宝智能交易平台 v4.0

<p align="center">
  <strong>💎 Liquid Glass 设计风格 | 阿里云 DashScope AI 驱动 | 全栈跨平台</strong>
</p>
<p align="center">
  Flutter 3.27+ · FastAPI · PostgreSQL · Redis · DashScope 千问
</p>

---

## 🎯 项目概述

**汇玉源（HuiYuYuan）** 是面向珠宝行业的 **全栈跨平台智能交易平台**，为珠宝商家和消费者提供智能化的商品浏览、AI 鉴赏对话、订单管理和后台运营体验。

### 核心功能

| 功能 | 描述 | 状态 |
|------|------|------|
| 🛒 **智能商城** | 130 款珠宝商品，分类筛选/搜索/排序/详情 | ✅ 完成 |
| 🤖 **AI 助手「玉小助」** | DashScope 千问流式对话 + 离线兜底 | ✅ 完成 |
| 📸 **AI 图片识别** | DashScope qwen-vl 珠宝图片鉴定（后端代理） | ✅ 完成 |
| 📦 **订单管理** | 创建/支付/发货/物流/取消/退款全生命周期 | ✅ 完成 |
| 🛍️ **购物车** | 增删改查/数量调整/结算下单 | ✅ 完成 |
| 💳 **收款管理** | API 驱动的多渠道收款账户管理 | ✅ 完成 |
| 📊 **管理员仪表盘** | 统计总览/商品管理/操作员管理/库存管理 | ✅ 完成 |
| 👔 **操作员工作台** | 店铺管理/AI 话术生成/客户联系 | ✅ 完成 |
| 🔔 **通知中心** | 全部/订单/活动/系统 Tab、未读标记 | ✅ 完成 |
| 🌍 **多语言** | 简体中文/繁体中文/English | ✅ 完成 |
| 🌙 **深色模式** | 全页面暗色/亮色主题适配 | ✅ 完成 |
| 🥽 **AR 试戴** | 虚拟珠宝试戴体验 | 🔄 原型 |

### 三种角色

| 角色 | 入口 | 能力 |
|------|------|------|
| **管理员** | 管理员 Tab 登录 | 统计仪表盘、商品 CRUD、操作员管理、库存管理 |
| **操作员** | 操作员 Tab 登录 | 商家联系、AI 话术、店铺雷达、业绩统计 |
| **消费者** | 手机号+验证码登录 | 商品浏览、购物车、下单、AI 对话、收藏、地址管理 |

---

## 🚀 快速开始

### 1. 环境要求

- Flutter SDK ≥ 3.27（Dart ≥ 3.6）
- Android Studio / VS Code
- Android SDK 34+（兼容 Android 5.0+）
- Python 3.11+（后端）
- PostgreSQL 15+、Redis 6+（后端数据库）

### 2. 安装依赖

```bash
cd huiyuyuan_app/
flutter pub get
```

### 3. 本地运行

```bash
# 浏览器中预览（推荐快速体验）
flutter run -d edge
flutter run -d chrome

# Android 设备/模拟器
flutter run

# Windows 桌面（需 Visual Studio C++ 工具链）
flutter run -d windows
```

### 4. 启动本地后端（可选）

```bash
cd huiyuyuan_app/backend/
pip install -r requirements.txt
python -m uvicorn main:app --reload --port 8000
```

### 5. 测试账号

| 角色 | 账号 | 密码 | 验证码 |
|------|------|------|--------|
| **管理员** | 18925816362 | admin123 | 8888 |
| **操作员** | 1-10（任意数字） | op123456 | — |
| **消费者** | 任意手机号 | — | 8888（万能验证码） |

---

## ✅ 2026-04-08 稳定性修复

- **认证与会话**：`logout`、`logout-others`、`refresh` 轮转、`reset-password`、`change-password` 已统一纳入会话失效链路，旧 token 不能继续使用。
- **订单与支付**：下单数量增加下界校验，库存扣减改为条件更新；支付写路径统一显式落库，后台确认到账会拒绝已取消或争议中的支付单。
- **安全与设备**：设备记录不再使用 `eval` 解析；登录与设备管理链路对 JWT / 会话校验保持一致。
- **质量回归**：后端 `python -m pytest -q` 当前 `167 passed`；前端 `flutter test` 当前 `490 passed`；`dart analyze lib test tool --no-fatal-warnings` 为 `No issues found`。

---

## 🎨 设计系统

本项目采用 **Liquid Glass**（流体玻璃）设计风格，营造高端珠宝品牌的视觉体验。

| 要素 | 值 | 说明 |
|------|-----|------|
| 深色背景 | `#0D1B2A` | 深邃星空蓝 |
| 翡翠绿主色 | `#2E8B57` | 品牌核心色 |
| 金色点缀 | `#D4AF37` | 高光装饰色 |
| 毛玻璃效果 | `BackdropFilter` + `ClipRRect` | 半透明磨砂质感 |
| 动画 | 呼吸感指示器/打字机光标/渐入渐出 | 微交互提升体验 |

全页面适配位置：底部导航栏、AI 对话气泡、商品卡片、登录页面、管理后台卡片等。

---

## 🏗️ 项目架构

### 数据流

```
用户操作
  → Screen（ConsumerWidget，ref.watch/read 消费 Provider）
    → Provider（Riverpod AsyncNotifier/Notifier）
      → Service（单例 factory 模式）
        → ApiService → Nginx /api/* → FastAPI 后端
        → AIDashScopeService → DashScope API（离线 fallback）
        → StorageService → SharedPreferences + SecureStorage
```

### 目录结构

```
huiyuyuan_project/
├── CLAUDE.md                      # ★ 项目权威指南
├── docs/                          # 📚 文档中心（49 个 .md 文件）
│   ├── planning/                  #   规划：任务列表、v4 总规划
│   ├── guides/                    #   指南：部署/AI/测试/支付
│   ├── agent_[a-e]_docs/          #   5 个 Agent 工作文档
│   └── reference/                 #   归档：历史版本参考
├── scripts/                       # 🛠️ 部署脚本
│   └── deploy.ps1                 #   一键部署（支持 -Target/-SkipAnalyze）
└── huiyuyuan_app/               # 📱 Flutter + 后端
    ├── lib/                       # 前端源码（121 个 Dart 文件，42,000+ 行）
    │   ├── app/                   #   应用壳/路由/启动页/错误页
    │   ├── config/                #   配置（api_config/app_config/secrets）
    │   ├── data/                  #   静态数据（商品/店铺/seed）
    │   ├── l10n/                  #   国际化（简中/繁中/英文）
    │   ├── models/                #   数据模型（11 个）
    │   ├── providers/             #   Riverpod 状态管理（5 个）
    │   ├── repositories/          #   Repository 层（5 个）
    │   ├── screens/               #   页面（24 个 Screen）
    │   ├── services/              #   服务层（21 个单例）
    │   ├── themes/                #   主题（JewelryColors + JewelryTheme）
    │   └── widgets/               #   通用组件（8+ 个）
    ├── test/                      # 前端测试（38 个文件，8,600+ 行）
    └── backend/                   # Python 后端（59 个文件，9,100+ 行）
        ├── main.py                #   FastAPI 入口（~107 行）
        ├── routers/               #   13 个 API 路由模块
        ├── schemas/               #   8 个 Pydantic 模型
        ├── services/              #   2 个业务服务
        └── tests/                 #   后端测试
```

---

## 🤖 AI 服务

### 当前配置（v4.0）

> ⚠️ 历史版本文档中的 DeepSeek / Gemini / OpenRouter 均已替换为 DashScope。

| 功能 | 提供方 | 模型 | 调用方式 |
|------|--------|------|----------|
| 文本对话 | 阿里云 DashScope | `qwen-plus` | Flutter 客户端直连（流式 SSE） |
| 图片识别 | 阿里云 DashScope | `qwen-vl-plus-latest` | 后端代理 `/api/ai/analyze-image` |
| 兜底策略 | 本地离线 | — | API 不可用时自动切换，无错误弹窗 |

### AI 能力矩阵

| 能力 | 说明 |
|------|------|
| 智能客服「玉小助」 | 珠宝行业专家，回答鉴赏/保养/选购问题 |
| 商务话术生成 | 自动生成商家邀约/跟进/报价话术 |
| 产品描述生成 | AI 优化商品文案和描述 |
| 看图鉴宝 | 上传珠宝图片，识别材质/工艺/估价 |
| 聊天分析 | 意图识别 + 情感分析 |
| 敏感词过滤 | 符合《广告法》合规要求 |

### 配置方式

```bash
# 方式一：.env.json（本地开发，gitignore）
echo '{"DASHSCOPE_API_KEY":"sk-xxx","API_BASE_URL":"http://127.0.0.1:8000"}' > huiyuyuan_app/.env.json

# 方式二：编译期注入（CI/CD）
flutter run --dart-define-from-file=.env.json
```

---

## 🔧 生产环境

### 服务器信息

| 项目 | 值 |
|------|-----|
| 服务器 | 阿里云 ECS `47.112.98.191` |
| 域名 | `https://汇玉源.top`（`https://xn--lsws2cdzg.top`） |
| 后端源码 | `/srv/huiyuyuan/backend/` |
| systemd 服务 | `huiyuyuan-backend` |
| Web 静态文件 | `/var/www/huiyuyuan/` |
| Nginx 反代 | `/api/` → `127.0.0.1:8000` |

### 部署命令

```bash
# 全量部署（分析 → 构建 → 后端 → 前端 → 健康检查）
scripts/deploy.ps1

# 快速部署（跳过分析）
scripts/deploy.ps1 -SkipAnalyze

# 仅部署前端 / 后端
scripts/deploy.ps1 -Target web
scripts/deploy.ps1 -Target backend

# 健康检查
curl https://xn--lsws2cdzg.top/api/health
```

---

## 📦 构建与发布

```bash
# Android APK
flutter build apk --debug            # Debug 版
flutter build apk --release           # Release 版（需签名配置）

# Web 版本
flutter build web --no-tree-shake-icons --release

# Windows
flutter build windows --release       # 需 Visual Studio C++

# 静态分析
cd huiyuyuan_app && dart analyze lib test tool --no-fatal-warnings

# 运行测试
flutter test                          # 当前 490/490 全部通过
```

---

## 📋 更新日志

### v4.0.1 (2026-04-08)

**安全加固 + 回归收口**

- 🔒 JWT 新增 `sid` 会话标识，登出、退出其他设备、重置密码、修改密码、刷新轮转都会使旧会话失效
- 🛒 下单数量校验与库存扣减逻辑收紧，修复负数数量和并发超卖风险
- 💳 支付 DB 写路径统一显式 `commit()`，后台确认到账拒绝取消/争议支付，审计日志归属付款用户
- 🧪 后端回归提升至 **167 passed**，前端全量测试提升至 **490 / 490**，静态分析为 **No issues found**

### v4.0.0 (2026-03-25)

**架构重构 + 模块化升级**

- 🏗️ 后端从单文件 `main.py`（2246行）拆分为 13 个路由 + 8 个 Schema + 2 个 Service
- 🏗️ 前端 `main.dart`（617行→50行）、`login_screen.dart`（1037行→320行）完成文件级拆分
- 🏗️ `ai_service.dart`（791行→223行）完成四轮服务拆分
- 🗄️ 后端 PostgreSQL 持久化（10/13 路由已 DB-Aware），Redis 缓存 + 限流
- 🔒 JWT 认证 + bcrypt 密码 + CORS + WebSocket 通知 + Pydantic v2
- 🧪 严格类型（`strict-casts` + `strict-raw-types`），262 处修复
- 📊 Flutter 测试从 397 提升至 **449 / 449 全部通过**
- ☁️ AI 服务从 DeepSeek/Gemini/OpenRouter 统一迁移至 **阿里云 DashScope**
- 🚀 CI/CD 增强：GitHub Actions 自动构建 + 后端/Web 自动部署
- 📝 文档体系：5 个 Agent 工作文档 + 49 个 .md 指南

### v3.0.3 (2026-03-18)

- ✨ 收款账户页改为 API 驱动
- 🧹 清理旧的本地支付账户存储逻辑

### v3.0.0 (2026-02-03)

- ✨ Liquid Glass 设计升级
- 🤖 OpenRouter 免费多模态 AI
- 🎨 毛玻璃导航栏、玻璃态对话气泡

### v2.0.0 (2026-01-31)

- 后端对接（FastAPI）
- AI 模型集成
- 视觉升级

---

## 📊 项目指标

| 指标 | 数值 |
|------|------|
| 前端 Dart 文件 | 121 个（42,000+ 行） |
| 后端 Python 文件 | 59 个（9,100+ 行） |
| 测试文件 | 38 个（8,600+ 行） |
| 屏幕/页面 | 24 个 |
| 商品数量 | 130 款（15+ 材质分类） |
| 合作店铺 | 12 家 |
| HTTP 端点 | 55 个 + 1 WebSocket |
| AI 模型 | DashScope 千问（文本+视觉） |
| 代码质量 | `dart analyze lib test tool --no-fatal-warnings` 无问题 |
| 前端测试通过率 | 490 / 490（100%） |
| 后端回归 | 167 passed |
| 生产域名 | `https://汇玉源.top` |
| 核心功能完成率 | ~88% |

---

## 📖 文档导航

| 文档 | 说明 | 路径 |
|------|------|------|
| **CLAUDE.md** | 项目权威指南（最新架构/配置/命令） | [`../CLAUDE.md`](../CLAUDE.md) |
| **AGENTS.md** | Codex/Agent 协作权威指南 | [`../AGENTS.md`](../AGENTS.md) |
| 任务清单 | 待办/进行中/已完成 | [`../docs/planning/task.md`](../docs/planning/task.md) |
| v4.0 总规划 | 多 Agent 协同开发规划 | [`../docs/planning/v4_master_plan.md`](../docs/planning/v4_master_plan.md) |
| 部署指南 | 一键部署 + CI/CD + 运维 | [`../docs/guides/deployment_guide_updated.md`](../docs/guides/deployment_guide_updated.md) |
| 生产安全清单 | 当前安全基线与服务器核查项 | [`../docs/guides/production_security_checklist_v2.md`](../docs/guides/production_security_checklist_v2.md) |
| AI 服务指南 | DashScope 接入说明 | [`../docs/guides/ai_service_guide.md`](../docs/guides/ai_service_guide.md) |
| 设计系统 | Liquid Glass 规范 | [`../docs/design/design_system.md`](../docs/design/design_system.md) |
| 快速启动 | 本地环境搭建 | [`../docs/guides/快速启动指南.md`](../docs/guides/快速启动指南.md) |
| 代码审查报告 | 质量审查与路线图 | [`../docs/huiyuyuan_code_review_and_roadmap.md`](../docs/huiyuyuan_code_review_and_roadmap.md) |

---

*文档版本: 4.0.1 | 最后更新: 2026-04-08*
