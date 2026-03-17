# 汇玉源 - 部署指南 (v4.0)

> 更新日期: 2026-03-17
> 服务器迁移: 47.98.188.141 → 47.112.98.191

---

## 架构总览

```
本地开发机 (Windows)
 ├─ scripts/deploy.ps1          ← 一键部署脚本
 ├─ .vscode/tasks.json          ← VSCode 任务集成
 └─ .github/workflows/ci.yml   ← Git push 自动部署

        ↓ SSH + SCP
        ↓
云服务器 ECS (47.112.98.191)
 ├─ /srv/huiyuanyuan/           ← 后端应用 (FastAPI + Gunicorn)
 │   ├─ main.py
 │   ├─ requirements.txt
 │   ├─ venv/
 │   ├─ .env
 │   └─ uploads/
 ├─ /var/www/huiyuanyuan/       ← 前端应用 (Flutter Web)
 │   ├─ index.html
 │   ├─ main.dart.js
 │   └─ assets/...
 └─ Nginx (80) → Gunicorn (8000)
```

---

## 服务器迁移记录

### 迁移历史
| 日期 | 旧服务器 | 新服务器 | 迁移内容 | 状态 |
|------|---------|---------|---------|------|
| 2026-03-17 | 47.98.188.141 | 47.112.98.191 | 完整系统迁移 | 进行中 |

### 迁移后配置变更
1. **服务器IP**: 更新为新服务器IP地址
2. **数据库连接**: 新的PostgreSQL连接信息
3. **Redis连接**: 新的Redis连接信息
4. **JWT密钥**: 新生成的JWT密钥
5. **CORS配置**: 更新为新服务器IP

---

## 方式一：一键部署（推荐日常使用）

### 前置条件

1. SSH 密钥已配置，可免密登录 `root@47.112.98.191`
2. Flutter SDK 已安装，PATH 中可用
3. PowerShell 5.1+（Windows 自带）

### 脚本使用

在项目根目录 `d:\huiyuanyuan_project\` 执行：

```powershell
# 全量部署（后端 + 数据库 + 重启 + 前端）
.\scripts\deploy.ps1

# 快速部署（跳过 dart analyze）
.\scripts\deploy.ps1 -SkipAnalyze

# 只部署前端（适合 UI 的小改动）
.\scripts\deploy.ps1 -Target web

# 只部署后端（适合 API 的小改动）
.\scripts\deploy.ps1 -Target backend

# 跳过构建（直接上传上次的构建产物）
.\scripts\deploy.ps1 -SkipBuild

