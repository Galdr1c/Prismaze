Set-StrictMode -Version Latest

function Find-PrismazeGodot {
    param([string]$GodotPath)
    if ($GodotPath) {
        if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
            throw "Godot executable not found: $GodotPath"
        }
        return (Resolve-Path -LiteralPath $GodotPath).Path
    }
    if ($env:GODOT_BIN) { return Find-PrismazeGodot $env:GODOT_BIN }
    $packages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $installed = Get-ChildItem -Path "$packages\GodotEngine.GodotEngine_*\Godot*_console.exe" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($installed) { return $installed.FullName }
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    throw 'Godot not found. Pass -GodotPath or set GODOT_BIN.'
}

function Invoke-PrismazeGodot {
    param([string]$Executable, [string[]]$Arguments, [string]$LogPath, [string]$Expected)
    $output = & $Executable @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $output | Tee-Object -FilePath $LogPath | ForEach-Object { Write-Host $_ }
    $text = $output -join "`n"
    if ($exitCode -ne 0 -or $text -match '(?m)^(SCRIPT ERROR:|ERROR:|FAIL:|WARNING: .*leaked)') {
        throw "Godot failed (exit $exitCode). See $LogPath"
    }
    if ($Expected -and $text -notmatch [regex]::Escape($Expected)) {
        throw "Godot did not complete the expected checks. See $LogPath"
    }
}
