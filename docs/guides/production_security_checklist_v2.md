# 汇玉源生产安全清单 v2（Phase E）

> 服务器：47.112.98.191 | 最后更新：2026-04-08

---

## 0. 应用层近期加固（2026-04-08）

- ✅ JWT 会话已绑定 `sid`，`logout`、`logout-others`、`refresh` 轮转、`reset-password`、`change-password` 都会撤销旧会话
- ✅ 管理员登录必须填写验证码，不能再通过省略验证码绕过校验
- ✅ 下单数量增加下界校验，库存扣减改为条件更新，降低负数数量与并发超卖风险
- ✅ 支付 DB 写路径显式 `commit()`，后台确认到账会拒绝已取消、超时或争议中的支付单
- ✅ 设备记录反序列化已移除 `eval`，改为安全解析

---

## 1. SSH 安全

### 1.1 当前状态

| 项目 | 值 | 状态 |
|------|-----|------|
| SSH 端口 | 22 | ⚠️ 建议改为非常规端口 |
| PermitRootLogin | yes | ⚠️ 允许root登录 |
| PasswordAuthentication | no | ✅ 仅密钥认证 |
| 唯一Shell用户 | root, postgres | ✅ |

### 1.2 已采取措施

- ✅ 禁用密码认证，仅允许公钥认证
- ✅ SSH密钥已配置（本地默认位置或ssh-agent）

### 1.3 建议改进

- [ ] 改为非标准端口（如2222）
- [ ] 创建专用运维用户，禁用root直接登录
- [ ] 配置SSH密钥轮换策略（每90天）

---

## 2. 防火墙与入侵防护

### 2.1 fail2ban

| Jail | 状态 | 说明 |
|------|------|------|
| sshd | ✅ 运行 | SSH暴力破解防护 |
| nginx-botsearch | ✅ 运行 | Nginx恶意扫描防护 |
| nginx-limit-req | ✅ 运行 | 请求频率限制 |

### 2.2 网络层

| 项目 | 状态 | 说明 |
|------|------|------|
| iptables | ⚠️ 默认ACCEPT | 无自定义规则 |
| 阿里云安全组 | ✅ 配置中 | 22/80/443端口开放 |
| UFW | ❌ 未安装 | 可选安装简化防火墙管理 |

### 2.3 建议

- [ ] 配置iptables基础规则（允许22/80/443，拒绝其他）
- [ ] 考虑启用阿里云WAF或Cloudflare免费套餐

---

## 3. 数据库备份

### 3.1 自动备份

| 项目 | 值 |
|------|-----|
| 脚本位置 | `/opt/huiyuyuan/scripts/db_backup.sh` |
| 执行频率 | 每日 3:00 AM（cron） |
| 保留天数 | 7 天 |
| 备份目录 | `/opt/huiyuyuan/backups/` |
| 备份格式 | PostgreSQL custom dump + gzip |
| 执行用户 | postgres（peer认证） |

### 3.2 验证方式

```bash
# 手动触发备份
bash /opt/huiyuyuan/scripts/db_backup.sh

# 查看备份日志
tail -20 /opt/huiyuyuan/logs/db_backup.log

# 列出备份文件
ls -lh /opt/huiyuyuan/backups/*.dump.gz
```

### 3.3 恢复测试（建议每季度执行）

```bash
# 1. 停止后端
systemctl stop huiyuyuan-backend

# 2. 删除当前数据库
sudo -u postgres dropdb huiyuyuan
sudo -u postgres createdb -O huyy_user huiyuyuan

# 3. 恢复最新备份
LATEST=$(ls -t /opt/huiyuyuan/backups/*.dump.gz | head -1)
gunzip -c "$LATEST" | sudo -u postgres pg_restore -d huiyuyuan

# 4. 重启后端
systemctl start huiyuyuan-backend
```

---

## 4. 后端快照

### 4.1 自动快照

| 项目 | 值 |
|------|-----|
| 快照目录 | `/opt/huiyuyuan/snapshots/` |
| 触发方式 | deploy.ps1 每次后端部署前自动创建 |
| 保留策略 | 手动管理（建议保留最近3个） |

### 4.2 清理旧快照

```bash
# 查看快照
ls -dt /opt/huiyuyuan/snapshots/*

# 保留最近3个，删除其余
ls -dt /opt/huiyuyuan/snapshots/* | tail -n +4 | xargs rm -rf
```

---

## 5. Swap 内存

| 项目 | 值 |
|------|-----|
| Swap 文件 | `/swapfile` |
| 大小 | 2 GB |
| 类型 | file |
| 开机挂载 | ✅ 已写入 /etc/fstab |

---

## 6. SSL 证书

