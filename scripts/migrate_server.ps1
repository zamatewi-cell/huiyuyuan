<#
.SYNOPSIS
    Migrate the current HuiYuYuan application and database to the target server.
.DESCRIPTION
    Exports the database from the old server, syncs the current application to
    the new server layout, restores the SQL dump, applies Alembic migrations,
    and reloads the production services.
.EXAMPLE
    .\scripts\migrate_server.ps1 -OldServerIP "47.98.188.141" -NewServerIP "47.112.98.191"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$OldServerIP,

    [Parameter(Mandatory = $true)]
    [string]$NewServerIP,

    [string]$PrimaryDomain = "xn--lsws2cdzg.top",
    [string]$SSHKeyPath = "${env:USERPROFILE}\.ssh\id_rsa",
    [switch]$SkipBackup,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$BackendLocal = "d:\huiyuanyuan_project\huiyuanyuan_app\backend"
$WebLocal = "d:\huiyuanyuan_project\huiyuanyuan_app\build\web"
$BackendRemote = "/srv/huiyuanyuan/backend"
$WebRemote = "/var/www/huiyuanyuan"
$EnvRemote = "/srv/huiyuanyuan/.env"
$ServiceName = "huiyuanyuan-backend"
$NginxRemote = "/etc/nginx/conf.d/huiyuanyuan.conf"
$NginxSnippetRemote = "/etc/nginx/snippets/proxy_params.conf"
$HealthUrl = "http://127.0.0.1:8000/api/health"
$MigrationStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LocalArtifactDir = Join-Path "builds\migration" "migration_$MigrationStamp"
$LocalDbDump = Join-Path $LocalArtifactDir "db_backup.sql"
$RemoteOldBackupDir = "/opt/huiyuanyuan/backups/migration_$MigrationStamp"
$RemoteNewSafetyDump = "/opt/huiyuanyuan/backups/pre_migration_$MigrationStamp.dump"

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Info([string]$Message) { Write-Host "  [INFO] $Message" -ForegroundColor Gray }
function Write-Ok([string]$Message) { Write-Host "  [OK]   $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
function Write-Fail([string]$Message) { Write-Host "  [FAIL] $Message" -ForegroundColor Red }

function Get-SshArgs {
    $args = @(
        "-o", "ConnectTimeout=10",
        "-o", "StrictHostKeyChecking=no"
    )
    if ($SSHKeyPath) {
        $args += @("-i", $SSHKeyPath)
    }
    return $args
}

function Test-SshConnection {
    param([string]$ServerIP)

    if ($DryRun) {
        Write-Warn "[DRY RUN] test ssh root@${ServerIP}"
        return
    }

    $output = & ssh @(Get-SshArgs) "root@${ServerIP}" "echo SSH_OK" 2>&1
    if ($LASTEXITCODE -ne 0 -or ($output -join "`n") -notmatch "SSH_OK") {
        throw "SSH connection failed for ${ServerIP}: $($output -join "`n")"
    }
}

function Invoke-Remote {
    param(
        [string]$ServerIP,
        [string]$Command
    )

    if ($DryRun) {
        Write-Warn "[DRY RUN] ssh root@${ServerIP} `"$Command`""
        return ""
    }

    $output = & ssh @(Get-SshArgs) "root@${ServerIP}" $Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Remote command failed on ${ServerIP}: $($output -join "`n")"
    }
    return ($output -join "`n").Trim()
}

