# 汇玉源珠宝智能交易平台 - 实施计划

> 📍 **唯一活跃规划文档** | 最后更新: 2026-02-23（全面修订版，含上架路线图）

---

## 📋 项目概述

汇玉源是一款专为珠宝行业设计的智能交易平台，集成 DeepSeek AI 技术，服务于：
- **B端用户**：操作员（商务拓展）和管理员
- **C端用户**：个人消费者

## 技术选型

| 层级 | 技术 | 说明 |
|------|------|------|
| **前端框架** | Flutter 3.x (Dart) | 跨平台 UI 开发 |
| **状态管理** | Riverpod 2.x | 响应式状态管理 |
| **本地存储** | SharedPreferences | 轻量级数据持久化 |
| **网络请求** | Dio | HTTP 客户端 |
| **AI 服务** | DeepSeek API + DashScope（通义千问VL） | 三级冗余智能对话 + 图片识别 |
| **设计风格** | Liquid Glass (毛玻璃 + 渐变) | 高端珠宝品牌调性 |
| **国际化** | 自研 (ref.tr() + Riverpod) | 简体中文/繁体中文/英文 |

---

## 🛠️ 技术架构

```
┌──────────────────────────────────────────────────────────────┐
│                        Flutter App                           │
├──────────────────────────────────────────────────────────────┤
│  UI Layer       │ Screens / Widgets / Themes (Liquid Glass)  │
├──────────────────────────────────────────────────────────────┤
│  State Layer    │ Riverpod Providers                         │
├──────────────────────────────────────────────────────────────┤
│  Service Layer  │ AIService / StorageService / PaymentService│
├──────────────────────────────────────────────────────────────┤
│  Data Layer     │ Models / DTOs / Repositories               │
├──────────────────────────────────────────────────────────────┤
│  External       │ DeepSeek API / Gemini API / Backend API / Firebase    │
└──────────────────────────────────────────────────────────────┘
```

---

## 📅 实施阶段

### ✅ 阶段一：基础架构 (已完成)
- [x] Flutter 项目重构 + SDK 配置
- [x] 主题系统 (JewelryTheme + 深色/浅色模式)
- [x] 状态管理 (Riverpod)
- [x] AI 服务 (DeepSeek API 集成)
- [x] 本地存储服务

### ✅ 阶段二：核心界面 (已完成)
- [x] 登录/注册、商城、商品详情、购物车
- [x] 订单管理、收藏、浏览记录、搜索
- [x] AI 助手、操作员工作台、管理员后台
- [x] 个人中心、地址管理、AR试戴

### ✅ 阶段三：功能增强 (已完成)
- [x] 真实商品/商家数据填充
- [x] 多语言国际化 (三语言)
- [x] 深色模式全面适配
- [x] AI 流式输出 + 编码修复
- [x] API 密钥安全管理

### ✅ 阶段四：测试 (已完成)
- [x] 单元测试/集成测试/真机测试指南
- [x] 代码质量 (0 error, 0 warning)

### ✅ 阶段五：功能完善 (2026-02-22 完成)
- [x] 登录验证码修复 (useMockApi=true，万能验证码 8888 正常工作)
- [x] Google Gemini API 集成 (gemini-2.0-flash-exp，流式+非流式均支持)
- [x] DeepSeek + Gemini 三级降级策略 (DeepSeek → Gemini → 离线)
- [ ] 图片上传服务 (阿里云 OSS 对接)

### 📋 阶段六：后端部署 (待执行)
- [ ] FastAPI 部署到云服务器
- [ ] 前端数据源切换到真实 API
- [ ] 数据库 + Redis 配置
- [ ] 短信验证码服务

### 📋 阶段七：上线 (审核通过后)
- [ ] 微信支付/支付宝支付 ⏳ 资质申请中
- [ ] Firebase 推送
- [ ] 区块链溯源
- [ ] 应用商店上架
- [ ] 域名 + HTTPS + 安全审计

---

