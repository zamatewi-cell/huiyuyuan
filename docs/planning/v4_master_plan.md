# 汇玉源 v4.0 — 多Agent协同开发总体规划

> 制定时间: 2026-02-27
> 基于: 全量代码审计 (28屏幕/12服务/5Provider/49端点/16测试)
> 当前状态: **原型演示阶段** → 目标: **生产就绪 (Production-Ready)**

---

## 〇、现状诊断（一句话）

> **前端 UI 和架构质量出色 (4/5)，但后端基础设施处于演示阶段 (1.5/5)。**
> 核心缺陷: 内存存储重启丢数据 | 支付全假 | 安全漏洞多 | 28屏幕零Widget测试 | 后端单文件2246行

### 量化现状

| 维度 | 当前 | 目标 |
|------|------|------|
| 后端数据存储 | 内存字典 (重启=清零) | PostgreSQL 持久化 |
| 安全评分 | ★☆☆☆☆ (CORS */硬编码密钥/SMS 8888) | ★★★★☆ |
| 支付系统 | 全占位符 (`wx_your_app_id`) | 模拟支付可测试 + 真实支付预留接口 |
| 测试覆盖 | 前端16文件, 后端0 | 前端+Widget+后端 pytest |
| 后端架构 | main.py 单文件 2246行 | 模块化 routers/models/services |
| HTTPS | 已启用 `xn--lsws2cdzg.top` | Let's Encrypt + Nginx |

---

## 一、Agent 身份定义

### Agent A — 后端架构师
**职责**: 后端从"玩具"到"生产"的全面升级
**技能要求**: Python/FastAPI/SQLAlchemy/PostgreSQL/Redis/安全
**工作范围**: `backend/` 目录
**不碰**: `lib/` 目录 (前端代码)

### Agent B — 前端质量工程师
**职责**: 消灭所有假数据/Stub/硬编码，打通前后端数据流
**技能要求**: Flutter/Dart/Riverpod/HTTP集成
**工作范围**: `lib/screens/`, `lib/services/`, `lib/providers/`
**不碰**: `backend/` 目录

### Agent C — 测试与安全专家
**职责**: 补全测试覆盖 + 安全加固 + CI/CD强化
**技能要求**: Flutter测试/pytest/安全审计
**工作范围**: `test/`, `backend/tests/`, `.github/workflows/`, 安全配置
**不碰**: 核心业务逻辑实现

### Agent D — DevOps与运维
**职责**: 服务器环境、数据库初始化、SSL、监控、备份
**技能要求**: Linux/Nginx/PostgreSQL/Redis/systemd/certbot
**工作范围**: 服务器 `xn--lsws2cdzg.top`（原 IP: `47.98.188.141`）、`scripts/`、`backend/*.conf`
**不碰**: 业务代码

---

## 二、Phase 1 — 地基加固 (P0 Critical, 预计3天)

> **目标**: 解决"服务重启=数据全丢"和"最严重安全漏洞"

### Agent A — 后端架构师 任务清单

#### A1. 后端模块化拆分 (Day 1)
**当前**: `main.py` 单文件 2246 行，包含所有路由/模型/存储
**目标**: 按领域拆分为模块化结构

```
backend/
├── main.py              # 仅 app 入口 + 中间件 (~100行)
├── config.py            # 环境变量 + 配置类
├── database.py          # SQLAlchemy engine/session
├── models/
│   ├── user.py          # SQLAlchemy 用户表
│   ├── product.py       # 商品表
│   ├── order.py         # 订单表
│   ├── cart.py          # 购物车表
│   └── review.py        # 评价表
├── routers/
│   ├── auth.py          # /api/auth/*
│   ├── products.py      # /api/products/*
│   ├── orders.py        # /api/orders/*
│   ├── cart.py          # /api/cart/*
│   ├── users.py         # /api/users/*
│   ├── admin.py         # /api/admin/*
│   ├── upload.py        # /api/upload/*
│   └── ai.py            # /api/ai/*
├── services/
│   ├── sms_service.py   # 阿里云短信
│   ├── oss_service.py   # OSS STS
│   └── ai_service.py    # DashScope/DeepSeek
├── middleware/
│   ├── auth.py          # JWT 验证中间件
│   └── rate_limit.py    # 限流
└── tests/
    ├── conftest.py       # pytest fixtures
    ├── test_auth.py
    ├── test_products.py
    ├── test_orders.py
    └── test_cart.py
```

