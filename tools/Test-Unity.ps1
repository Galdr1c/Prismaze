param([string]$UnityPath = 'D:\Unity\6000.3.17f1\Editor\Unity.exe')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $UnityPath)) { throw 'Unity Editor not found. Pass -UnityPath or install the pinned editor via Unity Hub.' }
$project = Split-Path $PSScriptRoot -Parent
$logs = Join-Path $project 'artifacts\unity'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$prepareLog = Join-Path $logs 'prepare.log'
$testLog = Join-Path $logs 'editmode.log'
$testResults = Join-Path $logs 'editmode.xml'
$process = Start-Process -FilePath $UnityPath -ArgumentList "-batchmode -nographics -quit -projectPath `"$project`" -executeMethod Prismaze.Unity.Editor.ProjectSetup.Prepare -logFile `"$prepareLog`"" -WindowStyle Hidden -PassThru
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw 'Unity preparation failed. Check artifacts/unity/prepare.log (including licence and package restore errors).' }
$process = Start-Process -FilePath $UnityPath -ArgumentList "-batchmode -nographics -projectPath `"$project`" -runTests -testPlatform EditMode -testResults `"$testResults`" -logFile `"$testLog`"" -WindowStyle Hidden -PassThru
$process.WaitForExit()
if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $testResults)) { throw 'Unity EditMode tests did not complete successfully.' }
[xml]$results = Get-Content -Raw (Join-Path $logs 'editmode.xml')
if ($results.'test-run'.result -ne 'Passed') { throw 'Unity EditMode tests failed; inspect artifacts/unity/editmode.xml.' }
$playResults = Join-Path $logs 'playmode.xml'
$playLog = Join-Path $logs 'playmode.log'
$process = Start-Process -FilePath $UnityPath -ArgumentList "-batchmode -nographics -projectPath `"$project`" -runTests -testPlatform PlayMode -testResults `"$playResults`" -logFile `"$playLog`"" -WindowStyle Hidden -PassThru
$process.WaitForExit()
if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $playResults)) { throw 'Unity PlayMode tests did not complete successfully.' }
[xml]$play = Get-Content -Raw $playResults
if ($play.'test-run'.result -ne 'Passed') { throw 'Unity PlayMode tests failed; inspect artifacts/unity/playmode.xml.' }
Write-Host "Unity EditMode and PlayMode tests passed. Results: $logs"
