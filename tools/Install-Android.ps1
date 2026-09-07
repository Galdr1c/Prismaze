param(
    [string]$AdbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    [string]$DeviceSerial = ""
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$apk = Join-Path $projectRoot 'Builds\Android\Prismaze-dev.apk'
if (-not (Test-Path -LiteralPath $AdbPath)) { throw "ADB not found: $AdbPath" }
if (-not (Test-Path -LiteralPath $apk)) { throw "APK not found: $apk. Run Build-Android.ps1 first." }
$devices = @(& $AdbPath devices | Select-Object -Skip 1 | Where-Object { $_ -match '^([^\s]+)\s+device$' })
if ([string]::IsNullOrEmpty($DeviceSerial)) {
    if ($devices.Count -ne 1) { throw "Expected one authorised Android device; found $($devices.Count). Pass -DeviceSerial when multiple devices are connected." }
    $DeviceSerial = [regex]::Match([string]$devices[0], '^\S+').Value
}
& $AdbPath -s $DeviceSerial install -r $apk
if ($LASTEXITCODE -ne 0) { throw "APK install failed for $DeviceSerial." }
& $AdbPath -s $DeviceSerial shell am force-stop com.prismaze.game.dev
& $AdbPath -s $DeviceSerial shell monkey -p com.prismaze.game.dev 1
if ($LASTEXITCODE -ne 0) { throw "Prismaze launch failed for $DeviceSerial." }
Write-Host "Prismaze started on $DeviceSerial. Test airplane mode, first tutorial tap, pause/resume, save and monetization fallback."
