# Shared helpers for the build / simulator scripts.

$RepoRoot = Split-Path -Parent $PSScriptRoot
$CiqHome = Join-Path $env:APPDATA 'Garmin\ConnectIQ'

# SDK chosen in the Connect IQ SDK Manager.
function Get-SdkPath {
    $cfg = Join-Path $CiqHome 'current-sdk.cfg'
    if (-not (Test-Path $cfg)) { throw "SDK が見つかりません。SDK Manager で SDK を入れてください（$cfg がありません）。" }
    return (Get-Content $cfg -Raw).Trim().TrimEnd('\')
}

# Developer key. Kept outside the repository; override with $env:GARMIN_DEV_KEY.
function Get-DeveloperKey {
    $key = if ($env:GARMIN_DEV_KEY) { $env:GARMIN_DEV_KEY } else { Join-Path $CiqHome 'developer_key.der' }
    if (-not (Test-Path $key)) { throw "開発者キーが見つかりません：$key" }
    return $key
}

# "template" or a folder name under faces/ -> the Connect IQ project folder.
function Get-AppDir([string]$Face) {
    if ($Face -eq 'template') { return Join-Path $RepoRoot 'template' }
    $dir = Join-Path $RepoRoot "faces\$Face\app"
    if (-not (Test-Path (Join-Path $dir 'manifest.xml'))) { throw "アプリが見つかりません：$dir" }
    return $dir
}

function Get-PrgPath([string]$Face) {
    return Join-Path (Get-AppDir $Face) "bin\$Face.prg"
}