| 项目 | 值 |
|------|-----|
| 颁发机构 | Let's Encrypt |
| 域名 | xn--lsws2cdzg.top, www.xn--lsws2cdzg.top |
| 到期时间 | 2026-06-22 |
| 自动续期 | ✅ cron 每日 3:00 执行 certbot renew |
| 续期策略 | 到期前 30 天自动续 |
| Webroot | /var/www/certbot |

### 验证命令

```bash
# 手动测试续期（dry-run）
certbot renew --dry-run

# 查看证书信息
openssl x509 -enddate -noout -in /etc/letsencrypt/live/xn--lsws2cdzg.top/fullchain.pem
```

---

## 7. 环境变量与密钥管理

### 7.1 后端环境变量

| 项目 | 值 |
|------|-----|
| 文件位置 | `/srv/huiyuyuan/backend/.env` |
| 权限 | `-rw-------` (600) |
| 所有者 | root:root |

### 7.2 敏感变量清单

| 变量 | 用途 | 保护级别 |
|------|------|----------|
| DATABASE_URL | PostgreSQL 连接 | 高 |
| REDIS_URL | Redis 连接 | 中 |
| JWT_SECRET_KEY | JWT 签名 | 高 |
| DASHSCOPE_API_KEY | AI 服务 | 高 |
| ALLOWED_ORIGINS | CORS 白名单 | 低 |

### 7.3 前端密钥

| 项目 | 值 |
|------|-----|
| 本地开发 | `.env.json`（已 gitignore） |
| 生产构建 | `--dart-define=DASHSCOPE_API_KEY=...` |
| CI/CD | GitHub Secrets |

### 7.4 建议

- [ ] 定期轮换 JWT_SECRET_KEY（用户需重新登录）
- [ ] 定期轮换 DASHSCOPE_API_KEY
- [ ] 备份 .env 文件到安全位置（加密存储）

---

## 8. 服务状态监控

### 8.1 关键服务

| 服务 | 状态 | 自启动 |
|------|------|--------|
| huiyuyuan-backend | ✅ active | ✅ enabled |
| nginx | ✅ active | ✅ enabled |
| postgresql | ✅ active | ✅ enabled |
| redis | ✅ active | ✅ enabled |
| fail2ban | ✅ active | ✅ enabled |

### 8.2 监控命令

```bash
# 快速状态检查
systemctl is-active huiyuyuan-backend nginx postgresql redis fail2ban

# 资源使用
free -h
df -h /
top -bn1 | head -15

# 服务日志
journalctl -u huiyuyuan-backend -n 50 --no-pager
tail -50 /var/log/nginx/huiyuyuan_error.log
```

---

## 9. 阿里云安全组件

| 组件 | 状态 | 说明 |
|------|------|------|
| 云盾（Aegis） | ✅ 运行 | 阿里云基础安全防护 |
| WAF | ❌ 未启用 | 可选，建议启用 |
| Anti-DDoS 基础 | ✅ 默认启用 | 阿里云免费提供 5Gbps 防护 |
| CDN | ❌ 未启用 | 可选，加速静态资源 |

---

## 10. 安全事件响应

### 10.1 可疑登录

```bash
# 查看最近的 SSH 登录日志
journalctl -u sshd -n 100 --no-pager | grep -E 'Accepted|Failed'

# 查看当前登录用户
who
last -10
```

### 10.2 服务异常

```bash
# 检查进程异常
ps aux | grep -E 'python|node|ruby' | grep -v grep

# 检查网络连接
netstat -tlnp | grep -E ':80|:443|:22|:8000'
```

### 10.3 数据库异常

```bash
# 检查慢查询
sudo -u postgres psql -d huiyuyuan -c "SELECT * FROM pg_stat_activity WHERE state != 'idle';"

# 检查锁
sudo -u postgres psql -d huiyuyuan -c "SELECT * FROM pg_locks WHERE NOT granted;"
```

---

## 11. 合规与审计

| 项目 | 状态 | 说明 |
|------|------|------|
| 日志保留 | ✅ 系统默认 | journalctl 默认保留 |
| 数据库审计 | ❌ 未启用 | 可开启 pgAudit |
| 访问日志 | ✅ Nginx access log | `/var/log/nginx/huiyuyuan_access.log` |
| 错误日志 | ✅ Nginx error log | `/var/log/nginx/huiyuyuan_error.log` |

---

## 12. Phase E 完成总结

### 已完成

- ✅ 数据库自动备份脚本（每日3:00，保留7天）
- ✅ Swap 分区（2GB，开机自动挂载）
- ✅ SSL 证书续期验证（cron 自动，到期前30天）
- ✅ fail2ban 状态确认（3个jail运行）
- ✅ SSH 安全基线确认（仅密钥认证）
- ✅ 服务监控清单建立

### 建议后续执行（非阻塞）

- [ ] 改为非标准SSH端口
- [ ] 配置iptables基础规则
- [ ] 启用阿里云WAF
- [ ] 定期恢复测试（季度）
- [ ] 密钥轮换策略
