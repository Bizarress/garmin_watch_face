# N°01 LIFE QUEST: 相棒の 5 つの姿（王冠なし・あり）と常時表示を、状態を固定したビルドで 1 つずつ
# シミュレーターに読み込んで撮り、mock/sim-states.png に並べる。シミュレーターは起動しておく。
#   .\faces\01-life-quest\tools\sim_states.ps1
# 確かめられるのは「各状態の絵」まで。どの条件で切り替わるかは実機で確かめる。
param([string]$Work = (Join-Path $env:TEMP 'life-quest-states'))
$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
. (Join-Path $repo 'scripts\common.ps1')
$sdk = Get-SdkPath
$key = Get-DeveloperKey

python -I (Join-Path $PSScriptRoot 'sim_states.py') variants "$Work\variants" | Out-Null
if ($LASTEXITCODE -ne 0) { throw '状態を固定したコピーを作れませんでした' }
New-Item -ItemType Directory -Force "$Work\shots" | Out-Null

foreach ($dir in Get-ChildItem "$Work\variants" -Directory) {
    $n = $dir.Name
    $prg = "$($dir.FullName)\bin\lq.prg"
    New-Item -ItemType Directory -Force (Split-Path $prg) | Out-Null
    $ErrorActionPreference = 'Continue'
    $log = & (Join-Path $sdk 'bin\monkeyc.bat') -d vivoactive5 -f "$($dir.FullName)\monkey.jungle" -o $prg -y $key -w -l 2 2>&1 | ForEach-Object { "$_" }
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0) { $log; throw "ビルドに失敗しました：$n" }
    # monkeydo は終わらないことがあるので、読み込みを待って撮ったら止める。
    $p = Start-Process -FilePath (Join-Path $sdk 'bin\monkeydo.bat') -ArgumentList "`"$prg`"", 'vivoactive5' `
        -RedirectStandardOutput "$Work\shots\$n.out.txt" -RedirectStandardError "$Work\shots\$n.err.txt" -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 6
    & (Join-Path $repo 'scripts\capture-sim.ps1') "$Work\shots\$n.png" -X 92 -Y 277 -W 420 -H 420 | Out-Null
    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
    $out = (Get-Content "$Work\shots\$n.out.txt" -Raw) -replace '\s+', ' '
    "$n  $out"
}
python -I (Join-Path $PSScriptRoot 'sim_states.py') sheet "$Work\shots" (Join-Path $PSScriptRoot '..\mock\sim-states.png')
