# HuiYuYuan Android Keystore Generator
$ErrorActionPreference = "Stop"
$appDir = Join-Path $PSScriptRoot "..\huiyuyuan_app\android"
$jksPath = Join-Path $appDir "huiyuyuan.jks"
$keyPropsPath = Join-Path $appDir "key.properties"
try { $null = Get-Command keytool -ErrorAction Stop } catch { Write-Host "ERROR: keytool not found. Install JDK first." -ForegroundColor Red; exit 1 }
if (Test-Path $jksPath) { Write-Host "Already exists: $jksPath" -ForegroundColor Yellow; exit 0 }
$storePass = Read-Host "Keystore password"
$kp = Read-Host "Key password (Enter=same)" -AsSecureString
$b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($kp)
$keyPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto($b)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)
if ($keyPass -eq "") { $keyPass = $storePass }
& keytool -genkeypair -v -keystore $jksPath -keyalg RSA -keysize 2048 -validity 10000 -alias huiyuyuan -storepass $storePass -keypass $keyPass -dname "CN=HuiYuYuan,OU=Dev,O=HuiYuYuan,L=Shenzhen,S=Guangdong,C=CN" 2>&1
$t = "storePassword=$storePass`nkeyPassword=$keyPass`nkeyAlias=huiyuyuan`nstoreFile=../huiyuyuan.jks"
[System.IO.File]::WriteAllText($keyPropsPath, $t, [Text.Encoding]::UTF8)
Write-Host "Done. Backup $jksPath safely!" -ForegroundColor Green
