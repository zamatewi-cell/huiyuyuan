# 汇玉源珠宝智能交易平台 - 任务清单

> 📍 **唯一活跃任务文档** | 最后更新: 2026-05-01

---

## ✅ 已完成任务

### 📌 2026-05-01 Cursor 续开发交接与产品主线复盘

- [x] 新增 `docs/cursor_development_handoff_20260501.md`，汇总 Cursor 续开发所需的项目 Review、页面、操作流、接口清单、MCP/Skills 建议和产品路线
- [x] 梳理当前后端 API：Auth、商品、店铺、购物车、收藏、用户、订单、支付、库存、管理后台、AI、上传、通知、评价
- [x] 梳理当前 Flutter 页面和服务层：登录、商品、购物车、结算、支付、订单、个人中心、AI、店铺、AR、管理后台、Provider、Repository、Service
- [x] 明确真实微信/支付宝支付暂缓，近期保留人工支付、上传凭证、后台确认到账闭环
- [x] 补充产品方向判断：近期重点从“普通电商功能堆叠”转向“珠宝鉴赏、信任凭证、AI 导购、一物一档”
- [x] 更新 `docs/README.md`，把 Cursor 交接文档加入当前必读

### 🚀 2026-04-28 UI 重构与生产同步

- [x] Flutter Web 完成 Liquid Glass UI 重构并部署到生产
- [x] 主要用户端页面完成新版视觉：登录、商品列表、商品详情、购物车、结算、支付、订单、物流、评价、个人中心、收藏、浏览记录、地址、通知、AI 助手、店铺详情、店铺雷达、AR 试戴
- [x] 管理端和操作员端关键页面完成新版视觉：管理员仪表盘、订单工作台、库存、支付对账、操作员工作台
- [x] Web 端关闭更新弹窗，移动端保留更新下载/安装能力
- [x] 后端部署订单/支付/权限增强，Alembic head 升级到 `20260415_0009_operator_permissions`
- [x] Nginx 与 Web 静态资源完成生产同步，`/api/health` 验证通过
- [x] 修复 `scripts/deploy.ps1` 在 Windows/SSH/Flutter 输出捕获下的发版稳定性问题
- [x] 清理根目录临时 SQL、排查 shell、Figma cookie、release_artifacts 等仓库污染文件
- [x] 新增 `docs/project_status_20260428.md` 作为本轮上线后的状态总览

### 📌 2026-04-28 当前仍需跟进

- [ ] GitHub 账号恢复后推送 `codex/ui-redesign-release-check` 并创建 PR
- [ ] 给临时脚本、release artifacts、Figma cookie 等补充 `.gitignore` 防误提交规则
- [ ] 内部试运行 3-5 天，重点验证下单、支付凭证、管理员确认到账、发货、评价
- [ ] 真实微信/支付宝支付改为暂缓，待产品主线和人工支付闭环稳定后再启动
- [ ] 补齐阿里云 SMS 正式资质、Android Release 签名和线上告警

### 🎯 2026-05-01 产品核心重构（全部完成）

> 详细记录见 `docs/planning/product_core_refactor_plan_20260501.md`

**第一里程碑：P0 工程地基**
- [x] i18n 引擎重构：去 MaterialApp key 作弊 + Riverpod 化 + 商品模型 @Deprecated + lint 工具
- [x] orders.py 乱码全量修复（22处）+ 删除 main_v3_backup.py + 新增 test_no_mojibake.py
- [x] 测试支付保护：生产环境守卫 + payment_url None + 5 条 pytest 用例
- [x] 根目录 229 张截图归档至 docs/screenshots/ + .cursorindexignore
- [x] `.cursor/rules/` 落地三个规则文件（i18n / Liquid Glass / secrets）

**第二里程碑：商品骨架升级**
- [x] ProductModel 新增 8 个鉴定/工艺/规格字段 + Alembic 迁移 + 后端 schema 同步
- [x] 商品详情"一物一档"骨架（鉴定说明/工艺亮点/克重/尺寸，优雅降级）
- [x] 头部 30 个商品补完整三语内容
- [x] AI 上下文精简：基于 appraisal_note/craft_highlights 的摘要 prompt

