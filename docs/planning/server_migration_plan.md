# 汇玉源服务器迁移计划

> 迁移日期: 2026-03-17
> 当前服务器: 47.98.188.141 (Ubuntu 22.04)
> 目标: 完整迁移至新云服务器，确保数据完整性和服务连续性

---

## 一、迁移概述

### 1.1 迁移目标
1. **服务器迁移**：将现有系统完整迁移至新云服务器
2. **环境配置**：在新服务器上安装所有必要的依赖包、配置运行环境及数据库系统
3. **文档更新**：修改相关Markdown文档，详细记录服务器迁移的过程、新服务器信息及配置变更
4. **安全加固**：实施服务器安全加固措施
5. **技术债务修复**：修复现有技术债务和数据风险

### 1.2 迁移范围
- **后端服务**：FastAPI应用 (Python 3.11 + Gunicorn)
- **数据库**：PostgreSQL 15 + Redis
- **前端服务**：Flutter Web应用
- **Web服务器**：Nginx反向代理
- **系统服务**：systemd服务管理、日志轮转、备份脚本

### 1.3 迁移策略
采用**蓝绿部署**策略，确保服务零停机时间：
1. 在新服务器上部署完整环境
2. 数据同步和验证
3. DNS切换或负载均衡切换
4. 旧服务器保留作为回滚备份

---

## 二、当前服务器状态分析

### 2.1 服务器配置
| 项目 | 当前值 | 备注 |
|------|--------|------|
| IP地址 | 47.98.188.141 | 阿里云ECS |
| 操作系统 | Ubuntu 22.04 LTS | |
| CPU | 2核 | |
| 内存 | 4GB | |
| 带宽 | 5Mbps | |
| 存储 | 40GB SSD | |

### 2.2 已部署服务
1. **FastAPI后端**：`/srv/huiyuanyuan/` (Gunicorn + Uvicorn)
2. **Flutter Web前端**：`/var/www/huiyuanyuan/`
3. **PostgreSQL 15**：数据库服务
4. **Redis**：缓存服务
5. **Nginx**：反向代理和静态文件服务

### 2.3 技术债务识别
1. **main.py单文件问题**：2246行代码，需要模块化拆分
2. **内存存储风险**：部分数据仍使用内存存储，数据可靠性不足
3. **安全配置**：CORS配置宽松、硬编码密钥等安全问题
4. **测试覆盖不足**：后端测试覆盖率低

---

## 三、迁移详细计划

### 3.1 阶段一：准备工作 (Day 1)

#### 3.1.1 新服务器采购
- **推荐配置**：阿里云ECS 2核4G 5Mbps
- **操作系统**：Ubuntu 22.04 LTS
- **存储**：50GB SSD (预留扩展空间)
- **地域**：中国大陆 (合规要求)

#### 3.1.2 数据备份
```bash
# 1. 数据库备份
pg_dump -U huyy_user huiyuanyuan > /opt/huiyuanyuan/backups/db_backup_$(date +%Y%m%d).sql

# 2. 应用文件备份
tar -czf /opt/huiyuanyuan/backups/app_backup_$(date +%Y%m%d).tar.gz /srv/huiyuanyuan/

# 3. 前端文件备份
tar -czf /opt/huiyuanyuan/backups/web_backup_$(date +%Y%m%d).tar.gz /var/www/huiyuanyuan/

# 4. 配置文件备份
cp /etc/nginx/sites-enabled/huiyuanyuan /opt/huiyuanyuan/backups/nginx_backup_$(date +%Y%m%d).conf
cp /etc/systemd/system/huiyuanyuan.service /opt/huiyuanyuan/backups/systemd_backup_$(date +%Y%m%d).service
```

#### 3.1.3 迁移脚本准备
创建自动化迁移脚本，包含：
- 环境安装脚本
- 数据迁移脚本
- 服务配置脚本
- 验证脚本

### 3.2 阶段二：新服务器环境配置 (Day 2)

#### 3.2.1 系统初始化
```bash
# 1. 系统更新
apt update && apt upgrade -y

# 2. 安装基础工具
apt install -y git curl wget unzip htop iotop logrotate ufw jq

# 3. 配置时区
timedatectl set-timezone Asia/Shanghai
```

