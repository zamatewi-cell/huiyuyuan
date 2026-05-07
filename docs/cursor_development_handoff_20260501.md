# Cursor 续开发交接与项目 Review

> 更新日期：2026-05-01
> 适用场景：在 Cursor 中继续开发汇玉源，快速理解当前项目、接口、页面、操作流、质量风险和后续产品方向。
> 当前策略：真实微信/支付宝支付暂缓，短期重点转向产品质感、内容可信度、交易闭环体验和工程交接稳定性。

---

## 1. 当前判断

汇玉源当前不是“不能用”，而是“能跑、功能多、但产品灵魂还没有完全站起来”。UI 重构已经让视觉从早期模板感里走出来了，生产 Web 也已经部署；但如果继续按普通电商小程序的套路做首页、分类、商品卡、购物车、订单，就会自然滑向“瑞幸咖啡小程序换皮”的感觉。

短期不建议把真实支付作为主线。支付接入会消耗大量资质、风控、回调、对账和售后成本，但它不能解决产品看起来潦草的问题。现在更值得优先做的是：

- 建立“珠宝交易平台”的产品叙事，而不是“普通商品列表 + 下单”。
- 把商品内容从 SKU 卡片升级成“一物一档、鉴赏理由、可信凭证、来源故事”。
- 把 AI 从聊天按钮升级成“懂玉的导购/鉴宝助理/下单顾问”。
- 把后台从能操作升级成“让运营人员不慌”的订单、库存、支付、售后工作台。
- 把文档、Cursor 规则、MCP/Skills 说明补齐，避免换工具后审美和工程约束断层。

---

## 2. Review 结论与风险

| 优先级 | 发现 | 影响 | 建议 |
|------|------|------|------|
| P0 | GitHub 账号申诉中，本地提交和生产部署暂时无法推送远端 | Cursor 继续开发时，如果换机器或误清理，本地成果和生产状态容易失联 | 先保留本地分支、release bundle 和 patch 包；GitHub 恢复后第一时间推送 |
| P1 | 产品信息架构仍偏普通电商，容易像瑞幸/点单小程序 | 品牌高级感被“列表、分类、下单”的惯性稀释 | 以“甄选、鉴赏、信任、顾问、藏家感”为主线重构核心旅程 |
| P1 | 支付链路仍是人工确认和测试逻辑混合，存在 `0.01` 自动确认测试订单 | 真实商业环境下容易造成误确认或用户误解 | 明确当前为“人工支付/凭证确认模式”，真实第三方支付暂缓，测试自动确认加环境保护 |
| P1 | 后端部分中文提示存在编码损坏，如订单路由里的乱码字符串 | 错误提示可能直接暴露给前端或日志，显得不专业 | 统一清理为 UTF-8 中文，或改为稳定错误码 + 前端本地化文案 |
| P1 | 根目录图片/视觉稿过多，当前根目录 PNG 约 212 个，Git 跟踪 PNG 约 331 个 | Cursor 打开项目时噪音很大，也会拖慢检索和让项目显得杂乱 | 设立 `docs/reference/visual_archive/` 或外部素材盘，根目录只保留必要文件 |
| P2 | `.vscode/mcp.json` 当前为空 | Cursor 没有 Figma/GitHub/浏览器自动化上下文，设计和交接能力会下降 | 在文档里写明建议 MCP，不把 token 写进仓库 |
| P2 | `ApiConfig.isProduction=false` 目前只作为常量存在 | 如果后续有人误用它判断生产环境，可能导致逻辑歧义 | 后续改成 dart-define 或删除未使用常量 |
| P2 | `LuxuryRedesignPreviewScreen` 已作为设计预览入口保留在 debug 配置后 | 这对设计交接有用，但不能误进生产默认路径 | 保持 `show_ui_redesign_preview` 仅本地调试可开 |

关键代码位置：

