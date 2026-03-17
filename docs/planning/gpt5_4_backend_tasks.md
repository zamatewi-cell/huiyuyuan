# GPT-5.4 后端技术债务修复任务清单

> 分配日期: 2026-03-17
> 负责人: GPT-5.4
> 优先级: 高

---

## 一、任务概述

GPT-5.4 负责汇玉源项目的后端技术债务修复和测试覆盖扩展工作。主要目标是提升后端代码质量、数据可靠性和系统安全性。

---

## 二、后端技术债务修复任务

### 2.1 main.py模块化拆分 (优先级: 高)

#### 当前状态
- **文件**: `backend/main.py`
- **行数**: 约100行（已部分模块化）
- **问题**: 需要进一步优化模块结构

#### 具体任务
1. **检查现有模块结构**:
   - 验证 `routers/` 目录下的路由模块完整性
   - 验证 `services/` 目录下的服务模块完整性
   - 验证 `schemas/` 目录下的Pydantic模型完整性

2. **提取缺失的模块**:
   - 创建 `models/` 目录，提取SQLAlchemy模型
   - 创建 `middleware/` 目录，提取中间件
   - 优化 `main.py`，确保行数 ≤ 100行

3. **验证标准**:
   - [ ] `main.py` 行数 ≤ 100行
   - [ ] 所有49个API端点正常工作
   - [ ] `curl /api/health` 返回200
   - [ ] 代码结构清晰，职责分离

### 2.2 内存存储迁移到PostgreSQL (优先级: 高)

#### 当前状态
- **内存存储**: `store.py` 包含所有数据字典
- **数据库**: PostgreSQL已配置但部分功能未使用
- **问题**: 数据可靠性不足，重启丢失

#### 具体任务
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

### 2.3 安全配置修复 (优先级: 高)

#### 当前问题
1. **CORS配置宽松**: `allow_origins=["*"]`
2. **JWT密钥硬编码**: 默认密钥未强制替换
3. **SMS验证绕过**: 固定验证码8888
4. **密码存储**: 部分使用明文存储

#### 具体任务
1. **CORS配置修复**:
   ```python
   # config.py
   _origins_raw = os.getenv("ALLOWED_ORIGINS", "")
   if _origins_raw and _origins_raw != "*":
       ALLOWED_ORIGINS = [o.strip() for o in _origins_raw.split(",") if o.strip()]
   else:
       if APP_ENV == "production":
           ALLOWED_ORIGINS = [
               "http://47.112.98.191",
               "https://47.112.98.191",
           ]
           logger.warning("ALLOWED_ORIGINS 未配置，默认仅允许服务器 IP")
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

## 三、测试覆盖扩展任务

### 3.1 后端pytest测试用例扩展 (优先级: 高)

#### 当前状态
- **测试目录**: `backend/tests/`
- **现有测试**: 基础测试用例
- **目标覆盖率**: 80%以上

#### 具体任务
1. **单元测试扩展**:
   - 为所有路由模块创建测试用例
   - 为所有服务模块创建测试用例
   - 为所有数据模型创建测试用例

2. **集成测试扩展**:
   - 测试API端点完整流程
   - 测试数据库操作完整性
   - 测试缓存机制有效性

3. **性能测试**:
   - 建立性能基准测试
   - 测试并发处理能力
   - 测试响应时间

4. **安全测试**:
   - 测试输入验证
   - 测试SQL注入防护
   - 测试XSS攻击防护

#### 测试用例示例
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
                "Origin": "http://unauthorized.com",
                "Access-Control-Request-Method": "GET"
            }
        )
        assert response.status_code == 400  # 或其他适当的错误码

@pytest.mark.asyncio
async def test_jwt_secret_required():
    """测试JWT密钥必须配置"""
    import os
    original_secret = os.environ.get("JWT_SECRET_KEY")
    try:
        os.environ.pop("JWT_SECRET_KEY", None)
        # 重新导入config模块应该抛出异常
        with pytest.raises(RuntimeError):
            import importlib
            import config
            importlib.reload(config)
    finally:
        if original_secret:
            os.environ["JWT_SECRET_KEY"] = original_secret
```

#### 验证标准
- [ ] 测试覆盖率 ≥ 80%
- [ ] 所有测试用例通过
- [ ] 性能测试基准建立
- [ ] 安全测试通过

### 3.2 测试自动化集成 (优先级: 中)

#### 具体任务
1. **CI/CD集成**:
   - 配置GitHub Actions自动运行测试
   - 配置测试覆盖率报告
   - 配置测试失败通知

2. **测试数据管理**:
   - 创建测试数据工厂
   - 实现测试数据清理
   - 实现测试环境隔离

3. **测试报告生成**:
   - 生成HTML测试报告
   - 生成覆盖率报告
   - 生成性能测试报告

#### 验证标准
- [ ] CI/CD自动运行测试
- [ ] 测试报告自动生成
- [ ] 测试环境隔离有效

---

## 四、时间安排

### 4.1 第一周：安全配置修复 (2026-03-18 ~ 2026-03-22)
- Day 1: CORS配置修复
- Day 2: JWT密钥强制配置
- Day 3: SMS验证修复
- Day 4: 密码存储修复
- Day 5: 安全测试和验证

### 4.2 第二周：数据迁移 (2026-03-23 ~ 2026-03-29)
- Day 1-2: 用户数据迁移
- Day 3: 商品数据迁移
- Day 4: 订单数据迁移
- Day 5: 购物车、收藏、评价数据迁移

### 4.3 第三周：架构优化 (2026-03-30 ~ 2026-04-05)
- Day 1-2: main.py模块化拆分
- Day 3: 路由模块提取
- Day 4: 服务模块提取
- Day 5: 模型模块提取

### 4.4 第四周：测试覆盖 (2026-04-06 ~ 2026-04-12)
- Day 1-2: 单元测试扩展
- Day 3: 集成测试扩展
- Day 4: 性能测试
- Day 5: 安全测试

---

## 五、协作机制

### 5.1 每日同步
- **时间**: 每天上午10:00
- **内容**: 进度汇报、问题讨论、计划调整
- **方式**: 通过GitHub Issues或项目文档

### 5.2 代码审查
- **流程**: 创建Pull Request → 代码审查 → 合并
- **标准**: 代码规范、测试覆盖、文档完整
- **工具**: GitHub Pull Requests

### 5.3 文档更新
- **要求**: 每完成一个任务更新相关文档
- **内容**: 技术方案、实现细节、测试结果
- **位置**: `docs/planning/` 目录

---

## 六、成功标准

### 6.1 技术指标
1. **代码质量**: main.py ≤ 100行，模块职责清晰
2. **数据可靠性**: 所有数据存储在PostgreSQL，内存存储仅作降级
3. **安全性**: 通过安全扫描，无高危漏洞
4. **测试覆盖率**: ≥ 80%

### 6.2 业务指标
1. **功能完整性**: 所有API端点正常工作
2. **性能**: API响应时间 < 200ms
3. **稳定性**: 服务可用性 ≥ 99.9%

### 6.3 运维指标
1. **部署成功率**: 99%以上
2. **故障恢复时间**: < 15分钟
3. **监控覆盖率**: 100%关键指标

---

*文档版本: v1.0*
*更新频率: 每周更新*
*下次更新: 2026-03-24*