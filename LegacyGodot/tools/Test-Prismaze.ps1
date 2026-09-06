param([string]$GodotPath, [switch]$Render)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Godot-Tools.ps1')
$projectRoot = Split-Path $PSScriptRoot -Parent
$engine = Find-PrismazeGodot $GodotPath
$runDirectory = Join-Path $projectRoot ('artifacts\tests\' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null

Invoke-PrismazeGodot $engine @('--headless', '--path', $projectRoot, '--editor', '--import') (Join-Path $runDirectory 'import.log') ''
$suites = @(
    @{ Script = 'res://tests/test_runner.gd'; Name = 'core'; Marker = 'Checks:' },
    @{ Script = 'res://tests/integration/audio_lifecycle.gd'; Name = 'audio'; Marker = 'Audio checks:' },
    @{ Script = 'res://tests/integration/ui_smoke.gd'; Name = 'ui'; Marker = 'UI checks:' },
    @{ Script = 'res://tests/integration/touch_smoke.gd'; Name = 'touch'; Marker = 'Touch checks:' },
    @{ Script = 'res://tests/integration/normal_close.gd'; Name = 'close'; Marker = 'Normal close requested during startup audio' }
)
foreach ($suite in $suites) {
    $arguments = @('--path', $projectRoot, '--script', $suite.Script, '--quit-after', '3600', '--max-fps', '120')
    if (-not ($Render -and $suite.Name -eq 'ui')) { $arguments += '--headless' }
    $arguments += @('--', ('--save-dir=' + (Join-Path $runDirectory $suite.Name).Replace('\', '/')))
    if ($suite.Name -eq 'touch') { $arguments += '--silent' }
    Invoke-PrismazeGodot $engine $arguments (Join-Path $runDirectory ($suite.Name + '.log')) $suite.Marker
}
Write-Host "All Prismaze tests passed. Logs: $runDirectory"
