#!/usr/bin/env pwsh
<#
.SYNOPSIS
    ����Դ v4.0 �� һ������ & ����ű�
.DESCRIPTION
    �Զ���ɣ���̬���� �� Web ���� �� ���ͬ��(��Ŀ¼) �� Nginx���� �� �������� �� �������
    ֧��ѡ���Բ��𣨽�ǰ�� / ����� / ȫ����
    v4.0 ����: �����Ŀ¼ rsync | Nginx ��������ͬ�� | ���ݿ�Ǩ�� | �汾���ջع�
.PARAMETER Target
    ����Ŀ��: all | web | backend | nginx | db-init
.PARAMETER SkipAnalyze
    ���� dart analyze ���裨���ٲ���
.PARAMETER SkipBuild
    ���� flutter build��ʹ���ϴι�������ֱ�Ӳ���
.PARAMETER DryRun
    ��ģ��ִ�У���ʵ�ʲ���
.PARAMETER Rollback
    �ع���˵�ָ���汾 (ʱ���)
.EXAMPLE
    .\scripts\deploy.ps1                        # ȫ������
    .\scripts\deploy.ps1 -Target web            # ������ǰ��
    .\scripts\deploy.ps1 -Target backend        # ��������
    .\scripts\deploy.ps1 -Target nginx          # ������ Nginx ����
    .\scripts\deploy.ps1 -Target db-init        # ��ʼ��/�������ݿ��
    .\scripts\deploy.ps1 -SkipAnalyze           # �������������ٲ���
    .\scripts\deploy.ps1 -DryRun                # ģ������
    .\scripts\deploy.ps1 -Target backend -Rollback 20260227_153000  # �ع�
#>

param(
    [ValidateSet("all", "web", "backend", "nginx", "db-init")]
    [string]$Target = "all",

    [switch]$SkipAnalyze,
    [switch]$SkipBuild,
    [switch]$DryRun,

    [string]$Rollback = ""
)

# �T�T�T�T�T�T�T�T�T�T�T�T�T�T�T ���� �T�T�T�T�T�T�T�T�T�T�T�T�T�T�T
$ErrorActionPreference = "Stop"

$SERVER_HOST    = "47.112.98.191"
$SERVER_USER    = "root"
$BACKEND_LOCAL  = "huiyuanyuan_app\backend"
$BACKEND_REMOTE = "/srv/huiyuanyuan"
$WEB_LOCAL      = "huiyuanyuan_app\build\web"
$WEB_REMOTE     = "/var/www/huiyuanyuan"
$APP_DIR        = "huiyuanyuan_app"
$HEALTH_URL     = "http://127.0.0.1:8000/api/health"
$MAX_RETRIES    = 5
$RETRY_DELAY    = 3
$SNAPSHOT_DIR   = "/opt/huiyuanyuan/snapshots"   # ����˰汾����Ŀ¼
$MAX_SNAPSHOTS  = 3                               # ����������

# �����ͬ�����ļ�/Ŀ¼ (v4.0: ��Ŀ¼�ṹ)
$BACKEND_SYNC_ITEMS = @(
    "main.py",
    "requirements.txt",
    "init_db.sql",
    "pyproject.toml",
    "config.py",
    "database.py",
    "security.py",
    "store.py",
    "logging_config.py",
    "alembic.ini",
    "migrations",
    "schemas",
    "data",
    "routers",
    "services",
    "tests",
    "scripts",
    "nginx_production.conf",
    "nginx_proxy_params.conf"
)