#### 3.2.2 数据库安装配置
```bash
# 1. 安装PostgreSQL 15
apt install -y postgresql-15 postgresql-client-15 postgresql-contrib-15

# 2. 创建数据库和用户
sudo -u postgres psql -c "CREATE USER huyy_user WITH PASSWORD 'NEW_STRONG_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE huiyuanyuan OWNER huyy_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE huiyuanyuan TO huyy_user;"

# 3. 配置PostgreSQL优化参数
cat > /etc/postgresql/15/main/conf.d/huiyuanyuan.conf << 'EOF'
shared_buffers = 512MB
effective_cache_size = 1GB
work_mem = 8MB
maintenance_work_mem = 128MB
max_connections = 100
log_min_duration_statement = 1000
log_statement = 'ddl'
timezone = 'Asia/Shanghai'
EOF

# 4. 配置访问权限
echo "local   huiyuanyuan   huyy_user   scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf
echo "host    huiyuanyuan   huyy_user   127.0.0.1/32   scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf

systemctl restart postgresql
```

#### 3.2.3 Redis安装配置
```bash
# 1. 安装Redis
apt install -y redis-server

# 2. 安全配置
REDIS_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(16))")

# 修改Redis配置
sed -i 's/^bind .*/bind 127.0.0.1 ::1/' /etc/redis/redis.conf
echo "requirepass ${REDIS_PASSWORD}" >> /etc/redis/redis.conf

# 禁用危险命令
cat >> /etc/redis/redis.conf << 'EOF'
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command DEBUG ""
rename-command CONFIG ""
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF

systemctl restart redis-server
```

#### 3.2.4 Python环境配置
```bash
# 1. 安装Python 3.11
apt install -y python3.11 python3.11-venv python3-pip

# 2. 创建应用目录
mkdir -p /srv/huiyuanyuan
mkdir -p /var/log/huiyuanyuan
mkdir -p /opt/huiyuanyuan/backups
mkdir -p /var/www/huiyuanyuan

# 3. 创建虚拟环境
cd /srv/huiyuanyuan
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
```

### 3.3 阶段三：应用迁移 (Day 3)

#### 3.3.1 后端应用迁移
```bash
# 1. 传输应用文件
scp -r /srv/huiyuanyuan/* root@NEW_SERVER_IP:/srv/huiyuanyuan/

# 2. 安装依赖
cd /srv/huiyuanyuan
source venv/bin/activate
pip install -r requirements.txt

# 3. 配置环境变量
cat > /srv/huiyuanyuan/.env << 'EOF'
# 数据库配置
DATABASE_URL=postgresql://huyy_user:NEW_STRONG_PASSWORD@localhost:5432/huiyuanyuan

# Redis配置
REDIS_URL=redis://:NEW_REDIS_PASSWORD@localhost:6379/0

# JWT配置
JWT_SECRET_KEY=NEW_JWT_SECRET_KEY
JWT_ALGORITHM=HS256
JWT_ACCESS_EXPIRE_MINUTES=120
JWT_REFRESH_EXPIRE_DAYS=7

# 应用配置
APP_ENV=production
DEBUG=false
ALLOWED_ORIGINS=http://NEW_SERVER_IP
LOG_LEVEL=INFO
EOF

chmod 600 /srv/huiyuanyuan/.env
```

#### 3.3.2 数据库迁移
```bash
# 1. 传输数据库备份
scp /opt/huiyuanyuan/backups/db_backup_*.sql root@NEW_SERVER_IP:/tmp/

# 2. 在新服务器上恢复数据
sudo -u postgres psql -d huiyuanyuan -f /tmp/db_backup_*.sql

# 3. 运行数据库迁移
cd /srv/huiyuanyuan
source venv/bin/activate
alembic upgrade head
```

#### 3.3.3 前端应用迁移
```bash
# 1. 构建Flutter Web应用
cd /path/to/huiyuanyuan_app
flutter build web --release

# 2. 传输前端文件
scp -r build/web/* root@NEW_SERVER_IP:/var/www/huiyuanyuan/
```

### 3.4 阶段四：服务配置 (Day 4)

