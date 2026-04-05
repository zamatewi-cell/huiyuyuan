#!/usr/bin/env pwsh

param(
    [string]$ServerHost = "47.112.98.191",
    [string]$ServerUser = "root",
    [string]$PublicBaseUrl = "https://xn--lsws2cdzg.top",
    [string]$HealthPath = "/api/health",
    [string]$SSHKeyPath = "",
    [string]$ServiceName = "huiyuyuan-backend"
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
        [string]$TargetHost,
        [string]$Command
    )

    $target = "${User}@${TargetHost}"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & ssh @(Get-SshBaseArgs) $target $Command 2>&1
    $ErrorActionPreference = $previousPreference
    if ($LASTEXITCODE -ne 0) {
        throw "ssh ${target} failed:`n$($output -join "`n")"
    }
    return ($output -join "`n").Trim()
}

function Invoke-CurlProbe {
    param([switch]$NoProxy)

    $uri = $PublicBaseUrl.TrimEnd("/") + $HealthPath
    $args = @("-vk", "--max-time", "8")
    if ($NoProxy) {
        $args += @("--noproxy", "*")
    }
    $args += $uri
    $quotedArgs = $args | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }
    $commandLine = "curl.exe " + ($quotedArgs -join " ") + " 2>&1"
    $output = cmd /c $commandLine

    return [pscustomobject]@{
        Mode = $(if ($NoProxy) { "direct" } else { "proxy-default" })
        ExitCode = $LASTEXITCODE
        Output = (($output | ForEach-Object { $_.ToString() }) -join "`n").Trim()
    }
}

$proxyVars = @(
    "http_proxy", "https_proxy", "all_proxy", "no_proxy",
    "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY"
)

Write-Step "Reading local proxy environment"
$detected = @()
foreach ($name in $proxyVars) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ($value) {
        $detected += [pscustomobject]@{ Name = $name; Value = $value }
    }
}

if ($detected.Count -eq 0) {
    Write-Ok "no proxy environment variables are set"
} else {
    Write-Warn "proxy environment variables detected:"
    foreach ($item in $detected) {
        Write-Host "    $($item.Name)=$($item.Value)"
    }
}

Write-Step "Running public HTTPS probes"
$proxyProbe = Invoke-CurlProbe
$directProbe = Invoke-CurlProbe -NoProxy

Write-Info "proxy-default exit=$($proxyProbe.ExitCode)"
Write-Host $proxyProbe.Output
Write-Info "direct exit=$($directProbe.ExitCode)"
Write-Host $directProbe.Output

Write-Step "Checking the server-side application path"
$serverReportCommand = @'
echo "host:$(hostname)"
echo "nginx:$(systemctl is-active nginx)"
echo "app:$(systemctl is-active __SERVICE__)"
echo "listen:"
ss -ltnp | grep -E ':80 |:443 |:8000 ' || true
echo "local_health:"
curl -s http://127.0.0.1:8000/api/health || true
echo "huiyuyuan_access_log_tail:"
tail -n 5 /var/log/nginx/huiyuyuan_access.log 2>/dev/null || true
echo "default_access_log_tail:"
tail -n 5 /var/log/nginx/access.log 2>/dev/null || true
'@
$serverReportCommand = $serverReportCommand.Replace("__SERVICE__", $ServiceName)
$serverReport = Invoke-SshRaw -User $ServerUser -TargetHost $ServerHost -Command $serverReportCommand
Write-Host $serverReport

Write-Step "Summary"
if ($detected.Count -gt 0) {
    Write-Warn "The local machine has proxy variables enabled. Prefer the direct probe before trusting HTTPS results."
}
if ($proxyProbe.ExitCode -ne 0) {
    Write-Warn "The proxy-default probe failed."
}
if ($directProbe.ExitCode -eq 0) {
    Write-Ok "The direct probe completed successfully."
} else {
    Write-Warn "The direct probe failed. If the local health endpoint is healthy, the remaining issue is outside the app process."
}