| 位置 | 说明 |
|------|------|
| `huiyuyuan_app/backend/routers/payments.py:150` | `0.01` 测试订单自动确认逻辑 |
| `huiyuyuan_app/backend/routers/orders.py:647` | `https://pay.example.com/...` 占位支付链接 |
| `huiyuyuan_app/backend/routers/orders.py:503` 起 | 多处订单错误提示字符串存在乱码 |
| `huiyuyuan_app/lib/config/api_config.dart:36` | `isProduction=false` 常量 |
| `.vscode/mcp.json` | Cursor/MCP 配置当前为空 |

---

## 3. 项目结构速览

| 区域 | 路径 | 作用 |
|------|------|------|
| 项目根目录 | `D:/huiyuyuan_project/` | 文档、脚本、Flutter 应用、Agent 配置 |
| Flutter 应用 | `D:/huiyuyuan_project/huiyuyuan_app/` | 前端主工程，支持 Web/Android/Windows 等 |
| Flutter 源码 | `D:/huiyuyuan_project/huiyuyuan_app/lib/` | 页面、Provider、Service、主题和配置 |
| FastAPI 后端 | `D:/huiyuyuan_project/huiyuyuan_app/backend/` | API、数据库、服务层、测试 |
| 文档中心 | `D:/huiyuyuan_project/docs/` | 当前有效文档入口 |
| 部署脚本 | `D:/huiyuyuan_project/scripts/` | 生产部署、入口验证、迁移脚本 |
| 本地 Agent 技能 | `D:/huiyuyuan_project/.agent/skills/` | 供 AI 辅助工具参考的技能包 |
| 本地工作流 | `D:/huiyuyuan_project/.agent/workflows/` | 常用启动、检查、构建流程说明 |
| VS Code/Cursor 配置 | `D:/huiyuyuan_project/.vscode/` | 编辑器设置和 MCP 配置占位 |

---

## 4. 产品角色与核心操作流

### 普通用户

| 流程 | 当前入口 | 说明 |
|------|------|------|
| 登录/注册 | `LoginScreen` | 支持用户、操作员、管理员三类入口；验证码/密码/注册模式 |
| 商品浏览 | `ProductListScreen` | 分类、搜索、列表、推荐商品 |
| 商品详情 | `ProductDetailScreen` | 商品图、价格、库存、详情、收藏、加入购物车 |
| AI 辅助 | `AIAssistantScreen` | 文本问答、产品上下文和图片识别能力 |
| 收藏 | `FavoriteListScreen` | 收藏商品列表 |
| 购物车 | `CartScreen` | 商品数量、选择、结算入口 |
| 结算 | `CheckoutScreen` | 地址、商品、金额、提交订单 |
| 支付 | `PaymentScreen` | 当前为人工支付/凭证确认模式，不是真实三方自动支付 |
| 订单 | `OrderListScreen` / `OrderDetailScreen` | 订单列表、状态、详情、取消、确认收货、退款申请 |
| 物流 | `LogisticsScreen` | 查看物流信息 |
| 评价 | `PublishReviewScreen` | 订单评价和晒单 |
| 地址 | `AddressListScreen` | 地址增删改查 |
| 设备 | `DeviceManagementScreen` | 登录设备查看和下线 |
| 通知 | `NotificationScreen` | 通知列表和已读 |
| 法务 | `PrivacyPolicyScreen` / `UserAgreementScreen` | 隐私政策和用户协议 |

### 管理员

| 流程 | 当前入口 | 说明 |
|------|------|------|
| 数据总览 | `AdminDashboard` | 管理后台首页、关键指标和活动 |
| 订单工作台 | `AdminOrderWorkbenchScreen` | 发货、确认到账、订单处理 |
| 库存管理 | `InventoryScreen` | 库存列表、库存调整、库存流水 |
| 支付对账 | `PaymentReconciliationWorkbenchScreen` | 查看支付记录、确认、争议、超时 |
| 操作员管理 | 后端 `/api/admin/operators` | 操作员状态和报表 |

### 操作员