**第三里程碑：首页 + AI 顾问**
- [x] HomeCurationScreen（珠宝鉴赏策展首页）替换客户 Tab 0
- [x] 商品详情底部 AI 咨询按钮 + 结算页 AI 悬浮气泡 + AIAssistantScreen 深链
- [x] 操作员"AI 起草回复"功能 + AI 页面接受 productId/context 参数

**第四里程碑：后台驾驶舱 + 视觉延展**
- [x] DashboardStats 补充 todayRevenue/todayOrders/pendingRefund
- [x] AdminDashboard 4 张差异化 KPI 卡（今日营业额/待发货/退款申请/低库存预警）
- [x] 今日待办 Timeline 组件 + AI 咨询热点区块
- [x] 四类页面视觉指纹差异化（首页翠绿/AI 紫蓝/后台琥珀金/详情档案风）

**P1 遗留清理**
- [x] 批量迁移 24 个文件废弃的 String.tr 扩展 → ref.tr() / TranslatorGlobal.instance.translate()
- [x] dart analyze 0 errors 验证通过

### 🏗️ 基础架构
- [x] Flutter 项目重构 + SDK 配置 (compileSdk 36)
- [x] ProductDetailScreen UI优化（PremiumCard、玻璃态效果、沉浸式大图）
- [x] ProductListScreen 组件替换为 PremiumCard，支持自适应暗色主题
- [x] 完善 CartScreen 真实订单创建逻辑，通过购物车生成真实单号与数据
- [x] 完善 OrderList & OrderDetail，覆盖 待发货、取消、查看物流等真实电商状态与按钮行为
- [x] 主题系统 (JewelryTheme - Liquid Glass 设计)
- [x] 状态管理 (Riverpod + SharedPreferences 持久化)
- [x] 全局配置 (AppConfig + Secrets 分离)
- [x] 本地存储 (SharedPreferences 封装)

### 🎨 核心页面
- [x] 登录页面 (玻璃态设计，双入口——管理员/操作员)
- [x] 主界面框架 (底部导航四Tab)
- [x] 商城首页 (商品列表、分类筛选、搜索排序)
- [x] 商品详情页 (产品信息、AI描述生成、购物车)
- [x] 商品搜索页 (搜索历史、热门搜索、实时结果)
- [x] 购物车 (增删改查、数量调整、结算)
- [x] 订单列表页 (订单分类Tab、状态管理)
- [x] 订单详情页 (状态流程、商品信息、支付信息)
- [x] 收藏列表页 (收藏展示、取消收藏、加入购物车)
- [x] 浏览记录页 (按日期分组、清空记录)
- [x] 个人中心 (用户信息、资产、各入口)
- [x] 收货地址管理 (增删改查、默认地址、地区选择)
- [x] AI 助手对话 (DeepSeek智能对话、快捷问答)
- [x] 操作员工作台 (商家管理、AI话术生成)
- [x] 管理员仪表盘 (Tab化：总览/商品管理/操作员)
- [x] 店铺详情页 (店铺信息、联系记录、AI话术)
- [x] AR 试戴界面 (虚拟试戴)
- [x] 通知中心页面 (全部/订单/活动/系统 Tab、未读标记、一键已读)

### 🤖 AI 服务
- [x] DeepSeek API 集成 + 密钥安全配置 (dart-define + secrets.dart 双层方案)
- [x] 珠宝行业专家角色 System Prompt
- [x] 产品上下文注入 (22款商品信息)
- [x] 流式输出 (打字机效果 + SSE解析)
- [x] 离线模式智能降级 (细分场景回复)
- [x] UTF-8 中文编码修复 (utf8.decode + json.decode)
- [x] API Key 有效性检查 + 友好提示
- [x] **Gemini API 集成** (gemini-2.0-flash-exp) — 2026-02-22
- [x] **DeepSeek → Gemini 三级降级策略** (DeepSeek 优先 → Gemini 备用 → 本地离线) — 2026-02-22
- [x] Gemini SSE 流式输出支持 (streamGenerateContent) — 2026-02-22
- [x] **AI 图片识别代理方案** — Gemini 国内不可达，切换至阿里云 DashScope（通义千问 qwen-vl-max），后端代理 `/api/ai/analyze-image` — 2026-02-23
- [x] **DashScope API Key 服务器配置** — `DASHSCOPE_API_KEY` 在 `/srv/huiyuyuan/backend/.env` 中配置并验证图片识别通过 — 2026-02-23