## ⚠️ 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| DeepSeek API 不稳定 | 高 | 已接入 Gemini 作为备用，三级冗余降级 |
| 支付接口安全 | 高 | 服务端签名验证，敏感数据不落地 |
| 应用商店审核 | 中 | 已准备隐私政策、用户协议 |
| 依赖版本冲突 | 中 | 锁定版本，定期升级测试 |

---

## 📅 里程碑（更新）

| 阶段 | 预计完成 | 状态 |
|------|----------|------|
| 基础架构 + 核心界面 | 2026-02-06 | ✅ 完成 |
| 功能增强 + 测试 | 2026-02-15 | ✅ 完成 |
| 功能完善 | 2026-02-22 | ✅ 完成 |
| 阶段六：登录重构 + 后端部署 | 2026-03-08 | 📋 计划中 |
| 阶段七：支付 + 客服系统 | 2026-03-22 | 📋 计划中 |
| 阶段八：安全审计 + 上架准备 | 2026-04-05 | 📋 计划中 |
| 阶段九：应用商店正式上架 | 2026-04-15 | 📋 目标 |

---

# ══════════════════════════════════════════
# 🚀 全面开发计划 — 当前到应用商店上架（2026-02-22 制定）
# ══════════════════════════════════════════

> **代码现状摘要**：Flutter 前端已完成 97% 功能（21+ 页、全量测试通过、0错误），后端 FastAPI 骨架存在但尚未部署。支付资质申请中，`useMockApi=true` 模式运行。核心缺口：①登录为 Mock 模式；②后端未上云；③支付未对接真实接口；④无真实短信验证码。

---

## 阶段六：登录系统重构 + 后端部署（2026-02-23 → 2026-03-08）

### 6.1 手机验证码登录系统重构

#### 现状分析
- 当前 `useMockApi = true`，验证码固定为 `8888`
- `login_screen.dart` 已有 UI，但 `api_service.dart` 中登录走 Mock 分支
- `main.py` 后端有 `/api/auth/login` 端点，但缺少 `/api/auth/send-sms` 路由
- 无真实短信服务商接入

#### 6.1.1 短信服务技术选型

| 方案 | 优点 | 缺点 | 推荐 |
|------|------|------|------|
| **阿里云短信 SMS** | 稳定、国内覆盖广、文档完善 | 需企业资质认证 | ✅ **首选** |
| 腾讯云短信 | 与微信生态联动好 | 审核周期较长 | 备选 |
| 网易云信 | 接入简单 | 价格较高 | 备选 |

#### 6.1.2 后端实现步骤（FastAPI / `main.py`）

```python
# 新增依赖
# requirements.txt 追加：
# aliyun-python-sdk-core==2.15.1
# aliyun-python-sdk-dysmsapi==2.3.3
# redis==5.0.1

# 新增路由
POST /api/auth/send-sms
  - 参数: { phone: str }
  - 逻辑:
    1. 验证手机号格式（正则）
    2. 检查同一号码60秒内是否已发送（Redis记录 key=sms:{phone}）
    3. 生成6位随机验证码
    4. 调用阿里云SDK：AlibabaCloud.send_sms()
    5. 将验证码写入 Redis，TTL=300秒 (key=sms_code:{phone})
    6. 记录发送日志（防刷统计）
  - 返回: { success: bool, expires_in: 300 }

POST /api/auth/verify-sms
  - 参数: { phone: str, code: str }
  - 逻辑:
    1. 从 Redis 读取 sms_code:{phone}
    2. 安全比对（防时序攻击，使用 hmac.compare_digest）
    3. 验证通过后删除 Redis 中的 code（一次性）
    4. 查询数据库：手机号已注册 → 返回Token；未注册 → 自动创建账号
    5. 生成 JWT（access_token 2h + refresh_token 7d）
  - 返回: { token, refresh_token, user, is_new_user }
```

**防刷安全措施：**
- 同一手机号：60秒冷却 + 每日上限10次（Redis 计数）
- 同一 IP：每分钟不超过5次（Nginx 层限流）
- 验证码错误超过5次：锁定该手机号30分钟
- 所有短信操作记录日志

#### 6.1.3 前端改造步骤（Flutter）

