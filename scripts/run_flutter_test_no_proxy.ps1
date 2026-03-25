$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $repoRoot 'huiyuanyuan_app'

$env:HTTP_PROXY = $null
$env:HTTPS_PROXY = $null
$env:ALL_PROXY = $null
$env:NO_PROXY = '127.0.0.1,localhost'

Push-Location $appDir
try {
    & flutter test @args
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
