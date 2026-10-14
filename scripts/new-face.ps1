# Create faces/<Face>/app from template/ with a fresh app id and display name.
#   .\scripts\new-face.ps1 16-example "Example"
param(
    [Parameter(Mandatory = $true)][string]$Face,
    [Parameter(Mandatory = $true)][string]$Name
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$appDir = Join-Path $RepoRoot "faces\$Face\app"
if (Test-Path $appDir) { throw "すでにあります：$appDir" }
New-Item -ItemType Directory -Force $appDir | Out-Null

$template = Join-Path $RepoRoot 'template'
foreach ($item in 'manifest.xml', 'monkey.jungle', 'source', 'resources') {
    Copy-Item -Recurse (Join-Path $template $item) $appDir
}

$utf8 = New-Object Text.UTF8Encoding $false
$manifest = Join-Path $appDir 'manifest.xml'
$id = [guid]::NewGuid().ToString('N')
$xml = [IO.File]::ReadAllText($manifest) -replace 'application id="[0-9a-f]{32}"', "application id=`"$id`""
[IO.File]::WriteAllText($manifest, $xml, $utf8)

$strings = Join-Path $appDir 'resources\strings\strings.xml'
$s = [IO.File]::ReadAllText($strings) -replace '<string id="AppName">[^<]*</string>', "<string id=`"AppName`">$Name</string>"
[IO.File]::WriteAllText($strings, $s, $utf8)

Write-Host "作成：$appDir（app id $id）"