# �T�T�T�T�T�T�T�T�T�T�T�T�T�T�T ���ߺ��� �T�T�T�T�T�T�T�T�T�T�T�T�T�T�T
function Write-Step  { param([string]$msg) Write-Host "`n[$([char]0x2192)] $msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn  { param([string]$msg) Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Info  { param([string]$msg) Write-Host "  $msg" -ForegroundColor Gray }

function Get-Timestamp { return (Get-Date -Format "yyyy-MM-dd HH:mm:ss") }

# ����ʱ�� SSH ִ��
function Invoke-SSH {
    param([string]$Command)
    if ($DryRun) {
        Write-Info "[DRY RUN] ssh ${SERVER_USER}@${SERVER_HOST} `"$Command`""
        return "DRY_RUN_OK"
    }
    $result = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_HOST}" $Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "SSH command failed (exit $LASTEXITCODE): $Command`n$result"
    }
    return $result
}

# SCP �ϴ�
function Invoke-SCP {
    param([string]$Source, [string]$Dest)
    if ($DryRun) {
        Write-Info "[DRY RUN] scp $Source -> ${SERVER_USER}@${SERVER_HOST}:$Dest"
        return
    }
    scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no -r $Source "${SERVER_USER}@${SERVER_HOST}:$Dest" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "SCP upload failed: $Source -> $Dest"
    }
}

# �T�T�T�T�T�T�T�T�T�T�T�T�T�T�T ������ �T�T�T�T�T�T�T�T�T�T�T�T�T�T�T
$startTime = Get-Date
$projectRoot = $PSScriptRoot | Split-Path -Parent

# ȷ������Ŀ��Ŀ¼����
if (-not (Test-Path (Join-Path $projectRoot "huiyuanyuan_app\pubspec.yaml"))) {
    # ���Ե�ǰĿ¼
    if (Test-Path "huiyuanyuan_app\pubspec.yaml") {
        $projectRoot = Get-Location
    } else {
        Write-Fail "������Ŀ��Ŀ¼���д˽ű�"
        exit 1
    }
}

Push-Location $projectRoot

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  ����Դ - �Զ������� ($(Get-Timestamp))" -ForegroundColor Magenta
Write-Host "  Ŀ��: $Target | ����: $(-not $SkipAnalyze) | ����: $(-not $SkipBuild)" -ForegroundColor Magenta
if ($DryRun) { Write-Host "  *** DRY RUN ģʽ ***" -ForegroundColor Yellow }
Write-Host "=============================================" -ForegroundColor Magenta