### 🎭 主题与国际化
- [x] 深色/浅色模式完整适配 (所有页面)
- [x] 主题自适应颜色扩展 (adaptiveBackground/Card/Text 等)
- [x] 多语言国际化 (简体中文/繁体中文/英文)
- [x] ref.tr() 扩展方法 + Riverpod 语言 Provider

### 📦 真实数据
- [x] 130款珠宝商品 (和田玉/翡翠/南红/黄金/钻石/珍珠/银饰/水晶/蜜蜡/碧玉/绿松石/珊瑚/天珠/玛瑙/沉香等) — 原23款 + 扩展107款 (2026-02-23)
- [x] 12家合作商家 (淘宝/抖音/小红书/快手等平台)
- [x] 商品图片 (Unsplash/picsum 高清图)

### 🧪 测试
- [x] 模型单元测试 (23用例)
- [x] 服务层测试 (57用例)
- [x] Provider测试 (42用例)
- [x] 集成测试 (56用例)
- [x] 真机测试指南

### 🔧 通用组件
- [x] 骨架屏组件 (商品卡片/列表/订单/店铺)
- [x] 空状态组件 (购物车空/无结果/无订单等)
- [x] 加载状态/错误状态组件
- [x] 评价展示组件 (统计/筛选/图片视频评价)
- [x] 毛玻璃卡片组件 (GlassmorphicCard)
- [x] 自动轮播图组件 (PromotionalBanner，4页自动播放 + 动画圆点指示器)

### 🛠️ 开发工具
- [x] APK 构建工作流
- [x] 购物流程测试工作流
- [x] GitHub Actions CI/CD（`.github/workflows/ci.yml`）— flutter analyze + test + build APK/AAB + 自动部署后端+前端到 ECS
- [x] Flutter 开发技能文档
- [x] 数据管理技能文档
- [x] 代码质量清理 (0 errors, 0 warnings)
- [x] 库存管理模块 (库存总览/出入库记录/库存统计三Tab、归入管理员仪表盘)
- [x] **一键部署脚本** `scripts/deploy.ps1`（分析→构建→后端→前端→健康检查，支持 -Target / -SkipAnalyze / -DryRun）— 2026-02-25
- [x] **VSCode 任务集成** `.vscode/tasks.json`（8 个任务：全量/快速/前端/后端部署 + 构建/分析/测试/健康检查）— 2026-02-25
- [x] **CI/CD 增强** — 新增 Web 前端自动部署 Job、统一后端部署路径 `/srv/huiyuyuan` — 2026-02-25
- [x] **项目清理** — 删除 17 个临时/过时文件、新增根 `.gitignore`、同步 nginx.conf 至生产配置 — 2026-02-25

---

## 📅 2026-02-25 今日完成

