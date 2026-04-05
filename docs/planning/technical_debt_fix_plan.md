# 汇玉源技术债务修复计划

> 更新日期: 2026-03-17
> 状态: 进行中
> 优先级: 高

---

## 一、技术债务概述

### 1.1 当前技术债务状态
根据代码分析，项目存在以下主要技术债务：

1. **后端架构问题**：
   - `main.py` 单文件2246行，需要模块化拆分
   - 内存存储与数据库存储混合使用
   - 部分安全配置不完善

2. **前端架构问题**：
   - 硬编码测试账号和Mock数据
   - 部分功能未对接真实API
   - 错误处理机制不完善

3. **数据风险**：
   - 内存存储数据可靠性不足
   - 数据备份策略不完善
   - 数据一致性检查缺失

### 1.2 修复优先级
| 优先级 | 问题类型 | 影响范围 | 预计工时 |
|--------|---------|---------|---------|
| 🔴 P0 | 安全配置修复 | 全系统 | 1天 |
| 🔴 P0 | 内存存储迁移 | 数据可靠性 | 2天 |
| 🔴 P0 | main.py模块化 | 代码维护性 | 2天 |
| 🟡 P1 | 前端Mock数据替换 | 功能完整性 | 2天 |
| 🟡 P1 | 错误处理完善 | 用户体验 | 1天 |
| 🟢 P2 | 代码规范优化 | 代码质量 | 1天 |

---

## 二、后端技术债务修复

### 2.1 main.py模块化拆分

#### 当前状态
- **文件**: `backend/main.py`
- **行数**: 2246行
- **问题**: 单文件包含所有路由、模型、服务逻辑

#### 目标结构
```
backend/
├── main.py              # 应用入口 (~100行)
├── config.py            # 配置管理
├── database.py          # 数据库连接
├── security.py          # 安全相关
├── store.py             # 内存存储 (降级方案)
├── logging_config.py    # 日志配置
├── models/              # SQLAlchemy模型
│   ├── __init__.py
│   ├── user.py
│   ├── product.py
│   ├── order.py
│   ├── cart.py
│   ├── review.py
│   ├── shop.py
│   ├── address.py
│   ├── payment.py
│   ├── notification.py
│   └── device.py
├── routers/             # API路由
│   ├── __init__.py
│   ├── auth.py
│   ├── products.py
│   ├── orders.py
│   ├── cart.py
│   ├── users.py
│   ├── admin.py
│   ├── upload.py
│   ├── ai.py
│   ├── shops.py
│   ├── favorites.py
│   ├── reviews.py
│   ├── notifications.py
│   └── ws.py
├── services/            # 业务服务
│   ├── __init__.py
│   ├── ai_service.py
│   ├── sms_service.py
│   ├── payment_service.py
│   ├── notification_service.py
│   └── logistics_service.py
├── schemas/             # Pydantic模型
│   ├── __init__.py
│   ├── auth.py
│   ├── product.py
│   ├── order.py
│   ├── cart.py
│   ├── user.py
│   ├── review.py
│   ├── shop.py
│   └── common.py
└── middleware/          # 中间件
    ├── __init__.py
    ├── auth.py
    ├── rate_limit.py
    └── logging.py
```

#### 拆分步骤
1. **创建目录结构** (已完成)
2. **提取配置模块** (已完成)
3. **提取数据库模块** (已完成)
4. **提取安全模块** (已完成)
5. **提取路由模块** (已完成)
6. **提取服务模块** (进行中)
7. **提取模型模块** (待开始)
8. **提取中间件模块** (待开始)
9. **更新main.py** (待开始)

#### 验证标准
- [ ] `main.py` 行数 ≤ 100行
- [ ] 所有49个API端点正常工作
- [ ] `curl /api/health` 返回200
- [ ] 代码结构清晰，职责分离

### 2.2 内存存储迁移到PostgreSQL

