<#
.SYNOPSIS
    汇玉源服务器迁移脚本 (Windows PowerShell)
.DESCRIPTION
    自动化执行服务器迁移任务，包括数据备份、文件传输、环境配置等
.PARAMETER OldServerIP
    旧服务器IP地址
.PARAMETER NewServerIP
    新服务器IP地址
.PARAMETER SSHKeyPath
    SSH私钥路径
.PARAMETER SkipBackup
    跳过备份步骤
.PARAMETER DryRun
    模拟运行，不实际执行
.EXAMPLE
    .\migrate_server.ps1 -OldServerIP "47.98.188.141" -NewServerIP "NEW_IP" -SSHKeyPath "~/.ssh/id_rsa"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OldServerIP,
    
    [Parameter(Mandatory=$true)]
    [string]$NewServerIP,
    
    [string]$SSHKeyPath = "$env:USERPROFILE\.ssh\id_rsa",
    
    [switch]$SkipBackup,
    
    [switch]$DryRun
)

# 颜色输出函数
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info($message) {
    Write-ColorOutput Green "[INFO] $message"
}

function Write-Warn($message) {
    Write-ColorOutput Yellow "[WARN] $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

function Write-Step($step, $message) {
    Write-ColorOutput Cyan "`n=== 步骤 $step: $message ==="
}

# 检查SSH连接
function Test-SSHConnection($serverIP) {
    Write-Info "测试SSH连接到 $serverIP..."
    if ($DryRun) {
        Write-Warn "[模拟] 测试SSH连接"
        return $true
    }
    
    try {
        $result = ssh -i $SSHKeyPath -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$serverIP "echo 'SSH连接成功'" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Info "SSH连接成功"
            return $true
        } else {
            Write-Error "SSH连接失败: $result"
            return $false
        }
    } catch {
        Write-Error "SSH连接异常: $_"
        return $false
    }
}

# 执行远程命令
function Invoke-RemoteCommand($serverIP, $command) {
    if ($DryRun) {
        Write-Warn "[模拟] 在 $serverIP 执行: $command"
        return $true
    }
    
    try {
        $result = ssh -i $SSHKeyPath -o StrictHostKeyChecking=no root@$serverIP $command 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        } else {
            Write-Error "命令执行失败: $result"
            return $false
        }
    } catch {
        Write-Error "命令执行异常: $_"
        return $false
    }
}

# 传输文件
function Copy-FileToServer($serverIP, $localPath, $remotePath) {
    if ($DryRun) {
        Write-Warn "[模拟] 传输文件 $localPath 到 $serverIP:$remotePath"
        return $true
    }
    
    try {
        scp -i $SSHKeyPath -o StrictHostKeyChecking=no -r $localPath root@${serverIP}:${remotePath} 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Info "文件传输成功: $localPath -> $remotePath"
            return $true
        } else {
            Write-Error "文件传输失败"
            return $false
        }
    } catch {
        Write-Error "文件传输异常: $_"
        return $false
    }
}

# 主迁移流程
Write-ColorOutput Magenta "╔══════════════════════════════════════════════════════════════╗"
Write-ColorOutput Magenta "║           汇玉源服务器迁移工具 v1.0                          ║"
Write-ColorOutput Magenta "╚══════════════════════════════════════════════════════════════╝"
Write-Info "旧服务器: $OldServerIP"
Write-Info "新服务器: $NewServerIP"
Write-Info "SSH密钥: $SSHKeyPath"

if ($DryRun) {
    Write-Warn "模拟运行模式 - 不会实际执行操作"
}

# 步骤1: 测试连接
Write-Step 1 "测试服务器连接"
if (-not (Test-SSHConnection $OldServerIP)) {
    Write-Error "无法连接到旧服务器，迁移终止"
    exit 1
}

if (-not (Test-SSHConnection $NewServerIP)) {
    Write-Error "无法连接到新服务器，迁移终止"
    exit 1
}

