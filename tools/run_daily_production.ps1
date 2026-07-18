[CmdletBinding(DefaultParameterSetName = 'SingleTableCard')]
param(
  [Parameter(Mandatory = $true)]
  [string]$InputCsv,

  [Parameter(Mandatory = $true)]
  [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
  [string]$ScanDate,

  [Parameter(Mandatory = $true)]
  [string]$WeekLabel,

  [string]$OutputRoot = '',
  [string]$SectorMapPath = '',
  [string]$LogoPath = '',
  [string]$PublishingArtifactsRoot = '',
  [string]$ArtifactContractPath = '',
  [string]$TopGainersCsvPath = '',
  [string]$MarketContextPath = '',
  [string]$TriggerBMetaPath = '',
  [string]$CoverNativeContractPath = '',
  [string]$SeoNativeContractPath = '',

  [Parameter(Mandatory = $true, ParameterSetName = 'SingleTableCard')]
  [string]$TableCardInputPath,

  [Parameter(Mandatory = $true, ParameterSetName = 'SingleTableCard')]
  [ValidateSet('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure','MarketObservation','Comparison')]
  [string]$TableCardType,

  [Parameter(ParameterSetName = 'SingleTableCard')]
  [string]$TableCardOutputName = '',

  [Parameter(Mandatory = $true, ParameterSetName = 'TableCardManifest')]
  [string]$TableCardManifestPath,

  [Parameter(Mandatory = $true)]
  [string]$CoverBriefPath,

  [Parameter(Mandatory = $true)]
  [string]$CoverBackgroundPath,

  [Parameter(Mandatory = $true)]
  [string]$SeoBackgroundPath,

  [switch]$RegressionTest
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')
. (Join-Path $PSScriptRoot 'table_card_bookkeeping.ps1')

if ((Get-AplFullPath $ProjectRoot) -ne (Get-AplFullPath $script:AplProjectRoot)) { throw 'Project Root resolution failed.' }
Assert-AplScanDate $ScanDate | Out-Null
$gitRoot = (& git -C $ProjectRoot rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$gitRoot)) { throw "Git Root not found for Project Root: $ProjectRoot" }
if ((Get-AplFullPath ([string]$gitRoot)) -ne (Get-AplFullPath $ProjectRoot)) { throw "Project Root/Git Root mismatch. Project='$ProjectRoot'; Git='$gitRoot'." }

function Test-PathInside([string]$Path, [string]$Parent) {
  $fullPath = (Get-AplFullPath $Path).TrimEnd('\')
  $fullParent = (Get-AplFullPath $Parent).TrimEnd('\')
  return ($fullPath.Equals($fullParent, [System.StringComparison]::OrdinalIgnoreCase) -or $fullPath.StartsWith($fullParent + '\', [System.StringComparison]::OrdinalIgnoreCase))
}

function Assert-InputFile([string]$Path, [string]$Label) {
  $full = Assert-AplProductionPath (Get-AplFullPath $Path) $Label -RegressionTest:$RegressionTest
  if (!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "$Label not found: $full" }
  return $full
}

function Assert-NewArtifact([string]$Path, [string]$Label) {
  $full = Assert-AplProductionPath (Get-AplFullPath $Path) $Label -RegressionTest:$RegressionTest
  if (Test-Path -LiteralPath $full) { throw "$Label already exists; production pipeline will not overwrite it: $full" }
  return $full
}

function Write-Utf8Text([string]$Path, [string]$Text) {
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.Encoding]::UTF8)
}

$InputCsv = Assert-InputFile $InputCsv 'InputCsv'
if (-not $RegressionTest -and $PSCmdlet.ParameterSetName -ne 'TableCardManifest') {
  throw 'Formal Daily Production requires TableCardManifest; the single-card parameter set is renderer regression only.'
}
if ($PSCmdlet.ParameterSetName -eq 'TableCardManifest') {
  $TableCardManifestPath = Assert-InputFile $TableCardManifestPath 'TableCardManifestPath'
} else {
  $TableCardInputPath = Assert-InputFile $TableCardInputPath 'TableCardInputPath'
}
$CoverBriefPath = Assert-InputFile $CoverBriefPath 'CoverBriefPath'
$CoverBackgroundPath = Assert-InputFile $CoverBackgroundPath 'CoverBackgroundPath'
$SeoBackgroundPath = Assert-InputFile $SeoBackgroundPath 'SeoBackgroundPath'
$managedParameterValues = [ordered]@{
  TopGainersCsvPath=$TopGainersCsvPath
  MarketContextPath=$MarketContextPath
  TriggerBMetaPath=$TriggerBMetaPath
  CoverNativeContractPath=$CoverNativeContractPath
  SeoNativeContractPath=$SeoNativeContractPath
  PublishingArtifactsRoot=$PublishingArtifactsRoot
}
if (-not $RegressionTest) {
  foreach ($entry in $managedParameterValues.GetEnumerator()) { if ([string]::IsNullOrWhiteSpace([string]$entry.Value)) { throw "Formal Daily Production requires -$($entry.Key)." } }
}
$hasCompleteManagedInputs = @($managedParameterValues.Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -eq $managedParameterValues.Count
if ($RegressionTest -and -not $hasCompleteManagedInputs -and @($managedParameterValues.Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) {
  throw 'Regression runner must supply either all managed preflight parameters or none.'
}
if ($hasCompleteManagedInputs) {
  $TopGainersCsvPath = Assert-InputFile $TopGainersCsvPath 'TopGainersCsvPath'
  $MarketContextPath = Assert-InputFile $MarketContextPath 'MarketContextPath'
  $TriggerBMetaPath = Assert-InputFile $TriggerBMetaPath 'TriggerBMetaPath'
  $CoverNativeContractPath = Assert-InputFile $CoverNativeContractPath 'CoverNativeContractPath'
  $SeoNativeContractPath = Assert-InputFile $SeoNativeContractPath 'SeoNativeContractPath'
}
if ($CoverBackgroundPath.Equals($SeoBackgroundPath, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw 'CoverBackgroundPath and SeoBackgroundPath must be different native source files.'
}
if ((Get-FileHash -LiteralPath $CoverBackgroundPath -Algorithm SHA256).Hash -ceq (Get-FileHash -LiteralPath $SeoBackgroundPath -Algorithm SHA256).Hash) {
  throw 'Cover and SEO native source bytes must be different; one background cannot serve both roles.'
}
if ([string]::IsNullOrWhiteSpace($SectorMapPath)) { $SectorMapPath = Join-Path $ProjectRoot 'tools\sector_map.json' }
$SectorMapPath = Assert-InputFile $SectorMapPath 'SectorMapPath'
if ([string]::IsNullOrWhiteSpace($LogoPath)) { $LogoPath = Join-Path $ProjectRoot 'Assets\Brand\APL_Deep_Scan_Brand_Logo_Renderer_Clean.png' }
$LogoPath = Assert-InputFile $LogoPath 'LogoPath'

if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Join-Path $ProjectRoot 'outputs' }
$OutputRoot = Assert-AplProductionPath (Get-AplFullPath $OutputRoot) 'OutputRoot' -RegressionTest:$RegressionTest
$formalOutputRoot = Get-AplFullPath (Join-Path $ProjectRoot 'outputs')
$regressionRoot = Get-AplFullPath (Join-Path $ProjectRoot 'tmp')
if ($RegressionTest) {
  if (-not (Test-PathInside $OutputRoot $regressionRoot)) { throw "RegressionTest OutputRoot must be inside '$regressionRoot'." }
} elseif (-not $OutputRoot.Equals($formalOutputRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Production OutputRoot must be '$formalOutputRoot'."
}
if ([string]::IsNullOrWhiteSpace($ArtifactContractPath)) { $ArtifactContractPath = Join-Path $ProjectRoot 'KnowledgeBase\Rules\APL_US_Stock_Production_Artifact_Contract.json' }
$ArtifactContractPath = Assert-AplNoReparsePath -Path $ArtifactContractPath -AllowedRoot $ProjectRoot -RequireFile
$publishingAllowedRoot = if ($RegressionTest) { $regressionRoot } else { Join-Path $ProjectRoot 'work' }
if (-not [string]::IsNullOrWhiteSpace($PublishingArtifactsRoot)) {
  $PublishingArtifactsRoot = Assert-AplNoReparsePath -Path $PublishingArtifactsRoot -AllowedRoot $publishingAllowedRoot -RequireDirectory
}
$managedInputDateRoot = $null
if ($hasCompleteManagedInputs) {
  $managedInputAllowedRoot = if ($RegressionTest) { $regressionRoot } else { Join-Path $ProjectRoot 'work\managed-inputs' }
  $managedInputDateRoot = Assert-AplNoReparsePath -Path (Join-Path $managedInputAllowedRoot $ScanDate) -AllowedRoot $managedInputAllowedRoot -RequireDirectory
}

$publishRoot = $OutputRoot
$finalDateOut = Join-Path $publishRoot $ScanDate
$runId = '{0}-{1}' -f $ScanDate, ([datetime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
$runMutex = Enter-AplNamedMutex ("orchestrator|$publishRoot|$ScanDate") 'Daily production pipeline'
try { $publishScoringMutex = Enter-AplNamedMutex ("scoring|$publishRoot|$ScanDate") 'Published scoring namespace' }
catch { Exit-AplNamedMutex $runMutex; throw }
$OutputRoot = Join-Path $publishRoot ".staging\$runId"
$dateOut = Join-Path $OutputRoot $ScanDate
$productionPackage = Join-Path $dateOut 'production-package'
$tableCardPackage = Join-Path $productionPackage 'Table Cards'
$logsRoot = Join-Path $publishRoot 'logs'

$allowedTableCardTypes = @('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure','MarketObservation','Comparison')
$requiredTriggerCCards = @('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure')
$tableCards = New-Object System.Collections.Generic.List[object]
if ($PSCmdlet.ParameterSetName -eq 'TableCardManifest') {
  $manifest = Read-AplUtf8Json $TableCardManifestPath
  if ($null -eq $manifest.SchemaVersion -or [string]$manifest.SchemaVersion -ne 'APL Table Card Manifest v1.1') { throw 'Table Card manifest SchemaVersion must be APL Table Card Manifest v1.1.' }
  if ($null -eq $manifest.ScanDate -or [string]$manifest.ScanDate -ne $ScanDate) { throw "Table Card manifest ScanDate must match runner ScanDate '$ScanDate'." }
  $manifestCards = @($manifest.Cards)
  if ($manifestCards.Count -eq 0) { throw 'Table Card manifest Cards must contain at least one item.' }
  $manifestDir = Split-Path -Parent $TableCardManifestPath
  $seenCardTypes = @{}
  $seenOutputNames = @{}
  foreach ($card in $manifestCards) {
    foreach ($name in @('CardType','InputSchemaVersion','InputPath','OutputName','Required')) { if ($null -eq $card.PSObject.Properties[$name]) { throw "Table Card manifest item missing '$name'." } }
    $cardType = [string]$card.CardType
    if ($allowedTableCardTypes -notcontains $cardType) { throw "Unsupported Table Card type in manifest: $cardType" }
    if ($seenCardTypes.ContainsKey($cardType)) { throw "Duplicate CardType in Table Card manifest: $cardType" }
    $seenCardTypes[$cardType] = $true
    if ([string]$card.InputSchemaVersion -cne 'APL Table Card Input v1.1') { throw "Table Card manifest InputSchemaVersion must be APL Table Card Input v1.1 for '$cardType'." }
    if ($card.Required -isnot [bool]) { throw "Table Card manifest Required must be boolean for '$cardType'." }
    $outputName = [string]$card.OutputName
    if ([string]::IsNullOrWhiteSpace($outputName) -or [System.IO.Path]::IsPathRooted($outputName) -or [System.IO.Path]::GetFileName($outputName) -cne $outputName) { throw "Table Card OutputName must be a file name without directory or traversal segments: $outputName" }
    if ([System.IO.Path]::GetExtension($outputName) -ine '.png') { throw "Table Card OutputName must use .png: $outputName" }
    if ($seenOutputNames.ContainsKey($outputName.ToLowerInvariant())) { throw "Duplicate OutputName in Table Card manifest: $outputName" }
    $seenOutputNames[$outputName.ToLowerInvariant()] = $true
    $inputValue = [string]$card.InputPath
    if ([string]::IsNullOrWhiteSpace($inputValue)) { throw "Table Card InputPath is empty for '$cardType'." }
    $resolvedInput = if ([System.IO.Path]::IsPathRooted($inputValue)) { $inputValue } else { Join-Path $manifestDir $inputValue }
    $resolvedInput = Assert-InputFile $resolvedInput "TableCardInputPath[$cardType]"
    $outputPath = Join-Path $tableCardPackage $outputName
    $tableCards.Add([pscustomobject]@{ CardType=$cardType; InputPath=$resolvedInput; OutputName=$outputName; Required=[bool]$card.Required; OutputPath=$outputPath; LogPath=[System.IO.Path]::ChangeExtension($outputPath,'.table-card-log.txt') })
  }
  if (-not $RegressionTest) {
    foreach ($requiredType in $requiredTriggerCCards) {
      $requiredItem = @($tableCards | Where-Object { $_.CardType -eq $requiredType -and $_.Required })
      if ($requiredItem.Count -ne 1) { throw "Trigger C production manifest must contain required CardType '$requiredType' with Required=true." }
    }
  }
} else {
  $safeTableType = $TableCardType -replace '[^A-Za-z0-9_-]', '_'
  if ([string]::IsNullOrWhiteSpace($TableCardOutputName)) { $TableCardOutputName = "APL_Blog_${safeTableType}_${ScanDate}.png" }
  if ([System.IO.Path]::IsPathRooted($TableCardOutputName) -or [System.IO.Path]::GetFileName($TableCardOutputName) -cne $TableCardOutputName) { throw 'TableCardOutputName must be a file name without directory or traversal segments.' }
  $outputPath = Join-Path $tableCardPackage $TableCardOutputName
  $tableCards.Add([pscustomobject]@{ CardType=$TableCardType; InputPath=$TableCardInputPath; OutputName=$TableCardOutputName; Required=$true; OutputPath=$outputPath; LogPath=[System.IO.Path]::ChangeExtension($outputPath,'.table-card-log.txt') })
}
$tableCardResultManifest = if ($PSCmdlet.ParameterSetName -eq 'TableCardManifest') { Join-Path $tableCardPackage "APL_Table_Card_Manifest_${ScanDate}.json" } else { $null }

$rankingCsv = Join-Path $dateOut "APL_Momentum_Score_Full_Ranking_$ScanDate.csv"
$topTxt = Join-Path $dateOut "APL_Quant_Top_30_$ScanDate.txt"
$topMd = Join-Path $dateOut "APL_Quant_Top_30_$ScanDate.md"
$watchlistTxt = Join-Path $dateOut "APL_Momentum_Leaders_Watchlist_$ScanDate.txt"
$removedAudit = Join-Path $dateOut "removed-below-sma200-$ScanDate.txt"
$retainedAudit = Join-Path $dateOut "retained-missing-sma200-$ScanDate.txt"
$overviewMd = Join-Path $dateOut "APL_Momentum_Leaders_Overview_$ScanDate.md"
$metaJson = Join-Path $dateOut "APL_Momentum_Leaders_Meta_$ScanDate.json"
$sourceCopy = Join-Path $dateOut "APL_Momentum_Leaders_Source_$ScanDate.csv"
$dashboardContract = Join-Path $dateOut "APL_DeepScan_Dashboard_Input_$ScanDate.json"
$socialContract = Join-Path $dateOut "APL_DeepScan_Social_Input_$ScanDate.json"
$dashboardSvg = Join-Path $dateOut "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_1920x1080.svg"
$dashboardPng = Join-Path $productionPackage "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_1920x1080.png"
$dashboardLog = Join-Path $dateOut "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_Render_Log.txt"
$socialSvg = Join-Path $dateOut "APL_DeepScan_Social_Card_${ScanDate}_1080x1350.svg"
$socialPng = Join-Path $productionPackage "APL_DeepScan_Social_Card_${ScanDate}_1080x1350.png"
$socialLog = Join-Path $dateOut "APL_DeepScan_Social_Card_${ScanDate}_Render_Log.txt"
$coverOutput = Join-Path $productionPackage "APL_Momentum_Leaders_Blog_Cover_${ScanDate}_1080x1350.png"
$coverLog = [System.IO.Path]::ChangeExtension($coverOutput, '.overlay-log.txt')
$seoOutput = Join-Path $productionPackage "APL_Momentum_Leaders_Blog_SEO_${ScanDate}_1280x720.png"
$seoLog = [System.IO.Path]::ChangeExtension($seoOutput, '.overlay-log.txt')
$whatsAppPackage = Join-Path $productionPackage "WhatsApp_${ScanDate}.md"
$blogMarkdownPackage = Join-Path $productionPackage "APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.md"
$blogHtmlPackage = Join-Path $productionPackage "APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.html"
$companyAnalysisPackage = Join-Path $productionPackage "table-card-log\APL_Momentum_Leaders_Top_30_Company_Business_Analysis_${ScanDate}.md"
$editorialAuditPackage = Join-Path $productionPackage "APL_Editorial_Completion_Audit_${ScanDate}.json"
$productionPackageManifest = Join-Path $productionPackage "APL_Production_Package_Manifest_${ScanDate}.json"
$finalAuditPath = Assert-NewArtifact (Join-Path $finalDateOut "Final_Production_Audit_${ScanDate}.json") 'FinalProductionAudit'

$rootCopies = @()
$tableCardExpectedArtifacts = @($tableCards | ForEach-Object { @($_.OutputPath,$_.LogPath) })
$expectedArtifacts = @($rankingCsv,$topTxt,$topMd,$watchlistTxt,$removedAudit,$retainedAudit,$overviewMd,$metaJson,$sourceCopy,$dashboardContract,$socialContract,$dashboardSvg,$dashboardPng,$dashboardLog,$socialSvg,$socialPng,$socialLog,$coverOutput,$coverLog,$seoOutput,$seoLog,$productionPackageManifest) + $tableCardExpectedArtifacts + @($tableCardResultManifest | Where-Object { $_ }) + $rootCopies
function Get-PublishedPath([string]$StagePath) {
  $full = Get-AplFullPath $StagePath
  if ($full.StartsWith($dateOut.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return Join-Path $finalDateOut $full.Substring($dateOut.TrimEnd('\').Length + 1) }
  if ($full.StartsWith($OutputRoot.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return Join-Path $publishRoot $full.Substring($OutputRoot.TrimEnd('\').Length + 1) }
  throw "Cannot map staging artifact to publish path: $full"
}
foreach ($artifact in $expectedArtifacts) { Assert-NewArtifact (Get-PublishedPath $artifact) 'Expected published artifact' | Out-Null }

if (!(Test-Path -LiteralPath $OutputRoot)) { New-Item -ItemType Directory -Path $OutputRoot | Out-Null }
if (!(Test-Path -LiteralPath $logsRoot)) { New-Item -ItemType Directory -Path $logsRoot | Out-Null }
$pipelineLog = Assert-NewArtifact (Join-Path $logsRoot "daily-production-$runId.log") 'PipelineLog'
$tracePath = Assert-NewArtifact (Join-Path $logsRoot "daily-production-$runId.jsonl") 'PipelineTrace'
$dailyStatePath = Assert-NewArtifact (Join-Path $logsRoot "daily-production-state-$ScanDate.json") 'DailyProductionState'
$script:stepNumber = 0
$script:completedArtifacts = New-Object System.Collections.Generic.List[string]
$script:tableCardResults = New-Object System.Collections.Generic.List[object]

function Write-TableCardPublicationManifest {
  if ([string]::IsNullOrWhiteSpace([string]$tableCardResultManifest)) { return }
  $requiredFailed = @($script:tableCardResults | Where-Object { $_.Required -and $_.Status -ne 'PASS' }).Count
  $document = [ordered]@{
    SchemaVersion = 'APL Table Card Publication Manifest v1.0'
    ScanDate = $ScanDate
    SourceManifest = Split-Path $TableCardManifestPath -Leaf
    Status = if ($requiredFailed -eq 0 -and $script:tableCardResults.Count -eq $tableCards.Count) { 'PASS' } else { 'INCOMPLETE' }
    Cards = (ConvertTo-AplObjectArray $script:tableCardResults)
  }
  Write-Utf8Text $tableCardResultManifest ($document | ConvertTo-Json -Depth 8)
}

function Write-ProductionPackageManifest {
  foreach ($forbiddenRootArtifact in @(
    (Join-Path $dateOut (Split-Path $dashboardPng -Leaf)),
    (Join-Path $dateOut (Split-Path $coverOutput -Leaf)),
    (Join-Path $dateOut (Split-Path $seoOutput -Leaf)),
    (Join-Path $dateOut (Split-Path $whatsAppPackage -Leaf))
  )) {
    if (Test-Path -LiteralPath $forbiddenRootArtifact) { throw "Production package artifact must not be duplicated at date root: $forbiddenRootArtifact" }
  }
  foreach ($card in $tableCards) {
    $rootDuplicate = Join-Path $dateOut $card.OutputName
    if (Test-Path -LiteralPath $rootDuplicate) { throw "Table Card must not be duplicated at date root: $rootDuplicate" }
  }

  $requiredDefinitions = New-Object System.Collections.Generic.List[object]
  foreach ($card in $tableCards) {
    if ($card.Required) { [void]$requiredDefinitions.Add([pscustomobject]@{ Id=("table-card-" + $card.CardType); Path=$card.OutputPath }) }
  }
  foreach ($definition in @(
    [pscustomobject]@{Id='dashboard-png';Path=$dashboardPng},
    [pscustomobject]@{Id='social-card-png';Path=$socialPng},
    [pscustomobject]@{Id='cover';Path=$coverOutput},
    [pscustomobject]@{Id='seo';Path=$seoOutput},
    [pscustomobject]@{Id='whatsapp';Path=$whatsAppPackage},
    [pscustomobject]@{Id='formal-blog-markdown';Path=$blogMarkdownPackage},
    [pscustomobject]@{Id='formal-blog-html';Path=$blogHtmlPackage},
    [pscustomobject]@{Id='company-business-analysis';Path=$companyAnalysisPackage},
    [pscustomobject]@{Id='editorial-completion-audit';Path=$editorialAuditPackage}
  )) { [void]$requiredDefinitions.Add($definition) }

  $requiredRecords = New-Object System.Collections.Generic.List[object]
  $seenIds = @{}
  $seenPaths = @{}
  foreach ($definition in $requiredDefinitions.ToArray()) {
    $id = [string]$definition.Id
    $path = Assert-AplNoReparsePath -Path ([string]$definition.Path) -AllowedRoot $productionPackage -RequireFile
    $relative = $path.Substring($productionPackage.TrimEnd('\').Length + 1).Replace('\','/')
    $idKey = $id.ToLowerInvariant(); $pathKey = $relative.ToLowerInvariant()
    if ($seenIds.ContainsKey($idKey)) { throw "Duplicate required production package Id: $id" }
    if ($seenPaths.ContainsKey($pathKey)) { throw "Duplicate required production package path: $relative" }
    $seenIds[$idKey] = $true; $seenPaths[$pathKey] = $true
    $item = Get-Item -LiteralPath $path
    if ($item.Length -le 0) { throw "Required production package artifact is empty: $relative" }
    [void]$requiredRecords.Add([pscustomobject]@{Id=$id;RelativePath=$relative;Size=[long]$item.Length;SHA256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash})
  }
  $inventory = @(Get-AplArchiveInventory $productionPackage | Where-Object { $_.RelativePath -cne (Split-Path $productionPackageManifest -Leaf) })
  $document = [ordered]@{
    SchemaVersion = 'APL Production Package Manifest v1.0'
    ScanDate = $ScanDate
    Status = 'PASS'
    PackageRoot = 'production-package'
    RequiredCount = $requiredRecords.Count
    FileCount = $inventory.Count
    TotalBytes = [long](($inventory | Measure-Object Size -Sum).Sum)
    GeneratedUtc = [datetime]::UtcNow.ToString('o')
    Required = [object[]]$requiredRecords.ToArray()
    Files = [object[]]@($inventory | ForEach-Object { [pscustomobject]@{RelativePath=[string]$_.RelativePath;Size=[long]$_.Size;SHA256=[string]$_.SHA256} })
  }
  Write-Utf8Text $productionPackageManifest ($document | ConvertTo-Json -Depth 10)
}

function Add-Trace([hashtable]$Record) {
  $line = ([pscustomobject]$Record | ConvertTo-Json -Compress -Depth 6)
  [System.IO.File]::AppendAllText($tracePath, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
}

function Add-Log([string]$Message) {
  $line = '[{0}] {1}' -f ([datetime]::UtcNow.ToString('o')), $Message
  [System.IO.File]::AppendAllText($pipelineLog, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
}

function Invoke-PipelineStep {
  param([string]$Name, [string]$ScriptPath, [string[]]$Arguments, [string[]]$Artifacts = @())
  $script:stepNumber++
  $started = [datetime]::UtcNow
  Add-Log "STEP $script:stepNumber START $Name"
  Add-Trace @{ step=$script:stepNumber; name=$Name; event='start'; utc=$started.ToString('o'); script=$ScriptPath; arguments=$Arguments }
  try {
    $output = @(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    foreach ($line in $output) { Add-Log "[$Name] $line" }
    if ($exitCode -ne 0) { throw "Step '$Name' failed with exit code $exitCode." }
    foreach ($artifact in $Artifacts) {
      if (!(Test-Path -LiteralPath $artifact -PathType Leaf)) { throw "Step '$Name' did not create required artifact: $artifact" }
      if ((Get-Item -LiteralPath $artifact).Length -le 0) { throw "Step '$Name' created empty artifact: $artifact" }
      $script:completedArtifacts.Add($artifact)
    }
    $ended = [datetime]::UtcNow
    Add-Trace @{ step=$script:stepNumber; name=$Name; event='complete'; utc=$ended.ToString('o'); durationMs=[math]::Round(($ended-$started).TotalMilliseconds); artifacts=$Artifacts }
    Add-Log "STEP $script:stepNumber PASS $Name"
  } catch {
    $ended = [datetime]::UtcNow
    Add-Trace @{ step=$script:stepNumber; name=$Name; event='failed'; utc=$ended.ToString('o'); durationMs=[math]::Round(($ended-$started).TotalMilliseconds); error=$_.Exception.Message }
    Add-Log "STEP $script:stepNumber FAIL $Name :: $($_.Exception.Message)"
    throw
  }
}

function Complete-InternalStep([string]$Name, [scriptblock]$Action, [string[]]$Artifacts = @()) {
  $script:stepNumber++
  $started = [datetime]::UtcNow
  Add-Log "STEP $script:stepNumber START $Name"
  Add-Trace @{ step=$script:stepNumber; name=$Name; event='start'; utc=$started.ToString('o'); internal=$true }
  try {
    & $Action
    foreach ($artifact in $Artifacts) {
      if (!(Test-Path -LiteralPath $artifact -PathType Leaf) -or (Get-Item -LiteralPath $artifact).Length -le 0) { throw "Internal step '$Name' missing required artifact: $artifact" }
      $script:completedArtifacts.Add($artifact)
    }
    $ended = [datetime]::UtcNow
    Add-Trace @{ step=$script:stepNumber; name=$Name; event='complete'; utc=$ended.ToString('o'); durationMs=[math]::Round(($ended-$started).TotalMilliseconds); artifacts=$Artifacts }
    Add-Log "STEP $script:stepNumber PASS $Name"
  } catch {
    $ended = [datetime]::UtcNow
    Add-Trace @{ step=$script:stepNumber; name=$Name; event='failed'; utc=$ended.ToString('o'); error=$_.Exception.Message }
    Add-Log "STEP $script:stepNumber FAIL $Name :: $($_.Exception.Message)"
    throw
  }
}

$processScript = Join-Path $PSScriptRoot 'process_apl_momentum_leaders.ps1'
$validatorScript = Join-Path $PSScriptRoot 'validate_renderer_inputs.ps1'
$dashboardScript = Join-Path $PSScriptRoot 'render_deep_scan_dashboard_svg.ps1'
$svgToPngScript = Join-Path $PSScriptRoot 'convert_svg_to_png.ps1'
$socialScript = Join-Path $PSScriptRoot 'render_deep_scan_social_card_svg.ps1'
$tableScript = Join-Path $PSScriptRoot 'render_blog_table_cards.ps1'
$overlayScript = Join-Path $PSScriptRoot 'render_blog_cover_overlay.ps1'
$archiveScript = Join-Path $PSScriptRoot 'archive_daily_production.ps1'
$artifactAuditScript = Join-Path $PSScriptRoot 'test_production_artifact_contract.ps1'
$completionScript = Join-Path $PSScriptRoot 'complete_daily_production.ps1'
$managedInputValidatorScript = Join-Path $PSScriptRoot 'validate_managed_inputs.ps1'

$status = 'FAILED'
try {
  Add-Log "RUN START $runId ProjectRoot=$ProjectRoot GitRoot=$gitRoot PublishRoot=$publishRoot StagingRoot=$OutputRoot RegressionTest=$([bool]$RegressionTest)"
  if ($hasCompleteManagedInputs) {
    $preflightArgs = @(
      '-InputCsv',$InputCsv,
      '-TopGainersCsvPath',$TopGainersCsvPath,
      '-MarketContextPath',$MarketContextPath,
      '-TriggerBMetaPath',$TriggerBMetaPath,
      '-ScanDate',$ScanDate,
      '-TableCardManifestPath',$TableCardManifestPath,
      '-CoverBriefPath',$CoverBriefPath,
      '-CoverBackgroundPath',$CoverBackgroundPath,
      '-SeoBackgroundPath',$SeoBackgroundPath,
      '-CoverNativeContractPath',$CoverNativeContractPath,
      '-SeoNativeContractPath',$SeoNativeContractPath,
      '-PublishingArtifactsRoot',$PublishingArtifactsRoot
    )
    if ($RegressionTest) { $preflightArgs += '-RegressionTest' }
    Invoke-PipelineStep 'ManagedInputPreflight' $managedInputValidatorScript $preflightArgs
  }
  $scoringRegressionArg = if ($RegressionTest) { @('-RegressionTest') } else { @() }
  Invoke-PipelineStep 'ScoringRanking' $processScript (@('-InputCsv',$InputCsv,'-ScanDate',$ScanDate,'-WeekLabel',$WeekLabel,'-OutputRoot',$OutputRoot,'-SkipRootCopies') + $scoringRegressionArg) @($rankingCsv,$topTxt,$topMd,$overviewMd,$metaJson,$sourceCopy)
  if ($hasCompleteManagedInputs) {
    Complete-InternalStep 'VerifyTriggerBEvidence' {
      $managedRoot = if ($RegressionTest) { $regressionRoot } else { Join-Path $ProjectRoot 'work\managed-inputs' }
      $managedMeta = Read-AplStrictJson $TriggerBMetaPath $managedRoot
      $generatedMeta = Read-AplStrictJson $metaJson $OutputRoot
      foreach ($field in @('scanDate','weekLabel','universe','qualified','leaders','leaderLock','averageMomentum','averageBuyability','removedBelowSma200Count','retainedMissingSma200Count','finalWatchlistCount')) {
        if ([string]$managedMeta.$field -cne [string]$generatedMeta.$field) { throw "Managed Trigger B metadata is stale or inconsistent: $field." }
      }
      $managedRanking = Assert-AplNoReparsePath -Path ([string]$managedMeta.fullRankingCsv) -AllowedRoot $managedRoot -RequireFile
      if ((Get-FileHash -LiteralPath $managedRanking -Algorithm SHA256).Hash -cne (Get-FileHash -LiteralPath $rankingCsv -Algorithm SHA256).Hash) { throw 'Managed Trigger B ranking does not match the ranking generated by this Production run.' }
      if ((Get-FileHash -LiteralPath $InputCsv -Algorithm SHA256).Hash -cne (Get-FileHash -LiteralPath $sourceCopy -Algorithm SHA256).Hash) { throw 'Scoring source copy does not match the managed cumulative screener input.' }
    }
  }
  Complete-InternalStep 'WatchlistSma200Audit' {
    foreach ($path in @($watchlistTxt,$removedAudit,$retainedAudit)) { if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Audit artifact missing: $path" } }
    $meta = Read-AplUtf8Json $metaJson
    foreach ($name in @('removedBelowSma200Count','retainedMissingSma200Count','finalWatchlistCount')) { if ($null -eq $meta.PSObject.Properties[$name]) { throw "Scoring metadata missing '$name'." } }
    $watchlistRaw = [System.IO.File]::ReadAllText($watchlistTxt, [System.Text.Encoding]::UTF8).Trim()
    $watchlistSymbols = if ([string]::IsNullOrWhiteSpace($watchlistRaw)) { @() } else { @($watchlistRaw.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) }
    $removedLines = @([System.IO.File]::ReadAllLines($removedAudit, [System.Text.Encoding]::UTF8))
    $retainedLines = @([System.IO.File]::ReadAllLines($retainedAudit, [System.Text.Encoding]::UTF8))
    $removedCount = [math]::Max(0, $removedLines.Count - 1)
    $retainedCount = [math]::Max(0, $retainedLines.Count - 1)
    if ($watchlistSymbols.Count -ne [int]$meta.finalWatchlistCount) { throw "Watchlist count mismatch. File=$($watchlistSymbols.Count); Meta=$($meta.finalWatchlistCount)." }
    if ($removedCount -ne [int]$meta.removedBelowSma200Count) { throw "Removed SMA200 audit count mismatch. File=$removedCount; Meta=$($meta.removedBelowSma200Count)." }
    if ($retainedCount -ne [int]$meta.retainedMissingSma200Count) { throw "Retained missing SMA200 audit count mismatch. File=$retainedCount; Meta=$($meta.retainedMissingSma200Count)." }
    $removedSymbols = @($removedLines | Select-Object -Skip 1 | ForEach-Object { ($_ -split ',', 2)[0].Trim() })
    $unexpected = @($removedSymbols | Where-Object { $watchlistSymbols -contains $_ })
    if ($unexpected.Count -gt 0) { throw "Below-SMA200 symbols remain in watchlist: $($unexpected -join ',')." }
    $retainedSymbols = @($retainedLines | Select-Object -Skip 1 | ForEach-Object { ($_ -split ',', 2)[0].Trim() })
    $missingRetained = @($retainedSymbols | Where-Object { $watchlistSymbols -notcontains $_ })
    if ($missingRetained.Count -gt 0) { throw "Missing-SMA200 symbols were not retained in watchlist: $($missingRetained -join ',')." }
  } @($watchlistTxt,$removedAudit,$retainedAudit)

  Complete-InternalStep 'BuildRendererContracts' {
    $meta = Read-AplUtf8Json $metaJson
    $common = [ordered]@{ SchemaVersion='APL Deep-Scan Renderer Input v1.0'; RankingCsv=$rankingCsv; ScanDate=$ScanDate; SectorMapPath=$SectorMapPath; OutputPath=$dateOut; LogoPath=$LogoPath; WeekLabel=$WeekLabel; ScanUniverseCount=[int]$meta.universe; ScanQualifiedCount=[int]$meta.qualified; LeaderCapacity=30; Meta=[ordered]@{ ProductionMode='Deep-Scan Research Mode'; ProductionNote="run_daily_production $runId" } }
    $dashboard = [ordered]@{}; foreach ($key in $common.Keys) { $dashboard[$key]=$common[$key] }; $dashboard.RendererType='Dashboard'
    $social = [ordered]@{}; foreach ($key in $common.Keys) { $social[$key]=$common[$key] }; $social.RendererType='Social'
    Write-Utf8Text $dashboardContract (($dashboard | ConvertTo-Json -Depth 6))
    Write-Utf8Text $socialContract (($social | ConvertTo-Json -Depth 6))
  } @($dashboardContract,$socialContract)

  Complete-InternalStep 'PrepareProductionPackage' {
    foreach ($directory in @($productionPackage,$tableCardPackage)) {
      if (!(Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
      Assert-AplNoReparsePath -Path $directory -AllowedRoot $dateOut -RequireDirectory | Out-Null
    }
  } @()

  $regressionArg = if ($RegressionTest) { @('-RegressionTest') } else { @() }
  Invoke-PipelineStep 'ValidateDashboardInput' $validatorScript (@('-RendererType','Dashboard','-InputPath',$dashboardContract) + $regressionArg)
  Invoke-PipelineStep 'ValidateSocialInput' $validatorScript (@('-RendererType','Social','-InputPath',$socialContract) + $regressionArg)
  Invoke-PipelineStep 'RenderDashboard' $dashboardScript (@('-InputPath',$dashboardContract) + $regressionArg) @($dashboardSvg,$dashboardLog)
  Invoke-PipelineStep 'ExportDashboardPng' $svgToPngScript (@('-InputSvg',$dashboardSvg,'-OutputPng',$dashboardPng,'-Width','1920','-Height','1080') + $regressionArg) @($dashboardPng)
  Invoke-PipelineStep 'RenderSocialCard' $socialScript (@('-InputPath',$socialContract) + $regressionArg) @($socialSvg,$socialLog)
  Invoke-PipelineStep 'ExportSocialPng' $svgToPngScript (@('-InputSvg',$socialSvg,'-OutputPng',$socialPng,'-Width','1080','-Height','1350') + $regressionArg) @($socialPng)
  foreach ($card in $tableCards) {
    $record = New-AplTableCardResult -Source ([pscustomobject]@{ CardType=$card.CardType; InputPath=$card.InputPath; InputSha256=(Get-FileHash -LiteralPath $card.InputPath -Algorithm SHA256).Hash; OutputName=$card.OutputName; Required=[bool]$card.Required; OutputPath=$null; LogPath=$null; Bytes=$null; Sha256=$null; LogBytes=$null; LogSha256=$null; Error=$null }) -Status PENDING
    try {
      Invoke-PipelineStep "ValidateTableCardInput[$($card.CardType)]" $validatorScript (@('-RendererType','TableCard','-TableCardInputPath',$card.InputPath,'-CardType',$card.CardType) + $regressionArg)
      Invoke-PipelineStep "RenderTableCard[$($card.CardType)]" $tableScript (@('-CardType',$card.CardType,'-OutDir',$tableCardPackage,'-Date',$ScanDate,'-InputPath',$card.InputPath,'-OutputName',$card.OutputName) + $regressionArg) @($card.OutputPath,$card.LogPath)
      $item = Get-Item -LiteralPath $card.OutputPath
      $record.Status = 'PASS'
      $record.OutputPath = Get-PublishedPath $card.OutputPath
      $record.LogPath = Get-PublishedPath $card.LogPath
      $record.Bytes = $item.Length
      $record.Sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
    } catch {
      $record.Status = 'FAIL'
      $record.Error = $_.Exception.Message
      if (-not $card.Required) {
        foreach ($partial in @($card.OutputPath,$card.LogPath)) {
          if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
        }
      }
    }
    Add-AplTableCardResult -Collection $script:tableCardResults -Result $record
    Write-TableCardPublicationManifest
    Add-Trace @{ event='table-card-result'; utc=[datetime]::UtcNow.ToString('o'); cardType=$card.CardType; required=[bool]$card.Required; status=$record.Status; outputName=$card.OutputName; outputPath=$record.OutputPath; bytes=$record.Bytes; sha256=$record.Sha256; error=$record.Error }
    if ($record.Status -ne 'PASS' -and $card.Required) { throw "Required Table Card '$($card.CardType)' failed: $($record.Error)" }
  }
  if ($PSCmdlet.ParameterSetName -eq 'TableCardManifest') {
    Complete-InternalStep 'FinalizeTableCardManifest' {
      $failedRequired = @($script:tableCardResults | Where-Object { $_.Required -and $_.Status -ne 'PASS' })
      if ($failedRequired.Count -gt 0) { throw "Required Table Cards failed: $($failedRequired.CardType -join ',')." }
      Write-TableCardPublicationManifest
      $publishedManifest = Read-AplUtf8Json $tableCardResultManifest
      if ([string]$publishedManifest.Status -ne 'PASS') { throw 'Table Card publication manifest did not reach PASS.' }
    } @($tableCardResultManifest)
  }
  Invoke-PipelineStep 'RenderCoverOverlay' $overlayScript @('-BriefPath',$CoverBriefPath,'-BackgroundPath',$CoverBackgroundPath,'-OutputPath',$coverOutput,'-Variant','Cover','-LogoPath',$LogoPath) @($coverOutput,$coverLog)
  Invoke-PipelineStep 'RenderSeoOverlay' $overlayScript @('-BriefPath',$CoverBriefPath,'-BackgroundPath',$SeoBackgroundPath,'-OutputPath',$seoOutput,'-Variant','SEO','-LogoPath',$LogoPath) @($seoOutput,$seoLog)
  Complete-InternalStep 'ImportPublishingArtifacts' {
    if ([string]::IsNullOrWhiteSpace($PublishingArtifactsRoot)) { return }
    $publishingRootFull = Assert-AplNoReparsePath -Path $PublishingArtifactsRoot -AllowedRoot $publishingAllowedRoot -RequireDirectory
    foreach ($item in @(Get-AplSafeFileList $publishingRootFull)) {
      $relative = $item.FullName.Substring($publishingRootFull.Length + 1).Replace('\','/')
      if (-not (Test-AplArchiveEligible $relative)) { continue }
      $target = Join-Path $dateOut $relative.Replace('/','\')
      if (Test-Path -LiteralPath $target) { throw "Publishing artifact conflicts with generated artifact: $relative" }
      $parent = Split-Path -Parent $target
      if (!(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
      Assert-AplNoReparsePath -Path $parent -AllowedRoot $dateOut -RequireDirectory | Out-Null
      Copy-Item -LiteralPath $item.FullName -Destination $target
    }
  } @()
  Complete-InternalStep 'NormalizeStagedArtifacts' {
    foreach ($contractPath in @($dashboardContract,$socialContract)) {
      $contract = Read-AplUtf8Json $contractPath
      $contract.RankingCsv = Join-Path $finalDateOut (Split-Path $rankingCsv -Leaf)
      $contract.OutputPath = $finalDateOut
      Write-Utf8Text $contractPath ($contract | ConvertTo-Json -Depth 6)
    }
    $publishedMeta = Read-AplUtf8Json $metaJson
    $publishedMeta.fullRankingCsv = Join-Path $finalDateOut (Split-Path $rankingCsv -Leaf)
    $publishedMeta.top30Txt = Join-Path $finalDateOut (Split-Path $topTxt -Leaf)
    Write-Utf8Text $metaJson ($publishedMeta | ConvertTo-Json -Depth 6)
    $tableCardLogs = @($tableCards | ForEach-Object { $_.LogPath } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    foreach ($path in @($dashboardLog,$socialLog,$coverLog,$seoLog) + $tableCardLogs) {
      $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
      $text = $text.Replace($dateOut, $finalDateOut).Replace($OutputRoot, $publishRoot)
      Write-Utf8Text $path $text
    }
    if ($PSCmdlet.ParameterSetName -eq 'TableCardManifest') {
      foreach ($record in @($script:tableCardResults | Where-Object { $_.Status -eq 'PASS' })) {
        $card = @($tableCards | Where-Object { $_.CardType -eq $record.CardType })[0]
        $outputItem = Get-Item -LiteralPath $card.OutputPath
        $logItem = Get-Item -LiteralPath $card.LogPath
        $record.Bytes = $outputItem.Length
        $record.Sha256 = (Get-FileHash -LiteralPath $outputItem.FullName -Algorithm SHA256).Hash
        $record.LogBytes = $logItem.Length
        $record.LogSha256 = (Get-FileHash -LiteralPath $logItem.FullName -Algorithm SHA256).Hash
      }
      Write-TableCardPublicationManifest
    }
  } @()

  Complete-InternalStep 'FinalizeProductionPackageManifest' {
    Write-ProductionPackageManifest
  } @($productionPackageManifest)

  Complete-InternalStep 'PublishArtifacts' {
    if (Test-Path -LiteralPath $finalDateOut) { throw "Final date output appeared during staging: $finalDateOut" }
    Move-Item -LiteralPath $dateOut -Destination $finalDateOut
  } @()

  $publishedPaths = @($script:completedArtifacts | Where-Object { Test-PathInside $_ $OutputRoot } | ForEach-Object { Get-PublishedPath $_ } | Sort-Object -Unique)
  Complete-InternalStep 'LockPublishedMachineArtifacts' {
    foreach ($path in $publishedPaths) {
      if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Published machine artifact missing before immutable lock: $path" }
      $item = Get-Item -LiteralPath $path
      $item.IsReadOnly = $true
      $locked = Get-Item -LiteralPath $path
      if (-not $locked.IsReadOnly) { throw "Published machine artifact immutable lock failed: $path" }
    }
  } @()

  $publishedArtifacts = @($publishedPaths | ForEach-Object { $item=Get-Item -LiteralPath $_; [ordered]@{ path=$item.FullName; bytes=$item.Length; sha256=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash } })
  $auditArgs = @('-ProductionDatePath',$finalDateOut,'-ScanDate',$ScanDate,'-ContractPath',$ArtifactContractPath,'-AuditOutputPath',$finalAuditPath)
  if ($hasCompleteManagedInputs) { $auditArgs += @('-ManagedInputDatePath',$managedInputDateRoot) }
  if ($RegressionTest) { $auditArgs += '-RegressionTest' }
  Invoke-PipelineStep 'FinalProductionAudit' $artifactAuditScript $auditArgs @($finalAuditPath)
  (Get-Item -LiteralPath $finalAuditPath).IsReadOnly = $true

  $status = 'PRODUCTION_PASS'
  Add-Trace @{ event='final-production-audit'; runId=$runId; utc=[datetime]::UtcNow.ToString('o'); status='PASS'; audit=$finalAuditPath; next='Archive' }
  Add-Log "PRODUCTION PASS $runId; ARCHIVE REQUIRED"

  $archiveRoot = if ($RegressionTest) { Join-Path $publishRoot '_archive' } else { Join-Path $ProjectRoot 'Archive' }
  $archiveArgs = @('-SourceDatePath',$finalDateOut,'-ScanDate',$ScanDate,'-FinalAuditPath',$finalAuditPath,'-ArchiveRoot',$archiveRoot)
  if ($RegressionTest) { $archiveArgs += '-RegressionTest' }
  Invoke-PipelineStep 'ArchiveDailyProduction' $archiveScript $archiveArgs
  $archiveDestination = Join-Path $archiveRoot (Join-Path $ScanDate.Substring(0,4) $ScanDate)
  $archiveManifestPath = Join-Path $archiveDestination 'archive-manifest.json'
  $archiveIndexPath = Join-Path $archiveRoot 'index.md'
  Complete-InternalStep 'VerifyArchivePass' {
    foreach ($requiredArchiveArtifact in @($archiveManifestPath,$archiveIndexPath)) {
      if (!(Test-Path -LiteralPath $requiredArchiveArtifact -PathType Leaf)) { throw "Archive verification artifact missing: $requiredArchiveArtifact" }
    }
    $archiveAudit = Read-AplStrictJson $archiveManifestPath $archiveDestination
    $archiveActual = @(Get-AplArchiveInventory $archiveDestination -ExcludeManifest)
    Assert-AplArchiveManifest $archiveAudit $ScanDate 'PASS' $archiveActual | Out-Null
    Assert-AplArchiveIndexRow $archiveIndexPath $archiveAudit $archiveRoot | Out-Null
  } @()

  $status = 'FINALIZING'
  $completionArgs = @('-ScanDate',$ScanDate,'-FinalAuditPath',$finalAuditPath,'-ArchiveManifestPath',$archiveManifestPath,'-ArchiveIndexPath',$archiveIndexPath,'-PipelineLog',$pipelineLog,'-PipelineTrace',$tracePath,'-StatePath',$dailyStatePath)
  if ($RegressionTest) { $completionArgs += '-RegressionTest' }
  $completionOutput = @(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $completionScript @completionArgs 2>&1)
  if ($LASTEXITCODE -ne 0) { throw "Daily production finalization failed: $($completionOutput -join ' ')" }
  $finalState = Read-AplStrictJson $dailyStatePath $logsRoot
  if ([string]$finalState.Status -cne 'PASS' -or $finalState.DailyProductionComplete -ne $true -or $finalState.DailyProductionPublishable -ne $true) { throw 'Authoritative daily production state did not reach publishable PASS.' }
  $status = 'PASS'
  Exit-AplNamedMutex $publishScoringMutex
  Exit-AplNamedMutex $runMutex
} catch {
  if ($status -eq 'PRODUCTION_PASS') { $status = 'ARCHIVE_FAILED' }
  elseif ($status -eq 'FINALIZING') { $status = 'FINALIZATION_FAILED' }
  try { Add-Trace @{ event='run-complete'; runId=$runId; utc=[datetime]::UtcNow.ToString('o'); status=$status; dailyProductionComplete=$false; error=$_.Exception.Message; artifacts=[string[]]$script:completedArtifacts.ToArray() } } catch {}
  try { Add-Log "RUN FAILED $runId :: $($_.Exception.Message)" } catch {}
  Exit-AplNamedMutex $publishScoringMutex
  Exit-AplNamedMutex $runMutex
  Write-Error $_
  exit 1
}

[pscustomobject]@{ RunId=$runId; Status=$status; DailyProductionComplete=($status -eq 'PASS'); DailyProductionPublishable=($status -eq 'PASS'); AuthoritativeState=$dailyStatePath; ProjectRoot=$ProjectRoot; OutputRoot=$publishRoot; DateOutput=$finalDateOut; FinalProductionAudit=$finalAuditPath; ArchiveDestination=$archiveDestination; ArchiveManifest=$archiveManifestPath; ArchiveIndex=$archiveIndexPath; PipelineLog=$pipelineLog; PipelineTrace=$tracePath; ArtifactCount=$publishedArtifacts.Count }