**修改 `api_config.dart`：**
```dart
// 新增路由
static const String authSendSms = '/api/auth/send-sms';
static const String authVerifySms = '/api/auth/verify-sms';

// 切换到真实 API 时（部署后）：
static const bool useMockApi = false; // ← 关键开关
```

**修改 `login_screen.dart`（手机验证码 Tab）：**
- 添加倒计时按钮（60秒冷却，`_countdown` 状态变量）
- 验证码输入框：6位数字限制，自动聚焦
- 发送前校验手机号正则：`RegExp(r'^1[3-9]\d{9}$')`
- 错误提示本地化（`ref.tr()`）

**修改 `auth_provider.dart`：**
```dart
// 新增方法
Future<void> sendSmsCode(String phone) async {
  // 调用 ApiService.post('/api/auth/send-sms', {'phone': phone})
}

Future<void> loginWithSms(String phone, String code) async {
  // 调用 ApiService.post('/api/auth/verify-sms', {'phone': phone, 'code': code})
  // 成功后更新 UserState，持久化 Token
}
```

#### 6.1.4 用户注册/登录合一逻辑
- 首次使用手机号 → 后端自动注册（无需单独注册流程）
- 返回 `is_new_user: true` → 前端跳转完善资料页（昵称、用户类型选择）
- 管理员/操作员入口保留密码登录（不走短信）

#### 6.1.5 Token 安全管理
- access_token 存入 Flutter `flutter_secure_storage`（而非 SharedPreferences）
- refresh_token 同样加密存储
- Token 到期前60秒自动静默刷新（在 `api_service.dart` 拦截器中已有骨架，补全逻辑）

---

### 6.2 后端云服务器部署方案

#### 6.2.1 服务器选型

| 指标 | 推荐配置 | 说明 |
|------|---------|------|
| **云服务商** | 阿里云 ECS | 国内访问速度最优，与 OSS/SMS 同生态 |
| **规格** | 2核 4GB 内存 | 初期足够，可按需升配 |
| **存储** | 系统盘 40GB SSD + OSS | 代码+DB 本地，图片走 OSS |
| **带宽** | 5 Mbps 固定 | 按需升级 |
| **系统** | Ubuntu 22.04 LTS | 长期支持，社区生态完善 |
| **区域** | 华东（上海）| 覆盖全国最均衡 |

**预估月成本：** ¥200–350（ECS + 弹性IP + OSS + 短信费用）

#### 6.2.2 服务器环境配置清单

```bash
# 1. 基础环境
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3.11 python3.11-venv python3-pip nginx redis-server

# 2. 数据库（PostgreSQL 16）
sudo apt install -y postgresql-16
sudo -u postgres createdb huiyuyuan
sudo -u postgres createuser huiyuyuan_user

# 3. 应用部署
cd /srv/huiyuyuan
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Gunicorn + uvicorn 运行
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 --daemon

# 5. Nginx 反向代理（含 SSL）
# /etc/nginx/sites-available/huiyuyuan
server {
    listen 443 ssl http2;
    server_name api.huiyuyuan.com;
    ssl_certificate /etc/letsencrypt/.../fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/.../privkey.pem;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header X-Real-IP $remote_addr;
    }
    # 限流
    limit_req_zone $binary_remote_addr zone=api:10m rate=20r/s;
    limit_req zone=api burst=50 nodelay;
}
```

#### 6.2.3 数据库设计方案

**核心表结构（PostgreSQL）：**

