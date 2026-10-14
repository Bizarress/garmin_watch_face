# Load a built watch face into the Connect IQ simulator (starts the simulator if needed).
#   .\scripts\build.ps1 01-life-quest; .\scripts\sim.ps1 01-life-quest
param(
    [Parameter(Mandatory = $true)][string]$Face,
    [string]$Device = 'vivoactive5'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$sdk = Get-SdkPath
$prg = Get-PrgPath $Face
if (-not (Test-Path $prg)) { throw "先にビルドしてください：.\scripts\build.ps1 $Face" }

if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) {
    Start-Process (Join-Path $sdk 'bin\simulator.exe')
    Start-Sleep -Seconds 5
}
& (Join-Path $sdk 'bin\monkeydo.bat') $prg $Device
