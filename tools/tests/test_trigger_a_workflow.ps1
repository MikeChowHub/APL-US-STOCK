[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'tmp'))
$runRoot = Join-Path $tmpRoot ('trigger-a-workflow-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$script:checks = 0
$script:failures = New-Object System.Collections.Generic.List[string]

function Check([bool]$Condition, [string]$Name) {
  $script:checks++
  if ($Condition) { Write-Output ('PASS: ' + $Name) }
  else { [void]$script:failures.Add($Name); Write-Output ('FAIL: ' + $Name) }
}

function FileHash([string]$Path) {
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Write-Utf8([string]$Path, [string]$Text, [bool]$Bom = $false) {
  $encoding = New-Object System.Text.UTF8Encoding($Bom)
  [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function New-Fixture([string]$Name) {
  $root = Join-Path $runRoot $Name
  $tools = Join-Path $root 'tools'
  $assets = Join-Path $root 'Assets\ReferenceData\Watchlists'
  $inputs = Join-Path $root 'inputs'
  foreach ($directory in @($tools, $assets, $inputs)) {
    [void][System.IO.Directory]::CreateDirectory($directory)
  }
  foreach ($leaf in @('run_trigger_a.ps1', 'production_archive_common.ps1')) {
    Copy-Item -LiteralPath (Join-Path $repoRoot ('tools\' + $leaf)) -Destination (Join-Path $tools $leaf)
  }
  $canonical = Join-Path $assets 'APL_Quant_Cumulative_Watchlist.txt'
  $manifest = Join-Path $assets 'watchlist-manifest.json'
  Write-Utf8 $canonical "AAPL,MSFT,MOG.A`r`n" $true
  $metadata = [ordered]@{
    SchemaVersion = 'APL Cumulative Watchlist Manifest v1.0'
    AsOfDate = '2040-01-01'
    File = 'APL_Quant_Cumulative_Watchlist.txt'
    SymbolCount = 3
    Bytes = (Get-Item -LiteralPath $canonical).Length
    SHA256 = FileHash $canonical
    # This path deliberately does not exist: provenance is never a runtime input.
    SourceArchivePath = 'Archive/1999/01/1999-01-01/seed.txt'
    UpdatedUtc = '2040-01-01T01:00:00Z'
  }
  Write-Utf8 $manifest (($metadata | ConvertTo-Json -Depth 5) + "`n")
  return [pscustomobject]@{
    Root = $root
    Entry = Join-Path $tools 'run_trigger_a.ps1'
    Inputs = $inputs
    Canonical = $canonical
    Manifest = $manifest
    Outputs = Join-Path $root 'outputs\trigger-a'
  }
}

function Write-Daily([object]$Fixture, [string]$Date, [string[]]$Symbols) {
  $path = Join-Path $Fixture.Inputs ('APL Breakout Screener_' + $Date + '_fixture.csv')
  $rows = @('Symbol,Unused,Unused') + @($Symbols | ForEach-Object { $_ + ',one,two' })
  Write-Utf8 $path (($rows -join "`r`n") + "`r`n")
  return $path
}

function Invoke-Run([object]$Fixture, [string]$InputPath, [string]$Mode) {
  return (& $Fixture.Entry -DailyScreenerCsv $InputPath -Mode $Mode)
}

function Reject-Run([object]$Fixture, [string]$InputPath, [string]$Pattern, [string]$Name) {
  $rejected = $false
  $message = ''
  try { $null = Invoke-Run $Fixture $InputPath 'write-output' }
  catch { $rejected = $true; $message = $_.Exception.Message }
  Check ($rejected -and $message -match $Pattern) $Name
}

function Snapshot([object]$Fixture) {
  $lines = foreach ($item in @(Get-ChildItem -LiteralPath $Fixture.Root -Recurse -File | Sort-Object FullName)) {
    $relative = $item.FullName.Substring($Fixture.Root.Length)
    $relative + '|' + $item.Length + '|' + (FileHash $item.FullName)
  }
  return ($lines -join "`n")
}

if (-not $runRoot.StartsWith($tmpRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw 'Fixture path must stay inside the repository tmp directory.'
}

try {
  $fixture = New-Fixture 'main'
  $csv = Write-Daily $fixture '2040-01-02' @('NVDA', 'nvda', 'AAPL', 'TSLA')
  $initial = Snapshot $fixture
  $dry = Invoke-Run $fixture $csv 'dry-run'
  Check ($dry.Status -ceq 'DRY_RUN_PASS' -and $dry.BaselineSymbolCount -eq 3 -and
    $dry.DailyRowCount -eq 4 -and $dry.DailyUniqueSymbolCount -eq 3 -and
    $dry.AddedSymbolCount -eq 2 -and $dry.FinalSymbolCount -eq 5) 'Dry-run normalizes and deduplicates daily symbols with repeated nonessential headers'
  Check (($dry.AddedSymbols -join ',') -ceq 'NVDA,TSLA') 'New symbols retain their first appearance order'
  Check ((Snapshot $fixture) -ceq $initial -and -not (Test-Path -LiteralPath $fixture.Outputs) -and
    -not (Test-Path -LiteralPath (Join-Path $fixture.Root 'Archive'))) 'Dry-run does not write files or require outputs and Archive'

  $written = Invoke-Run $fixture $csv 'write-output'
  $output02 = Join-Path $fixture.Outputs 'APL_Quant_Cumulative_Watchlist_2040-01-02.txt'
  $metadata = Get-Content -LiteralPath $fixture.Manifest -Raw | ConvertFrom-Json
  Check ($written.Status -ceq 'WRITE_OUTPUT_PASS' -and $written.CanonicalUpdated -and $written.ManifestUpdated -and
    [System.IO.File]::ReadAllText($fixture.Canonical).Trim() -ceq 'AAPL,MSFT,MOG.A,NVDA,TSLA') 'First write promotes the complete accumulation without removing baseline symbols'
  Check ((Test-Path -LiteralPath $output02) -and -not (Test-Path -LiteralPath (Join-Path $fixture.Outputs '2040-01-02'))) 'Latest dated TXT is delivered directly under trigger-a'
  Check ($metadata.AsOfDate -ceq '2040-01-02' -and $metadata.SymbolCount -eq 5 -and
    $metadata.Bytes -eq (Get-Item -LiteralPath $fixture.Canonical).Length -and
    $metadata.SHA256 -ceq (FileHash $fixture.Canonical) -and
    (FileHash $output02) -ceq (FileHash $fixture.Canonical)) 'Delivery, canonical baseline, and manifest have matching counts, bytes, and SHA256'

  $sameDayBefore = Snapshot $fixture
  $rerun = Invoke-Run $fixture $csv 'write-output'
  Check ($rerun.Status -ceq 'WRITE_OUTPUT_PASS' -and $rerun.OutputAlreadyExisted -and
    -not $rerun.WritesPerformed -and -not $rerun.CanonicalUpdated -and -not $rerun.ManifestUpdated) 'Identical same-day rerun reports a verified no-op'
  Check ((Snapshot $fixture) -ceq $sameDayBefore) 'Identical same-day rerun preserves every fixture file including manifest bytes'

  $csvConflict = Write-Daily $fixture '2040-01-02' @('AMD')
  $conflictBefore = Snapshot $fixture
  Reject-Run $fixture $csvConflict 'Same-date Trigger A reruns' 'Same-day input that adds a new symbol is rejected'
  Check ((Snapshot $fixture) -ceq $conflictBefore) 'Same-day conflict preserves canonical, manifest, delivery, and input'

  $csv03 = Write-Daily $fixture '2040-01-03' @('ORCL', 'AAPL')
  $hash02 = FileHash $output02
  $next = Invoke-Run $fixture $csv03 'write-output'
  $output03 = Join-Path $fixture.Outputs 'APL_Quant_Cumulative_Watchlist_2040-01-03.txt'
  $archive02 = Join-Path $fixture.Outputs 'Archive\2040-01-02\APL_Quant_Cumulative_Watchlist_2040-01-02.txt'
  Check ($next.Status -ceq 'WRITE_OUTPUT_PASS' -and $next.AddedSymbolCount -eq 1 -and $next.FinalSymbolCount -eq 6 -and
    (Test-Path -LiteralPath $archive02) -and (FileHash $archive02) -ceq $hash02 -and
    -not (Test-Path -LiteralPath $output02)) 'Next-day publication preserves the previous delivery in its Archive date folder'
  $metadata03 = Get-Content -LiteralPath $fixture.Manifest -Raw | ConvertFrom-Json
  Check ((Test-Path -LiteralPath $output03) -and $metadata03.AsOfDate -ceq '2040-01-03' -and $metadata03.SymbolCount -eq 6 -and
    (FileHash $fixture.Canonical) -ceq (FileHash $output03) -and $metadata03.SHA256 -ceq (FileHash $output03)) 'Next-day delivery and promoted baseline remain consistent'

  $archive03Dir = Join-Path $fixture.Outputs 'Archive\2040-01-03'
  [void][System.IO.Directory]::CreateDirectory($archive03Dir)
  $archive03 = Join-Path $archive03Dir 'APL_Quant_Cumulative_Watchlist_2040-01-03.txt'
  Write-Utf8 $archive03 'CONFLICTING HISTORICAL CONTENT'
  $csv04 = Write-Daily $fixture '2040-01-04' @('INTC')
  $archiveConflictBefore = Snapshot $fixture
  Reject-Run $fixture $csv04 'Archive conflict' 'Conflicting existing Archive content blocks the next publication'
  Check ((Snapshot $fixture) -ceq $archiveConflictBefore) 'Archive conflict retains both historical content and the current delivery without promotion'

  $conflicting = New-Fixture 'conflict'
  $conflictingCsv = Write-Daily $conflicting '2040-01-02' @('NVDA')
  [void][System.IO.Directory]::CreateDirectory($conflicting.Outputs)
  $existingOutput = Join-Path $conflicting.Outputs 'APL_Quant_Cumulative_Watchlist_2040-01-02.txt'
  Write-Utf8 $existingOutput 'EXISTING OUTPUT CONTENT'
  $outputConflictBefore = Snapshot $conflicting
  Reject-Run $conflicting $conflictingCsv 'output already exists with different content' 'Existing conflicting output is rejected'
  Check ((Snapshot $conflicting) -ceq $outputConflictBefore) 'Existing output conflict does not overwrite either output or baseline'

  $rollback = New-Fixture 'rollback'
  $rollbackCsv = Write-Daily $rollback '2040-01-02' @('NVDA')
  $canonicalBefore = FileHash $rollback.Canonical
  $manifestBefore = FileHash $rollback.Manifest
  $manifestAttributes = [System.IO.File]::GetAttributes($rollback.Manifest)
  [System.IO.File]::SetAttributes($rollback.Manifest, ($manifestAttributes -bor [System.IO.FileAttributes]::ReadOnly))
  $rollbackRejected = $false
  try { $null = Invoke-Run $rollback $rollbackCsv 'write-output' }
  catch { $rollbackRejected = $true }
  finally { [System.IO.File]::SetAttributes($rollback.Manifest, $manifestAttributes) }
  Check ($rollbackRejected -and (FileHash $rollback.Canonical) -ceq $canonicalBefore -and
    (FileHash $rollback.Manifest) -ceq $manifestBefore) 'Failure replacing a read-only manifest rolls back canonical promotion'

  if ($script:failures.Count -gt 0) {
    throw ('Trigger A workflow regression failed: ' + ($script:failures -join '; '))
  }
  Write-Output ('PASS: ' + $script:checks + ' Trigger A workflow checks')
} finally {
  $resolved = [System.IO.Path]::GetFullPath($runRoot)
  if (-not $resolved.StartsWith($tmpRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing fixture cleanup outside the repository tmp directory.'
  }
  if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
