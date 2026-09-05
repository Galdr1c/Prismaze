param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Godot-Tools.ps1')
$projectRoot = Split-Path $PSScriptRoot -Parent
$engine = Find-PrismazeGodot $GodotPath
$template = Join-Path $projectRoot 'artifacts\tooling\android_debug.apk'
if (-not (Test-Path -LiteralPath $template)) {
    throw 'Missing Android debug template. Follow SETUP.md to prepare artifacts/tooling/android_debug.apk.'
}
$outputDirectory = Join-Path $projectRoot 'exports\android'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
Invoke-PrismazeGodot $engine @('--headless', '--path', $projectRoot, '--editor', '--import') (Join-Path $outputDirectory 'import.log') ''
$apk = Join-Path $outputDirectory 'prismaze-debug.apk'
Invoke-PrismazeGodot $engine @('--headless', '--path', $projectRoot, '--export-debug', 'Android Debug', $apk) (Join-Path $outputDirectory 'export.log') ''
if (-not (Test-Path -LiteralPath $apk)) { throw 'APK output was not created.' }
Get-Item -LiteralPath $apk | Select-Object FullName, Length
