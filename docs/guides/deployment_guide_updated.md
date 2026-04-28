# 汇玉源 - 生产部署指南

> 更新日期：2026-04-08
> 当前生产服务器：`47.112.98.191`
> 当前生产域名：`https://汇玉源.top` / `https://xn--lsws2cdzg.top`

---

## 当前架构

```text
本地开发机 (Windows)
 ├─ scripts/deploy.ps1
 ├─ scripts/verify_public_ingress.ps1
 └─ huiyuyuan_app/

        ↓ SSH + SCP
        ↓
阿里云 ECS (47.112.98.191)
 ├─ /srv/huiyuyuan/backend/        ← FastAPI 后端源码
 ├─ /srv/huiyuyuan/backend/.env    ← 生产环境变量
 ├─ /var/www/huiyuyuan/            ← Flutter Web 静态文件
 ├─ /etc/nginx/conf.d/huiyuyuan.conf
 └─ systemd: huiyuyuan-backend
```

当前公网入口已经切换为域名 + HTTPS。日常发版以 `scripts/deploy.ps1` 为准。

## 2026-04-08 发布前回归基线

- 后端：`cd D:/huiyuyuan_project/huiyuyuan_app/backend && python -m pytest -q`，当前基线为 `167 passed`
- 前端：`cd D:/huiyuyuan_project/huiyuyuan_app && flutter test`，当前基线为 `490 passed`
- 静态检查：`cd D:/huiyuyuan_project/huiyuyuan_app && dart analyze lib test tool --no-fatal-warnings`
- 重点验收：
  - 登出、退出其他设备、重置密码、修改密码后，旧 token 不可继续访问
  - 支付取消 / 争议单不可被后台误确认到账
  - 订单负数数量与异常库存扣减已被后端拦截

---

## 日常部署

### 前置条件

1. SSH 密钥已配置，可免密登录 `root@47.112.98.191`
2. Flutter SDK 可用
3. 服务器上已存在 Python 虚拟环境和 `huiyuyuan-backend` 服务
4. 域名、SSL、Nginx 基础配置已完成

### 常用命令

```powershell
# 全量部署：后端 + Alembic + Nginx + 前端
.\scripts\deploy.ps1

# 只部署后端代码并执行 Alembic
.\scripts\deploy.ps1 -Target backend

# 只部署前端静态文件
.\scripts\deploy.ps1 -Target web

# 只下发 Nginx 配置
.\scripts\deploy.ps1 -Target nginx

# 初始化数据库 bootstrap SQL，然后补跑 Alembic
.\scripts\deploy.ps1 -Target db-init

# 本地预演
.\scripts\deploy.ps1 -DryRun
```

### 当前脚本行为

`scripts/deploy.ps1` 现在会执行这些动作：

1. 校验 SSH 连通性
2. 可选执行 `dart analyze`
3. 可选执行 `flutter build web --release`
4. 同步后端源码到 `/srv/huiyuyuan/backend`
5. 在服务器执行 `pip install -r requirements.txt`
6. 在服务器执行 `alembic upgrade head`
7. 重启 `huiyuyuan-backend`
8. 上传 `nginx_current.conf` 到 `/etc/nginx/conf.d/huiyuyuan.conf`
9. `nginx -t` 成功后 reload Nginx
10. 上传前端构建产物到 `/var/www/huiyuyuan/`
11. 校验本机后端健康检查 `http://127.0.0.1:8000/api/health`

---

## 首次 SSL 后发版

域名和证书配置完成后，首发建议顺序：

```powershell
cd d:\huiyuyuan_project
.\scripts\deploy.ps1 -Target backend
.\scripts\deploy.ps1 -Target nginx
.\scripts\deploy.ps1 -Target web
.\scripts\verify_public_ingress.ps1
```

如果希望一次完成，也可以直接：

```powershell
.\scripts\deploy.ps1
```

---

## 数据库迁移

### 日常 schema 迁移

日常数据库结构变更不再依赖手工执行 SQL。
以 Alembic 为准，包含在 `scripts/deploy.ps1 -Target backend` 和全量部署流程里。

### 新环境初始化

如果是全新数据库，先执行：

```powershell
.\scripts\deploy.ps1 -Target db-init
```

这个目标会：

1. 上传 `init_db.sql`
2. 执行 `psql -f init_db.sql`
3. 再执行 `alembic upgrade head`

### 历史数据说明

`xn--lsws2cdzg.top` 的历史客户数据已经在 `2026-03-18` 导入到当前生产环境。
当前继续发版时，不需要再重复做一次旧服客户导入。

---

## 服务器关键路径

| 路径 | 说明 |
|------|------|
| `/srv/huiyuyuan/backend/` | 后端源码目录 |
| `/srv/huiyuyuan/backend/venv/` | Python 虚拟环境 |
| `/srv/huiyuyuan/backend/.env` | 生产环境变量 |
| `/srv/huiyuyuan/backend/uploads/` | 后端上传文件目录 |
| `/var/www/huiyuyuan/` | Flutter Web 静态目录 |
| `/etc/nginx/conf.d/huiyuyuan.conf` | 当前线上 Nginx 配置 |
| `/etc/nginx/snippets/proxy_params.conf` | 反向代理参数片段 |
| `/etc/systemd/system/huiyuyuan-backend.service` | systemd 服务文件 |
| `/opt/huiyuyuan/snapshots/` | 后端快照回滚目录 |

---

## 验证命令

```bash
# 后端本机健康检查
curl http://127.0.0.1:8000/api/health

# 公网 HTTPS 健康检查
curl -I https://xn--lsws2cdzg.top/api/health

# Nginx 配置测试
nginx -t

# 后端服务状态
systemctl status huiyuyuan-backend

# 后端日志
journalctl -u huiyuyuan-backend -n 50 --no-pager

# Nginx 日志
tail -n 50 /var/log/nginx/huiyuyuan_access.log
tail -n 50 /var/log/nginx/huiyuyuan_error.log
```

Windows 本地可以直接用：

```powershell
.\scripts\verify_public_ingress.ps1
```

---

## 生产检查清单

- [ ] `https://汇玉源.top` 可以正常打开
- [ ] `https://www.汇玉源.top` 可以正常打开
- [ ] `http://汇玉源.top` 自动跳转到 HTTPS
- [ ] `GET /api/health` 返回正常
- [ ] `huiyuyuan-backend` 处于 `active` 状态
- [ ] `nginx -t` 返回 successful
- [ ] Alembic 已升级到最新 revision
- [ ] `.env` 的 `ALLOWED_ORIGINS` 已包含主域名和 `www`

---

## 故障排查

| 现象 | 排查方式 |
|------|----------|
| SSH 连接失败 | 检查安全组 22 端口、密钥、`root@47.112.98.191` 连通性 |
| 后端启动失败 | `journalctl -u huiyuyuan-backend -n 100 --no-pager` |
| Alembic 失败 | `cd /srv/huiyuyuan/backend && source venv/bin/activate && alembic current` |
| 502 Bad Gateway | 检查 `huiyuyuan-backend` 是否运行、Nginx upstream 是否指向 `127.0.0.1:8000` |
| HTTPS 可访问但接口报跨域 | 检查 `/srv/huiyuyuan/backend/.env` 中 `ALLOWED_ORIGINS` |
| HTTPS 证书续期异常 | 检查 `/var/www/certbot/.well-known/acme-challenge/` 和 cron 配置 |

---

## 说明

目前仓库中仍有一部分历史文档和自动化流程保留了旧的 IP-only 部署假设。
在这些内容完全清理前，`scripts/deploy.ps1` 和本文件是当前生产发版的权威入口。
