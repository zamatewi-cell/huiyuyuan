# 汇玉源 — 下一步行动计划（2026-02-22 制定）

> **阅读说明**：? = 需要你手动操作 | ? = 我（AI/Copilot）直接帮你写代码

---

## ? 当前状态快照

| 项目 | 状态 |
|------|------|
| Flutter 前端 | ? 99% 完成，0 error，23+ 页面，全面迭代完成 |
| AI 服务（DeepSeek + Gemini + 千问VL） | ? 三级降级 + 图片识别已完成 |
| 后端 `main.py` | ? 已部署至 47.98.188.141，health check 正常 |
| 登录系统 | ?? Mock 模式（验证码固定 8888），待接入阿里云 SMS |
| 支付 | ? 资质申请中，尚未对接 |
| 数据库 | ? PostgreSQL 14，9 张表已建 |
| 云服务器 | ? ECS 47.98.188.141 运行中，最近部署 2026-02-25 |
| Web 前端 | ? 已部署至 /var/www/huiyuyuan，Nginx 反代 |

---

## ? 第一阶段：阶段六（2026-02-23 → 2026-03-08）

### 任务优先级总览

| 优先级 | 任务 | 谁来做 | 预估耗时 |
|--------|------|--------|--------|
| P0 | 购买并配置阿里云服务器 | ? 你 | 2小时 |
| P0 | 注册阿里云短信服务 | ? 你 | 1天（审核） |
| P0 | 后端新增 SMS 路由代码 | ? 我 | 立刻可做 |
| P0 | PostgreSQL 数据库建表 | ? 我 | 立刻可做 |
| P0 | 前端 `api_config.dart` 更新 | ? 我 | 立刻可做 |
| P0 | 生成 Android 签名密钥 | ? 你 | 30分钟 |
| P1 | HTTPS 证书配置（Nginx） | ? 你 | 30分钟 |
| P1 | 隐私政策/用户协议页面 | ? 我（页面代码）+ ? 你（内容） | 1天 |

---

## ? 你现在需要做的事（按顺序）

### 第1步：购买阿里云服务器（约30分钟）

**访问地址：** https://ecs.console.aliyun.com/

**推荐配置：**
- 规格：2核 4GB（`ecs.c7.large` 或同等）
- 系统：Ubuntu 22.04 LTS
- 存储：40GB SSD 系统盘
- 带宽：5 Mbps 固定
- 区域：华东（上海）
- **预计月费：** ?120–200

**购买后你需要告诉我：**
1. 服务器公网 IP 地址
2. SSH 登录用户名（默认 `root` 或 `ubuntu`）

---

### 第2步：注册阿里云短信服务（约1天，审核时间）

**访问地址：** https://dysms.console.aliyun.com/

**操作步骤：**
1. 完成企业实名认证（需营业执照）
2. 申请「短信签名」：签名名称填写「汇玉源」，类型选择「APP」
3. 申请「短信模板」：内容参考 `您的验证码为${code}，5分钟内有效，请勿泄露。`
4. 进入「AccessKey 管理」创建一个专用 AccessKey（子账号权限只勾选 SMS）

**你需要记下这些信息（之后告诉我）：**
```
AccessKey ID:     LTAI5t_______________
AccessKey Secret: ______________________
短信签名名称:     汇玉源
短信模板 Code:   SMS_____________
```

---

### 第3步：生成 Android 签名密钥（约30分钟）

在你的电脑上运行（需要 JDK，Flutter 自带 Java）：

```bash
# 在 huiyuyuan_app/android/ 目录下运行
keytool -genkey -v -keystore huiyuyuan.jks \
  -alias huiyuyuan -keyalg RSA -keysize 2048 -validity 36500
```

**填写时的建议：**
- 姓名：huiyuyuan
- 组织单位：mobile
- 组织：huiyuyuan
- 城市：你的城市
- 省：你的省份
- 国家：CN

> ?? **重要**：生成的 `huiyuyuan.jks` 文件务必备份到安全位置！将密码记录在安全地方。
> ?? 不要将 `.jks` 文件提交到 Git！

---

### 第4步：服务器环境初始化（你拿到 IP 后）

SSH 登录服务器后，依次执行：

```bash
# 1. 系统更新
sudo apt update && sudo apt upgrade -y

# 2. 安装依赖
sudo apt install -y python3.11 python3.11-venv python3-pip nginx redis-server postgresql-16 git

# 3. 启动 Redis 和 PostgreSQL
sudo systemctl enable redis-server postgresql
sudo systemctl start redis-server postgresql

# 4. 创建数据库和用户
sudo -u postgres psql -c "CREATE DATABASE huiyuyuan;"
sudo -u postgres psql -c "CREATE USER huyy_user WITH PASSWORD 'Huyy@2026_Study';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE huiyuyuan TO huyy_user;"

# 5. 上传代码（在你本地运行）
# 方式A：SCP 上传
scp -r huiyuyuan_app/backend/ user@服务器IP:/srv/huiyuyuan/

# 方式B：Git（推荐，把后端代码 push 到 GitHub 私有仓库后 clone）
git clone https://github.com/你的账号/huiyuyuan-backend.git /srv/huiyuyuan
```

---

## ? 我现在可以立刻帮你做的事

以下代码任务，你告诉我"开始"，我就立刻写/修改：

### 可立刻执行的代码任务

---

#### ~~任务A：后端 SMS 路由（后端代码）~~ ? 已完成 (2026-02-22)

