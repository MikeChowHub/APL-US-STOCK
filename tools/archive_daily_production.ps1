[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$SourceDatePath,
  [Parameter(Mandatory = $true)][string]$ScanDate,
  [Parameter(Mandatory = $true)][string]$FinalAuditPath,
  [string]$ArchiveRoot = '',
  [string]$ArchivePolicyPath = '',
  [switch]$RegressionTest
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')

function Read-FinalProductionAudit([string]$Path, [string]$AllowedRoot) {
  $audit = Read-AplStrictJson $Path $AllowedRoot
  foreach ($name in @('SchemaVersion','ContractSchemaVersion','ScanDate','Status','Required','TableCardSemantic','ProductionPackage','ProductionFileCount','ProductionBytes')) {
    if ($null -eq $audit.PSObject.Properties[$name]) { throw "Final Production Audit missing '$name'." }
  }
  if ([string]$audit.SchemaVersion -cne $script:AplFinalAuditSchemaVersion -or [string]$audit.ContractSchemaVersion -cne 'APL Production Artifact Contract v1.0' -or [string]$audit.ScanDate -cne $ScanDate -or [string]$audit.Status -cne 'PASS') {
    throw 'Archive requires a matching APL Final Production Audit v2.0 PASS.'
  }
  $required = @($audit.Required)
  if ($required.Count -eq 0 -or @($required | Where-Object { [string]$_.Status -ne 'PASS' }).Count -gt 0) { throw 'Final Production Audit required artifact results are incomplete.' }
  if ([string]$audit.ProductionPackage.Status -cne 'PASS' -or [int]$audit.ProductionPackage.RequiredCount -lt 12) { throw 'Archive requires a PASS production-package semantic/integrity audit.' }
  $semantic = @($audit.TableCardSemantic)
  if ($semantic.Count -ne 4 -or @($semantic | Where-Object { [string]$_.Status -cne 'PASS' }).Count -gt 0) { throw 'Archive requires four PASS Table Card semantic audits.' }
  return $audit
}

function Get-IndexContent([string]$Root, [object]$CurrentManifest, [object]$Policy) {
  $rows = New-Object System.Collections.Generic.List[string]
  $datesSeen = @{}
  foreach ($yearDirectory in @(Get-ChildItem -LiteralPath $Root -Directory | Where-Object { $_.Name -match '^\d{4}$' } | Sort-Object Name -Descending)) {
    Assert-AplNoReparsePath -Path $yearDirectory.FullName -AllowedRoot $Root -RequireDirectory | Out-Null
    foreach ($dateDirectory in @(Get-ChildItem -LiteralPath $yearDirectory.FullName -Directory | Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' } | Sort-Object Name -Descending)) {
      Assert-AplNoReparsePath -Path $dateDirectory.FullName -AllowedRoot $Root -RequireDirectory | Out-Null
      $date = $dateDirectory.Name
      $key = $date.ToLowerInvariant()
      if ($datesSeen.ContainsKey($key)) { throw "Duplicate Archive date directory in index: $date" }
      $datesSeen[$key] = $true
      if ($date -eq [string]$CurrentManifest.ScanDate) {
        $status = 'PASS'
        $count = [int]$CurrentManifest.ArchiveFileCount
        $bytes = [long]$CurrentManifest.TotalBytes
      } else {
        $inventory = @(Get-AplArchiveInventory $dateDirectory.FullName -ExcludeManifest)
        $existingManifestPath = Join-Path $dateDirectory.FullName 'archive-manifest.json'
        $count = $inventory.Count
        $bytes = [long](($inventory | Measure-Object Size -Sum).Sum)
        $isLegacy = Test-AplLegacyUnverifiedDate $Policy $date
        if (Test-Path -LiteralPath $existingManifestPath -PathType Leaf) {
          if ($isLegacy) { throw "Legacy allowlisted date must not claim v2 PASS without an approved migration: $date" }
          $existingManifest = Read-AplStrictJson $existingManifestPath $dateDirectory.FullName
          if ([string]$existingManifest.Status -ceq 'PASS') {
            Assert-AplArchiveManifest $existingManifest $date 'PASS' $inventory | Out-Null
            $status = 'PASS'
            $notes = 'V2 manifest verified'
          } elseif ([string]$existingManifest.Status -ceq 'PENDING_INDEX') {
            Assert-AplArchiveManifest $existingManifest $date 'PENDING_INDEX' $inventory | Out-Null
            $status = 'PENDING_INDEX'
            $notes = 'V2 copy verified; index/finalization pending'
          } else {
            throw "Archive date has unsupported manifest Status '$($existingManifest.Status)': $date"
          }
          $manifestRelative = '{0}/{1}/archive-manifest.json' -f $yearDirectory.Name, $date
        } else {
          if (-not $isLegacy) { throw "Archive date without v2 manifest is not allowlisted as legacy: $date" }
          $status = 'LEGACY_UNVERIFIED'
          $manifestRelative = 'N/A'
          $notes = 'Pre-v2 archive; inventory-only counts; integrity not attested'
        }
      }
      if ($date -eq [string]$CurrentManifest.ScanDate) {
        $manifestRelative = '{0}/{1}/archive-manifest.json' -f $yearDirectory.Name, $date
        $notes = 'V2 manifest verified'
      }
      $rows.Add("| $date | $status | $count | $bytes | $manifestRelative | $notes |")
    }
  }
  $lines = @(
    '# APL US Stock Archive Index',
    '',
    'This index is maintained automatically after copy and integrity verification. Final Archive status is authoritative only in each archive-manifest.json.',
    '',
    '| Date | Status | Files | Bytes | Manifest | Notes |',
    '|---|---|---:|---:|---|---|'
  ) + [string[]]$rows.ToArray()
  return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

function Update-And-VerifyIndex([string]$Root, [object]$Manifest, [object]$Policy) {
  $indexPath = Join-Path $Root 'index.md'
  $content = Get-IndexContent $Root $Manifest $Policy
  Write-AplUtf8Atomic $indexPath $content $Root | Out-Null
  $indexProjection = $Manifest | ConvertTo-Json -Depth 10 | ConvertFrom-Json
  $indexProjection.Status = 'PASS'
  Assert-AplArchiveIndexRow $indexPath $indexProjection $Root | Out-Null
  foreach ($legacyDateValue in @($Policy.LegacyUnverifiedDates)) {
    $legacyDate = [string]$legacyDateValue
    $legacyDirectory = Join-Path $Root (Join-Path $legacyDate.Substring(0,4) $legacyDate)
    if (!(Test-Path -LiteralPath $legacyDirectory -PathType Container)) { continue }
    $legacyInventory = @(Get-AplArchiveInventory $legacyDirectory -ExcludeManifest)
    Assert-AplLegacyArchiveIndexRow $indexPath $legacyDate $legacyInventory.Count ([long](($legacyInventory | Measure-Object Size -Sum).Sum)) $Root | Out-Null
  }
  return $indexPath
}

function New-Manifest([string]$Status, [object[]]$Inventory, [string]$Destination) {
  $total = [long](($Inventory | Measure-Object Size -Sum).Sum)
  return [pscustomobject][ordered]@{
    SchemaVersion = $script:AplArchiveManifestSchemaVersion
    ScanDate = $ScanDate
    Status = $Status
    Source = $SourceDatePath
    Destination = $Destination
    CopyMode = 'COPY_SOURCE_UNCHANGED'
    FinalProductionAudit = $FinalAuditPath
    SourceFileCount = $Inventory.Count
    ArchiveFileCount = $Inventory.Count
    TotalBytes = $total
    VerifiedUtc = [datetime]::UtcNow.ToString('o')
    Files = [object[]]@(ConvertTo-AplManifestRecords $Inventory)
  }
}

Assert-AplScanDate $ScanDate | Out-Null
$gitRoot = (& git -C $ProjectRoot rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$gitRoot) -or (Get-AplCanonicalPath ([string]$gitRoot)) -ne (Get-AplCanonicalPath $ProjectRoot)) { throw 'Project Root/Git Root mismatch.' }
Assert-AplNoReparsePath -Path $ProjectRoot -AllowedRoot $ProjectRoot -RequireDirectory | Out-Null
if ([string]::IsNullOrWhiteSpace($ArchivePolicyPath)) { $ArchivePolicyPath = Join-Path $ProjectRoot 'tools\archive-v2-policy.json' }
$policyAllowedRoot = if ($RegressionTest) { $ProjectRoot } else { Join-Path $ProjectRoot 'tools' }
$ArchivePolicyPath = Assert-AplNoReparsePath -Path $ArchivePolicyPath -AllowedRoot $policyAllowedRoot -RequireFile
if (-not $RegressionTest -and $ArchivePolicyPath -cne (Get-AplCanonicalPath (Join-Path $ProjectRoot 'tools\archive-v2-policy.json'))) { throw 'Formal ArchivePolicyPath must be the repository adoption policy.' }
$archivePolicy = Read-AplArchiveV2Policy $ArchivePolicyPath $policyAllowedRoot

$formalOutputsRoot = Join-Path $ProjectRoot 'outputs'
$tmpRoot = Join-Path $ProjectRoot 'tmp'
$sourceAllowedRoot = if ($RegressionTest) { $tmpRoot } else { $formalOutputsRoot }
$SourceDatePath = Assert-AplNoReparsePath -Path $SourceDatePath -AllowedRoot $sourceAllowedRoot -RequireDirectory
if ((Split-Path $SourceDatePath -Leaf) -cne $ScanDate) { throw "Archive source directory must match ScanDate '$ScanDate'." }
if (-not $RegressionTest -and $SourceDatePath -cne (Get-AplCanonicalPath (Join-Path $formalOutputsRoot $ScanDate))) { throw 'Formal archive source path mismatch.' }
$FinalAuditPath = Assert-AplNoReparsePath -Path $FinalAuditPath -AllowedRoot $SourceDatePath -RequireFile
$finalAudit = Read-FinalProductionAudit $FinalAuditPath $SourceDatePath

if ([string]::IsNullOrWhiteSpace($ArchiveRoot)) { $ArchiveRoot = if ($RegressionTest) { Join-Path (Split-Path $SourceDatePath -Parent) '_archive' } else { Join-Path $ProjectRoot 'Archive' } }
$archiveAllowedRoot = if ($RegressionTest) { $tmpRoot } else { $ProjectRoot }
$ArchiveRoot = Assert-AplNoReparsePath -Path $ArchiveRoot -AllowedRoot $archiveAllowedRoot
if (-not $RegressionTest -and $ArchiveRoot -cne (Get-AplCanonicalPath (Join-Path $ProjectRoot 'Archive'))) { throw 'Formal ArchiveRoot must be ProjectRoot\Archive.' }
if (!(Test-Path -LiteralPath $ArchiveRoot)) { New-Item -ItemType Directory -Path $ArchiveRoot | Out-Null }
$ArchiveRoot = Assert-AplNoReparsePath -Path $ArchiveRoot -AllowedRoot $archiveAllowedRoot -RequireDirectory

$year = $ScanDate.Substring(0,4)
$yearRoot = Join-Path $ArchiveRoot $year
if (!(Test-Path -LiteralPath $yearRoot)) { New-Item -ItemType Directory -Path $yearRoot | Out-Null }
$yearRoot = Assert-AplNoReparsePath -Path $yearRoot -AllowedRoot $ArchiveRoot -RequireDirectory
$destination = Join-Path $yearRoot $ScanDate
$sourceInventory = @(Get-AplArchiveInventory $SourceDatePath)
if ($sourceInventory.Count -eq 0) { throw 'Archive source inventory is empty.' }

# A pending manifest for this ScanDate is resumable below.  A pending manifest
# for any other date is an unresolved Archive state and blocks every new or
# reused completion until it is finalized, so no run can bypass the index gate.
$pendingDates = New-Object System.Collections.Generic.List[string]
foreach ($yearDirectory in @(Get-ChildItem -LiteralPath $ArchiveRoot -Directory | Where-Object { $_.Name -match '^\d{4}$' })) {
  foreach ($dateDirectory in @(Get-ChildItem -LiteralPath $yearDirectory.FullName -Directory | Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' })) {
    $pendingManifestPath = Join-Path $dateDirectory.FullName 'archive-manifest.json'
    if (!(Test-Path -LiteralPath $pendingManifestPath -PathType Leaf)) { continue }
    $pendingManifest = Read-AplStrictJson $pendingManifestPath $dateDirectory.FullName
    if ([string]$pendingManifest.Status -ceq 'PENDING_INDEX' -and $dateDirectory.Name -cne $ScanDate) { [void]$pendingDates.Add($dateDirectory.Name) }
  }
}
if ($pendingDates.Count -gt 0) { throw "Existing PENDING_INDEX Archive dates must be resumed before Archive can continue: $($pendingDates.ToArray() -join ', ')" }

if (Test-Path -LiteralPath $destination) {
  $destination = Assert-AplNoReparsePath -Path $destination -AllowedRoot $ArchiveRoot -RequireDirectory
  $manifestPath = Join-Path $destination 'archive-manifest.json'
  $manifest = Read-AplStrictJson $manifestPath $destination
  $actual = @(Get-AplArchiveInventory $destination -ExcludeManifest)
  if ([string]$manifest.Status -eq 'PENDING_INDEX') {
    Assert-AplArchiveManifest $manifest $ScanDate 'PENDING_INDEX' $actual | Out-Null
    Assert-AplInventoryMatch $sourceInventory $actual 'Same-date pending Archive versus source'
    $indexPath = Update-And-VerifyIndex $ArchiveRoot $manifest $archivePolicy
    $manifest.Status = 'PASS'
    Write-AplUtf8Atomic $manifestPath ($manifest | ConvertTo-Json -Depth 10) $destination | Out-Null
  } elseif ([string]$manifest.Status -eq 'PASS') {
    Assert-AplArchiveManifest $manifest $ScanDate 'PASS' $actual | Out-Null
    Assert-AplInventoryMatch $sourceInventory $actual 'Same-date Archive versus source'
    $indexPath = Update-And-VerifyIndex $ArchiveRoot $manifest $archivePolicy
  } else { throw "Existing same-date Archive is not resumable: $($manifest.Status)" }
  $manifest = Read-AplStrictJson $manifestPath $destination
  $actual = @(Get-AplArchiveInventory $destination -ExcludeManifest)
  Assert-AplArchiveManifest $manifest $ScanDate 'PASS' $actual | Out-Null
  Assert-AplArchiveIndexRow $indexPath $manifest $ArchiveRoot | Out-Null
  [pscustomobject]@{ Status='PASS'; Reused=$true; ScanDate=$ScanDate; Source=$SourceDatePath; Destination=$destination; FileCount=$manifest.ArchiveFileCount; TotalBytes=$manifest.TotalBytes; Manifest=$manifestPath; Index=$indexPath }
  exit 0
}

$stagingRoot = Join-Path $ArchiveRoot ".staging\$([guid]::NewGuid().ToString('N'))"
$stagedDestination = $stagingRoot
New-Item -ItemType Directory -Path $stagedDestination -Force | Out-Null
$stagingRoot = Assert-AplNoReparsePath -Path $stagingRoot -AllowedRoot $ArchiveRoot -RequireDirectory
$stagedDestination = Assert-AplNoReparsePath -Path $stagedDestination -AllowedRoot $stagingRoot -RequireDirectory
try {
  foreach ($file in $sourceInventory) {
    $copyPath = Join-Path $stagedDestination $file.RelativePath.Replace('/','\')
    $copyParent = Split-Path -Parent $copyPath
    if (!(Test-Path -LiteralPath $copyParent)) { New-Item -ItemType Directory -Path $copyParent -Force | Out-Null }
    Assert-AplNoReparsePath -Path $copyParent -AllowedRoot $stagedDestination -RequireDirectory | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $copyPath
  }
  $copyInventory = @(Get-AplArchiveInventory $stagedDestination)
  Assert-AplInventoryMatch $sourceInventory $copyInventory 'Archive copy integrity verification'
  $provisional = New-Manifest 'PENDING_INDEX' $copyInventory $destination
  $stagedManifestPath = Join-Path $stagedDestination 'archive-manifest.json'
  Write-AplUtf8Atomic $stagedManifestPath ($provisional | ConvertTo-Json -Depth 10) $stagedDestination | Out-Null
  $stagedActual = @(Get-AplArchiveInventory $stagedDestination -ExcludeManifest)
  Assert-AplArchiveManifest $provisional $ScanDate 'PENDING_INDEX' $stagedActual | Out-Null
  Move-Item -LiteralPath $stagedDestination -Destination $destination
  $destination = Assert-AplNoReparsePath -Path $destination -AllowedRoot $ArchiveRoot -RequireDirectory
  $manifestPath = Join-Path $destination 'archive-manifest.json'
  $provisional = Read-AplStrictJson $manifestPath $destination
  $actual = @(Get-AplArchiveInventory $destination -ExcludeManifest)
  Assert-AplArchiveManifest $provisional $ScanDate 'PENDING_INDEX' $actual | Out-Null
  $indexPath = Update-And-VerifyIndex $ArchiveRoot $provisional $archivePolicy
  $provisional.Status = 'PASS'
  Write-AplUtf8Atomic $manifestPath ($provisional | ConvertTo-Json -Depth 10) $destination | Out-Null
  $finalManifest = Read-AplStrictJson $manifestPath $destination
  $finalActual = @(Get-AplArchiveInventory $destination -ExcludeManifest)
  Assert-AplArchiveManifest $finalManifest $ScanDate 'PASS' $finalActual | Out-Null
  Assert-AplArchiveIndexRow $indexPath $finalManifest $ArchiveRoot | Out-Null
  [pscustomobject]@{ Status='PASS'; Reused=$false; ScanDate=$ScanDate; Source=$SourceDatePath; Destination=$destination; FileCount=$finalManifest.ArchiveFileCount; TotalBytes=$finalManifest.TotalBytes; Manifest=$manifestPath; Index=$indexPath }
} finally {
  if (Test-Path -LiteralPath $stagingRoot) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force }
}