# 模拟运行（不实际执行，只打印需要的步骤）
.\scripts\deploy.ps1 -DryRun
```

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `-Target` | `all\|web\|backend` | `all` | 部署范围 |
| `-SkipAnalyze` | switch | `false` | 跳过 `dart analyze` |
| `-SkipBuild` | switch | `false` | 跳过 `flutter build web` |
| `-DryRun` | switch | `false` | 模拟运行 |

### 执行流程

```
1. SSH 连通性检查  →  失败则终止
2. dart analyze     →  有 error 则终止（-SkipAnalyze 可跳过）
3. flutter build web →  构建失败则终止（-SkipBuild 可跳过）
4. SCP 上传后端    →  main.py + requirements.txt 到 /srv/huiyuanyuan/
5. pip install + 重启 Gunicorn
6. 后端健康检查    →  重试 5 次，每次间隔 3 秒
7. SCP 上传前端    →  build/web/* 到 /var/www/huiyuanyuan/
8. nginx -t + reload
9. 前端可访问性检查
```

---

## 方式二：VSCode 任务（快捷键触发）

按 `Ctrl+Shift+B` 直接触发默认构建（全量部署），或通过 `Ctrl+Shift+P` → `Tasks: Run Task` 选择：

| 任务 | 说明 |
|------|------|
| 🚀 全量部署（后端+前端+上传） | 默认构建任务 |
| ⚡ 快速部署（仅后端） | 日常最常用 |
| 🎨 只部署前端 | UI 小改动快速上线 |
| 🔧 只部署后端 | API 小改动快速上线 |
| 🔍 健康检查（验证） | 验证服务器是否正常 |
| 📊 静态分析 | 运行 dart analyze |
| 🧪 运行测试 | 运行 flutter test |
| 📈 服务器状态监控 | 查看服务器状态/内存/负载 |

---

## 方式三：Git Push 自动部署（CI/CD）

推送到 `main` 分支时，GitHub Actions 自动执行：

1. **Job 1**: Flutter 静态分析 → 单元测试 → 构建 Release AAB
2. **Job 2**: 后端部署（SCP → pip install → 重启 Gunicorn → 健康检查）
3. **Job 3**: Web 前端部署（flutter build web → SCP → nginx reload）

### 配置要求

在 GitHub 仓库 Settings → Secrets and variables → Actions 中设置：

| Secret | 值 | 说明 |
|--------|------|------|
| `SERVER_HOST` | `47.112.98.191` | 服务器 IP |
| `SERVER_USER` | `root` | SSH 用户名 |
| `SERVER_SSH_KEY` | `(私钥内容)` | SSH 私钥 |
| `OPENROUTER_API_KEY` | `sk-or-v1-...` | OpenRouter API 密钥 |
| `OPENROUTER_MODEL` | `nvidia/nemotron-nano-12b-v2-vl:free` | 统一使用的免费多模态模型 |

---

## 服务器目录说明

| 路径 | 说明 |
|------|------|
| `/srv/huiyuanyuan/` | 后端应用根目录 |
| `/srv/huiyuanyuan/main.py` | FastAPI 应用入口 |
| `/srv/huiyuanyuan/.env` | 环境变量（数据库/JWT/API Key） |
| `/srv/huiyuanyuan/venv/` | Python 虚拟环境 |
| `/srv/huiyuanyuan/uploads/` | 用户上传文件 |
| `/var/www/huiyuanyuan/` | Flutter Web 前端文件 |
| `/var/log/huiyuanyuan/` | 应用日志 |
| `/etc/nginx/sites-enabled/huiyuanyuan` | Nginx 站点配置 |
| `/etc/systemd/system/huiyuanyuan.service` | Gunicorn 服务单元 |

### 常用运维命令

```bash
# 查看服务状态
systemctl status huiyuanyuan

# 查看应用日志
journalctl -u huiyuanyuan -n 50

# 手动重启
systemctl restart huiyuanyuan

# Nginx 测试 & 重载
nginx -t && systemctl reload nginx

# 数据库连接
psql -U huyy_user -d huiyuanyuan

# Redis连接
redis-cli -a <password>
```

---

## 服务器迁移脚本

### 使用迁移脚本

```powershell
# 完整迁移
.\scripts\migrate_server.ps1 -OldServerIP "47.98.188.141" -NewServerIP "47.112.98.191" -SSHKeyPath "~/.ssh/id_rsa"

# 模拟运行
.\scripts\migrate_server.ps1 -OldServerIP "47.98.188.141" -NewServerIP "47.112.98.191" -DryRun

# 跳过备份
.\scripts\migrate_server.ps1 -OldServerIP "47.98.188.141" -NewServerIP "47.112.98.191" -SkipBackup
```

### 迁移步骤

1. **测试连接**: 验证新旧服务器SSH连接
2. **数据备份**: 备份数据库、应用文件、配置文件
3. **环境准备**: 在新服务器上安装系统依赖
4. **文件传输**: 传输后端和前端文件
5. **配置生成**: 生成新的环境变量和配置文件
6. **数据库迁移**: 恢复数据库并运行迁移
7. **服务配置**: 配置systemd和Nginx
8. **服务启动**: 启动所有服务
9. **功能验证**: 验证后端和前端功能
10. **安全加固**: 执行安全加固脚本
11. **防火墙配置**: 配置UFW防火墙

---

## 故障排查

| 现象 | 排查命令 |
|------|----------|
| SSH 连接超时 | 检查 ECS 安全组是否放通 22 端口 |
| 后端启动失败 | `journalctl -u huiyuanyuan -n 50` 查看应用日志 |
| Nginx 配置错误 | `nginx -t` 查看配置详情 |
| 构建失败 | `dart analyze lib/` 检查代码 |
| 前端页面空白 | 检查 `/var/www/huiyuanyuan/index.html` 是否存在 |
| 502 Bad Gateway | Gunicorn 未运行，`systemctl restart huiyuanyuan` |
| 数据库连接失败 | 检查PostgreSQL服务状态和连接配置 |
| Redis连接失败 | 检查Redis服务状态和密码配置 |

---

## 安全配置

### 服务器安全加固

```bash
# 运行安全加固脚本
bash /opt/huiyuanyuan/security_harden.sh

# 检查安全状态
bash /opt/huiyuanyuan/security_harden.sh --check-only
```

### 安全措施包括
1. **fail2ban**: 防止暴力破解
2. **unattended-upgrades**: 自动安全更新
3. **SSH加固**: 禁用root密码登录、设置超时
4. **内核加固**: SYN cookies、ICMP保护
5. **防火墙**: UFW配置，仅开放必要端口

---

## 监控和备份

### 自动备份
- **数据库备份**: 每天凌晨3:00自动备份
- **备份保留**: 保留最近7天的备份
- **备份位置**: `/opt/huiyuanyuan/backups/`

### 健康监控
- **监控频率**: 每5分钟检查一次
- **监控内容**: 服务状态、API响应、资源使用
- **告警方式**: 日志记录（可扩展为邮件/钉钉告警）

### 日志管理
- **应用日志**: `/var/log/huiyuanyuan/`
- **Nginx日志**: `/var/log/nginx/`
- **系统日志**: `journalctl`
- **日志轮转**: 自动保留14天

---

## 性能优化

### 数据库优化
```sql
-- PostgreSQL性能配置
shared_buffers = 512MB
effective_cache_size = 1GB
work_mem = 8MB
maintenance_work_mem = 128MB
max_connections = 100
```

### Redis优化
```conf
# Redis配置
maxmemory 256mb
maxmemory-policy allkeys-lru
```

### Nginx优化
```nginx
# 启用Gzip压缩
gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript;

# 静态资源缓存
location /assets/ {
    expires 365d;
    add_header Cache-Control "public, immutable";
}
```

---

## 回滚方案

### 快速回滚
1. **DNS回滚**: 将DNS记录改回旧服务器IP
2. **服务恢复**: 在旧服务器上启动服务
3. **数据同步**: 同步新产生的数据

### 回滚时间目标
- **RTO**: 15分钟内恢复服务
- **RPO**: 1小时内数据不丢失

---

## 后续优化计划

### 短期优化 (1-2周)
1. **UI视觉升级**: 实现Liquid Glass设计系统
2. **测试覆盖**: 提升测试覆盖率至80%
3. **性能监控**: 建立完整的监控体系

### 中期优化 (1-2月)
1. **SSL证书**: 配置HTTPS
2. **CDN加速**: 配置静态资源CDN
3. **负载均衡**: 配置多实例负载均衡

### 长期优化 (3-6月)
1. **容器化**: Docker部署
2. **微服务**: 服务拆分
3. **自动化**: 完整的CI/CD流水线

---

*文档版本: 2.0.0 | 最后更新: 2026-03-17*