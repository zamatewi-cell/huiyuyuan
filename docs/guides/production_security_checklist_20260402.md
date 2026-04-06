# 生产发布前安全清单

> 更新时间：2026-04-02
> 适用范围：`https://xn--lsws2cdzg.top`

## 1. 代码层已补齐

- 密码继续使用 `bcrypt` 哈希，不是明文存储。
- 生产环境强制要求 `JWT_SECRET_KEY`，避免临时密钥上线。
- 生产环境强制要求显式 `ALLOWED_ORIGINS`，不允许 `*`。
- 后端新增 `ALLOWED_HOSTS` / 来源主机校验，避免异常 `Host` 头直接打到应用。
- 后端统一补充安全响应头：
  - `X-Frame-Options: DENY`
  - `X-Content-Type-Options: nosniff`
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - `Permissions-Policy`
  - 生产环境下的 `Strict-Transport-Security`
- `/api/auth/*` 响应增加 `Cache-Control: no-store`，降低令牌被中间层缓存的风险。
- 密码登录增加失败限流：
  - 同一账号+IP 连续失败达到阈值后，15 分钟内拒绝继续尝试
  - 同一 IP 的累计失败次数也会被限制

## 2. Nginx 层已要求

- 只开放 `80/443`，业务流量通过 `nginx` 进入，不要直接暴露 `8000`。
- 已配置 `TLSv1.2/TLSv1.3`、HSTS、安全响应头、上传大小限制。
- 已配置 `limit_req` / `limit_conn`：
  - `/api/auth/send-sms`
  - `/api/auth/login|register|verify-sms|refresh|logout`
  - `/api/upload`
  - `/api/`
- 现在额外要求：
  - `server_tokens off`
  - 限流和连接超限直接返回 `429`

## 3. 发布前必须确认

- 安全组只允许公网访问 `80/443`，`22` 仅限运维 IP。
- `8000` 端口不能对公网开放。
- `/srv/huiyuyuan/backend/.env` 已配置：
  - `APP_ENV=production`
  - `JWT_SECRET_KEY`
  - `ALLOWED_ORIGINS`
  - `ALLOWED_HOSTS`
  - `DATABASE_URL`
  - `REDIS_URL`
- PostgreSQL 和 Redis 使用强密码，且 Redis 不能裸露到公网。
- 管理员账号必须改成强密码，不能继续使用默认弱口令。
- 服务器开启自动安全更新、日志轮转、磁盘空间监控。

## 4. 防 DDoS / 扫描还需要的基础设施

这些不能只靠代码解决，正式对外前建议继续补：

- 接入云厂商防护：
  - 阿里云 `Anti-DDoS Origin` / `WAF`
  - 或者 CDN / 代理防护层（如 Cloudflare）
- SSH 只允许密钥登录，禁用密码登录。
- 已补服务端脚本 [install_fail2ban.sh](/D:/huiyuyuan_project/huiyuyuan_app/backend/scripts/install_fail2ban.sh) 可用于启用 `sshd`、`nginx-limit-req`、`nginx-botsearch` 自动封禁。
- 对登录、支付确认、上传接口接入日志告警。
- 做数据库定时备份和回滚演练。

## 5. 这次发布后的最小验收

- `https://xn--lsws2cdzg.top/api/health` 正常返回 `200`
- 收款账户页不再报“网络连接失败”
- 下单后支付页能看到平台收款二维码 / 收款信息
- 管理员能在后台确认到账，订单状态再变为 `paid`
- 重复输错管理员密码多次后，会被临时限制登录
