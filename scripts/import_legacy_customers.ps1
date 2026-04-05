#!/usr/bin/env pwsh

param(
    [string]$OldServerIP = "47.98.188.141",
    [string]$NewServerIP = "47.112.98.191",
    [string]$OldServerUser = "root",
    [string]$NewServerUser = "root",
    [string]$SSHKeyPath = "",
    [string]$ExportDir = "builds\migration",
    [switch]$Apply,
    [switch]$IncludeSmsLogs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Info([string]$Message) { Write-Host "  [INFO] $Message" -ForegroundColor Gray }
function Write-Ok([string]$Message) { Write-Host "  [OK]   $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
function Write-Fail([string]$Message) { Write-Host "  [FAIL] $Message" -ForegroundColor Red }

function Get-SshBaseArgs {
    $args = @(
        "-o", "ConnectTimeout=10",
        "-o", "StrictHostKeyChecking=no"
    )
    if ($SSHKeyPath) {
        $args += @("-i", $SSHKeyPath)
    }
    return $args
}

function Invoke-SshRaw {
    param(
        [string]$User,
        [string]$ServerHost,
        [string]$Command
    )

    $target = "${User}@${ServerHost}"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & ssh @(Get-SshBaseArgs) $target $Command 2>&1
    $ErrorActionPreference = $previousPreference
    if ($LASTEXITCODE -ne 0) {
        throw "ssh ${target} failed:`n$($output -join "`n")"
    }
    return ($output -join "`n").Trim()
}

function Invoke-ScpUpload {
    param(
        [string]$User,
        [string]$ServerHost,
        [string]$LocalPath,
        [string]$RemotePath
    )

    $target = "${User}@${ServerHost}:${RemotePath}"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & scp @(Get-SshBaseArgs) $LocalPath $target 2>&1
    $ErrorActionPreference = $previousPreference
    if ($LASTEXITCODE -ne 0) {
        throw "scp to ${target} failed:`n$($output -join "`n")"
    }
}

function Resolve-AbsolutePath([string]$PathValue) {
    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\$PathValue"))
}

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $normalized = $Content -replace "`r`n", "`n"
    $normalized = $normalized -replace "`r", "`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

function Export-QueryCsv {
    param(
        [string]$User,
        [string]$ServerHost,
        [string]$Sql
    )

    $remoteCommand = @"
cd /tmp && cat <<'SQL' | sudo -u postgres psql -d huiyuyuan
$Sql
SQL
"@
    return Invoke-SshRaw -User $User -ServerHost $ServerHost -Command $remoteCommand
}

function Export-CustomerCsv {
    param([string]$User, [string]$ServerHost)

    $sql = "\copy (SELECT id, phone, username, password_hash, avatar_url, user_type, operator_num, balance, points, is_active, created_at, updated_at FROM users WHERE user_type = 'customer' ORDER BY created_at) TO STDOUT WITH CSV HEADER"
    return Export-QueryCsv -User $User -ServerHost $ServerHost -Sql $sql
}

function Export-AllUserKeysCsv {
    param([string]$User, [string]$ServerHost)

    $sql = "\copy (SELECT id, phone, user_type FROM users ORDER BY created_at) TO STDOUT WITH CSV HEADER"
    return Export-QueryCsv -User $User -ServerHost $ServerHost -Sql $sql
}

function Export-SmsLogsCsv {
    param([string]$User, [string]$ServerHost)

    $sql = "\copy (SELECT * FROM sms_logs ORDER BY created_at) TO STDOUT WITH CSV HEADER"
    return Export-QueryCsv -User $User -ServerHost $ServerHost -Sql $sql
}

function Get-Scalar {
    param(
        [string]$User,
        [string]$ServerHost,
        [string]$Sql
    )

    $remoteCommand = @"
cd /tmp && cat <<'SQL' | sudo -u postgres psql -d huiyuyuan -Atq
$Sql
SQL
"@
    return Invoke-SshRaw -User $User -ServerHost $ServerHost -Command $remoteCommand
}

function Show-UserTypeCounts {
    param(
        [string]$Label,
        [string]$User,
        [string]$ServerHost
    )

    $raw = Get-Scalar -User $User -ServerHost $ServerHost -Sql "select user_type || ':' || count(*) from users group by user_type order by user_type;"
    Write-Info "$Label user counts:"
    foreach ($line in ($raw -split "`r?`n" | Where-Object { $_ })) {
        Write-Host "    $line"
    }
}

function Get-ConflictReport {
    param(
        [object[]]$LegacyCustomers,
        [object[]]$CurrentUsers
    )

    $phoneMap = @{}
    $idMap = @{}
    foreach ($user in $CurrentUsers) {
        if ($user.phone) {
            $phoneMap[$user.phone] = $user
        }
        if ($user.id) {
            $idMap[$user.id] = $user
        }
    }

    $phoneConflicts = New-Object System.Collections.Generic.List[object]
    $idConflicts = New-Object System.Collections.Generic.List[object]

    foreach ($customer in $LegacyCustomers) {
        if ($customer.phone -and $phoneMap.ContainsKey($customer.phone)) {
            $existing = $phoneMap[$customer.phone]
            $phoneConflicts.Add([pscustomobject]@{
                phone = $customer.phone
                legacy_id = $customer.id
                current_id = $existing.id
                current_type = $existing.user_type
            })
        }
        if ($customer.id -and $idMap.ContainsKey($customer.id)) {
            $existing = $idMap[$customer.id]
            $idConflicts.Add([pscustomobject]@{
                id = $customer.id
                legacy_phone = $customer.phone
                current_phone = $existing.phone
                current_type = $existing.user_type
            })
        }
    }

    return [pscustomobject]@{
        phone = $phoneConflicts
        id = $idConflicts
    }
}

$resolvedExportDir = Resolve-AbsolutePath -PathValue $ExportDir
New-Item -ItemType Directory -Force -Path $resolvedExportDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvLocalPath = Join-Path $resolvedExportDir "legacy_customers_${timestamp}.csv"
$sqlLocalPath = Join-Path $resolvedExportDir "legacy_customers_import_${timestamp}.sql"
$smsLocalPath = Join-Path $resolvedExportDir "legacy_sms_logs_${timestamp}.csv"
$csvRemotePath = "/tmp/legacy_customers_${timestamp}.csv"
$sqlRemotePath = "/tmp/legacy_customers_import_${timestamp}.sql"
$backupRemotePath = "/opt/huiyuyuan/backups/pre_legacy_customer_import_${timestamp}.dump"

Write-Step "Checking server access"
Invoke-SshRaw -User $OldServerUser -ServerHost $OldServerIP -Command "echo legacy-ok" | Out-Null
Invoke-SshRaw -User $NewServerUser -ServerHost $NewServerIP -Command "echo current-ok" | Out-Null
Write-Ok "SSH access to both servers is healthy"

Write-Step "Collecting current counts"
$legacyCustomerCount = [int](Get-Scalar -User $OldServerUser -ServerHost $OldServerIP -Sql "select count(*) from users where user_type = 'customer';")
$legacyAdminCount = [int](Get-Scalar -User $OldServerUser -ServerHost $OldServerIP -Sql "select count(*) from users where user_type = 'admin';")
$legacySmsCount = [int](Get-Scalar -User $OldServerUser -ServerHost $OldServerIP -Sql "select count(*) from sms_logs;")
$currentCustomerCount = [int](Get-Scalar -User $NewServerUser -ServerHost $NewServerIP -Sql "select count(*) from users where user_type = 'customer';")
$currentTotalUsers = [int](Get-Scalar -User $NewServerUser -ServerHost $NewServerIP -Sql "select count(*) from users;")

Write-Info "legacy customers: $legacyCustomerCount"
Write-Info "legacy admins:    $legacyAdminCount"
Write-Info "legacy sms_logs:  $legacySmsCount"
Write-Info "current users:    $currentTotalUsers"
Write-Info "current customers:$currentCustomerCount"

Show-UserTypeCounts -Label "legacy" -User $OldServerUser -ServerHost $OldServerIP
Show-UserTypeCounts -Label "current" -User $NewServerUser -ServerHost $NewServerIP

Write-Step "Exporting legacy customer rows"
$customerCsv = Export-CustomerCsv -User $OldServerUser -ServerHost $OldServerIP
Write-Utf8NoBomFile -Path $csvLocalPath -Content $customerCsv
$legacyCustomers = Import-Csv -Path $csvLocalPath
Write-Ok "exported $($legacyCustomers.Count) customer rows to $csvLocalPath"

Write-Step "Checking for ID and phone conflicts on the current server"
$currentUserKeysCsv = Export-AllUserKeysCsv -User $NewServerUser -ServerHost $NewServerIP
$currentUsers = $currentUserKeysCsv | ConvertFrom-Csv
$conflicts = Get-ConflictReport -LegacyCustomers $legacyCustomers -CurrentUsers $currentUsers

if ($conflicts.phone.Count -gt 0) {
    Write-Warn "phone conflicts detected:"
    foreach ($row in $conflicts.phone) {
        Write-Host "    phone=$($row.phone) legacy_id=$($row.legacy_id) current_id=$($row.current_id) current_type=$($row.current_type)"
    }
}
if ($conflicts.id.Count -gt 0) {
    Write-Warn "id conflicts detected:"
    foreach ($row in $conflicts.id) {
        Write-Host "    id=$($row.id) legacy_phone=$($row.legacy_phone) current_phone=$($row.current_phone) current_type=$($row.current_type)"
    }
}

if (($conflicts.phone.Count -gt 0) -or ($conflicts.id.Count -gt 0)) {
    throw "Import aborted because conflicts were detected. Resolve conflicts before applying."
}
Write-Ok "no ID or phone conflicts were found"

if ($IncludeSmsLogs) {
    Write-Step "Exporting legacy sms_logs for audit"
    $smsCsv = Export-SmsLogsCsv -User $OldServerUser -ServerHost $OldServerIP
    Write-Utf8NoBomFile -Path $smsLocalPath -Content $smsCsv
    Write-Ok "exported legacy sms_logs to $smsLocalPath"
}

$sqlContent = @"
BEGIN;

CREATE TEMP TABLE legacy_customer_import (
  id varchar(64),
  phone varchar(20),
  username varchar(64),
  password_hash varchar(256),
  avatar_url text,
  user_type varchar(20),
  operator_num integer,
  balance numeric(12,2),
  points integer,
  is_active boolean,
  created_at timestamptz,
  updated_at timestamptz
) ON COMMIT DROP;

\copy legacy_customer_import FROM '$csvRemotePath' WITH (FORMAT csv, HEADER true, NULL '');

INSERT INTO users (
  id,
  phone,
  username,
  password_hash,
  avatar_url,
  user_type,
  operator_num,
  balance,
  points,
  is_active,
  created_at,
  updated_at
)
SELECT
  id,
  phone,
  username,
  password_hash,
  avatar_url,
  user_type,
  operator_num,
  balance,
  points,
  is_active,
  created_at,
  updated_at
FROM legacy_customer_import
WHERE user_type = 'customer'
ON CONFLICT (phone) DO NOTHING;

COMMIT;

SELECT 'customer_users=' || count(*) FROM users WHERE user_type = 'customer';
SELECT 'total_users=' || count(*) FROM users;
"@

Write-Utf8NoBomFile -Path $sqlLocalPath -Content $sqlContent
Write-Ok "generated import SQL at $sqlLocalPath"

if (-not $Apply) {
    Write-Step "Preflight complete"
    Write-Info "No production changes were made."
    Write-Info "Use -Apply to upload $csvLocalPath and import the legacy customer rows."
    exit 0
}

Write-Step "Creating a safety backup on the current server"
Invoke-SshRaw -User $NewServerUser -ServerHost $NewServerIP -Command "mkdir -p /opt/huiyuyuan/backups && sudo -u postgres pg_dump -d huiyuyuan --format=custom --compress=9 > $backupRemotePath"
Write-Ok "backup created at $backupRemotePath"

Write-Step "Uploading import artifacts"
Invoke-ScpUpload -User $NewServerUser -ServerHost $NewServerIP -LocalPath $csvLocalPath -RemotePath $csvRemotePath
Invoke-ScpUpload -User $NewServerUser -ServerHost $NewServerIP -LocalPath $sqlLocalPath -RemotePath $sqlRemotePath
Invoke-SshRaw -User $NewServerUser -ServerHost $NewServerIP -Command "chmod 644 $csvRemotePath $sqlRemotePath"
Write-Ok "artifacts uploaded to /tmp"

Write-Step "Applying legacy customer import"
$applyOutput = Invoke-SshRaw -User $NewServerUser -ServerHost $NewServerIP -Command "cd /tmp && sudo -u postgres psql -d huiyuyuan -f $sqlRemotePath"
Write-Host $applyOutput

Write-Step "Verifying imported counts"
$finalCustomerCount = [int](Get-Scalar -User $NewServerUser -ServerHost $NewServerIP -Sql "select count(*) from users where user_type = 'customer';")
$finalTotalUsers = [int](Get-Scalar -User $NewServerUser -ServerHost $NewServerIP -Sql "select count(*) from users;")
$delta = $finalCustomerCount - $currentCustomerCount

Write-Ok "current customer count is now $finalCustomerCount"
Write-Ok "current total user count is now $finalTotalUsers"
Write-Ok "imported customer rows in this run: $delta"

if ($delta -ne $legacyCustomers.Count) {
    Write-Warn "expected to import $($legacyCustomers.Count) rows but inserted $delta rows"
} else {
    Write-Ok "all legacy customer rows were imported"
}