#### 3.4.1 systemd服务配置
```bash
cat > /etc/systemd/system/huiyuanyuan.service << 'EOF'
[Unit]
Description=汇玉源 FastAPI 后端服务 v4.0
After=network.target postgresql.service redis-server.service
Requires=postgresql.service
Wants=redis-server.service

[Service]
Type=notify
User=root
Group=root
WorkingDirectory=/srv/huiyuanyuan
Environment="PATH=/srv/huiyuanyuan/venv/bin:/usr/local/bin:/usr/bin"
EnvironmentFile=/srv/huiyuanyuan/.env

ExecStart=/srv/huiyuanyuan/venv/bin/gunicorn main:app \
    -w 2 \
    -k uvicorn.workers.UvicornWorker \
    --bind 127.0.0.1:8000 \
    --access-logfile /var/log/huiyuanyuan/access.log \
    --error-logfile /var/log/huiyuanyuan/error.log \
    --timeout 120 \
    --graceful-timeout 30 \
    --max-requests 1000 \
    --max-requests-jitter 100

ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30

Restart=on-failure
RestartSec=5
StartLimitBurst=5
StartLimitIntervalSec=60

ProtectSystem=strict
ReadWritePaths=/srv/huiyuanyuan /var/log/huiyuanyuan
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable huiyuanyuan
```

#### 3.4.2 Nginx配置
```bash
# 复制Nginx配置文件
cp /srv/huiyuanyuan/nginx_production.conf /etc/nginx/sites-available/huiyuanyuan

# 修改server_name为新服务器IP
sed -i 's/server_name 47.112.98.191;/server_name NEW_SERVER_IP;/' /etc/nginx/sites-available/huiyuanyuan

# 启用站点
ln -s /etc/nginx/sites-available/huiyuanyuan /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 测试并重启Nginx
nginx -t && systemctl restart nginx
```

#### 3.4.3 防火墙配置
```bash
# 配置UFW防火墙
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable
```

### 3.5 阶段五：安全加固 (Day 5)

#### 3.5.1 运行安全加固脚本
```bash
# 复制安全加固脚本
scp /srv/huiyuanyuan/scripts/security_harden.sh root@NEW_SERVER_IP:/opt/huiyuanyuan/

# 执行安全加固
bash /opt/huiyuanyuan/security_harden.sh
```

#### 3.5.2 技术债务修复
1. **main.py模块化拆分**：
   - 将2246行的main.py拆分为模块化结构
   - 创建routers/、models/、services/等目录
   - 保持向后兼容性

2. **内存存储迁移**：
   - 将所有内存存储迁移到PostgreSQL
   - 实现数据持久化
   - 添加数据备份机制

3. **安全配置修复**：
   - 修复CORS配置，限制允许的源
   - 移除硬编码密钥
   - 实现环境变量管理

### 3.6 阶段六：验证和切换 (Day 6)

#### 3.6.1 功能验证
```bash
# 1. 后端健康检查
curl http://NEW_SERVER_IP/api/health

# 2. 数据库连接验证
psql -U huyy_user -d huiyuanyuan -c "SELECT COUNT(*) FROM users;"

# 3. Redis连接验证
redis-cli -a NEW_REDIS_PASSWORD ping

# 4. 前端访问验证
curl -I http://NEW_SERVER_IP/
```

#### 3.6.2 性能测试
```bash
# 使用ab进行压力测试
ab -n 1000 -c 10 http://NEW_SERVER_IP/api/products
```

#### 3.6.3 DNS切换
1. 更新DNS记录，指向新服务器IP
2. 设置TTL为300秒，便于快速回滚
3. 监控DNS传播状态

---

## 四、回滚计划

### 4.1 回滚触发条件
1. 新服务器服务不可用超过5分钟
2. 数据库连接失败
3. 关键功能异常
4. 性能严重下降

### 4.2 回滚步骤
1. **立即回滚DNS**：将DNS记录改回旧服务器IP
2. **恢复旧服务器服务**：
   ```bash
   systemctl start huiyuanyuan
   systemctl start postgresql
   systemctl start redis-server
   ```
3. **数据同步**：将新服务器产生的数据同步回旧服务器
4. **问题排查**：分析新服务器问题原因

### 4.3 回滚时间目标
- **RTO (恢复时间目标)**：15分钟
- **RPO (恢复点目标)**：1小时