```sql
-- 用户表
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(11) UNIQUE NOT NULL,
  username VARCHAR(50),
  avatar_url TEXT,
  user_type VARCHAR(20) DEFAULT 'consumer', -- consumer/operator/admin
  balance DECIMAL(12,2) DEFAULT 0,
  points INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

-- 商品表
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL,
  original_price DECIMAL(12,2),
  category VARCHAR(50),
  material VARCHAR(100),
  images JSONB DEFAULT '[]',
  stock INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 5.0,
  sales_count INTEGER DEFAULT 0,
  is_hot BOOLEAN DEFAULT false,
  is_new BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 订单表
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_no VARCHAR(32) UNIQUE NOT NULL, -- HYY + timestamp + random
  user_id UUID REFERENCES users(id),
  status VARCHAR(30) DEFAULT 'pending_payment',
  -- pending_payment/paid/shipped/delivered/completed/cancelled/refunding/refunded
  total_amount DECIMAL(12,2) NOT NULL,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  shipping_fee DECIMAL(8,2) DEFAULT 0,
  address_snapshot JSONB, -- 快照，防地址修改影响历史
  remark TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  shipped_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

-- 订单商品表
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_snapshot JSONB NOT NULL, -- 快照
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL
);

-- 支付记录表
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id),
  payment_method VARCHAR(20), -- wechat/alipay/balance
  amount DECIMAL(12,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  transaction_id VARCHAR(100), -- 第三方流水号
  raw_response JSONB, -- 原始回调数据（审计用）
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- 购物车表
CREATE TABLE cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  quantity INTEGER DEFAULT 1,
  selected BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- 索引优化
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_cart_user ON cart_items(user_id);
```

#### 6.2.4 Redis 使用规划

| Key 模式 | TTL | 用途 |
|----------|-----|------|
| `sms_code:{phone}` | 300s | 验证码 |
| `sms_count:{phone}:{date}` | 86400s | 每日发送次数计数 |
| `sms_lock:{phone}` | 3600s | 错误超限锁定 |
| `user_token:{user_id}` | 7200s | Token 黑名单（退出登录） |
| `product_cache:{id}` | 3600s | 商品详情缓存 |
| `hot_products` | 1800s | 热门商品列表缓存 |

---

### 6.3 CI/CD 流程规划

```
开发者 push → GitHub
    ↓
GitHub Actions (CI：flutter test + python test)
    ↓ 通过
自动 SSH 到服务器，git pull + restart gunicorn
    ↓
Nginx 无缝转发（零宕机）
```

**GitHub Actions 工作流（`.github/workflows/deploy.yml`）：**

```yaml
name: Deploy to Production
on:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter test
  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /srv/huiyuyuan
            git pull origin main
            source venv/bin/activate
            pip install -r requirements.txt --quiet
            sudo systemctl restart gunicorn
```

---

## 阶段七：电商核心功能完善（2026-03-09 → 2026-03-22）

### 7.1 真实商品交易系统

#### 现状
- 前端购物车/结算流程已完成，使用本地 Mock 数据
- `product_service.dart` 存在但接口未对接真实后端
- `CartScreen` 已实现完整 UI 和本地状态

#### 待完成任务

**商品数据云端化：**
1. 将 `lib/data/` 中的硬编码商品数据迁移至 PostgreSQL
2. 后端实现分页接口：`GET /api/products?page=1&size=20&category=&sort=`
3. 前端 `product_service.dart` 关闭 `useMockApi` 后自动切换

**购物车云端同步：**
1. 用户登录后触发：`POST /api/cart/sync`（本地购物车 → 云端合并）
2. 跨设备登录保持购物车一致性
3. Riverpod `cartProvider` 改为服务端驱动（乐观更新 UI 保持流畅）

**结算流程强化：**
```
选择商品 → 确认地址 → 选择优惠券 → 确认支付金额 → 调用支付 → 等待回调 → 展示结果
                                                        ↑
                                               后端创建订单（防重：幂等 key）
```

### 7.2 订单管理系统完整流程

#### 全状态机实现

```
待支付 ──(超30分钟未付)──→ 自动取消
  ↓ 支付成功
待发货 ──(手动发货)──→ 已发货
  ↓ 物流更新
运输中 ──(签收)──→ 已签收 ──(7天自动)──→ 已完成
  ↓ 申请退款（任意阶段）
退款审核 ──(拒绝)──→ 原状态
  ↓ 通过
退款中 ──(退款成功)──→ 已退款
```

**后端需新增/完善的接口：**

