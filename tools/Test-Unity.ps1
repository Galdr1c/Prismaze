param([string]$UnityPath = 'D:\Unity\6000.3.17f1\Editor\Unity.exe')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $UnityPath)) { throw 'Unity Editor not found. Pass -UnityPath or install the pinned editor via Unity Hub.' }
$project = Split-Path $PSScriptRoot -Parent
$logs = Join-Path $project 'artifacts\unity'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
& $UnityPath -batchmode -nographics -quit -projectPath $project -executeMethod Prismaze.Unity.Editor.ProjectSetup.Prepare -logFile (Join-Path $logs 'prepare.log')
if ($LASTEXITCODE -ne 0) { throw 'Unity preparation failed. Check artifacts/unity/prepare.log (including licence and package restore errors).' }
& $UnityPath -batchmode -nographics -projectPath $project -runTests -testPlatform EditMode -testResults (Join-Path $logs 'editmode.xml') -logFile (Join-Path $logs 'editmode.log')
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $logs 'editmode.xml'))) { throw 'Unity EditMode tests did not complete successfully.' }
[xml]$results = Get-Content -Raw (Join-Path $logs 'editmode.xml')
if ($results.'test-run'.result -ne 'Passed') { throw 'Unity EditMode tests failed; inspect artifacts/unity/editmode.xml.' }