#### 当前状态
- **内存存储**: `store.py` 包含所有数据字典
- **数据库**: PostgreSQL已配置但部分功能未使用
- **问题**: 数据可靠性不足，重启丢失

#### 迁移计划
1. **用户数据迁移**:
   - 将 `USERS_DB` 迁移到 `users` 表
   - 保持密码哈希兼容性
   - 实现用户CRUD操作

2. **商品数据迁移**:
   - 将 `PRODUCTS_DB` 迁移到 `products` 表
   - 保持商品ID格式兼容
   - 实现商品CRUD操作

3. **订单数据迁移**:
   - 将 `ORDERS_DB` 迁移到 `orders` 表
   - 实现订单状态管理
   - 实现订单查询和统计

4. **购物车数据迁移**:
   - 将 `CARTS_DB` 迁移到 `cart_items` 表
   - 实现购物车CRUD操作
   - 实现购物车合并逻辑

5. **收藏数据迁移**:
   - 将 `FAVORITES_DB` 迁移到 `favorites` 表
   - 实现收藏CRUD操作

6. **评价数据迁移**:
   - 将 `REVIEWS_DB` 迁移到 `reviews` 表
   - 实现评价CRUD操作

#### 迁移策略
```python
# 双写策略：同时写入内存和数据库
async def create_user(user_data: dict):
    # 1. 写入数据库
    if DB_AVAILABLE:
        db_user = User(**user_data)
        db.add(db_user)
        await db.commit()
    
    # 2. 写入内存（降级方案）
    USERS_DB[user_data["id"]] = user_data
    
    return user_data

# 读取策略：优先从数据库读取
async def get_user(user_id: str):
    # 1. 尝试从数据库读取
    if DB_AVAILABLE:
        db_user = await db.query(User).filter(User.id == user_id).first()
        if db_user:
            return db_user.to_dict()
    
    # 2. 降级到内存存储
    return USERS_DB.get(user_id)
```

#### 验证标准
- [ ] 所有数据表创建完成
- [ ] 数据迁移脚本执行成功
- [ ] 双写机制正常工作
- [ ] 数据一致性验证通过
- [ ] 性能测试通过

### 2.3 安全配置修复

#### 当前问题
1. **CORS配置宽松**: `allow_origins=["*"]`
2. **JWT密钥硬编码**: 默认密钥未强制替换
3. **SMS验证绕过**: 固定验证码8888
4. **密码存储**: 部分使用明文存储

#### 修复方案
1. **CORS配置修复**:
```python
# config.py
_origins_raw = os.getenv("ALLOWED_ORIGINS", "")
if _origins_raw and _origins_raw != "*":
    ALLOWED_ORIGINS = [o.strip() for o in _origins_raw.split(",") if o.strip()]
else:
    if APP_ENV == "production":
        ALLOWED_ORIGINS = [
            "https://xn--lsws2cdzg.top",
            "https://www.xn--lsws2cdzg.top",
        ]
        logger.warning("ALLOWED_ORIGINS 未配置，默认仅允许生产域名")
    else:
        ALLOWED_ORIGINS = ["*"]
```

2. **JWT密钥强制配置**:
```python
# config.py
_jwt_secret = os.getenv("JWT_SECRET_KEY", "")
if not _jwt_secret:
    if APP_ENV == "production":
        raise RuntimeError(
            "JWT_SECRET_KEY 未设置！生产环境必须配置。\n"
            "   生成方式: python -c \"import secrets; print(secrets.token_hex(32))\""
        )
    _jwt_secret = "dev_only_" + secrets.token_hex(16)
    logger.warning("JWT_SECRET_KEY 未配置，使用随机开发密钥（重启失效）")
```

3. **SMS验证修复**:
```python
# services/sms_service.py
async def send_sms_code(phone: str, code: str):
    if not REDIS_AVAILABLE:
        if APP_ENV == "production":
            raise HTTPException(status_code=503, detail="SMS服务暂时不可用")
        # 开发环境使用固定验证码
        return {"success": True, "code": "8888"}
    
    # 生产环境使用Redis存储验证码
    redis_key = f"sms_code:{phone}"
    await redis_client.setex(redis_key, 300, code)  # 5分钟过期
    return {"success": True}
```

