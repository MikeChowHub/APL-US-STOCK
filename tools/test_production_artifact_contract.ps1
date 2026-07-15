[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ProductionDatePath,
  [Parameter(Mandatory = $true)][string]$ScanDate,
  [string]$ContractPath = '',
  [string]$AuditOutputPath = '',
  [switch]$RegressionTest
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')

Assert-AplScanDate $ScanDate | Out-Null
$allowedRoot = if ($RegressionTest) { Join-Path $ProjectRoot 'tmp' } else { Join-Path $ProjectRoot 'outputs' }
$ProductionDatePath = Assert-AplNoReparsePath -Path $ProductionDatePath -AllowedRoot $allowedRoot -RequireDirectory
if ((Split-Path $ProductionDatePath -Leaf) -cne $ScanDate) { throw 'ProductionDatePath leaf must equal ScanDate.' }
if ([string]::IsNullOrWhiteSpace($ContractPath)) { $ContractPath = Join-Path $ProjectRoot 'KnowledgeBase\Rules\APL_US_Stock_Production_Artifact_Contract.json' }
$ContractPath = Assert-AplNoReparsePath -Path $ContractPath -AllowedRoot $ProjectRoot -RequireFile
if ([string]::IsNullOrWhiteSpace($AuditOutputPath)) { $AuditOutputPath = Join-Path $ProductionDatePath "Final_Production_Audit_${ScanDate}.json" }
$AuditOutputPath = Assert-AplNoReparsePath -Path $AuditOutputPath -AllowedRoot $ProductionDatePath

$contract = Read-AplStrictJson $ContractPath $ProjectRoot
if ([string]$contract.SchemaVersion -cne 'APL Production Artifact Contract v1.0') { throw 'Unsupported Production Artifact Contract SchemaVersion.' }
$requiredDefinitions = @($contract.Required)
$optionalDefinitions = @($contract.Optional)
if ($requiredDefinitions.Count -eq 0) { throw 'Production Artifact Contract Required must not be empty.' }
$ids = @{}
foreach ($definition in @($requiredDefinitions + $optionalDefinitions)) {
  foreach ($name in @('Id','Category','Patterns')) { if ($null -eq $definition.PSObject.Properties[$name]) { throw "Artifact contract entry missing '$name'." } }
  $id = [string]$definition.Id
  if ([string]::IsNullOrWhiteSpace($id) -or $ids.ContainsKey($id.ToLowerInvariant())) { throw "Duplicate or empty artifact contract Id: $id" }
  $ids[$id.ToLowerInvariant()] = $true
  if (@('Machine','Publishing') -notcontains [string]$definition.Category) { throw "Invalid artifact contract Category for '$id'." }
  if (@($definition.Patterns).Count -eq 0) { throw "Artifact contract Patterns must not be empty for '$id'." }
}

function Expand-Pattern([string]$Pattern) { return $Pattern.Replace('{ScanDate}', $ScanDate).Replace('\','/') }
function Find-Matches([object[]]$Files, [object]$Definition) {
  $patterns = @($Definition.Patterns | ForEach-Object { Expand-Pattern ([string]$_) })
  return [object[]]@($Files | Where-Object { $relative=$_.RelativePath; @($patterns | Where-Object { $relative -like $_ }).Count -gt 0 } | Sort-Object RelativePath -Unique)
}

$safeFiles = @(Get-AplArchiveInventory $ProductionDatePath | Where-Object { $_.RelativePath -notlike 'Final_Production_Audit_*.json' })
$requiredResults = New-Object System.Collections.Generic.List[object]
$optionalResults = New-Object System.Collections.Generic.List[object]
$classified = @{}
$failure = $null
try {
  foreach ($definition in $requiredDefinitions) {
    $matchMode = [string]$definition.Match
    if (@('ExactlyOne','AtLeastOne') -notcontains $matchMode) { throw "Required artifact '$($definition.Id)' has invalid Match mode." }
    $matches = @(Find-Matches $safeFiles $definition)
    if ($matchMode -eq 'ExactlyOne' -and $matches.Count -ne 1) { throw "Required artifact '$($definition.Id)' expected exactly one match; found $($matches.Count)." }
    if ($matchMode -eq 'AtLeastOne' -and $matches.Count -lt 1) { throw "Required artifact '$($definition.Id)' expected at least one match; found 0." }
    foreach ($match in $matches) { $classified[$match.RelativePath.ToLowerInvariant()] = $true }
    if ($null -ne $definition.PSObject.Properties['RequiredCsvColumns']) {
      foreach ($match in $matches) {
        $first = @(Import-Csv -LiteralPath $match.FullName | Select-Object -First 1)
        if ($first.Count -eq 0) { throw "Required CSV is empty: $($match.RelativePath)" }
        $columns = @($first[0].PSObject.Properties.Name)
        foreach ($column in @($definition.RequiredCsvColumns)) { if ($columns -notcontains [string]$column) { throw "Required CSV '$($definition.Id)' missing score column '$column'." } }
      }
    }
    $requiredResults.Add([pscustomobject]@{ Id=[string]$definition.Id; Category=[string]$definition.Category; Status='PASS'; Files=[object[]]@($matches | ForEach-Object { [pscustomobject]@{ RelativePath=[string]$_.RelativePath; Size=[long]$_.Size; SHA256=[string]$_.SHA256 } }) })
  }

  $tableManifestResult = @($requiredResults.ToArray() | Where-Object { $_.Id -eq 'table-card-publication-manifest' })[0]
  $tableManifestRelative = [string]$tableManifestResult.Files[0].RelativePath
  $tableManifest = Read-AplStrictJson (Join-Path $ProductionDatePath $tableManifestRelative.Replace('/','\')) $ProductionDatePath
  if ([string]$tableManifest.SchemaVersion -cne 'APL Table Card Publication Manifest v1.0' -or [string]$tableManifest.ScanDate -cne $ScanDate -or [string]$tableManifest.Status -cne 'PASS') { throw 'Table Card publication manifest schema/date/status mismatch.' }
  foreach ($type in @($contract.RequiredTableCardTypes)) {
    $records = @($tableManifest.Cards | Where-Object { [string]$_.CardType -eq [string]$type -and $_.Required -eq $true -and [string]$_.Status -eq 'PASS' })
    if ($records.Count -ne 1) { throw "Required Table Card '$type' does not have exactly one required PASS record." }
    $record = $records[0]
    $outputName = [string]$record.OutputName
    if ([System.IO.Path]::GetFileName($outputName) -cne $outputName) { throw "Unsafe Table Card OutputName: $outputName" }
    $outputs = @($safeFiles | Where-Object { (Split-Path $_.RelativePath -Leaf) -ceq $outputName })
    if ($outputs.Count -ne 1) { throw "Required Table Card '$type' output expected exactly once; found $($outputs.Count)." }
    if ([long]$record.Bytes -ne [long]$outputs[0].Size -or [string]$record.Sha256 -cne [string]$outputs[0].SHA256) { throw "Required Table Card '$type' size/SHA-256 mismatch." }
    $classified[$outputs[0].RelativePath.ToLowerInvariant()] = $true
  }

  foreach ($definition in $optionalDefinitions) {
    $matches = @(Find-Matches $safeFiles $definition)
    foreach ($match in $matches) { $classified[$match.RelativePath.ToLowerInvariant()] = $true }
    $optionalResults.Add([pscustomobject]@{ Id=[string]$definition.Id; Category=[string]$definition.Category; Status=if($matches.Count -gt 0){'PRESENT'}else{'ABSENT'}; Files=[object[]]@($matches | ForEach-Object { [pscustomobject]@{ RelativePath=[string]$_.RelativePath; Size=[long]$_.Size; SHA256=[string]$_.SHA256 } }) })
  }
} catch {
  $failure = $_.Exception.Message
}

$unclassified = [string[]]@($safeFiles | Where-Object { -not $classified.ContainsKey($_.RelativePath.ToLowerInvariant()) } | ForEach-Object { [string]$_.RelativePath })
[object[]]$requiredResultArray = @(ConvertTo-AplArchiveObjectArray $requiredResults)
[object[]]$optionalResultArray = @(ConvertTo-AplArchiveObjectArray $optionalResults)
$errorResults = New-Object System.Collections.Generic.List[object]
if ($null -ne $failure) { $errorResults.Add([pscustomobject]@{ Code='FINAL_AUDIT_FAILURE'; Message=[string]$failure }) }
$audit = [ordered]@{
  SchemaVersion = $script:AplFinalAuditSchemaVersion
  ContractSchemaVersion = [string]$contract.SchemaVersion
  ContractPath = $ContractPath
  ScanDate = $ScanDate
  Status = if ($null -eq $failure) { 'PASS' } else { 'FAIL' }
  AuditedUtc = [datetime]::UtcNow.ToString('o')
  Required = [object[]]$requiredResultArray
  Optional = [object[]]$optionalResultArray
  UnclassifiedArtifacts = $unclassified
  ProductionFileCount = $safeFiles.Count
  ProductionBytes = [long](($safeFiles | Measure-Object Size -Sum).Sum)
  Errors = [object[]]$errorResults.ToArray()
  Error = $failure
}
Write-AplUtf8Atomic $AuditOutputPath ($audit | ConvertTo-Json -Depth 12) $ProductionDatePath | Out-Null
if ($null -ne $failure) { Write-Error $failure; exit 1 }
[pscustomobject]@{ Status='PASS'; ScanDate=$ScanDate; Audit=$AuditOutputPath; RequiredCount=$requiredResults.Count; OptionalCount=$optionalResults.Count; ProductionFileCount=$safeFiles.Count; ProductionBytes=$audit.ProductionBytes }