# 步骤2: 备份数据
if (-not $SkipBackup) {
    Write-Step 2 "备份旧服务器数据"
    
    $backupDate = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "/opt/huiyuanyuan/backups/migration_$backupDate"
    
    # 创建备份目录
    Invoke-RemoteCommand $OldServerIP "mkdir -p $backupDir"
    
    # 备份数据库
    Write-Info "备份PostgreSQL数据库..."
    Invoke-RemoteCommand $OldServerIP "sudo -u postgres pg_dump huiyuanyuan > $backupDir/db_backup.sql"
    
    # 备份应用文件
    Write-Info "备份应用文件..."
    Invoke-RemoteCommand $OldServerIP "tar -czf $backupDir/app_backup.tar.gz /srv/huiyuanyuan/"
    
    # 备份前端文件
    Write-Info "备份前端文件..."
    Invoke-RemoteCommand $OldServerIP "tar -czf $backupDir/web_backup.tar.gz /var/www/huiyuanyuan/"
    
    # 备份配置文件
    Write-Info "备份配置文件..."
    Invoke-RemoteCommand $OldServerIP "cp /etc/nginx/sites-enabled/huiyuanyuan $backupDir/nginx_backup.conf"
    Invoke-RemoteCommand $OldServerIP "cp /etc/systemd/system/huiyuanyuan.service $backupDir/systemd_backup.service"
    
    Write-Info "备份完成: $backupDir"
} else {
    Write-Warn "跳过备份步骤"
}

# 步骤3: 准备新服务器环境
Write-Step 3 "准备新服务器环境"

# 传输服务器初始化脚本
Write-Info "传输服务器初始化脚本..."
$serverSetupScript = "d:\huiyuanyuan_project\huiyuanyuan_app\backend\server_setup.sh"
Copy-FileToServer $NewServerIP $serverSetupScript "/tmp/server_setup.sh"

# 执行服务器初始化
Write-Info "执行服务器初始化..."
Invoke-RemoteCommand $NewServerIP "chmod +x /tmp/server_setup.sh && /tmp/server_setup.sh"

# 步骤4: 传输应用文件
Write-Step 4 "传输应用文件"

# 传输后端应用
Write-Info "传输后端应用文件..."
$backendPath = "d:\huiyuanyuan_project\huiyuanyuan_app\backend"
Copy-FileToServer $NewServerIP $backendPath "/srv/huiyuanyuan/"

# 传输前端构建文件
Write-Info "传输前端构建文件..."
$webBuildPath = "d:\huiyuanyuan_project\huiyuanyuan_app\build\web"
if (Test-Path $webBuildPath) {
    Copy-FileToServer $NewServerIP $webBuildPath "/var/www/huiyuanyuan/"
} else {
    Write-Warn "前端构建文件不存在，需要先构建"
}

# 步骤5: 配置新服务器
Write-Step 5 "配置新服务器"

# 生成新的环境变量
Write-Info "生成新的环境变量..."
$newEnvContent = @"
# 汇玉源 v4.0 生产环境配置
# 生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# 数据库配置
DATABASE_URL=postgresql://huyy_user:NEW_STRONG_PASSWORD@localhost:5432/huiyuanyuan

# Redis配置
REDIS_URL=redis://:NEW_REDIS_PASSWORD@localhost:6379/0

# JWT配置
JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
JWT_ALGORITHM=HS256
JWT_ACCESS_EXPIRE_MINUTES=120
JWT_REFRESH_EXPIRE_DAYS=7

# 应用配置
APP_ENV=production
DEBUG=false
ALLOWED_ORIGINS=http://$NewServerIP
LOG_LEVEL=INFO
"@

# 传输环境变量文件
$envFile = [System.IO.Path]::GetTempFileName()
$newEnvContent | Out-File -FilePath $envFile -Encoding UTF8
Copy-FileToServer $NewServerIP $envFile "/srv/huiyuanyuan/.env"
Remove-Item $envFile

# 设置文件权限
Invoke-RemoteCommand $NewServerIP "chmod 600 /srv/huiyuanyuan/.env"

# 步骤6: 数据库迁移
Write-Step 6 "数据库迁移"

# 传输数据库备份
Write-Info "传输数据库备份..."
$dbBackupPath = "/opt/huiyuanyuan/backups/migration_$backupDate/db_backup.sql"
Copy-FileToServer $NewServerIP $dbBackupPath "/tmp/db_backup.sql"

# 恢复数据库
Write-Info "恢复数据库..."
Invoke-RemoteCommand $NewServerIP "sudo -u postgres psql -d huiyuanyuan -f /tmp/db_backup.sql"

# 运行数据库迁移
Write-Info "运行数据库迁移..."
Invoke-RemoteCommand $NewServerIP "cd /srv/huiyuanyuan && source venv/bin/activate && alembic upgrade head"

# 步骤7: 配置系统服务
Write-Step 7 "配置系统服务"

# 配置systemd服务
Write-Info "配置systemd服务..."
$systemdService = @"
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

