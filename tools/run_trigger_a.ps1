[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$DailyScreenerCsv,

  [ValidateSet('dry-run')]
  [string]$Mode = 'dry-run'
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')

function Assert-RequiredProperty([object]$Object, [string]$Name) {
  if ($null -eq $Object.PSObject.Properties[$Name]) { throw "Watchlist manifest missing '$Name'." }
}

function ConvertTo-CanonicalSymbol([object]$Value, [string]$Context) {
  if ($null -eq $Value) { throw "$Context symbol is missing." }
  $symbol = ([string]$Value).Trim().ToUpperInvariant()
  if ([string]::IsNullOrWhiteSpace($symbol)) { throw "$Context symbol is empty." }
  if ($symbol -cnotmatch '^[A-Z][A-Z0-9]*(\.[A-Z0-9]+)?$') {
    throw "$Context symbol is invalid: '$symbol'."
  }
  return $symbol
}

function Get-PreviewBytes([string]$Text) {
  $encoding = New-Object System.Text.UTF8Encoding($true)
  return [byte[]]($encoding.GetPreamble() + $encoding.GetBytes($Text))
}

function Get-ByteArraySha256([byte[]]$Bytes) {
  $algorithm = [System.Security.Cryptography.SHA256]::Create()
  try { return [System.BitConverter]::ToString($algorithm.ComputeHash($Bytes)).Replace('-', '') }
  finally { $algorithm.Dispose() }
}

if ($Mode -cne 'dry-run') { throw 'Trigger A v1 supports dry-run mode only.' }

$DailyScreenerCsv = Assert-AplNoReparsePath -Path $DailyScreenerCsv -AllowedRoot $ProjectRoot -RequireFile
$outputsRoot = Join-Path $ProjectRoot 'outputs'
$archiveRoot = Join-Path $ProjectRoot 'Archive'
if ((Test-AplPathInside $DailyScreenerCsv $outputsRoot) -or (Test-AplPathInside $DailyScreenerCsv $archiveRoot)) {
  throw 'Daily Screener CSV must not be sourced from outputs or Archive.'
}

$fileNameMatch = [regex]::Match(
  (Split-Path $DailyScreenerCsv -Leaf),
  '^APL Breakout Screener_(\d{4}-\d{2}-\d{2})(?:_[^\\/:*?"<>|]+)?\.csv$',
  [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
if (-not $fileNameMatch.Success) { throw 'Daily Screener CSV filename does not match an approved Trigger A form.' }
$scanDate = $fileNameMatch.Groups[1].Value
$scanDateValue = Assert-AplScanDate $scanDate

$watchlistRoot = Join-Path $ProjectRoot 'Assets\ReferenceData\Watchlists'
$watchlistRoot = Assert-AplNoReparsePath -Path $watchlistRoot -AllowedRoot $ProjectRoot -RequireDirectory
$canonicalPath = Assert-AplNoReparsePath -Path (Join-Path $watchlistRoot 'APL_Quant_Cumulative_Watchlist.txt') -AllowedRoot $watchlistRoot -RequireFile
$manifestPath = Assert-AplNoReparsePath -Path (Join-Path $watchlistRoot 'watchlist-manifest.json') -AllowedRoot $watchlistRoot -RequireFile

$canonicalHashBefore = (Get-FileHash -LiteralPath $canonicalPath -Algorithm SHA256).Hash
$canonicalBytesBefore = (Get-Item -LiteralPath $canonicalPath).Length
$manifestHashBefore = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
$manifestBytesBefore = (Get-Item -LiteralPath $manifestPath).Length

$manifest = Read-AplStrictJson $manifestPath $watchlistRoot
foreach ($propertyName in @('SchemaVersion','AsOfDate','File','SymbolCount','Bytes','SHA256','SourceArchivePath','UpdatedUtc')) {
  Assert-RequiredProperty $manifest $propertyName
}
if ([string]$manifest.SchemaVersion -cne 'APL Cumulative Watchlist Manifest v1.0') {
  throw "Unsupported watchlist manifest SchemaVersion: $($manifest.SchemaVersion)"
}
if ([string]$manifest.File -cne 'APL_Quant_Cumulative_Watchlist.txt') { throw 'Watchlist manifest File is invalid.' }
$baselineDateValue = Assert-AplScanDate ([string]$manifest.AsOfDate)
if ($baselineDateValue -ge $scanDateValue) { throw 'Watchlist manifest AsOfDate must be earlier than the Daily Screener ScanDate.' }
if ([string]$manifest.SHA256 -cnotmatch '^[0-9A-F]{64}$') { throw 'Watchlist manifest SHA256 format is invalid.' }
if ([string]$manifest.SHA256 -cne $canonicalHashBefore) { throw 'Canonical watchlist SHA256 does not match manifest.' }
if ([long]$manifest.Bytes -ne $canonicalBytesBefore) { throw 'Canonical watchlist bytes do not match manifest.' }

$baselineText = [System.IO.File]::ReadAllText($canonicalPath, [System.Text.Encoding]::UTF8).Trim()
if ([string]::IsNullOrWhiteSpace($baselineText)) { throw 'Canonical watchlist is empty.' }
$baselineSymbols = New-Object System.Collections.Generic.List[string]
$baselineSeen = @{}
$baselineIndex = 0
foreach ($value in @($baselineText -split ',')) {
  $baselineIndex++
  $symbol = ConvertTo-CanonicalSymbol $value "Canonical baseline record $baselineIndex"
  if ($baselineSeen.ContainsKey($symbol)) { throw "Canonical watchlist contains duplicate symbol '$symbol'." }
  $baselineSeen[$symbol] = $true
  [void]$baselineSymbols.Add($symbol)
}
if ($baselineSymbols.Count -ne [int]$manifest.SymbolCount) { throw 'Canonical watchlist symbol count does not match manifest.' }

$dailyRows = @(Import-Csv -LiteralPath $DailyScreenerCsv -Encoding UTF8)
if ($dailyRows.Count -eq 0) { throw 'Daily Screener CSV contains no data rows.' }
$symbolColumns = @($dailyRows[0].PSObject.Properties.Name | Where-Object { [string]$_ -ceq 'Symbol' })
if ($symbolColumns.Count -ne 1) { throw 'Daily Screener CSV must contain exactly one Symbol column.' }

$dailySymbols = New-Object System.Collections.Generic.List[string]
$dailySeen = @{}
$dailyRowNumber = 1
foreach ($row in $dailyRows) {
  $dailyRowNumber++
  $symbol = ConvertTo-CanonicalSymbol $row.Symbol "Daily Screener row $dailyRowNumber"
  if (-not $dailySeen.ContainsKey($symbol)) {
    $dailySeen[$symbol] = $true
    [void]$dailySymbols.Add($symbol)
  }
}

$mergedSymbols = New-Object System.Collections.Generic.List[string]
$mergedSeen = @{}
foreach ($symbol in $baselineSymbols) {
  $mergedSeen[$symbol] = $true
  [void]$mergedSymbols.Add($symbol)
}
$addedSymbols = New-Object System.Collections.Generic.List[string]
foreach ($symbol in $dailySymbols) {
  if (-not $mergedSeen.ContainsKey($symbol)) {
    $mergedSeen[$symbol] = $true
    [void]$mergedSymbols.Add($symbol)
    [void]$addedSymbols.Add($symbol)
  }
}

if ($mergedSymbols.Count -ne ($baselineSymbols.Count + $addedSymbols.Count)) { throw 'Trigger A merge count invariant failed.' }
foreach ($symbol in $baselineSymbols) {
  if (-not $mergedSeen.ContainsKey($symbol)) { throw "Trigger A attempted to delete canonical symbol '$symbol'." }
}

$previewText = ($mergedSymbols.ToArray() -join ',') + "`r`n"
$previewBytes = Get-PreviewBytes $previewText
$previewSha256 = Get-ByteArraySha256 $previewBytes

$canonicalHashAfter = (Get-FileHash -LiteralPath $canonicalPath -Algorithm SHA256).Hash
$canonicalBytesAfter = (Get-Item -LiteralPath $canonicalPath).Length
$manifestHashAfter = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
$manifestBytesAfter = (Get-Item -LiteralPath $manifestPath).Length
if ($canonicalHashBefore -cne $canonicalHashAfter -or $canonicalBytesBefore -ne $canonicalBytesAfter) {
  throw 'Canonical watchlist changed during dry-run.'
}
if ($manifestHashBefore -cne $manifestHashAfter -or $manifestBytesBefore -ne $manifestBytesAfter) {
  throw 'Watchlist manifest changed during dry-run.'
}

[pscustomobject]@{
  Status = 'DRY_RUN_PASS'
  Mode = $Mode
  ScanDate = $scanDate
  DailyScreenerCsv = $DailyScreenerCsv
  CanonicalWatchlist = $canonicalPath
  Manifest = $manifestPath
  BaselineAsOfDate = [string]$manifest.AsOfDate
  BaselineSymbolCount = $baselineSymbols.Count
  DailyRowCount = $dailyRows.Count
  DailyUniqueSymbolCount = $dailySymbols.Count
  AddedSymbolCount = $addedSymbols.Count
  AddedSymbols = [object[]]$addedSymbols.ToArray()
  FinalSymbolCount = $mergedSymbols.Count
  PreviewBytes = $previewBytes.Length
  PreviewSHA256 = $previewSha256
  CanonicalWouldChange = ($addedSymbols.Count -gt 0)
  WritesPerformed = $false
  CanonicalUpdated = $false
  ManifestUpdated = $false
}
