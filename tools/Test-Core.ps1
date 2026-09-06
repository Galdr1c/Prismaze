$ErrorActionPreference = 'Stop'
$project = Join-Path (Split-Path $PSScriptRoot -Parent) 'Tests\Core\CoreTests.csproj'
dotnet run --project $project --configuration Release
if ($LASTEXITCODE -ne 0) { throw 'Prismaze C# core tests failed.' }
