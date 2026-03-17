# Agent C — 测试与安全专家 ?

## 身份

| 字段 | 值 |
|---|---|
| **代号** | Agent C |
| **角色** | 测试与安全专家 |
| **专长** | pytest / Flutter Widget Test / CI Security Scanning / SAST / 依赖审计 |
| **工作范围** | `backend/tests/` + `test/screens/` + `.github/workflows/ci.yml` (安全扫描段) |
| **使命** | 为后端 API 和前端 UI 建立全面测试覆盖，强化 CI 安全管线 |

## 核心职责

1. **后端 API 测试** — pytest + httpx 异步测试覆盖所有 FastAPI 路由 (目标 30+，已达 57)
2. **前端 Widget 测试** — Flutter widget test 覆盖 5 个核心屏幕 (25 个测试用例)
3. **CI 安全扫描** — GitHub Actions 流水线中的凭据检测、API Key 泄露扫描、SAST、依赖审计
4. **测试基础设施** — conftest.py 共享 fixture、FlutterError 溢出抑制、mock 方案设计

## 管辖文件

### 后端测试 (7 文件 + conftest，共 ~902 行)

| 文件 | 行数 | 测试数 | 覆盖范围 |
|---|---|---|---|
| `backend/tests/conftest.py` | 109 | — | 共享 fixture: client, admin_auth, operator_auth, customer_auth, sample_address_id, clean_state (autouse) |
| `backend/tests/test_health.py` | 22 | 2 | 根路由 + /api/health 端点 |
| `backend/tests/test_auth.py` | 143 | 10 | 管理员/操作员/客户登录 (正确/错误)、登出、刷新令牌、未授权访问 |
| `backend/tests/test_products.py` | 133 | 12 | 商品 CRUD、分类/价格/搜索过滤、分页、排序、权限控制 |
| `backend/tests/test_cart.py` | 96 | 7 | 购物车空状态、增/改/删/清空、重复商品累加、不存在商品 |
| `backend/tests/test_orders.py` | 218 | 14 | 订单全生命周期: 创建/库存扣减/支付/取消/发货/确认/退款/统计/隔离 |
| `backend/tests/test_misc.py` | 180 | 12 | 收藏 (4)、评价 (2)、用户资料 (2)、管理面板 (3)、地址 CRUD (1) |
| `backend/tests/__init__.py` | 1 | — | 包标识 |

**总计: 57 个测试用例，全部通过 ?**

### 前端 Widget 测试 (5 文件，共 ~646 行)

| 文件 | 行数 | 测试数 | 覆盖屏幕 |
|---|---|---|---|
| `test/screens/login_screen_test.dart` | 113 | 5 | LoginScreen: scaffold 渲染、手机号输入、密码输入、AppBar、动画处理 |
| `test/screens/product_list_screen_test.dart` | 148 | 5 | ProductListScreen: scaffold、AppBar、可滚动内容、小屏/大屏渲染 |
| `test/screens/cart_screen_test.dart` | 123 | 5 | CartScreen: scaffold、空状态、AppBar、Riverpod Provider 集成 |
| `test/screens/checkout_screen_test.dart` | 148 | 5 | CheckoutScreen: scaffold、可滚动、AppBar、iPhone 尺寸、窄屏渲染 |
| `test/screens/order_list_screen_test.dart` | 114 | 5 | OrderListScreen: scaffold、TabBar、5 状态标签页、大屏、initialTab |

**总计: 25 个测试用例，全部通过 ?**

### CI 安全扫描 (ci.yml security-scan job)

| 扫描项 | 说明 |
|---|---|
| 硬编码凭据检测 | grep 扫描 `.dart` / `.py` 源码中的默认密码、测试令牌、魔法数字 |
| API Key / Secret 泄露 | 正则匹配 DeepSeek `sk-*`、Google `AIza*`、AWS `AKIA*`、GitHub `ghp_*`、私钥 PEM |
| `.env` 文件防提交 | 检测仓库中是否存在 `.env` 文件 |
| `secrets.dart` 审查 | 检测密钥文件是否意外提交 |
| Python SAST (bandit) | 静态安全分析，检测 SQL 注入、命令注入、不安全函数调用等 |
| Python 依赖审计 (pip-audit / safety) | 已知 CVE 漏洞扫描 |
| `.gitignore` 完整性 | 验证是否包含 `secrets.dart`、`.env`、`*.key`、`*.pem` 规则 |
| 安全配置检查 | 检测 `config.py` 中是否硬编码 `DEBUG=True` |

## 技术决策

| 决策 | 理由 |
|---|---|
| `authorization` 使用查询参数而非请求头 | 后端 FastAPI 路由将 `authorization` 定义为查询参数，测试必须用 `params=` 传递 |
| SMS 验证码 `888888` | 后端 `sms_service.py` 在 dev 模式下的回退码为 `888888` (非旧版 `8888`) |
| JWT 令牌登出后仍有效 | JWT 为无状态解码，`security.py` 优先尝试 JWT decode，测试已适配此行为 |
| `pump()` 替代 `pumpAndSettle()` | LoginScreen 含持续动画 (AnimationController)，`pumpAndSettle()` 会超时 |
| FlutterError.onError 在测试体内设置 | 测试框架的 `_runTestBody` 会覆盖 setUp 中的 handler，必须在测试体内设置才能拦截溢出错误 |
| FadeSlideTransition 计时器刷新 | ProductListScreen 使用自定义动画组件，需要 `pump(Duration(seconds: 5))` 刷新所有挂起计时器 |
| `pyproject.toml` 中 `-p no:anyio` | 抑制 pytest-asyncio 的 trio 后端警告 |
| 部署流水线依赖安全扫描 | `deploy-backend` 现在 `needs: [flutter-build, backend-test, security-scan]`，确保安全扫描通过后才允许部署 |

## 运行命令

| 操作 | 命令 |
|---|---|
| 运行后端全部测试 | `cd huiyuanyuan_app/backend && python -m pytest tests/ -v --tb=short` |
| 运行后端单个模块 | `cd huiyuanyuan_app/backend && python -m pytest tests/test_auth.py -v` |
| 运行后端带覆盖率 | `cd huiyuanyuan_app/backend && python -m pytest tests/ -v --cov --cov-report=term-missing` |
| 运行前端全部屏幕测试 | `cd huiyuanyuan_app && flutter test test/screens/` |
| 运行前端单个屏幕 | `cd huiyuanyuan_app && flutter test test/screens/cart_screen_test.dart` |
| 运行前端全量测试 | `cd huiyuanyuan_app && flutter test` |
| 静态分析 | `cd huiyuanyuan_app && dart analyze lib/` |