---

## 五、文档更新计划

### 5.1 需要更新的文档
1. **deployment_guide.md**：更新服务器IP和部署步骤
2. **production_checklist.md**：更新服务器配置信息
3. **server_migration_plan.md**：本迁移计划文档
4. **README.md**：更新项目状态和服务器信息

### 5.2 文档更新内容
1. 新服务器IP地址
2. 新的数据库连接信息
3. 新的Redis连接信息
4. 更新的部署脚本
5. 新的安全配置说明

---

## 六、后续工作清单

### 6.1 UI视觉升级 (优先级：高)
1. **设计系统落地**：实现Liquid Glass设计系统
2. **视觉优化**：添加毛玻璃效果、渐变设计、微动效
3. **用户体验**：优化页面转场、加载状态、交互反馈
4. **暗黑模式**：实现完整的暗黑模式支持

### 6.2 测试覆盖扩展 (优先级：高)
1. **后端测试**：扩展pytest测试用例，覆盖率提升至80%
2. **前端测试**：增加Widget测试和集成测试
3. **性能测试**：建立性能基准和监控
4. **安全测试**：定期安全扫描和渗透测试

### 6.3 AI集成更新 (并行处理中)
1. **移除冗余AI服务**：移除deepseek、千问和gemini的冗余集成
2. **集成OpenRouter**：集成OpenRouter的免费模型API
3. **图片识别功能**：确保新AI服务具备图片识别功能
4. **功能验证**：验证新AI集成的功能完整性和性能表现

---

## 七、风险控制

### 7.1 技术风险
| 风险 | 影响 | 应对措施 |
|------|------|---------|
| 数据迁移失败 | 数据丢失 | 多重备份、验证脚本 |
| 服务配置错误 | 服务不可用 | 配置模板、测试验证 |
| 性能下降 | 用户体验差 | 性能测试、监控告警 |
| 安全漏洞 | 数据泄露 | 安全加固、定期审计 |

### 7.2 业务风险
| 风险 | 影响 | 应对措施 |
|------|------|---------|
| 服务中断 | 业务损失 | 蓝绿部署、快速回滚 |
| 数据不一致 | 业务错误 | 数据验证、事务处理 |
| 用户投诉 | 品牌影响 | 提前通知、客服准备 |

### 7.3 时间风险
| 风险 | 影响 | 应对措施 |
|------|------|---------|
| 迁移延期 | 计划打乱 | 预留缓冲时间、并行处理 |
| 问题排查耗时 | 迁移时间延长 | 详细日志、监控工具 |

---

## 八、成功标准

### 8.1 技术指标
1. **服务可用性**：99.9%以上
2. **响应时间**：API响应时间<200ms
3. **错误率**：<0.1%
4. **数据一致性**：100%数据完整迁移

### 8.2 业务指标
1. **用户无感知**：迁移过程用户无感知
2. **功能完整**：所有功能正常工作
3. **性能提升**：响应时间提升20%以上
4. **安全增强**：通过安全审计

---

## 九、时间安排

| 阶段 | 时间 | 主要任务 |
|------|------|---------|
| 准备工作 | Day 1 | 服务器采购、数据备份、脚本准备 |
| 环境配置 | Day 2 | 系统安装、数据库配置、Python环境 |
| 应用迁移 | Day 3 | 后端迁移、数据迁移、前端迁移 |
| 服务配置 | Day 4 | systemd、Nginx、防火墙配置 |
| 安全加固 | Day 5 | 安全脚本、技术债务修复 |
| 验证切换 | Day 6 | 功能验证、性能测试、DNS切换 |

---

## 十、团队分工

### 10.1 Agent A - 后端架构师
- 负责后端应用迁移
- 数据库迁移和优化
- 技术债务修复

### 10.2 Agent B - 前端质量工程师
- 负责前端应用迁移
- UI视觉升级
- 测试覆盖扩展

### 10.3 Agent C - 测试与安全专家
- 负责安全加固
- 功能验证测试
- 性能测试

### 10.4 Agent D - DevOps运维
- 负责服务器环境配置
- 服务部署和监控
- 运维文档更新

---

*计划制定时间: 2026-03-17*
*计划版本: v1.0*
*下次更新: 迁移完成后*