| 流程 | 当前入口 | 说明 |
|------|------|------|
| 操作员登录 | `LoginScreen` 操作员标签 | 使用操作员编号和密码 |
| 门店/客户辅助 | `OperatorHomeScreen` | 面向客服、导购、门店协作 |
| 店铺详情 | `ShopDetailScreen` | 店铺信息和联系入口 |
| 店铺雷达 | `ShopRadar` | 店铺位置/雷达体验 |

### 发布与运维

| 流程 | 命令/入口 | 说明 |
|------|------|------|
| 后端启动 | `cd huiyuyuan_app/backend && python main.py` | 本地 FastAPI |
| Flutter Web 启动 | `cd huiyuyuan_app && flutter run -d chrome` | 浏览器调试 |
| Windows 启动 | `cd huiyuyuan_app && flutter run -d windows` | 桌面调试 |
| 后端测试 | `cd huiyuyuan_app/backend && python -m pytest` | 后端测试 |
| 前端测试 | `cd huiyuyuan_app && flutter test` | Flutter 测试 |
| 静态分析 | `cd huiyuyuan_app && flutter analyze` | Dart/Flutter 检查 |
| 生产部署 | `.\scripts\deploy.ps1` | 一键部署入口 |
| 公网验证 | `.\scripts\verify_public_ingress.ps1` | 域名和后端健康检查 |

---

## 5. 前端结构与页面清单

### 入口与配置

| 文件 | 作用 |
|------|------|
| `huiyuyuan_app/lib/main.dart` | Flutter 应用入口，初始化本地调试配置、存储和商品服务 |
| `huiyuyuan_app/lib/app/app_router.dart` | 隐私、更新、登录态、设计预览和主界面路由判断 |
| `huiyuyuan_app/lib/config/api_config.dart` | API 地址、Mock 开关、OSS、DashScope 配置 |
| `huiyuyuan_app/lib/config/secrets.dart` | 通过 `--dart-define` 注入密钥 |
| `huiyuyuan_app/lib/themes/` | Liquid Glass 主题、颜色、组件样式 |
| `huiyuyuan_app/lib/widgets/` | 复用组件 |

### 页面

| 页面 | 路径 |
|------|------|
| 登录 | `huiyuyuan_app/lib/screens/login_screen.dart` |
| 主框架 | `huiyuyuan_app/lib/screens/main_screen.dart` |
| 商品列表 | `huiyuyuan_app/lib/screens/trade/product_list_screen.dart` |
| 商品详情 | `huiyuyuan_app/lib/screens/trade/product_detail_screen.dart` |
| 购物车 | `huiyuyuan_app/lib/screens/trade/cart_screen.dart` |
| 结算 | `huiyuyuan_app/lib/screens/trade/checkout_screen.dart` |
| 支付 | `huiyuyuan_app/lib/screens/payment/payment_screen.dart` |
| 支付管理 | `huiyuyuan_app/lib/screens/payment_management_screen.dart` |
| 订单列表 | `huiyuyuan_app/lib/screens/order/order_list_screen.dart` |
| 订单详情 | `huiyuyuan_app/lib/screens/order/order_detail_screen.dart` |
| 物流 | `huiyuyuan_app/lib/screens/order/logistics_screen.dart` |
| 发布评价 | `huiyuyuan_app/lib/screens/order/publish_review_screen.dart` |
| 搜索 | `huiyuyuan_app/lib/screens/product/search_screen.dart` |
| 个人中心 | `huiyuyuan_app/lib/screens/profile/profile_screen.dart` |
| 地址 | `huiyuyuan_app/lib/screens/profile/address_list_screen.dart` |
| 收藏 | `huiyuyuan_app/lib/screens/profile/favorite_list_screen.dart` |
| 浏览记录 | `huiyuyuan_app/lib/screens/profile/browse_history_screen.dart` |
| 设备管理 | `huiyuyuan_app/lib/screens/profile/device_management_screen.dart` |
| 通知 | `huiyuyuan_app/lib/screens/notification/notification_screen.dart` |
| AI 助手 | `huiyuyuan_app/lib/screens/chat/ai_assistant_screen.dart` |
| AR 试戴 | `huiyuyuan_app/lib/screens/ar/ar_tryon_screen.dart` |
| 店铺详情 | `huiyuyuan_app/lib/screens/shop/shop_detail_screen.dart` |
| 店铺雷达 | `huiyuyuan_app/lib/screens/shop/shop_radar.dart` |
| 隐私政策 | `huiyuyuan_app/lib/screens/legal/privacy_policy_screen.dart` |
| 用户协议 | `huiyuyuan_app/lib/screens/legal/user_agreement_screen.dart` |
| 管理后台 | `huiyuyuan_app/lib/screens/admin/admin_dashboard.dart` |
| 管理订单工作台 | `huiyuyuan_app/lib/screens/admin/admin_order_workbench_screen.dart` |
| 库存管理 | `huiyuyuan_app/lib/screens/admin/inventory_screen.dart` |
| 支付对账工作台 | `huiyuyuan_app/lib/screens/admin/payment_reconciliation_workbench_screen.dart` |
| 视觉预览 | `huiyuyuan_app/lib/screens/design/luxury_redesign_preview_screen.dart` |

