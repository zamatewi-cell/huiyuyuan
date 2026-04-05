param(
    [switch]$SkipPubGet,
    [switch]$SkipAnalyze
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $repoRoot 'huiyuyuan_app'

Push-Location $appDir
try {
    if (-not $SkipPubGet) {
        Write-Host '==> flutter pub get'
        flutter pub get
    }

    Write-Host '==> dart run tool/i18n_audit.dart'
    dart run tool/i18n_audit.dart

    Write-Host '==> flutter test test/l10n/i18n_guard_test.dart'
    flutter test test/l10n/i18n_guard_test.dart

    if (-not $SkipAnalyze) {
        Write-Host '==> flutter analyze --no-fatal-infos lib/ test/l10n/ tool/i18n_audit.dart'
        flutter analyze --no-fatal-infos lib/ test/l10n/ tool/i18n_audit.dart
    }
}
finally {
    Pop-Location
}