**具体步骤**:
1. 创建 `config.py` — 从环境变量读取所有配置，用 Pydantic Settings
2. 创建 `database.py` — SQLAlchemy async engine + session factory
3. 逐个提取 router: auth → products → orders → cart → users → admin → upload → ai
4. 每提取一个 router 后运行 `curl /api/health` 验证不破坏现有功能
5. 最后删除原 `main.py` 中的已迁移代码

**验收标准**:
- [ ] `main.py` <= 100 行
- [ ] 所有 49 个端点仍可正常访问
- [ ] `curl /api/health` 返回 200

#### A2. PostgreSQL 数据持久化 (Day 1-2)
**当前**: 6个内存字典 (PRODUCTS_DB, ORDERS_DB, USERS_DB, CARTS_DB, PAYMENTS_DB, FAVORITES_DB)
**目标**: SQLAlchemy ORM + PostgreSQL

**数据表设计**:
```sql
-- users (核心)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE,
    nickname VARCHAR(100),
    avatar VARCHAR(500),
    user_type VARCHAR(20) NOT NULL DEFAULT 'customer',  -- admin/operator/customer
    password_hash VARCHAR(255),  -- bcrypt
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- products (商品)
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    original_price DECIMAL(12,2),
    category VARCHAR(50),
    material VARCHAR(50),
    images JSONB DEFAULT '[]',
    stock INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 5.0,
    sales_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- orders (订单)
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_no VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID REFERENCES users(id),
    product_id UUID REFERENCES products(id),
    product_name VARCHAR(200),
    product_image VARCHAR(500),
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(12,2),
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    payment_method VARCHAR(20),
    shipping_address TEXT,
    recipient_name VARCHAR(100),
    recipient_phone VARCHAR(20),
    logistics_company VARCHAR(50),
    tracking_number VARCHAR(100),
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancel_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- cart_items
CREATE TABLE cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    product_id UUID REFERENCES products(id),
    quantity INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- favorites
CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    product_id UUID REFERENCES products(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- reviews
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    product_id UUID REFERENCES products(id),
    order_id UUID REFERENCES orders(id),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    content TEXT,
    images JSONB DEFAULT '[]',
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- addresses
CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    recipient_name VARCHAR(100),
    phone VARCHAR(20),
    province VARCHAR(50),
    city VARCHAR(50),
    district VARCHAR(50),
    detail TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**具体步骤**:
1. 在服务器安装 PostgreSQL 15, 创建数据库 `huiyuyuan`
2. 创建 `backend/models/*.py` SQLAlchemy 模型 (对应上述7张表)
3. 创建 `backend/database.py` 连接管理
4. 逐个迁移 router 从 `内存字典` → `async session + ORM 查询`
5. 用 `init_db.sql` 初始化种子数据 (从 product_data.dart 的静态数据导入)
6. 保留 `DB_AVAILABLE` flag — DB不可用时仍可回退内存 (开发调试用)

**验收标准**:
- [ ] 服务重启后数据不丢失
- [ ] 49 个端点全部通过 PostgreSQL 读写
- [ ] `alembic` or SQL 迁移文件存在

#### A3. 安全加固第一批 (Day 2)
**具体修复**:

| # | 问题 | 修复方案 |
|---|------|----------|
| 1 | CORS `allow_origins=["*"]` | 改为 `["https://xn--lsws2cdzg.top", "https://www.xn--lsws2cdzg.top", "http://localhost:*"]` |
| 2 | JWT Secret 默认值 | 强制从 `.env` 读取，无值则启动报错退出 |
| 3 | SMS 降级固定 `8888` | Redis 不可用时拒绝发送验证码 (返回 503 Service Unavailable) |
| 4 | 密码明文比较 | 引入 `bcrypt`，`verify_password(plain, hashed)` |
| 5 | OSS STS mock 凭据 | 无阿里云配置时返回 501 而非假凭据 |

**验收标准**:
- [ ] 无 `allow_origins=["*"]`
- [ ] 无默认 JWT Secret
- [ ] SMS 无 Redis 时返回 503
- [ ] 用户密码存储为 bcrypt hash

---

### Agent D — DevOps 任务清单

#### D1. PostgreSQL 服务器安装与配置 (Day 1)
```bash
# 在 xn--lsws2cdzg.top 上执行
apt install postgresql-15 postgresql-client-15
sudo -u postgres createuser huiyuyuan_user -P  # 设置强密码
sudo -u postgres createdb huiyuyuan -O huiyuyuan_user
# pg_hba.conf: 仅允许 localhost 连接
# postgresql.conf: listen_addresses = 'localhost'
```

**配置 .env**:
```env
DATABASE_URL=postgresql+asyncpg://huiyuyuan_user:STRONG_PWD@localhost/huiyuyuan
JWT_SECRET_KEY=<生成64位随机字符串>
REDIS_URL=redis://localhost:6379/0
```

#### D2. Redis 安装 (Day 1)
```bash
apt install redis-server
systemctl enable redis-server
# redis.conf: bind 127.0.0.1, requirepass <密码>
```

#### D3. Let's Encrypt SSL (Day 2, 可选 — 需域名)
```bash
apt install certbot python3-certbot-nginx
certbot --nginx -d xn--lsws2cdzg.top -d www.xn--lsws2cdzg.top
# 自动续期: systemctl enable certbot.timer
```

已有生产域名时直接申请正式证书；若无域名，暂时为 IP 配置自签证书或保持 HTTP。

#### D4. 数据库备份脚本 (Day 2)
```bash
# /opt/huiyuyuan/backup.sh
#!/bin/bash
BACKUP_DIR="/opt/huiyuyuan/backups"
pg_dump huiyuyuan | gzip > "$BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).sql.gz"
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete  # 保留7天
```
加入 crontab: `0 3 * * * /opt/huiyuyuan/backup.sh`

**验收标准**:
- [ ] PostgreSQL 运行中，`psql` 可连接
- [ ] Redis 运行中，`redis-cli ping` 返回 PONG
- [ ] `.env` 已配置实际密码
- [ ] 备份脚本每天 3:00 自动执行

---

## 三、Phase 2 — 前端数据集成 (P1 High, 预计2天)

> **目标**: 消灭所有假数据和 Mock，前端全部连接真实后端

### Agent B — 前端质量工程师 任务清单

#### B1. 消灭硬编码数据 (Day 3)

| # | 屏幕 | 当前问题 | 修复方案 |
|---|------|----------|----------|
| 1 | `notification_screen.dart` | `_generateSampleData()` 6条假通知 | 调用 `GET /api/notifications` → 展示真实数据，空时显示 empty state |
| 2 | `shop_radar.dart` | `_loadMockData()` 5个假店铺 | 调用 `GET /api/shops` → 真实数据，保留筛选/排序功能 |
| 3 | `shop_detail_screen.dart` | 硬编码联系记录 | 调用 `GET /api/shops/{id}/contacts` 或本地缓存 |
| 4 | `operator_home.dart` | 硬编码联系记录列表 | 同上 |
| 5 | `browse_history_screen.dart` | 仅显示 "商品 {id}" | 从 `realProductData` 或 API 查找商品名称+图片 |
| 6 | `favorite_list_screen.dart` | 无商品图片 | 确保 ProductModel.images.first 作为 CachedNetworkImage 显示 |
| 7 | `logistics_screen.dart` | 状态生成 mock 节点 | 调用 `GET /api/orders/{id}/logistics` 获取真实物流节点 |

**每个修复的标准模式**:
```dart
// BEFORE (硬编码)
final data = _getMockData();

// AFTER (API 优先 + 降级)
final apiData = ref.watch(xxxProvider);
return apiData.when(
  data: (items) => _buildList(items),
  loading: () => const SkeletonLoader(),
  error: (e, _) => _buildEmptyState('暂无数据'),
);
```

#### B2. Payment Screen 安全修复 (Day 3)
**当前严重问题**:
1. 使用硬编码 `'Bearer mock_token'` 发请求 → 改用 `ApiService` 统一鉴权
2. 轮询 3 次后本地 mock 标记成功 → 改为轮询 30 次 (30s)，超时提示"支付超时，请检查" 而非自动标记成功
3. `simulatePayment` 仅开发环境可用 → 加 `kDebugMode` 判断

#### B3. 客户端硬编码凭据清理 (Day 3)
**当前**: `app_config.dart` 包含 `admin123`/`8888`/`op123456`
**修复**:
1. 移除客户端所有测试凭据（登录界面不再预填）
2. 仅 `kDebugMode` 时在输入框显示 hint 提示测试账号
3. 登录全部走后端认证 API

#### B4. 库存 Provider 持久化 (Day 4)
**当前**: `inventory_provider.dart` 纯内存，从 `realProductData` 初始化
**修复**:
1. 创建 `InventoryService` — 封装 `GET/PUT /api/products/{id}/stock`
2. `InventoryProvider` 改为 API 优先 + 本地降级
3. 增减调操作通过 API 更新后端数据库

#### B5. 评价数据后端同步 (Day 4)
**当前**: `review_service.dart` 纯本地 SharedPreferences
**修复**:
1. `submitReview()` → `POST /api/reviews`
2. `getReviews()` → `GET /api/products/{id}/reviews`
3. 保留本地缓存作为离线降级

---

## 四、Phase 3 — 测试与安全 (P1, 预计2天)

### Agent C — 测试与安全专家 任务清单

#### C1. 后端 pytest 测试 (Day 4-5)

创建 `backend/tests/` 目录:

```python
# conftest.py
import pytest
from httpx import AsyncClient, ASGITransport
from main import app  # 或拆分后的 app

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c

@pytest.fixture
async def auth_headers(client):
    resp = await client.post("/api/auth/login", json={
        "phone": "18937766669", "password": "admin123"
    })
    token = resp.json()["token"]
    return {"Authorization": f"Bearer {token}"}
```

**必须覆盖的端点 (按优先级)**:

| 优先级 | 端点 | 测试场景 |
|--------|------|----------|
| P0 | POST /api/auth/login | 正确凭据/错误密码/不存在用户 |
| P0 | GET /api/products | 列表/过滤/分页/排序 |
| P0 | POST /api/orders | 创建/库存不足/无效商品 |
| P0 | POST /api/orders/{id}/pay | 支付/重复支付/已取消订单 |
| P1 | GET /api/orders | 用户隔离(A看不到B的订单) |
| P1 | POST /api/admin/orders/{id}/ship | 权限(仅admin/operator) |
| P1 | GET /api/cart | CRUD + 数量限制 |
| P2 | POST /api/reviews | 去重/星级范围 |
| P2 | GET /api/orders/stats | 统计准确性 |

**验收标准**:
- [ ] >= 30 个测试用例
- [ ] 核心路径 (认证/商品/订单/支付) 100% 覆盖
- [ ] `pytest --cov` 覆盖率 >= 60%

#### C2. 前端 Widget Test (Day 5)

**需要补充的关键屏幕测试**:

| 屏幕 | 测试要点 |
|------|----------|
| `login_screen.dart` | 三种登录tab切换、表单验证、提交调用 provider |
| `product_list_screen.dart` | 商品渲染、分类过滤、搜索跳转 |
| `cart_screen.dart` | 增删改查、金额计算、空购物车状态 |
| `checkout_screen.dart` | 地址选择、支付方式、提交按钮 |
| `order_list_screen.dart` | 5个tab切换、订单卡片渲染 |

**每个测试的标准结构**:
```dart
testWidgets('商品列表 - 显示商品卡片', (tester) async {
  // 1. 创建 ProviderScope + mock overrides
  // 2. pump widget
  // 3. act (tap/scroll)
  // 4. verify (find.text / find.byType)
});
```

#### C3. CI/CD 安全强化 (Day 5)

修改 `.github/workflows/ci.yml`:
```yaml
# 新增 job
security-scan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Dart SAST
      run: dart analyze --fatal-infos
    - name: Check hardcoded secrets
      run: |
        grep -rn "admin123\|op123456\|8888\|mock_token\|dev_secret" lib/ && exit 1 || true
    - name: Dependency audit
      run: flutter pub outdated

backend-test:
  runs-on: ubuntu-latest
  services:
    postgres:
      image: postgres:15
      env:
        POSTGRES_DB: test_db
        POSTGRES_PASSWORD: test
      ports: ['5432:5432']
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
      with: { python-version: '3.11' }
    - run: pip install -r backend/requirements.txt pytest pytest-asyncio httpx
    - run: cd backend && pytest tests/ -v --cov
```

---

## 五、Phase 4 — 功能完善 (P2, 预计3天)

### Agent B — 前端质量工程师

#### B6. 推送通知基础实现 (Day 6)
**当前**: `push_service.dart` 全 Stub
**最小可用方案** (不依赖 Firebase):
1. 后端 WebSocket 端点 `/ws/notifications`
2. 前端 `NotificationService` 连接 WS，接收实时消息
3. 本地通知用 `flutter_local_notifications` 包
4. 通知页面从 WS 历史 + API 获取数据

#### B7. 评价列表展示优化 (Day 6)
1. `product_detail_screen.dart` 新增评价 tab/section
2. 星级分布图表
3. 带图评价展示

#### B8. 浏览历史完善 (Day 6)
1. 记录浏览时展示商品完整信息 (名称+图片+价格)
2. 按日期分组显示
3. 清空历史功能

### Agent A — 后端架构师

#### A4. WebSocket 通知 (Day 6)
```python
# routers/ws.py
@router.websocket("/ws/notifications")
async def notification_ws(websocket: WebSocket, user_id: str):
    await websocket.accept()
    # 注册到 connection_manager
    # 订单状态变更时推送到对应 user
```

#### A5. 物流真实数据 (Day 7)
选项1: 对接快递100 API (免费额度)
选项2: 对接快递鸟 API
实现: `GET /api/orders/{id}/logistics` 返回真实数据

#### A6. 搜索优化 (Day 7)
当前: 内存 `filter()` — 全扫描
优化: PostgreSQL `pg_trgm` + `GIN` 索引 实现中文模糊搜索
```sql
CREATE EXTENSION pg_trgm;
CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);
```

---

## 六、Phase 5 — 运维与上线准备 (P2, 预计2天)

### Agent D — DevOps

#### D5. Nginx 生产配置 (Day 8)
```nginx
server {
    listen 443 ssl http2;
    server_name xn--lsws2cdzg.top www.xn--lsws2cdzg.top;
    
    ssl_certificate /etc/letsencrypt/live/xn--lsws2cdzg.top/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/xn--lsws2cdzg.top/privkey.pem;
    
    # 安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000";
    
    # 限流
    limit_req_zone $binary_remote_addr zone=api:10m rate=30r/m;
    
    location /api/ {
        limit_req zone=api burst=10;
        proxy_pass http://127.0.0.1:8000;
    }
    
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location / {
        root /var/www/huiyuyuan;
        try_files $uri $uri/ /index.html;
    }
}
```

#### D6. 监控告警 (Day 8)
1. systemd watchdog — 进程挂掉自动重启 (已有)
2. 健康检查脚本 — 每 5 分钟 curl `/api/health`，失败发企业微信/钉钉通知
3. 磁盘/内存监控 — `df -h` < 80% 告警

#### D7. 部署脚本升级 (Day 9)
修改 `scripts/deploy.ps1`:
1. 后端部署: `rsync` 整个 `backend/` 目录 (不再是单个 main.py)
2. 数据库迁移: `ssh alembic upgrade head`
3. 回滚支持: 保留前 3 个版本快照

---

## 七、Phase 6 — 创新功能 (P3, 持续迭代)

> 以下为差异化竞争功能，优先级根据用户反馈调整

### 创新 1: AI 珠宝鉴定助手 (Agent B)
- 用户拍照 → Gemini Vision 分析材质/真伪/价值
- 生成鉴定报告 PDF
- 历史鉴定记录

### 创新 2: 价格趋势图表 (Agent B)
- 每日记录商品价格变动
- 折线图展示 30/90/365 天趋势
- 降价提醒推送

### 创新 3: 客户分层标签 (Agent A + B)
- 基于消费金额/频次自动标签: VIP/高潜/流失
- 管理员面板展示客户分层分布
- 针对性促销推送

### 创新 4: 智能话术生成 (Agent B)
- 操作员输入客户需求 → AI 生成销售话术
- 珠宝专业知识库注入
- 多轮对话优化

### 创新 5: 批量发货 (Agent A + B)
- 管理员勾选多个订单 → 批量填入物流单号
- Excel 导入发货信息
- 发货后自动推送通知

---

## 八、甘特图总览

```
Day  1  ████████ Agent A: 后端拆分 + DB建模  |  Agent D: PostgreSQL/Redis安装
Day  2  ████████ Agent A: DB迁移 + 安全加固   |  Agent D: .env配置/备份脚本
Day  3  ████████ Agent B: 消灭假数据(7屏幕)   |  Agent A: 联调验证
Day  4  ████████ Agent B: 库存+评价持久化      |  Agent C: 后端pytest
Day  5  ████████ Agent C: Widget Test + CI/CD  |  Agent B: Payment修复
Day  6  ████████ Agent B: 推送+评价展示        |  Agent A: WebSocket
Day  7  ████████ Agent A: 物流API+搜索优化     |  Agent B: 浏览历史
Day  8  ████████ Agent D: Nginx生产配 + 监控   |  Agent C: 安全扫描
Day  9  ████████ Agent D: 部署脚本升级         |  全员: 联调+修bug
Day 10+ ████████ Phase 6 创新功能持续迭代
```

---

## 九、接口约定 (Agent 间协作)

### Agent A 为 Agent B 提供的 API 契约

所有 API 返回格式统一:
```json
// 成功
{"code": 200, "data": {...}, "message": "ok"}

// 失败
{"code": 400, "data": null, "message": "具体错误信息"}

// 分页
{"code": 200, "data": {"items": [...], "total": 100, "page": 1, "size": 20}}
```

### 环境变量约定 (Agent A 与 Agent D)
```env
# 必填 (无则启动失败)
DATABASE_URL=postgresql+asyncpg://user:pwd@localhost/huiyuyuan
JWT_SECRET_KEY=<64字符随机串>

# 可选 (无则降级)
REDIS_URL=redis://localhost:6379/0
ALIYUN_ACCESS_KEY_ID=
ALIYUN_ACCESS_KEY_SECRET=
DEEPSEEK_API_KEY=
GEMINI_API_KEY=
```

### 前端配置约定 (Agent B)
```dart
// api_config.dart — 所有 URL 必须通过此文件配置
// 禁止在 Screen/Service 中硬编码任何 URL 或 Token
```

---

## 十、质量门禁 (每个 Phase 结束时检查)

| 检查项 | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|--------|---------|---------|---------|---------|
| `dart analyze` 0 error | ? | ? | ? | ? |
| `flutter test` 全通过 | ? | ? | ? | ? |
| `pytest` 全通过 | ? | ? | ? | ? |
| 后端 `curl /api/health` = 200 | ? | ? | ? | ? |
| 前端 HTTP 200 | ? | ? | ? | ? |
| 无 `TODO` 新增(只能减少) | - | ? | ? | ? |
| Git tag 标记版本 | v4.0-alpha | v4.0-beta | v4.0-rc | v4.0 |

---

## 附录: 当前问题全量清单 (供 Agent 领取)

| ID | 严重性 | Agent | 问题 | 状态 |
|----|--------|-------|------|------|
| P0-1 | ? | A+D | 后端内存存储 → PostgreSQL | ? |
| P0-2 | ? | A | CORS 全开 → 白名单 | ? |
| P0-3 | ? | A | JWT Secret 默认值 → 强制 env | ? |
| P0-4 | ? | B | 客户端硬编码凭据 → 移除 | ? |
| P0-5 | ? | A | SMS 8888 → Redis 不可用返回 503 | ? |
| P0-6 | ? | A | 密码明文 → bcrypt | ? |
| P1-1 | ? | B | payment_screen mock_token → ApiService | ? |
| P1-2 | ? | B | 支付轮询 mock 成功 → 真超时提示 | ? |
| P1-3 | ? | B | notification_screen 假数据 → API | ? |
| P1-4 | ? | B | shop_radar 假数据 → API | ? |
| P1-5 | ? | B | browse_history 仅ID → 完整信息 | ? |
| P1-6 | ? | B | favorite_list 无图 → CachedNetworkImage | ? |
| P1-7 | ? | B | logistics mock节点 → 真实API | ? |
| P1-8 | ? | B | inventory_provider 纯内存 → API | ? |
| P1-9 | ? | B | review_service 纯本地 → API同步 | ? |
| P2-1 | ? | C | 后端 0 测试 → pytest >= 30用例 | ? |
| P2-2 | ? | C | 28 屏幕 0 Widget Test → 关键5屏幕 | ? |
| P2-3 | ? | C | CI/CD 安全扫描 | ? |
| P2-4 | ? | A | 后端单文件 → 模块化 | ? |
| P2-5 | ? | B | push_service Stub → 基础WebSocket | ? |
| P2-6 | ? | D | Nginx 生产配置 + 安全头 | ? |
| P2-7 | ? | D | 数据库备份脚本 | ? |
| P3-1 | ? | B | AR 试戴 Stub → 移除入口或真实实现 | ? |
| P3-2 | ? | A | OSS STS mock → 真实凭据或移除 | ? |