### Provider / Repository / Service

| 类型 | 文件 | 作用 |
|------|------|------|
| Provider | `auth_provider.dart` | 登录态、用户身份 |
| Provider | `cart_provider.dart` | 购物车 |
| Provider | `product_catalog_provider.dart` | 商品目录 |
| Provider | `product_search_provider.dart` | 商品搜索 |
| Provider | `inventory_provider.dart` | 库存 |
| Provider | `payment_provider.dart` | 支付状态 |
| Provider | `payment_reconciliation_provider.dart` | 对账工作台 |
| Provider | `notification_provider.dart` | 通知 |
| Provider | `app_settings_provider.dart` | App 设置 |
| Repository | `admin_repository.dart` | 管理端 API |
| Repository | `payment_repository.dart` | 支付 API |
| Repository | `payment_account_repository.dart` | 收款账户 |
| Repository | `product_catalog_repository.dart` | 商品目录 |
| Repository | `user_data_repository.dart` | 用户数据 |
| Service | `api_service.dart` | HTTP 基础封装 |
| Service | `backend_service.dart` | 后端通用服务 |
| Service | `order_service.dart` | 订单 |
| Service | `payment_service.dart` | 支付 |
| Service | `product_service.dart` | 商品 |
| Service | `address_service.dart` | 地址 |
| Service | `review_service.dart` | 评价 |
| Service | `admin_service.dart` | 管理端 |
| Service | `ai_service.dart` | AI 入口 |
| Service | `ai_dashscope_service.dart` | DashScope 文本对话 |
| Service | `gemini_image_service.dart` | 历史兼容命名，当前走后端 DashScope 图片代理 |
| Service | `oss_service.dart` | 上传/OSS |
| Service | `notification_service.dart` | 通知 |
| Service | `notification_realtime_service.dart` | 实时通知/WebSocket |
| Service | `app_update_service.dart` | 移动端更新检测 |

---

## 6. 后端接口汇总

API 基础地址：

| 环境 | 地址 |
|------|------|
| Web 生产 | 同源请求，`ApiConfig.baseUrl == ''` |
| Native 生产 | `https://xn--lsws2cdzg.top` |
| 本地开发 | 可通过 `--dart-define=HUIYUYUAN_API_BASE_URL=...` 覆盖 |

FastAPI 运行后可以访问交互式文档：

| 文档 | 地址 |
|------|------|
| Swagger | `http://localhost:8000/docs` |
| ReDoc | `http://localhost:8000/redoc` |

### 健康检查

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/` | 根路径状态 |
| GET | `/api/health` | 后端健康检查 |

### Auth

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/login` | 密码登录 |
| POST | `/api/auth/send-sms` | 发送短信验证码 |
| POST | `/api/auth/verify-sms` | 校验短信验证码 |
| POST | `/api/auth/register` | 注册 |
| POST | `/api/auth/reset-password` | 重置密码 |
| POST | `/api/auth/logout` | 登出并使当前会话失效 |
| POST | `/api/auth/refresh` | 刷新 Token 并轮转会话 |
| GET | `/api/auth/captcha` | 图形验证码 |
| GET | `/api/auth/devices` | 登录设备列表 |
| DELETE | `/api/auth/devices/{device_fingerprint}` | 下线指定设备 |
| POST | `/api/auth/devices/logout-others` | 下线其他设备 |

