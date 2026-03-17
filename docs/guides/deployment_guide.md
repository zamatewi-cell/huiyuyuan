# 汇玉源 — 部署指南

> 最后更新: 2026-02-25

---

## 架构概览

```
本地开发机 (Windows)
 ├── scripts/deploy.ps1          ← 一键部署入口
 ├── .vscode/tasks.json          ← VSCode 任务集成
 └── .github/workflows/ci.yml   ← Git push 自动部署

        │ SSH + SCP
        ▼
阿里云 ECS (47.98.188.141)
 ├── /srv/huiyuanyuan/           ← 后端 (FastAPI + Gunicorn)
 │   ├── main.py
 │   ├── requirements.txt
 │   ├── venv/
 │   ├── .env
 │   └── uploads/
 ├── /var/www/huiyuanyuan/       ← 前端 (Flutter Web)
 │   ├── index.html
 │   ├── main.dart.js
 │   └── assets/...
 └── Nginx (80) → Gunicorn (8000)
```

---

## 方式一：本地一键部署（推荐日常使用）

### 前置条件

1. SSH 密钥已配置，可免密登录 `root@47.98.188.141`
2. Flutter SDK 已安装并在 PATH 中
3. PowerShell 5.1+（Windows 自带）

### 命令行使用

在项目根目录 `d:\huiyuanyuan_project\` 下运行：

```powershell
# 全量部署（分析 + 构建 + 后端 + 前端）
.\scripts\deploy.ps1

# 快速部署（跳过 dart analyze）
.\scripts\deploy.ps1 -SkipAnalyze

# 仅部署前端（适用于 UI 改动）
.\scripts\deploy.ps1 -Target web

# 仅部署后端（适用于 API 改动）
.\scripts\deploy.ps1 -Target backend

# 跳过构建，直接上传上次的构建产物
.\scripts\deploy.ps1 -SkipBuild

# 模拟运行（不实际执行，仅打印将要做的操作）
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
2. dart analyze     →  有 error 则终止（可 -SkipAnalyze 跳过）
3. flutter build web →  构建失败则终止（可 -SkipBuild 跳过）
4. SCP 上传后端    →  main.py + requirements.txt → /srv/huiyuanyuan/
5. pip install + 重启 Gunicorn
6. 健康检查        →  最多重试 5 次，每次间隔 3 秒
7. SCP 上传前端    →  build/web/* → /var/www/huiyuanyuan/
8. nginx -t + reload
9. 前端可访问性检查
```

---

## 方式二：VSCode 任务（快捷键触发）

按 `Ctrl+Shift+B` 直接触发默认构建任务（全量部署），或通过 `Ctrl+Shift+P` → `Tasks: Run Task` 选择：

| 任务 | 说明 |
|------|------|
| ? 全量部署 (分析+构建+上传) | 默认构建任务，完整流程 |
| ? 快速部署 (跳过分析) | 日常迭代最常用 |
| ? 仅部署前端 | UI 改动后快速更新 |
| ? 仅部署后端 | API 改动后快速更新 |
| ? 仅构建 (不部署) | 本地验证构建是否通过 |
| ? 静态分析 | 运行 dart analyze |
| ? 运行测试 | 运行 flutter test |
| ? 服务器健康检查 | 查看服务器状态/内存/磁盘 |

---

## 方式三：Git Push 自动部署（CI/CD）

推送到 `main` 分支时，GitHub Actions 自动执行：

1. **Job 1**: Flutter 静态分析 → 单元测试 → 构建 Release AAB
2. **Job 2**: 后端部署（SCP → pip install → 重启 Gunicorn → 健康检查）
3. **Job 3**: Web 前端部署（flutter build web → SCP → nginx reload）

### 配置要求

在 GitHub 仓库 Settings → Secrets and variables → Actions 中配置：

| Secret | 值 | 说明 |
|--------|------|------|
| `SERVER_HOST` | `47.98.188.141` | 服务器 IP |
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

# 查看最近日志
journalctl -u huiyuanyuan -n 50

# 手动重启
systemctl restart huiyuanyuan

# Nginx 测试 & 重载
nginx -t && systemctl reload nginx
```

---

## 故障排查

| 问题 | 解决方案 |
|------|----------|
| SSH 连接超时 | 检查 ECS 安全组是否放通 22 端口 |
| 健康检查失败 | `journalctl -u huiyuanyuan -n 50` 查看错误日志 |
| Nginx 配置错误 | `nginx -t` 查看具体错误 |
| 构建失败 | `dart analyze lib/` 检查代码错误 |
| 前端页面空白 | 检查 `/var/www/huiyuanyuan/index.html` 是否存在 |
| 502 Bad Gateway | Gunicorn 未运行，`systemctl restart huiyuanyuan` |
