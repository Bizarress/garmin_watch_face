# Build one watch face into faces/<Face>/app/bin/<Face>.prg.
#   .\scripts\build.ps1 01-life-quest
#   .\scripts\build.ps1 template
param(
    [Parameter(Mandatory = $true)][string]$Face,
    [string]$Device = 'vivoactive5'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$sdk = Get-SdkPath
$appDir = Get-AppDir $Face
$prg = Get-PrgPath $Face
New-Item -ItemType Directory -Force (Split-Path $prg) | Out-Null

# monkeyc prints warnings on stderr; keep them as output instead of terminating errors.
$key = Get-DeveloperKey
$ErrorActionPreference = 'Continue'
& (Join-Path $sdk 'bin\monkeyc.bat') -d $Device -f (Join-Path $appDir 'monkey.jungle') -o $prg -y $key -w -l 2 2>&1 | ForEach-Object { "$_" }
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { throw "ビルドに失敗しました：$Face" }
Write-Host "出力：$prg"