| 任务 | 详情 |
|------|------|
| 🔍 搜索功能完全重写 | `search_screen.dart` 从 mock 数据改为基于 `realProductData` 的真实搜索，支持名称/材质/分类/编号/产地/描述多维搜索，实时联想建议、分类过滤栏、排序方式（综合/价格/销量）、关键词高亮、「发现好物」推荐区 |
| 🔔 通知系统新建 | `notification_screen.dart` 全新通知中心，Tab 分类（全部/订单/活动/系统）、未读标记、一键已读、详情弹窗 |
| 🎠 轮播图完全重写 | `promotional_banner.dart` 从静态单图改为 4 页自动轮播，4s 自动播放、手动滑动暂停恢复、动画圆点指示器 |
| 🛒 购物车结算修复 | `cart_screen.dart` `_checkout()` 不再过滤不存在的 `isSelected` 字段，改为处理全部商品 |
| 💰 立即购买修复 | `product_detail_screen.dart` 「立即购买」从 SnackBar 弹窗改为跳转 CheckoutScreen + 图片轮播页码指示器 + `memCacheWidth: 800` |
| 🔗 后端服务优化 | `backend_service.dart` baseUrl 改用 `ApiConfig.baseUrl`、新增 Auth token 拦截器自动注入、超时时间调大 |
| 🔧 操作员开关修复 | `operator_home.dart` 提醒开关闭包 bug（`isOn` 每次 rebuild 被重置）已修复 |
| 👤 个人中心优化 | `profile_screen.dart` 编辑资料弹窗、提醒设置 SharedPreferences 持久化 |
| ⚡ 性能优化 | `main.dart` 错误页“重试”按钮实现实际重载、`SystemChrome` 移至 postFrameCallback 避免每帧冗余调用 |
| 🚀 部署上线 | `flutter build web` 构建成功，scp 部署到 xn--lsws2cdzg.top（原 47.98.188.141），nginx reload，后端 health check 通过 |
| 🤖 自动化部署系统 | 新增 `scripts/deploy.ps1` 一键部署脚本（支持 -Target all/web/backend、-SkipAnalyze、-SkipBuild、-DryRun），含 SSH 连通检查、静态分析、Web 构建、SCP 上传、服务重启、健康检查完整流水线 |
| ⌨️ VSCode 任务集成 | `.vscode/tasks.json` 新增 8 个任务（全量部署/快速部署/前端部署/后端部署/仅构建/静态分析/测试/健康检查），Ctrl+Shift+B 触发默认部署 |
| 🔄 CI/CD 增强 | `ci.yml` 新增 Job 3: Web 前端自动部署（flutter build web → SCP → nginx reload），后端路径统一为 `/srv/huiyuyuan` |
| 🧹 项目清理 | 删除 17 个临时/过时文件（analyze*.txt、tmp_*.txt、test_sms.py、docs/reference/1.md、2.md），新增根 `.gitignore`，nginx.conf 同步至生产配置 |
| 📖 部署文档 | 新增 `docs/guides/deployment_guide.md`（架构概览、三种部署方式、服务器目录、故障排查），更新 copilot-instructions.md |

---

## 📅 2026-02-23 完成

| 任务 | 详情 |
|------|------|
| 🔧 验证码登录错误修复 | `_handleError()` 新增 `detail` 字段解析（FastAPI HTTPException 返回 `{"detail":...}`）；`loginCustomer()` 新增 `lastLoginError` 字段，前端显示实际错误而非硬编码消息 |
| 🔁 Token刷新无限循环修复 | Dio `onError` 拦截器增加 `_refreshRetryCount` + `_maxRefreshRetries = 2`，超过上限清除 Token 停止重试 |
| 🖼️ AI图片识别替换 | Gemini API 国内完全不可达（HTTP 000），切换至 DashScope 通义千问 VL（`qwen-vl-max`），后端代理 `/api/ai/analyze-image`，前端改用 `uploadBytes()` 上传至后端而非直連 Gemini |
| 🔑 DashScope 配置 | `DASHSCOPE_API_KEY=sk-64b7fb...` 写入服务器 `.env`，重启服务，测试通过：准确识别玫瑰金钻石手链并返回结构化 JSON |
| 📦 商品扩充至130款 | 新增 `product_data_extended.dart`（107款），覆盖 15+ 材质分类：和田玉/翡翠/南红/黄金/钻石/珍珠/银饰/水晶/蜜蜡/碧玉/绿松石/珊瑚/天珠/玛瑙/沉香/紫檀等 |
| 🚀 全量部署 | 后端 `main.py` + `httpx` 安装 + 前端 `flutter build web --release` → scp 至服务器，`/api/health` 200 OK |

---

## 📅 2026-02-22 完成

