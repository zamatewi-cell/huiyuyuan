# Agent D — DevOps 路线图

> 按优先级排列的运维改进计划

---

## P0 — 紧急 / 下一步

### ? SSL 证书部署
- **状态**: 脚本已就绪 (`backend/scripts/ssl_setup.sh`)，待执行
- **前置**: 需要域名解析到 `47.98.188.141`
- **操作**: `ssh root@47.98.188.141 "bash /srv/huiyuanyuan/scripts/ssl_setup.sh yourdomain.com"`
- **影响**: HTTP→HTTPS，Nginx 自动重定向，certbot 自动续期

### ? 服务器初始化验证
- **状态**: 脚本已就绪 (`backend/server_setup.sh`)，部分组件可能已手动安装
- **操作**: 在服务器上逐段验证 PostgreSQL 15 / Redis / Python venv / systemd / UFW / logrotate 状态
- **风险**: 服务器可能仍在用内存存储模式，需确认 `DB_AVAILABLE=True`

### ? 监控 Cron 激活
- **状态**: ? 安装脚本已创建 (`backend/scripts/install_cron.sh`)
- **操作**: `sudo bash /opt/huiyuanyuan/scripts/install_cron.sh`
- **支持**: `--remove` 卸载，自动创建 logrotate 配置

### ? 备份 Cron 激活
- **状态**: ? 纳入 `install_cron.sh` 统一管理 (每日 02:30)
- **操作**: 同上，一次安装同时激活监控 + 备份

---

## P1 — 重要 / 本迭代

### ? Docker 化 (可选)
- 当前使用 systemd + venv，稳定可靠
- Docker 化收益: 环境一致性、快速回滚、多实例部署
- 考虑: 单机 ECS 场景下 Docker 收益有限，暂不急

### ? 结构化日志
- **状态**: ? 已实现 (`backend/logging_config.py`)
- 生产: JSON 格式 (ts/level/logger/msg + extras)
- 开发: 彩色文本格式
- HTTP 请求中间件: method/path/status/duration_ms/client_ip
- 已集成到 `main.py`，已加入部署同步清单

### ? 数据库迁移工具
- **状态**: ? Alembic 框架已搭建
- `alembic.ini` + `migrations/env.py` + 基线迁移 0001
- 部署流程已集成: `deploy.sh` 自动执行 `alembic upgrade head`
- 同步清单已更新: deploy.ps1 + ci.yml
- 新增迁移: `alembic revision -m "add_xxx"` → 编辑 upgrade()/downgrade() → 提交

### ? 后端测试覆盖率提升
- **状态**: ? 78/78 tests, 0 warnings
- 新增 4 个测试文件: test_shops (5), test_notifications (6), test_admin (6), test_upload (4)
- 覆盖: 13 个 router 中 10 个有测试 (剩余 AI/WS 需外部依赖)
- 修复 security.py datetime.utcnow() 弃用警告

---

## P2 — 改进 / 后续版本

### ? CDN 静态资源加速
- **状态**: ? Nginx 缓存策略已优化
- `/assets/` + `/canvaskit/` → 365d 长缓存 (Flutter hash-versioned)
- 静态资源 → 30d 缓存, 关键文件 → no-cache
- CDN 接入 (阿里云/Cloudflare) 可后续按需启用

### ? APK/AAB 自动分发
- GitHub Actions 构建后自动上传到阿里云 OSS / 蒲公英
- 二维码扫码安装测试版本

### ? 告警通道完善
- 当前: 钉钉/企微 webhook (已预留接口)
- 完善: 接入实际 webhook URL + 配置告警级别 + 静默规则

### ? 性能基线与报警
- API 响应时间 P99 基线建立
- 超过阈值自动告警
- 可选: 接入 Prometheus + Grafana (但对单机可能过重)

### ? 安全加固
- **状态**: ? 脚本已创建 (`backend/scripts/security_harden.sh`)
- fail2ban + unattended-upgrades + SSH 加固 + sysctl 网络加固
- 支持 `--check-only` 审计模式
- 待执行: `sudo bash /opt/huiyuanyuan/scripts/security_harden.sh`

---

## P3 — 长期愿景

### ?? 多环境 (staging + production)
- staging 环境用于上线前验证
- 基于 Git 分支的自动部署: `dev` → staging, `main` → production

### ? 蓝绿部署 / 滚动更新
- 当前: 单实例 restart (有短暂中断)
- 目标: 双实例蓝绿切换或 Gunicorn graceful reload

### ? 基础设施即代码 (IaC)
- Terraform / Pulumi 管理阿里云资源
- Ansible 管理服务器配置
- 完全可复现的基础设施

---

## 已完成 ?

- [x] 服务器初始化脚本 (`server_setup.sh`)
- [x] PostgreSQL 15 安装配置
- [x] Redis 安装配置 (密码 + 内存限制)
- [x] systemd 服务定义
- [x] UFW 防火墙规则
- [x] logrotate 日志轮转
- [x] Nginx 生产配置 (安全头 + WebSocket + 速率限制)
- [x] SSL 脚本 (待执行)
- [x] 数据库备份脚本
- [x] 数据库恢复脚本
- [x] 健康监控脚本
- [x] 服务器诊断脚本
- [x] deploy.ps1 v4 (整目录 + 快照 + 回滚)
- [x] deploy.sh v4 (快照 + 健康检查 + 自动回滚)
- [x] CI/CD 后端测试 (pytest + PG/Redis 容器)
- [x] CI/CD 安全扫描
- [x] .env.example 完善
- [x] VSCode 任务集
- [x] 部署同步清单适配模块化后端
- [x] 结构化 JSON 日志 (`logging_config.py` + `RequestLoggingMiddleware`)
- [x] Cron 一键安装器 (`install_cron.sh`: 监控 + 备份 + logrotate)
- [x] 部署同步添加 `logging_config.py`
- [x] 后端测试覆盖率: 57→78 tests, 10/13 router 覆盖
- [x] security.py datetime 弃用警告修复 (224→0 warnings)
- [x] 安全加固脚本 (`security_harden.sh`: fail2ban + auto-upgrades + SSH + sysctl)
- [x] Alembic 数据库迁移框架 (基线 0001 + env.py + 部署集成)
- [x] Nginx 缓存优化 (assets/canvaskit 365d + 分类缓存策略)
- [x] deploy.sh 移植步骤 + 快照扩展 (logging_config + alembic + migrations)