### App Meta

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/app/version` | App 版本和更新信息。Web 端当前不弹更新提示，移动端保留 |

### Products

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/products` | 商品列表 |
| GET | `/api/products/{product_id}` | 商品详情 |
| POST | `/api/products` | 创建商品 |
| PUT | `/api/products/{product_id}` | 更新商品 |
| DELETE | `/api/products/{product_id}` | 删除商品 |
| GET | `/api/products/{product_id}/reviews` | 商品评价列表 |

### Shops

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/shops` | 店铺列表 |
| GET | `/api/shops/{shop_id}` | 店铺详情 |

### Cart

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/cart` | 获取购物车 |
| POST | `/api/cart` | 添加购物车 |
| PUT | `/api/cart/{product_id}` | 更新商品数量 |
| DELETE | `/api/cart/{product_id}` | 删除购物车商品 |
| DELETE | `/api/cart` | 清空购物车 |

### Favorites

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/favorites` | 收藏列表 |
| POST | `/api/favorites/{product_id}` | 添加收藏 |
| DELETE | `/api/favorites/{product_id}` | 取消收藏 |

### Users

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/users/profile` | 用户资料 |
| PUT | `/api/users/profile` | 更新用户资料 |
| POST | `/api/users/account/change-password` | 修改密码 |
| POST | `/api/users/account/deactivate` | 注销账号 |
| GET | `/api/users/addresses` | 地址列表 |
| POST | `/api/users/addresses` | 新增地址 |
| PUT | `/api/users/addresses/{address_id}` | 更新地址 |
| DELETE | `/api/users/addresses/{address_id}` | 删除地址 |
| GET | `/api/users/payment-accounts` | 收款账户列表 |
| POST | `/api/users/payment-accounts` | 新增收款账户 |
| PUT | `/api/users/payment-accounts/{account_id}` | 更新收款账户 |
| DELETE | `/api/users/payment-accounts/{account_id}` | 删除收款账户 |

### Orders

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/orders` | 订单列表 |
| GET | `/api/orders/stats` | 订单统计 |
| GET | `/api/orders/{order_id}` | 订单详情 |
| POST | `/api/orders` | 创建订单 |
| POST | `/api/orders/checkout` | 结算下单。当前返回占位支付链接，真实支付暂缓 |
| POST | `/api/orders/{order_id}/pay` | 订单支付/上传凭证 |
| GET | `/api/orders/{order_id}/pay-status` | 支付状态 |
| POST | `/api/orders/{order_id}/cancel` | 取消订单 |
| POST | `/api/orders/{order_id}/confirm-receipt` | 确认收货 |
| POST | `/api/orders/{order_id}/refund` | 申请退款 |
| GET | `/api/orders/{order_id}/logistics` | 物流信息 |

### Payments

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/payments` | 创建支付记录 |
| GET | `/api/payments/{payment_id}` | 支付详情 |
| POST | `/api/payments/{payment_id}/upload-voucher` | 上传支付凭证 |
| POST | `/api/payments/{payment_id}/cancel` | 取消支付 |
| GET | `/api/payments` | 支付记录列表 |
| GET | `/api/payments/admin/reconciliation` | 管理员对账列表 |
| POST | `/api/payments/admin/{payment_id}/confirm` | 管理员确认到账 |
| POST | `/api/payments/admin/{payment_id}/dispute` | 管理员标记争议 |
| POST | `/api/payments/admin/check-timeout` | 检查超时支付 |
| GET | `/api/payments/admin/audit/{user_id}` | 用户支付审计 |

当前支付策略：

