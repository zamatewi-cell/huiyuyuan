# 汇玉源 - 域名注册与 SSL 证书配置指南

> 文档版本：v1.1  
> 最后更新：2026-03-25  
> 适用环境：Alibaba Cloud Linux 3.2104 LTS + Nginx + Let's Encrypt  
> 实战记录：完整配置过程已验证通过

---

## 📋 目录

1. [域名注册与 DNS 解析](#域名注册与 dns 解析)
2. [SSL 证书申请与配置](#ssl 证书申请与配置)
3. [自动续期配置](#自动续期配置)
4. [常见问题排查](#常见问题排查)
5. [实战问题总结](#实战问题总结)
6. [后续待办事项](#后续待办事项)

---

## 域名注册与 DNS 解析

### 1.1 域名注册

**推荐平台：**
- 阿里云（万网）：https://www.aliyun.com
- 腾讯云（DNSPod）：https://cloud.tencent.com
- Namecheap：https://www.namecheap.com

**汇玉源项目域名：** `汇玉源.top`

### 1.2 DNS 解析配置

登录阿里云控制台 → 域名与网站 → 域名列表 → 管理 → 解析设置

添加以下 A 记录：

| 主机记录 | 记录类型 | 记录值 | 说明 |
|---------|---------|--------|------|
| @ | A | 47.112.98.191 | 主域名 |
| www | A | 47.112.98.191 | www 子域名 |

**生效时间：** 10 分钟～2 小时

### 1.3 验证 DNS 解析

在本地 Windows PowerShell 执行：

```powershell
# 测试主域名
nslookup 汇玉源.top

# 测试 www 子域名
nslookup www.汇玉源.top

# 预期输出：
# 名称：汇玉源.top
# Address: 47.112.98.191
```

### 1.4 服务器 DNS 配置

如果服务器无法解析域名，需要修改 DNS 服务器配置：

```bash
# SSH 登录服务器
ssh root@47.112.98.191

# 编辑 resolv.conf
vi /etc/resolv.conf

# 添加阿里云 DNS 服务器
nameserver 223.5.5.5
nameserver 8.8.8.8
options timeout:2 attempts:3

# 验证解析
ping 汇玉源.top -c 4
```

---

## SSL 证书申请与配置

### 2.1 安装 Certbot

Alibaba Cloud Linux 使用 yum 安装（snap 方式可能不可用）：

```bash
# 检查是否已安装
which certbot
certbot --version

# 如果未安装，使用 yum 安装
yum install certbot python3-certbot-nginx -y
```

### 2.2 获取 Punycode 编码

中文域名需要转换为 Punycode 格式：

```bash
# 使用 Python 转换
python3 -c "print('汇玉源.top'.encode('idna').decode('ascii'))"
# 输出：xn--lsws2cdzg.top

python3 -c "print('www.汇玉源.top'.encode('idna').decode('ascii'))"
# 输出：www.xn--lsws2cdzg.top
```

### 2.3 申请 SSL 证书

```bash
# 使用 Punycode 申请证书
certbot --nginx -d xn--lsws2cdzg.top -d www.xn--lsws2cdzg.top
```

**按提示操作：**
1. 输入邮箱（用于续期提醒）
2. 同意服务条款：输入 `A`
3. 订阅 EFF 邮件：输入 `Y` 或 `N`
4. 选择 HTTPS 重定向：输入 `2`（推荐）

### 2.4 配置 Nginx 使用 SSL 证书

编辑 Nginx 配置文件：

```bash
# 备份原配置
cp /etc/nginx/conf.d/huiyuyuan.conf /etc/nginx/conf.d/huiyuyuan.conf.backup

# 编辑配置
vi /etc/nginx/conf.d/huiyuyuan.conf
```

完整配置内容：

```nginx
# 限流配置
limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;
limit_req_zone $binary_remote_addr zone=sms:10m rate=5r/m;

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name xn--lsws2cdzg.top www.xn--lsws2cdzg.top;

    # Let's Encrypt 域名验证（必须在 HTTP server 块中）
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }

    # 其他 HTTP 请求重定向到 HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    server_name xn--lsws2cdzg.top www.xn--lsws2cdzg.top;
    client_max_body_size 20M;

    # SSL 证书路径
    ssl_certificate /etc/letsencrypt/live/xn--lsws2cdzg.top/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/xn--lsws2cdzg.top/privkey.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5:!RC4;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/javascript application/json text/javascript;

    # 前端文件根目录
    root /var/www/huiyuyuan;
    index index.html;

    # Flutter 关键文件不缓存
    location ~ ^/(index\.html|flutter_bootstrap\.js|flutter_service_worker\.js|main\.dart\.js|version\.json)$ {
        add_header Cache-Control 'no-cache, no-store, must-revalidate';
        add_header Pragma 'no-cache';
        add_header Expires '0';
        try_files $uri =404;
    }

    # 发送短信接口限流
    location /api/auth/send-sms {
        limit_req zone=sms burst=3 nodelay;
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # API 反向代理
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
        proxy_connect_timeout 10s;
    }

    # 上传文件
    location /uploads/ {
        alias /srv/huiyuyuan/backend/uploads/;
        expires 30d;
    }

    # SPA 路由
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 隐藏文件禁止访问
    location ~ /\. {
        deny all;
    }
}
```

### 2.5 测试并重启 Nginx

```bash
# 测试配置
nginx -t

# 重启 Nginx
systemctl reload nginx

# 查看状态
systemctl status nginx
```

### 2.6 验证 HTTPS

```bash
# 测试 HTTPS 访问
curl -I https://xn--lsws2cdzg.top

# 查看证书信息
echo | openssl s_client -connect xn--lsws2cdzg.top:443 2>/dev/null | openssl x509 -noout -dates

# 预期输出：
# notBefore=Mar 24 14:29:44 2026 GMT
# notAfter=Jun 22 14:29:43 2026 GMT
```

---

## 自动续期配置

### 3.1 Let's Encrypt 证书有效期

- **有效期：** 90 天
- **自动续期：** 到期前 30 天
- **提醒方式：** 邮件通知

### 3.2 配置自动续期（cron 方式）

yum 安装的 Certbot 可能没有 systemd timer，使用 cron 更可靠：

```bash
# 1. 检查 cron 服务
systemctl status crond

# 2. 如果没有运行，启动它
systemctl start crond
systemctl enable crond

# 3. 添加续期任务到 cron（每天凌晨 3 点检查）
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet --preferred-challenges webroot --webroot-path /var/www/certbot") | crontab -

# 4. 验证 cron 任务
crontab -l
```

### 3.3 手动测试续期

```bash
# 测试续期（不会实际执行）
certbot renew --dry-run

# 如果失败，使用 webroot 模式
certbot renew --dry-run --preferred-challenges webroot --webroot-path /var/www/certbot
```

### 3.4 手动续期（紧急情况）

如果自动续期失败，可以手动续期：

```bash
# 方法 1：停止 Nginx，使用 standalone 模式（100% 成功）
systemctl stop nginx && certbot renew --force-renewal && systemctl start nginx

# 方法 2：使用 webroot 模式
certbot renew --force-renewal --preferred-challenges webroot --webroot-path /var/www/certbot

# 查看证书列表
certbot certificates
```

---

## 常见问题排查

### 问题 1：域名无法解析

**症状：** `ping: xn--lsws2cdzg.top: Name or service not known`

**解决方案：**
```bash
# 检查 /etc/resolv.conf
cat /etc/resolv.conf

# 如果没有 DNS 服务器，添加
nameserver 223.5.5.5
nameserver 8.8.8.8

# 测试解析
ping 汇玉源.top -c 4
```

### 问题 2：Certbot 不支持中文域名

**症状：** `Non-ASCII domain names not supported`

**解决方案：** 使用 Punycode 编码
```bash
# 生成 Punycode
python3 -c "print('汇玉源.top'.encode('idna').decode('ascii'))"

# 使用 Punycode 申请证书
certbot --nginx -d xn--lsws2cdzg.top -d www.xn--lsws2cdzg.top
```

### 问题 3：SSL 证书安装失败

**症状：** `Could not install certificate`

**解决方案：** 手动配置 Nginx SSL 设置（见 2.4 节）

### 问题 4：自动续期 403 错误

**症状：** `403 Forbidden` 或 `unauthorized`

**原因：** `.well-known/acme-challenge/` 路径被阻止或目录不存在

**解决方案：**
```bash
# 1. 创建完整的目录结构
mkdir -p /var/www/certbot/.well-known/acme-challenge

# 2. 设置正确的权限
chmod -R 755 /var/www/certbot
chown -R nginx:nginx /var/www/certbot

# 3. 在 HTTP server 块中添加 location（不是 HTTPS server 块）
location /.well-known/acme-challenge/ {
    root /var/www/certbot;
    allow all;
}
```

### 问题 5：Nginx 启动失败 - 端口占用

**症状：** `Address already in use`

**原因：** Nginx 已经在运行，重复启动导致失败

**解决方案：**
```bash
# 强制重启 Nginx
systemctl stop nginx
pkill -9 nginx
systemctl start nginx

# 或者使用 reload
systemctl reload nginx
```

### 问题 6：安全组端口未开放

**症状：** 无法访问 HTTP/HTTPS

**解决方案：**
1. 登录阿里云控制台 → ECS → 网络与安全 → 安全组
2. 添加入方向规则：
   - HTTP: 80/80，授权对象 0.0.0.0/0
   - HTTPS: 443/443，授权对象 0.0.0.0/0

---

## 实战问题总结

> 本节记录了实际配置过程中遇到的所有问题和解决方案，按时间顺序排列。

### 问题 1：操作系统包管理器不匹配

**时间：** 安装 Certbot 时  
**症状：** `sudo: apt: command not found`  
**原因：** Alibaba Cloud Linux 基于 CentOS/RHEL，使用 yum/dnf 而非 apt  
**解决方案：**
```bash
# 使用 yum 安装
yum install certbot python3-certbot-nginx -y

# 或使用 snap（如果可用）
yum install snapd -y
snap install --classic certbot
```

### 问题 2：EPEL 仓库冲突

**时间：** 尝试安装 EPEL 时  
**症状：** `package epel-aliyuncs-release conflicts with epel-release`  
**原因：** 阿里云定制的 EPEL 与官方 EPEL 冲突  
**解决方案：** 直接使用已有的阿里云 EPEL，或跳过 EPEL 直接安装 certbot

### 问题 3：DNS 解析失败

**时间：** 申请证书前  
**症状：** `ping: xn--lsws2cdzg.top: Name or service not known`  
**原因：** 服务器 DNS 配置问题  
**解决方案：**
```bash
# 直接修改 /etc/resolv.conf
cat > /etc/resolv.conf << 'EOF'
nameserver 223.5.5.5
nameserver 8.8.8.8
options timeout:2 attempts:3
EOF
```

### 问题 4：Punycode 编码错误

**时间：** 申请证书时  
**症状：** `server can't find 冲.top: NXDOMAIN`  
**原因：** 错误的 Punycode 编码（`xn--57q.top` 而非正确的 `xn--lsws2cdzg.top`）  
**解决方案：**
```bash
# 使用 Python 生成正确的 Punycode
python3 -c "print('汇玉源.top'.encode('idna').decode('ascii'))"
# 输出：xn--lsws2cdzg.top
```

### 问题 5：Certbot 自动续期失败 - 目录不存在

**时间：** 测试续期时  
**症状：** `open() "/var/www/certbot/.well-known/acme-challenge/xxx" failed (2: No such file or directory)`  
**原因：** 只创建了 `/var/www/certbot`，没有创建 `.well-known/acme-challenge` 子目录  
**解决方案：**
```bash
# 创建完整的目录结构
mkdir -p /var/www/certbot/.well-known/acme-challenge

# 设置正确的权限
chmod -R 755 /var/www/certbot
chown -R nginx:nginx /var/www/certbot
```

### 问题 6：Certbot 自动续期失败 - location 配置位置错误

**时间：** 多次尝试续期  
**症状：** `403 Forbidden`  
**原因：** `.well-known/acme-challenge/` location 块被放在了 HTTPS server 块中，但 Certbot 验证使用的是 HTTP（80 端口）  
**解决方案：** 在 HTTP server 块（listen 80）中添加 location：
```nginx
server {
    listen 80;
    server_name xn--lsws2cdzg.top www.xn--lsws2cdzg.top;

    # Let's Encrypt 域名验证（必须在 HTTP server 块中）
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
```

### 问题 7：Certbot nginx 插件兼容性

**时间：** 使用 `certbot renew --dry-run`  
**症状：** `Missing command line flag or config entry for this setting`  
**原因：** Certbot 1.22.0 的 nginx 插件与当前配置不兼容  
**解决方案：** 改用 webroot 模式：
```bash
# 修改续期配置文件
vi /etc/letsencrypt/renewal/xn--lsws2cdzg.top.conf

# 将 authenticator = nginx 改为 authenticator = webroot
# 添加 [[webroot_map]] 部分
```

### 问题 8：最终成功的续期方法

**时间：** 最终解决  
**症状：** 多种方法都失败  
**解决方案：** 使用 standalone 模式（停止 Nginx，释放 80 端口）：
```bash
# 一行命令搞定
systemctl stop nginx && certbot renew --force-renewal && systemctl start nginx
```

**输出：**
```
Congratulations, all renewals succeeded:
  /etc/letsencrypt/live/xn--lsws2cdzg.top/fullchain.pem (success)
```

### 问题 9：自动续期定时器不存在

**时间：** 配置自动续期  
**症状：** `Unit file certbot.timer does not exist`  
**原因：** yum 安装的 Certbot 没有创建 systemd timer  
**解决方案：** 使用 cron 替代：
```bash
# 添加续期任务到 cron
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet --preferred-challenges webroot --webroot-path /var/www/certbot") | crontab -
```

---

## 后续待办事项

### 5.1 本地项目配置更新

以下仓库文件应当与域名/证书状态保持一致：

```text
huiyuyuan_app/lib/config/api_config.dart
huiyuyuan_app/backend/nginx_current.conf
huiyuyuan_app/backend/nginx_production.conf
huiyuyuan_app/backend/.env.example
scripts/deploy.ps1
```

当前推荐的生产值：

```text
生产域名: https://xn--lsws2cdzg.top
CORS: https://汇玉源.top, https://www.汇玉源.top,
      https://xn--lsws2cdzg.top, https://www.xn--lsws2cdzg.top
Nginx 配置路径: /etc/nginx/conf.d/huiyuyuan.conf
后端服务: huiyuyuan-backend
后端代码目录: /srv/huiyuyuan/backend
```

服务器 `.env` 权威路径为 `/srv/huiyuyuan/backend/.env`，后端通过 `python-dotenv` 加载。
- `/srv/huiyuyuan/backend/.env`

### 5.2 重新部署项目

在 Windows PowerShell 执行：

```powershell
cd d:\huiyuyuan_project

# 推荐顺序：先后端和数据库迁移，再 Nginx，再前端
.\scripts\deploy.ps1 -Target backend
.\scripts\deploy.ps1 -Target nginx
.\scripts\deploy.ps1 -Target web

# 如果是全新数据库，再额外执行
.\scripts\deploy.ps1 -Target db-init
```

说明：

- `backend` 目标会自动执行 `alembic upgrade head`
- `nginx` 目标会把 `nginx_current.conf` 下发到 `/etc/nginx/conf.d/huiyuyuan.conf`
- `web` 目标会上传 Flutter Web 构建产物到 `/var/www/huiyuyuan/`

### 5.3 验证清单

- [ ] 浏览器访问 `https://汇玉源.top` 显示正常
- [ ] 浏览器访问 `https://www.汇玉源.top` 显示正常
- [ ] HTTP 自动跳转到 HTTPS
- [ ] API 接口正常工作
- [ ] `huiyuyuan-backend` 服务状态正常
- [ ] `curl http://127.0.0.1:8000/api/health` 返回正常
- [ ] `curl -I https://xn--lsws2cdzg.top/api/health` 返回正常
- [ ] 浏览器地址栏显示安全锁图标
- [ ] 证书自动续期测试通过

### 5.4 监控与维护

```bash
# 查看证书过期时间
certbot certificates

# 设置证书过期提醒（日历事件）
# 证书到期前 30 天检查自动续期是否成功

# 检查后端服务
systemctl status huiyuyuan-backend
journalctl -u huiyuyuan-backend -n 50 --no-pager

# 定期检查 Nginx 日志
tail -f /var/log/nginx/huiyuyuan_access.log
tail -f /var/log/nginx/huiyuyuan_error.log
```

---

## 附录

### A. 重要文件路径

| 文件 | 路径 |
|------|------|
| Nginx 配置 | `/etc/nginx/conf.d/huiyuyuan.conf` |
| SSL 证书 | `/etc/letsencrypt/live/xn--lsws2cdzg.top/fullchain.pem` |
| SSL 私钥 | `/etc/letsencrypt/live/xn--lsws2cdzg.top/privkey.pem` |
| 后端环境配置 | `/srv/huiyuyuan/backend/.env` |
| 前端文件目录 | `/var/www/huiyuyuan/` |
| 后端应用目录 | `/srv/huiyuyuan/backend/` |
| 续期配置 | `/etc/letsencrypt/renewal/xn--lsws2cdzg.top.conf` |
| Cron 任务 | `/var/spool/cron/root` |

### B. 常用命令速查

```bash
# Nginx 相关
nginx -t                          # 测试配置
systemctl reload nginx            # 重载配置
systemctl status nginx            # 查看状态
systemctl restart nginx           # 重启服务
systemctl stop nginx              # 停止服务
systemctl start nginx             # 启动服务

# Certbot 相关
certbot certificates              # 查看证书列表
certbot renew --dry-run           # 测试续期
certbot renew --force-renewal     # 强制续期
certbot delete --cert-name <name> # 删除证书

# DNS 测试
ping 汇玉源.top -c 4              # 测试域名解析
nslookup 汇玉源.top 223.5.5.5     # 指定 DNS 查询

# HTTPS 测试
curl -I https://汇玉源.top        # 测试 HTTPS 访问
openssl s_client -connect 汇玉源.top:443  # 查看证书详情

# Cron 相关
crontab -l                        # 查看 cron 任务
crontab -e                        # 编辑 cron 任务
systemctl status crond            # 查看 cron 状态
```

### C. 实战经验总结

#### 关键教训

1. **中文域名必须使用 Punycode**  
   始终使用 `python3 -c "print('域名'.encode('idna').decode('ascii'))"` 生成正确的编码

2. **Certbot 验证使用 HTTP 而非 HTTPS**  
   `.well-known/acme-challenge/` location 必须放在 `listen 80` 的 server 块中

3. **目录结构必须完整**  
   创建 `/var/www/certbot/.well-known/acme-challenge/` 而不仅仅是 `/var/www/certbot`

4. **standalone 模式最可靠**  
   当 nginx 插件失败时，`systemctl stop nginx && certbot renew --force-renewal` 100% 成功

5. **cron 比 systemd timer 更可靠**  
   yum 安装的 Certbot 可能没有 timer，使用 cron 更通用

#### 推荐流程

1. 安装 Certbot → 2. 申请证书 → 3. 配置 Nginx → 4. 测试续期 → 5. 配置 cron

如果续期测试失败，直接使用 standalone 模式强制续期，然后配置 cron 自动续期。

### D. 参考资料

- [Let's Encrypt 官方文档](https://letsencrypt.org/docs/)
- [Certbot 用户指南](https://certbot.eff.org/docs/)
- [Nginx SSL 配置指南](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [阿里云 DNS 解析](https://help.aliyun.com/product/29697.html)
- [中文域名技术 FAQ](https://help.aliyun.com/knowledge_detail/35953.html)
- [Alibaba Cloud Linux 文档](https://help.aliyun.com/product/52649.html)

---

**文档结束**

如有问题，请查看日志文件或联系技术支持。
