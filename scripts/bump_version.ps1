# 汇玉源版本号同步脚本
# 用途：一次性更新 pubspec.yaml、app_config.dart、backend/config.py 的版本号
#
# 使用方法（PowerShell）：
#   cd D:\huiyuyuan_project
#   .\scripts\bump_version.ps1                           # 自动递增 patch 版本
#   .\scripts\bump_version.ps1 -Version "3.1.0"          # 指定版本号
#   .\scripts\bump_version.ps1 -Version "3.1.0" -Build 10 # 指定版本号和构建号
#
# 示例输出：
#   pubspec.yaml: 3.0.3+5 → 3.0.4+6
#   app_config.dart: 3.0.3 / 5 → 3.0.4 / 6
#   backend/config.py: 3.0.3 / 5 → 3.0.4 / 6

param(
    [Parameter(Mandatory = $false)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [int]$Build,

    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$appDir = Join-Path $projectRoot "huiyuyuan_app"
$pubspecPath = Join-Path $appDir "pubspec.yaml"
$appConfigPath = Join-Path $appDir "lib\config\app_config.dart"
$backendConfigPath = Join-Path $appDir "backend\config.py"

# ── 读取当前版本号 ──
$pubspecContent = Get-Content $pubspecPath -Raw -Encoding UTF8
$currentVersion = ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)') ? $Matches[1] : "unknown"
$currentBuild = ($pubspecContent -match 'version:\s*\d+\.\d+\.\d+\+(\d+)') ? $Matches[1] : "0"

Write-Host "`n=== 汇玉源版本号同步工具 ===" -ForegroundColor Cyan
Write-Host "当前版本: $currentVersion+$currentBuild" -ForegroundColor Yellow

# ── 计算新版本号 ──
if (-not $Version) {
    # 自动递增 patch
    $parts = $currentVersion.Split('.')
    $parts[2] = [int]$parts[2] + 1
    $Version = $parts -join '.'
}

if ($Build -eq 0) {
    $Build = [int]$currentBuild + 1
}

$newVersionString = "$Version+$Build"

Write-Host "新版本号: $newVersionString" -ForegroundColor Green

if ($WhatIf) {
    Write-Host "`n[WhatIf] 未执行任何修改，以下是将会更改的内容：" -ForegroundColor Yellow
    Write-Host "  pubspec.yaml:    version: $currentVersion+$currentBuild → version: $newVersionString"
    Write-Host "  app_config.dart: appVersion = '$currentVersion' → '$Version'"
    Write-Host "  app_config.dart: appBuildNumber = $currentBuild → $Build"
    Write-Host "  backend/config.py: APP_LATEST_VERSION = '$currentVersion' → '$Version'"
    Write-Host "  backend/config.py: APP_LATEST_BUILD_NUMBER = $currentBuild → $Build"
    exit 0
}

# ── 确认 ──
$confirm = Read-Host "`n确认更新版本号？(y/n)"
if ($confirm -ne 'y') {
    Write-Host "已取消" -ForegroundColor Yellow
    exit 0
}

# ── 更新 pubspec.yaml ──
$newPubspec = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersionString"
$newPubspec | Out-File -FilePath $pubspecPath -Encoding UTF8 -NoNewline
Write-Host "[OK] pubspec.yaml → $newVersionString" -ForegroundColor Green

# ── 更新 app_config.dart ──
$appConfigContent = Get-Content $appConfigPath -Raw -Encoding UTF8
$newAppConfig = $appConfigContent `
    -replace "static const String appVersion = '$currentVersion'", "static const String appVersion = '$Version'" `
    -replace "static const int appBuildNumber = $currentBuild", "static const int appBuildNumber = $Build"
$newAppConfig | Out-File -FilePath $appConfigPath -Encoding UTF8 -NoNewline
Write-Host "[OK] app_config.dart → $Version / $Build" -ForegroundColor Green

# ── 更新 backend/config.py ──
$backendContent = Get-Content $backendConfigPath -Raw -Encoding UTF8
$newBackend = $backendContent `
    -replace 'APP_LATEST_VERSION = "' + $currentVersion + '"', 'APP_LATEST_VERSION = "' + $Version + '"' `
    -replace 'APP_LATEST_BUILD_NUMBER = ' + $currentBuild, 'APP_LATEST_BUILD_NUMBER = ' + $Build `
    -replace 'APP_RELEASED_AT = "[^"]*"', 'APP_RELEASED_AT = "' + (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz') + '"'
$newBackend | Out-File -FilePath $backendConfigPath -Encoding UTF8 -NoNewline
Write-Host "[OK] backend/config.py → $Version / $Build" -ForegroundColor Green

# ── 完成 ──
Write-Host "`n=== 版本号更新完成 ===" -ForegroundColor Green
Write-Host "新版本: $newVersionString" -ForegroundColor Cyan
Write-Host "`n下一步：" -ForegroundColor Yellow
Write-Host "  1. 更新 backend/config.py 中的 APP_RELEASE_NOTES"
Write-Host "  2. 提交更改: git commit -m '发布: 更新版本号至 $newVersionString'"
Write-Host "  3. 构建 APK: flutter build apk --release"
Write-Host "  4. 发布: .\scripts\deploy.ps1"