try {
    # ������ Step 1: SSH ��ͨ�Լ�� ������
    Write-Step "����������ͨ��..."
    $sshResult = Invoke-SSH "echo CONNECTED"
    if ($sshResult -match "CONNECTED" -or $DryRun) {
        Write-Ok "������ $SERVER_HOST ��������"
    } else {
        throw "�޷����ӷ����� $SERVER_HOST"
    }

    # ������ Step 2: ��̬��������ѡ�� ������
    if (-not $SkipAnalyze -and ($Target -eq "all" -or $Target -eq "web")) {
        Write-Step "���о�̬���� (dart analyze)..."
        Push-Location $APP_DIR
        $analyzeOutput = dart analyze lib/ 2>&1 | Out-String
        Pop-Location

        $errorCount = ([regex]::Matches($analyzeOutput, " error ")).Count
        $warnCount  = ([regex]::Matches($analyzeOutput, " warning ")).Count

        if ($errorCount -gt 0) {
            Write-Fail "���� $errorCount ��������ֹ����"
            Write-Host $analyzeOutput -ForegroundColor Red
            exit 1
        }
        Write-Ok "����ͨ�� ($errorCount errors, $warnCount warnings)"
    }

    # ������ Step 3: Flutter Web ��������ѡ�� ������
    if (-not $SkipBuild -and ($Target -eq "all" -or $Target -eq "web")) {
        Write-Step "���� Flutter Web..."
        Push-Location $APP_DIR
        $buildOutput = flutter build web --no-tree-shake-icons --release 2>&1 | Out-String
        Pop-Location

        if ($buildOutput -match "Built build\\web" -or $buildOutput -match "Built build/web") {
            Write-Ok "Web �����ɹ�"
        } else {
            Write-Fail "Web ����ʧ��"
            Write-Host $buildOutput -ForegroundColor Red
            exit 1
        }
    }

    # ������ Step 4: ������ ������
    if ($Target -eq "all" -or $Target -eq "backend") {
        # ���� �ع�ģʽ ����
        if ($Rollback) {
            Write-Step "�ع���˵��汾 $Rollback..."
            Invoke-SSH "if [ -d ${SNAPSHOT_DIR}/${Rollback} ]; then cp -a ${SNAPSHOT_DIR}/${Rollback}/* ${BACKEND_REMOTE}/; systemctl restart huiyuanyuan; echo 'ROLLBACK_OK'; else echo 'SNAPSHOT_NOT_FOUND'; fi"
            Write-Ok "�ع����"
        } else {
            # ���� ��������ǰ���� ����
            Write-Step "��������ǰ����..."
            $snapTs = Get-Date -Format "yyyyMMdd_HHmmss"
            Invoke-SSH "mkdir -p ${SNAPSHOT_DIR}/${snapTs}; cp -a ${BACKEND_REMOTE}/main.py ${BACKEND_REMOTE}/requirements.txt ${BACKEND_REMOTE}/config.py ${BACKEND_REMOTE}/database.py ${BACKEND_REMOTE}/security.py ${BACKEND_REMOTE}/store.py ${SNAPSHOT_DIR}/${snapTs}/ 2>/dev/null; cp -a ${BACKEND_REMOTE}/routers ${BACKEND_REMOTE}/services ${BACKEND_REMOTE}/schemas ${BACKEND_REMOTE}/data ${SNAPSHOT_DIR}/${snapTs}/ 2>/dev/null; ls ${SNAPSHOT_DIR}/ | head -n -${MAX_SNAPSHOTS} | xargs -I{} rm -rf ${SNAPSHOT_DIR}/{} 2>/dev/null; echo SNAP_OK"
            Write-Ok "�����Ѵ���: $snapTs"

            # ���� �ϴ�����ļ� (v4: ��Ŀ¼�ṹ) ����
            Write-Step "�������ļ� (v4 ģ�黯)..."

            foreach ($item in $BACKEND_SYNC_ITEMS) {
                $localPath = Join-Path $BACKEND_LOCAL $item
                if (Test-Path $localPath) {
                    $isDir = (Get-Item $localPath).PSIsContainer
                    if ($isDir) {
                        # Ŀ¼: ����Զ�̴��������ϴ�����
                        Invoke-SSH "mkdir -p ${BACKEND_REMOTE}/${item}"
                        Invoke-SCP -Source "$localPath\*" -Dest "${BACKEND_REMOTE}/${item}/"
                    } else {
                        Invoke-SCP -Source $localPath -Dest "${BACKEND_REMOTE}/${item}"
                    }
                    Write-Info "  $item -> ${BACKEND_REMOTE}/${item}"
                }
            }

            Write-Step "��װ������� & ��������..."
            Invoke-SSH "cd ${BACKEND_REMOTE}; source venv/bin/activate; pip install -r requirements.txt -q 2>/dev/null; systemctl restart huiyuanyuan"
            Write-Ok "��˷���������"
        }

        # �������
        Write-Step "��˽������..."
        Start-Sleep -Seconds 3
        $healthy = $false
        for ($i = 1; $i -le $MAX_RETRIES; $i++) {
            $status = Invoke-SSH "curl -s -o /dev/null -w '%{http_code}' $HEALTH_URL 2>/dev/null || echo 000"
            if ($status -match "200") {
                Write-Ok "�������ͨ�� (���� $i/$MAX_RETRIES)"
                $healthy = $true
                break
            }
            Write-Warn "�ȴ��������... ($i/$MAX_RETRIES)"
            Start-Sleep -Seconds $RETRY_DELAY
        }
        if (-not $healthy -and -not $DryRun) {
            Write-Fail "��˽������ʧ�ܣ������Զ��ع�..."
            if ($snapTs) {
                Invoke-SSH "cp -a ${SNAPSHOT_DIR}/${snapTs}/* ${BACKEND_REMOTE}/ 2>/dev/null; systemctl restart huiyuanyuan"
                Write-Warn "�ѻع������� $snapTs�����Ų�: journalctl -u huiyuanyuan -n 50"
            }
            exit 1
        }
    }

    # ������ Step 4.5: ���� Nginx ���� ������
    if ($Target -eq "all" -or $Target -eq "nginx") {
        Write-Step "���� Nginx ��������..."

        $nginxProd = Join-Path $BACKEND_LOCAL "nginx_production.conf"
        $nginxSnippet = Join-Path $BACKEND_LOCAL "nginx_proxy_params.conf"

        if (Test-Path $nginxProd) {
            Invoke-SCP -Source $nginxProd -Dest "/etc/nginx/sites-available/huiyuanyuan"
            Write-Info "  nginx_production.conf -> sites-available"
        }
        if (Test-Path $nginxSnippet) {
            Invoke-SSH "mkdir -p /etc/nginx/snippets"
            Invoke-SCP -Source $nginxSnippet -Dest "/etc/nginx/snippets/proxy_params.conf"
            Write-Info "  proxy_params.conf -> snippets"
        }

        $nginxTest = Invoke-SSH "nginx -t 2>&1"
        if ($nginxTest -match "successful") {
            Invoke-SSH "systemctl reload nginx"
            Write-Ok "Nginx �����Ѹ��²�����"
        } else {
            Write-Fail "Nginx ���ò���ʧ��: $nginxTest"
            Write-Warn "Nginx δ���أ����ֶ��޸�"
        }
    }

    # ������ Step 4.6: ���ݿ��ʼ�� ������
    if ($Target -eq "db-init") {
        Write-Step "��ʼ��/�������ݿ��..."
        $initSql = Join-Path $BACKEND_LOCAL "init_db.sql"
        if (Test-Path $initSql) {
            Invoke-SCP -Source $initSql -Dest "${BACKEND_REMOTE}/init_db.sql"
            $dbResult = Invoke-SSH "sudo -u postgres psql -d huiyuanyuan -f ${BACKEND_REMOTE}/init_db.sql 2>&1 | tail -5"
            Write-Info $dbResult
            Write-Ok "���ݿ��ʼ�����"
        } else {
            Write-Fail "init_db.sql ������"
        }
    }

    # ������ Step 5: ����ǰ�� ������
    if ($Target -eq "all" -or $Target -eq "web") {
        Write-Step "���� Web ǰ��..."
        $webBuildPath = "$WEB_LOCAL\*"
        if (-not (Test-Path $WEB_LOCAL) -and -not $DryRun) {
            Write-Fail "Web �������ﲻ����: $WEB_LOCAL�����ȹ���"
            exit 1
        }
        Invoke-SCP -Source $webBuildPath -Dest $WEB_REMOTE
        Write-Ok "ǰ���ļ����ϴ��� $WEB_REMOTE"

        Write-Step "���� Nginx..."
        Invoke-SSH "nginx -t 2>&1 && systemctl reload nginx"
        Write-Ok "Nginx ����������"

        # ǰ�˿ɷ����Լ��
        $webStatus = Invoke-SSH "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/index.html 2>/dev/null || echo 000"
        if ($webStatus -match "200") {
            Write-Ok "ǰ��ҳ��ɷ��� (HTTP 200)"
        } else {
            Write-Warn "ǰ�˷���״̬: $webStatus"
        }
    }

    # ������ ��� ������
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  ������ɣ���ʱ ${elapsed}s" -ForegroundColor Green
    Write-Host "  ǰ��: http://$SERVER_HOST/" -ForegroundColor Green
    Write-Host "  ���: http://$SERVER_HOST/api/health" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green

} catch {
    Write-Fail "����ʧ��: $_"
    exit 1
} finally {
    Pop-Location -ErrorAction SilentlyContinue
}
