# HuiYuYuan - Generate Android Release Keystore (Non-Interactive)
# This script generates a keystore with auto-generated secure passwords.
# For production, prefer the interactive version: .\generate_keystore.ps1

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $repoRoot "huiyuyuan_app\android"
$jksPath = Join-Path $appDir "huiyuyuan.jks"
$keyPropsPath = Join-Path $appDir "key.properties"

# Check keytool
try { $null = Get-Command keytool -ErrorAction Stop }
catch {
    Write-Host "[ERROR] keytool not found. Install JDK first." -ForegroundColor Red
    exit 1
}

# Check if already exists
if (Test-Path $jksPath) {
    Write-Host "[WARN] Keystore already exists: $jksPath" -ForegroundColor Yellow
    Write-Host "        Delete it first if you want to regenerate." -ForegroundColor Yellow
    exit 0
}

# Generate secure random passwords (32 chars hex)
$bytes = [byte[]]::new(16)
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$storePass = -join ($bytes | ForEach-Object { '{0:x2}' -f $_ })
$keyPass = $storePass

Write-Host "[1/3] Generating keystore..." -ForegroundColor Cyan
# keytool writes to stderr even on success, so we suppress $ErrorActionPreference temporarily
$originalEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & keytool -genkeypair -v `
        -keystore $jksPath `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -alias huiyuyuan `
        -storepass $storePass `
        -keypass $keyPass `
        -dname "CN=HuiYuYuan, OU=Dev, O=HuiYuYuan, L=Shenzhen, S=Guangdong, C=CN" `
        2>$null
} finally {
    $ErrorActionPreference = $originalEAP
}

if (-not (Test-Path $jksPath)) {
    Write-Host "[ERROR] keytool failed" -ForegroundColor Red
    exit 1
}

Write-Host "[2/3] Writing key.properties..." -ForegroundColor Cyan
$props = @"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=huiyuyuan
storeFile=../huiyuyuan.jks
"@
[System.IO.File]::WriteAllText($keyPropsPath, $props, [Text.Encoding]::UTF8)

Write-Host "[3/3] Verifying..." -ForegroundColor Cyan
$verify = & keytool -list -keystore $jksPath -storepass $storePass 2>&1
if (Test-Path $jksPath) {
    Write-Host "`n[OK] Keystore generated successfully!" -ForegroundColor Green
    Write-Host "  Path: $jksPath" -ForegroundColor White
    Write-Host "  Alias: huiyuyuan" -ForegroundColor White
    Write-Host "  Validity: 10000 days (~27 years)" -ForegroundColor White
    Write-Host "`n[IMPORTANT] BACK UP $jksPath IMMEDIATELY!" -ForegroundColor Red
    Write-Host "           Losing this keystore means you CANNOT update your app on Google Play." -ForegroundColor Red
    Write-Host "           Add it to your secure password manager or offline storage." -ForegroundColor Red
} else {
    Write-Host "[ERROR] Verification failed" -ForegroundColor Red
    Write-Host $verify -ForegroundColor Red
    exit 1
}
