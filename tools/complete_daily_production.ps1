[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ScanDate,
  [Parameter(Mandatory = $true)][string]$FinalAuditPath,
  [Parameter(Mandatory = $true)][string]$ArchiveManifestPath,
  [Parameter(Mandatory = $true)][string]$ArchiveIndexPath,
  [Parameter(Mandatory = $true)][string]$PipelineLog,
  [Parameter(Mandatory = $true)][string]$PipelineTrace,
  [Parameter(Mandatory = $true)][string]$StatePath,
  [switch]$RegressionTest,
  [switch]$TestFailFinalLog
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')
Assert-AplScanDate $ScanDate | Out-Null
$artifactContract = Read-AplStrictJson (Join-Path $ProjectRoot 'KnowledgeBase\Rules\APL_US_Stock_Production_Artifact_Contract.json') $ProjectRoot
$expectedEditorialSourceCount = @($artifactContract.EditorialReadiness.RequiredSourceRoles).Count
if ($expectedEditorialSourceCount -lt 1) { throw 'Production Artifact Contract EditorialReadiness source roles are invalid.' }
$scanDateValue=[datetime]::ParseExact($ScanDate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
$editorialQualityFrom=[datetime]::ParseExact('2026-08-10','yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
$ctaDisclaimerRemovalFrom=[datetime]::ParseExact('2026-08-28','yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
$investmentImplicationFrom=[datetime]::ParseExact('2026-08-30','yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
$expectedEditorialSectionCount=if($scanDateValue-ge$investmentImplicationFrom){10}elseif($scanDateValue-ge$editorialQualityFrom-and$scanDateValue-lt$ctaDisclaimerRemovalFrom){11}else{9}
$allowedRoot = if ($RegressionTest) { Join-Path $ProjectRoot 'tmp' } else { $ProjectRoot }
$FinalAuditPath = Assert-AplNoReparsePath -Path $FinalAuditPath -AllowedRoot $allowedRoot -RequireFile
$ArchiveManifestPath = Assert-AplNoReparsePath -Path $ArchiveManifestPath -AllowedRoot $allowedRoot -RequireFile
$archiveDatePath = Split-Path $ArchiveManifestPath -Parent
$archiveRoot = Split-Path (Split-Path $archiveDatePath -Parent) -Parent
$ArchiveIndexPath = Assert-AplNoReparsePath -Path $ArchiveIndexPath -AllowedRoot $archiveRoot -RequireFile
$PipelineLog = Assert-AplNoReparsePath -Path $PipelineLog -AllowedRoot $allowedRoot -RequireFile
$PipelineTrace = Assert-AplNoReparsePath -Path $PipelineTrace -AllowedRoot $allowedRoot -RequireFile
$StatePath = Assert-AplNoReparsePath -Path $StatePath -AllowedRoot $allowedRoot

if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
  $existing = Read-AplStrictJson $StatePath $allowedRoot
  if ([string]$existing.SchemaVersion -cne 'APL Daily Production State v1.0' -or [string]$existing.ScanDate -cne $ScanDate -or [string]$existing.Status -cne 'PASS' -or $existing.DailyProductionComplete -ne $true -or $existing.DailyProductionPublishable -ne $true) { throw 'Existing daily production state is invalid.' }
  [pscustomobject]@{ Status='PASS'; DailyProductionComplete=$true; DailyProductionPublishable=$true; Reused=$true; StatePath=$StatePath }
  exit 0
}

$audit = Read-AplStrictJson $FinalAuditPath (Split-Path $FinalAuditPath -Parent)
if ([string]$audit.SchemaVersion -cne $script:AplFinalAuditSchemaVersion -or [string]$audit.ScanDate -cne $ScanDate -or [string]$audit.Status -cne 'PASS') { throw 'Final Production Audit is not PASS.' }
if ([string]$audit.ProductionPackage.Status -cne 'PASS' -or [int]$audit.ProductionPackage.RequiredCount -lt 13) { throw 'Production package audit is not PASS.' }
if ([string]$audit.EditorialCompletion.Status -cne 'PASS' -or $audit.EditorialCompletion.ProductionReadiness -ne $true -or $audit.EditorialCompletion.DailyProductionPublishable -ne $true -or [int]$audit.EditorialCompletion.MandatorySections -ne $expectedEditorialSectionCount -or [int]$audit.EditorialCompletion.SourceEvidence -ne $expectedEditorialSourceCount) { throw 'Editorial Completion Audit is not production-ready publishable PASS.' }
if (@($audit.TableCardSemantic).Count -ne 4 -or @($audit.TableCardSemantic | Where-Object { [string]$_.Status -cne 'PASS' }).Count -gt 0) { throw 'Table Card semantic audit is not PASS.' }
$manifest = Read-AplStrictJson $ArchiveManifestPath $archiveDatePath
$actual = @(Get-AplArchiveInventory $archiveDatePath -ExcludeManifest)
Assert-AplArchiveManifest $manifest $ScanDate 'PASS' $actual | Out-Null
Assert-AplArchiveIndexRow $ArchiveIndexPath $manifest $archiveRoot | Out-Null

$readyTrace = [ordered]@{ event='daily-production-finalization-ready'; scanDate=$ScanDate; utc=[datetime]::UtcNow.ToString('o'); finalAudit=$FinalAuditPath; archiveManifest=$ArchiveManifestPath; archiveIndex=$ArchiveIndexPath }
[System.IO.File]::AppendAllText($PipelineTrace, (($readyTrace | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine), [System.Text.Encoding]::UTF8)
if ($TestFailFinalLog) { throw 'Injected final log write failure.' }
[System.IO.File]::AppendAllText($PipelineLog, ('[{0}] ARCHIVE PASS; DAILY PRODUCTION FINALIZATION READY{1}' -f [datetime]::UtcNow.ToString('o'), [Environment]::NewLine), [System.Text.Encoding]::UTF8)

$state = [ordered]@{
  SchemaVersion = 'APL Daily Production State v1.0'
  ScanDate = $ScanDate
  Status = 'PASS'
  DailyProductionComplete = $true
  DailyProductionPublishable = $true
  CompletedUtc = [datetime]::UtcNow.ToString('o')
  FinalProductionAudit = $FinalAuditPath
  ArchiveManifest = $ArchiveManifestPath
  ArchiveIndex = $ArchiveIndexPath
  PipelineLog = $PipelineLog
  PipelineTrace = $PipelineTrace
}
Write-AplUtf8Atomic $StatePath ($state | ConvertTo-Json -Depth 6) $allowedRoot | Out-Null
[pscustomobject]@{ Status='PASS'; DailyProductionComplete=$true; DailyProductionPublishable=$true; Reused=$false; StatePath=$StatePath }