function Copy-ToServer {
    param(
        [string]$ServerIP,
        [string]$LocalPath,
        [string]$RemotePath
    )

    if ($DryRun) {
        Write-Warn "[DRY RUN] scp $LocalPath -> root@${ServerIP}:$RemotePath"
        return
    }

    $output = & scp @(Get-SshArgs) -r $LocalPath "root@${ServerIP}:$RemotePath" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "SCP upload failed: $($output -join "`n")"
    }
}

function Copy-FromServer {
    param(
        [string]$ServerIP,
        [string]$RemotePath,
        [string]$LocalPath
    )

    if ($DryRun) {
        Write-Warn "[DRY RUN] scp root@${ServerIP}:$RemotePath -> $LocalPath"
        return
    }

    $output = & scp @(Get-SshArgs) "root@${ServerIP}:$RemotePath" $LocalPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "SCP download failed: $($output -join "`n")"
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  HuiYuYuan server migration" -ForegroundColor Magenta
Write-Host "  Old: $OldServerIP" -ForegroundColor Magenta
Write-Host "  New: $NewServerIP" -ForegroundColor Magenta
if ($DryRun) {
    Write-Host "  DRY RUN mode" -ForegroundColor Yellow
}
Write-Host "=============================================" -ForegroundColor Magenta

try {
    Write-Step "Checking SSH connectivity"
    Test-SshConnection -ServerIP $OldServerIP
    Test-SshConnection -ServerIP $NewServerIP
    Write-Ok "both servers are reachable"

    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $LocalArtifactDir | Out-Null
    }

    Write-Step "Exporting the old server database"
    Invoke-Remote -ServerIP $OldServerIP -Command "mkdir -p $RemoteOldBackupDir"
    Invoke-Remote -ServerIP $OldServerIP -Command "sudo -u postgres pg_dump huiyuanyuan > $RemoteOldBackupDir/db_backup.sql"
    Copy-FromServer -ServerIP $OldServerIP -RemotePath "$RemoteOldBackupDir/db_backup.sql" -LocalPath $LocalDbDump
    Write-Ok "database dump exported to $LocalDbDump"

    if (-not $SkipBackup) {
        Write-Step "Creating safety backup on the new server"
        Invoke-Remote -ServerIP $NewServerIP -Command "mkdir -p /opt/huiyuanyuan/backups"
        Invoke-Remote -ServerIP $NewServerIP -Command "sudo -u postgres pg_dump -Fc huiyuanyuan > $RemoteNewSafetyDump"
        Write-Ok "new server safety backup created at $RemoteNewSafetyDump"
    } else {
        Write-Warn "skipping safety backup on the new server"
    }

    Write-Step "Uploading backend source"
    Invoke-Remote -ServerIP $NewServerIP -Command "mkdir -p $BackendRemote"
    Copy-ToServer -ServerIP $NewServerIP -LocalPath $BackendLocal -RemotePath "/srv/huiyuanyuan/"
    Write-Ok "backend source uploaded"

    Write-Step "Uploading web assets"
    if (Test-Path $WebLocal) {
        Copy-ToServer -ServerIP $NewServerIP -LocalPath $WebLocal -RemotePath $WebRemote
        Write-Ok "web build uploaded"
    } else {
        Write-Warn "web build not found at $WebLocal"
    }

    Write-Step "Updating production config on the new server"
    Invoke-Remote -ServerIP $NewServerIP -Command "test -f $EnvRemote"
    # Keep ALLOWED_ORIGINS ASCII-only so the remote sed command is encoding-safe.
    $allowedOrigins = "https://$PrimaryDomain,https://www.$PrimaryDomain"
    $envCommand = @"
bash -lc 'if grep -q "^ALLOWED_ORIGINS=" ${EnvRemote}; then
  sed -i "s|^ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=${allowedOrigins}|" ${EnvRemote};
else
  printf "\nALLOWED_ORIGINS=${allowedOrigins}\n" >> ${EnvRemote};
fi;
chmod 600 ${EnvRemote}'
"@
    Invoke-Remote -ServerIP $NewServerIP -Command $envCommand | Out-Null

    Copy-ToServer -ServerIP $NewServerIP -LocalPath (Join-Path $BackendLocal "huiyuanyuan-backend.service") -RemotePath "/etc/systemd/system/huiyuanyuan-backend.service"
    Invoke-Remote -ServerIP $NewServerIP -Command "mkdir -p /etc/nginx/snippets"
    Copy-ToServer -ServerIP $NewServerIP -LocalPath (Join-Path $BackendLocal "nginx_production.conf") -RemotePath $NginxRemote
    Copy-ToServer -ServerIP $NewServerIP -LocalPath (Join-Path $BackendLocal "nginx_proxy_params.conf") -RemotePath $NginxSnippetRemote
    Write-Ok "service and Nginx config uploaded"

    Write-Step "Restoring database on the new server"
    Copy-ToServer -ServerIP $NewServerIP -LocalPath $LocalDbDump -RemotePath "/tmp/db_backup.sql"
    Invoke-Remote -ServerIP $NewServerIP -Command "sudo -u postgres psql -d huiyuanyuan -f /tmp/db_backup.sql"
    Write-Ok "database restored"

    Write-Step "Applying Alembic and restarting services"
    $deployCommand = @"
bash -lc 'cd ${BackendRemote};
source venv/bin/activate;
pip install -r requirements.txt -q 2>/dev/null;
alembic upgrade head;
systemctl daemon-reload;
systemctl enable ${ServiceName};
systemctl restart ${ServiceName};
nginx -t;
systemctl reload nginx'
"@
    Invoke-Remote -ServerIP $NewServerIP -Command $deployCommand | Out-Null
    Write-Ok "application and Nginx reloaded"

    Write-Step "Verifying health"
    $localHealth = Invoke-Remote -ServerIP $NewServerIP -Command "curl -s $HealthUrl"
    Write-Info "server local health: $localHealth"

    if ($DryRun) {
        Write-Warn "[DRY RUN] skip public HTTPS verification"
    } else {
        try {
            $publicHealth = Invoke-RestMethod -Uri "https://$PrimaryDomain/api/health" -TimeoutSec 30
            Write-Ok "public HTTPS health: $($publicHealth.status)"
        } catch {
            Write-Warn "public HTTPS verification failed: $_"
        }
    }

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  Migration completed" -ForegroundColor Green
    Write-Host "  Domain: https://$PrimaryDomain" -ForegroundColor Green
    Write-Host "  Health: https://$PrimaryDomain/api/health" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} catch {
    Write-Fail "$_"
    exit 1
}
