param(
  [Parameter(Mandatory = $true)]
  [string]$InputSvg,

  [Parameter(Mandatory = $true)]
  [string]$OutputPng,

  [int]$Width = 1920,
  [int]$Height = 1080,
  [string]$BrowserPath = '',
  [switch]$RegressionTest
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')

$InputSvg = Assert-AplProductionPath (Get-AplFullPath $InputSvg) 'InputSvg' -RegressionTest:$RegressionTest
$OutputPng = Assert-AplProductionPath (Get-AplFullPath $OutputPng) 'OutputPng' -RegressionTest:$RegressionTest
if (!(Test-Path -LiteralPath $InputSvg -PathType Leaf)) { throw "InputSvg not found: $InputSvg" }
if ([System.IO.Path]::GetExtension($InputSvg) -ine '.svg') { throw 'InputSvg must use .svg.' }
if ([System.IO.Path]::GetExtension($OutputPng) -ine '.png') { throw 'OutputPng must use .png.' }
if (Test-Path -LiteralPath $OutputPng) { throw "OutputPng already exists; converter will not overwrite it: $OutputPng" }
if ($Width -le 0 -or $Height -le 0) { throw 'Width and Height must be positive integers.' }

if ([string]::IsNullOrWhiteSpace($BrowserPath)) {
  $browserCandidates = @(
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
  )
  $detectedBrowser = $browserCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
  if ($null -ne $detectedBrowser) { $BrowserPath = [string]$detectedBrowser }
}
if ([string]::IsNullOrWhiteSpace([string]$BrowserPath) -or !(Test-Path -LiteralPath $BrowserPath -PathType Leaf)) { throw 'Microsoft Edge or Google Chrome executable not found. Use -BrowserPath to provide an approved Chromium browser.' }

$outputDir = [System.IO.Path]::GetFullPath((Split-Path -Parent $OutputPng)).TrimEnd('\')
if (!(Test-Path -LiteralPath $outputDir -PathType Container)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }
$profileDir = [System.IO.Path]::GetFullPath((Join-Path $outputDir ('.svg-export-profile-' + [guid]::NewGuid().ToString('N'))))
if (-not $profileDir.StartsWith($outputDir + '\', [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Browser profile path escaped OutputPng directory.' }
$inputUri = ([System.Uri]::new($InputSvg)).AbsoluteUri

try {
  New-Item -ItemType Directory -Path $profileDir | Out-Null
  $arguments = @(
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--force-device-scale-factor=1',
    '--run-all-compositor-stages-before-draw',
    '--virtual-time-budget=2000',
    "--window-size=$Width,$Height",
    ('--user-data-dir="{0}"' -f $profileDir),
    ('--screenshot="{0}"' -f $OutputPng),
    $inputUri
  )
  $process = Start-Process -FilePath $BrowserPath -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
  if ($process.ExitCode -ne 0) { throw "Chromium SVG export failed with exit code $($process.ExitCode)." }
  if (!(Test-Path -LiteralPath $OutputPng -PathType Leaf)) { throw "Chromium SVG export did not create OutputPng: $OutputPng" }
  if ((Get-Item -LiteralPath $OutputPng).Length -le 0) { throw "Chromium SVG export created an empty OutputPng: $OutputPng" }
  Add-Type -AssemblyName System.Drawing
  $image = [System.Drawing.Image]::FromFile($OutputPng)
  try {
    if ($image.Width -ne $Width -or $image.Height -ne $Height) { throw "OutputPng dimensions mismatch. Expected=${Width}x${Height}; Actual=$($image.Width)x$($image.Height)." }
  } finally {
    $image.Dispose()
  }
} catch {
  if (Test-Path -LiteralPath $OutputPng -PathType Leaf) { Remove-Item -LiteralPath $OutputPng -Force }
  throw
} finally {
  if (Test-Path -LiteralPath $profileDir -PathType Container) {
    $verifiedProfile = [System.IO.Path]::GetFullPath($profileDir)
    if ($verifiedProfile.StartsWith($outputDir + '\', [System.StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $verifiedProfile -Recurse -Force }
  }
}

[pscustomobject]@{
  Status = 'PASS'
  InputSvg = $InputSvg
  OutputPng = $OutputPng
  Width = $Width
  Height = $Height
  Bytes = (Get-Item -LiteralPath $OutputPng).Length
  Sha256 = (Get-FileHash -LiteralPath $OutputPng -Algorithm SHA256).Hash
  Browser = $BrowserPath
}
