param(
    [string]$UnityPath = 'D:\Unity\6000.3.17f1\Editor\Unity.exe',
    [string]$SdkPath = "$env:LOCALAPPDATA\Android\Sdk",
    [string]$NdkPath = 'D:\Unity\Toolchains\android-ndk-r27c',
    [string]$JdkPath = 'C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot',
    [string]$GradleCachePath = 'D:\Unity\Caches\Gradle'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$editorRoot = Split-Path $UnityPath -Parent
foreach ($required in @($UnityPath, "$editorRoot\Data\PlaybackEngines\AndroidPlayer", "$SdkPath\platform-tools\adb.exe", "$SdkPath\platforms\android-36\android.jar", "$NdkPath\source.properties", "$JdkPath\bin\java.exe")) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing Android build dependency: $required" }
}
if (-not (Select-String -LiteralPath "$NdkPath\source.properties" -Pattern '27\.2\.12479018' -Quiet)) { throw 'Unity 6000.3.17f1 requires NDK r27c (27.2.12479018).' }
$logs = Join-Path $projectRoot 'artifacts\unity'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$log = Join-Path $logs 'android-build.log'
$oldSdk=$env:PRISMAZE_ANDROID_SDK; $oldNdk=$env:PRISMAZE_ANDROID_NDK; $oldJdk=$env:PRISMAZE_ANDROID_JDK
$oldGradle=$env:GRADLE_USER_HOME
try {
    $env:PRISMAZE_ANDROID_SDK=$SdkPath
    $env:PRISMAZE_ANDROID_NDK=$NdkPath
    $env:PRISMAZE_ANDROID_JDK=$JdkPath
    New-Item -ItemType Directory -Path $GradleCachePath -Force | Out-Null
    $env:GRADLE_USER_HOME=$GradleCachePath
    $process=Start-Process -FilePath $UnityPath -ArgumentList "-batchmode -nographics -quit -buildTarget Android -projectPath `"$projectRoot`" -executeMethod Prismaze.Unity.Editor.ProjectSetup.BuildAndroid -logFile `"$log`"" -WindowStyle Hidden -PassThru
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "Unity Android build failed (exit $($process.ExitCode)). See $log" }
} finally {
    $env:PRISMAZE_ANDROID_SDK=$oldSdk; $env:PRISMAZE_ANDROID_NDK=$oldNdk; $env:PRISMAZE_ANDROID_JDK=$oldJdk
    $env:GRADLE_USER_HOME=$oldGradle
}
$apk=Join-Path $projectRoot 'Builds\Android\Prismaze-dev.apk'
if (-not (Test-Path -LiteralPath $apk)) { throw 'Unity returned without producing the APK.' }
$aapt=Join-Path $SdkPath 'build-tools\36.0.0\aapt.exe'
$permissions=& $aapt dump permissions $apk
if ($LASTEXITCODE -ne 0) { throw 'APK permissions could not be inspected.' }
$permissions | Tee-Object -FilePath (Join-Path $logs 'android-permissions.txt')
if (($permissions -join "`n") -match 'android.permission.(INTERNET|ACCESS_NETWORK_STATE|ACCESS_WIFI_STATE)') {
    throw 'Offline APK validation failed: unexpected networking permission.'
}
Get-Item -LiteralPath $apk | Select-Object FullName,Length
Get-FileHash -LiteralPath $apk -Algorithm SHA256
