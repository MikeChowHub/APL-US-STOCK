[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ProductionDatePath,
  [Parameter(Mandatory = $true)][string]$ScanDate,
  [string]$ContractPath = '',
  [string]$AuditOutputPath = '',
  [string]$ManagedInputDatePath = '',
  [string]$PublishedDatePath = '',
  [switch]$RegressionTest
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')

Assert-AplScanDate $ScanDate | Out-Null
$allowedRoot = if ($RegressionTest) { Join-Path $ProjectRoot 'tmp' } else { Join-Path $ProjectRoot 'outputs' }
$ProductionDatePath = Assert-AplNoReparsePath -Path $ProductionDatePath -AllowedRoot $allowedRoot -RequireDirectory
if ((Split-Path $ProductionDatePath -Leaf) -cne $ScanDate) { throw 'ProductionDatePath leaf must equal ScanDate.' }
if ([string]::IsNullOrWhiteSpace($PublishedDatePath)) {
  $PublishedDatePath = $ProductionDatePath
} else {
  $PublishedDatePath = Assert-AplNoReparsePath -Path $PublishedDatePath -AllowedRoot $allowedRoot
  if ((Split-Path $PublishedDatePath -Leaf) -cne $ScanDate) { throw 'PublishedDatePath leaf must equal ScanDate.' }
  if (-not $RegressionTest -and -not (Test-AplPathInside $ProductionDatePath (Join-Path $ProjectRoot 'outputs\.staging'))) { throw 'Formal PublishedDatePath override is allowed only when auditing a staging production directory.' }
}
if ([string]::IsNullOrWhiteSpace($ContractPath)) { $ContractPath = Join-Path $ProjectRoot 'KnowledgeBase\Rules\APL_US_Stock_Production_Artifact_Contract.json' }
$ContractPath = Assert-AplNoReparsePath -Path $ContractPath -AllowedRoot $ProjectRoot -RequireFile
if ([string]::IsNullOrWhiteSpace($AuditOutputPath)) { $AuditOutputPath = Join-Path $ProductionDatePath "Final_Production_Audit_${ScanDate}.json" }
$AuditOutputPath = Assert-AplNoReparsePath -Path $AuditOutputPath -AllowedRoot $ProductionDatePath
$managedInputAllowedRoot = if ($RegressionTest) { Join-Path $ProjectRoot 'tmp' } else { Join-Path $ProjectRoot 'work\managed-inputs' }
if (-not $RegressionTest -and [string]::IsNullOrWhiteSpace($ManagedInputDatePath)) { throw 'Formal Final Production Audit requires ManagedInputDatePath.' }
if (-not [string]::IsNullOrWhiteSpace($ManagedInputDatePath)) {
  $ManagedInputDatePath = Assert-AplNoReparsePath -Path $ManagedInputDatePath -AllowedRoot $managedInputAllowedRoot -RequireDirectory
  if ((Split-Path $ManagedInputDatePath -Leaf) -cne $ScanDate) { throw 'ManagedInputDatePath leaf must equal ScanDate.' }
}

$contract = Read-AplStrictJson $ContractPath $ProjectRoot
if ([string]$contract.SchemaVersion -cne 'APL Production Artifact Contract v1.0') { throw 'Unsupported Production Artifact Contract SchemaVersion.' }
$readinessContract=$contract.EditorialReadiness
if($null-eq$readinessContract-or[string]::IsNullOrWhiteSpace([string]$readinessContract.SchemaVersion)-or@($readinessContract.RequiredSourceRoles).Count-lt1-or@($readinessContract.RequiredChecks).Count-lt1){throw 'Production Artifact Contract EditorialReadiness definition is invalid.'}
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
$tableCardSemanticResults = New-Object System.Collections.Generic.List[object]
$productionPackageAudit = $null
$editorialCompletionAudit = $null
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
    $expectedTableRelative = "production-package/Table Cards/$outputName"
    $outputs = @($safeFiles | Where-Object { [string]$_.RelativePath -ceq $expectedTableRelative })
    if ($outputs.Count -ne 1) { throw "Required Table Card '$type' output expected exactly once; found $($outputs.Count)." }
    $expectedPublishedInput = Get-AplCanonicalPath (Join-Path $PublishedDatePath $expectedTableRelative.Replace('/','\'))
    if ([string]$record.OutputPath -cne $expectedPublishedInput) { throw "Required Table Card '$type' publication manifest OutputPath is not the canonical package path." }
    if ([long]$record.Bytes -ne [long]$outputs[0].Size -or [string]$record.Sha256 -cne [string]$outputs[0].SHA256) { throw "Required Table Card '$type' size/SHA-256 mismatch." }
    if ([string]::IsNullOrWhiteSpace([string]$record.InputPath) -or [string]::IsNullOrWhiteSpace([string]$record.InputSha256)) { throw "Required Table Card '$type' publication record is missing semantic input evidence." }
    $semanticAllowedRoot = if ($RegressionTest) { Join-Path $ProjectRoot 'tmp' } else { Join-Path $ProjectRoot 'work' }
    $semanticInputPath = Assert-AplNoReparsePath -Path ([string]$record.InputPath) -AllowedRoot $semanticAllowedRoot -RequireFile
    $semanticInputSha = (Get-FileHash -LiteralPath $semanticInputPath -Algorithm SHA256).Hash
    if ($semanticInputSha -cne [string]$record.InputSha256) { throw "Required Table Card '$type' semantic input SHA-256 mismatch." }
    $semanticJson = Read-AplStrictJson $semanticInputPath $semanticAllowedRoot
    $semanticContract = Assert-AplTableCardContract $semanticJson ([string]$type)
    if ([string]$semanticContract.SchemaVersion -cne 'APL Table Card Input v1.1' -or [string]$semanticContract.CardType -cne [string]$type) { throw "Required Table Card '$type' semantic schema/type mismatch." }
    if ([int]$semanticContract.Rows -lt 1 -or [int]$semanticContract.Columns -lt 1) { throw "Required Table Card '$type' semantic rows/columns are empty." }
    [void]$tableCardSemanticResults.Add([pscustomobject]@{
      CardType = [string]$type
      Status = 'PASS'
      SchemaVersion = [string]$semanticContract.SchemaVersion
      InputPath = $semanticInputPath
      InputSha256 = $semanticInputSha
      Rows = [int]$semanticContract.Rows
      DisplayColumns = [int]$semanticContract.Columns
      SemanticFields = [string](@($semanticContract.Presentation.Columns | ForEach-Object { [string]$_.Key }) -join ',')
    })
    $classified[$outputs[0].RelativePath.ToLowerInvariant()] = $true
  }

  $packageManifestResult = @($requiredResults.ToArray() | Where-Object { $_.Id -eq 'production-package-manifest' })[0]
  $packageManifestRelative = [string]$packageManifestResult.Files[0].RelativePath
  $packageRoot = Assert-AplNoReparsePath -Path (Join-Path $ProductionDatePath 'production-package') -AllowedRoot $ProductionDatePath -RequireDirectory
  $packageManifestPath = Assert-AplNoReparsePath -Path (Join-Path $ProductionDatePath $packageManifestRelative.Replace('/','\')) -AllowedRoot $packageRoot -RequireFile
  $packageManifest = Read-AplStrictJson $packageManifestPath $packageRoot
  if ([string]$packageManifest.SchemaVersion -cne 'APL Production Package Manifest v1.0' -or [string]$packageManifest.ScanDate -cne $ScanDate -or [string]$packageManifest.Status -cne 'PASS' -or [string]$packageManifest.PackageRoot -cne 'production-package') { throw 'Production package manifest schema/date/status/root mismatch.' }

  $expectedPackageRequired = [ordered]@{}
  foreach ($type in @($contract.RequiredTableCardTypes)) {
    $record = @($tableManifest.Cards | Where-Object { [string]$_.CardType -eq [string]$type -and $_.Required -eq $true -and [string]$_.Status -eq 'PASS' })[0]
    $expectedPackageRequired["table-card-$type"] = "Table Cards/$([string]$record.OutputName)"
  }
  $expectedPackageRequired['dashboard-png'] = "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_1920x1080.png"
  $expectedPackageRequired['social-card-png'] = "APL_DeepScan_Social_Card_${ScanDate}_1080x1350.png"
  $expectedPackageRequired['social-radar-png'] = "APL_DeepScan_Social_Radar_Top30_${ScanDate}_1080x1350.png"
  $expectedPackageRequired['cover'] = "APL_Momentum_Leaders_Blog_Cover_${ScanDate}_1080x1350.png"
  $expectedPackageRequired['seo'] = "APL_Momentum_Leaders_Blog_SEO_${ScanDate}_1280x720.png"
  $expectedPackageRequired['whatsapp'] = "WhatsApp_${ScanDate}.md"
  $expectedPackageRequired['formal-blog-markdown'] = "APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.md"
  $expectedPackageRequired['formal-blog-html-source'] = "APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.html.txt"
  $expectedPackageRequired['company-business-analysis'] = "table-card-log/APL_Momentum_Leaders_Top_30_Company_Business_Analysis_${ScanDate}.md"
  $expectedPackageRequired['editorial-completion-audit'] = "APL_Editorial_Completion_Audit_${ScanDate}.json"

  $requiredPackageRecords = @($packageManifest.Required)
  if ([int]$packageManifest.RequiredCount -ne $expectedPackageRequired.Count -or $requiredPackageRecords.Count -ne $expectedPackageRequired.Count) { throw "Production package required count mismatch. Expected=$($expectedPackageRequired.Count)." }
  $seenPackageIds = @{}; $seenPackagePaths = @{}
  foreach ($record in $requiredPackageRecords) {
    foreach ($name in @('Id','RelativePath','Size','SHA256')) { if ($null -eq $record.PSObject.Properties[$name]) { throw "Production package required record missing '$name'." } }
    $id = [string]$record.Id; $relative = [string]$record.RelativePath
    if (-not $expectedPackageRequired.Contains($id) -or [string]$expectedPackageRequired[$id] -cne $relative) { throw "Unexpected production package required mapping: $id -> $relative" }
    if ([System.IO.Path]::IsPathRooted($relative) -or $relative.Contains('\') -or $relative.Contains('..')) { throw "Unsafe production package RelativePath: $relative" }
    $idKey=$id.ToLowerInvariant();$pathKey=$relative.ToLowerInvariant()
    if ($seenPackageIds.ContainsKey($idKey) -or $seenPackagePaths.ContainsKey($pathKey)) { throw "Duplicate production package required id/path: $id -> $relative" }
    $seenPackageIds[$idKey]=$true;$seenPackagePaths[$pathKey]=$true
    $actualPath = Assert-AplNoReparsePath -Path (Join-Path $packageRoot $relative.Replace('/','\')) -AllowedRoot $packageRoot -RequireFile
    $actualItem = Get-Item -LiteralPath $actualPath
    $actualSha = (Get-FileHash -LiteralPath $actualPath -Algorithm SHA256).Hash
    if ([long]$record.Size -ne [long]$actualItem.Length -or [string]$record.SHA256 -cne $actualSha) { throw "Production package required size/SHA-256 mismatch: $relative" }
  }
  foreach ($id in $expectedPackageRequired.Keys) { if (-not $seenPackageIds.ContainsKey($id.ToLowerInvariant())) { throw "Production package missing required id: $id" } }

  $editorialAuditPath = Assert-AplNoReparsePath -Path (Join-Path $packageRoot "APL_Editorial_Completion_Audit_${ScanDate}.json") -AllowedRoot $packageRoot -RequireFile
  $editorialAudit = Read-AplStrictJson $editorialAuditPath $packageRoot
  if ([string]$editorialAudit.SchemaVersion -cne [string]$readinessContract.SchemaVersion -or [string]$editorialAudit.ScanDate -cne $ScanDate -or [string]$editorialAudit.Status -cne 'PASS' -or $editorialAudit.EditorialCompletion -ne $true -or $editorialAudit.ProductionReadiness -ne $true -or $editorialAudit.DailyProductionPublishableCandidate -ne $true) { throw 'Editorial Completion Audit schema/date/status/readiness mismatch.' }
  $headingMap=Get-AplBlogHeadingMap -ScanDate $ScanDate
  $mandatorySections=@(
    [string]$headingMap.ExecutiveSummary,
    [string]$headingMap.MarketContext,
    [string]$headingMap.WhyAPL,
    [string]$headingMap.DeepScanOverview,
    [string]$headingMap.TopGainers,
    [string]$headingMap.MomentumLeaders,
    [string]$headingMap.SectorAnalysis
  )
  $scanDateValue=[datetime]::ParseExact($ScanDate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
  $editorialQualityFrom=[datetime]::ParseExact('2026-08-10','yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
  $ctaDisclaimerRemovalFrom=[datetime]::ParseExact('2026-08-28','yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
  $investmentImplicationFrom=[datetime]::ParseExact('2026-08-30','yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
  if($scanDateValue-ge$investmentImplicationFrom){$mandatorySections+=@([string]$headingMap.InvestmentImplication)}
  $mandatorySections+=@([string]$headingMap.Risk,[string]$headingMap.DeepScanConclusion)
  if($scanDateValue-ge$editorialQualityFrom-and$scanDateValue-lt$ctaDisclaimerRemovalFrom){$mandatorySections+=@([string]$headingMap.CallToAction,[string]$headingMap.Disclaimer)}
  if(@($editorialAudit.MandatorySections).Count-ne$mandatorySections.Count){throw 'Editorial Completion Audit mandatory section count mismatch.'}
  for($i=0;$i-lt$mandatorySections.Count;$i++){if([string]$editorialAudit.MandatorySections[$i]-cne$mandatorySections[$i]){throw 'Editorial Completion Audit mandatory section order mismatch.'}}
  foreach($name in @($readinessContract.RequiredChecks)){if($null-eq$editorialAudit.Checks.PSObject.Properties[[string]$name]-or$editorialAudit.Checks.([string]$name)-ne$true){throw "Editorial Completion Audit check is not PASS: $name"}}
  $sourceRoles=@($readinessContract.RequiredSourceRoles|ForEach-Object{[string]$_})
  if(@($editorialAudit.Sources).Count-ne$sourceRoles.Count){throw 'Editorial Completion Audit source evidence count mismatch.'}
  $seenSourceRoles=@{};$seenSourcePaths=@{}
  foreach($role in $sourceRoles){
    $records=@($editorialAudit.Sources|Where-Object{[string]$_.Role-ceq$role});if($records.Count-ne1){throw "Editorial Completion Audit source role mismatch: $role"}
    $record=$records[0];$relative=[string]$record.RelativePath
    if([string]::IsNullOrWhiteSpace($relative)-or[IO.Path]::IsPathRooted($relative)-or$relative.Contains('\')-or$relative.Contains('..')){throw "Editorial Completion Audit source path is unsafe: $role"}
    if([long]$record.Size-le0-or[string]$record.SHA256-cnotmatch'^[0-9A-F]{64}$'){throw "Editorial Completion Audit source size/SHA is invalid: $role"}
    $roleKey=$role.ToLowerInvariant();$pathKey=$relative.ToLowerInvariant();if($seenSourceRoles.ContainsKey($roleKey)-or$seenSourcePaths.ContainsKey($pathKey)){throw "Editorial Completion Audit source role/path is duplicated: $role"};$seenSourceRoles[$roleKey]=$true;$seenSourcePaths[$pathKey]=$true
    if(-not[string]::IsNullOrWhiteSpace($ManagedInputDatePath)){$actualSource=Assert-AplNoReparsePath -Path (Join-Path $ManagedInputDatePath $relative.Replace('/','\')) -AllowedRoot $ManagedInputDatePath -RequireFile;$item=Get-Item -LiteralPath $actualSource;$sha=(Get-FileHash -LiteralPath $actualSource -Algorithm SHA256).Hash;if([long]$record.Size-ne[long]$item.Length-or[string]$record.SHA256-cne$sha){throw "Editorial Completion Audit source size/SHA mismatch: $role"}}
  }
  if($null-eq$editorialAudit.TableCardSourceIntegrity-or[int]$editorialAudit.TableCardSourceIntegrity.RankingRows-lt30-or[int]$editorialAudit.TableCardSourceIntegrity.TopLeaderRows-lt1-or[int]$editorialAudit.TableCardSourceIntegrity.TopGainerRows-lt1-or[int]$editorialAudit.TableCardSourceIntegrity.SectorRepresentatives-lt1){throw 'Editorial Completion Audit Table Card source integrity summary is invalid.'}
  if($null-eq$editorialAudit.NativeCompositionIntegrity-or[string]::IsNullOrWhiteSpace([string]$editorialAudit.NativeCompositionIntegrity.SceneConceptId)-or$editorialAudit.NativeCompositionIntegrity.DistinctSourcePaths-ne$true-or$editorialAudit.NativeCompositionIntegrity.DistinctSourceSHA256-ne$true-or$editorialAudit.NativeCompositionIntegrity.NativeAspectRatios-ne$true-or$editorialAudit.NativeCompositionIntegrity.DistinctViewpoints-ne$true-or[string]$editorialAudit.NativeCompositionIntegrity.CoverSourceSHA256-ceq[string]$editorialAudit.NativeCompositionIntegrity.SeoSourceSHA256){throw 'Editorial Completion Audit Native Composition integrity summary is invalid.'}
  $editorialRolePaths=[ordered]@{'blog-markdown'="APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.md";'blog-html-source'="APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.html.txt";'whatsapp'="WhatsApp_${ScanDate}.md";'company-business-analysis'="table-card-log/APL_Momentum_Leaders_Top_30_Company_Business_Analysis_${ScanDate}.md"}
  foreach($role in $editorialRolePaths.Keys){$record=@($editorialAudit.Artifacts|Where-Object{[string]$_.Role-ceq$role});if($record.Count-ne1){throw "Editorial Completion Audit missing artifact role: $role"};$actualPath=Assert-AplNoReparsePath -Path (Join-Path $packageRoot ([string]$editorialRolePaths[$role]).Replace('/','\')) -AllowedRoot $packageRoot -RequireFile;$actual=Get-Item -LiteralPath $actualPath;$sha=(Get-FileHash -LiteralPath $actualPath -Algorithm SHA256).Hash;if([long]$record[0].Size-ne[long]$actual.Length-or[string]$record[0].SHA256-cne$sha){throw "Editorial Completion Audit artifact size/SHA mismatch: $role"}}
  $editorialCompletionAudit=[pscustomobject]@{Status='PASS';Audit="production-package/APL_Editorial_Completion_Audit_${ScanDate}.json";MandatorySections=$mandatorySections.Count;SourceEvidence=$sourceRoles.Count;ProductionReadiness=$true;DailyProductionPublishable=$true}

  $packageInventory = @(Get-AplArchiveInventory $packageRoot | Where-Object { $_.RelativePath -cne (Split-Path $packageManifestPath -Leaf) })
  $declaredPackageInventory = @(Get-AplManifestInventory $packageManifest)
  Assert-AplInventoryMatch $declaredPackageInventory $packageInventory 'Production package manifest'
  $packageBytes = [long](($packageInventory | Measure-Object Size -Sum).Sum)
  if ([int]$packageManifest.FileCount -ne $packageInventory.Count -or [long]$packageManifest.TotalBytes -ne $packageBytes) { throw 'Production package file count/total bytes mismatch.' }

  foreach ($relative in $expectedPackageRequired.Values) {
    $rootDuplicate = Join-Path $ProductionDatePath (Split-Path $relative -Leaf)
    if (Test-Path -LiteralPath $rootDuplicate -PathType Leaf) { throw "Production package artifact is duplicated at date root: $rootDuplicate" }
  }
  $productionPackageAudit = [pscustomobject]@{Status='PASS';Manifest=$packageManifestRelative;RequiredCount=$expectedPackageRequired.Count;FileCount=$packageInventory.Count;TotalBytes=$packageBytes}

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
  TableCardSemantic = [object[]]$tableCardSemanticResults.ToArray()
  ProductionPackage = $productionPackageAudit
  EditorialCompletion = $editorialCompletionAudit
  UnclassifiedArtifacts = $unclassified
  ProductionFileCount = $safeFiles.Count
  ProductionBytes = [long](($safeFiles | Measure-Object Size -Sum).Sum)
  Errors = [object[]]$errorResults.ToArray()
  Error = $failure
}
Write-AplUtf8Atomic $AuditOutputPath ($audit | ConvertTo-Json -Depth 12) $ProductionDatePath | Out-Null
if ($null -ne $failure) { Write-Error $failure; exit 1 }
[pscustomobject]@{ Status='PASS'; ScanDate=$ScanDate; Audit=$AuditOutputPath; RequiredCount=$requiredResults.Count; OptionalCount=$optionalResults.Count; ProductionFileCount=$safeFiles.Count; ProductionBytes=$audit.ProductionBytes }