4. **密码存储修复**:
```python
# security.py
def hash_password(password: str) -> str:
    """使用bcrypt哈希密码"""
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证密码"""
    return bcrypt.checkpw(plain_password.encode(), hashed_password.encode())
```

#### 验证标准
- [ ] CORS配置限制为指定域名
- [ ] JWT密钥必须从环境变量读取
- [ ] SMS验证码使用Redis存储
- [ ] 所有密码使用bcrypt哈希
- [ ] 安全扫描通过

---

## 三、前端技术债务修复

### 3.1 移除硬编码测试账号

#### 当前问题
- `app_config.dart` 包含硬编码测试账号
- 登录页面预填测试账号
- 部分功能依赖测试账号

#### 修复方案
1. **移除硬编码账号**:
```dart
// lib/config/app_config.dart
class AppConfig {
  // 移除硬编码账号
  // static const String testAdminPhone = '18937766669';
  // static const String testAdminPassword = 'admin123';
  
  // 保留配置项
  static const String apiBaseUrl = 'https://xn--lsws2cdzg.top';
  static const bool useMockApi = false; // 生产环境设为false
}
```

2. **登录页面优化**:
```dart
// lib/screens/login_screen.dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // 开发环境显示提示，不预填账号
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开发环境：请使用测试账号登录')),
        );
      });
    }
  }
}
```

3. **API服务统一认证**:
```dart
// lib/services/api_service.dart
class ApiService {
  static String? _authToken;
  
  static void setAuthToken(String token) {
    _authToken = token;
  }
  
  static Map<String, String> get headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }
}
```

### 3.2 实现真实API调用替代Mock数据

#### 当前问题
- 多个页面使用Mock数据
- 部分功能未对接后端API
- 数据一致性无法保证

#### 修复方案
1. **通知页面**:
```dart
// lib/screens/notification/notification_screen.dart
// BEFORE: _generateSampleData()
// AFTER: API调用
class NotificationScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    
    return notifications.when(
      data: (items) => _buildNotificationList(items),
      loading: () => const SkeletonLoader(),
      error: (e, _) => _buildEmptyState('加载失败'),
    );
  }
}
```

2. **店铺雷达页面**:
```dart
// lib/screens/shop/shop_radar.dart
// BEFORE: _loadMockData()
// AFTER: API调用
class ShopRadarScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(shopsProvider);
    
    return shops.when(
      data: (items) => _buildShopList(items),
      loading: () => const SkeletonLoader(),
      error: (e, _) => _buildEmptyState('加载失败'),
    );
  }
}
```

3. **浏览历史页面**:
```dart
// lib/screens/profile/browse_history_screen.dart
// BEFORE: 显示 "商品 {id}"
// AFTER: 显示真实商品信息
class BrowseHistoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(browseHistoryProvider);
    
    return history.when(
      data: (items) => _buildHistoryList(items),
      loading: () => const SkeletonLoader(),
      error: (e, _) => _buildEmptyState('加载失败'),
    );
  }
}
```

### 3.3 错误处理机制完善

#### 当前问题
- 错误处理不统一
- 用户反馈不明确
- 网络错误处理不完善

#### 修复方案
1. **统一错误处理**:
```dart
// lib/services/api_service.dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;
  
  ApiException(this.statusCode, this.message, this.data);
  
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(
          e.response!.statusCode ?? 500,
          e.response!.statusMessage ?? '请求失败',
          e.response!.data,
        );
      } else {
        throw ApiException(0, '网络连接失败', null);
      }
    } catch (e) {
      throw ApiException(500, '未知错误', e);
    }
  }
}
```