- 保留人工支付、上传凭证、后台确认到账。
- 不在短期内接入微信支付/支付宝真实支付。
- 保留后台对账工作台，先把“人工确认也不出错”做好。
- 所有对外文案避免承诺“自动支付成功”。
- `0.01` 测试自动确认需要在后续版本加环境保护或移除。

### Inventory

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/inventory` | 库存列表 |
| GET | `/api/inventory/transactions` | 库存流水 |
| POST | `/api/inventory/transactions` | 创建库存流水 |
| GET | `/api/inventory/{product_id}` | 商品库存 |
| PUT | `/api/inventory/{product_id}/stock` | 调整库存 |

### Admin

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/dashboard` | 管理仪表盘 |
| GET | `/api/admin/activities` | 管理活动 |
| GET | `/api/admin/operators` | 操作员列表 |
| PUT | `/api/admin/operators/{operator_id}` | 更新操作员 |
| GET | `/api/admin/operators/reports` | 操作员报表 |
| GET | `/api/admin/operators/{operator_id}/report` | 单个操作员报表 |
| POST | `/api/admin/orders/{order_id}/ship` | 管理员发货 |
| POST | `/api/admin/orders/{order_id}/confirm-payment` | 管理员确认订单到账 |

### AI

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/ai/health` | AI 服务健康状态 |
| POST | `/api/ai/analyze-image` | 图片识别，后端代理 DashScope Vision |
| POST | `/api/ai/chat` | 文本聊天 |

### Upload / OSS

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/upload/image` | 上传图片 |
| GET | `/api/oss/sts-token` | 获取 OSS STS Token |

### Notifications / WebSocket

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/notifications/register` | 注册通知设备 |
| GET | `/api/notifications` | 通知列表 |
| POST | `/api/notifications/{notification_id}/read` | 单条已读 |
| POST | `/api/notifications/read-all` | 全部已读 |
| WS | `/ws/notifications` | 实时通知 WebSocket |

### Reviews

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/reviews` | 创建评价 |

---

## 7. 如何把产品做得不像普通点单小程序

现在最需要的是“产品脊梁”。下面这些方向可以在不推翻现有架构的前提下逐步落地。

### 首页从商品入口变成鉴赏入口

| 现在的问题 | 建议改法 |
|------|------|
| 首页容易变成分类、Banner、商品流 | 改成“今日甄选”“本周入库”“值得细看的一件”“材质知识” |
| 商品卡主要展示价格和图 | 增加“鉴赏理由”“稀缺点”“适合人群”“信任标签” |
| 促销味太重 | 少用满减、抢购，多用鉴赏、收藏、证书、来源 |

### 商品详情从电商详情变成一物一档

建议新增或强化这些模块：

- “一句话鉴赏”：这件珠宝为什么值得看。
- “材质与工艺”：翡翠、和田玉、南红、蜜蜡等分类的专业解释。
- “上手/佩戴场景”：不是卖货，而是帮用户想象使用。
- “可信凭证”：证书编号、检测机构、实拍图、瑕疵说明。
- “AI 问这件”：用户可以围绕当前商品直接问 AI。
- “适合谁”：送礼、自戴、收藏、入门、进阶。

### AI 从聊天入口变成导购能力

建议把 AI 能力放进商品和交易流里，而不只是一个独立聊天页：

- 商品详情页提供“帮我看懂这件”。
- 结算前提供“这件适合送什么人吗”。
- 图片识别后直接推荐类似材质或价位。
- 客服/操作员端提供“回复建议”和“风险提示”。

### 管理后台从功能集合变成运营驾驶舱

后台应该让运营人员知道“今天该处理什么”，而不是只给表格：

- 今日待确认付款。
- 今日待发货。
- 库存异常。
- 高价值订单。
- 有争议支付。
- AI/用户咨询热点。

### 视觉上保留大体方向，但增加惊喜

保持 Liquid Glass、深玉色、金色点缀的大方向，但避免所有页面都套同一张玻璃卡：