ExecReload=/bin/kill -s HUP `$MAINPID
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
"@

$serviceFile = [System.IO.Path]::GetTempFileName()
$systemdService | Out-File -FilePath $serviceFile -Encoding UTF8
Copy-FileToServer $NewServerIP $serviceFile "/etc/systemd/system/huiyuanyuan.service"
Remove-Item $serviceFile

# 配置Nginx
Write-Info "配置Nginx..."
$nginxConfig = "d:\huiyuanyuan_project\huiyuanyuan_app\backend\nginx_production.conf"
Copy-FileToServer $NewServerIP $nginxConfig "/etc/nginx/sites-available/huiyuanyuan"

# 修改Nginx配置中的server_name
Invoke-RemoteCommand $NewServerIP "sed -i 's/server_name 47.98.188.141;/server_name $NewServerIP;/' /etc/nginx/sites-available/huiyuanyuan"

# 启用Nginx站点
Invoke-RemoteCommand $NewServerIP "ln -sf /etc/nginx/sites-available/huiyuanyuan /etc/nginx/sites-enabled/"
Invoke-RemoteCommand $NewServerIP "rm -f /etc/nginx/sites-enabled/default"

# 步骤8: 启动服务
Write-Step 8 "启动服务"

# 重新加载systemd
Invoke-RemoteCommand $NewServerIP "systemctl daemon-reload"
Invoke-RemoteCommand $NewServerIP "systemctl enable huiyuanyuan"

# 启动服务
Write-Info "启动汇玉源服务..."
Invoke-RemoteCommand $NewServerIP "systemctl start huiyuanyuan"

# 测试Nginx配置
Write-Info "测试Nginx配置..."
Invoke-RemoteCommand $NewServerIP "nginx -t && systemctl restart nginx"

# 步骤9: 验证服务
Write-Step 9 "验证服务"

# 等待服务启动
Write-Info "等待服务启动..."
Start-Sleep -Seconds 10

# 测试后端健康检查
Write-Info "测试后端健康检查..."
if ($DryRun) {
    Write-Warn "[模拟] 测试后端健康检查"
} else {
    try {
        $healthCheck = Invoke-RestMethod -Uri "http://$NewServerIP/api/health" -TimeoutSec 30
        Write-Info "后端健康检查成功: $($healthCheck.status)"
    } catch {
        Write-Error "后端健康检查失败: $_"
    }
}

# 测试前端访问
Write-Info "测试前端访问..."
if ($DryRun) {
    Write-Warn "[模拟] 测试前端访问"
} else {
    try {
        $frontendResponse = Invoke-WebRequest -Uri "http://$NewServerIP/" -TimeoutSec 30
        if ($frontendResponse.StatusCode -eq 200) {
            Write-Info "前端访问成功"
        } else {
            Write-Warn "前端访问返回状态码: $($frontendResponse.StatusCode)"
        }
    } catch {
        Write-Error "前端访问失败: $_"
    }
}

# 步骤10: 安全加固
Write-Step 10 "安全加固"

# 传输安全加固脚本
Write-Info "传输安全加固脚本..."
$securityScript = "d:\huiyuanyuan_project\huiyuanyuan_app\backend\scripts\security_harden.sh"
Copy-FileToServer $NewServerIP $securityScript "/opt/huiyuanyuan/security_harden.sh"

# 执行安全加固
Write-Info "执行安全加固..."
Invoke-RemoteCommand $NewServerIP "chmod +x /opt/huiyuanyuan/security_harden.sh && /opt/huiyuanyuan/security_harden.sh"

# 步骤11: 配置防火墙
Write-Step 11 "配置防火墙"

Write-Info "配置UFW防火墙..."
Invoke-RemoteCommand $NewServerIP "ufw allow 22/tcp"
Invoke-RemoteCommand $NewServerIP "ufw allow 80/tcp"
Invoke-RemoteCommand $NewServerIP "ufw allow 443/tcp"
Invoke-RemoteCommand $NewServerIP "ufw --force enable"

# 完成
Write-ColorOutput Green "`n╔══════════════════════════════════════════════════════════════╗"
Write-ColorOutput Green "║           服务器迁移完成！                                   ║"
Write-ColorOutput Green "╚══════════════════════════════════════════════════════════════╝"

Write-Info "新服务器IP: $NewServerIP"
Write-Info "后端API: http://$NewServerIP/api/health"
Write-Info "前端页面: http://$NewServerIP/"
Write-Info "数据库: PostgreSQL 15"
Write-Info "缓存: Redis"

Write-Warn "`n后续步骤:"
Write-Warn "1. 更新DNS记录指向新服务器IP"
Write-Warn "2. 配置SSL证书 (可选)"
Write-Warn "3. 更新相关文档"
Write-Warn "4. 监控服务运行状态"

if ($DryRun) {
    Write-Warn "`n注意: 这是模拟运行，未实际执行操作"
}