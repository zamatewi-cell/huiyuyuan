# 汇玉源版本回滚说明

> 本文档说明如何在发布失败或发现严重问题时快速回滚到上一个稳定版本。
> 最后更新：2026-04-05

---

## 1. 回滚策略概览

| 组件 | 回滚方式 | 预计耗时 |
|------|----------|----------|
| 后端 | systemd 快照回滚 | 2-3 分钟 |
| Web 前端 | 静态文件恢复 | 1-2 分钟 |
| APK | 重新上传旧版本 | 1 分钟 |
| 数据库 | PostgreSQL 快照恢复 | 5-10 分钟 |
| Nginx | 配置恢复 | 30 秒 |

---

## 2. 后端回滚

### 2.1 查看可用快照

```powershell
ssh root@47.112.98.191 "ls -dt /opt/huiyuyuan/snapshots/*"
```

输出示例：
```
/opt/huiyuyuan/snapshots/20260405_170000
/opt/huiyuyuan/snapshots/20260404_120000
/opt/huiyuyuan/snapshots/20260403_090000
```

### 2.2 执行回滚

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 `
  -Target backend -Rollback 20260405_170000
```

这会自动：
1. 停止当前后端服务
2. 清除当前后端代码
3. 恢复快照内容
4. 重启后端服务
5. 验证健康检查

### 2.3 手动回滚（脚本不可用时）

```powershell
ssh root@47.112.98.191 << 'EOF'
systemctl stop huiyuyuan-backend
rm -rf /srv/huiyuyuan/backend/*
cp -a /opt/huiyuyuan/snapshots/20260405_170000/. /srv/huiyuyuan/backend/
cd /srv/huiyuyuan/backend
source venv/bin/activate
pip install -r requirements.txt -q
systemctl start huiyuyuan-backend
sleep 3
curl -s http://127.0.0.1:8000/api/health
EOF
```

---

## 3. Web 前端回滚

### 3.1 前提

发布前必须先备份：

```powershell
ssh root@47.112.98.191 "
  stamp=\$(date +%Y%m%d_%H%M%S)
  mkdir -p /opt/huiyuyuan/web-snapshots/\$stamp
  cp -a /var/www/huiyuyuan/. /opt/huiyuyuan/web-snapshots/\$stamp/
  echo \"Backup created: \$stamp\"
"
```

### 3.2 执行回滚

```powershell
ssh root@47.112.98.191 "
  cp -a /opt/huiyuyuan/web-snapshots/20260405_170000/. /var/www/huiyuyuan/
  systemctl reload nginx
  echo 'Web rolled back successfully'
"
```

### 3.3 验证

```powershell
ssh root@47.112.98.191 "stat -c '%y %n' /var/www/huiyuyuan/index.html"
curl.exe -I https://xn--lsws2cdzg.top/
```

---

## 4. APK 回滚

### 4.1 查看历史 APK

如果有保留历史构建产物：

```powershell
ls -la D:\huiyuyuan_project\builds\migration\*.apk
```

### 4.2 重新上传

```powershell
scp D:\huiyuyuan_project\builds\migration\huiyuyuan-v3.0.3.apk `
  root@47.112.98.191:/var/www/huiyuyuan/downloads/huiyuyuan-latest.apk
```

### 4.3 同步版本号

回滚 APK 后，需要同步降低后端版本号：

```powershell
cd D:\huiyuyuan_project\huiyuyuan_app
python tool/version_manager.py set 3.0.3 5
```

然后部署后端：

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target backend
```

---

## 5. 数据库回滚

### 5.1 Alembic 迁移回滚

如果问题出在数据库迁移：

```powershell
ssh root@47.112.98.191 "
  cd /srv/huiyuyuan/backend
  source venv/bin/activate
  alembic downgrade -1
"
```

### 5.2 完整数据库恢复

如果有 PostgreSQL 备份：

```powershell
# 1. 查看可用备份
ssh root@47.112.98.191 "ls -lt /opt/huiyuyuan/backups/*.sql* | head -5"

# 2. 停止后端
ssh root@47.112.98.191 "systemctl stop huiyuyuan-backend"

# 3. 删除并重建数据库
ssh root@47.112.98.191 "
  sudo -u postgres dropdb huiyuyuan
  sudo -u postgres createdb -O huyy_user huiyuyuan
"

# 4. 恢复备份
ssh root@47.112.98.191 "
  gunzip -c /opt/huiyuyuan/backups/latest_dump.sql.gz | sudo -u postgres psql -d huiyuyuan
"

# 5. 重启后端
ssh root@47.112.98.191 "systemctl start huiyuyuan-backend"
```

---

## 6. Nginx 配置回滚

### 6.1 查看备份

```powershell
ssh root@47.112.98.191 "ls -lt /etc/nginx/conf.d/huiyuyuan.conf.bak.* | head -5"
```

### 6.2 恢复配置

```powershell
ssh root@47.112.98.191 "
  cp /etc/nginx/conf.d/huiyuyuan.conf.bak.20260405_170000 /etc/nginx/conf.d/huiyuyuan.conf
  sed -i '1s/^\xEF\xBB\xBF//' /etc/nginx/conf.d/huiyuyuan.conf
  nginx -t && systemctl reload nginx
"
```

### 6.3 从本地重新部署

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target nginx
```

> 注意：部署后需要在服务器上去除 BOM：
> ```powershell
> ssh root@47.112.98.191 "sed -i '1s/^\xEF\xBB\xBF//' /etc/nginx/conf.d/huiyuyuan.conf && nginx -t && systemctl reload nginx"
> ```

---

## 7. 完整回滚流程（最坏情况）

当新版本出现严重问题时，按以下顺序回滚：

```powershell
cd D:\huiyuyuan_project

# 1. 停止后端（防止写入）
ssh root@47.112.98.191 "systemctl stop huiyuyuan-backend"

# 2. 回滚数据库（如果需要）
ssh root@47.112.98.191 "
  cd /srv/huiyuyuan/backend && source venv/bin/activate && alembic downgrade -1
"

# 3. 回滚后端代码
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 `
  -Target backend -Rollback 20260405_170000

# 4. 回滚 Web 前端
ssh root@47.112.98.191 "
  cp -a /opt/huiyuyuan/web-snapshots/20260405_170000/. /var/www/huiyuyuan/
"

# 5. 回滚 Nginx（如果需要）
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target nginx

# 6. 回滚 APK（如果需要）
scp builds\migration\huiyuyuan-v3.0.3.apk `
  root@47.112.98.191:/var/www/huiyuyuan/downloads/huiyuyuan-latest.apk

# 7. 验证
ssh root@47.112.98.191 "
  echo '=== Backend ==='; systemctl is-active huiyuyuan-backend
  echo '=== Nginx ==='; nginx -t 2>&1
  echo '=== Health ==='; curl -s http://127.0.0.1:8000/api/health
"
```

---

## 8. 回滚后检查清单

- [ ] 后端健康检查通过
- [ ] Web 页面正常加载
- [ ] 登录功能正常
- [ ] 版本号回退到预期值
- [ ] APK 下载链接可用
- [ ] Nginx 配置正常
- [ ] 数据库数据一致
- [ ] 后端日志无异常
- [ ] 通知系统正常

---

## 9. 预防措施

为避免需要回滚，建议：

1. **发布前**：完整运行所有测试和检查
2. **发布时**：分步发布（后端 → Nginx → Web），不要一次性全量发布
3. **发布后**：立即执行 smoke test
4. **定期**：确认备份可用，定期测试恢复流程
5. **快照管理**：最多保留 3 个快照，避免磁盘占满