2. **用户友好错误提示**:
```dart
// lib/widgets/common/error_widget.dart
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## 四、数据风险修复

### 4.1 数据备份策略

#### 当前状态
- 有备份脚本但未定期执行
- 备份验证机制不完善
- 恢复流程不明确

#### 修复方案
1. **自动备份脚本**:
```bash
#!/bin/bash
# scripts/db_backup.sh
BACKUP_DIR="/opt/huiyuyuan/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/db_backup_$DATE.sql.gz"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
pg_dump -U huyy_user huiyuyuan | gzip > $BACKUP_FILE

# 验证备份
if [ $? -eq 0 ]; then
    echo "备份成功: $BACKUP_FILE"
    # 保留最近7天的备份
    find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +7 -delete
else
    echo "备份失败" >&2
    exit 1
fi
```

2. **备份验证脚本**:
```bash
#!/bin/bash
# scripts/verify_backup.sh
BACKUP_FILE=$1
TEMP_DB="huiyuyuan_verify"

# 创建临时数据库
createdb $TEMP_DB

# 恢复备份
gunzip -c $BACKUP_FILE | psql -U huyy_user $TEMP_DB

# 验证数据
TABLE_COUNT=$(psql -U huyy_user -d $TEMP_DB -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")

if [ $TABLE_COUNT -gt 0 ]; then
    echo "备份验证成功: $TABLE_COUNT 个表"
else
    echo "备份验证失败" >&2
fi

# 清理临时数据库
dropdb $TEMP_DB
```

3. **恢复流程文档**:
```markdown
# 数据库恢复流程

## 1. 停止应用服务
systemctl stop huiyuyuan

## 2. 恢复数据库
gunzip -c /opt/huiyuyuan/backups/db_backup_YYYYMMDD_HHMMSS.sql.gz | psql -U huyy_user huiyuyuan

## 3. 验证数据
psql -U huyy_user -d huiyuyuan -c "SELECT COUNT(*) FROM users;"

## 4. 启动应用服务
systemctl start huiyuyuan

## 5. 验证服务
curl http://localhost:8000/api/health
```

### 4.2 数据一致性检查

#### 当前问题
- 内存存储与数据库数据可能不一致
- 缺乏数据一致性验证机制
- 数据冲突处理不完善

#### 修复方案
1. **数据一致性检查脚本**:
```python
# scripts/check_data_consistency.py
import asyncio
from sqlalchemy import text
from database import SessionLocal
from store import USERS_DB, PRODUCTS_DB, ORDERS_DB

async def check_user_consistency():
    """检查用户数据一致性"""
    async with SessionLocal() as db:
        # 从数据库获取用户
        db_users = await db.execute(text("SELECT id, phone, username FROM users"))
        db_user_ids = {row[0] for row in db_users}
        
        # 从内存获取用户
        memory_user_ids = set(USERS_DB.keys())
        
        # 检查差异
        only_in_db = db_user_ids - memory_user_ids
        only_in_memory = memory_user_ids - db_user_ids
        
        if only_in_db:
            print(f"仅在数据库中的用户: {only_in_db}")
        if only_in_memory:
            print(f"仅在内存中的用户: {only_in_memory}")
        
        return len(only_in_db) == 0 and len(only_in_memory) == 0

async def main():
    """主检查函数"""
    checks = [
        ("用户数据", check_user_consistency),
        # 添加其他数据检查
    ]
    
    all_passed = True
    for name, check_func in checks:
        try:
            passed = await check_func()
            status = "✓" if passed else "✗"
            print(f"{status} {name}: {'通过' if passed else '失败'}")
            all_passed = all_passed and passed
        except Exception as e:
            print(f"✗ {name}: 检查失败 - {e}")
            all_passed = False
    
    return all_passed

if __name__ == "__main__":
    success = asyncio.run(main())
    exit(0 if success else 1)
```

2. **数据同步机制**:
```python
# services/data_sync_service.py
class DataSyncService:
    @staticmethod
    async def sync_user_to_db(user_id: str):
        """同步用户数据到数据库"""
        if user_id not in USERS_DB:
            return False
        
        user_data = USERS_DB[user_id]
        
        async with SessionLocal() as db:
            # 检查用户是否存在
            existing = await db.execute(
                text("SELECT id FROM users WHERE id = :id"),
                {"id": user_id}
            )
            
            if existing.fetchone():
                # 更新用户
                await db.execute(
                    text("""
                        UPDATE users 
                        SET phone = :phone, username = :username, 
                            password_hash = :password_hash, balance = :balance,
                            points = :points, updated_at = NOW()
                        WHERE id = :id
                    """),
                    {
                        "id": user_id,
                        "phone": user_data.get("phone"),
                        "username": user_data.get("username"),
                        "password_hash": user_data.get("password_hash"),
                        "balance": user_data.get("balance", 0),
                        "points": user_data.get("points", 0),
                    }
                )
            else:
                # 插入用户
                await db.execute(
                    text("""
                        INSERT INTO users (id, phone, username, password_hash, 
                                         user_type, balance, points)
                        VALUES (:id, :phone, :username, :password_hash,
                               :user_type, :balance, :points)
                    """),
                    {
                        "id": user_id,
                        "phone": user_data.get("phone"),
                        "username": user_data.get("username"),
                        "password_hash": user_data.get("password_hash"),
                        "user_type": user_data.get("user_type", "customer"),
                        "balance": user_data.get("balance", 0),
                        "points": user_data.get("points", 0),
                    }
                )
            
            await db.commit()
            return True
```

---

## 五、修复时间安排

### 5.1 第一阶段：安全修复 (Day 1)
- [ ] CORS配置修复
- [ ] JWT密钥强制配置
- [ ] SMS验证修复
- [ ] 密码存储修复

### 5.2 第二阶段：数据迁移 (Day 2-3)
- [ ] 用户数据迁移
- [ ] 商品数据迁移
- [ ] 订单数据迁移
- [ ] 购物车数据迁移
- [ ] 收藏数据迁移
- [ ] 评价数据迁移

### 5.3 第三阶段：架构优化 (Day 4-5)
- [ ] main.py模块化拆分
- [ ] 路由模块提取
- [ ] 服务模块提取
- [ ] 模型模块提取

### 5.4 第四阶段：前端修复 (Day 6-7)
- [ ] 移除硬编码测试账号
- [ ] 实现真实API调用
- [ ] 错误处理机制完善
- [ ] 用户体验优化

### 5.5 第五阶段：数据风险修复 (Day 8-9)
- [ ] 数据备份策略完善
- [ ] 数据一致性检查
- [ ] 数据同步机制
- [ ] 恢复流程文档

---

## 六、验证和测试

### 6.1 单元测试
```python
# tests/test_technical_debt.py
import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_cors_configuration():
    """测试CORS配置"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.options(
            "/api/products",
            headers={
                "Origin": "http://malicious-site.com",
                "Access-Control-Request-Method": "GET",
            }
        )
        # 应该拒绝恶意域名
        assert response.status_code == 400 or "Access-Control-Allow-Origin" not in response.headers

@pytest.mark.asyncio
async def test_jwt_required():
    """测试JWT必需"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/users/me")
        # 应该返回401未授权
        assert response.status_code == 401