| 接口 | 方法 | 描述 |
|------|------|------|
| `/api/orders` | POST | 创建订单（含库存原子扣减） |
| `/api/orders/{id}/pay` | POST | 发起支付（创建 payment 记录） |
| `/api/orders/{id}/confirm-receipt` | POST | 用户确认收货 |
| `/api/orders/{id}/refund` | POST | 申请退款 |
| `/api/orders/{id}/cancel` | POST | 取消订单（未付款） |
| `/api/orders/{id}/logistics` | GET | 查询物流（对接快递100 API） |
| `/api/admin/orders/{id}/ship` | POST | 管理员填写快递单号 |
| `/api/admin/orders/{id}/refund` | PUT | 处理退款审核 |

**库存原子扣减（防超卖）：**
```sql
-- 使用 PostgreSQL 行锁
BEGIN;
SELECT stock FROM products WHERE id=? FOR UPDATE;
-- 检查 stock >= quantity
UPDATE products SET stock = stock - ? WHERE id=? AND stock >= ?;
COMMIT;
-- 若 UPDATE 影响行数=0，回滚并返回"库存不足"
```

**订单号生成规则：**
- 格式：`HYY` + `yyyyMMddHHmmss` + 6位随机数
- 示例：`HYY20260309143025123456`
- 后端幂等控制：同一用户+同一商品组合+5分钟内，返回已有未付款订单

### 7.3 客服系统实现

#### 技术方案

**方案比较：**

| 方案 | 特点 | 推荐 |
|------|------|------|
| **自建 WebSocket** | 完全可控，成本低 | ✅ **推荐（初期）** |
| 环信 IM / 融云 | 功能完整，快速接入 | 升级选项 |
| 微信客服 | 仅限微信渠道 | 不推荐 |

**WebSocket 客服方案架构：**

```
用户 App ←─── WebSocket ───→ FastAPI (websockets)
                                  ↓
                             Redis Pub/Sub
                                  ↓  
                          客服工作台（Web管理后台）
```

**后端实现（FastAPI）：**
```python
# 新增依赖：websockets, redis

@app.websocket("/ws/chat/{session_id}")
async def chat_endpoint(websocket: WebSocket, session_id: str):
    await manager.connect(websocket, session_id)
    try:
        while True:
            data = await websocket.receive_json()
            # 保存消息到 DB
            await save_message(session_id, data)
            # 转发给客服（Redis Pub/Sub）
            await redis.publish(f"cs_session:{session_id}", json.dumps(data))
    except WebSocketDisconnect:
        manager.disconnect(session_id)
```

**消息类型支持：**
- 文字消息（即时）
- 图片消息（上传到 OSS 后发送 URL）
- 订单卡片（内嵌订单快照，一键跳转详情）
- 系统消息（自动回复、关闭会话等）

**前端（Flutter）：**
- 新建 `customer_service_screen.dart`
- 使用 `web_socket_channel` package（已在生态圈内）
- AI 自动分流：简单问题 → DeepSeek/Gemini 自动回答；复杂投诉 → 转人工

**客服工单系统：**

```sql
CREATE TABLE cs_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  status VARCHAR(20) DEFAULT 'open', -- open/assigned/resolved/closed
  category VARCHAR(50), -- refund/product/delivery/other
  assigned_to UUID REFERENCES users(id), -- 客服人员
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE TABLE cs_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES cs_sessions(id) ON DELETE CASCADE,
  sender_type VARCHAR(10) NOT NULL, -- user/agent/system/ai
  sender_id UUID,
  content TEXT,
  message_type VARCHAR(20) DEFAULT 'text', -- text/image/order_card/system
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**SLA 指标目标：**
- 首响应时间 ≤ 2分钟（工作时间）
- 问题解决率 ≥ 85%（24小时内）
- AI 自动解决率目标 ≥ 40%

---

## 阶段八：支付集成 + 安全审计（2026-03-23 → 2026-04-05）

### 8.1 支付接口对接

#### 微信支付（App 支付）

**前置条件：**
1. 微信开放平台账号（已创建 App 应用）
2. 微信支付商户号（资质：营业执照 + 银行卡）
3. 在微信开放平台绑定：App ID ↔ 商户号

**后端签名流程（后端必须处理，不可在前端）：**
```python
# /api/pay/wechat/create-order
def create_wechat_order(order_id, amount, openid=None):
    params = {
        "appid": WECHAT_APP_ID,
        "mchid": WECHAT_MCH_ID,
        "description": "汇玉源珠宝订单",
        "out_trade_no": order_id,
        "amount": {"total": int(amount * 100), "currency": "CNY"},
        "notify_url": "https://api.huiyuyuan.com/api/pay/wechat/callback",
    }
    # 使用商户私钥签名（RSA-256）
    return wechatpay.pay(params)

