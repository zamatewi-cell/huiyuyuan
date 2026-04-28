#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy the current project to the production ECS server.
.DESCRIPTION
    Syncs the backend source into /srv/huiyuyuan/backend, uploads the Flutter
    web build, applies Alembic migrations, reloads Nginx, and verifies the
    backend health endpoint.
.PARAMETER Target
    all | web | backend | nginx | db-init
.PARAMETER SkipAnalyze
    Skip dart analyze for faster web deployments.
.PARAMETER SkipBuild
    Skip flutter build web and reuse the existing build/web output.
.PARAMETER DryRun
    Print commands without executing SSH/SCP actions.
.PARAMETER Rollback
    Restore a previously created backend snapshot timestamp.
#>

param(
    [ValidateSet("all", "web", "backend", "nginx", "db-init", "apk")]
    [string]$Target = "all",
    [switch]$SkipAnalyze,
    [switch]$SkipBuild,
    [switch]$DryRun,
    [string]$Rollback = ""
)

$ErrorActionPreference = "Stop"

$SERVER_HOST = "47.112.98.191"
$SERVER_USER = "root"
$PRIMARY_DOMAIN = "xn--lsws2cdzg.top"
$APP_DIR = "huiyuyuan_app"
$BACKEND_LOCAL = "huiyuyuan_app\backend"
$BACKEND_REMOTE = "/srv/huiyuyuan/backend"
$WEB_LOCAL = "huiyuyuan_app\build\web"
$WEB_REMOTE = "/var/www/huiyuyuan"
$SERVICE_NAME = "huiyuyuan-backend"
$SYSTEMD_REMOTE_UNIT = "/etc/systemd/system/${SERVICE_NAME}.service"
$NGINX_REMOTE_CONF = "/etc/nginx/conf.d/huiyuyuan.conf"
$NGINX_SNIPPET_REMOTE = "/etc/nginx/snippets/proxy_params.conf"
$HEALTH_URL = "http://127.0.0.1:8000/api/health"
$SNAPSHOT_DIR = "/opt/huiyuyuan/snapshots"
$MAX_SNAPSHOTS = 3
$MAX_RETRIES = 5
$RETRY_DELAY = 3
$PUBLIC_SITE_URL = "https://$PRIMARY_DOMAIN"
$PUBLIC_HEALTH_URL = "$PUBLIC_SITE_URL/api/health"

$BACKEND_SYNC_ITEMS = @(
    ".env.example",
    "alembic.ini",
    "config.py",
    "data",
    "database.py",
    "deploy_current_server.sh",
    "huiyuyuan-backend.service",
    "init_db.sql",
    "logging_config.py",
    "main.py",
    "migrations",
    "nginx_current.conf",
    "nginx_production.conf",
    "nginx_proxy_params.conf",
    "pyproject.toml",
    "requirements.txt",
    "routers",
    "schemas",
    "scripts",
    "security.py",
    "services",
    "store.py",
    "tests"
)

$SNAPSHOT_ITEMS = @(
    "alembic.ini",
    "config.py",
    "data",
    "database.py",
    "deploy_current_server.sh",
    "huiyuyuan-backend.service",
    "init_db.sql",
    "logging_config.py",
    "main.py",
    "migrations",
    "nginx_current.conf",
    "nginx_production.conf",
    "nginx_proxy_params.conf",
    "pyproject.toml",
    "requirements.txt",
    "routers",
    "schemas",
    "scripts",
    "security.py",
    "services",
    "store.py",
    "tests"
)

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "  [INFO] $Message" -ForegroundColor Gray
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  [OK]   $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
}

function Invoke-SSH {
    param([string]$Command)

    # Multiline here-strings are authored on Windows; strip CR so remote bash
    # never receives `$'\r'` as a command.
    $Command = $Command -replace "`r`n", "`n" -replace "`r", ""

    if ($DryRun) {
        Write-Info "[DRY RUN] ssh ${SERVER_USER}@${SERVER_HOST} `"$Command`""
        return "DRY_RUN_OK"
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $result = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_HOST}" $Command 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        throw "SSH command failed (exit $exitCode): $Command`n$result"
    }
    return ($result | Out-String).Trim()
}