**完成内容：**
- ? `POST /api/auth/send-sms` — Redis 60s冷却 + 日10次上限 + 5次错误锁定
- ? `POST /api/auth/verify-sms` — 一次性码 + JWT 颁发 + PostgreSQL 自动注册 + 内存降级
- ? 阿里云 SMS SDK 已接入，AccessKey 为空时自动切换测试模式
- ? 6个测试用例全部通过（send/cooldown/wrong/verify/reuse/DB写入）

**你现在只需要（等短信服务审核通过后）：**
```bash
# SSH 进入服务器后填入:
sed -i 's/ALIYUN_ACCESS_KEY_ID=/ALIYUN_ACCESS_KEY_ID=LTAI5t.../' /srv/huiyuyuan/.env
sed -i 's/ALIYUN_ACCESS_KEY_SECRET=/ALIYUN_ACCESS_KEY_SECRET=.../' /srv/huiyuyuan/.env
sed -i 's/SMS_TEMPLATE_CODE=/SMS_TEMPLATE_CODE=SMS_.../' /srv/huiyuyuan/.env
systemctl restart huiyuyuan
```

---

#### ~~任务B：数据库建表 SQL + 后端集成~~ ? 已完成 (2026-02-22)

**完成内容：**
- ? `backend/init_db.sql` — 9张表，含完整约束、外键、索引
- ? 服务器已执行 `init_db_utf8.sql`，9张表全部创建（return code=0）
- ? `main.py` 集成 SQLAlchemy ORM，PostgreSQL 不可用时自动降级到内存
- ? `verify-sms` 路由实现新用户自动注册并写入 PostgreSQL

---

#### ~~任务C：前端 useMockApi 切换准备~~ ? 已完成 (2026-02-22)

**完成内容：**
- ? `api_config.dart`：`authSendSms` / `authVerifySms` 常量、`useMockApi = false`、`baseUrl = http://47.98.188.141`
- ? `auth_provider.dart`：`sendSmsCode()` / `loginWithSms()` 对接真实接口
- ? `login_screen.dart`：60s倒计时 + 手机号正则 + 6位验证码输入框
- ? `flutter_secure_storage`：Token 存入 Android Keystore / iOS Keychain

---

#### 任务D：Nginx 配置文件 + 部署脚本生成

**我会生成：**
- `/etc/nginx/sites-available/huiyuyuan` 完整配置（含 SSL/限流）
- `deploy.sh` 一键部署脚本
- `gunicorn.service` systemd 服务文件（开机自启）
- GitHub Actions CI/CD 工作流 `.github/workflows/deploy.yml`

> **说"帮我做任务D"即可开始。**（此任务不依赖服务器，可以现在做）

---

#### 任务E：Android 签名配置

**我会修改：**
- `android/app/build.gradle.kts` — 配置 release 签名
- `android/key.properties` — 签名配置文件（已加入 .gitignore）
- 更新 `README.md` 中的构建命令

> 需要你先完成第3步（生成密钥），然后**说"帮我做任务E"并告诉我密钥别名和文件路径。**

---

#### 任务F：隐私政策 + 用户协议 Flutter 页面

**我会创建：**
- `lib/screens/legal/privacy_policy_screen.dart`
- `lib/screens/legal/user_agreement_screen.dart`
- 路由接入个人中心页面
- 首次启动隐私弹窗（同意前不收集数据）

> **说"帮我做任务F"即可开始。**

---

## ? 第二阶段快速预览（阶段七 2026-03-09 后）

等阶段六完成后，我会帮你做：

| 任务 | 我能做什么 |
|------|-----------|
| 购物车云端同步 | 修改 cartProvider + 后端 /api/cart/sync |
| 订单系统对接真实后端 | OrderService 移除 Mock，接入 PostgreSQL |
| 客服 WebSocket 系统 | 后端 WebSocket + 前端 customer_service_screen.dart |
| Firebase Crashlytics | main.dart 接入 + 配置 google-services.json |

---

## ? 建议立刻开始的顺序

```
? 已完成 (2026-02-22):
  ? 任务A — SMS 后端路由 + Redis 限流 + PostgreSQL 自动注册
  ? 任务B — 数据库9张表 + SQLAlchemy 集成 + 降级策略
  ? 任务C — 前端登录改造 + flutter_secure_storage
  ? 服务器 — ECS + Gunicorn + Nginx + PostgreSQL + Redis 全部运行
  ? useMockApi = false — 前端已对接真实后端

? 等阿里云短信审核通过后:
  ? 在服务器 .env 填入 AccessKey → systemctl restart huiyuyuan

现在可以继续 (不依赖外部审核):
  ? 任务D — CI/CD GitHub Actions
  ? 任务F — 隐私政策 + 用户协议 Flutter 页面
  ? 任务E — Android 签名密钥生成 + build.gradle 配置
  ? HTTPS 域名配置（域名备案 + Certbot）
```

---

## ? 下一步决定

1. **继续做哪个任务？** 推荐 **"帮我做任务F"**（隐私政策页面，上架必须）或 **"帮我做任务D"**（CI/CD）
2. **阿里云短信资质**：审核通过后告诉我，我帮你写 `.env` 填入命令并验证
3. **HTTPS 域名**：如已有域名，告诉我，我帮你配置 Certbot + Nginx SSL

---

*最后更新: 2026-02-22（任务A+B+C+服务器部署全部完成）| 由 GitHub Copilot 生成*