@pytest.mark.asyncio
async def test_password_hashing():
    """测试密码哈希"""
    from security import hash_password, verify_password
    
    password = "test_password123"
    hashed = hash_password(password)
    
    # 验证密码
    assert verify_password(password, hashed)
    assert not verify_password("wrong_password", hashed)
```

### 6.2 集成测试
```python
# tests/test_integration.py
@pytest.mark.asyncio
async def test_user_registration_flow():
    """测试用户注册流程"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        # 1. 发送验证码
        sms_response = await client.post(
            "/api/auth/send-sms",
            json={"phone": "13800138000"}
        )
        assert sms_response.status_code == 200
        
        # 2. 验证验证码
        verify_response = await client.post(
            "/api/auth/verify-sms",
            json={"phone": "13800138000", "code": "123456"}
        )
        assert verify_response.status_code == 200
        
        # 3. 用户注册
        register_response = await client.post(
            "/api/auth/register",
            json={
                "phone": "13800138000",
                "password": "password123",
                "username": "测试用户"
            }
        )
        assert register_response.status_code == 200
        assert "token" in register_response.json()
```

### 6.3 性能测试
```python
# tests/test_performance.py
import asyncio
import time
from httpx import AsyncClient

async def test_concurrent_requests():
    """测试并发请求"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        start_time = time.time()
        
        # 并发100个请求
        tasks = []
        for i in range(100):
            task = client.get("/api/products")
            tasks.append(task)
        
        responses = await asyncio.gather(*tasks)
        
        end_time = time.time()
        duration = end_time - start_time
        
        # 验证所有请求成功
        success_count = sum(1 for r in responses if r.status_code == 200)
        assert success_count == 100
        
        # 验证响应时间
        assert duration < 10  # 100个请求应在10秒内完成
        
        print(f"100个并发请求完成，耗时: {duration:.2f}秒")