| 任务 | 详情 |
|------|------|
| 🔐 登录验证码修复 | `useMockApi` 改回 `true`，万能验证码 8888 及管理员/用户 Mock 登录完全恢复 |
| 🤖 Gemini API 集成 | `app_config.dart` 新增 `geminiApiKey / geminiBaseUrl / geminiModel`，从 `Secrets.geminiApiKey` 读取 |
| ⚡ DeepSeek+Gemini 融合 | `ai_service.dart` 实现三级降级：DeepSeek → Gemini → 离线 |
| 🌊 Gemini 流式输出 | 新增 `_chatStreamWithGemini()`，完整实现 Gemini SSE |
| 📦 零编译错误 | 全量 `get_errors` 通过，0 error / 0 warning |
| 🚀 服务器部署完成 | xn--lsws2cdzg.top（原 ECS 47.98.188.141）/ Gunicorn / PostgreSQL 14 / Redis / Nginx 全部运行，`/api/health` 返回 `healthy` |
| 🔐 任务C：前端登录改造 | `flutter_secure_storage`、60s倒计时、`sendSmsCode()`、加密Token，0 errors |
| 📋 任务B：数据库建表 | 9张表（users/products/orders/order_items/payments/cart_items/addresses/sms_logs/reviews）+ 触发器 + 索引全部创建成功 |
| 📱 任务A：SMS 路由 | `/api/auth/send-sms`（Redis限流：60s冷却/日10次/5次错误锁定）+ `/api/auth/verify-sms`（JWT+PostgreSQL自动注册），含降级，6个测试用例全通过 |
| 🔧 useMockApi 切换 | `api_config.dart` `useMockApi = false`，前端已对接真实后端 |
| 📄 任务F：隐私合规页面 | 新增 `privacy_policy_screen.dart`（8节完整隐私政策）+ `user_agreement_screen.dart`（8节完整用户协议），`profile_screen.dart` 改为 Navigator.push，`main.dart` 添加首次启动 `_PrivacyConsentDialog`（不可取消，SharedPreferences `privacy_accepted_v1`） |
| ⚙️ 任务D：GitHub Actions | `.github/workflows/ci.yml` — Job 1: flutter analyze + test + 构建 Debug APK(PR)/Release AAB(main push)；Job 2: 依赖 Job1，SCP 上传后端 + SSH 重启 Gunicorn + 健康检查 |

---

## 📅 2026-02-20 今日完成

| 任务 | 详情 |
|------|------|
| 🔐 API密钥安全配置 | secrets.dart 重构为 `--dart-define` + 本地回退双层方案 |
| 🌙 深色模式全面适配 | 登录页/主页/搜索/收藏/浏览记录/订单列表/订单详情 全部适配 |
| 🎨 主题扩展方法 | 新增 adaptiveBackground/Surface/Card/Text 等便利 getter |
| 🤖 AI 流式编码修复 | `String.fromCharCodes` → `utf8.decode`，RegExp → `json.decode` |
| 🔇 离线模式优化 | 移除误导性"网络不稳定"提示，静默降级 + [离线模式] 标记 |
| 📡 Base URL 修正 | DeepSeek API 地址改为官方推荐 `https://api.deepseek.com` |
| 🌍 AI 多语言适配 | 助手回复跟随系统语言 (英/繁/简) |
| ✨ 前端动效升级 | 呼吸感 TypingIndicator、打字机光标、FadeSlideTransition 进场动画 |
| 🌐 设置页国际化 | 修复 Dark Mode/Language 等枚举值未翻译的问题 |
| 💎 前端 UI/UX 体验优化 | 根据 UI-UX Pro Max 对商品列表、详情页应用玻璃态卡片与自适应颜色体系，更贴近生活使用场景 |
| 🖼️ 商品详情多图滑动 | 使用 PageView 支持详情页顶部商品图片的多图滑动 |

---

## 🚧 下次开发任务

### 🔴 P0 高优先级 — 阻塞上线（必须完成，目标 2026-03-08 前）

#### 后端部署
- [x] 购置阿里云 ECS（2核4GB，Ubuntu 22.04，华东，IP: 47.98.188.141 → 域名 xn--lsws2cdzg.top）
- [x] 安装 Python 3.11 / PostgreSQL 14 / Redis 6.0 / Nginx 1.18
- [x] 部署 FastAPI 后端（Gunicorn + uvicorn worker，systemd 开机自启）
- [x] 配置 Nginx 反向代理（80→8000，含 limit_req_zone 限流）
- [ ] 配置 HTTPS 证书（Let's Encrypt / Certbot）— 需先配置域名
- [x] 配置生产域名 `xn--lsws2cdzg.top`（已启用 HTTPS，原 IP: 47.98.188.141）
- [x] 数据库建表（9张表 + 触发器 + 索引，init_db_utf8.sql 已执行）

#### 登录系统重构（阿里云 SMS）
- [ ] 注册阿里云短信服务（企业资质），获取 AccessKey、短信签名、模板 Code
- [x] 后端 `main.py` 新增 `/api/auth/send-sms`（Redis 限流 + 阿里云 SDK 占位符）
- [x] 后端 `main.py` 新增 `/api/auth/verify-sms`（验证码校验 + JWT 颁发 + PostgreSQL 自动注册）
- [x] 前端 `api_config.dart` 新增路由常量 + `useMockApi = false`
- [x] 前端 `login_screen.dart` 改造：60秒倒计时按钮 + 错误提示
- [x] 前端 `auth_provider.dart` 新增 `sendSmsCode()` / `loginWithSms()` 方法
- [x] 引入 `flutter_secure_storage`，Token 改为加密存储
- [ ] 在服务器 `.env` 填入真实 `ALIYUN_ACCESS_KEY_ID` / `SECRET` / `SMS_TEMPLATE_CODE`