- 首页可以更像“珠宝展柜”，用横向精选和深色光影。
- 商品详情可以更像“鉴定档案”，用证书、纹理、微距图层。
- AI 页面可以更像“私人顾问室”，减少普通聊天 App 味道。
- 后台可以更像“交易控制台”，信息密度更高，少一点装饰。

---

## 8. Cursor 续开发配置建议

### 在 Cursor 中打开项目

推荐直接打开：

```powershell
D:\huiyuyuan_project
```

打开后优先阅读：

| 文档 | 用途 |
|------|------|
| `AGENTS.md` | 当前仓库的权威协作规则 |
| `docs/README.md` | 文档入口 |
| `docs/project_status_20260428.md` | 最近上线状态和验证结果 |
| `docs/cursor_development_handoff_20260501.md` | 本交接文档 |
| `docs/design/design_system.md` | 视觉系统 |
| `docs/design/figma_ui_redesign_handoff.md` | Figma 设计方向 |
| `docs/guides/deployment_guide_updated.md` | 部署 |

### Cursor Rules 建议

如果你在 Cursor 里使用 `.cursor/rules/`，建议把下面规则拆成一个或多个规则文件。不要把密钥写进去。

```md
# HuiYuYuan Development Rules

- Always read AGENTS.md before making project-wide changes.
- Treat docs/project_status_20260428.md and docs/cursor_development_handoff_20260501.md as current handoff references.
- Do not use docs/reference/ or archive documents as current authority unless explicitly asked.
- Preserve the Liquid Glass design direction: deep jade, glassmorphism, champagne gold accents, premium jewelry mood.
- Do not make the app feel like a generic coupon/store-ordering mini program.
- Real WeChat/Alipay payment is postponed. Keep payment flows in manual voucher + admin confirmation mode unless explicitly asked.
- Never commit secrets, API keys, Figma tokens, GitHub tokens, OSS credentials, or local .env files.
- For Flutter changes, run flutter analyze and relevant flutter test when feasible.
- For backend changes, run python -m pytest or targeted pytest when feasible.
- Keep Web update prompts disabled. Web should update by static deployment/cache refresh; mobile can keep update prompts.
```

### 现有本地 Skills

仓库中已经有 `.agent/skills/`，但 Cursor 不一定会自动识别这些技能。可以把它们当作“可读知识库”：

| Skill | 路径 | 建议用途 |
|------|------|------|
| `ui-ux-pro-max` | `.agent/skills/ui-ux-pro-max/` | 设计风格、配色、排版灵感 |
| `theme-factory` | `.agent/skills/theme-factory/` | 快速生成主题方向 |
| `pdf` | `.agent/skills/pdf/` | PDF 处理 |
| `xlsx` | `.agent/skills/xlsx/` | 表格处理 |
| `brand-guidelines` | `.agent/skills/brand-guidelines/` | 这是 Anthropic 品牌规则，不适合直接用于汇玉源 |

Codex 当前环境里还有一些插件 Skills，例如 Figma、GitHub、i18n release guard。这些能力不会自动迁移到 Cursor，除非 Cursor 侧也配置相应 MCP 或扩展。因此所有重要设计方向都应写入 `docs/`，不要只留在聊天记录里。

### 现有 Workflows

| Workflow | 路径 | 用途 |
|------|------|------|
| build-apk | `.agent/workflows/build-apk.md` | APK 构建 |
| check-env | `.agent/workflows/check-env.md` | 环境检查 |
| run-app | `.agent/workflows/run-app.md` | 启动前端 |
| run-backend | `.agent/workflows/run-backend.md` | 启动后端 |
| verify-quality | `.agent/workflows/verify-quality.md` | 质量验证 |

### MCP 建议

当前 `.vscode/mcp.json` 内容为空：

```json
{
  "servers": {}
}
```

建议在 Cursor 侧按需配置，但不要把 token、cookie、账号密码提交到仓库：

