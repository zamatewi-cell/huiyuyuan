# 汇玉源 - 部署指南

> 最后更新: 2026-03-25
> 当前生产服务器: `47.112.98.191`
> 当前公网域名: `https://汇玉源.top` / `https://xn--lsws2cdzg.top`

---

## 当前架构

```text
本地开发机 (Windows)
 ├─ scripts/deploy.ps1          ← 日常发布入口
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

---

## 日常部署

### 前置条件

1. SSH 密钥已配置，可免密登录 `root@47.112.98.191`
2. Flutter SDK 已安装并可用
3. 服务器上已存在 Python 虚拟环境和 `huiyuyuan-backend` 服务
4. 域名、SSL、Nginx 基础配置已经完成

### 常用命令

```powershell
# 全量部署：后端 + Alembic + Nginx + 前端
.\scripts\deploy.ps1

# 只部署后端代码并执行 Alembic
.\scripts\deploy.ps1 -Target backend

# 只下发 Nginx 配置
.\scripts\deploy.ps1 -Target nginx

# 只部署前端静态文件
.\scripts\deploy.ps1 -Target web

# 新环境初始化数据库后补跑 Alembic
.\scripts\deploy.ps1 -Target db-init

# 本地预演
.\scripts\deploy.ps1 -DryRun
```

### 当前发布顺序

1. 同步后端源码到 `/srv/huiyuyuan/backend`
2. 在服务器执行 `pip install -r requirements.txt`
3. 在服务器执行 `alembic upgrade head`
4. 重启 `huiyuyuan-backend`
5. 下发 `nginx_current.conf` 到 `/etc/nginx/conf.d/huiyuyuan.conf`
6. `nginx -t` 成功后 reload Nginx
7. 上传 Flutter Web 构建产物到 `/var/www/huiyuyuan/`
8. 验证 `http://127.0.0.1:8000/api/health` 和公网 HTTPS 入口

---

## CI/CD 约定

GitHub Actions 中与服务器相关的关键变量应保持如下理解：

| Secret | 推荐值 | 说明 |
|---|---|---|
| `SERVER_HOST` | `xn--lsws2cdzg.top` | 服务器公网域名 |
| `SERVER_USER` | `root` | SSH 用户 |
| `SERVER_SSH_KEY` | `(private key)` | SSH 私钥 |

说明：
- 对外访问域名使用 `xn--lsws2cdzg.top` / `汇玉源.top`
- 生产服务器固定为 `47.112.98.191`
- 生产后端目录固定为 `/srv/huiyuyuan/backend`
- 生产服务名固定为 `huiyuyuan-backend`

---

## 服务器关键路径

| 路径 | 说明 |
|---|---|
| `/srv/huiyuyuan/backend/` | 后端源码目录 |
| `/srv/huiyuyuan/backend/venv/` | Python 虚拟环境 |
| `/srv/huiyuyuan/backend/.env` | 生产环境变量 |
| `/srv/huiyuyuan/backend/uploads/` | 后端上传目录 |
| `/var/www/huiyuyuan/` | Flutter Web 静态目录 |
| `/etc/nginx/conf.d/huiyuyuan.conf` | 当前线上 Nginx 配置 |
| `/etc/systemd/system/huiyuyuan-backend.service` | systemd 服务文件 |
| `/opt/huiyuyuan/snapshots/` | 后端快照回滚目录 |

### 常用运维命令

```bash
# 查看后端服务状态
systemctl status huiyuyuan-backend

# 查看后端最近日志
journalctl -u huiyuyuan-backend -n 50 --no-pager

# 手动重启后端
systemctl restart huiyuyuan-backend

# 测试并重载 Nginx
nginx -t && systemctl reload nginx
```

---

## 故障排查

| 问题 | 解决方式 |
|---|---|
| SSH 连接超时 | 检查安全组 22 端口、密钥、`root@47.112.98.191` 连通性 |
| 后端启动失败 | `journalctl -u huiyuyuan-backend -n 100 --no-pager` |
| Alembic 失败 | `cd /srv/huiyuyuan/backend && source venv/bin/activate && alembic current` |
| Nginx 配置错误 | `nginx -t` 查看具体报错 |
| 前端页面空白 | 检查 `/var/www/huiyuyuan/index.html` 是否存在 |
| 502 Bad Gateway | 确认 `huiyuyuan-backend` 正在运行，且 upstream 指向 `127.0.0.1:8000` |
| HTTPS 可访问但接口跨域失败 | 检查 `/srv/huiyuyuan/backend/.env` 中的 `ALLOWED_ORIGINS` |

---

## 验证清单

- [ ] `https://汇玉源.top` 可以正常打开
- [ ] `https://www.汇玉源.top` 可以正常打开
- [ ] `http://汇玉源.top` 自动跳转到 HTTPS
- [ ] `curl -I https://xn--lsws2cdzg.top/api/health` 返回正常
- [ ] `huiyuyuan-backend` 处于 `active` 状态
- [ ] `nginx -t` 返回 successful
- [ ] `.env` 中 `ALLOWED_ORIGINS` 已包含主域名和 `www`