```

---

## 七、风险控制

### 7.1 技术风险
| 风险 | 影响 | 应对措施 |
|------|------|---------|
| 数据迁移失败 | 数据丢失 | 多重备份、回滚方案 |
| 性能下降 | 用户体验差 | 性能测试、监控告警 |
| 兼容性问题 | 功能异常 | 兼容性测试、渐进式迁移 |
| 安全漏洞 | 数据泄露 | 安全扫描、代码审查 |

### 7.2 时间风险
| 风险 | 影响 | 应对措施 |
|------|------|---------|
| 修复延期 | 计划打乱 | 预留缓冲时间、优先级调整 |
| 测试不充分 | 缺陷遗漏 | 测试覆盖、自动化测试 |
| 依赖阻塞 | 等待时间 | 提前准备、备选方案 |

### 7.3 业务风险
| 风险 | 影响 | 应对措施 |
|------|------|---------|
| 服务中断 | 业务损失 | 蓝绿部署、快速回滚 |
| 数据不一致 | 业务错误 | 数据验证、事务处理 |
| 用户投诉 | 品牌影响 | 提前通知、客服准备 |

---

## 八、成功标准

### 8.1 技术指标
1. **代码质量**: `main.py` ≤ 100行
2. **测试覆盖率**: ≥ 80%
3. **性能指标**: API响应时间 < 200ms
4. **安全指标**: 通过安全扫描

### 8.2 业务指标
1. **功能完整性**: 所有功能正常工作
2. **数据可靠性**: 数据持久化，不丢失
3. **用户体验**: 错误处理友好，反馈及时
4. **系统稳定性**: 99.9%可用性

### 8.3 运维指标
1. **备份成功率**: 100%
2. **恢复时间目标**: < 15分钟
3. **监控覆盖率**: 100%关键指标
4. **告警及时性**: 5分钟内响应

---

## 九、团队分工

### 9.1 Agent A - 后端架构师
- 负责main.py模块化拆分
- 负责内存存储迁移
- 负责安全配置修复
- 负责数据一致性检查

### 9.2 Agent B - 前端质量工程师
- 负责移除硬编码测试账号
- 负责实现真实API调用
- 负责错误处理机制完善
- 负责用户体验优化

### 9.3 Agent C - 测试与安全专家
- 负责安全扫描和测试
- 负责性能测试
- 负责集成测试
- 负责质量保证

### 9.4 Agent D - DevOps运维
- 负责数据备份策略
- 负责监控告警配置
- 负责恢复流程文档
- 负责运维自动化

---

*文档版本: v1.0*
*更新频率: 每日更新*
*下次更新: 2026-03-18*