# /api/pay/wechat/callback (POST)
def wechat_callback(request):
    # 1. 验证微信签名
    # 2. 解密通知内容
    # 3. 幂等处理：transaction_id 唯一
    # 4. 更新 orders.status = 'paid', payments.status = 'success'
    # 5. 触发 Firebase 推送通知
    return {"code": "SUCCESS", "message": "成功"}
```

**前端集成（Flutter）：**
- 使用 `pay` 或 `tobias` package（封装微信/支付宝唤起）
- 支付成功后轮询后端状态（5秒一次，最多12次 = 60秒）
- `payment_service.dart` 中 `createWechatPayment()` 已有骨架，补全实现

#### 支付宝（App 支付）
- 使用 Flutter `tobias` package
- 后端使用 `alipay-sdk-python3`
- 签名方式：RSA2（比微信更简单）
- 回调验签：`alipay.verify(data, signature)`

#### 安全规范
- **绝对禁止**：支付密钥、商户私钥出现在 Flutter 代码中
- 所有签名计算在后端完成
- 回调地址必须是 HTTPS
- 支付金额以订单数据库记录为准（防客户端篡改）
- 退款需要双重审核（操作员+管理员）

### 8.2 安全审计清单

#### 接口安全
- [ ] 所有需要登录的接口检查 JWT（`Authorization: Bearer <token>`）
- [ ] JWT 密钥使用 256位随机字符串，存放在服务器环境变量（非代码）
- [ ] 管理员接口额外检查用户角色（`user_type == 'admin'`）
- [ ] 接口请求频率限制（Nginx + Redis）
- [ ] SQL 使用 ORM/参数化查询，禁止拼接（防 SQL 注入）
- [ ] 文件上传：限制类型（jpg/png/webp）、大小（≤10MB）、重命名存储

#### 数据安全
- [ ] HTTPS 全程加密（Let's Encrypt 免费证书，自动续期）
- [ ] 敏感字段加密：手机号在日志中脱敏（`138****6669`）
- [ ] 数据库每日自动备份到 OSS（保留30天）
- [ ] 用户密码（管理员/操作员）bcrypt 哈希存储
- [ ] 禁止明文存储验证码（Redis 中存 bcrypt_hash(code)）

#### Flutter 客户端安全
- [ ] API Key（DeepSeek/Gemini）使用 `--dart-define` 传入，不进代码仓库
- [ ] Token 使用 `flutter_secure_storage`（加密 Keychain/Keystore）
- [ ] Release 版本开启混淆（`flutter build apk --obfuscate --split-debug-info`）
- [ ] 禁用 Android Debug Bridge 调试（`android:debuggable="false"`）
- [ ] 证书绑定（可选，高安全场景）

#### 隐私合规
- [ ] 隐私政策包含：数据收集范围、使用目的、第三方共享、删除权利
- [ ] 首次启动弹出隐私协议弹窗，用户明确同意后才收集数据
- [ ] 隐私政策页面在应用内可访问（`/profile` → 设置 → 隐私政策）
- [ ] 遵循《个人信息保护法》（PIPL）要求

---

## 阶段九：应用商店上架准备（2026-04-06 → 2026-04-15）

### 9.1 材料准备清单

#### 通用材料（各应用商店均需）

| 材料 | 规格要求 | 状态 |
|------|---------|------|
| 应用图标 | 1024×1024 PNG（无透明通道） | ⬜ 待制作 |
| 启动图 | 各平台尺寸（见下） | ⬜ 待制作 |
| 应用截图 | 手机端6-8张，平板2张（1080×1920 或以上） | ⬜ 待截图 |
| 应用简介 | ≤80字（吸引眼球，含关键词） | ⬜ 待撰写 |
| 应用详细描述 | ≤4000字，含功能说明 | ⬜ 待撰写 |
| 隐私政策 URL | 需可公开访问的 HTTPS 链接 | ⬜ 待上线 |
| 用户协议 URL | 同上 | ⬜ 待上线 |
| 涉及特殊权限说明 | 相机（AR试戴）、存储（图片保存） | ⬜ 待填写 |

#### 应用截图建议场景
1. 商城首页（精美珠宝展示）
2. 商品详情页（AI 描述 + 多图）
3. AR 虚拟试戴效果
4. AI 智能客服对话
5. 订单管理页
6. 个人中心/资产页

### 9.2 各平台上架要求

#### 华为应用市场（AppGallery）
- 必须使用华为 `agconnect-services.json` 替换 Firebase（国内环境）
- 推送：使用华为 HMS Push Kit 替代 FCM
- 支付：可选接入 Huawei Pay（需额外资质）
- 隐私弹窗：必须在 `main()` 启动的第一个操作
- **敏感权限**：需在应用内弹窗说明用途（相机权限前必须解释）
- 审核周期：3-7 个工作日

#### 小米应用商店（GetApps）
- 需提供 `小米开放平台` 账号
- 功能测试账号：需提供测试用手机号+验证码（提交时说明测试账号）
- APK 大小 ≤ 200MB（Flutter Release 通常 30-60MB，满足）
- 审核周期：1-3 个工作日

#### OPPO 应用市场（ColorOS Software Store）  
- 需 OPPO 开放平台企业账号
- 含虚拟财产/支付功能需额外资质审核
- 审核周期：3-5 个工作日

#### 应用宝（腾讯）
- 腾讯开放平台企业认证
- 含支付功能需提供《支付许可》截图
- 微信分享/登录需要绑定微信 AppID
- 审核周期：3-5 个工作日

#### App Store（iOS）
- 需 Apple Developer Program（¥688/年）
- 含收付款功能必须支持 Apple Pay 或使用 Apple 内购
- **关键陷阱**：直接支付（微信/支付宝）在 iOS 需要特殊处理（数字商品必须走内购）
- 实物商品（珠宝）可以走微信/支付宝，需在描述中明确说明是实物
- 隐私标签（Privacy Nutrition Labels）需如实填写
- 审核周期：1-3 个工作日（有时更长）

### 9.3 上架前技术检查清单

#### Android（Flutter）
```bash
# 1. 生成正式签名密钥（仅一次，密钥文件务必备份！）
keytool -genkey -v -keystore huiyuyuan.jks \
  -alias huiyuyuan -keyalg RSA -keysize 2048 -validity 36500

