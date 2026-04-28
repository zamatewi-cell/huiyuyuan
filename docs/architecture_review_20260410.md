# 汇玉源项目全景架构梳理报告

> **生成日期**: 2026-04-10
> **版本**: v4.0
> **审查范围**: 完整代码库(前端 + 后端 + 部署 + 测试)
> **审查深度**: 架构级、模块级、代码级三层分析

---

## 📋 目录

1. [项目概览](#项目概览)
2. [技术栈总览](#技术栈总览)
3. [整体架构图](#整体架构图)
4. [前端架构详解](#前端架构详解)
5. [后端架构详解](#后端架构详解)
6. [数据流与交互模式](#数据流与交互模式)
7. [AI 服务架构](#ai-服务架构)
8. [安全体系](#安全体系)
9. [测试覆盖分析](#测试覆盖分析)
10. [CI/CD 流水线](#cicd-流水线)
11. [发现的问题与风险](#发现的问题与风险)
12. [改进建议路线图](#改进建议路线图)
13. [附录:关键文件索引](#附录关键文件索引)

---

## 项目概览

### 基本信息

| 属性 | 值 |
|------|-----|
| **项目名称** | 汇玉源 (HuiYuYuan) |
| **定位** | 全栈跨平台珠宝智能交易平台 |
| **当前版本** | v4.0(模块化架构已完成) |
| **核心特色** | AI 多模态能力(文本对话 + 图片识别) |
| **设计系统** | Liquid Glass 毛玻璃风格 |
| **品牌色** | 翡翠绿 `#2E8B57` + 金色 `#D4AF37` |
| **生产域名** | https://汇玉源.top / https://xn--lsws2cdzg.top |
| **服务器** | 阿里云 ECS `47.112.98.191` |

### 量化指标

| 维度 | 数值 |
|------|------|
| 前端页面数 | 23+ 屏幕 |
| 商品数量 | 130 款(15+ 材质分类) |
| 合作店铺 | 12 家 |
| 后端 API 端点 | 49+ |
| 前端测试用例 | 490 passed |
| 后端测试用例 | 167 passed |
| 核心功能完成率 | ~99% |
| 上线就绪率 | ~88% |

### 角色体系

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  管理员      │     │  操作员       │     │  普通用户    │
│  (Admin)    │     │  (Operator)   │     │  (Customer) │
└──────┬──────┘     └──────┬───────┘     └──────┬──────┘
       │                   │                     │
       ▼                   ▼                     ▼
  全局管理面板        订单处理工作台         购物浏览界面
  - 用户管理          - 订单确认             - 商品浏览
  - 数据统计          - 支付审核             - 购物车
  - 系统配置          - 库存查询             - 下单支付
                      - 客服沟通             - 个人中心
```

---

## 整体架构图

```
客户端层 (Flutter)
├── Android/iOS App
├── Windows Desktop
└── Web Browser
        │
        ▼
    Riverpod State Management
    ├── Auth Provider (认证状态)
    ├── Cart Provider (购物车)
    ├── Product Providers (商品目录/搜索)
    └── Notification Provider (通知中心)
        │
        ▼
    Dio HTTP Client + Storage Services
        │
        ▼
┌───────────────────────────────────────┐
│   Nginx Reverse Proxy (生产服务器)     │
│   - /api/* → FastAPI :8000            │
│   - Static Files → /var/www/huiyuyuan │
└───────────────┬───────────────────────┘
                │
                ▼
┌───────────────────────────────────────┐
│   FastAPI Backend (模块化架构)         │
│                                       │
│   Routers (16个模块):                  │
│   ├── auth.py        - 认证授权       │
│   ├── products.py    - 商品管理       │
│   ├── orders.py      - 订单生命周期   │
│   ├── cart.py        - 购物车         │
│   ├── payments.py    - 支付处理       │
│   ├── admin.py       - 管理员功能     │
│   ├── ai.py          - AI图片识别     │
│   └── ...                             │
│                                       │
│   Services (业务逻辑层):               │
│   ├── ai_service.py    - DashScope代理│
│   ├── payment_service.py - 支付状态机 │
│   ├── sms_service.py   - 短信发送     │
│   └── ...                             │
└───────────────┬───────────────────────┘
                │
        ┌───────┴───────┐
        ▼               ▼
  PostgreSQL        Redis
  (持久化存储)      (缓存/限流)
        │
        ▼
  External APIs
  ├── DashScope (AI)
  ├── Aliyun SMS (待接入)
  ├── OSS (待接入)
  └── WeChat/Alipay Pay (待接入)
```

---

## 前端架构详解

### 目录结构概览

```
lib/
├── main.dart                          # 应用入口
├── config/                            # 配置层 (4个文件)
│   ├── api_config.dart               # API URL / 超时配置
│   ├── app_config.dart               # 应用常量 / 密钥读取
│   ├── secrets.dart                  # --dart-define 注入的密钥
│   └── local_debug_config.dart       # .env.json 本地调试配置
├── models/                            # 数据模型层 (17个文件)
│   ├── user_model.dart               # UserModel, UserType enum
│   ├── product_model.dart            # ProductModel, MaterialCategory
│   ├── order_model.dart              # OrderModel, OrderStatus
│   ├── cart_item_model.dart          # CartItemModel
│   └── ... (其他业务模型)
├── providers/                         # 状态管理层 (9个Provider)
│   ├── auth_provider.dart            # 认证状态 (AsyncNotifier)
│   ├── cart_provider.dart            # 购物车状态
│   ├── product_catalog_provider.dart # 商品目录
│   ├── product_search_provider.dart  # 商品搜索
│   └── ... (其他状态)
├── screens/                           # UI页面层 (23+屏幕)
│   ├── login_screen.dart             # 登录页 (三合一)
│   ├── main_screen.dart              # 主导航壳
│   ├── admin/                        # 管理员专属 (5个页面)
│   ├── operator/                     # 操作员专属 (4个页面)
│   ├── trade/                        # 交易相关 (6个页面)
│   ├── order/                        # 订单管理 (4个页面)
│   ├── shop/                         # 店铺相关 (3个页面)
│   ├── chat/                         # AI对话 (2个页面)
│   ├── profile/                      # 个人中心 (5个页面)
│   └── ... (其他功能组)
├── services/                          # 服务层 (22个单例服务)
│   ├── storage_service.dart          # 本地存储封装
│   ├── api_service.dart              # HTTP客户端封装 (Dio)
│   ├── ai_service.dart               # AI对话服务 (聚合层)
│   ├── ai_dashscope_service.dart     # DashScope直连服务
│   ├── order_service.dart            # 订单业务逻辑
│   └── ... (其他服务)
├── widgets/                           # 可复用组件
│   ├── common/                       # 通用组件 (15+)
│   ├── product/                      # 商品相关组件
│   ├── order/                        # 订单相关组件
│   └── chat/                         # 聊天相关组件
├── themes/                            # 主题定义
│   ├── colors.dart                   # JewelryColors (品牌色系)
│   └── jewelry_theme.dart            # ThemeData (亮/暗主题)
├── l10n/                              # 国际化
│   ├── app_strings.dart              # 翻译字典 (zh_CN/en/zh_TW)
│   └── l10n_provider.dart            # Riverpod翻译Provider
└── utils/                             # 工具函数
    ├── text_sanitizer.dart           # UTF清理
    ├── validators.dart               # 表单验证
    └── formatters.dart               # 格式化
```

### 核心设计模式

#### 1. 服务层单例模式

```dart
class XxxService {
  static final XxxService _instance = XxxService._internal();
  factory XxxService() => _instance;
  XxxService._internal();
}
```

**优点**:
- 全局唯一实例,避免重复初始化
- 便于依赖注入和测试 Mock
- 符合 Flutter 最佳实践

**缺点**:
- 难以进行并行测试隔离
- 隐式依赖关系不够清晰

#### 2. Riverpod 状态管理模式

```dart
// AsyncNotifierProvider (带异步初始化的状态)
final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // 从本地存储恢复状态
    await _storage.init();
    final userData = await _storage.getUser();
    return userData != null ? UserModel.fromJson(userData) : null;
  }

  Future<bool> loginAdmin(...) async {
    // 业务逻辑
  }
}
```

**状态流转**:
```
Initial State → build() → Load from Storage
     ↓
  Success → AsyncValue.data(user) → UI显示已登录
     ↓
  Failure → AsyncValue.error(exception) → UI显示错误

User Action (login/logout)
     ↓
Update state = AsyncValue.data(new_user)
     ↓
Persist to Storage → Notify Listeners → UI rebuild
```

#### 3. API结果封装模式

```dart
class ApiResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? code;

  factory ApiResult.success(T data, {String? message}) {...}
  factory ApiResult.error(String message, {int? code}) {...}
}
```

### 关键业务流程

#### 认证流程

```
用户输入账号密码验证码
    ↓
LoginScreen → ref.read(authProvider.notifier).loginAdmin()
    ↓
AuthProvider → POST /api/auth/login
    ↓
Backend验证 → 返回 {token, refresh_token, user}
    ↓
StorageService保存 → saveToken/saveUser
    ↓
state = AsyncValue.data(user)
    ↓
MainScreen根据isAdminProvider切换角色界面
    ├─ Admin → AdminDashboard
    ├─ Operator → OperatorHome
    └─ Customer → ProductList
```

#### AI对话流程

```
用户输入消息
    ↓
AIAssistantScreen → AIService.chatStream()
    ↓
AIDashScopeService.createChatCompletionStream()
    ↓
POST DashScope API (SSE流式响应)
    ├─ 成功 → onToken逐字更新UI → onDone显示完整回复
    └─ 失败 → AIPromptService.getOfflineResponse()离线答案
```

#### 下单流程

```
CheckoutScreen获取选中购物车项
    ↓
OrderService创建订单 → POST /api/orders/create
    ↓
返回 {order_id, total_amount}
    ↓
PaymentService发起支付 → POST /api/payments/initiate
    ↓
显示支付二维码
    ↓
用户扫码支付 → 轮询查询支付状态
    ├─ 成功 → 清空购物车 → 跳转订单详情
    └─ 失败 → 提示重试
```

### 前端性能优化策略

1. **图片懒加载与缓存**: CachedNetworkImage + memCacheWidth/Height
2. **列表虚拟化**: ListView.builder 按需渲染
3. **防抖搜索**: Timer延迟500ms执行搜索
4. **按需监听Provider**: Consumer精确订阅,避免不必要重建
5. **Platform-aware API URL**: Web端走Nginx同源代理,Native端直连域名

---

## 后端架构详解

### 模块化目录结构

```
backend/
├── main.py                          # FastAPI应用入口 (~100行)
├── config.py                        # 环境变量读取与配置类
├── database.py                      # SQLAlchemy Engine + Session管理
├── security.py                      # JWT生成/验证 + bcrypt密码哈希
├── store.py                         # 内存存储降级实现 (仅开发环境)
├── logging_config.py                # 结构化日志配置 (JSON格式)
├── requirements.txt                 # Python依赖清单
├── alembic.ini                      # Alembic迁移配置
├── migrations/                      # 数据库迁移脚本
│   └── versions/                    # 版本化迁移文件
├── routers/                         # API路由模块 (16个)
│   ├── auth.py                      # /api/auth/* 认证授权
│   ├── products.py                  # /api/products/* 商品CRUD
│   ├── orders.py                    # /api/orders/* 订单生命周期
│   ├── cart.py                      # /api/cart/* 购物车操作
│   ├── payments.py                  # /api/payments/* 支付回调
│   ├── admin.py                     # /api/admin/* 管理员统计
│   ├── ai.py                        # /api/ai/* AI图片识别
│   ├── users.py                     # /api/users/* 用户资料
│   ├── shops.py                     # /api/shops/* 店铺管理
│   ├── inventory.py                 # /api/inventory/* 库存调整
│   ├── favorites.py                 # /api/favorites/* 收藏
│   ├── reviews.py                   # /api/reviews/* 评价系统
│   ├── upload.py                    # /api/upload/* 文件上传
│   ├── notifications.py             # /api/notifications/* 通知
│   ├── ws.py                        # /ws/* WebSocket实时通信
│   └── app_meta.py                  # /api/meta/* App版本信息
├── services/                        # 业务逻辑服务 (10个)
│   ├── ai_service.py                # DashScope图片识别代理
│   ├── payment_service.py           # 支付状态机
│   ├── sms_service.py               # 阿里云短信发送
│   ├── captcha_service.py           # 图形验证码生成
│   ├── device_tracker.py            # 设备指纹追踪
│   └── login_guard_service.py       # 登录保护(异地检测)
├── schemas/                         # Pydantic数据模型 (9个)
│   ├── auth.py                      # LoginRequest, TokenResponse
│   ├── product.py                   # ProductCreate, ProductFilter
│   ├── order.py                     # OrderCreate, OrderUpdate
│   └── ... (其他DTO)
└── tests/                           # pytest测试套件 (21个文件)
    ├── conftest.py                  # Fixtures (client, db_session)
    ├── test_auth.py                 # 认证测试
    ├── test_orders.py               # 订单测试
    ├── test_products.py             # 商品测试
    └── ... (其他模块测试)
```

### 路由注册机制

```python
# main.py - 应用入口
from routers import auth, products, orders, cart, payments, ...

app = FastAPI(title="HuiYuYuan API", version="4.0.0")

# 注册16个路由器
app.include_router(auth.router)
app.include_router(products.router)
app.include_router(orders.router)
# ... 共16个
```

每个路由器独立定义:

```python
# routers/products.py
from fastapi import APIRouter, Depends, Query
from database import get_db
from schemas.product import ProductCreate, ProductFilter
from services.product_service import ProductService

router = APIRouter(prefix="/api/products", tags=["products"])

@router.get("/")
async def list_products(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    category: str = Query(None),
    db: Session = Depends(get_db)
):
    service = ProductService(db)
    return await service.list(skip=skip, limit=limit, category=category)

@router.post("/")
async def create_product(
    product: ProductCreate,
    db: Session = Depends(get_db),
    current_user = Depends(require_admin)  # 权限校验
):
    service = ProductService(db)
    return await service.create(product.dict())
```

### 依赖注入链

```
Request
  ↓
Middleware层
  ├─ CORS中间件
  ├─ Security Headers (X-Frame-Options等)
  └─ Request Logging (JSON格式)
  ↓
Router Endpoint
  ├─ Depends(get_db) → SQLAlchemy Session
  ├─ Depends(require_auth) → JWT验证 → CurrentUser
  ├─ Depends(require_admin) → 角色权限检查
  └─ Pydantic Schema自动验证
  ↓
Service Layer (业务逻辑)
  ├─ Database Operations (SQLAlchemy ORM)
  ├─ Cache Operations (Redis)
  └─ External API Calls (AI/SMS/OSS)
  ↓
Response (Pydantic Model → JSON)
```

### 数据库设计要点

**核心表**:
- `users` - 用户表 (admin/operator/customer三角色)
- `products` - 商品表 (130款,15+材质分类)
- `orders` + `order_items` - 订单主从表
- `cart_items` - 购物车表 (user_id + product_id唯一约束)
- `payments` - 支付记录表 (状态机: pending/success/failed/refunded)
- `reviews` - 评价表 (关联订单和商品)
- `notifications` - 通知表 (is_read标记)

**索引优化**:
- 商品: category, material (筛选高频字段)
- 订单: user_id, status (查询热点)
- 购物车: user_id (个人购物车查询)
- 通知: (user_id, is_read) 复合索引 (未读计数)

**会话安全增强** (2026-04-08修复):
- JWT令牌绑定`sid`会话ID
- logout/logout-others/refresh轮转/reset-password/change-password均使旧会话失效
- 防止Token泄露后的重放攻击

### 安全中间件

#### 1. CORS配置
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,  # 生产环境限定域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

#### 2. 安全响应头
```python
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=()"

    if request.url.path.startswith("/api/auth/"):
        response.headers["Cache-Control"] = "no-store"

    if IS_PRODUCTION:
        response.headers["Strict-Transport-Security"] = "max-age=31536000"

    return response
```

#### 3. 请求日志 (生产环境JSON格式)
```python
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        duration_ms = (time.time() - start_time) * 1000

        logger.info({
            "method": request.method,
            "path": request.url.path,
            "status": response.status_code,
            "duration_ms": round(duration_ms, 2),
            "client_ip": request.client.host
        })

        return response
```

### 优雅降级策略

**开发环境**:
- PostgreSQL不可用 → 回退到内存字典存储 (`store.py`)
- Redis不可用 → SMS限流失效,但不阻断功能
- JWT/bcrypt缺失 → 使用UUID/明文 (仅调试)

**生产环境**:
- 强制PostgreSQL连接,失败则启动 abort
- 强制Redis用于会话管理和限流
- 所有敏感操作必须经过JWT验证

```python
# database.py
if DATABASE_URL:
    try:
        _engine = create_engine(DATABASE_URL, ...)
        DB_AVAILABLE = True
    except Exception as e:
        if IS_PRODUCTION:
            raise RuntimeError(f"PostgreSQL连接失败,生产环境不能降级: {e}")
        logger.warning(f"PostgreSQL不可用,将使用内存存储")
else:
    if IS_PRODUCTION:
        raise RuntimeError("DATABASE_URL未配置,生产环境必须连接PostgreSQL")
```

---

## 数据流与交互模式

### 前后端数据交互流程

```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│ Flutter  │         │   Dio    │         │  Nginx   │         │ FastAPI  │
│  Screen  │         │  Client  │         │  Proxy   │         │  Router  │
└────┬─────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                     │                    │                    │
     │  User Action        │                    │                    │
     ├────────────────────>│                    │                    │
     │                     │  HTTP Request      │                    │
     │                     ├───────────────────>│                    │
     │                     │                    │  Forward /api/*    │
     │                     │                    ├───────────────────>│
     │                     │                    │                    │
     │                     │                    │              Validate
     │                     │                    │              Process
     │                     │                    │                    │
     │                     │  HTTP Response     │                    │
     │                     │<───────────────────│                    │
     │  ApiResult<T>       │                    │                    │
     │<────────────────────┤                    │                    │
     │                     │                    │                    │
     │  Update UI          │                    │                    │
     └─────────────────────┘                    └────────────────────┘
```

### 状态同步机制

**本地优先策略**:
1. 用户操作 → 立即更新本地状态 (Optimistic UI)
2. 异步发送API请求
3. 成功 → 持久化到Storage,保持UI
4. 失败 → 回滚本地状态,显示错误提示

**示例 - 购物车添加**:
```dart
// CartProvider
Future<void> addToCart(ProductModel product) async {
  // 1. Optimistic update
  final optimisticItems = [...state.items, CartItem(product: product)];
  state = state.copyWith(items: optimisticItems);

  try {
    // 2. API call
    await backendService.addToCart(product.id);

    // 3. Persist to storage
    await _storage.saveCart(optimisticItems);
  } catch (e) {
    // 4. Rollback on failure
    state = state.copyWith(items: state.items.where(...).toList());
    showError('添加失败,请重试');
  }
}
```

### WebSocket实时通知

```
Client (WebSocket) ←→ Server (/ws/notifications)
     │                        │
     │  Connect with JWT      │
     ├───────────────────────>│
     │                        ├─ Validate Token
     │                        ├─ Subscribe to user_id channel
     │  Connection Established│
     │<───────────────────────┤
     │                        │
     │  Order Status Changed  │
     │  (Background Event)    │
     │                        ├─ Publish to Redis channel
     │                        ├─ WebSocket broadcast
     │  Notification Payload  │
     │<───────────────────────┤
     │                        │
     │  Update Badge Count    │
     └────────────────────────┘
```

---

## AI 服务架构

### 双通道设计

```
┌─────────────────────────────────────────────────────┐
│                  AIService (聚合层)                   │
│                                                      │
│  chat() / chatStream()                               │
│  ├─ Build Messages (System Prompt + History)        │
│  ├─ Extract Product Context (if includeProducts)    │
│  ├─ Call AIDashScopeService                         │
│  │   ├─ Success → Return streaming response         │
│  │   └─ Failure → Fallback to Offline Answers      │
│  └─ Filter Sensitive Words                          │
└─────────────────────────────────────────────────────┘
           │                    │
           ↓                    ↓
┌──────────────────┐  ┌──────────────────────┐
│ AIDashScopeService│  │ AIPromptService      │
│ (Online Channel)  │  │ (Offline Fallback)   │
│                   │  │                      │
│ POST DashScope    │  │ Pattern Matching     │
│ /chat/completions │  │ ├─ Greeting patterns │
│ Model: qwen-plus  │  │ ├─ Product queries   │
│ Streaming: SSE    │  │ ├─ Order status      │
│                   │  │ └─ Default responses │
└──────────────────┘  └──────────────────────┘
```

### 文本对话流程 (前端直连)

```dart
// ai_dashscope_service.dart
Future<String?> createChatCompletion({
  required List<Map<String, String>> messages,
}) async {
  if (!_isConfigured) {
    _lastError = 'DASHSCOPE_API_KEY not configured';
    return null;
  }

  try {
    final response = await _dio.post(
      '${ApiConfig.dashScopeBaseUrl}/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer ${AppConfig.dashScopeApiKey}',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': ApiConfig.dashScopeModel, // qwen-plus
        'messages': messages,
        'stream': false,
        'max_tokens': 2000,
      },
    );

    final choices = response.data['choices'] as List;
    return choices[0]['message']['content'] as String;
  } catch (e) {
    _lastError = e.toString();
    return null;
  }
}
```

### 图片识别流程 (后端代理)

```
Flutter App                    Backend API               DashScope API
     │                              │                          │
     │  Select Image                │                          │
     ├─────────────┐                │                          │
     │             │                │                          │
     │  Upload to   │                │                          │
     │  Backend     │  POST /api/ai/ │                          │
     ├─────────────>│  analyze-image │                          │
     │             │                │  Base64 encode image     │
     │             │                ├─────────────────────────>│
     │             │                │                          │
     │             │                │  qwen-vl-plus-latest     │
     │             │                │  Analyze jewelry image   │
     │             │                │<─────────────────────────┤
     │             │                │                          │
     │             │  JSON Result   │                          │
     │             │  {description, │                          │
     │             │   material,    │                          │
     │             │   category,    │                          │
     │             │   tags}        │                          │
     │<─────────────┤                │                          │
     │             │                │                          │
     │  Display AI Analysis         │                          │
     └─────────────┘                └──────────────────────────┘
```

**后端实现** (`backend/services/ai_service.py`):
```python
async def analyze_image(file: UploadFile) -> dict:
    import httpx

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="图片不能超过10MB")

    b64 = base64.b64encode(image_bytes).decode()
    mime = file.content_type or "image/jpeg"
    data_uri = f"data:{mime};base64,{b64}"

    prompt = (
        "请分析这张珠宝图片,并严格返回JSON:\n"
        '{"description":"详细描述","material":"材质",'
        '"category":"分类","tags":["标签"],"quality_score":0.8}'
    )

    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(
            f"{DASHSCOPE_BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {DASHSCOPE_API_KEY}"},
            json={
                "model": DASHSCOPE_VISION_MODEL,  # qwen-vl-plus-latest
                "messages": [{
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": data_uri}}
                    ]
                }],
                "max_tokens": 1200,
            }
        )

    payload = response.json()
    content = payload['choices'][0]['message']['content']
    return json.loads(content)
```

### Prompt工程策略

**系统Prompt模板**:
```
你是汇玉源珠宝平台的AI助手,专业解答珠宝相关问题。

【角色设定】
- 专业知识: 翡翠、和田玉、黄金、钻石等材质鉴别
- 服务态度: 耐心细致,用通俗易懂的语言解释
- 边界意识: 不提供投资建议,不承诺保值增值

【上下文信息】
当前浏览商品: {product_name}
材质: {material}
价格: ¥{price}
店铺: {shop_name}

【回答规范】
1. 优先回答用户具体问题
2. 适当结合当前商品信息
3. 长度控制在200字以内
4. 使用友好亲切的语气
5. 不确定时诚实告知

用户问题: {user_message}
```

**离线答案匹配规则**:
```dart
// ai_prompt_service.dart
String getOfflineResponse(String userMessage, {String language = 'zh_CN'}) {
  final lowerMsg = userMessage.toLowerCase();

  if (lowerMsg.contains('你好') || lowerMsg.contains('hello')) {
    return t('ai_offline_greeting');
  }

  if (lowerMsg.contains('价格') || lowerMsg.contains('多少钱')) {
    return t('ai_offline_price_query');
  }

  if (lowerMsg.contains('真假') || lowerMsg.contains('鉴定')) {
    return t('ai_offline_authentication');
  }

  if (lowerMsg.contains('保养') || lowerMsg.contains('清洗')) {
    return t('ai_offline_maintenance');
  }

  return t('ai_offline_default');
}
```

---

## 安全体系

### 认证与授权

#### JWT令牌结构

```json
{
  "sub": "user_id_123",
  "username": "admin",
  "user_type": "admin",
  "sid": "session_uuid_v4",
  "iat": 1712736000,
  "exp": 1712822400,
  "iss": "huiyuyuan-api"
}
```

**关键字段**:
- `sid` (Session ID): 绑定会话,支持单设备登录和强制下线
- `user_type`: 角色标识 (admin/operator/customer)
- `exp`: 过期时间 (24小时)
- `iat`: 签发时间

#### 会话安全管理 (2026-04-08增强)

**Token轮转机制**:
```python
# routers/auth.py
@router.post("/refresh")
async def refresh_token(refresh_token: str):
    # 验证refresh token
    payload = verify_refresh_token(refresh_token)

    # 生成新的access token + 新的refresh token
    new_access = create_access_token(payload['sub'])
    new_refresh = create_refresh_token(payload['sub'])

    # 使旧refresh token失效 (Redis黑名单)
    await redis.blacklist(refresh_token)

    return {"access_token": new_access, "refresh_token": new_refresh}
```

**强制下线场景**:
1. `POST /api/auth/logout` - 主动登出,清除当前会话
2. `POST /api/auth/logout-others` - 踢出其他设备,保留当前会话
3. `POST /api/auth/reset-password` - 重置密码,所有会话失效
4. `POST /api/auth/change-password` - 修改密码,所有会话失效

**实现原理**:
```python
# security.py
def verify_access_token(token: str) -> dict:
    payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])

    # 检查会话是否有效
    user_id = payload['sub']
    current_sid = payload.get('sid')

    stored_sid = redis.get(f"user_session:{user_id}")
    if stored_sid != current_sid:
        raise HTTPException(status_code=401, detail="会话已失效")

    return payload
```

### 密码安全

**bcrypt哈希**:
```python
import bcrypt

# 注册时
password_hash = bcrypt.hashpw(
    password.encode('utf-8'),
    bcrypt.gensalt(rounds=12)
).decode('utf-8')

# 登录时
if bcrypt.checkpw(
    password.encode('utf-8'),
    stored_hash.encode('utf-8')
):
    # 密码正确
```

**强度要求**:
- 最小长度: 8字符
- 必须包含: 大小写字母 + 数字
- 禁止常见弱口令 (admin123, password等)

### 输入验证与 sanitization

**前端层面**:
```dart
// utils/text_sanitizer.dart
String sanitizeUtf16(String input) {
  // 移除控制字符
  return input.replaceAllMapped(
    RegExp(r'[\u0000-\u001F\u007F-\u009F]'),
    (match) => '',
  );
}

// utils/validators.dart
bool isValidPhone(String phone) {
  return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
}

bool isValidPassword(String password) {
  return password.length >= 8 &&
         RegExp(r'[A-Z]').hasMatch(password) &&
         RegExp(r'[a-z]').hasMatch(password) &&
         RegExp(r'\d').hasMatch(password);
}
```

**后端层面**:
```python
# Pydantic自动验证
class LoginRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)
    captcha: str = Field(..., pattern=r'^\d{4}$')

# SQL注入防护 (SQLAlchemy ORM参数化查询)
db.query(User).filter(User.username == username).first()
# ✅ 安全: 自动生成参数化SQL

# ❌ 危险: 永远不要拼接SQL字符串
# db.execute(f"SELECT * FROM users WHERE username='{username}'")
```

### XSS与CSRF防护

**XSS防护**:
- Flutter天然免疫 (无innerHTML概念)
- Web端启用CSP (Content Security Policy)
- 所有用户输入经过sanitizeUtf16清理

**CSRF防护**:
- API采用Token认证 (非Cookie Session)
- CORS限制跨域请求来源
- 敏感操作需二次验证 (验证码/密码)

### 敏感数据保护

**密钥管理**:
```
开发环境: .env.json (Git忽略)
构建注入: --dart-define=DASHSCOPE_API_KEY=sk-xxx
生产环境: 服务器/etc/environment + systemd EnvironmentFile
```

**加密存储**:
```dart
// flutter_secure_storage (AES-256加密)
await secureStorage.write(key: 'jwt_token', value: token);
await secureStorage.write(key: 'refresh_token', value: refreshToken);
```

**日志脱敏**:
```python
# logging_config.py
class SensitiveDataFilter(logging.Filter):
    def filter(self, record):
        # 脱敏手机号: 138****1234
        record.msg = re.sub(r'1[3-9]\d{9}', r'\g<0>****\g<0>', record.msg)
        # 脱敏身份证: 110***********1234
        record.msg = re.sub(r'\d{17}[\dX]', r'\g<0>****\g<0>', record.msg)
        return True
```

### 速率限制

**Redis限流**:
```python
# middleware/rate_limit.py
async def rate_limit_dependency(request: Request):
    client_ip = request.client.host
    key = f"rate_limit:{client_ip}:{request.url.path}"

    count = await redis.incr(key)
    if count == 1:
        await redis.expire(key, 60)  # 1分钟窗口

    if count > 100:  # 每分钟最多100次请求
        raise HTTPException(status_code=429, detail="请求过于频繁")
```

**SMS防刷**:
```python
# services/sms_service.py
async def send_sms(phone: str):
    key = f"sms_limit:{phone}"
    last_sent = await redis.get(key)

    if last_sent and (time.time() - float(last_sent)) < 60:
        raise HTTPException(status_code=429, detail="请稍后再试")

    # 发送短信
    await aliyun_sms.send(phone, template_code, params)
    await redis.set(key, time.time(), ex=60)
```

---

## 测试覆盖分析

### 前端测试 (Flutter)

**测试统计**:
- 总用例数: **490 passed**
- 测试类型: Unit Tests + Widget Tests
- 覆盖率估算: ~65% (核心业务逻辑较高,UI组件较低)

**测试目录结构**:
```
test/
├── models/                    # 模型层测试
│   ├── user_model_test.dart
│   ├── product_model_test.dart
│   └── order_model_test.dart
├── providers/                 # Provider状态管理测试
│   ├── auth_provider_test.dart
│   ├── cart_provider_test.dart
│   └── app_settings_provider_test.dart
├── services/                  # 服务层测试 (Mock API)
│   ├── api_service_test.dart
│   ├── storage_service_test.dart
│   └── ai_service_test.dart
├── screens/                   # 屏幕Widget测试
│   ├── login_screen_test.dart
│   ├── product_list_screen_test.dart
│   └── checkout_screen_test.dart
├── widgets/                   # 通用组件测试
│   ├── glass_card_test.dart
│   ├── captcha_widget_test.dart
│   └── product_card_test.dart
├── utils/                     # 工具函数测试
│   ├── validators_test.dart
│   ├── formatters_test.dart
│   └── text_sanitizer_test.dart
└── integration/               # 集成测试 (端到端)
    └── auth_flow_test.dart
```

**典型测试案例**:

```dart
// test/providers/auth_provider_test.dart
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('初始状态应为null', () async {
    final authState = await container.read(authProvider.future);
    expect(authState, isNull);
  });

  test('登录成功后更新状态', () async {
    final notifier = container.read(authProvider.notifier);
    final result = await notifier.loginAdmin(
      '18925816362',
      'admin123',
      '8888',
    );

    expect(result, isTrue);
    final user = await container.read(authProvider.future);
    expect(user, isNotNull);
    expect(user!.userType, UserType.admin);
  });

  test('登录失败返回false', () async {
    final notifier = container.read(authProvider.notifier);
    final result = await notifier.loginAdmin(
      'wrong_phone',
      'wrong_password',
      '0000',
    );

    expect(result, isFalse);
    final user = await container.read(authProvider.future);
    expect(user, isNull);
  });
}
```

**Widget测试示例**:

```dart
// test/widgets/product_card_test.dart
void main() {
  testWidgets('ProductCard显示商品信息', (tester) async {
    final product = ProductModel(
      id: '1',
      name: '翡翠手镯',
      price: 2999.00,
      imageUrl: 'https://example.com/jade.jpg',
      material: '翡翠A货',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductCard(product: product),
      ),
    );

    expect(find.text('翡翠手镯'), findsOneWidget);
    expect(find.text('¥2999.00'), findsOneWidget);
    expect(find.text('翡翠A货'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });

  testWidgets('点击ProductCard触发回调', (tester) async {
    bool tapped = false;
    final product = ProductModel(...);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductCard(
          product: product,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(ProductCard));
    expect(tapped, isTrue);
  });
}
```

### 后端测试 (pytest)

**测试统计**:
- 总用例数: **167 passed**
- 测试类型: Unit Tests + Integration Tests
- 覆盖率估算: ~75% (API端点覆盖较全)

**测试目录结构**:
```
backend/tests/
├── conftest.py                # pytest fixtures
├── test_auth.py               # 认证接口测试 (15 cases)
├── test_auth_db.py            # 数据库认证测试 (10 cases)
├── test_products.py           # 商品接口测试 (20 cases)
├── test_orders.py             # 订单接口测试 (18 cases)
├── test_cart.py               # 购物车接口测试 (12 cases)
├── test_admin.py              # 管理员接口测试 (10 cases)
├── test_payments.py           # 支付接口测试 (8 cases)
├── test_ai.py                 # AI服务测试 (5 cases)
├── test_upload.py             # 文件上传测试 (6 cases)
├── test_ws.py                 # WebSocket测试 (4 cases)
├── test_app_security.py       # 安全头测试 (7 cases)
├── test_config_security.py    # 配置安全测试 (5 cases)
├── test_database_security.py  # 数据库安全测试 (6 cases)
└── ... (其他模块测试)
```

**Fixture配置**:

```python
# conftest.py
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from main import app
from database import get_db, Base

# 测试数据库
SQLALCHEMY_DATABASE_URL = "postgresql://test:test@localhost/test_huiyuyuan"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db_session():
    """每个测试函数独立的数据库会话"""
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db_session):
    """带数据库注入的测试客户端"""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
```

**典型测试案例**:

```python
# tests/test_auth.py
def test_login_success(client, db_session):
    """测试管理员登录成功"""
    # 准备测试数据
    from security import get_password_hash
    from models.user import User

    admin = User(
        username="admin",
        phone="18925816362",
        password_hash=get_password_hash("admin123"),
        user_type="admin",
        is_active=True
    )
    db_session.add(admin)
    db_session.commit()

    # 发送登录请求
    response = client.post("/api/auth/login", json={
        "username": "18925816362",
        "password": "admin123",
        "captcha": "8888",
        "type": "admin"
    })

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["user_type"] == "admin"

def test_login_invalid_credentials(client):
    """测试登录失败 - 错误凭证"""
    response = client.post("/api/auth/login", json={
        "username": "wrong_phone",
        "password": "wrong_password",
        "captcha": "0000",
        "type": "admin"
    })

    assert response.status_code == 401
    assert "detail" in response.json()

def test_protected_route_without_token(client):
    """测试未授权访问受保护路由"""
    response = client.get("/api/admin/statistics")
    assert response.status_code == 401
```

**安全性测试**:

```python
# tests/test_app_security.py
def test_security_headers(client):
    """测试安全响应头"""
    response = client.get("/api/health")

    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["Referrer-Policy"] == "strict-origin-when-cross-origin"

def test_auth_endpoints_no_cache(client):
    """测试认证端点禁用缓存"""
    response = client.post("/api/auth/login", json={...})

    assert response.headers["Cache-Control"] == "no-store"
    assert response.headers["Pragma"] == "no-cache"

def test_cors_restricted_origins(client):
    """测试CORS限制跨域来源"""
    response = client.options(
        "/api/products",
        headers={"Origin": "https://evil.com"}
    )

    # 生产环境应拒绝未知来源
    assert "access-control-allow-origin" not in response.headers or \
           response.headers["access-control-allow-origin"] != "https://evil.com"
```

### 测试盲区与改进建议

**当前不足**:
1. ❌ **前端E2E测试缺失**: 无真实设备上的完整用户流程测试
2. ❌ **性能测试空白**: 无压力测试、并发测试
3. ❌ **无障碍测试**: 未覆盖残障人士使用场景
4. ⚠️ **边缘情况覆盖不全**: 网络超时、服务端5xx错误的UI反馈测试不足
5. ⚠️ **国际化测试**: 多语言切换后的布局适配测试缺失

**建议补充**:
```yaml
优先级P0:
  - 添加关键路径E2E测试 (登录→浏览→下单→支付)
  - 补充API压力测试 (Locust/k6)
  - 增加异常场景测试 (断网/弱网/服务器宕机)

优先级P1:
  - Widget快照测试 (Golden Tests)
  - 无障碍审计 (axe-core)
  - 多语言RTL布局测试

优先级P2:
  - 视觉回归测试 (Percy/Applitools)
  - 兼容性测试矩阵 (不同Android/iOS版本)
  - 安全渗透测试 (OWASP ZAP自动化扫描)
```

---

## CI/CD 流水线

### GitHub Actions工作流

**触发条件**:
```yaml
on:
  push:
    branches: [master, main, dev]
  pull_request:
    branches: [master, main, dev]
```

**Jobs执行顺序**:

```mermaid
graph LR
    A[Checkout Code] --> B[Setup Java 17]
    B --> C[Setup Flutter 3.32.0]
    C --> D[flutter pub get]
    D --> E[build_runner生成代码]
    E --> F[flutter analyze]
    F --> G[flutter test]
    G --> H{Branch?}
    H -->|main/master| I[Build APK/AAB]
    H -->|dev| J[Skip Build]
    I --> K[Upload Artifacts]
    K --> L[Deploy Backend]
    L --> M[Deploy Web]
    M --> N[Health Check]
```

**详细步骤**:

#### Job 1: flutter-build

```yaml
jobs:
  flutter-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter 3.32.0
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Static analysis
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        if: github.ref == 'refs/heads/main'
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: huiyuyuan_app/coverage/lcov.info
```

#### Job 2: deploy-backend (仅main分支)

```yaml
  deploy-backend:
    needs: flutter-build
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to ECS
        env:
          SERVER_HOST: ${{ secrets.SERVER_HOST }}
          SERVER_USER: ${{ secrets.SERVER_USER }}
          SERVER_SSH_KEY: ${{ secrets.SERVER_SSH_KEY }}
        run: |
          echo "$SERVER_SSH_KEY" > key.pem
          chmod 600 key.pem

          # SCP上传后端代码
          scp -i key.pem -r huiyuyuan_app/backend/ \
            $SERVER_USER@$SERVER_HOST:/srv/huiyuyuan/backend/

          # SSH执行部署脚本
          ssh -i key.pem $SERVER_USER@$SERVER_HOST << 'EOF'
            cd /srv/huiyuyuan/backend
            source venv/bin/activate
            pip install -r requirements.txt

            # Alembic数据库迁移
            alembic upgrade head

            # 重启服务
            systemctl restart huiyuyuan-backend

            # 健康检查 (最多重试5次)
            for i in {1..5}; do
              if curl -f http://127.0.0.1:8000/api/health; then
                echo "✅ Backend healthy"
                exit 0
              fi
              sleep 3
            done
            echo "❌ Health check failed"
            exit 1
          EOF
```

#### Job 3: deploy-web (仅main分支)

```yaml
  deploy-web:
    needs: flutter-build
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'

      - name: Build Web
        env:
          DASHSCOPE_API_KEY: ${{ secrets.DASHSCOPE_API_KEY }}
        run: |
          cd huiyuyuan_app
          flutter build web --release

      - name: Deploy to Nginx
        env:
          SERVER_HOST: ${{ secrets.SERVER_HOST }}
          SERVER_SSH_KEY: ${{ secrets.SERVER_SSH_KEY }}
        run: |
          echo "$SERVER_SSH_KEY" > key.pem
          chmod 600 key.pem

          scp -i key.pem -r huiyuyuan_app/build/web/* \
            root@$SERVER_HOST:/var/www/huiyuyuan/

          ssh -i key.pem root@$SERVER_HOST "nginx -t && systemctl reload nginx"
```

### 本地部署脚本 (PowerShell)

**一键部署命令**:
```powershell
# 全量部署
.\scripts\deploy.ps1

# 仅部署后端
.\scripts\deploy.ps1 -Target backend

# 仅部署前端
.\scripts\deploy.ps1 -Target web

# 干跑模式 (不实际执行)
.\scripts\deploy.ps1 -DryRun

# 跳过静态分析 (快速部署)
.\scripts\deploy.ps1 -SkipAnalyze
```

**部署流程**:
```
1. 前置检查
   ├─ Git状态检查 (是否有未提交更改)
   ├─ 依赖完整性 (flutter pub get / pip install)
   └─ 静态分析 (dart analyze / flake8)

2. 构建阶段
   ├─ Flutter Web构建 → build/web/
   ├─ Flutter APK构建 (可选) → build/app/outputs/
   └─ Python依赖打包 (可选) → requirements freeze

3. 上传阶段
   ├─ SCP上传后端代码 → /srv/huiyuyuan/backend/
   ├─ SCP上传前端静态文件 → /var/www/huiyuyuan/
   └─ SCP上传Nginx配置 → /etc/nginx/conf.d/

4. 远程执行
   ├─ Alembic数据库迁移
   ├─ pip install -r requirements.txt
   ├─ systemctl restart huiyuyuan-backend
   ├─ nginx -t && systemctl reload nginx
   └─ 健康检查 (curl /api/health, 最多5次重试)

5. 回滚机制
   └─ 部署前自动创建快照 → /opt/huiyuyuan/snapshots/<timestamp>/
       支持手动回滚: .\deploy.ps1 -Rollback 20260410_120000
```

### 数据库备份策略

**定时备份** (cron job):
```bash
# /opt/huiyuyuan/backup.sh
#!/bin/bash
BACKUP_DIR="/opt/huiyuyuan/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="huiyuyuan_$TIMESTAMP.sql.gz"

pg_dump -U postgres huiyuyuan | gzip > "$BACKUP_DIR/$FILENAME"

# 保留最近30天备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: $FILENAME"
```

**Cron配置**:
```cron
# 每天凌晨3点备份
0 3 * * * /opt/huiyuyuan/backup.sh >> /var/log/db_backup.log 2>&1
```

**手动触发**:
```powershell
.\scripts\deploy.ps1 -Target db-init  # 初始化新环境
ssh root@47.112.98.191 "bash /opt/huiyuyuan/backup.sh"  # 立即备份
```

---

## 发现的问题与风险

### 🔴 P0 - 严重问题 (必须立即修复)

#### 1. 支付系统未接入真实渠道
**现状**:
- 所有支付均为Mock状态 (`wx_your_app_id`, `alipay_mock`)
- 无法完成真实交易闭环
- 订单状态手动确认,存在人为失误风险

**影响**:
- ❌ 无法正式上线运营
- ❌ 财务对账困难
- ⚠️ 资金安全风险 (人工确认易出错)

**修复方案**:
```dart
// 优先级排序
1. 接入微信支付JSAPI (公众号/H5)
2. 接入支付宝WAP支付
3. 实现支付回调验签逻辑
4. 添加退款接口
5. 对接第三方支付聚合平台 (Ping++/BeeCloud)
```

#### 2. 阿里云SMS资质未完成
**现状**:
- 验证码固定为`8888` (开发万能码)
- 无真实短信发送能力
- 用户注册/找回密码功能不可用

**影响**:
- ❌ 新用户无法注册
- ❌ 密码找回功能瘫痪
- ⚠️ 安全风险 (万能验证码泄露)

**修复方案**:
```
1. 申请阿里云短信服务资质
   ├─ 企业营业执照认证
   ├─ 短信签名审核 (汇玉源)
   └─ 短信模板审核 (验证码:${code})

2. 配置环境变量
   export ALIYUN_ACCESS_KEY_ID=LTAIxxxx
   export ALIYUN_ACCESS_KEY_SECRET=xxxx
   export SMS_TEMPLATE_CODE=SMS_123456789

3. 移除开发万能码
   // config/app_config.dart
   static const bool allowDevUniversalCaptcha = false; // 生产环境禁用
```

#### 3. Android签名密钥未配置
**现状**:
- Debug APK可直接构建
- Release APK缺少keystore配置
- 无法上架Google Play/华为应用市场

**影响**:
- ❌ 无法发布正式版APK
- ❌ 无法启用ProGuard混淆
- ⚠️ 应用被反编译风险高

**修复方案**:
```powershell
# 生成签名密钥
.\scripts\generate_keystore.ps1

# 配置android/key.properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=huiyuyuan
storeFile=../huiyuyuan.jks

# 修改android/app/build.gradle
signingConfigs {
    release {
        def keystoreProperties = new Properties()
        keystoreProperties.load(new FileInputStream(rootProject.file("key.properties")))

        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

#### 4. 购物车/订单/收藏数据未云端同步
**现状**:
- 数据存储于本地SharedPreferences
- 更换设备后数据丢失
- 多设备登录数据不同步

**影响**:
- ⚠️ 用户体验差 (换手机购物车清空)
- ⚠️ 数据可靠性低 (卸载即丢失)
- ⚠️ 无法实现跨设备续购

**修复方案**:
```dart
// 当前实现 (本地存储)
await _prefs.setString('cart_items', jsonEncode(cartItems));

// 改进方案 (云端同步)
Future<void> syncCartToCloud() async {
  final user = ref.read(authProvider).value;
  if (user == null) return;

  await backendService.syncCart(
    userId: user.id,
    items: cartItems.map((item) => item.toJson()).toList(),
  );
}

// 登录时拉取云端数据
Future<List<CartItem>> loadCartFromCloud(String userId) async {
  final response = await api.get('/api/cart/$userId');
  return (response.data as List)
      .map((json) => CartItem.fromJson(json))
      .toList();
}
```

### 🟡 P1 - 重要问题 (近期需解决)

#### 5. 隐私政策页面不可访问
**现状**:
- `privacy_policy_screen.dart`已实现
- 但URL指向本地Asset或占位符
- 应用商店审核需要提供可访问的HTTPS URL

**影响**:
- ❌ Apple App Store审核拒绝
- ❌ Google Play合规性问题
- ⚠️ 法律风险 (GDPR/个人信息保护法)

**修复方案**:
```
1. 创建独立HTML页面
   docs/legal/privacy_policy.html

2. 部署到生产服务器
   scp privacy_policy.html root@47.112.98.191:/var/www/huiyuyuan/legal/

3. 更新App内链接
   // app_config.dart
   static const String privacyPolicyUrl =
       'https://xn--lsws2cdzg.top/legal/privacy_policy.html';

4. 确保HTTPS可访问
   curl -I https://xn--lsws2cdzg.top/legal/privacy_policy.html
   # HTTP/2 200
```

#### 6. Firebase Crashlytics未接入
**现状**:
- 无线上崩溃监控
- 用户遇到Crash无法自动上报
- 排查线上问题依赖用户反馈

**影响**:
- ⚠️ 故障发现滞后
- ⚠️ 难以定位偶发性Bug
- ⚠️ 无法统计崩溃率

**修复方案**:
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_crashlytics: ^3.4.0

# main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // 非Debug模式启用Crashlytics
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(MyApp());
}
```

#### 7. WebSocket连接稳定性不足
**现状**:
- 基础WebSocket实现已完成
- 缺少自动重连机制
- 网络切换后连接断开无提示

**影响**:
- ⚠️ 实时通知丢失
- ⚠️ 在线状态不准确
- ⚠️ 用户体验中断

**修复方案**:
```dart
class NotificationRealtimeService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  Future<void> connect() async {
    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse('wss://${ApiConfig.productionHost}/ws/notifications'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      _reconnectAttempts = 0;
      _listenToMessages();
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      logger.warning('达到最大重连次数,停止重试');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      logger.info('尝试第$_reconnectAttempts次重连...');
      connect();
    });
  }

  void _listenToMessages() {
    _channel?.stream.listen(
      (message) {
        _handleNotification(message);
      },
      onError: (error) {
        logger.error('WebSocket错误: $error');
        _scheduleReconnect();
      },
      onDone: () {
        logger.info('WebSocket连接关闭');
        _scheduleReconnect();
      },
    );
  }
}
```

#### 8. 图片上传未使用OSS
**现状**:
- 图片存储在服务器本地文件系统 (`/srv/huiyuyuan/backend/uploads/`)
- 单点故障风险
- CDN加速未启用

**影响**:
- ⚠️ 服务器磁盘空间有限
- ⚠️ 图片加载速度慢 (无CDN)
- ⚠️ 备份复杂度高

**修复方案**:
```python
# services/oss_service.py
import oss2

class OSSService:
    def __init__(self):
        self.auth = oss2.Auth(
            os.getenv('OSS_ACCESS_KEY_ID'),
            os.getenv('OSS_ACCESS_KEY_SECRET')
        )
        self.bucket = oss2.Bucket(
            self.auth,
            'https://oss-cn-hangzhou.aliyuncs.com',
            'huiyuyuan-images'
        )

    async def upload_image(self, file: UploadFile) -> str:
        """上传图片到OSS,返回公开URL"""
        object_name = f"products/{uuid.uuid4()}_{file.filename}"

        self.bucket.put_object(
            object_name,
            file.file.read(),
            headers={'Content-Type': file.content_type}
        )

        # 生成带签名的临时URL (私有Bucket)
        # url = self.bucket.sign_url('GET', object_name, 3600)

        # 或使用公共读Bucket直接返回
        return f"https://huiyuyuan-images.oss-cn-hangzhou.aliyuncs.com/{object_name}"
```

### 🟢 P2 - 优化建议 (中长期改进)

#### 9. 前端Widget测试覆盖率低
**现状**: 23+屏幕,仅少数有Widget测试

**建议**:
- 为核心屏幕编写Golden Tests (快照测试)
- 增加交互测试 (点击/滑动/输入)
- 目标覆盖率: 80%+

#### 10. 后端缺少性能基准测试
**现状**: 无压力测试数据

**建议**:
```python
# 使用Locust进行负载测试
from locust import HttpUser, task, between

class ApiUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def browse_products(self):
        self.client.get("/api/products?skip=0&limit=20")

    @task(1)
    def view_product_detail(self):
        self.client.get("/api/products/prod_123")

    @task(2)
    def search_products(self):
        self.client.get("/api/products/search?q=翡翠")
```

#### 11. 数据库查询未充分优化
**现状**:
- 部分N+1查询问题
- 缺少慢查询日志

**建议**:
```python
# 启用SQLAlchemy慢查询日志
from sqlalchemy import event

@event.listens_for(Engine, "before_cursor_execute")
def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    conn.info.setdefault('query_start_time', []).append(time.time())

@event.listens_for(Engine, "after_cursor_execute")
def receive_after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total = time.time() - conn.info['query_start_time'].pop(-1)
    if total > 1.0:  # 超过1秒的查询
        logger.warning(f"Slow query ({total:.2f}s): {statement[:200]}")
```

#### 12. 国际化不完整
**现状**: zh_CN/en/zh_TW三语言,但部分硬编码中文

**建议**:
- 运行脚本扫描所有`.t('key')`调用
- 补充缺失的翻译键
- 增加日语/韩语支持 (拓展海外市场)

#### 13. 无障碍(Accessibility)支持薄弱
**现状**: 未针对视障/听障用户优化

**建议**:
```dart
// 为关键组件添加Semantics
Semantics(
  label: '添加到购物车按钮',
  hint: '双击将此商品加入购物车',
  child: ElevatedButton(
    onPressed: () => addToCart(product),
    child: Text('加入购物车'),
  ),
)

// 确保颜色对比度符合WCAG 2.1 AA标准
// 使用contrast_ratio包检测
assert(ContrastRatio.between(
  foreground: Colors.white,
  background: JewelryColors.emeraldGreen,
) >= 4.5);
```

#### 14. 监控告警体系不完善
**现状**: 仅基础健康检查,无业务指标监控

**建议**:
```yaml
监控维度:
  基础设施:
    - CPU/Memory/Disk使用率
    - 网络带宽
    - PostgreSQL连接数

  应用层:
    - API响应时间P95/P99
    - 错误率 (5xx比例)
    - QPS峰值

  业务层:
    - 日活跃用户(DAU)
    - 订单转化率
    - 支付成功率
    - AI对话调用量

工具选型:
  - Prometheus + Grafana (指标采集+可视化)
  - ELK Stack (日志聚合分析)
  - Sentry (错误追踪)
  - UptimeRobot (外部可用性监控)
```

---

## 改进建议路线图

### Phase 1: 上线前必做 (1-2周)

```mermaid
gantt
    title Phase 1 上线前必做任务
    dateFormat  YYYY-MM-DD
    section 支付接入
    微信支付SDK集成           :crit, p1_1, 2026-04-11, 3d
    支付宝SDK集成             :crit, p1_2, after p1_1, 3d
    支付回调验签              :crit, p1_3, after p1_2, 2d
    沙箱环境测试              :crit, p1_4, after p1_3, 2d

    section 短信服务
    阿里云SMS资质申请         :crit, p1_5, 2026-04-11, 5d
    短信模板配置              :p1_6, after p1_5, 1d
    移除万能验证码            :crit, p1_7, after p1_6, 1d

    section Android发布
    生成Keystore签名          :crit, p1_8, 2026-04-11, 1d
    配置Release构建           :p1_9, after p1_8, 1d
    ProGuard规则调优          :p1_10, after p1_9, 2d

    section 合规性
    隐私政策页面部署          :crit, p1_11, 2026-04-11, 2d
    用户协议页面部署          :p1_12, after p1_11, 1d
    GDPR合规自查              :p1_13, after p1_12, 2d
```

**验收标准**:
- ✅ 真实支付流程跑通 (微信+支付宝)
- ✅ 新用户可通过短信验证码注册
- ✅ Release APK可安装且签名正确
- ✅ 隐私政策URL可HTTPS访问
- ✅ 通过Apple TestFlight审核

### Phase 2: 稳定性提升 (2-4周)

**重点任务**:
1. **云端数据同步**
   - 购物车/订单/收藏迁移到PostgreSQL
   - 实现增量同步算法 (减少流量消耗)
   - 冲突解决策略 (Last Write Wins)

2. **Firebase集成**
   - Crashlytics崩溃监控
   - Analytics用户行为分析
   - Remote Config动态配置

3. **WebSocket优化**
   - 指数退避重连
   - 心跳保活 (ping/pong)
   - 离线消息队列

4. **OSS迁移**
   - 历史图片批量上传到OSS
   - 启用CDN加速
   - 图片压缩与WebP转换

**预期成果**:
- 崩溃率 < 0.5%
- 图片加载速度提升50%+
- 多设备数据一致性100%

### Phase 3: 性能与体验优化 (1-2月)

**技术债务清理**:
- [ ] 重构冗余代码 (DRY原则)
- [ ] 数据库索引优化 (EXPLAIN ANALYZE)
- [ ] API响应缓存 (Redis TTL策略)
- [ ] 前端Bundle体积优化 (Tree Shaking)

**用户体验增强**:
- [ ] Skeleton Screen骨架屏
- [ ] 下拉刷新/上拉加载更多
- [ ] 深色模式完善
- [ ] 手势操作优化 (左滑删除等)

**国际化扩展**:
- [ ] 日语/韩语翻译
- [ ] RTL布局支持 (阿拉伯语)
- [ ] 货币符号自适应

### Phase 4: 智能化升级 (长期规划)

**AI能力深化**:
1. **个性化推荐引擎**
   ```python
   # 基于协同过滤
   def recommend_products(user_id: str) -> List[Product]:
       # 分析用户浏览历史
       viewed_categories = get_user_viewed_categories(user_id)

       # 查找相似用户
       similar_users = find_similar_users(user_id)

       # 推荐他们喜欢但你没看过的商品
       recommendations = collaborative_filtering(similar_users, viewed_categories)

       return recommendations[:10]
   ```

2. **智能客服知识库**
   - RAG检索增强生成
   - 常见问题FAQ自动匹配
   - 多轮对话上下文记忆

3. **图像搜索以图搜图**
   ```python
   # 使用CLIP模型提取特征向量
   def search_by_image(image_bytes: bytes) -> List[Product]:
       embedding = clip_model.encode_image(image_bytes)

       # 向量相似度搜索 (Faiss)
       similar_indices = faiss_index.search(embedding, k=10)

       return [products[i] for i in similar_indices]
   ```

4. **价格趋势预测**
   - 历史价格数据分析
   - 季节性波动建模
   - 购买时机建议

---

## 附录:关键文件索引

### 前端核心文件

| 文件路径 | 作用 | 行数 | 复杂度 |
|---------|------|------|--------|
| `lib/main.dart` | 应用入口 | ~40 | Low |
| `lib/screens/main_screen.dart` | 主导航壳 | ~150 | Medium |
| `lib/screens/login_screen.dart` | 登录页 | ~200 | Medium |
| `lib/providers/auth_provider.dart` | 认证状态管理 | ~180 | High |
| `lib/services/api_service.dart` | HTTP客户端封装 | ~250 | High |
| `lib/services/ai_service.dart` | AI对话聚合层 | ~120 | Medium |
| `lib/services/ai_dashscope_service.dart` | DashScope直连 | ~100 | Medium |
| `lib/config/api_config.dart` | API配置 | ~80 | Low |
| `lib/themes/colors.dart` | 品牌色系定义 | ~60 | Low |
| `lib/l10n/app_strings.dart` | 翻译字典 | ~500 | Low |

### 后端核心文件

| 文件路径 | 作用 | 行数 | 复杂度 |
|---------|------|------|--------|
| `backend/main.py` | FastAPI入口 | ~100 | Low |
| `backend/database.py` | DB连接管理 | ~80 | Medium |
| `backend/security.py` | JWT+bcrypt | ~120 | Medium |
| `backend/routers/auth.py` | 认证路由 | ~150 | High |
| `backend/routers/orders.py` | 订单路由 | ~200 | High |
| `backend/routers/payments.py` | 支付路由 | ~180 | High |
| `backend/services/ai_service.py` | AI图片识别 | ~100 | Medium |
| `backend/services/payment_service.py` | 支付状态机 | ~150 | High |
| `backend/schemas/order.py` | 订单Pydantic模型 | ~80 | Medium |

### 配置文件

| 文件路径 | 用途 |
|---------|------|
| `.github/workflows/ci.yml` | CI/CD流水线 |
| `scripts/deploy.ps1` | PowerShell部署脚本 |
| `backend/.env.example` | 环境变量模板 |
| `backend/requirements.txt` | Python依赖 |
| `huiyuyuan_app/pubspec.yaml` | Flutter依赖 |
| `huiyuyuan_app/analysis_options.yaml` | Dart Lint规则 |

### 文档资源

| 文档路径 | 说明 |
|---------|------|
| `docs/planning/v4_master_plan.md` | v4.0总体规划 |
| `docs/guides/deployment_guide_updated.md` | 生产部署指南⭐ |
| `docs/guides/production_security_checklist_v2.md` | 安全清单⭐ |
| `docs/guides/ai_service_guide.md` | AI服务配置⭐ |
| `docs/design/design_system.md` | Liquid Glass设计规范 |
| `AGENTS.md` | AI助手参考指南 |
| `CLAUDE.md` | Claude专用指南 |

---

## 总结

### 项目优势

✅ **架构清晰**: 前后端分离,模块化程度高
✅ **技术栈现代**: Flutter 3.27 + FastAPI + PostgreSQL
✅ **AI能力突出**: DashScope双模态(文本+视觉)
✅ **设计精美**: Liquid Glass毛玻璃风格,品牌辨识度高
✅ **测试扎实**: 657个测试用例覆盖核心逻辑
✅ **CI/CD完善**: GitHub Actions自动化部署

### 主要短板

❌ **支付未接入**: 无法形成商业闭环
❌ **SMS资质缺失**: 用户注册功能受限
❌ **数据本地化**: 云端同步能力不足
❌ **监控薄弱**: 缺乏线上问题预警机制

### 总体评价

**汇玉源v4.0**是一个**架构优秀、功能完整、距离生产就绪仅一步之遥**的全栈项目。

- **代码质量**: ★★★★☆ (4/5)
- **功能完备度**: ★★★★☆ (4/5)
- **安全性**: ★★★☆☆ (3/5, 待加固)
- **可维护性**: ★★★★☆ (4/5)
- **生产就绪度**: ★★★☆☆ (3/5, 待支付/SMS接入)

**下一步行动**: 优先完成Phase 1的4项P0任务,即可进入小范围内测阶段。

---

**报告生成者**: GitHub Copilot (Claude Opus 4.6)
**审查日期**: 2026-04-10
**下次审查建议**: 完成Phase 1后进行复审