| MCP/工具 | 用途 | 必要性 |
|------|------|------|
| Figma | 读取/继续设计稿、同步视觉方向 | 推荐 |
| GitHub | GitHub 恢复后查看 PR、Issue、CI | 推荐，账号恢复后再配 |
| Playwright/Browser | 做 Web 端视觉和交互冒烟测试 | 推荐 |
| Filesystem/Search | 大项目检索和批量阅读 | Cursor 内置通常够用 |
| Terminal/Shell | 运行 Flutter、pytest、部署脚本 | 必要 |

MCP 配置原则：

- 不把私密 token 写进 Git。
- 优先放在 Cursor 用户级配置，而不是项目仓库。
- 如果必须写项目级示例，只写占位符和说明。
- Figma 无法使用时，以 `docs/design/figma_ui_redesign_handoff.md` 和 `luxury_redesign_preview_screen.dart` 为视觉参考。

---

## 9. Cursor 中常用命令

### 前端

```powershell
cd D:\huiyuyuan_project\huiyuyuan_app
flutter pub get
flutter run -d chrome
flutter run -d windows
flutter analyze
flutter test
```

### 后端

```powershell
cd D:\huiyuyuan_project\huiyuyuan_app\backend
pip install -r requirements.txt
python main.py
python -m pytest
```

### Web 构建

```powershell
cd D:\huiyuyuan_project\huiyuyuan_app
flutter build web --release
```

### 生产部署

```powershell
cd D:\huiyuyuan_project
.\scripts\deploy.ps1
.\scripts\deploy.ps1 -Target web
.\scripts\deploy.ps1 -Target backend
.\scripts\verify_public_ingress.ps1
```

部署前建议：

- 当前 GitHub 未恢复时，不要随意删除本地分支和 release bundle。
- 部署前至少跑一次前端 analyze 或目标测试。
- Web 端旧页面通常优先排查浏览器缓存、CDN/代理缓存、Service Worker 或虚拟网卡代理 DNS。

---

## 10. 后续优先级建议

### 近期主线

| 优先级 | 事项 | 目标 |
|------|------|------|
| P0 | 产品主线重塑 | 让核心体验从普通电商变成珠宝鉴赏和交易平台 |
| P0 | 商品详情升级 | 一物一档、鉴赏理由、证书、材质、适用场景 |
| P0 | 首页重构 | 从分类商品流改成甄选、故事、AI 导购、信任入口 |
| P1 | 清理乱码提示 | 后端错误文案和日志恢复专业感 |
| P1 | 支付模式边界 | 保留人工支付，移除或保护测试自动确认 |
| P1 | 项目文件整理 | 视觉稿、截图、临时文件归档，不让根目录继续膨胀 |
| P1 | Cursor 规则落地 | 建立 `.cursor/rules` 或在 Cursor 中配置等价规则 |
| P2 | 后台体验增强 | 待处理事项、风险提示、对账效率 |
| P2 | 监控和崩溃采集 | 正式商业化前补齐 |

### 暂缓事项

| 事项 | 暂缓原因 |
|------|------|
| 微信支付/支付宝真实支付 | 当前产品质感和信任链路更优先，支付资质和风控成本高 |
| 大规模营销活动 | 现在做促销会加重“点单小程序”感 |
| 复杂会员体系 | 容易堆功能，暂时不能提升珠宝交易信任 |
| 多端花哨适配 | 先把 Web/Android 主链路做扎实 |

---

## 11. 下一轮开发的 Definition of Done

下一轮如果目标是“把产品做精”，建议完成标准不是页面数量，而是下面这些结果：

- 首页一眼能看出这是珠宝/玉石平台，不是普通商城。
- 商品详情能回答用户“为什么这件值得买/值得看”。
- AI 在商品页和结算前能提供有上下文的建议。
- 支付文案明确是人工确认，不假装已有三方支付。
- 后台能清楚告诉管理员今天该处理哪些订单和支付。
- 新增页面继续遵守 Liquid Glass，但不重复套同一种卡片。
- 关键流程至少覆盖登录、浏览、详情、购物车、下单、人工支付、后台确认、订单状态。
- 文档同步更新，不把重要设计只留在聊天记录里。