# 2. 配置 android/app/build.gradle.kts
signingConfigs {
    create("release") {
        storeFile = file("huiyuyuan.jks")
        storePassword = System.getenv("KEYSTORE_PASSWORD")
        keyAlias = "huiyuyuan"
        keyPassword = System.getenv("KEY_PASSWORD")
    }
}

# 3. 构建发布包（App Bundle 优先，APK 备用）
flutter build appbundle --release \
  --dart-define=DEEPSEEK_API_KEY=xxx \
  --dart-define=GEMINI_API_KEY=xxx \
  --obfuscate --split-debug-info=build/debug-info

# 4. 检查 APK/AAB 大小（目标 < 60MB）
# 5. 验证无 debug 标志
```

#### iOS
```bash
# 1. Xcode 配置 Bundle ID：com.huiyuyuan.app
# 2. 配置推送证书（APNs）
# 3. 构建
flutter build ipa --release \
  --dart-define=DEEPSEEK_API_KEY=xxx \
  --dart-define=GEMINI_API_KEY=xxx \
  --obfuscate --split-debug-info=build/debug-info
```

#### 版本号规范
- `pubspec.yaml`：`version: 1.0.0+1`（格式：`版本名+版本号`）
- 每次提交审核必须递增 `versionCode`（+1 整数）
- 语义化版本：`主版本.次版本.补丁`

### 9.4 上架后运维监控方案

#### 崩溃监控
- 接入 **Firebase Crashlytics**（免费，实时崩溃上报）
- 配置 Dart 异常捕获：
```dart
void main() {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  runZonedGuarded(
    () => runApp(const ProviderScope(child: App())),
    FirebaseCrashlytics.instance.recordError,
  );
}
```

#### 性能监控
- Firebase Performance Monitoring（网络请求耗时、页面加载时间）
- 后端：Prometheus + Grafana 监控 API 响应时间、错误率、QPS

#### 用户行为分析
- Firebase Analytics（埋点：页面访问、商品点击、加购、支付转化漏斗）

#### 告警机制
- 服务器 CPU > 80%：发送邮件/短信告警
- 接口错误率 > 5%：30秒内告警
- 数据库连接池耗尽：立即告警

#### 版本更新策略
- **强制更新**：安全漏洞修复，弹窗强制升级（无"稍后"选项）
- **建议更新**：功能更新，可跳过
- 告知方式：`GET /api/app/version-check` 接口（含 `force_update` 字段）

---

## 开发优先级总结

### 🔴 P0 — 阻塞上线（必须完成）

| 任务 | 预计工时 | 负责模块 |
|------|---------|---------|
| 短信验证码服务（阿里云 SMS + Redis） | 2天 | 后端 + 前端 |
| FastAPI 部署到云服务器 | 2天 | 后端/运维 |
| PostgreSQL 数据库上云 + 数据迁移 | 1天 | 后端 |
| 前端 `useMockApi → false` 对接 | 2天 | 前端 |
| HTTPS 证书配置（Let's Encrypt） | 0.5天 | 运维 |
| 签名密钥管理（Android 签名 + iOS 证书） | 1天 | 发布 |
| 隐私政策 + 用户协议上线 | 1天 | 产品/前端 |

### 🟡 P1 — 上线同期（首发版本含）

| 任务 | 预计工时 | 负责模块 |
|------|---------|---------|
| 微信支付/支付宝对接（资质就绪后） | 3天 | 后端 + 前端 |
| 客服 WebSocket 系统 | 4天 | 后端 + 前端 |
| 购物车/订单云端数据同步 | 2天 | 后端 + 前端 |
| Firebase Crashlytics 集成 | 0.5天 | 前端 |
| 应用截图 + 商店素材制作 | 2天 | 设计 |
| 各商店账号注册 + 应用提交 | 1天 | 运营 |

### 🟢 P2 — 上线后迭代（v1.1.0+）

| 任务 | 预计工时 | 负责模块 |
|------|---------|---------|
| 区块链溯源证书展示 | 5天 | 后端 + 前端 |
| 阿里云 OSS 图片上传（商家发布商品） | 2天 | 后端 + 前端 |
| Firebase 推送通知（订单状态） | 2天 | 前端 |
| 物流查询对接（快递100 API） | 2天 | 后端 + 前端 |
| AI 多模态图片输入（识别珠宝真伪） | 5天 | 后端 + 前端 |

---

## 风险评估（更新）

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|---------|
| 支付资质审核迟缓 | 高 | 中 | 先上线余额支付（无需资质），支付宝/微信资质就绪后热更新 |
| 应用商店审核驳回 | 中 | 低 | 提前阅读各平台审核指南，准备商品实物说明；用测试账号供审核员体验 |
| 阿里云SMS发送失败（运营商拦截） | 高 | 低 | 备用腾讯云SMS；超时60秒后提示用户重试；保留 8888 万能码仅用于演示环境 |
| 数据库性能瓶颈 | 中 | 低 | 合理索引 + Redis缓存热点数据；初期2C4G可承载约500并发 |
| DeepSeek/Gemini API 限流 | 中 | 中 | 三级冗余已实现（DeepSeek→Gemini→离线）；可缓存高频问答 |
| iOS Apple Pay 强制要求 | 高 | 中 | 珠宝属于实物商品，明确说明可绕过 IAP；准备苹果审核答复模板 |
| 隐私合规问题（PIPL） | 高 | 低 | 隐私政策委托法律顾问审核；首启动强制同意弹窗 |

---

*最后更新: 2026-02-23 | 全面修订版含上架路线图*