function Invoke-SCP {
    param(
        [string]$Source,
        [string]$Dest
    )

    if ($DryRun) {
        Write-Info "[DRY RUN] scp $Source -> ${SERVER_USER}@${SERVER_HOST}:$Dest"
        return
    }

    scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -r $Source "${SERVER_USER}@${SERVER_HOST}:$Dest" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "SCP upload failed: $Source -> $Dest"
    }
}

function Ensure-ProjectRoot {
    $projectRoot = $PSScriptRoot | Split-Path -Parent
    if (Test-Path (Join-Path $projectRoot "huiyuyuan_app\pubspec.yaml")) {
        return $projectRoot
    }
    if (Test-Path "huiyuyuan_app\pubspec.yaml") {
        return (Get-Location).Path
    }
    throw "Run this script from the repository root."
}

function New-RemoteSnapshot {
    param([string]$Timestamp)

    $snapshotList = $SNAPSHOT_ITEMS -join " "
    $snapshotCommand = @"
bash -lc 'mkdir -p ${SNAPSHOT_DIR}/${Timestamp};
cd ${BACKEND_REMOTE};
for item in ${snapshotList}; do
  if [ -e "`$item" ]; then
    cp -a "`$item" ${SNAPSHOT_DIR}/${Timestamp}/;
  fi;
done;
ls -dt ${SNAPSHOT_DIR}/* 2>/dev/null | tail -n +$($MAX_SNAPSHOTS + 1) | xargs -r rm -rf;
echo SNAP_OK'
"@
    Invoke-SSH $snapshotCommand | Out-Null
}

function Test-BackendHealth {
    if ($DryRun) {
        Write-Info "[DRY RUN] skip backend health verification"
        return
    }

    for ($attempt = 1; $attempt -le $MAX_RETRIES; $attempt++) {
        $status = Invoke-SSH "curl -s -o /dev/null -w '%{http_code}' ${HEALTH_URL} 2>/dev/null || echo 000"
        if ($status -match "200") {
            Write-Ok "backend health check passed on attempt $attempt/$MAX_RETRIES"
            return
        }
        Write-Warn "backend not ready yet ($attempt/$MAX_RETRIES)"
        Start-Sleep -Seconds $RETRY_DELAY
    }

    throw "backend health check did not return HTTP 200"
}

$startTime = Get-Date
$projectRoot = Ensure-ProjectRoot
Push-Location $projectRoot

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  HuiYuYuan deploy started" -ForegroundColor Magenta
Write-Host "  Target: $Target | Analyze: $(-not $SkipAnalyze) | Build: $(-not $SkipBuild)" -ForegroundColor Magenta
if ($DryRun) {
    Write-Host "  DRY RUN mode" -ForegroundColor Yellow
}
Write-Host "=============================================" -ForegroundColor Magenta

try {
    Write-Step "Checking SSH connectivity"
    $sshResult = Invoke-SSH "echo CONNECTED"
    if ($sshResult -notmatch "CONNECTED" -and -not $DryRun) {
        throw "unable to connect to ${SERVER_HOST}"
    }
    Write-Ok "server ${SERVER_HOST} is reachable"

    if (-not $SkipAnalyze -and ($Target -eq "all" -or $Target -eq "web")) {
        Write-Step "Running dart analyze"
        Push-Location $APP_DIR
        $analyzeOutput = dart analyze lib/ 2>&1 | Out-String
        Pop-Location

        $errorCount = ([regex]::Matches($analyzeOutput, " error ")).Count
        if ($errorCount -gt 0) {
            Write-Fail "dart analyze reported $errorCount errors"
            Write-Host $analyzeOutput -ForegroundColor Red
            exit 1
        }
        Write-Ok "dart analyze passed"
    }

    if (-not $SkipBuild -and ($Target -eq "all" -or $Target -eq "web")) {
        Write-Step "Building Flutter Web"
        Push-Location $APP_DIR
        $buildOutput = flutter build web --no-tree-shake-icons --release 2>&1 | Out-String
        Pop-Location

        if ($buildOutput -notmatch "Built build\\web" -and $buildOutput -notmatch "Built build/web") {
            Write-Fail "flutter build web failed"
            Write-Host $buildOutput -ForegroundColor Red
            exit 1
        }
        Write-Ok "Flutter Web build completed"
    }

    if ($Target -eq "all" -or $Target -eq "backend") {
        if ($Rollback) {
            Write-Step "Rolling back backend snapshot $Rollback"
            $rollbackCommand = @"
bash -lc 'if [ -d ${SNAPSHOT_DIR}/${Rollback} ]; then
  cp -a ${SNAPSHOT_DIR}/${Rollback}/* ${BACKEND_REMOTE}/ 2>/dev/null;
  if [ -f "${BACKEND_REMOTE}/${SERVICE_NAME}.service" ]; then
    cp "${BACKEND_REMOTE}/${SERVICE_NAME}.service" "${SYSTEMD_REMOTE_UNIT}";
    systemctl daemon-reload;
  fi;
  systemctl restart ${SERVICE_NAME};
  echo ROLLBACK_OK;
else
  echo SNAPSHOT_NOT_FOUND;
fi'
"@
            $rollbackResult = Invoke-SSH $rollbackCommand
            if ($rollbackResult -notmatch "ROLLBACK_OK" -and -not $DryRun) {
                throw "snapshot ${Rollback} was not found"
            }
            Write-Ok "rollback completed"
        } else {
            $snapshotTs = Get-Date -Format "yyyyMMdd_HHmmss"
            Write-Step "Creating backend snapshot $snapshotTs"
            New-RemoteSnapshot -Timestamp $snapshotTs
            Write-Ok "snapshot created"

            Write-Step "Uploading backend source"
            foreach ($item in $BACKEND_SYNC_ITEMS) {
                $localPath = Join-Path $BACKEND_LOCAL $item
                if (-not (Test-Path $localPath)) {
                    continue
                }

                $entry = Get-Item $localPath
                if ($entry.PSIsContainer) {
                    Invoke-SSH "mkdir -p ${BACKEND_REMOTE}/${item}"
                    Invoke-SCP -Source "$localPath\*" -Dest "${BACKEND_REMOTE}/${item}/"
                } else {
                    Invoke-SCP -Source $localPath -Dest "${BACKEND_REMOTE}/${item}"
                }
                Write-Info "$item -> ${BACKEND_REMOTE}/${item}"
            }

            Write-Step "Installing backend dependencies and applying Alembic"
            $backendDeployCommand = @"
bash -lc 'cd ${BACKEND_REMOTE};
source venv/bin/activate;
pip install -r requirements.txt -q 2>/dev/null;
alembic upgrade head;
if [ -f "${BACKEND_REMOTE}/${SERVICE_NAME}.service" ]; then
  cp "${BACKEND_REMOTE}/${SERVICE_NAME}.service" "${SYSTEMD_REMOTE_UNIT}";
  systemctl daemon-reload;
fi;
systemctl restart ${SERVICE_NAME}'
"@
            Invoke-SSH $backendDeployCommand | Out-Null
            Write-Ok "backend restarted"
        }

        Write-Step "Verifying backend health"
        try {
            Test-BackendHealth
        } catch {
            if (-not $DryRun -and $snapshotTs) {
                Write-Warn "health check failed, restoring snapshot $snapshotTs"
                $restoreCommand = @"
bash -lc 'cp -a ${SNAPSHOT_DIR}/${snapshotTs}/* ${BACKEND_REMOTE}/ 2>/dev/null;
if [ -f "${BACKEND_REMOTE}/${SERVICE_NAME}.service" ]; then
  cp "${BACKEND_REMOTE}/${SERVICE_NAME}.service" "${SYSTEMD_REMOTE_UNIT}";
  systemctl daemon-reload;
fi;
systemctl restart ${SERVICE_NAME}'
"@
                Invoke-SSH $restoreCommand | Out-Null
            }
            throw
        }
    }

    if ($Target -eq "all" -or $Target -eq "nginx") {
        Write-Step "Uploading Nginx configuration"

        $nginxCurrent = Join-Path $BACKEND_LOCAL "nginx_current.conf"
        $nginxSnippet = Join-Path $BACKEND_LOCAL "nginx_proxy_params.conf"

        Invoke-SSH "mkdir -p /etc/nginx/snippets"
        Invoke-SCP -Source $nginxCurrent -Dest $NGINX_REMOTE_CONF
        Invoke-SCP -Source $nginxSnippet -Dest $NGINX_SNIPPET_REMOTE

        # Remove potential UTF-8 BOM that breaks nginx
        Invoke-SSH "sed -i '1s/^\xEF\xBB\xBF//' $NGINX_REMOTE_CONF 2>/dev/null || true"

        $nginxTest = Invoke-SSH "nginx -t 2>&1"
        if ($nginxTest -notmatch "successful" -and -not $DryRun) {
            throw "nginx -t failed: $nginxTest"
        }

        Invoke-SSH "systemctl reload nginx" | Out-Null
        Write-Ok "Nginx reloaded"
    }

    if ($Target -eq "db-init") {
        Write-Step "Initializing database bootstrap SQL"
        $initSql = Join-Path $BACKEND_LOCAL "init_db.sql"
        Invoke-SCP -Source $initSql -Dest "${BACKEND_REMOTE}/init_db.sql"
        Invoke-SSH "sudo -u postgres psql -d huiyuyuan -f ${BACKEND_REMOTE}/init_db.sql" | Out-Null
        Invoke-SSH "bash -lc 'cd ${BACKEND_REMOTE}; source venv/bin/activate; alembic upgrade head'" | Out-Null
        Write-Ok "database bootstrap and migrations completed"
    }

    if ($Target -eq "all" -or $Target -eq "web") {
        Write-Step "Uploading Flutter Web build"
        if (-not (Test-Path $WEB_LOCAL) -and -not $DryRun) {
            throw "missing web build output at ${WEB_LOCAL}"
        }

        Invoke-SCP -Source "$WEB_LOCAL\*" -Dest "${WEB_REMOTE}/"

        # 上传独立下载页面（不在 Flutter 构建产物中）
        $DOWNLOAD_PAGE = Join-Path $PSScriptRoot "..\huiyuyuan_app\web\download.html" | Resolve-Path
        if (Test-Path $DOWNLOAD_PAGE) {
            Invoke-SCP -Source $DOWNLOAD_PAGE -Dest "${WEB_REMOTE}/download.html"
            Write-Ok "download.html uploaded"
        }

        Write-Ok "web assets uploaded"

        Invoke-SSH "nginx -t 2>&1 && systemctl reload nginx" | Out-Null
        Write-Ok "Nginx reloaded after web deployment"
    }

    # ── APK 分发（仅在全量发布或指定 target=apk 时） ──
    if ($Target -eq "all" -or $Target -eq "apk") {
        $apkLocal = Join-Path $APP_DIR "build\app\outputs\flutter-apk\app-release.apk"
        if (Test-Path $apkLocal) {
            Write-Step "Distributing APK to server"
            Invoke-SSH "mkdir -p /var/www/huiyuyuan/downloads"
            Invoke-SCP -Source $apkLocal -Dest "/var/www/huiyuyuan/downloads/huiyuyuan-latest.apk"
            $apkSize = [math]::Round((Get-Item $apkLocal).Length / 1MB, 1)
            $apkHash = (Get-FileHash -Path $apkLocal -Algorithm SHA256).Hash.ToLowerInvariant()
            $remoteApkSize = Invoke-SSH "stat -c %s /var/www/huiyuyuan/downloads/huiyuyuan-latest.apk 2>/dev/null || echo 0"
            Write-Ok "APK distributed (${apkSize}MB) → /downloads/huiyuyuan-latest.apk"
            Write-Info "APK SHA256: ${apkHash}"
            Write-Info "Remote APK size: ${remoteApkSize} bytes"
        } else {
            Write-Host "  [skip] no release APK found at ${apkLocal}" -ForegroundColor Yellow
            Write-Host "  Hint: run 'flutter build apk --release' first" -ForegroundColor Gray
        }
    }

    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  Deploy completed in ${elapsed}s" -ForegroundColor Green
    Write-Host "  Site:   ${PUBLIC_SITE_URL}/" -ForegroundColor Green
    Write-Host "  Health: ${PUBLIC_HEALTH_URL}" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} catch {
    Write-Fail "$_"
    exit 1
} finally {
    Pop-Location -ErrorAction SilentlyContinue
}