#### 隐私合规
- [x] 撰写《隐私政策》（含数据收集、使用、删除条款，遵循 PIPL）— `lib/screens/legal/privacy_policy_screen.dart`
- [x] 撰写《用户服务协议》— `lib/screens/legal/user_agreement_screen.dart`
- [ ] 部署隐私政策页面到 HTTPS 可访问 URL（或嵌入 App 内 WebView）
- [x] 首次启动隐私协议弹窗（用户同意后才初始化 Analytics/Crashlytics）— `main.dart _AppRouter` + `_PrivacyConsentDialog`，SharedPreferences `privacy_accepted_v1`

#### 发布准备
- [ ] 生成 Android 签名密钥（`huiyuyuan.jks`），安全备份到多处
- [ ] 配置 `build.gradle.kts` Release 签名（从环境变量读取密码）
- [ ] 购买 Apple Developer Program（¥688/年，如需 iOS 上架）
- [ ] 构建首个 Release AAB / IPA 并内部测试通过

---

### 🟡 P1 中优先级 — 首发版本含（2026-03-09 → 2026-03-22）

#### 支付系统（资质就绪后）
- [ ] 微信支付：后端签名 + 回调验签 + orders 状态更新
- [ ] 支付宝：后端 RSA2 签名 + 回调处理
- [ ] 前端 `payment_service.dart`：补全 `createWechatPayment()` / `createAlipayPayment()`
- [ ] 支付结果轮询（每5秒，最多60秒）

#### 客服系统
- [ ] 后端 WebSocket 路由 `/ws/chat/{session_id}` + Redis Pub/Sub
- [ ] 数据库建表：`cs_sessions` / `cs_messages`
- [ ] 新建 `customer_service_screen.dart`（消息列表 + 输入框 + 订单卡片）
- [ ] AI 自动分流：简单问题 → AI 回答，复杂/投诉 → 转人工

#### 数据云端化
- [ ] 购物车云端同步（登录后同步本地购物车到后端）
- [ ] 订单列表从 API 拉取（替换本地 Mock）
- [ ] 收藏列表云端持久化
- [ ] 地址同步到云端

#### 监控
- [ ] 接入 Firebase Crashlytics（`FlutterError.onError` 注册）
- [ ] 后端接入请求日志（access.log 格式，Nginx 记录）

---

### 🟢 P2 低优先级 — v1.1.0 后迭代（2026-04 以后）
- [ ] 图片上传服务（阿里云 OSS STS Token + Flutter 上传）
- [ ] Firebase 推送通知（订单状态变更推送）
- [ ] 物流查询（对接快递100 API）
- [ ] 区块链溯源证书功能完善
- [x] AI 多模态图片输入（上传珠宝图片识别真伪）— **已完成**，DashScope qwen-vl-max，后端代理方案 (2026-02-23)
- [ ] 平板/折叠屏适配优化

---

## 📊 项目进度

| 指标 | 数值 |
|------|------|
| 页面文件 | 23+ (含通知中心、库存管理) |
| 组件文件 | 9+ (含自动轮播图) |
| 服务文件 | 7+ |
| 模型文件 | 6+ (含库存模型) |
| 数据文件 | 3 (product_data + product_data_extended + shop_data) |
| 商品数量 | 130 (23原有 + 107扩展) |
| 店铺数量 | 12 |
| 核心功能完成率 | 99% |
| AI 服务可靠性 | 三级冗余 (DeepSeek + 通义千问VL + 离线) |
| AI 图片识别 | ✅ DashScope qwen-vl-max 已配置并验证 |
| 上线就绪率 | 88% (待支付/HTTPS/域名) |

---

*最后更新: 2026-02-25（全面迭代开发：搜索重写 + 通知系统 + 轮播图 + 交互补全 + 性能优化 + 库存管理 + 部署上线）*
