param(
  [Parameter(Mandatory=$true)][string]$InputSvg,
  [Parameter(Mandatory=$true)][string]$OutputPng,
  [int]$Width=1920,
  [int]$Height=1080,
  [ValidateSet('Auto','Resvg','Chromium')][string]$Renderer='Auto',
  [string]$RendererPath='',
  [switch]$RegressionTest
)

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')

function Remove-PartialOutput([string]$Path) {
  if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue }
}
function Get-RepositoryDashboardFontAudit {
  $manifestPath = Join-Path $script:AplProjectRoot 'tools\font-manifest.json'
  if (!(Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Repository font manifest is missing: $manifestPath" }
  $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $fonts = @($manifest.Fonts | Where-Object { @($_.requiredFor) -contains 'Dashboard' })
  if ($fonts.Count -lt 6) { throw 'Dashboard font manifest must contain the six required Alibaba Sans HK and Montserrat font assets.' }
  foreach ($font in $fonts) {
    $fontPath = Join-Path $script:AplProjectRoot ([string]$font.file)
    if (!(Test-Path -LiteralPath $fontPath -PathType Leaf)) { throw "Repository font asset is missing: $($font.file)" }
    if ((Get-FileHash -LiteralPath $fontPath -Algorithm SHA256).Hash -cne [string]$font.sha256) { throw "Repository font SHA-256 mismatch: $($font.file)" }
  }
  return @($fonts | Select-Object logicalName,file,internalFamily,weight,style)
}

$InputSvg=Assert-AplProductionPath (Get-AplFullPath $InputSvg) 'InputSvg' -RegressionTest:$RegressionTest
$OutputPng=Assert-AplProductionPath (Get-AplFullPath $OutputPng) 'OutputPng' -RegressionTest:$RegressionTest
if((!(Test-Path -LiteralPath $InputSvg -PathType Leaf)) -or ([IO.Path]::GetExtension($InputSvg) -ine '.svg')) { throw 'InputSvg must be an existing .svg file.' }
if(([IO.Path]::GetExtension($OutputPng) -ine '.png') -or (Test-Path -LiteralPath $OutputPng)) { throw 'OutputPng must be a new .png path.' }
if($Width -le 0 -or $Height -le 0) { throw 'Width and Height must be positive.' }
if($Renderer -eq 'Chromium') { throw 'Chromium is optional only and is disabled by this browser-independent policy. Specify a validated renderer.' }

$resvg=if($RendererPath){Get-AplFullPath $RendererPath}else{Join-Path $PSScriptRoot 'renderers\resvg\resvg.exe'}
if(!(Test-Path -LiteralPath $resvg -PathType Leaf)) { throw "resvg renderer not found: $resvg" }
$fontAudit = Get-RepositoryDashboardFontAudit
$fontDirectory = Join-Path $script:AplProjectRoot 'Assets\Fonts'
$dir=[IO.Path]::GetFullPath((Split-Path $OutputPng -Parent))
if(!(Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

$started=[datetime]::UtcNow
$output=@()
$exit=$null
$previousErrorAction=$ErrorActionPreference
try {
  $ErrorActionPreference='Continue'
  $output=@(& $resvg $InputSvg $OutputPng -w $Width -h $Height --use-fonts-dir $fontDirectory --skip-system-fonts 2>&1)
  $exit=$LASTEXITCODE
} finally {
  $ErrorActionPreference=$previousErrorAction
}

$rendererLog = @($output | ForEach-Object { [string]$_ })
$fontFallbackCount = @($rendererLog | Where-Object { $_ -match '(?i)fallback\s+(?:from|font)|font\s+fallback|using\s+fallback|no\s+fonts?\s+with|no\s+match\s+for.*font-family' }).Count
$invalidGeometryCount = @($rendererLog | Where-Object { $_ -match '(?i)invalid.*(?:width|height|geometry)|failed\s+to\s+parse\s+(?:width|height)' }).Count
if($exit -ne 0) {
  Remove-PartialOutput $OutputPng
  throw "resvg export failed with exit code $exit. $($rendererLog -join ' ')"
}
if($fontFallbackCount -gt 0 -or $invalidGeometryCount -gt 0) {
  Remove-PartialOutput $OutputPng
  throw "resvg quality gate failed: FontFallbackWarningCount=$fontFallbackCount; InvalidGeometryWarningCount=$invalidGeometryCount. $($rendererLog -join ' ')"
}
if(!(Test-Path -LiteralPath $OutputPng) -or (Get-Item -LiteralPath $OutputPng).Length -le 0) {
  Remove-PartialOutput $OutputPng
  throw 'resvg did not create a non-empty PNG.'
}
if((Get-Item -LiteralPath $OutputPng).LastWriteTimeUtc -lt $started) {
  Remove-PartialOutput $OutputPng
  throw 'PNG is stale: output timestamp predates this export.'
}
$bytes=[IO.File]::ReadAllBytes($OutputPng)
if($bytes.Length -lt 8 -or (($bytes[0..7] | ForEach-Object {$_.ToString('X2')}) -join '') -cne '89504E470D0A1A0A') {
  Remove-PartialOutput $OutputPng
  throw 'PNG magic bytes are invalid.'
}
Add-Type -AssemblyName System.Drawing
$image=$null
try {
  $image=[Drawing.Image]::FromFile($OutputPng)
  if($image.Width -ne $Width -or $image.Height -ne $Height) { throw "PNG dimensions mismatch: $($image.Width)x$($image.Height)" }
} catch {
  Remove-PartialOutput $OutputPng
  throw
} finally {
  if($null -ne $image) { $image.Dispose() }
}

[pscustomobject]@{
  Status='PASS'; Renderer='resvg'; RendererPath=$resvg; RendererVersion=((& $resvg --version 2>$null)-join ' ')
  InputSvg=$InputSvg; OutputPng=$OutputPng; Width=$Width; Height=$Height; Bytes=(Get-Item -LiteralPath $OutputPng).Length
  Sha256=(Get-FileHash -LiteralPath $OutputPng -Algorithm SHA256).Hash; ExitCode=$exit; StdErrStdOut=($rendererLog -join [Environment]::NewLine)
  RequestedFontFamilies=@('Alibaba Sans HK (400/600)','Montserrat (400/500/600/700)'); RepositoryFontAssets=$fontAudit
  ResolvedFontPolicy='resvg --use-fonts-dir Assets/Fonts --skip-system-fonts; zero fallback warnings required'
  FontFallbackWarningCount=$fontFallbackCount; InvalidGeometryWarningCount=$invalidGeometryCount
  StartedUtc=$started.ToString('o'); FinishedUtc=[datetime]::UtcNow.ToString('o')
}
